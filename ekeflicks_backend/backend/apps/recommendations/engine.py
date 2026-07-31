from decimal import Decimal

from django.conf import settings
from django.db.models import Q
from django.utils import timezone

from core.models import (
    Content,
    Favorite,
    Profile,
    Rating,
    Recommendation,
    TrendingCache,
    WatchHistory,
)

try:
    from neo4j import GraphDatabase
except ImportError:  # pragma: no cover - exercised only when dependency is absent
    GraphDatabase = None


_driver = None


def neo4j_package_available():
    return GraphDatabase is not None


def neo4j_enabled():
    return (
        getattr(settings, 'NEO4J_ENABLED', False)
        and getattr(settings, 'RECOMMENDATION_ENGINE', 'django') == 'neo4j'
        and neo4j_package_available()
        and bool(getattr(settings, 'NEO4J_PASSWORD', ''))
    )


def get_neo4j_driver():
    global _driver
    if not neo4j_enabled():
        return None
    if _driver is None:
        _driver = GraphDatabase.driver(
            settings.NEO4J_URI,
            auth=(settings.NEO4J_USERNAME, settings.NEO4J_PASSWORD),
        )
    return _driver


def close_neo4j_driver():
    global _driver
    if _driver is not None:
        _driver.close()
        _driver = None


def _session():
    driver = get_neo4j_driver()
    if not driver:
        return None
    return driver.session(database=getattr(settings, 'NEO4J_DATABASE', 'neo4j'))


def ensure_graph_schema():
    session = _session()
    if not session:
        return False
    with session:
        session.run('CREATE CONSTRAINT profile_id IF NOT EXISTS FOR (p:Profile) REQUIRE p.id IS UNIQUE')
        session.run('CREATE CONSTRAINT content_id IF NOT EXISTS FOR (c:Content) REQUIRE c.id IS UNIQUE')
        session.run('CREATE CONSTRAINT genre_id IF NOT EXISTS FOR (g:Genre) REQUIRE g.id IS UNIQUE')
    return True


def _content_payload(content):
    return {
        'id': str(content.id),
        'title': content.title,
        'type': content.type,
        'release_year': content.release_year or 0,
        'rating_avg': float(content.rating_avg or 0),
        'view_count': int(content.view_count or 0),
        'popularity_score': float(content.popularity_score or 0),
        'trending_score': float(content.trending_score or 0),
    }


def sync_catalog_to_graph():
    session = _session()
    if not session:
        return {'enabled': False, 'contents': 0, 'genres': 0}

    ensure_graph_schema()
    contents_count = 0
    genres_count = 0
    queryset = Content.objects.prefetch_related('genres').all()
    with session:
        for content in queryset:
            session.run(
                """
                MERGE (c:Content {id: $content.id})
                SET c.title = $content.title,
                    c.type = $content.type,
                    c.release_year = $content.release_year,
                    c.rating_avg = $content.rating_avg,
                    c.view_count = $content.view_count,
                    c.popularity_score = $content.popularity_score,
                    c.trending_score = $content.trending_score
                """,
                content=_content_payload(content),
            )
            contents_count += 1
            for genre in content.genres.all():
                session.run(
                    """
                    MERGE (g:Genre {id: $genre.id})
                    SET g.name = $genre.name, g.slug = $genre.slug
                    WITH g
                    MATCH (c:Content {id: $content_id})
                    MERGE (c)-[:IN_GENRE]->(g)
                    """,
                    genre={
                        'id': str(genre.id),
                        'name': genre.name,
                        'slug': genre.slug,
                    },
                    content_id=str(content.id),
                )
                genres_count += 1

    return {'enabled': True, 'contents': contents_count, 'genres': genres_count}


