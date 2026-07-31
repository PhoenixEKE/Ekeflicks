# Base de donnees

## PostgreSQL

PostgreSQL stocke les donnees principales :

- utilisateurs ;
- profils ;
- contenus ;
- saisons et episodes ;
- abonnements ;
- paiements ;
- notifications ;
- historiques ;
- recommandations.

## Migrations

Appliquer les migrations :

```bash
docker compose run --rm django python manage.py migrate
```

Verifier les migrations :

```bash
docker compose run --rm django python manage.py showmigrations
```

Creer de nouvelles migrations apres modification des modeles :

```bash
docker compose run --rm django python manage.py makemigrations
```

## Sauvegarde

Exemple :

```bash
docker compose exec postgres pg_dump -U "$POSTGRES_USER" "$POSTGRES_DB" > backup.sql
```

## Restauration

Exemple :

```bash
cat backup.sql | docker compose exec -T postgres psql -U "$POSTGRES_USER" "$POSTGRES_DB"
```

