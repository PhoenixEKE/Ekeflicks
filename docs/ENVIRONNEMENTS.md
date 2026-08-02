# Environnements EkeFlicks

Ce guide definit les environnements supportes, les prerequis et les commandes de
reference. Toutes les commandes partent de la racine du depot, sauf indication
contraire.

## 1. Matrice des environnements

| Environnement | Objectif | Donnees | Services externes | Deploiement |
|---|---|---|---|---|
| Local | Developpement individuel | Jetables | Doubles ou sandbox | Docker Compose + Flutter local |
| Test | Tests automatises | Ephemeres | Simules | GitHub Actions |
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
