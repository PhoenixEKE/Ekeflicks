# Stockage medias

Le backend utilise trois niveaux :

- MinIO : stockage temporaire interne et traitement.
- Backblaze B2 : stockage final production.
- CDN/DRM : diffusion securisee aux utilisateurs.

## Variables MinIO

```env
USE_B2_STORAGE=False
USE_B2_FINAL_STORAGE=True
MINIO_ACCESS_KEY=change-me
MINIO_SECRET_KEY=change-me
MINIO_BUCKET=ekeflicks-temp
MINIO_ENDPOINT=http://minio:9000
MINIO_USE_SSL=False
MINIO_REGION=us-east-1
STREAMING_STORE_PROCESSING_ARTIFACTS=True
STREAMING_SIGNED_URLS_ENABLED=True
STREAMING_SIGNED_URL_TTL_SECONDS=3600
MEDIA_CDN_BASE_URL=https://cdn.ekeflicks.com
```

## Variables Backblaze B2

```env
B2_KEY_ID=change-me
B2_APPLICATION_KEY=change-me
B2_BUCKET=ekeflicks-videos
B2_VIDEO_BUCKET=ekeflicks-videos
B2_POSTER_BUCKET=ekeflicks-posters
B2_BACKDROP_BUCKET=ekeflicks-backdrops
B2_TRAILER_BUCKET=ekeflicks-trailers
B2_AVATAR_BUCKET=ekeflicks-avatars
B2_SUBTITLE_BUCKET=ekeflicks-subtitles
B2_ENDPOINT=https://s3.us-west-005.backblazeb2.com
B2_REGION=us-west-005
```

## Organisation MinIO

Bucket interne :

```text
ekeflicks-temp/
|-- uploads/
|   `-- producer_{producer_id}/
|       `-- YYYY/MM/DD/
|           `-- asset_{asset_id}/
|               |-- video_original.mp4
|               |-- trailer_original.mp4
|               |-- poster.jpg
|               |-- backdrop.jpg
|               `-- metadata.json
|-- processing/
|   `-- {job_id}/
|       |-- source.mp4
|       |-- video_1080p.mp4
|       |-- video_720p.mp4
|       |-- video_480p.mp4
|       |-- audio.m4a
|       `-- thumbnails/
|           |-- frame_001.jpg
|           `-- frame_002.jpg
`-- cache/
    `-- recent/
```

## Organisation Backblaze B2

Buckets finaux :

```text
ekeflicks-videos/
|-- movies/
|   `-- {movie_id}/
|       |-- manifest.m3u8
|       |-- 1080p/
|       |   `-- segment_*.ts
|       |-- 720p/
|       |   `-- segment_*.ts
|       |-- 480p/
|       |   `-- segment_*.ts
|       `-- subtitles/
|           |-- fr.vtt
|           `-- en.vtt
`-- series/
    `-- {series_id}/
        `-- season_01/
            `-- episode_01/
                |-- manifest.m3u8
                |-- 1080p/
                |   `-- segment_*.ts
                |-- 720p/
                |   `-- segment_*.ts
                |-- 480p/
                |   `-- segment_*.ts
                `-- subtitles/
                    |-- fr.vtt
                    `-- en.vtt

ekeflicks-posters/{content_id}/poster_large.jpg
ekeflicks-backdrops/{content_id}/backdrop_1920x1080.jpg
ekeflicks-trailers/{content_id}/trailer_1080p.mp4
ekeflicks-avatars/users/user_{id}.jpg
ekeflicks-subtitles/{content_id}/fr.vtt
```

Endpoints media :

- `POST /api/v1/contents/{id}/upload-poster/`
- `POST /api/v1/contents/{id}/upload-backdrop/`
- `POST /api/v1/contents/{id}/upload-trailer/`
- `POST /api/v1/video-assets/{id}/upload-subtitle/`

Chaque endpoint utilise le meme modele : fichier entrant dans MinIO `uploads/producer_{id}/...`, copie finale dans le bucket B2 specialise, puis URL CDN enregistree dans le modele.

## Recommandation production

- Utiliser des URLs signees pour la lecture video.
- Ne pas exposer directement les fichiers originaux.
- Transcoder les videos en HLS/DASH avant publication.
- Separer stockage temporaire, stockage source et stockage public.

## Streaming HLS

Pipeline recommande :

