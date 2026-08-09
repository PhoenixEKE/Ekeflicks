# Audit general d'EkeFlicks

**Date de la revue :** 9 août 2026 (mise à jour de l’audit du 29 juillet 2026)
**Perimetre :** depot applicatif, backend Django, client Flutter, donnees, streaming,
securite, exploitation et qualite.
**Methode :** lecture statique du code et de la configuration, inventaire des routes,
modeles et tests, puis tentatives d'execution des controles disponibles.

> Cet audit mesure l'etat du depot, pas celui d'une infrastructure de production.
> L'ambition « niveau Netflix » est traitee comme un objectif de qualite de service,
> de produit et d'exploitation, et non comme une promesse de parite immediate.

## 1. Synthese de direction

EkeFlicks dispose d'un **socle backend nettement plus avance qu'un prototype** : le
domaine metier, l'authentification, le catalogue, les profils, les interactions, la
facturation, le workflow producteur, les licences de lecture, l'analytics et les
recommandations sont modelises et exposes par API. Le pipeline media prevoit HLS,
DASH, sous-titres, moderation, stockage temporaire/final, CDN et DRM. L'ensemble est
découpé par domaines. Django découvre désormais **87 tests backend** ; sept tests
client et un test par portail sont également présents.

En revanche, le **produit de bout en bout n'est pas encore prêt pour une mise en
production grand public**. Le client Flutter possède désormais des services pour le
catalogue, les interactions, les notifications et les comptes, mais plusieurs écrans
parallèles utilisent encore Picsum ou des données locales. Le lecteur reçoit une URL
directe et ses sous-titres restent simulés : l'obtention d'une licence de lecture
n'est pas intégrée. Les deux portails n'ont aucune couche HTTP. Les paiements,
l'observabilité, la diffusion vidéo et les intégrations externes sont configurables,
mais leur robustesse en conditions réelles n'est pas démontrée par ce dépôt.

### Verdict

| Axe | Maturite estimee | Lecture |
|---|---:|---|
| Modele metier et API backend | **Avance** | Bonne couverture fonctionnelle, a durcir et valider |
| Workflow media/producteur | **Intermediaire a avance** | Architecture presente, industrialisation a prouver |
| Client spectateur Flutter | **Prototype fonctionnel** | UI riche mais catalogue/player encore factices |
| Securite et conformite | **Intermediaire** | Bons reglages de base, audit offensif et conformite absents |
| Qualité et automatisation | **Intermédiaire** | CI présente et 96 tests découverts, mais couverture E2E et analyse statique absentes |
| Production/SRE | **Insuffisant** | Docker local documente, aucun dispositif HA/SLO verifiable |

**Conclusion :** le backend constitue un MVP technique credible. La priorite n'est
pas d'ajouter davantage d'ecrans ou de modeles, mais de fermer le parcours reel
« inscription -> abonnement -> choix du profil -> decouverte -> lecture securisee ->
reprise -> support », de fiabiliser les paiements/media et de mettre en place la
chaine de qualite et d'exploitation.

## 2. Ce qui a deja ete fait

### 2.1 Architecture et infrastructure

- Monolithe Django REST modulaire, organise en domaines `auth`, `catalog`, `profiles`,
  `playback`, `billing`, `notifications`, `recommendations`, `analytics` et
  `streaming`.
- PostgreSQL pour le transactionnel, Redis pour cache/queue, Celery pour les taches,
  ClickHouse pour l'analytics, MinIO pour le stockage temporaire et Backblaze B2
  envisage pour les medias finaux.
- Environnement Docker Compose comprenant API, worker, scheduler et services de
  donnees; health checks HTTP et documentation Swagger/Redoc.
- Configuration par variables d'environnement, secret Django obligatoire hors debug,
  CORS/CSRF parametrables et reglages HTTPS/cookies securises hors debug.

### 2.2 Identite, comptes et profils

- Utilisateur base sur l'email, JWT avec rotation et blacklist.
- Inscription, connexion, rafraichissement, deconnexion, consultation/modification du
  compte.
- Verification d'email, renvoi du message, demande et confirmation de reinitialisation
  du mot de passe.
- Demande de fermeture de compte et workflow support de changement d'email.
- Profils multiples, profil principal, type de profil et controle d'appartenance.

