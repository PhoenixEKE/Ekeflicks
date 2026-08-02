# MVP EkeFlicks : SLO, analytics et criteres d'acceptation

**Version :** 1.0  
**Date de reference :** 1er aout 2026  
**Statut :** contrat de lancement propose pour le pilote ferme  
**Perimetre :** staging proche de la production, puis production du pilote

Ce document transforme la sortie de la phase 1 en exigences mesurables. Il sert de
reference commune au produit, a l'engineering, au support et a l'exploitation. Une
fonctionnalite qui n'est pas instrumentee ou un SLO qui n'est pas mesurable n'est pas
considere comme livre.

## 1. Perimetre et hypotheses du MVP

Le MVP couvre un seul parcours spectateur de bout en bout :

`inscription -> verification email -> connexion -> abonnement -> profil -> accueil
-> fiche contenu -> licence -> lecture -> progression -> reprise -> resiliation`.

Le pilote est limite aux choix suivants, a confirmer avant le gel fonctionnel :

- un pays et une devise, avec un fournisseur de paiement principal ;
- web, Android mobile et Android TV comme plateformes certifiees ;
- contenus a la demande HLS, avec une piste audio et au moins une piste de
  sous-titres lorsqu'elle est disponible ;
- un catalogue dont les droits, territoires et dates de diffusion sont renseignes ;
- un environnement de production, un staging representatif et des comptes de test
  distincts ;
- support en francais, sans telechargement hors ligne, casting, multi-CDN ni
  personnalisation avancee dans le perimetre obligatoire.

Tout changement de pays, paiement, DRM, CDN ou plateforme certifiee impose de rejouer
les tests d'acceptation concernes. Les donnees factices et les URL video publiques de
demonstration sont interdites dans les builds du pilote.

## 2. Vocabulaire de fiabilite

- **SLI** : mesure observee, calculee uniquement a partir de telemetrie de production.
- **SLO** : cible associee a un SLI sur une fenetre glissante de 28 jours, sauf
  indication contraire.
- **Budget d'erreur** : `1 - SLO`. Pour un SLO de 99,9 %, le budget est de 0,1 % des
  requetes eligibles.
- **Requete eligible** : requete synthetique ou utilisateur valide, hors trafic de
  test identifie, bots bloques et requetes refusees avant l'application par le WAF.
- **Succes API** : reponse attendue en moins de 30 secondes. Les `5xx`, timeouts et
  erreurs de dependance comptent comme echecs ; un `4xx` metier attendu ne compte pas
  comme indisponibilite.
- **Tentative de lecture** : emission de `playback_start_requested` suivie d'une
  demande de licence pour un contenu autorise.
- **Session de lecture valide** : session ayant joue au moins 10 secondes, hors
  bande-annonce et tests internes identifies.

Les maintenances planifiees restent dans le calcul : elles affectent les utilisateurs
comme tout autre arret. Une panne fournisseur n'est pas exclue si elle rend le
parcours EkeFlicks indisponible. Les exclusions exceptionnelles doivent etre
documentees dans un post-mortem et approuvees conjointement par les responsables
produit et exploitation.

## 3. SLO du pilote

### 3.1 Cibles et modes de calcul

| Parcours / service | SLI et formule | SLO sur 28 jours | Source de verite |
|---|---|---:|---|
| API critique : authentification, profils, abonnement, licence et progression | `requetes reussies / requetes eligibles` par route et globalement | >= 99,9 % | metriques serveur au point d'entree API |
| API catalogue : accueil, recherche, fiche | disponibilite selon la meme formule | >= 99,5 % | metriques serveur au point d'entree API |
| Latence API critique | p95 de la duree serveur, hors temps de transfert media | < 500 ms | histogrammes serveur |
| Latence catalogue | p95 de la duree serveur, hors images | < 300 ms | histogrammes serveur |
| Licence de lecture | licences valides emises en moins de 2 s / demandes autorisees | >= 99,5 % | API de licence et traces distribuees |
| Demarrage video | p75 entre `playback_start_requested` et `playback_started` | < 3 s | evenements client correles |
| Echec de lecture | sessions sans `playback_started` sous 10 s, ou terminees par erreur avant 60 s / tentatives | < 1,0 % | analytics QoE et erreurs player |
| Rebuffering | somme du temps de buffering apres demarrage / somme du temps de lecture | < 1,0 % | battements et fin de session player |
| Progression et reprise | mises a jour visibles sur un second appareil en moins de 30 s / mises a jour valides | >= 99,0 % | tests synthetiques et API progression |
| Paiement confirme | webhooks valides traites une seule fois en moins de 60 s / webhooks valides recus | >= 99,9 % | journal immuable de webhooks |
| Reconciliation paiement | paiements fournisseur relies a un etat interne explicable | 100 % avant J+1 09:00 UTC | rapprochement finance quotidien |
| Client | sessions sans crash / sessions ouvertes | >= 99,5 % par plateforme/version | crash reporting |
| Publication media | contenus publies ayant passe tous les controles techniques | 100 % | pipeline media et registre de publication |

