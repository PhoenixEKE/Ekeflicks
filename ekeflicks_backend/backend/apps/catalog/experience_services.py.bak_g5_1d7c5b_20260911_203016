from django.db.models import Q
from django.utils import timezone

from core.models import Content, Genre, Profile, Recommendation, TrendingCache, WatchHistory


def limit_value(request, default=20, maximum=50):
    raw_value = request.query_params.get('limit', default)
    try:
        value = int(raw_value)
    except (TypeError, ValueError):
        value = default
    return max(1, min(value, maximum))


def get_profile_for_request(request):
    user = getattr(request, 'user', None)
    if not user or not user.is_authenticated:
        return None

    queryset = Profile.objects.filter(user=user, is_active=True).select_related('type')
    profile_id = request.query_params.get('profile')
    if profile_id:
        return queryset.filter(pk=profile_id).first()
    return queryset.order_by('created_at').first()


def base_content_queryset():
    return (
        Content.objects.select_related('status')
        .prefetch_related('genres', 'emissions')
        .all()
    )


def apply_advanced_search_filters(queryset, params):
    query = params.get('q') or params.get('query') or params.get('search')
    if query:
        queryset = queryset.filter(
            Q(title__icontains=query)
            | Q(original_title__icontains=query)
            | Q(description__icontains=query)
            | Q(synopsis__icontains=query)
            | Q(genres__name__icontains=query)
            | Q(emissions__name__icontains=query)
        )

    content_type = params.get('type')
    if content_type:
        queryset = queryset.filter(type=content_type)

    genre = params.get('genre')
    if genre:
        genre_filter = Q(genres__slug=genre)
        if str(genre).isdigit():
            genre_filter |= Q(genres__id=genre)
        queryset = queryset.filter(genre_filter)

    emission = params.get('emission')
    if emission:
        emission_filter = Q(emissions__slug=emission)
        if str(emission).isdigit():
            emission_filter |= Q(emissions__id=emission)
        queryset = queryset.filter(emission_filter)

    age_rating = params.get('age_rating')
    if age_rating:
        queryset = queryset.filter(age_rating__iexact=age_rating)

    for param_name, lookup in [
        ('year', 'release_year'),
        ('min_year', 'release_year__gte'),
        ('max_year', 'release_year__lte'),
        ('min_rating', 'rating_avg__gte'),
    ]:
        value = params.get(param_name)
        if value not in [None, '']:
            queryset = queryset.filter(**{lookup: value})

    if params.get('is_4k') in {'true', '1', 'yes'}:
        queryset = queryset.filter(is_4k=True)
    if params.get('is_hd') in {'true', '1', 'yes'}:
        queryset = queryset.filter(is_hd=True)

    return queryset.distinct()


def top_10_queryset():
    return base_content_queryset().order_by(
        '-view_count',
        '-popularity_score',
        '-rating_avg',
        '-created_at',
    )


def new_releases_queryset():
    return base_content_queryset().order_by(
        '-release_year',
        '-release_date',
        '-created_at',
    )


def trending_queryset(period='week'):
    cached_ids = list(
        TrendingCache.objects.filter(period=period)
        .order_by('rank', '-score')
        .values_list('content_id', flat=True)
    )
    if cached_ids:
        preserved_order = {content_id: index for index, content_id in enumerate(cached_ids)}
        return sorted(
            base_content_queryset().filter(id__in=cached_ids),
            key=lambda content: preserved_order.get(content.id, 9999),
        )
    return base_content_queryset().order_by('-trending_score', '-view_count', '-created_at')


def continue_watching_queryset(profile):
    if not profile:
        return WatchHistory.objects.none()
    return (
        WatchHistory.objects.filter(
            profile=profile,
            completed=False,
            progress__gt=0,
        )
        .select_related('content', 'content__status', 'episode')
        .prefetch_related('content__genres', 'content__emissions')
        .order_by('-updated_at')
    )


def recommended_queryset(profile):
    if profile:
        recommended_ids = list(
            Recommendation.objects.filter(
                profile=profile,
                is_viewed=False,
            )
            .filter(Q(expires_at__isnull=True) | Q(expires_at__gt=timezone.now()))
            .order_by('-score', '-created_at')
            .values_list('content_id', flat=True)
        )
        if recommended_ids:
            preserved_order = {content_id: index for index, content_id in enumerate(recommended_ids)}
            return sorted(
                base_content_queryset().filter(id__in=recommended_ids),
                key=lambda content: preserved_order.get(content.id, 9999),
            )

        watched_genres = Genre.objects.filter(contents__watchhistory__profile=profile).distinct()
        if watched_genres.exists():
            watched_ids = WatchHistory.objects.filter(profile=profile).values_list('content_id', flat=True)
            return (
                base_content_queryset()
                .filter(genres__in=watched_genres)
                .exclude(id__in=watched_ids)
                .distinct()
                .order_by('-rating_avg', '-popularity_score', '-created_at')
            )

    return top_10_queryset()


def genre_rails(limit=12, genre_limit=6):
    rails = []
    for genre in Genre.objects.order_by('name')[:genre_limit]:
        queryset = (
            base_content_queryset()
            .filter(genres=genre)
            .order_by('-popularity_score', '-rating_avg', '-created_at')[:limit]
        )
        items = list(queryset)
        if items:
            rails.append((genre, items))
    return rails