### 2.3 Catalogue et experience de decouverte backend

- Films, series/emissions, genres, statuts de publication, saisons et episodes.
- Serialisation liste/detail et controle producteur/proprietaire/admin.
- Recherche, filtrage et rangees d'accueil de type « continuer », tendances, top 10,
  nouveautes et contenus similaires dans l'API catalogue.
- Workflow producteur : creation, ajout des visuels/medias, soumission, moderation,
  validation ou rejet motive, puis publication.

### 2.4 Lecture et engagement

- Historique, favoris, notes, listes personnalisees et sessions de visionnage.
- Progression de lecture et fondations pour « continuer a regarder ».
- Actifs video, renditions, pistes de sous-titres, licences de lecture et licences de
  telechargement hors ligne.
- Generation/signature d'URL de lecture et options DRM locales/Axinom.
- Transcodage asynchrone prevu avec FFmpeg vers HLS/DASH, puis transfert du stockage
  temporaire vers le stockage final.

### 2.5 Moneti­sation, producteurs et analytics

- Plans, abonnements, paiements et evenements webhook persistants.
- Adaptateurs de verification pour CinetPay, Paystack, Flutterwave et Wave selon les
  secrets configures.
- Demandes de reversement producteur, validation/rejet administrateur, regles de
  remuneration et devises par pays.
- Statistiques quotidiennes, vues par contenu/producteur et integration ClickHouse
  optionnelle.
- Recommandations persistees, tendances, similarite, moteur Neo4j optionnel et repli
  sur le moteur Django.

### 2.6 Client Flutter

- Cibles Android, iOS, web, Windows, macOS et Linux; adaptation mobile/web/TV.
- Themes clair/sombre, francais/anglais, navigation clavier/telecommande et clavier TV.
- Ecrans d'accueil, recherche, genres, authentification, compte, profils, abonnement,
  FAQ, mentions legales et lecteur video.
- Stockage securise des jetons, restauration de session, deep link de reinitialisation
  et client OpenAPI partiel.

## 3. Ce qui doit etre corrige en priorite

### P0 — Bloquants avant toute production publique

1. **Achever l'intégration client et le vrai streaming.** `ContentProvider` appelle
   maintenant les API d'accueil, catalogue et interactions, mais des écrans de
   recherche, genres, information et post-connexion génèrent encore des fiches
   Picsum. Le lecteur reçoit directement `videoUrl` et affiche des sous-titres
   simulés. Unifier les parcours sur les services API, obtenir une licence puis lire
   les manifests signés HLS/DASH et les pistes serveur.
2. **Fermer le parcours d'abonnement/paiement.** Les ecrans existent mais il faut
   prouver l'initialisation fournisseur, le retour client, le webhook signe,
   l'idempotence, le rapprochement, le renouvellement, l'echec, le remboursement et
   la resiliation sur chaque marche cible. Aucun acces premium ne doit dependre du
   seul statut retourne au client.
3. **Étendre la CI existante.** Le workflow fournit PostgreSQL et lance les 87 tests
   backend ainsi que les tests Flutter des trois applications. Ajouter
   `flutter analyze`, la vérification des migrations et du schéma OpenAPI, un scan de secrets
   et dépendances, puis des builds représentatifs.
4. **Créer les tests d'intégration et E2E.** Les tests Flutter (7 côté client, 1 par
   portail) restent surtout unitaires. Couvrir les contrats API, rôles, paiements,
   upload, modération et lecture sur une stack éphémère reproductible.
5. **Valider la chaine media en conditions proches de la production.** Tester upload
   volumineux et multipart, reprise, antivirus, timeout, echec FFmpeg, profils ABR,
   audio multiples, sous-titres, thumbnails, publication atomique, purge CDN et
   suppression definitive.
6. **Faire un audit securite externe avant lancement.** Menaces prioritaires : IDOR
   entre producteurs/profils, contournement d'abonnement, rejeu de webhook, fuite
   d'URL signee, abus upload, JWT vole, enumeration de comptes et acces DRM/offline.

### P1 — Corrections importantes du depot