def sync_profile_to_graph(profile):
    session = _session()
    if not session:
        return {'enabled': False, 'profile_id': str(profile.id), 'relationships': 0}

    sync_catalog_to_graph()
    relationships = 0
    with session:
        session.run(
            """
            MERGE (p:Profile {id: $profile.id})
            SET p.name = $profile.name, p.user_id = $profile.user_id
            """,
            profile={
                'id': str(profile.id),
                'name': profile.name,
                'user_id': str(profile.user_id),
            },
        )

        for history in WatchHistory.objects.filter(profile=profile).select_related('content'):
            session.run(
                """
                MATCH (p:Profile {id: $profile_id})
                MATCH (c:Content {id: $content_id})
                MERGE (p)-[r:WATCHED]->(c)
                SET r.progress = $progress,
                    r.completed = $completed,
                    r.last_position = $last_position,
                    r.updated_at = $updated_at
                """,
                profile_id=str(profile.id),
                content_id=str(history.content_id),
                progress=history.progress,
                completed=history.completed,
                last_position=history.last_position,
                updated_at=history.updated_at.isoformat(),
            )
            relationships += 1

        for favorite in Favorite.objects.filter(profile=profile).select_related('content'):
            session.run(
                """
                MATCH (p:Profile {id: $profile_id})
                MATCH (c:Content {id: $content_id})
                MERGE (p)-[r:FAVORITED]->(c)
                SET r.created_at = $created_at
                """,
                profile_id=str(profile.id),
                content_id=str(favorite.content_id),
                created_at=favorite.created_at.isoformat(),
            )
            relationships += 1

        for rating in Rating.objects.filter(profile=profile).select_related('content'):
            session.run(
                """
                MATCH (p:Profile {id: $profile_id})
                MATCH (c:Content {id: $content_id})
                MERGE (p)-[r:RATED]->(c)
                SET r.rating = $rating,
                    r.updated_at = $updated_at
                """,
                profile_id=str(profile.id),
                content_id=str(rating.content_id),
                rating=float(rating.rating),
                updated_at=rating.updated_at.isoformat(),
            )
            relationships += 1

    return {
        'enabled': True,
        'profile_id': str(profile.id),
        'relationships': relationships,
    }


def _neo4j_recommendations(profile, limit):
    session = _session()
    if not session:
        return []

    sync_profile_to_graph(profile)
    query = """
    MATCH (p:Profile {id: $profile_id})
    CALL {
        WITH p
        MATCH (p)-[:WATCHED|FAVORITED|RATED]->(:Content)<-[:WATCHED|FAVORITED|RATED]-(other:Profile)
        MATCH (other)-[rel:WATCHED|FAVORITED|RATED]->(c:Content)
        WHERE NOT (p)-[:WATCHED|FAVORITED|RATED]->(c)
        RETURN c.id AS content_id,
               sum(
                   CASE type(rel)
                   WHEN 'FAVORITED' THEN 4.0
                   WHEN 'RATED' THEN coalesce(rel.rating, 3.0)
                   ELSE 2.0
                   END
               ) + count(DISTINCT other) * 5.0 AS score,
               'because_you_watched' AS reason
        UNION
        WITH p
        MATCH (p)-[:WATCHED|FAVORITED|RATED]->(:Content)-[:IN_GENRE]->(g:Genre)<-[:IN_GENRE]-(c:Content)
        WHERE NOT (p)-[:WATCHED|FAVORITED|RATED]->(c)
        RETURN c.id AS content_id,
               count(DISTINCT g) * 8.0 + coalesce(c.trending_score, 0.0) + coalesce(c.rating_avg, 0.0) * 5.0 AS score,
               'similar_genre' AS reason
    }
    RETURN content_id, max(score) AS score, collect(reason)[0] AS reason
    ORDER BY score DESC
    LIMIT $limit
    """
    with session:
        records = session.run(query, profile_id=str(profile.id), limit=limit)
        return [
            {
                'content_id': record['content_id'],
                'score': float(record['score'] or 0),
                'reason': record['reason'] or 'ai_match',
            }
            for record in records
        ]


