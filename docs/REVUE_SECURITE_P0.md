# Revue de securite P0

**Date :** 1er aout 2026
**Perimetre :** backend Django et API REST, authentification, profils, catalogue/producteurs,
facturation, streaming/DRM, stockage, taches media et deploiement Docker Compose.
**Methode :** revue statique orientee abus, recherche de secrets et de primitives dangereuses,
lecture des controles d'acces, des frontieres de confiance et des tests existants. Aucun test
d'intrusion sur une infrastructure de production n'a ete realise.

## 1. Decision de lancement

**NO-GO pour une exposition publique en production.** La revue identifie quatre risques P0
ouverts. Ils permettent soit de contourner durablement le controle d'acces aux contenus, soit
d'exposer les donnees et secrets d'infrastructure. Les controles webhook constituent une bonne
base mais ne suffisent pas a rendre la plateforme exploitable publiquement.

Un P0 est ici un risque pouvant causer une compromission systemique, une fuite massive, un
contournement de revenu a grande echelle ou une perte irrecuperable, avec une voie d'exploitation
credible avant lancement.

## 2. Registre des constats P0

| ID | Constat | Impact | Preuve dans le depot | Statut / condition de sortie |
|---|---|---|---|---|
| P0-01 | Les objets S3/MinIO sont configures sans authentification d'URL (`querystring_auth=False`) tandis que les URLs de manifests/renditions sont stockees et retournees. La signature applicative ajoute des parametres `ef_*`, mais aucun validateur cote CDN/origine n'est present dans le depot. | Toute personne connaissant ou devinant une URL d'objet peut potentiellement contourner abonnement, expiration et DRM applicatif. Fuite du catalogue video et perte de revenus. | `config/settings.py` (`AWS_QUERYSTRING_AUTH`, options MinIO/B2), `apps/streaming/services.py` (`sign_streaming_url`), `apps/streaming/tasks.py` (URLs finales persistees). | **Ouvert.** Buckets prives; origine inaccessible directement; validation HMAC a l'edge/origine; signature couvrant hote, chemin, expiration et audience; test negatif d'URL nue; rotation d'un secret streaming distinct. |
| P0-02 | Compose publie PostgreSQL, Redis, MinIO, ClickHouse et potentiellement Neo4j sur toutes les interfaces. Redis n'utilise aucun mot de passe et MinIO autorise HTTP/TLS desactive par defaut. | Acces direct aux donnees, vol/modification de sessions/cache, execution de taches, exfiltration des medias et secrets; mouvement lateral complet si ce Compose est deploye sur un hote joignable. | `docker-compose.yml` (`ports` des services), `.env.example` (`REDIS_PASSWORD` vide, `MINIO_USE_SSL=False`). | **Ouvert.** Ne publier que le reverse proxy; supprimer les ports des donnees ou les lier a `127.0.0.1` dans une surcharge locale; authentification Redis; TLS/reseau prive; regles pare-feu verifiees par scan externe. |
| P0-03 | Les secrets streaming et DRM retombent sur `SECRET_KEY`; l'exemple fournit plusieurs valeurs `change-me` et l'application ne refuse pas le demarrage avec ces valeurs. | La compromission d'un seul secret permet de forger JWT, URL de streaming et cles DRM. Une configuration copiee depuis l'exemple rend les secrets previsibles. Rayon d'impact systemique et rotation couplee. | `config/settings.py` (`STREAMING_SIGNING_SECRET`, `DRM_MASTER_KEY`), `.env.example`. | **Ouvert.** Secrets distincts, aleatoires et obligatoires hors debug; refus des valeurs connues/faibles; coffre de secrets; procedure de rotation et revocation testee. |
| P0-04 | La protection des URLs signees n'est qu'une generation de parametres dans ce depot : le toggle peut desactiver les signatures, l'expiration vaut une heure et aucune preuve de validation par le CDN n'existe. La playlist HLS contient en outre des chemins de segments relatifs qui doivent etre proteges de la meme facon. | Partage/rejeu d'URL, acces direct aux segments et contournement de l'entitlement meme si le point de licence Django est correct. | `apps/streaming/services.py` (`signed_urls_enabled`, `sign_streaming_url`), `apps/streaming/tasks.py` (playlists/segments HLS), `.env.example`. | **Ouvert.** Signature obligatoire en production; jeton/cookie edge couvrant toute l'arborescence HLS; TTL court; anti-rejeu adapte; tests E2E depuis une origine non autorisee et apres expiration. |

## 3. Constats P1 a traiter avant la beta