Les percentiles sont calcules globalement et segmentes par plateforme, version
d'application, type de reseau, pays, FAI et contenu. Un bon resultat global ne masque
pas un segment certifie sous la cible : tout segment representant au moins 5 % du
trafic ou 100 sessions sur la fenetre est examine separement.

### 3.2 Alertes et budget d'erreur

Chaque SLO dispose d'un tableau de bord, d'un proprietaire et d'un runbook avant le
pilote. Pour les SLO de disponibilite, des alertes de consommation du budget utilisent
au minimum deux fenetres :

- **page urgente** : consommation projetee au moins 14,4 fois trop rapide sur 1 h,
  confirmee sur 5 min ;
- **ticket prioritaire** : consommation projetee au moins 6 fois trop rapide sur 6 h,
  confirmee sur 30 min ;
- **revue hebdomadaire** : budget restant, principales causes et segments affectes.

Si plus de 50 % du budget mensuel est consomme, les changements a risque sont geles
et l'equipe priorise la fiabilite. A 100 %, seuls les correctifs, retours arriere et
changements de securite urgents sont deployes jusqu'au retour sous la trajectoire.
Le responsable d'incident peut ordonner un rollback sans validation produit.

### 3.3 Dependances, continuite et securite

- Sauvegardes PostgreSQL chiffrees quotidiennes : **RPO <= 24 h** pour le pilote.
- Restauration complete exercee avant lancement : **RTO <= 4 h** mesure du debut de
  l'exercice a la validation fonctionnelle.
- Aucune vulnerabilite critique ou haute connue n'est ouverte au lancement ; une
  critique decouverte en production declenche confinement immediat et incident P0.
- Les secrets, jetons, donnees de paiement et donnees personnelles ne figurent ni
  dans les evenements analytics ni dans les logs applicatifs.

## 4. Contrat des evenements analytics

### 4.1 Enveloppe commune

Tous les noms sont en `snake_case`, en anglais, au passe pour un resultat et au
present participial uniquement pour un etat. Chaque evenement contient :

| Champ | Type | Regle |
|---|---|---|
| `event_id` | UUID | unique, genere a la source et utilise pour dedupliquer |
| `event_name` | chaine | nom de la taxonomie ci-dessous |
| `event_version` | entier | commence a 1 ; incremente pour tout changement incompatible |
| `occurred_at` | ISO 8601 UTC | heure de l'action a la source |
| `received_at` | ISO 8601 UTC | ajoutee par le collecteur |
| `anonymous_id` | UUID | present avant authentification, non reutilise entre installations |
| `user_id` | UUID nullable | identifiant interne pseudonymise, jamais l'email |
| `profile_id` | UUID nullable | present pour toute action dans un profil |
| `session_id` | UUID | session applicative, renouvelee apres 30 min d'inactivite |
| `playback_session_id` | UUID nullable | obligatoire pour tous les evenements de lecture |
| `platform` | enum | `web`, `android_mobile` ou `android_tv` pour le MVP |
| `app_version` | chaine | version et numero de build |
| `environment` | enum | `staging` ou `production` ; jamais melanges dans les KPI |
| `country` | ISO 3166-1 alpha-2 | derive cote serveur si necessaire |
| `consent_analytics` | booleen | etat du consentement a l'emission |
| `schema_revision` | chaine | revision du schema valide par le pipeline |

Les proprietes communes optionnelles sont `device_class`, `os_version`,
`network_type`, `correlation_id`, `experiment_ids` et `is_internal`. Les dimensions
libres, URLs completes, requetes de recherche brutes et messages d'erreur non filtres
sont interdits afin de limiter cardinalite et donnees personnelles.

### 4.2 Taxonomie MVP

