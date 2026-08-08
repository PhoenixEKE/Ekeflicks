# API

## Documentation interactive

- Swagger : `/swagger/`
- Redoc : `/redoc/`
- Schema JSON : `/swagger.json`
- Alias stable pour les outils : `/openapi.json`

## Contrats transverses

Toutes les routes metier sont versionnees dans leur URL (`/api/v1/`). Un client peut
egalement envoyer `X-API-Version: 1`. Chaque reponse expose `X-API-Version`,
`API-Supported-Versions` et un `X-Request-ID` reutilisable dans les journaux et les
demandes au support. Une autre version explicite est refusee avec le code
`unsupported_api_version`; une future v2 sera publiee sous `/api/v2/` sans modifier
le comportement de v1.

Les collections paginees acceptent `page` et `page_size` (maximum 100) et renvoient :

```json
{
  "count": 42,
  "next": "https://api.ekeflicks.com/api/v1/contents/?page=2",
  "previous": null,
  "page": 1,
  "page_size": 20,
  "total_pages": 3,
  "results": []
}

## Routes actives

| Route | Role |
| --- | --- |
| `/` | Health check |
| `/health/` | Health check |
| `/admin/` | Administration Django |
| `/api/v1/avatars/` | Liste publique des avatars disponibles |
| `/api/v1/auth/` | Authentification |
| `/api/v1/` | API metier EkeFlicks |

## Organisation du code

Les routes metier sont separees par app Django dans `backend/apps/` :

- `apps/catalog`
- `apps/profiles`
- `apps/playback`
- `apps/billing`
- `apps/recommendations`
- `apps/notifications`
- `apps/analytics`
- `apps/streaming`

## Authentification

Endpoints actuels :

- `POST /api/v1/auth/login/`
- `POST /api/v1/auth/register/`
- `POST /api/v1/auth/refresh/`
- `POST /api/v1/auth/token/refresh/`
- `GET /api/v1/auth/me/`
- `GET/PATCH /api/v1/auth/personal-info/`
- `GET/POST /api/v1/auth/verify-email/`
- `POST /api/v1/auth/resend-email-verification/`
- `POST /api/v1/auth/password-reset/request/`
- `POST /api/v1/auth/password-reset/confirm/`
- `/api/v1/auth/email-change-support-requests/`
- `/api/v1/auth/email-change-support-requests/{id}/cancel/`
- `/api/v1/auth/email-change-support-requests/{id}/resolve/`
- `/api/v1/auth/email-change-support-requests/{id}/reject/`
- `POST /api/v1/auth/logout/`
- `/api/v1/auth/account-closure-requests/`
- `/api/v1/auth/account-closure-requests/{id}/cancel/`
- `/api/v1/auth/account-closure-requests/{id}/process/`
- `/api/v1/auth/account-closure-requests/process-due/`

Les demandes de fermeture couvrent `deactivate_account`, `delete_account` et `cancel_subscription`. Le traitement automatique utilise `ACCOUNT_CLOSURE_GRACE_DAYS`.

A l'inscription, un token de validation email est cree et un lien est envoye via email. Le champ `is_verified` permet aux apps de savoir si l'email est valide.

`personal-info` permet de modifier `firstname`, `lastname`, `phone` et `country_code`. L'email reste en lecture seule. Une modification d'email passe par `email-change-support-requests`, puis le support/admin marque la demande `resolved` ou `rejected` avec un motif.

Le reset password se fait en deux etapes : `password-reset/request` envoie un lien contenant le token, puis `password-reset/confirm` applique le nouveau mot de passe.

## Catalogue

Lecture publique. L'ecriture est reservee au staff et aux producteurs sur leurs propres contenus.

- `/api/v1/genres/`
- `/api/v1/emissions/`
- `/api/v1/content-statuses/`
- `/api/v1/contents/`
- `/api/v1/contents/search/`
- `/api/v1/contents/home/`
- `/api/v1/contents/mine/`
- `/api/v1/contents/producer-dashboard/`
- `/api/v1/contents/pending-submissions/`
- `/api/v1/contents/popular/`
- `/api/v1/contents/trending/`
- `/api/v1/contents/top-10/`
- `/api/v1/contents/new-releases/`
- `/api/v1/contents/{id}/seasons/`
- `/api/v1/contents/{id}/similar/`
- `/api/v1/contents/{id}/submit/`
- `/api/v1/contents/{id}/approve-submission/`
- `/api/v1/contents/{id}/reject-submission/`
- `/api/v1/contents/{id}/upload-poster/`
- `/api/v1/contents/{id}/upload-backdrop/`
- `/api/v1/contents/{id}/upload-trailer/`
- `/api/v1/seasons/`
- `/api/v1/episodes/`

Les endpoints `mine` et `producer-dashboard` servent l'espace producteur. Un producteur peut creer, modifier, soumettre et enrichir uniquement les contenus dont il est proprietaire. Les saisons et episodes suivent la meme regle de propriete via le contenu parent.

Les endpoints `pending-submissions`, `approve-submission` et `reject-submission` sont reserves au staff. Un refus exige un motif dans `reason`.

Les endpoints `upload-poster`, `upload-backdrop` et `upload-trailer` sont accessibles au staff et au producteur proprietaire du contenu. Ils stockent d'abord le fichier dans MinIO `uploads/producer_{id}/...`, publient la version finale vers B2, puis mettent a jour `poster_url`, `backdrop_url` ou `trailer_url` avec l'URL CDN.

`/api/v1/contents/home/` renvoie des rangees pretes pour l'accueil : hero, continuer a regarder, recommandations, tendances, top 10, nouveautes, films, series et genres dynamiques.

`/api/v1/contents/search/` fournit une recherche avancee avec filtres `q`, `type`, `genre`, `emission`, `year`, `min_year`, `max_year`, `min_rating`, `age_rating`, `is_hd`, `is_4k` et `ordering`.

Filtres utiles sur `/api/v1/contents/` :

- `q`
- `type`
- `genre`
- `emission`
- `status`
- `producer_status`
- `submission_status`
- `year`
- `min_year`
- `max_year`
- `is_hd`
- `is_4k`
- `ordering`

## Avatars

`GET /api/v1/avatars/` est public afin que les clients puissent proposer le choix
d'un avatar avant l'inscription. La reponse contient `avatars`, une liste d'objets
avec `name`, `path` et l'URL publique `url` issue du stockage d'avatars configure.

La gestion du catalogue d'avatars est reservee aux comptes staff :

- `POST /api/v1/avatars/` accepte un formulaire multipart contenant l'image `file`
  et, facultativement, `name`, puis publie le fichier sous `catalog/` dans le bucket
  B2 configure par `B2_AVATAR_BUCKET` ;
- `DELETE /api/v1/avatars/{path}/` supprime du bucket l'objet designe par le champ
  `path` renvoye par la liste ou par l'ajout.


## Utilisateur connecte

Routes protegees par JWT.

- `/api/v1/profile-types/`
- `/api/v1/profiles/`
- `/api/v1/favorites/`
- `/api/v1/watch-history/`
- `/api/v1/watch-history/continue-watching/`
- `/api/v1/ratings/`
- `/api/v1/lists/`
- `/api/v1/list-items/`
- `/api/v1/recommendations/`
- `/api/v1/recommendations/{id}/mark-viewed/`
- `/api/v1/recommendations/engine-status/`
- `/api/v1/recommendations/sync-graph/`
- `/api/v1/recommendations/generate/`
- `/api/v1/notifications/`
- `/api/v1/notifications/{id}/mark-read/`
- `/api/v1/notifications/mark-all-read/`
- `/api/v1/viewing-sessions/`

Les recommandations peuvent etre generees avec le fallback Django ou avec Neo4j si `RECOMMENDATION_ENGINE=neo4j` et `NEO4J_ENABLED=True`.

`POST /api/v1/recommendations/sync-graph/` synchronise le profil, son historique, ses favoris, ses notes, les contenus et les genres vers Neo4j.

`POST /api/v1/recommendations/generate/` calcule les recommandations et alimente la table `Recommendation`.

## Abonnements et paiements

- `/api/v1/subscription-plans/`
- `/api/v1/subscriptions/`
- `/api/v1/payments/`
- `/api/v1/producer-payout-requests/`
- `/api/v1/producer-payout-requests/balance/`
- `/api/v1/producer-payout-requests/{id}/approve/`
- `/api/v1/producer-payout-requests/{id}/reject/`
- `/api/v1/producer-payout-requests/{id}/mark-paid/`
- `/api/v1/producer-payout-requests/set-global-remuneration/`
- `/api/v1/producer-payout-requests/set-producer-remuneration/`
- `/api/v1/billing/webhooks/{provider}/`

Les plans sont lisibles publiquement si actifs. Les modifications de plans sont reservees au staff.

Une creation d'abonnement par le client demarre en statut `pending`. Une creation de paiement reprend le montant et la devise du plan, puis demarre aussi en statut `pending`. La validation finale doit passer par le backend, l'administration ou un webhook fournisseur.

Fournisseurs prevus :

- `cinetpay`
- `paystack`
- `flutterwave`
- `wave`

Le webhook doit etre signe. Si le secret du fournisseur n'est pas configure, l'evenement est refuse et conserve comme non traite.

Paiements producteurs :

- une vue est eligible quand la session atteint au moins 30% de la duree totale du film ou episode ;
- le tarif par defaut est `1.5 EUR / 1000 vues` ;
- le seuil, le tarif et le minimum de paiement sont modifiables dans l'admin via `ProducerRevenueSetting` ;
- la devise locale est calculee via `ProducerCountryCurrency`, modifiable dans l'admin ;
- les admins peuvent desactiver la remuneration globalement ou pour un producteur.

## Streaming et offline

- `/api/v1/video-assets/`
- `/api/v1/video-assets/mine/`
- `/api/v1/video-assets/producer-dashboard/`
- `/api/v1/video-assets/pending-submissions/`
- `/api/v1/video-assets/{id}/upload-source/`
- `/api/v1/video-assets/{id}/upload-subtitle/`
- `/api/v1/video-assets/{id}/start-transcode/`
- `/api/v1/video-assets/{id}/approve/`
- `/api/v1/video-assets/{id}/reject/`
- `/api/v1/video-assets/{id}/publish/`
- `/api/v1/video-assets/{id}/unpublish/`
- `/api/v1/video-assets/{id}/manifest/`
- `/api/v1/video-assets/{id}/license/`
- `/api/v1/video-assets/{id}/offline-license/`
- `/api/v1/video-assets/{id}/drm-key/`
- `/api/v1/video-assets/{id}/request-offline/`
- `/api/v1/offline-licenses/`
- `/api/v1/offline-licenses/{id}/revoke/`

La lecture renvoie un manifest HLS/DASH au lecteur, jamais le fichier source. Le manifest contient des URLs CDN signees quand `STREAMING_SIGNED_URLS_ENABLED=True`.

`POST /api/v1/video-assets/{id}/license/` cree une licence courte duree pour un profil et un appareil. Avec `offline=true`, la licence devient persistante pour mobile. `POST /api/v1/video-assets/{id}/offline-license/` est l'alias dedie pour Android/iOS.

Champs utiles pour la licence :

- `profile_id`
- `device_id`
- `device_type`
- `platform` : `android`, `ios`, `web` ou `tv`
- `drm_system` : `widevine`, `fairplay`, `playready` ou `aes_128`
- `offline`

`GET /api/v1/video-assets/{id}/drm-key/?license_token=...` renvoie la cle AES-128 uniquement si la licence est active et non expiree. Widevine, FairPlay et PlayReady restent branches via les URLs de fournisseur configurees dans `.env`.

Avec `drm_provider=axinom`, la reponse `drm` renvoie la configuration Multi-DRM :

- Android : Widevine + licence offline persistante.
- iOS : FairPlay + certificat FairPlay + licence offline persistante.
- TV/Web : PlayReady ou Widevine selon la demande client et les URLs configurees.
- `entitlement_token` : token signe cote backend pour transmettre les droits de lecture au fournisseur DRM.

`POST /api/v1/video-assets/{id}/upload-subtitle/` publie un fichier `.vtt` ou `.srt` vers le bucket B2 des sous-titres et cree ou met a jour la piste `SubtitleTrack`.

Le telechargement offline cree une licence limitee par profil, appareil et date d'expiration.

Workflow admin/producteur :

1. Le producteur cree ou met a jour son contenu.
2. Le producteur ajoute les saisons/episodes si le contenu est une serie.
3. Le producteur cree un `VideoAsset` et envoie le fichier source via `upload-source`.
4. Le producteur soumet le contenu avec `submit`.
5. L'admin verifie les soumissions via `pending-submissions`.
6. L'admin lance `start-transcode`, verifie les renditions HLS, puis valide avec `approve` ou refuse avec `reject`.
7. L'admin publie avec `publish`.

Un rejet exige un motif. Une video ne peut pas etre publiee tant que `moderation_status` n'est pas `approved`. Les clients ne voient que les assets `ready`, `approved` et avec `published_at` defini.

## Analytics

- `/api/v1/daily-stats/`
- `/api/v1/daily-stats/dashboard/`
- `/api/v1/daily-stats/views-by-minute/`
- `/api/v1/daily-stats/views-by-country/`
- `/api/v1/daily-stats/clickhouse-status/`
- `/api/v1/producer-revenue-settings/`
- `/api/v1/producer-revenue-settings/current/`
- `/api/v1/producer-country-currencies/`
- `/api/v1/producer-content-views/`

`daily-stats` reste reserve aux administrateurs. Le dashboard et les vues producteur filtrent automatiquement les donnees pour un producteur non staff.

## Reponse health check

```json
{
  "status": "ok",
  "service": "ekeflicks-backend"
}
```
