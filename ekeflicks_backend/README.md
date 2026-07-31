# EkeFlicks Backend

Backend officiel de la plateforme de streaming EkeFlicks.

EkeFlicks est une plateforme de streaming video multi-supports (mobile, web, TV) construite autour de Django REST Framework, PostgreSQL, Redis, Celery, MinIO / Backblaze B2 et ClickHouse.

## Fonctionnalites backend

- Authentification JWT.
- Gestion des utilisateurs et profils.
- Catalogue de contenus : films, series, emissions.
- Historique de visionnage.
- Abonnements et paiements.
- Notifications.
- Recommandations IA.
- Analytics.
- Administration Django.

## Demarrage rapide serveur

Depuis ce dossier :

```bash
cp .env.example .env
docker compose build
docker compose up -d postgres redis minio clickhouse
docker compose run --rm django python manage.py migrate
docker compose run --rm django python manage.py check
docker compose run --rm django python manage.py test --settings=config.settings_test
docker compose up -d
```

## Routes utiles

- `/` : health check.
- `/health/` : health check.
- `/swagger/` : documentation Swagger.
- `/redoc/` : documentation Redoc.
- `/api/v1/auth/` : authentification.

## Documentation

La documentation complete est dans [`docs/`](docs/README.md).

- [`01-architecture.md`](docs/01-architecture.md)
- [`02-installation.md`](docs/02-installation.md)
- [`03-configuration.md`](docs/03-configuration.md)
- [`04-database.md`](docs/04-database.md)
- [`05-models.md`](docs/05-models.md)
- [`06-api.md`](docs/06-api.md)
- [`07-storage.md`](docs/07-storage.md)
- [`08-analytics.md`](docs/08-analytics.md)
- [`09-deployment.md`](docs/09-deployment.md)
- [`10-monitoring.md`](docs/10-monitoring.md)

## Etat actuel

Fonctionnel :

- Infrastructure Docker.
- PostgreSQL.
- Redis.
- ClickHouse.
- MinIO.
- Authentification JWT.
- Modeles principaux.
- Administration Django.
- API catalogue.
- API profils.
- API favoris, historique, notes et listes.
- API abonnements et paiements.
- API notifications et recommandations.
- API analytics de visionnage.
- APIs separees par domaine dans `backend/apps/`.
- API streaming HLS/DASH et licences offline.
- Webhooks paiement pour fournisseurs Mobile Money et Wave.
- Workflow upload source -> transcodage HLS -> stockage MinIO/B2 -> moderation -> publication.
- Architecture media : MinIO temporaire, B2 final production, CDN/DRM.
- Moderation admin des videos producteur avec motif de validation ou rejet.
- Experience catalogue Netflix-like : recherche avancee, accueil par rangees, continuer a regarder, top 10, tendances et nouveautes.
- Moteur de recommandations IA optionnel avec Neo4j et fallback Django.

En cours :

- Optimisation fine des recommandations IA.
- Streaming avance.
- Dashboard analytics.