| Evenement | Moment d'emission | Proprietes metier obligatoires |
|---|---|---|
| `sign_up_started` | formulaire d'inscription affiche apres action utilisateur | `entry_point` |
| `sign_up_completed` | compte cree par le serveur | `verification_required` |
| `email_verified` | verification acceptee par le serveur | `verification_method` |
| `login_succeeded` | session authentifiee | `auth_method` |
| `login_failed` | tentative rejetee | `reason_code`, sans identifiant saisi |
| `plan_viewed` | offres affichees | `plan_ids`, `currency` |
| `checkout_started` | redirection/SDK fournisseur lance | `plan_id`, `provider`, `currency`, `amount_minor` |
| `payment_succeeded` | webhook verifie et etat interne confirme | `payment_id`, `plan_id`, `provider`, `currency`, `amount_minor` |
| `payment_failed` | echec definitif confirme cote serveur | champs precedents et `reason_code` |
| `subscription_cancelled` | resiliation enregistree | `plan_id`, `effective_at`, `reason_code` |
| `profile_selected` | profil actif confirme | `profile_type` |
| `home_viewed` | accueil rendu avec au moins une rangee | `row_count`, `personalized` |
| `search_submitted` | recherche envoyee | `query_length`, `result_count`, `normalized_query_hash` |
| `content_detail_viewed` | fiche rendue | `content_id`, `content_type`, `source`, `rank` |
| `favorite_added` | serveur confirme l'ajout | `content_id`, `content_type` |
| `playback_start_requested` | utilisateur demande la lecture | `content_id`, `content_type`, `source`, `position_ms` |
| `playback_license_granted` | licence recue | `content_id`, `drm_type`, `latency_ms` |
| `playback_started` | premiere frame video rendue | `content_id`, `startup_time_ms`, `bitrate_kbps`, `cdn` |
| `playback_heartbeat` | toutes les 30 s de lecture active | `content_id`, `position_ms`, `played_ms`, `buffered_ms`, `bitrate_kbps` |
| `playback_buffering_started` | buffering apres premiere frame | `content_id`, `position_ms` |
| `playback_buffering_ended` | reprise apres buffering | `content_id`, `position_ms`, `buffering_duration_ms` |
| `playback_quality_changed` | changement de rendition | `content_id`, `from_bitrate_kbps`, `to_bitrate_kbps`, `reason_code` |
| `playback_failed` | erreur empechant ou terminant la lecture | `content_id`, `stage`, `reason_code`, `retryable` |
| `playback_ended` | fin, sortie ou arret definitif | `content_id`, `end_reason`, `position_ms`, `played_ms`, `buffered_ms` |
| `progress_synced` | progression acceptee par le serveur | `content_id`, `position_ms`, `sync_latency_ms` |
| `resume_started` | lecture reprise depuis une progression serveur | `content_id`, `saved_position_ms`, `device_changed` |

`payment_succeeded`, `payment_failed`, `email_verified` et
`subscription_cancelled` sont des evenements serveur faisant foi. Le client ne doit
jamais determiner seul la conversion ni le droit de lecture. Les codes d'erreur sont
des enums documentes (`network`, `timeout`, `entitlement_denied`, `license_error`,
`manifest_error`, `decoder_error`, `unknown`) et non des messages arbitraires.

### 4.3 KPI derives

- **Conversion inscription** = utilisateurs avec `sign_up_completed` / utilisateurs
  avec `sign_up_started` sur une cohorte de 24 h.
- **Conversion payante** = utilisateurs avec `payment_succeeded` / utilisateurs avec
  `checkout_started`, ventilee par fournisseur, plan, plateforme et pays.
- **Taux de demarrage** = `playback_started` / `playback_start_requested`.
- **Temps de demarrage** = `playback_started.occurred_at -
  playback_start_requested.occurred_at`, controle par `startup_time_ms`.
- **Ratio de rebuffering** = somme `buffering_duration_ms` / somme `played_ms`.
- **Completion** = sessions atteignant 90 % de la duree du contenu / sessions
  demarrees, hors generiques ignores si cette information est disponible.
- **Reprise reussie** = `resume_started` a +/- 30 s de la derniere progression serveur
  / tentatives de reprise.
- **Retention J7/J30** = utilisateurs ayant une session de lecture valide au jour
  cible / utilisateurs de la cohorte de premiere lecture.