- **Nettoyage realise le 29 juillet 2026 :** les sauvegardes suivies
  (`settings.py.save`, `urls.py.old`, `users.py.old`), le rapport de build Android,
  les copies Dart orphelines et les medias generes de `test_media` ont ete retires.
  Un `.gitignore` racine empeche leur reintroduction; conserver uniquement des
  fixtures minimales et reproductibles.
- **Documentation realisee le 29 juillet 2026 :** les README Flutter generiques ont
  ete remplaces et un guide commun decrit les SDK, variables, commandes test/build et
  la separation des environnements. Poursuivre la normalisation du code au fil des
  changements fonctionnels.
- Remplacer les appareils connectes factices par l'API des sessions utilisateur,
  avec revocation d'un appareil et « deconnecter tous les appareils ».
- Regenerer un client OpenAPI couvrant tous les domaines et l'integrer derriere des
  repositories/services testables plutot que des appels disperses.
- Corriger le cycle de vie du player : le controleur peut etre utilise/supprime avant
  son initialisation en cas d'erreur; limiter les `setState` a chaque tick, envoyer la
  progression par lots et gerer proprement background/reseau/retry.
- Remplacer les types `dynamic` du player et des donnees d'episode par des modeles
  immuables; ajouter une machine d'etat explicite (initialisation, lecture, buffering,
  erreur, fin).
- Ne pas reutiliser `SECRET_KEY` comme repli pour les secrets de signature streaming,
  cle DRM ou communication DRM en production; exiger des secrets distincts, geres par
  un coffre et avec rotation.
- Verrouiller le comportement lorsque les secrets webhook sont absents; journaliser
  et alerter sans stocker de secrets ni de donnees sensibles.

## 4. Ce qui reste à construire ou à démontrer, par plateforme

Les mentions **construire** signalent une capacité absente ou encore factice. Les
mentions **démontrer** signalent une implémentation présente dont le comportement
réel, la sécurité ou l'exploitabilité ne sont pas établis par les tests du dépôt.

### 4.1 Plateforme client (spectateur)

| Priorité | Nature | Reste à faire / preuve attendue |
|---|---|---|
| P0 | Construire | Unifier les écrans sur les services API déjà présents et remplacer Picsum, les résultats de recherche, genres, épisodes et appareils connectés factices par les endpoints catalogue, sessions et recommandations. |
| P0 | Construire | Obtenir une licence serveur et lire un manifeste HLS/DASH signé avec sous-titres et progression persistée, au lieu d'un média de démonstration. |
| P0 | Démontrer | Valider inscription, vérification d'email, connexion, réinitialisation, choix du profil, abonnement, paiement, reprise et déconnexion sur une stack intégrée. |
| P0 | Démontrer | Prouver que l'autorisation premium, les limites d'âge et l'appartenance au profil sont contrôlées côté serveur, y compris en cas de requêtes modifiées. |
| P1 | Construire | Implémenter favoris, listes, notes, historique, épisode suivant, reprise multi-appareil et révocation des sessions avec états hors ligne/erreur. |
| P1 | Construire | Ajouter téléchargement chiffré, quotas, expiration/renouvellement de licence, audio/sous-titres accessibles, casting et picture-in-picture selon cible. |
| P1 | Démontrer | Tester le cycle de vie du player (buffering, changement réseau, arrière-plan, retry, fin), les deep links et les paiements refusés/annulés/remboursés. |
| P2 | Construire | Notifications et préférences réelles, consentement analytics, centre d'aide, tickets et diagnostic de lecture. |
| P2 | Démontrer | Accessibilité, navigation TV/clavier, responsive, français/anglais et builds signés Android, iOS, web et TV/appareils réellement visés. |

**Définition de terminé client :** aucun jeu de données de démonstration dans un
parcours de production, tests de contrat et E2E verts, télémétrie sans données
sensibles, puis recette sur chaque famille d'appareils officiellement supportée.

### 4.2 Plateforme producteur

