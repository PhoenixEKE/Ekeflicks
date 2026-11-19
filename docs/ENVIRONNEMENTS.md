# Environnements EkeFlicks

Ce guide définit les environnements, les prérequis et les commandes de référence.
Toutes les commandes partent de la racine du dépôt.

## Matrice des environnements

| Environnement | Objectif | Données | Services externes | Déploiement |
|---|---|---|---|---|
| Local | Développement | Jetables | Doubles ou sandbox | Docker Compose + Flutter local |
| Test | Automatisation | Éphémères | Simulés | GitHub Actions |
| Staging | Recette intégrée | Non productives | Comptes sandbox | À construire |
| Production | Utilisateurs réels | Sauvegardées et chiffrées | Comptes live | À construire |

Une base, un bucket, une clé, un webhook ou un compte fournisseur ne doit jamais être
partagé entre staging et production.

## Prérequis

- Git et Docker avec le plugin `docker compose` pour le backend local ;
- Flutter **3.32.8**, version épinglée par la CI (les portails demandent Dart 3.8.1) ;
- les SDK de la cible choisie (Android Studio/JDK, Xcode sur macOS ou navigateur) ;
- FFmpeg seulement si les traitements média sont lancés hors conteneur.

```bash
docker --version
docker compose version
flutter --version
flutter doctor -v
