# Architecture

## Stack technique

| Composant | Technologie |
| --- | --- |
| API | Django REST Framework |
| Auth | JWT avec SimpleJWT |
| Base de donnees | PostgreSQL 15 |
| Cache | Redis 7 |
| Taches asynchrones | Celery |
| Scheduler | Celery Beat |
| Stockage temporaire interne | MinIO `ekeflicks-temp` |
| Stockage final media | Backblaze B2 buckets videos/assets |
| Diffusion securisee | CDN / DRM |
| Analytics | ClickHouse |
| Recommandations IA | Neo4j optionnel + fallback Django |
| Reverse proxy | Nginx |
| Serveur WSGI | Gunicorn |
| Containerisation | Docker Compose |

## Flux global

```text
Client Flutter / Web / TV
        |
        v
Nginx HTTPS
        |
        v
Gunicorn
        |
        v
Django REST API
        |
        +-- PostgreSQL
        +-- Redis
        +-- MinIO temporaire
        +-- B2 final production
        +-- CDN / DRM media
        +-- Celery
        +-- ClickHouse
        +-- Neo4j recommandations
```

## Structure backend

```text
backend/
|-- config/
|   |-- settings.py
|   |-- settings_test.py
|   |-- urls.py
|   |-- celery.py
|   |-- asgi.py
|   `-- wsgi.py
|-- apps/
|   |-- auth/
|   |-- catalog/
|   |-- profiles/
|   |-- playback/
|   |-- billing/
|   |-- notifications/
|   |-- recommendations/
|   |-- analytics/
|   |-- streaming/
|   `-- common/
|-- core/
|   |-- models/
|   |-- migrations/
|   |-- services/
|   |-- tests/
|   |-- admin.py
|   |-- apps.py
|   `-- signals.py
|-- media/
|-- staticfiles/
|-- logs/
|-- manage.py
`-- requirements.txt
```

## Principes

- L'API est versionnee sous `/api/v1/`.
- Le backend serveur est la source de verite des utilisateurs, profils, contenus et abonnements.
- Les sources videos sont stockees dans MinIO `ekeflicks-temp` pour le traitement interne.
- Les manifests et segments HLS publies sont envoyes vers B2 dans `ekeflicks-videos`, puis servis via CDN/DRM.
- Les traitements longs doivent passer par Celery.
- Les analytics lourds doivent aller vers ClickHouse.
- Les recommandations avancees peuvent utiliser Neo4j pour exploiter le graphe profils, contenus, genres, favoris, notes et historique.

## Organisation API

Les modeles restent centralises dans `core/models/`, deja separes par domaine. Les APIs sont decoupees dans `apps/` :

- `apps/auth` : connexion, inscription, session utilisateur.
- `apps/catalog` : contenus, genres, emissions, saisons, episodes.
- `apps/profiles` : profils et types de profils.
- `apps/playback` : favoris, historique, notes, listes, sessions de visionnage.
- `apps/billing` : plans, abonnements, paiements.
- `apps/notifications` : notifications utilisateur.
- `apps/recommendations` : recommandations personnalisees.
- `apps/analytics` : statistiques reservees aux administrateurs.
- `apps/streaming` : manifests HLS/DASH, renditions video, licences offline.
- `apps/common` : permissions et helpers partages.
