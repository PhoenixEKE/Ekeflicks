# Portail administrateur EkeFlicks

Application Flutter destinée à l'administration des utilisateurs, producteurs,
contenus et réclamations. Les écrans administratifs utilisent le client API sécurisé
avec MFA, renouvellement de session et RBAC. Le package porte encore le nom technique
`plateforme_administrateur` ; son renommage devra inclure les identifiants natifs.
## Adresses de développement

Les trois services utilisent des adresses distinctes :

| Service | Adresse |
| --- | --- |
| Plateforme client | `http://192.162.68.247:3000/` |
| Plateforme administrateur | `http://192.162.68.247:8080/` |
| API Django | `http://192.162.68.247:8000/` |

Le portail administrateur appelle les routes sous
`http://192.162.68.247:8000/api/v1/admin/`. L'adresse de l'interface (`:8080`)
ne doit donc pas être utilisée comme `API_URL`.

Pour démarrer la version web administrateur depuis le serveur :

```bash
flutter run -d web-server \
  --web-hostname 0.0.0.0 \
  --web-port 8080 \
  --dart-define=API_URL=http://192.162.68.247:8000/api/v1/admin
```

Pour produire les fichiers statiques à servir avec Nginx :

```bash
flutter build web \
  --release \
  --dart-define=API_URL=http://192.162.68.247:8000/api/v1/admin
```

Sans `--dart-define`, le client administrateur utilise l'API locale
`http://localhost:8000/api/v1/admin`.

## Créer le super-administrateur et configurer le MFA

Les migrations doivent impérativement être appliquées avant la création du compte.
Depuis le dossier `ekeflicks_backend` :

```bash
docker compose run --rm django python manage.py migrate --noinput
docker compose run --rm django python manage.py create_superadmin \
  --email admin@ekeflicks.com \
  --password 'remplacez-par-un-mot-de-passe-long-et-unique'
```

La deuxième commande affiche une URI commençant par `otpauth://`. Ajoutez cette URI
à Google Authenticator, Microsoft Authenticator, 2FAS ou Aegis. L'application
d'authentification produit alors le code MFA à six chiffres demandé à la connexion.

Si PostgreSQL signale que la relation `admin_mfa_devices` n'existe pas, cela signifie
que la migration `core.0020_admin_security` n'a pas encore été appliquée. Exécutez la
commande `migrate` ci-dessus, puis relancez `create_superadmin`.

## Démarrage

Voir le [guide des environnements](../docs/ENVIRONNEMENTS.md), puis :

```bash
flutter pub get
flutter gen-l10n
flutter analyze
flutter test
flutter run -d chrome
