# Ekeflicks
Plateforme de streaming composee d'une API Django REST et d'un client Flutter
multi-supports.

## Documentation projet

- [Audit general et feuille de route vers une plateforme de niveau industriel](docs/AUDIT_GENERAL.md)
- [Guide des environnements et commandes de travail](docs/ENVIRONNEMENTS.md)
- [Documentation technique du backend](ekeflicks_backend/docs/README.md)

## Composants

| Repertoire | Role |
|---|---|
| `ekeflicks_backend/` | API Django, traitements asynchrones et infrastructure locale |
| `plateforme_client/` | Application Flutter pour les spectateurs |
| `plateforme_producteurs/` | Portail Flutter des producteurs |
| `plateforme_administrateur/` | Portail Flutter d'administration |

Consulter le guide des environnements avant de lancer un composant. Les fichiers
`.env`, medias de test, sorties de build et copies de sauvegarde ne doivent pas etre
ajoutes au depot.

Pour nettoyer une ancienne copie du depot sur un serveur, lancer d'abord en simulation
`./scripts/nettoyer_depot.sh --root /chemin/vers/Ekeflicks`, puis ajouter `--apply`
apres verification de la liste affichee.
