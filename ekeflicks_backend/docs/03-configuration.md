diff --git a/ekeflicks_backend/docs/03-configuration.md b/ekeflicks_backend/docs/03-configuration.md
# Configuration
 
Le backend utilise un fichier `.env` a la racine de `ekeflicks_backend`.
 
 Ne jamais publier `.env`.
 
Pour la separation local/test/staging/production et les commandes de reference,
consulter [`../../docs/ENVIRONNEMENTS.md`](../../docs/ENVIRONNEMENTS.md).

 ## Variables principales
 
 | Variable | Role |
 | --- | --- |
 | `DJANGO_SECRET_KEY` | Cle secrete Django |
 | `DEBUG` | `False` en production |
 | `ALLOWED_HOSTS` | Domaines autorises |
 | `API_BASE_URL` | URL publique de l'API |
 | `FRONTEND_BASE_URL` | URL publique Web/Mobile utilisee dans les liens email |
 | `EMAIL_VERIFICATION_FRONTEND_PATH` | Chemin frontend pour valider un email |
 | `PASSWORD_RESET_FRONTEND_PATH` | Chemin frontend pour changer un mot de passe |
 | `DB_NAME` | Nom base PostgreSQL |
 | `DB_USER` | Utilisateur PostgreSQL |
 | `DB_PASSWORD` | Mot de passe PostgreSQL |
 | `DB_HOST` | Hote PostgreSQL |
 | `DB_PORT` | Port PostgreSQL |
 | `REDIS_HOST` | Hote Redis |
 | `REDIS_PORT` | Port Redis |
 | `MINIO_ENDPOINT` | Endpoint MinIO interne |
 | `MINIO_BUCKET` | Bucket temporaire interne, par defaut `ekeflicks-temp` |
 | `USE_B2_FINAL_STORAGE` | Active B2 comme stockage final des medias |
 | `B2_ENDPOINT` | Endpoint Backblaze B2 final |
 | `B2_VIDEO_BUCKET` | Bucket final videos HLS/DASH |
 | `B2_POSTER_BUCKET` | Bucket final posters |
 | `B2_BACKDROP_BUCKET` | Bucket final backdrops |
 | `B2_TRAILER_BUCKET` | Bucket final trailers |
 | `B2_AVATAR_BUCKET` | Bucket final avatars |
 | `B2_SUBTITLE_BUCKET` | Bucket final sous-titres |
 | `STREAMING_CDN_BASE_URL` | URL CDN utilisee pour diffuser les HLS |
 | `STREAMING_STORE_PROCESSING_ARTIFACTS` | Conserve les artefacts FFmpeg dans MinIO `processing/` |
 | `STREAMING_SIGNED_URLS_ENABLED` | Active la signature des URLs CDN |
 | `STREAMING_SIGNED_URL_TTL_SECONDS` | Duree de validite des URLs CDN signees |
 | `STREAMING_SIGNING_SECRET` | Secret HMAC pour signer les URLs CDN |
 | `MEDIA_CDN_BASE_URL` | URL CDN utilisee pour posters, backdrops, trailers et sous-titres |
 | `DRM_LICENSE_TTL_SECONDS` | Duree de validite des licences de lecture |
 | `DRM_MASTER_KEY` | Secret maitre pour deriver les cles AES-128 |
 | `DRM_WIDEVINE_LICENSE_URL` | URL du serveur Widevine externe |
 | `DRM_FAIRPLAY_LICENSE_URL` | URL du serveur FairPlay externe |
 | `DRM_FAIRPLAY_CERTIFICATE_URL` | URL du certificat FairPlay |
 | `DRM_PLAYREADY_LICENSE_URL` | URL du serveur PlayReady externe |
 | `DRM_ANDROID_OFFLINE_LICENSE_DAYS` | Duree des licences offline Android |
 | `DRM_IOS_OFFLINE_LICENSE_DAYS` | Duree des licences offline iOS |
 | `AXINOM_DRM_ENABLED` | Active les reponses Axinom Multi-DRM |
 | `AXINOM_TENANT_ID` | Tenant Axinom |
 | `AXINOM_POLICY_ID` | Politique Axinom appliquee aux licences |
 | `AXINOM_COMMUNICATION_KEY_ID` | Identifiant de cle Axinom pour signer les tokens |
 | `AXINOM_COMMUNICATION_KEY` | Secret de signature des tokens Axinom |
 | `AXINOM_WIDEVINE_LICENSE_URL` | URL Axinom Widevine |
 | `AXINOM_FAIRPLAY_LICENSE_URL` | URL Axinom FairPlay |
 | `AXINOM_FAIRPLAY_CERTIFICATE_URL` | Certificat FairPlay Axinom |
 | `AXINOM_PLAYREADY_LICENSE_URL` | URL Axinom PlayReady |
 | `RECOMMENDATION_ENGINE` | `django` ou `neo4j` |
 | `RECOMMENDATION_DEFAULT_LIMIT` | Nombre par defaut de recommandations generees |
 | `NEO4J_ENABLED` | Active le moteur graphe Neo4j |
 | `NEO4J_URI` | URI Bolt Neo4j |
 | `NEO4J_USERNAME` | Utilisateur Neo4j |
 | `NEO4J_PASSWORD` | Mot de passe Neo4j |
 | `NEO4J_DATABASE` | Base Neo4j |
 | `CLICKHOUSE_HOST` | Hote ClickHouse |
 
 ## Production
 
 Valeurs attendues :
 
 ```env
 DEBUG=False
 ALLOWED_HOSTS=api.ekeflicks.com,ekeflicks.com,www.ekeflicks.com
 API_BASE_URL=https://api.ekeflicks.com
 FRONTEND_BASE_URL=https://ekeflicks.com
 FRONTEND_BASE_URL=http://192.162.68.247:3000 POUR LE DEV
 USE_B2_FINAL_STORAGE=True
 STREAMING_CDN_BASE_URL=https://cdn.ekeflicks.com
 STREAMING_STORE_PROCESSING_ARTIFACTS=True
 STREAMING_SIGNED_URLS_ENABLED=True
 STREAMING_SIGNED_URL_TTL_SECONDS=3600
 MEDIA_CDN_BASE_URL=https://cdn.ekeflicks.com
 DRM_LICENSE_TTL_SECONDS=3600
 AXINOM_DRM_ENABLED=False
 RECOMMENDATION_ENGINE=django
 NEO4J_ENABLED=False