def _fallback_recommendations(profile, limit):
    watched_ids = set(
        WatchHistory.objects.filter(profile=profile).values_list('content_id', flat=True)
    )
    favorite_ids = set(
        Favorite.objects.filter(profile=profile).values_list('content_id', flat=True)
    )
    rated_ids = set(
        Rating.objects.filter(profile=profile).values_list('content_id', flat=True)
    )
    excluded_ids = watched_ids | favorite_ids | rated_ids

    scored = {}
    watched_genre_ids = list(
        Content.objects.filter(
            Q(watchhistory__profile=profile)
            | Q(favorite__profile=profile)
            | Q(ratings__profile=profile)
        )
        .values_list('genres__id', flat=True)
        .exclude(genres__id__isnull=True)
        .distinct()
    )

    if watched_genre_ids:
        for content in (
            Content.objects.filter(genres__id__in=watched_genre_ids)
            .exclude(id__in=excluded_ids)
            .distinct()
            .prefetch_related('genres')
        ):
            scored[str(content.id)] = {
                'content': content,
                'score': float(content.rating_avg or 0) * 10
                + float(content.popularity_score or 0)
                + float(content.trending_score or 0),
                'reason': 'similar_genre',
            }

    for content in Content.objects.exclude(id__in=excluded_ids).order_by(
        '-trending_score',
        '-view_count',
        '-popularity_score',
    )[: limit * 2]:
        item = scored.setdefault(
            str(content.id),
            {'content': content, 'score': 0.0, 'reason': 'trending'},
        )
        item['score'] += (
            float(content.trending_score or 0)
            + float(content.popularity_score or 0)
            + min(float(content.view_count or 0) / 1000, 20)
        )

    for cache in (
        TrendingCache.objects.select_related('content')
        .filter(period='week')
        .exclude(content_id__in=excluded_ids)
        .order_by('rank', '-score')[: limit * 2]
    ):
        item = scored.setdefault(
            str(cache.content_id),
            {'content': cache.content, 'score': 0.0, 'reason': 'trending'},
        )
        item['score'] += float(cache.score or 0)

    return [
        {
            'content_id': item['content'].id,
            'score': item['score'],
            'reason': item['reason'],
        }
        for item in sorted(scored.values(), key=lambda value: value['score'], reverse=True)[:limit]
    ]


def _save_recommendations(profile, rows):
    saved = []
    expires_at = timezone.now() + timezone.timedelta(days=7)
    for row in rows:
        score_value = max(0.0, min(float(row['score']), 999.99))
        recommendation, _created = Recommendation.objects.update_or_create(
            profile=profile,
            content_id=row['content_id'],
            defaults={
                'score': Decimal(str(round(score_value, 2))),
                'reason': row.get('reason') or 'ai_match',
                'is_viewed': False,
                'expires_at': expires_at,
            },
        )
        saved.append(recommendation)
    return saved


def generate_recommendations(profile, limit=None):
    limit = int(limit or getattr(settings, 'RECOMMENDATION_DEFAULT_LIMIT', 20))
    engine = 'neo4j' if neo4j_enabled() else 'django'
    rows = []

    if engine == 'neo4j':
        try:
            rows = _neo4j_recommendations(profile, limit)
        except Exception:
            rows = []
            engine = 'django'

    if not rows:
        rows = _fallback_recommendations(profile, limit)
        engine = 'django'

    saved = _save_recommendations(profile, rows)
    return {
        'engine': engine,
        'profile_id': str(profile.id),
        'count': len(saved),
        'recommendations': saved,
    }


def engine_status():
    return {
        'configured_engine': getattr(settings, 'RECOMMENDATION_ENGINE', 'django'),
        'active_engine': 'neo4j' if neo4j_enabled() else 'django',
        'neo4j_enabled': getattr(settings, 'NEO4J_ENABLED', False),
        'neo4j_package_available': neo4j_package_available(),
        'neo4j_uri': getattr(settings, 'NEO4J_URI', ''),
        'neo4j_database': getattr(settings, 'NEO4J_DATABASE', 'neo4j'),
    }
