# Modele de menaces EkeFlicks

**Version :** 1.0 — 1er aout 2026
**Approche :** decomposition des flux et STRIDE, completee par les abus metier propres au
streaming et au paiement. Ce document doit etre mis a jour a chaque nouvelle integration de
paiement, CDN/DRM, stockage ou plateforme cliente.

## 1. Objectifs de securite

1. Un contenu n'est lisible que par un utilisateur, profil, appareil et abonnement autorises,
pendant la fenetre et sur le territoire autorises.
2. Un paiement ou abonnement ne change d'etat qu'apres une preuve serveur authentique,
idempotente et reconciliable.
3. Les utilisateurs et producteurs ne peuvent lire ou modifier que leurs ressources; les actes
administratifs sont fortement authentifies et audites.
4. Les donnees personnelles, secrets, cles DRM et medias sources restent confidentiels et
minimises pendant tout leur cycle de vie.
5. La plateforme resiste a l'abus volumetrique sans bloquer inscription, paiement et lecture
legitimes.

## 2. Actifs et priorite

| Actif | Sensibilite | Consequence principale |
|---|---:|---|
| Cles Django/JWT, streaming, DRM, stockage et paiement | Critique | Compromission systemique, fraude, contenu dechiffre |
| Medias sources, renditions, manifests, segments et sous-titres | Critique | Piratage du catalogue et violation des droits |
| Etats de paiement, abonnements et remuneration producteur | Critique | Fraude et perte financiere/comptable |
| Comptes admin/producteur et jetons de session | Critique | Prise de controle privilegiee |
| PII utilisateur, historique, profils enfants, geolocalisation | Elevee | Atteinte a la vie privee et risque reglementaire |
| Disponibilite API, licences, origine/CDN et pipeline media | Elevee | Interruption de lecture ou publication |
| Logs, webhooks et analytics | Elevee | PII, falsification de preuve, injection de donnees |

## 3. Acteurs

- **Spectateur legitime**, avec ou sans abonnement; **enfant** soumis aux regles du profil.
- **Producteur legitime**, autorise uniquement sur son contenu.
- **Administrateur/support**, cible prioritaire du phishing et de l'escalade de privileges.
- **Attaquant Internet anonyme**, fraudeur au paiement, pirate de contenu ou bot.
- **Utilisateur/producteur malveillant**, disposant d'un JWT valide et cherchant une IDOR.
- **Fournisseurs** de paiement, email, stockage, CDN et DRM; leurs comptes ou canaux peuvent etre
compromis.
- **Interne malveillant** ou poste CI/operation compromis.

## 4. Architecture et frontieres de confiance

```text
[Applications Flutter / navigateur non fiables]
          | HTTPS + JWT                    frontiere A
          v
[WAF / reverse proxy / API Django] <---- [Fournisseurs paiement: webhooks]
          |                 |                    frontiere B
          |                 +--> [Email / notifications]
          | SQL / cache / jobs                   frontiere C
          v                 v
[PostgreSQL] [Redis/Celery] [ClickHouse/Neo4j]
          |
          | identifiants stockage                frontiere D
          v
[MinIO temporaire] --> [workers FFmpeg] --> [B2/origine] --> [CDN/DRM]
                                                  frontiere E
                                                       |
                                                       v
                                             [lecteur hostile]
```

- **A :** le client, ses champs, son `device_id`, ses URLs et son etat local sont controlables.
- **B :** un webhook est hostile tant que fournisseur, signature, fraicheur et idempotence ne sont
pas verifies.
- **C :** les reseaux de donnees ne doivent jamais etre joignables directement par Internet.
- **D :** un media uploade est hostile jusqu'aux controles type/taille/malware et au transcodage
sandboxe.
- **E :** le lecteur et l'URL livree peuvent etre copies; l'edge doit refaire l'autorisation
cryptographique, pas faire confiance au secret d'une URL opaque.

## 5. Flux critiques et controles requis

| Flux | Menace/abus | Controles requis | Preuve attendue |
|---|---|---|---|
| Inscription/login/reset | Enumeration, credential stuffing, token vole | Reponse non enumerante, throttles route/IP/identite, MFA admin, token court a usage unique, revocation des sessions apres reset | Tests 429, tests enumeration, journal d'alerte |
| Acces profil | IDOR vers un autre foyer/profil enfant | Filtrage serveur par utilisateur, permission objet, PIN parental cote serveur | Matrice de tests croises |
| Creation/moderation producteur | Substitution de `producer_id`, stored XSS, upload hostile | Ownership serveur, champs en lecture seule, sanitation au rendu, quarantaine et scan | Tests producteur A/B; echantillons EICAR/media corrompu |
| Licence de lecture | Abonnement simule, asset non publie, appareil/profile forge | Entitlement serveur transactionnel, etat publication/droits/territoire, liaison asset-profile-user-device, TTL court | Tests abonnement expire et asset non publie |
| Livraison HLS/DASH | URL partagee/rejouee, segments directs, hotlink | Buckets prives, origine verrouillee, jeton edge signe couvrant chemin/arborescence/audience/expiration, DRM | URL nue refusee; expiration/referrer non suffisant |
| Cle/licence DRM | Extraction/rejeu de cle, downgrade `drm_provider=none` | TLS, licence liee au contexte, politique DRM immuable apres publication, rotation/revocation, no-store | Tests de rejeu/downgrade et audit des cles |
| Webhook paiement | Fausse signature, rejeu, confusion fournisseur/reference/montant | HMAC sur octets bruts, fournisseur allowlist, fraicheur, unicite, verification API fournisseur, montant/devise attendus, machine d'etat monotone | Fixtures officielles et tests concurrence/rejeu |
| Transcodage | Bombe de decompression, epuisement CPU/disque, exploitation FFmpeg | Taille/duree/codec limites, sandbox sans reseau, quotas, timeout, image patchee, stockage temporaire purge | Tests charge/corruption, limites cgroup |
| Administration | Vol de session, CSRF/phishing, acte non attribuable | MFA resistant au phishing, RBAC moindre privilege, reseau admin, session courte, audit immuable, double validation financiere | Revue trimestrielle des acces et export d'audit |
| Suppression compte | Suppression d'un tiers, course/recuperation incomplete | Reauthentification, delai/revocation, job idempotent, inventaire des copies/retentions | Test E2E et rapport d'effacement |

