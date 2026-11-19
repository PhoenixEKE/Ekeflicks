# Documentation Backend EkeFlicks

Cette documentation accompagne le backend serveur EkeFlicks.

## Sommaire

1. [Architecture](01-architecture.md)
2. [Installation](02-installation.md)
3. [Configuration](03-configuration.md)
4. [Base de donnees](04-database.md)
5. [Modeles](05-models.md)
6. [API](06-api.md)
7. [Stockage medias](07-storage.md)
8. [Analytics](08-analytics.md)
9. [Deploiement](09-deployment.md)
10. [Monitoring](10-monitoring.md)

## Presentation

EkeFlicks est une plateforme de streaming video multi-supports (mobile, web, TV) construite autour d'une architecture moderne basee sur Django REST Framework.

Le backend fournit :

- Authentification JWT.
- Gestion des utilisateurs et profils.
- Catalogue de contenus.
- Historique de visionnage.
- Gestion des abonnements.
- Gestion des paiements.
- Notifications.
- Recommandations IA.
- Analytics.

## Structure generale

```text
ekeflicks_backup/
|-- backend/
|   |-- apps/
|   |-- config/
|   |-- core/
|   |-- manage.py
|   `-- requirements.txt
|-- docs/
|-- docker-compose.yml
|-- Dockerfile
|-- .env.example
`-- README.md
```

