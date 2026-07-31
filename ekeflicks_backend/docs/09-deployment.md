# Deploiement

## Avant copie serveur

Verifier :

- `.env.example` est present.
- `.env` contient les vraies valeurs serveur.
- `DEBUG=False`.
- `ALLOWED_HOSTS` contient le domaine public.
- Les secrets ont ete remplaces.
- Les tests passent.
- Le volume media est partage entre Django et Celery.
- MinIO est configure comme stockage temporaire interne `ekeflicks-temp`.
- B2 est configure comme stockage final production avec les buckets videos, posters, backdrops, trailers, avatars et sous-titres.
- Le CDN pointe vers le bucket B2 final des videos et applique la strategie DRM retenue.
- Neo4j est configure seulement si le moteur de recommandations graphe est active.

## Copie du dossier complet

Le dossier a deployer est :

```text
ekeflicks_backup/
```

Destination recommandee :

```text
/opt/ekeflicks/
```

Commande type :

```bash
rsync -av ekeflicks_backup/ user@server:/opt/ekeflicks/
```

## Premiere mise en production

```bash
cd /opt/ekeflicks
docker compose build
docker compose up -d postgres redis minio clickhouse
docker compose run --rm django python manage.py migrate
docker compose run --rm django python manage.py collectstatic --noinput
docker compose run --rm django python manage.py check
docker compose run --rm django python manage.py test --settings=config.settings_test
docker compose up -d
```

## Neo4j recommandations

Pour activer le moteur graphe :

```env
RECOMMENDATION_ENGINE=neo4j
NEO4J_ENABLED=True
NEO4J_URI=bolt://neo4j:7687
NEO4J_USERNAME=neo4j
NEO4J_PASSWORD=change-me
NEO4J_DATABASE=neo4j
```

Demarrage du service :

```bash
docker compose up -d neo4j
```

Ou avec le profil optionnel :

```bash
docker compose --profile neo4j up -d neo4j
```

Verifier le moteur :

```bash
curl -H "Authorization: Bearer <token>" \
  https://api.ekeflicks.com/api/v1/recommendations/engine-status/
```

Le backend garde un fallback Django si Neo4j est desactive.

Verifier FFmpeg dans l'image :

```bash
docker compose run --rm django ffmpeg -version
```

## Nginx

Nginx doit router le domaine API vers Django/Gunicorn :

```text
https://api.ekeflicks.com -> http://127.0.0.1:8000
```

## Apres deploiement

Verifier :

```bash
curl https://api.ekeflicks.com/health/
```

## Webhooks paiement

Les URLs publiques a declarer chez les fournisseurs :

```text
https://api.ekeflicks.com/api/v1/billing/webhooks/cinetpay/
https://api.ekeflicks.com/api/v1/billing/webhooks/paystack/
https://api.ekeflicks.com/api/v1/billing/webhooks/flutterwave/
https://api.ekeflicks.com/api/v1/billing/webhooks/wave/
```

Configurer les secrets correspondants dans `.env` avant de passer en production.