| ID | Risque | Mesure exigee |
|---|---|---|
| P1-01 | `SECURE_SSL_REDIRECT=False` hors debug fait reposer HTTPS uniquement sur l'infrastructure, sans garde-fou applicatif. | Activer la redirection ou documenter/tester le contrat proxy; tester HSTS et en-tetes depuis Internet. |
| P1-02 | Swagger/Redoc et le schema sont publics en production, facilitant la reconnaissance. | Les desactiver par defaut hors debug ou les proteger par authentification/reseau d'administration. |
| P1-03 | Les validateurs Django de mot de passe ne sont pas appeles a l'inscription ni au reset; seule une longueur de 8 est imposee. | Appeler `validate_password`, tester mots communs/numeriques/similaires et conserver des messages non enumerants. |
| P1-04 | Les requetes login, inscription, reset, renvoi d'email et webhooks n'ont pas toutes un throttle explicite metier; le taux anonyme global ne remplace pas des quotas par identite/IP/route. | Throttles dedies, limites au proxy/WAF, backoff, alertes et tests de contournement distribue. |
| P1-05 | Le webhook persiste l'ensemble des en-tetes et du payload, y compris avant validation. Cela peut conserver signatures, PII et corps volumineux fournis par un attaquant. | Liste blanche/redaction, taille maximale avant parsing, retention courte des echecs et quota par fournisseur/IP. |
| P1-06 | Les dependances sont bornees par plages mais non verrouillees avec empreintes; aucune CI SCA/secrets n'est visible. | Lock reproductible, SBOM, Dependabot/Renovate, `pip-audit`, scanner de secrets et politique de correction. |
| P1-07 | `AWS_S3_VERIFY=False` et `verify=False` pour MinIO rendent possible l'interception si le trafic traverse une frontiere non sure. | TLS avec verification obligatoire hors environnement local et CA interne geree. |
| P1-08 | Docker utilise des tags mutables (`latest`) et monte le code source dans les conteneurs applicatifs. | Images immuables par digest, utilisateur non-root, systeme de fichiers lecture seule et aucun bind mount en production. |

## 4. Controles positifs observes

- `DJANGO_SECRET_KEY` est obligatoire quand `DEBUG=False`, ce qui evite le secret de
developpement implicite dans le cas nominal.
- Les permissions REST sont fermees par defaut (`IsAuthenticated`) et les querysets de profils,
lecture, notifications et facturation sont generalement filtres par utilisateur.
- Les refresh tokens tournent et sont blacklistes; les tokens de verification/reset sont a usage
unique et expires.
- Les webhooks refusent un secret absent et comparent les HMAC avec `compare_digest`; les
evenements sont journalises pour idempotence/audit.
- Les commandes FFmpeg utilisent une liste d'arguments sans shell, ce qui reduit l'injection de
commande directe.

Ces elements reduisent le risque, mais ne ferment aucun des quatre P0.

## 5. Plan de remediation et preuves attendues

### Dans les 48 heures

1. Confirmer par inventaire reseau que les ports de donnees ne sont exposes dans aucun
environnement partage; sinon les fermer, isoler les hotes et effectuer une rotation des secrets.
2. Rendre tous les buckets media prives et invalider les URLs/identifiants existants.
3. Generer des secrets distincts pour Django/JWT, streaming, DRM et chaque fournisseur; les
charger depuis un coffre, jamais depuis l'image ou le depot.

### Avant reouverture d'un staging Internet

1. Ajouter un profil de configuration production qui echoue au demarrage si une signature est
desactivee, si un secret est absent/faible/reutilise ou si TLS storage n'est pas verifie.
2. Implementer et documenter la validation CDN/origine pour manifests, segments, sous-titres et
cles; ajouter une suite E2E d'autorisation/expiration.
3. Separer Compose local et deploiement production, scanner les ports depuis un reseau externe.
4. Ajouter les tests d'autorisation croisee: utilisateur, profil, producteur, asset, licence,
appareil, abonnement expire et contenu territorialement indisponible.

### Critere GO

Le GO exige : **zero P0 ouvert**, zero vulnerabilite critique/haute exploitable au pentest,
preuves automatisees des controles d'entitlement et d'isolation, restauration testee, rotation
des secrets testee et validation par un responsable securite independant de l'implementation.

## 6. Limites

Cette revue ne prouve ni l'etat du pare-feu, du CDN, des buckets, des secrets reels, des comptes
cloud, ni celui des applications Flutter compilees. Les controles d'infrastructure absents du
depot sont marques non demontres, et non necessairement inexistants. Une revue dynamique du
staging puis un pentest independant restent obligatoires.
