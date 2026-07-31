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
```

Extraire un service uniquement lorsqu'une limite est mesuree : transcodage et
packaging d'abord, puis recherche/evenements/recommandation si la charge ou l'equipe
le justifie. L'API doit rester versionnee et compatible avec les anciennes versions
mobiles.

## 6. Feuille de route recommandee

### Phase 0 — Stabilisation (2 a 4 semaines)

- Nettoyer le depot et documenter les environnements.
- Creer la CI, rendre les 58 tests backend reproductibles et ajouter les premiers
  tests Flutter.
- Generer le client OpenAPI complet; definir les contrats d'erreur, pagination et
  versionnement.
- Realiser la revue de securite P0 et un modele de menaces.
- Definir SLO, evenements analytics et criteres d'acceptation du MVP.

**Sortie :** branche principale verte, staging reproductible, zero secret dans le
depot, migrations et rollback verifies.

### Phase 1 — Parcours spectateur reel (4 a 8 semaines)

- Remplacer toutes les donnees factices par les API.
- Integrer catalogue, recherche, fiche, profils, interactions et player sous licence.
- Connecter un fournisseur de paiement prioritaire de bout en bout.
- Ajouter tests widget/integration et parcours E2E sur web, Android et TV prioritaire.

**Sortie :** un utilisateur de test peut payer et regarder un contenu autorise sur
staging, reprendre sur un second appareil et resilier.

### Phase 2 — Media, securite et exploitation (6 a 10 semaines)

- Industrialiser ingest, ABR, sous-titres/audio, DRM, CDN et telechargement.
- Mettre en place observabilite complete, alertes, astreinte, sauvegarde/restauration.
- Tests de charge sur login, accueil, licences, webhooks et origine; corriger les
  goulets mesures.
- Pentest independant et correction de toutes les vulnerabilites critiques/hautes.

**Sortie :** pilote ferme exploitable avec SLO mesures et runbooks testes.

### Phase 3 — Beta et croissance controlee (8 a 12 semaines)

- Recommandation v1 mesuree, A/B testing et tableaux produit/QoE.
- Deuxieme moyen de paiement/CDN si le risque commercial le justifie.
- Accessibilite, controle parental, support client et conformite des marches cibles.
- Beta par vagues avec budget de charge et criteres go/no-go.

**Sortie :** lancement public limite, capacite et cout par heure visionnee connus.

### Phase continue — Niveau industriel

- Optimisation codecs/CDN, personnalisation, experimentation et couts.
- Exercices de reprise, chaos engineering cible, red team et audits reguliers.
- Extension territoriale seulement apres droits, paiements, support et conformite.

## 7. Indicateurs et objectifs de service

Les cibles initiales doivent etre validees par des mesures, puis resserrees :

| Domaine | Indicateur de lancement suggere |
|---|---|
| API critique | 99,9 % de disponibilite mensuelle |
| API catalogue | p95 < 300 ms hors transfert d'image |
| Demarrage video | p75 < 3 s sur reseau cible |
| Rebuffering | ratio < 1 % du temps regarde |
| Erreur de lecture | < 1 % des tentatives |
| Paiement | taux de succes mesure par fournisseur/pays, webhooks 100 % reconciliables |
| Crash client | sessions sans crash > 99,5 % |
| Reprise | progression multi-appareil coherente en moins de 30 s |
| Media | 100 % des publications passent les controles techniques |
| Securite | aucune vulnerabilite critique/haute ouverte au lancement |
| Reprise apres sinistre | RPO/RTO definis puis prouves par exercice |

Suivre aussi conversion essai->payant, retention J7/J30, churn, heures visionnees,
abandon au demarrage, cout CDN/transcodage par heure, qualite par FAI/appareil et taux
de contact support.

## 8. Strategie de tests attendue

- **Unitaires backend :** permissions, etats metier, signatures, idempotence,
  remuneration et dates de droits.
- **Contrats API :** schema OpenAPI stable, compatibilite client et erreurs uniformes.
- **Integration :** PostgreSQL, Redis/Celery, stockage S3, FFmpeg, webhooks et DRM avec
  doubles controles.
- **Flutter :** unitaires providers/repositories, golden tests des composants, widgets
  et navigation sur tailles mobile/tablette/TV.
- **E2E :** inscription, verification, paiement, profil, lecture, reprise, expiration,
  resiliation et suppression du compte.
- **Non fonctionnels :** charge, endurance, reseau degrade, appareils bas de gamme,
  accessibilite, securite SAST/DAST/dependances et restauration.

Une fonctionnalite n'est « terminee » que si elle a des criteres d'acceptation, tests,
telemetrie, gestion des erreurs, documentation, controle d'acces et plan de rollback.

## 9. Risques majeurs a piloter

| Risque | Impact | Reduction |
|---|---|---|
| UI de demonstration confondue avec produit integre | Critique | Parcours E2E reel comme objectif no 1 |
| Fuite/contournement des contenus | Critique | Entitlements serveur, DRM, URLs courtes, pentest |
| Webhook faux ou rejoue | Critique | Signature obligatoire, idempotence, reconciliation |
| Echec de transcodage ou saturation stockage | Eleve | Quotas, retry controle, DLQ, alertes, purge |
| Tests non reproductibles | Eleve | Conteneur test et CI obligatoire |
| Dette multi-plateforme trop tot | Eleve | Matrice de supports priorisee et appareils certifies |
| Donnees personnelles mal gouvernees | Critique | Cartographie, minimisation, retention et audit juridique |
| Cout CDN/egress incontrôlé | Eleve | Tableaux de cout, ABR, cache, budgets et alertes |
| Recommandations non mesurees | Moyen | Baseline editoriale, experimentation et KPI |

## 10. Prochaines decisions produit

Avant d'engager la phase 1, les responsables doivent trancher :

1. Pays de lancement, catalogue licencie et contraintes territoriales.
2. Plateformes prioritaires (par exemple web + Android mobile + Android TV) et celles
   qui seront explicitement reportees.
3. Fournisseur de paiement principal et politique d'abonnement/remboursement.
4. Fournisseur DRM/CDN et budget cible par heure de visionnage.
5. SLO, nombre d'utilisateurs simultanes du pilote et budget d'erreur.
6. Exigences legales, fiscales, parentales et de conservation par pays.
7. Equipe responsable de l'astreinte, de la securite, des contenus et du support.

Ces decisions permettent de transformer l'ambition « comme Netflix » en un plan
mesurable : une excellente experience sur un perimetre restreint, puis une extension
basee sur des donnees plutot qu'une dispersion fonctionnelle.