## 6. Analyse STRIDE priorisee

| STRIDE | Scenario representatif | Impact | Priorite | Mesure principale |
|---|---|---:|---:|---|
| Spoofing | JWT/admin ou signature webhook forges via secret reutilise/faible | Critique | P0 | Secrets distincts en coffre, MFA admin, rotation |
| Tampering | Requete concurrente/rejouee modifie deux fois paiement ou remuneration | Critique | P0/P1 | Contrainte d'unicite, transaction/verrou, etats monotones, reconciliation |
| Repudiation | Un admin nie une moderation/remuneration; logs locaux modifiables | Eleve | P1 | Audit append-only distant avec acteur, correlation et horodatage |
| Information disclosure | Bucket/segments accessibles sans URL edge valide | Critique | P0 | Origine et buckets prives, controle edge obligatoire |
| Denial of service | Upload/FFmpeg, webhook ou login sature workers, disque ou DB | Eleve | P1 | WAF, quotas/taille, files separees, cgroups, backpressure |
| Elevation of privilege | Producteur change l'asset d'un autre ou appelle une action admin | Critique | P0/P1 | Permission objet et queryset, tests negatifs exhaustifs |

## 7. Abus metier a tester explicitement

1. Demander une licence pour un asset pret mais non publie, rejete ou appartenant a un territoire
non autorise.
2. Utiliser le profil d'un autre compte, reutiliser une licence sur un autre appareil ou apres
resiliation.
3. Ouvrir directement master playlist, rendition, segment, sous-titre et cle sans JWT/jeton edge,
puis apres expiration.
4. Remplacer l'identifiant de contenu/producteur pendant create/update/upload et moderation.
5. Rejouer deux webhooks simultanes; modifier montant, devise, reference ou fournisseur tout en
conservant une signature valide issue d'un autre message.
6. Envoyer un fichier enorme, polyglotte, tronque ou concu pour epuiser FFmpeg; verifier reseau,
CPU, disque et purge apres echec.
7. Enchainer reset/login/refresh/logout pour verifier revocation, rotation et absence
d'enumeration.
8. Tester chaque action admin avec anonyme, spectateur, producteur proprietaire, producteur tiers,
staff et superuser.

## 8. Hypotheses a valider

- Le reverse proxy termine TLS correctement et nettoie les en-tetes `X-Forwarded-*` venant
d'Internet.
- Le CDN sait valider les `ef_*` ou un autre jeton; cette capacite n'est pas demontree dans le
depot.
- Les buckets finaux et temporaires ne sont pas publics malgre `querystring_auth=False`.
- Les fournisseurs de paiement documentent exactement les algorithmes/en-tetes implementes et
une verification serveur de transaction est disponible.
- Les droits territoriaux, classification enfant et limites d'appareils sont definis hors du code
observe; ils ne doivent pas etre consideres acquis.

Toute hypothese non validee est traitee comme un controle absent pour la decision de lancement.

## 9. Exigences d'observabilite et reponse

Journaliser sans secret ni contenu sensible : echecs d'authentification, changements de role,
actions admin/producteur, creation/validation/revocation de licence, signature edge refusee,
webhook et transition financiere. Associer un identifiant de correlation, proteger l'integrite et
definir une retention. Alerter sur pics de 401/403/429, licences par compte/appareil, telechargement
de segments, signatures webhook invalides, nouvelles cles/admins et erreurs/purge media.

Runbooks minimaux : secret/JWT compromis, bucket rendu public, fraude webhook, compte admin pris,
fuite de cle DRM, ransomware base de donnees et saturation transcodage. Chaque runbook precise
proprietaire, isolation, rotation/revocation, conservation des preuves, communication et criteres
de retablissement.

## 10. Gouvernance du modele

Le responsable securite revoit ce document au minimum chaque trimestre et avant tout changement
de CDN, DRM, paiement, stockage, authentification ou role. Chaque menace prioritaire doit avoir un
proprietaire, une echeance et un test automatise ou une preuve d'infrastructure. Le registre P0 de
`docs/REVUE_SECURITE_P0.md` constitue la porte de lancement actuelle.
