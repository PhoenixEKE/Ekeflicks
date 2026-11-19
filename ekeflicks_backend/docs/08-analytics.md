# Analytics

## Objectif

ClickHouse sert a stocker et analyser les evenements lourds :

- sessions de visionnage ;
- duree regardee ;
- contenus populaires ;
- tendances ;
- revenus ;
- activite quotidienne ;
- qualite de lecture.

## Modeles actuels

### ViewingSession

Trace une session de lecture :

- `profile`
- `content`
- `episode`
- `session_id`
- `start_time`
- `end_time`
- `duration_watched`
- `was_completed`
- `device_type`
- `quality_played`

### DailyStat

Agregat quotidien :

- `total_users`
- `active_users`
- `total_views`
- `total_watch_time`
- `new_subscriptions`
- `revenue`

### ProducerRevenueSetting

Parametrage de la remuneration producteur :

- `remuneration_enabled`
- `eligible_progress_percent`
- `rate_per_1000_views_eur`
- `minimum_payout_eur`

Le tarif par defaut est `1.5 EUR / 1000 vues` et le seuil par defaut est `30%`.

### ProducerCountryCurrency

Conversion EUR vers la devise du pays producteur :

- `country_code`
- `currency`
- `eur_to_currency_rate`
- `is_active`

Les pays CFA sont initialises avec `XOF` ou `XAF`, mais tout reste modifiable dans l'admin.

### ProducerContentView

Vue eligible a remuneration :

- `viewing_session`
- `producer`
- `content`
- `watched_seconds`
- `total_seconds`
- `progress_percent`
- `viewer_country_code`
- `amount_eur`
- `currency`
- `amount_local`
- `status`

Une vue n'est comptabilisee qu'une seule fois par session.

## Endpoints analytics

- `GET /api/v1/daily-stats/dashboard/`
- `GET /api/v1/daily-stats/views-by-minute/`
- `GET /api/v1/daily-stats/views-by-country/`
- `GET /api/v1/daily-stats/clickhouse-status/`
- `/api/v1/producer-revenue-settings/`
- `/api/v1/producer-country-currencies/`
- `/api/v1/producer-content-views/`

ClickHouse est utilise quand il est configure et disponible. Le backend conserve un fallback PostgreSQL pour le dashboard et les statistiques minute/pays.

## Evolution recommandee

- Envoyer les evenements de lecture en asynchrone.
- Calculer les tendances via Celery Beat.
- Alimenter les recommandations avec l'historique et les scores de popularite.

## Recommandations IA avec Neo4j

Neo4j peut servir de moteur de graphe pour les recommandations avancees.

Noeuds principaux :

- `Profile`
- `Content`
- `Genre`

Relations :

- `(:Profile)-[:WATCHED]->(:Content)`
- `(:Profile)-[:FAVORITED]->(:Content)`
- `(:Profile)-[:RATED]->(:Content)`
- `(:Content)-[:IN_GENRE]->(:Genre)`

Le backend expose :

- `GET /api/v1/recommendations/engine-status/`
- `POST /api/v1/recommendations/sync-graph/`
- `POST /api/v1/recommendations/generate/`

Quand Neo4j est desactive, le backend utilise un fallback Django base sur les genres regardes, les favoris, les notes et les tendances.
