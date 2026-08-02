# Audit general d'EkeFlicks

**Date de l'audit :** 29 juillet 2026
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
decoupe par domaines et compte 58 tests backend declares.

En revanche, le **produit de bout en bout n'est pas encore pret pour une mise en
production grand public**. Le client Flutter utilise encore un catalogue, des videos
et des sous-titres de demonstration. Il ne consomme qu'une petite partie de l'API
generee (principalement authentification, utilisateurs, profils et avatars). Les
paiements, l'observabilite, la diffusion video et les integrations externes sont
largement configurables, mais leur robustesse en conditions reelles n'est pas
demontree par ce depot.

### Verdict

| Axe | Maturite estimee | Lecture |
|---|---:|---|
| Modele metier et API backend | **Avance** | Bonne couverture fonctionnelle, a durcir et valider |
| Workflow media/producteur | **Intermediaire a avance** | Architecture presente, industrialisation a prouver |
| Client spectateur Flutter | **Prototype fonctionnel** | UI riche mais catalogue/player encore factices |
| Securite et conformite | **Intermediaire** | Bons reglages de base, audit offensif et conformite absents |
| Qualite et automatisation | **Insuffisant** | Tests backend presents, CI et tests client manquants |
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

1. **Brancher le client au vrai catalogue et au vrai streaming.** `ContentProvider`
   attend artificiellement une seconde, genere des fiches Picsum et lit Big Buck
   Bunny. Le lecteur affiche des sous-titres en dur. Il faut implementer les clients
   catalogue, accueil, recherche, interactions, recommandations et licences, puis
   lire les manifests signes HLS/DASH et les pistes serveur.
2. **Fermer le parcours d'abonnement/paiement.** Les ecrans existent mais il faut
   prouver l'initialisation fournisseur, le retour client, le webhook signe,
   l'idempotence, le rapprochement, le renouvellement, l'echec, le remboursement et
   la resiliation sur chaque marche cible. Aucun acces premium ne doit dependre du
   seul statut retourne au client.
3. **Rendre les tests reproductibles.** La commande documentee echoue sans
   `DJANGO_SECRET_KEY`, puis sans configuration PostgreSQL. `settings_test.py` importe
   d'abord les reglages de production et ne definit pas une base autonome. Fournir un
   environnement test complet (idealement PostgreSQL ephemere) et une commande unique.
4. **Ajouter une CI bloquante.** Aucun workflow CI n'est versionne. A chaque commit :
   formatage/lint, migrations, tests backend, analyse/tests Flutter, generation
   OpenAPI, verification de secrets/dependances et construction des artefacts.
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

## 4. Ce qui reste a construire ou a demontrer

### Produit spectateur

- Parcours complet API reel : accueil personnalise, fiche, saison/episode, recherche,
  favoris, listes, notes, historique, reprise multi-appareil et episode suivant.
- Controle parental robuste : PIN, classification par territoire, verrouillage des
  profils adultes, historique enfant et regles de recherche.
- Audio multilingue, sous-titres accessibles, audiodescription, vitesse, qualite
  manuelle/auto, casting et picture-in-picture selon plateforme.
- Telechargement reel chiffre, quotas par offre/appareil, expiration et renouvellement
  de licence.
- Notifications push/email transactionnelles avec preferences et desabonnement.
- Centre d'aide exploitable, tickets, diagnostic de lecture et communication incident.

### Plateforme media

- Packaging CMAF, echelle ABR calibree par contenu, codec H.264 puis evaluation
  HEVC/AV1, normalisation audio, controles qualite objectifs et perceptuels.
- DRM Widevine/FairPlay/PlayReady selon appareils, rotation de cles, politique HDCP,
  watermarking et processus de gestion des ayants droit.
- Origine video hautement disponible, CDN multi-region (eventuellement multi-CDN),
  invalidation, protection anti-hotlink et pilotage par qualite d'experience.
- Gestion complete des droits : territoires, fenetres, langues, supports, offres,
  exclusivites et retrait automatique.

### Donnees et personnalisation

- Taxonomie editoriale et qualite des metadonnees; recherche tolérante aux fautes,
  synonymes et langues locales via un moteur dedie.
- Pipeline d'evenements versionne avec consentement, deduplication et controle qualite.
- Recommandations mesurees hors ligne et en A/B test, diversite/fraicheur, demarrage a
  froid, explicabilite interne et garde-fous enfant.
- Separation des analytics produit, finance et remuneration; reconciliation et piste
  d'audit immuable pour les paiements producteurs.

### Exploitation et organisation

- Environnements dev/staging/production isoles, infrastructure as code, deploiements
  progressifs, migrations sans interruption et retour arriere teste.
- Sauvegarde chiffree, restauration testee, plan de reprise (RPO/RTO), rotation des
  secrets et gestion des acces privilegies.
- Logs structures avec identifiant de correlation, metriques Prometheus/OpenTelemetry,
  traces, crash reporting client, dashboards et alertes actionnables.
- Astreinte, runbooks, classification d'incident, post-mortems sans blame et tests de
  charge/chaos.
- Conformite : politique de confidentialite juridiquement validee, consentement,
  retention/minimisation, export/suppression, registre des traitements, contrats
  fournisseurs, fiscalite et obligations locales des pays servis.

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
