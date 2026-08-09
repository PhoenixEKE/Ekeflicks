# Application client EkeFlicks

Application Flutter multi-supports destinée aux spectateurs. Elle contient les
parcours d'authentification, profils, catalogue, abonnement et lecture. Certaines
zones restent alimentées par des données de démonstration ; consulter l'[audit
général](../docs/AUDIT_GENERAL.md) avant toute recette.

## Démarrage

Voir le [guide des environnements](../docs/ENVIRONNEMENTS.md), puis :

```bash
flutter pub get
flutter gen-l10n
flutter analyze
flutter test
flutter run -d chrome