- **Churn volontaire** = abonnements avec `subscription_cancelled` / abonnements
  actifs au debut de la periode ; les echecs de renouvellement sont mesures a part.

Les KPI financiers proviennent du registre de paiement reconcilie, pas du pipeline
produit. Les vues producteur proviennent des sessions de lecture valides dedupliquees,
avec une regle de remuneration distincte et auditable.

### 4.4 Qualite, consentement et retention

- Le collecteur valide le schema, place les evenements invalides en quarantaine et
  publie le taux d'acceptation. Cible : **>= 99,5 %** recus sous 5 minutes et
  **>= 99,9 %** recus sous 24 h.
- La deduplication porte sur `event_id`. Un evenement hors ligne conserve
  `occurred_at`; les battements peuvent etre agreges avant envoi.
- Les tests internes ont `is_internal=true` et sont exclus des KPI mais conserves
  dans un jeu de donnees de validation separe.
- Sans consentement analytics, seuls les journaux strictement necessaires a la
  securite, au paiement et a la fourniture du service sont traites. Aucun evenement
  marketing ou d'experimentation n'est emis.
- La duree de retention, la base legale, les droits d'acces/suppression et la liste
  des sous-traitants doivent etre valides juridiquement avant production. A defaut,
  le lancement est bloque ; une valeur ne doit pas etre inventee par l'equipe
  technique.
- Toute nouvelle propriete passe une revue donnees, securite et cardinalite. Un
  dictionnaire versionne indique proprietaire, finalite, source et date de retrait.

## 5. Criteres d'acceptation fonctionnels

Chaque scenario doit passer sur staging avec les API, stockage, worker, paiement en
bac a sable et chaine media reels. Les plateformes certifiees executent le meme lot,
sauf mention explicite.

| ID | Etant donne / Quand / Alors | Preuve requise |
|---|---|---|
| AC-01 | Etant donne une adresse inutilisee, quand le visiteur s'inscrit et confirme le lien, alors il peut se connecter et aucun compte premium n'est cree avant paiement. | test E2E et evenements inscription/verification |
| AC-02 | Etant donne un lien expire ou deja utilise, quand il est ouvert, alors l'acces est refuse sans enumeration de compte et un renvoi peut etre demande. | test API/securite |
| AC-03 | Etant donne un plan disponible, quand le fournisseur confirme un paiement signe, alors l'abonnement devient actif une seule fois et le recu est rapprochable. | test integration webhook, doublon et journal finance |
| AC-04 | Etant donne un webhook invalide, rejoue ou recu dans le desordre, quand il est traite, alors il ne cree ni droit ni double paiement et produit une alerte exploitable. | tests signature, idempotence et ordre |
| AC-05 | Etant donne un abonnement actif, quand l'utilisateur cree/selectionne un profil, alors seuls ses profils sont accessibles et le profil reste actif apres redemarrage. | test E2E et test IDOR |
| AC-06 | Etant donne un profil, quand l'accueil, la recherche et une fiche sont ouverts, alors les donnees viennent de l'API, respectent publication/droits et chaque etat vide, chargement et erreur offre une action utile. | tests widget, API et capture des requetes |
| AC-07 | Etant donne un contenu non publie, hors territoire, hors fenetre ou sans abonnement, quand une licence est demandee, alors le serveur refuse meme si le client est modifie. | tests permissions et entitlement |
| AC-08 | Etant donne un contenu autorise, quand Lecture est active, alors une licence et une URL signee a duree courte sont emises, le manifest HLS reel demarre et aucun secret n'apparait dans les logs. | E2E player et inspection logs/reseau |
| AC-09 | Etant donne un reseau coupe ou degrade pendant la lecture, quand il revient, alors le player affiche l'etat, retente avec une limite, reprend sans crash et emet une telemetrie QoE coherente. | test reseau degrade par plateforme |
| AC-10 | Etant donne 60 s regardees, quand l'utilisateur quitte puis ouvre un second appareil, alors la reprise propose une position a +/- 30 s en moins de 30 s et ne regresse pas face a une mise a jour plus recente. | E2E multi-appareil |
| AC-11 | Etant donne la fin d'un contenu, quand 90 % sont atteints, alors il est marque termine et n'est pas propose comme reprise incomplete. | test API et E2E |
| AC-12 | Etant donne un abonnement actif, quand l'utilisateur resilie, alors la date d'effet est explicite, aucun renouvellement ulterieur n'est accepte et l'acces suit la politique affichee. | E2E, webhook et reconciliation |
| AC-13 | Etant donne deux utilisateurs/producteurs, quand l'un modifie les identifiants d'une requete, alors aucune donnee, progression, contenu prive ou statistique de l'autre n'est revelee. | suite d'autorisation/IDOR |
| AC-14 | Etant donne un media candidat, quand il est publie, alors antivirus, transcodage, manifest, renditions, audio, sous-titres, duree, miniature et droits ont un statut valide ; sinon la publication est atomiquement refusee. | test pipeline et registre QC |
| AC-15 | Etant donne un refus de consentement analytics, quand le parcours est execute, alors aucun evenement optionnel n'est collecte et le service essentiel reste utilisable. | inspection reseau et stockage |
| AC-16 | Etant donne une version client precedente encore supportee, quand l'API est deployee, alors le contrat OpenAPI reste compatible ou le deploiement est bloque. | test de contrat CI |

