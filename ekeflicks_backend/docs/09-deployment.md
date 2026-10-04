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
Le code Python execute provient exclusivement de l'image construite. Ne pas monter
le dossier hote `backend/` sur `/app` en production : ce montage masquerait les
fichiers copies par le `Dockerfile` et pourrait combiner un ancien
`avatar_views.py` avec un nouveau `config/urls.py`.

## Mise a jour de l'application

Pour garantir que Django, Celery et Celery Beat executent tous la meme revision :

```bash
git pull --ff-only
docker compose build --pull django
docker compose run --rm django python manage.py check
docker compose run --rm django python manage.py migrate
docker compose up -d --force-recreate django celery celery-beat
```

Le `Dockerfile` execute aussi `python manage.py check` pendant la construction. Une
image contenant une route qui importe une vue absente echoue donc avant le
deploiement, au lieu de redemarrer Gunicorn en boucle.

## Neo4j recommandations

Pour activer le moteur graphe :

```env
RECOMMENDATION_ENGINE=neo4j
NEO4J_ENABLED=True
NEO4J_URI=bolt://neo4j:7687
NEO4J_USERNAME=neo4j
NEO4J_PASSWORD=change-me
NEO4J_DATABASE=neo4j
NEO4J_CONNECTION_TIMEOUT=5
NEO4J_MAX_CONNECTION_POOL_SIZE=50
```

Demarrage du service :

```bash
docker compose up -d neo4j
```

Ou avec le profil optionnel :

```bash
docker compose --profile neo4j up -d neo4j
```
Attendre que le conteneur soit sain, puis creer les contraintes et charger le
catalogue dans le graphe :

```bash
docker compose --profile neo4j ps neo4j
docker compose run --rm django python manage.py setup_neo4j
```

Pour une premiere mise en service, il est possible de synchroniser en plus tous
les profils actifs, leurs visionnages, favoris et notes :

```bash
docker compose run --rm django python manage.py setup_neo4j --with-profiles
```

La commande echoue explicitement si le service est indisponible ou si les
identifiants sont incorrects. Le mot de passe d'exemple doit etre remplace par
un secret fort avant tout deploiement. Les executions suivantes sont
idempotentes : les noeuds, relations et contraintes sont crees avec `MERGE` ou
`IF NOT EXISTS`.

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

## TURN relay for Ekeroom

Ekeroom asks this API for ICE servers only after the authenticated user has joined an open salon.
The API keeps the Coturn shared secret server-side and returns a short-lived HMAC credential
(default one hour, limited to 24 hours). With no TURN URLs or secret configured, the client keeps
the existing public STUN fallback; relay traffic is not enabled until Coturn is provisioned.

The optional Coturn service runs in host networking so its UDP relay port range is reachable.
Before enabling it on a server:

1. Create a DNS A record for `turn.ekeflicks.com` pointing to the TURN host's public IP.
2. Obtain a TLS certificate for that hostname. Copy its full chain and private key to the
   paths in `.env`, owned by UID/GID 65534 (the Coturn image's `nobody` user); use mode
   `0644` for the certificate and `0600` for the private key. Configure a Certbot renewal hook
   to refresh these copies and restart Coturn.
3. Generate one random shared secret on the server (for example, `openssl rand -hex 32`) and
   set the same value in `TURN_SHARED_SECRET` in the backend `.env`.
4. Set `TURN_EXTERNAL_IP`, `TURN_REALM`, and
   `TURN_ICE_SERVER_URLS` in that same `.env`, for example:
   `turn:turn.ekeflicks.com:3478?transport=udp,turn:turn.ekeflicks.com:3478?transport=tcp,turns:turn.ekeflicks.com:5349?transport=tcp`.
   Keep the URL list and secret out of source control.
5. Open TCP/UDP 3478, TCP 5349, and TCP/UDP 49160–49200 in the host firewall and provider firewall.
6. From `ekeflicks_backend/`, start the optional relay with
   `docker compose --profile turn -f docker-compose.yml -f docker-compose.turn.yml up -d coturn`.
   Recreate the Django service after changing its `.env` so the credential endpoint receives the
   same secret as Coturn.

Coturn relays consume server bandwidth when direct peer connections fail. This PR only adds the
opt-in service and app/API support; it does not configure DNS, open firewall ports, or deploy the
relay to production. Validate the configured relay with web, mobile and Android TV network tests.

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
