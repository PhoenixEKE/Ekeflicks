# Monitoring

## Logs

Les logs Django sont ecrits dans :

```text
backend/logs/ekeflicks.log
```

Commandes utiles :

```bash
docker compose logs -f django
docker compose logs -f celery
docker compose logs -f celery-beat
```

## Services a surveiller

- Django / Gunicorn.
- PostgreSQL.
- Redis.
- Celery.
- Celery Beat.
- MinIO ou Backblaze B2.
- ClickHouse.
- Nginx.

## Verification rapide

```bash
docker compose ps
curl https://api.ekeflicks.com/health/
```

## Alertes recommandees

- API indisponible.
- PostgreSQL indisponible.
- Redis indisponible.
- File Celery bloquee.
- Espace disque faible.
- Erreurs 5xx elevees.
- Echec de sauvegarde.

## Sauvegardes

Surveiller :

- sauvegardes PostgreSQL ;
- sauvegardes medias ;
- rotation des logs ;
- restauration testee regulierement.

