diff --git a/ekeflicks_backend/docs/04-database.md b/ekeflicks_backend/docs/04-database.md
index 2b260c50368fae6a89542d00962b35cc59e66672..b5a8d4e24b03faac72ea5fc3df946e4d1fd3c23a 100644
--- a/ekeflicks_backend/docs/04-database.md
+++ b/ekeflicks_backend/docs/04-database.md
@@ -1,52 +1,74 @@
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
 
### Mise a jour recommandee

Le script suivant sauvegarde PostgreSQL, verifie que les modeles correspondent
aux migrations versionnees, affiche le plan, puis applique les migrations :

```bash
cd ekeflicks_backend
./scripts/update_database.sh
```

Les sauvegardes sont placees par defaut dans `ekeflicks_backend/backups/` (ignore
par Git). Pour choisir leur emplacement :

```bash
./scripts/update_database.sh --backup-dir /chemin/securise/sauvegardes
```

L'option `--no-backup` est disponible pour un environnement jetable uniquement.
Le script ne lance volontairement pas `makemigrations` : les fichiers de migration
doivent etre crees et relus pendant le developpement, puis livres avec le code.

### Commandes manuelles

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