| Priorité | Nature | Reste à faire / preuve attendue |
|---|---|---|
| P0 | Construire | Ajouter authentification/autorisation producteur et un client API typé : le portail ne contient actuellement aucune couche HTTP. |
| P0 | Construire | Relier création et modification des films/séries/saisons/épisodes, visuels, upload multipart avec reprise, puis soumission à modération. |
| P0 | Démontrer | Prouver l'isolation entre producteurs (IDOR), les quotas et formats, l'antivirus, les erreurs/reprises d'upload et l'idempotence des soumissions. |
| P1 | Construire | Brancher tableau de bord, vues, revenus, reversements, réclamations et profil sur les données backend avec pagination, filtres et états vides/erreur. |
| P1 | Construire | Exposer le statut du traitement média et de la modération, les motifs de rejet, la correction puis la nouvelle soumission. |
| P1 | Démontrer | Réconcilier vues éligibles, règles de rémunération, devises, retenues et reversements avec une piste d'audit exportable. |
| P2 | Construire | Notifications, gestion d'équipe et rôles délégués, contrats/droits territoriaux et exports comptables si retenus dans le périmètre produit. |
| P2 | Démontrer | Tests E2E navigateur, gros fichiers/réseau instable, accessibilité, localisation et build web de production. |

**Définition de terminé producteur :** un producteur peut déposer un contenu, suivre
son traitement, corriger un rejet, publier après validation et rapprocher ses revenus
sans intervention technique, sans pouvoir consulter les données d'un autre compte.

### 4.3 Plateforme administrateur

| Priorité | Nature | Reste à faire / preuve attendue |
|---|---|---|
| P0 | Construire | Remplacer utilisateurs, producteurs et réclamations d'exemple par un client API administrateur ; ajouter connexion forte, renouvellement et révocation de session. |
| P0 | Construire | Implémenter RBAC à privilège minimal et contrôles serveur pour support, modérateur, finance et super-administrateur. |
| P0 | Construire | Brancher les files de modération, validation/rejet motivé, suspension, gestion des comptes et décisions de reversement. |
| P0 | Démontrer | Prouver l'impossibilité d'escalade de privilège et produire un journal d'audit immuable des consultations et mutations sensibles. |
| P1 | Construire | Ajouter recherche/pagination/filtrage serveur, pièces jointes de réclamation, doubles validations finance et gestion sûre des erreurs concurrentes. |
| P1 | Démontrer | Tester les workflows complets producteur→modération→publication et demande→validation→paiement, y compris rejet, retry et doublon. |
| P1 | Construire | Renommer proprement le package encore nommé `plateforme_producteurs`, y compris bundle IDs, titres et artefacts natifs. |
| P2 | Construire | Tableaux de bord opérationnels, alertes fraude/abus, exports contrôlés et masquage des données personnelles selon le rôle. |
| P2 | Démontrer | MFA, durée de session, réauthentification des actions critiques, accessibilité, localisation et build web durci derrière SSO/VPN si retenu. |

**Définition de terminé administrateur :** chaque action sensible est autorisée côté
serveur, attribuable et réversible lorsque le métier le permet ; les rôles ont été
testés négativement et aucun écran de production ne dépend de données locales.

### 4.4 Socle partagé à démontrer

- **Média :** chaîne upload→scan→transcodage ABR→contrôle qualité→publication
  atomique→CDN→DRM, avec reprise, purge et suppression définitive.
- **Paiements :** signatures webhook, idempotence, rapprochement, renouvellement,
  échec, remboursement, résiliation et reversement pour chaque fournisseur/pays.
- **Exploitation :** staging/production isolés, infrastructure as code, sauvegarde et
  restauration testées, RPO/RTO, observabilité, alertes, runbooks et retour arrière.
- **Sécurité/conformité :** test d'intrusion indépendant, rotation des secrets,
  minimisation/rétention/export/suppression des données et validation juridique.
- **Qualité :** CI enrichie, contrats OpenAPI, tests E2E multi-rôles, charge et chaos,
  budgets de performance et critères SLO du document dédié.

## 5. Architecture cible pragmatique

Ne pas chercher a copier prematurement les centaines de microservices d'un acteur
mondial. Le monolithe modulaire Django est adapte au lancement s'il reste observable,
teste et scalable horizontalement.

```text
Applications Flutter
        |
 API Gateway / WAF / rate limiting
        |
 Django REST stateless ---- Redis ---- Celery workers
        |                       |
 PostgreSQL                jobs media/notifications
        |
 Outbox/evenements ---> bus ---> ClickHouse / recommandation

 Upload direct multipart ---> stockage temporaire ---> transcodage/controle
                                               ---> stockage origine ---> CDN + DRM
