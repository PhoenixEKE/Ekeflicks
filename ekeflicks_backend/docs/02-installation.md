# Installation

## Prerequis serveur

- Docker.
- Docker Compose v2.
- Acces SSH au serveur.
- Nom de domaine pointe vers le serveur.
- Certificat HTTPS via Nginx / Let's Encrypt.

## Copier le dossier sur le serveur

Depuis la machine locale, copier le dossier `ekeflicks_backup` vers le serveur.

Exemple avec `scp` :

```bash
scp -r ekeflicks_backup user@server:/opt/ekeflicks
```

Exemple avec `rsync` :

```bash
rsync -av --exclude='backend/logs/*' --exclude='backend/__pycache__' ekeflicks_backup/ user@server:/opt/ekeflicks/
```

## Premiere installation

Sur le serveur :

```bash
cd /opt/ekeflicks
cp .env.example .env
```

Editer `.env`, puis lancer :

```bash
docker compose build
docker compose up -d postgres redis minio clickhouse
docker compose run --rm django python manage.py migrate
docker compose run --rm django python manage.py createsuperuser
docker compose run --rm django python manage.py check
docker compose up -d
```

## Tests

```bash
docker compose run --rm django python manage.py test --settings=config.settings_test
```

## Verification rapide

```bash
curl http://127.0.0.1:8000/health/
```

