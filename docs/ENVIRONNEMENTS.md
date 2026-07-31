# Environnements EkeFlicks

Ce guide definit les environnements supportes, les prerequis et les commandes de
reference. Toutes les commandes partent de la racine du depot, sauf indication
contraire.

## 1. Matrice des environnements

| Environnement | Objectif | Donnees | Services externes | Deploiement |
|---|---|---|---|---|
| Local | Developpement individuel | Jetables | Doubles ou sandbox | Docker Compose + Flutter local |
| Test | Tests automatises | Ephemeres | Simules | CI, a mettre en place |
| Staging | Validation integree | Non productives | Comptes sandbox | Infrastructure isolee |
| Production | Utilisateurs reels | Sauvegardees/chiffrees | Comptes live | Infrastructure administree |

Ne jamais reutiliser une base, un bucket, une cle, un webhook ou un compte fournisseur
entre staging et production.

## 2. Prerequis

- Git.
- Docker avec le plugin `docker compose` pour le backend local.
- Flutter compatible avec Dart `^3.8.1` pour les trois applications.
- Les SDK de plateforme necessaires a la cible choisie (Android Studio/JDK, Xcode sur
  macOS, navigateur pour le web).
- FFmpeg est fourni dans l'image backend; il n'est requis sur l'hote que pour lancer
  les traitements hors Docker.

Verification rapide :

```bash
docker --version
docker compose version
flutter --version
flutter doctor -v
```

## 3. Backend local avec Docker

Creer la configuration locale sans jamais versionner sa valeur :

```bash
cd ekeflicks_backend
cp .env.example .env
```

Remplacer au minimum toutes les valeurs `change-me`. Pour un environnement local,
conserver les hotes internes `postgres`, `redis`, `minio`, `clickhouse` et `neo4j`.
Puis demarrer et initialiser :

```bash
docker compose build
docker compose up -d postgres redis minio clickhouse
docker compose run --rm django python manage.py migrate
docker compose run --rm django python manage.py check
docker compose up -d django celery celery-beat
```

Services exposes sur l'hote :

| Service | URL/port local |
|---|---|
| API | `http://localhost:8000` |
| Swagger | `http://localhost:8000/swagger/` |
| PostgreSQL | `localhost:5433` |
| Redis | `localhost:6379` |
| MinIO S3 / console | `localhost:9010` / `http://localhost:9011` |
| ClickHouse HTTP | `http://localhost:8124` |
| Neo4j (profil optionnel) | `http://localhost:7474` / `localhost:7687` |

Commandes d'exploitation locale :

```bash
cd ekeflicks_backend
docker compose ps
docker compose logs -f django celery
docker compose down
# Supprime aussi les donnees locales : action destructive
docker compose down -v
```

## 4. Tests backend

Les tests utilisent `config.settings_test`, mais importent d'abord la configuration
principale. Ils ont donc besoin d'une cle Django et d'une base PostgreSQL valide. La
voie de reference actuelle est Docker :

```bash
cd ekeflicks_backend
docker compose up -d postgres redis
docker compose run --rm \
  -e DJANGO_SECRET_KEY=test-only-not-for-production \
  django python manage.py test --settings=config.settings_test
```

Les fichiers generes pendant les tests vont dans `backend/test_media/`, qui est ignore
et peut etre supprime sans risque :

```bash
rm -rf ekeflicks_backend/backend/test_media
```

## 5. Applications Flutter

Le depot contient trois applications independantes :

| Application | Repertoire | Package actuel |
|---|---|---|
| Spectateurs | `plateforme_client` | `app_ekeflicks` |
| Producteurs | `plateforme_producteurs` | `plateforme_producteurs` |
| Administration | `plateforme_administrateur` | `plateforme_producteurs` (a renommer) |

Pour chaque application :

```bash
cd <repertoire_application>
flutter pub get
flutter gen-l10n
flutter analyze
flutter test
flutter run -d chrome
```

Utiliser `flutter devices` pour choisir Android, iOS, desktop ou TV. Les repertoires
`build/`, `.dart_tool/`, caches natifs et rapports de compilation sont locaux et
ignores.

