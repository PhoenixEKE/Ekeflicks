# Modeles

## Utilisateurs

### User

Modele utilisateur personnalise.

Champs principaux :

- `email`
- `firstname`
- `lastname`
- `phone`
- `country_code`
- `is_active`
- `is_verified`
- `is_producer`
- `producer_company`
- `producer_remuneration_enabled`
- `preferences`

### UserSession

Gestion des appareils connectes.

- `device_id`
- `device_type`
- `refresh_token`
- `expires_at`
- `is_active`

### AccountClosureRequest

Demande de fermeture ou suppression :

- `user`
- `request_type`
- `status`
- `requested_for`
- `processed_at`

## Profils

### Profile

Profils associes a un utilisateur.

- `name`
- `avatar_url`
- `age`
- `phone`
- `country_code`
- `pin_code`
- `is_active`

### ProfileType

Types de profils :

- `main`
- `child`
- `guest`

## Catalogue

### Content

Film ou serie.

- `title`
- `original_title`
- `description`
- `synopsis`
- `type`
- `poster_url`
- `backdrop_url`
- `banner_url`
- `video_url`
- `trailer_url`
- `release_year`
- `duration`
- `rating_avg`
- `view_count`
- `ia_score`
- `trending_score`
- `producer`
- `producer_submission_status`
- `producer_notes`
- `review_reason`
- `submitted_at`
- `reviewed_by`
- `reviewed_at`

### Genre

Categories cinematographiques.

### Emission

Categories d'emissions.

### ContentStatus

Statut de publication.

## Series

### Season

Saison rattachee a un contenu de type serie.

### Episode

Episode rattache a une saison.

## Streaming

### VideoAsset

Source video et manifests HLS/DASH rattaches a un contenu ou episode.

- `content`
- `episode`
- `source_file_path`
- `source_file_url`
- `source_uploaded_by`
- `status`
- `moderation_status`
- `moderation_reason`
- `moderated_by`
- `published_at`

### VideoRendition

Rendition HLS/DASH par qualite.

### SubtitleTrack

Piste de sous-titres ou captions publiee vers le stockage final.

## Visionnage

- `WatchHistory`
- `ViewingSession`
- `ProducerContentView`
- `Favorite`
- `Rating`

## Abonnements

- `SubscriptionPlan`
- `Subscription`
- `Payment`
- `ProducerPayoutRequest`

## Remuneration producteur

- `ProducerRevenueSetting`
- `ProducerCountryCurrency`
- `ProducerContentView`

## Notifications

- `NotificationType`
- `Notification`

## Recommandations

- `Recommendation`
- `ContentSimilarity`
- `TrendingCache`