```text
Producteur upload
        |
        v
MinIO / ekeflicks-temp / uploads
        |
        v
Validation admin
        |
        v
Celery + FFmpeg
        |
        v
MinIO / processing
        |
        v
Generation HLS/DASH
        |
        v
Transfert final vers B2
        |
        v
CDN + DRM
        |
        v
Flutter / Web / TV
```

Regles :

- Segmenter en HLS avec des segments courts, par defaut 6 secondes.
- Creer un manifest master avec plusieurs qualites.
- Garder le fichier source dans MinIO, espace prive de traitement.
- Publier seulement les manifests, segments HLS, sous-titres et assets finaux vers B2.
- Servir les URLs finales via CDN quand `STREAMING_CDN_BASE_URL` est configure.
- Signer les URLs CDN avec expiration avant de les renvoyer aux clients.
- Activer le chiffrement HLS AES-128 pour le MVP, puis Widevine/FairPlay/PlayReady pour une protection avancee.

La tache Celery `apps.streaming.tasks.transcode_video_asset_to_hls` prepare les renditions HLS a partir d'un `VideoAsset`.

Etapes backend :

1. `POST /api/v1/video-assets/` cree l'asset.
2. `POST /api/v1/video-assets/{id}/upload-source/` stocke la source dans `uploads/producer_{producer_id}/YYYY/MM/DD/asset_{asset_id}/`.
3. `POST /api/v1/video-assets/{id}/start-transcode/` lance FFmpeg via Celery.
4. Le worker lit la source depuis MinIO, conserve les artefacts dans `processing/{job_id}/` si `STREAMING_STORE_PROCESSING_ARTIFACTS=True`, genere les playlists et segments, puis publie vers B2 sous `movies/{movie_id}/` ou `series/{series_id}/season_XX/episode_XX/`.
5. `POST /api/v1/video-assets/{id}/approve/` valide la video.
6. `POST /api/v1/video-assets/{id}/publish/` rend l'asset lisible par les clients.

Le service Django et le worker Celery utilisent MinIO pour l'ingestion et B2 pour les fichiers finaux. La lecture finale doit utiliser les URLs B2 ou CDN.

## CDN et DRM

Variables :

```env
DRM_LICENSE_TTL_SECONDS=3600
DRM_MASTER_KEY=change-me
DRM_WIDEVINE_LICENSE_URL=
DRM_FAIRPLAY_LICENSE_URL=
DRM_FAIRPLAY_CERTIFICATE_URL=
DRM_PLAYREADY_LICENSE_URL=
DRM_ANDROID_OFFLINE_LICENSE_DAYS=30
DRM_IOS_OFFLINE_LICENSE_DAYS=30
AXINOM_DRM_ENABLED=False
AXINOM_TENANT_ID=
AXINOM_POLICY_ID=
AXINOM_COMMUNICATION_KEY_ID=
AXINOM_COMMUNICATION_KEY=
AXINOM_WIDEVINE_LICENSE_URL=
AXINOM_FAIRPLAY_LICENSE_URL=
AXINOM_FAIRPLAY_CERTIFICATE_URL=
AXINOM_PLAYREADY_LICENSE_URL=
```

Flux de lecture securise :

1. Le client demande `GET /api/v1/video-assets/{id}/manifest/`.
2. Le backend verifie le profil et l'abonnement.
3. Les URLs du manifest, des renditions et des sous-titres sont signees.
4. Le client demande `POST /api/v1/video-assets/{id}/license/` avec `profile_id` et `device_id`.
5. Pour HLS AES-128, le client utilise `key_url` pour recuperer la cle via `drm-key`.
6. Pour Widevine, FairPlay et PlayReady, le client utilise l'URL fournisseur configuree.
7. Pour Axinom, le client transmet aussi `entitlement_token` au module DRM selon la plateforme.

## Lecture offline

L'app mobile doit telecharger :

- le manifest autorise,
- les segments HLS,
- les sous-titres,
- une licence offline limitee.

Le backend cree une licence par profil et appareil. Cette licence contient une date d'expiration et peut etre revoquee.

Plateformes mobiles :

- Android utilise Widevine. La duree est controlee par `DRM_ANDROID_OFFLINE_LICENSE_DAYS`.
- iOS utilise FairPlay. La duree est controlee par `DRM_IOS_OFFLINE_LICENSE_DAYS` et le certificat vient de `AXINOM_FAIRPLAY_CERTIFICATE_URL` ou `DRM_FAIRPLAY_CERTIFICATE_URL`.