### Configuration de l'API client

Le client spectateur contient actuellement une URL API generee et une URL de
traduction codees en dur. C'est une dette connue : avant staging, elles doivent etre
remplacees par une configuration compilee (`--dart-define`) ou un fichier de
configuration non secret. Ne pas modifier directement les fichiers OpenAPI generes.

Convention cible :

```bash
flutter run -d chrome \
  --dart-define=APP_ENV=local \
  --dart-define=API_BASE_URL=http://localhost:8000/api/v1
```

L'URL n'est pas un secret. Les jetons et secrets fournisseur ne doivent jamais etre
passes par `--dart-define` ni embarques dans une application Flutter.

## 6. Variables backend par categorie

Le catalogue exhaustif et les valeurs exemples sont dans
`ekeflicks_backend/.env.example`. Les groupes principaux sont :

| Groupe | Variables structurantes |
|---|---|
| Django | `DEBUG`, `DJANGO_SECRET_KEY`, `ALLOWED_HOSTS` |
| URLs | `API_BASE_URL`, `FRONTEND_BASE_URL` |
| PostgreSQL | `DB_*`, `POSTGRES_*` |
| Cache/queue | `REDIS_HOST`, `REDIS_PORT`, `REDIS_PASSWORD` |
| Stockage | `MINIO_*`, `B2_*`, `USE_B2_FINAL_STORAGE` |
| Streaming | `STREAMING_*`, `MEDIA_CDN_BASE_URL` |
| DRM | `DRM_*`, `AXINOM_*` |
| Paiement | `CINETPAY_*`, `PAYSTACK_*`, `FLUTTERWAVE_*`, `WAVE_*` |
| Donnees | `CLICKHOUSE_*`, `NEO4J_*`, `RECOMMENDATION_ENGINE` |
| Exploitation | `SENTRY_DSN`, email |

## 7. Regles staging et production

- `DEBUG=False`, HTTPS obligatoire et domaines CORS/CSRF explicites.
- Secrets distincts, aleatoires et fournis par un gestionnaire de secrets; aucune
  valeur `change-me`.
- Secrets Django, streaming, DRM et webhooks differents et rotatables.
- PostgreSQL, Redis, MinIO et ClickHouse non exposes publiquement.
- Buckets distincts par environnement avec chiffrement, politiques minimales et cycle
  de retention.
- Webhooks fournisseurs en HTTPS avec signature obligatoire, idempotence et alertes.
- Migrations executees comme une etape controlee avant la bascule applicative.
- Sauvegarde et restauration testees avant toute donnee utilisateur reelle.
- Logs sans jetons, secrets, mots de passe ni informations de paiement.

## 8. Hygiene du depot

Ne pas versionner :

- `.env` et secrets;
- medias uploades ou generes (`media/`, `test_media/`, segments HLS/DASH);
- sorties Flutter/Gradle/Xcode (`build/`, caches, rapports);
- bases locales, logs, couvertures et caches Python;
- fichiers de sauvegarde `*.old`, `*.save`, `*.bak` ou copies manuelles.

Avant un commit :

```bash
git status --short
git diff --check
git ls-files | rg '(test_media/|/build/|\.old$|\.save$|\.bak$)'
```

La derniere commande ne doit retourner aucun fichier.

### Nettoyer une copie existante sur un serveur

Le script versionne reproduit le nettoyage des artefacts historiques. Il verifie la
structure du depot et fonctionne d'abord en simulation :

```bash
./scripts/nettoyer_depot.sh --root /chemin/vers/Ekeflicks
./scripts/nettoyer_depot.sh --apply --root /chemin/vers/Ekeflicks
```

Il supprime uniquement `backend/test_media`, les trois sauvegardes historiques, le
rapport Android et les deux fichiers Dart orphelins. Il ne supprime ni `.git`, ni le
code actif, ni les fichiers `.env`. Faire une sauvegarde serveur avant `--apply`, puis
controler la liste affichee et `git status --short`.