## 6. Criteres non fonctionnels et go/no-go

### 6.1 Preuves obligatoires avant pilote

- CI verte sur le commit candidat : lint, tests backend et Flutter, migrations,
  contrats OpenAPI, analyse de dependances/secrets et builds des plateformes ciblees.
- Tous les AC-01 a AC-16 automatises quand cela est raisonnable ; toute etape
  manuelle possede une procedure, un resultat date et un responsable.
- Test de charge sur login, accueil, recherche, licence et progression au pic prevu
  multiplie par deux, sans violation des objectifs de latence ni saturation durable.
- Test d'endurance d'au moins 8 h et test de reseau degrade sur chaque plateforme.
- Paiement : succes, refus, timeout, abandon, doublon, webhook invalide, ordre inverse,
  remboursement et resiliation rapproches.
- Exercice de restauration respectant RPO/RTO, rollback applicatif et migration de
  base testes sur staging.
- Dashboards, alertes, astreinte, contacts fournisseurs et runbooks pour API, player,
  paiement, media, base et stockage verifies par un exercice d'incident.
- Revue securite independante terminee ; zero finding critique/haut ouvert et risques
  moyens acceptes nominativement avec echeance.
- Politique de confidentialite, consentement, retention et suppression valides par
  les responsables juridique/securite ; droits catalogue valides pour le pilote.
- Support dispose des procedures de diagnostic, remboursement, resiliation et
  escalade, sans acces direct non audite aux donnees de production.

### 6.2 Decision de lancement

Le **go** exige simultanement :

1. 100 % des criteres d'acceptation obligatoires passes sur le build candidat ;
2. sept jours consecutifs de mesure synthetique sur staging sans violation durable
   des SLO et avec une collecte analytics conforme ;
3. aucun bug P0/P1, vulnerabilite critique/haute ou ecart financier non explique ;
4. signatures produit, engineering, exploitation, securite et finance/juridique ;
5. proprietaire, alerte et runbook associes a chaque SLO critique.

La decision est **no-go** si une preuve manque. Une derogation n'est possible que
pour un critere hors parcours critique : elle est ecrite, datee, limitee dans le
temps, assortie d'un rollback et signee par le proprietaire du risque. Aucun ecart de
controle d'acces, entitlement, paiement, donnees personnelles, restauration ou
telemetrie critique ne peut faire l'objet d'une derogation.

## 7. Responsabilites et cadence

| Objet | Responsable (role) | Cadence |
|---|---|---|
| SLO API, licence, progression | backend / SRE | revue hebdomadaire et apres incident |
| QoE video et pipeline media | equipe playback/media | quotidienne pendant pilote |
| Crash et compatibilite client | equipe Flutter | par version et quotidienne |
| Paiement et reconciliation | billing + finance | quotidienne avant 09:00 UTC |
| Taxonomie et KPI produit | product analytics | revue de schema avant chaque release |
| Consentement et retention | privacy/securite + juridique | avant lancement puis trimestrielle |
| Go/no-go et arbitrage budget | product owner + engineering lead | a chaque release pilote |

Les noms des personnes, rotations d'astreinte, capacite cible, pays, fournisseur de
paiement et seuil de trafic doivent etre renseignes dans le dossier de lancement. Ce
document definit le minimum commun ; le dossier fournit les valeurs operationnelles
qui ne peuvent pas etre deduites du depot.
