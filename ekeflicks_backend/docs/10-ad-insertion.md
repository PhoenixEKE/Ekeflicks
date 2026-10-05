# Régie publicitaire et insertion SSAI

## Formats pris en charge

- **Pré-roll** : avant le contenu. Le lecteur peut lire une création HTTPS, ou le moteur SSAI peut la joindre au flux.
- **Mid-roll** : aux repères en secondes enregistrés par film ou série dans une campagne. Le lecteur côté client met en pause le contenu pendant la création; en SSAI, le repère propre au titre est envoyé au moteur de stitching. Un ciblage sans titre garde les repères globaux historiques.
- **Sur pause** : visuel et CTA affichés par le lecteur lorsque la lecture s’arrête. Ce placement reste côté lecteur, y compris sur Android TV.
- Les lecteurs Android TV n’exécutent pas les créations vidéo côté client; ils acceptent une insertion SSAI et les publicités sur pause.

Le lecteur n’insère pas VAST directement côté client. Une URL VAST est transmise au moteur SSAI; pour un pré-roll ou mid-roll côté lecteur, l’administration demande une URL HTTPS de fichier vidéo exploitable par BetterPlayer.

Dans la régie, l’administrateur recherche les films et séries approuvés ayant une vidéo prête, les sélectionne par titre, puis configure les secondes de mid-roll pour chaque titre. L’API `GET /api/v1/admin/ad-campaigns/content-options/?search=...` alimente ce sélecteur; les campagnes renvoient `content_details` et `content_cue_points`. Les anciennes campagnes utilisent toujours `cue_points_seconds` comme repères globaux jusqu’à leur modification.

## Ciblage et choix du client

Les forfaits sans publicité n’appellent pas la sélection d’annonces. Les campagnes peuvent filtrer par pays, genre du contenu, centres d’intérêt issus de l’historique, âge adulte déclaré, période, priorité, poids et plafond quotidien.

Le pays et le genre du contenu servent au ciblage de contexte. L’historique et l’âge ne sont utilisés que pour un profil adulte ayant enregistré un consentement explicite dans ses réglages. Les profils enfant, les profils de moins de 18 ans et les profils sans âge adulte déclaré ne sont pas personnalisés. Un retrait de consentement arrête les nouvelles lectures comportementales.

L’application renseigne le pays du profil; le backend ne déduit pas de géolocalisation à partir d’un en-tête proxy non vérifié. Pour un ciblage géographique réseau, l’infrastructure doit fournir à Django une donnée vérifiée à la frontière CDN et l’équipe devra la relier à cette sélection.

## Contrat du moteur SSAI

Configurer ces valeurs côté serveur après avoir choisi un moteur SSAI :

- AD_SSAI_ENABLED=True
- AD_SSAI_SESSION_URL=https://ssai-provider.example/api/session
- AD_SSAI_API_KEY=REMPLACER_PAR_LE_SECRET_DU_MOTEUR si le moteur exige un jeton Bearer
- AD_SSAI_ALLOWED_HOSTS=manifest.vendor.example,cdn.vendor.example pour autoriser les domaines de manifests de session
- AD_SSAI_TIMEOUT_SECONDS=5

Quand une décision de pré-roll comprend des campagnes SSAI, le backend envoie au moteur un POST JSON avec le manifeste source signé, la session de lecture, le système DRM demandé et les repères publicitaires. Le moteur doit conserver l’autorisation du manifeste source et les paramètres DRM Axinom en insérant les créations et en retournant une session lisible. Il répond sous 15 secondes avec :

    {
      "session_id": "id-session-moteur",
      "manifest_url": "https://hôte-autorisé/session/manifest.mpd"
    }

Chaque entrée de breaks contient campaign_id, placement, creative_url (VAST ou vidéo), duration_seconds, name, advertiser, le CTA éventuel et, pour un mid-roll, cue_point_seconds. Les repères sont exprimés en secondes dans la ligne de temps du contenu. Le moteur doit préserver cette ligne de temps aux repères afin que l’overlay CTA du lecteur, y compris Android TV, reste synchronisé.

Le backend ne transmet ni clé DRM au moteur ni au lecteur. Il transmet uniquement un manifeste signé de durée courte, drm_system et l’identifiant d’asset/contenu. Le lecteur conserve sa configuration de licence Axinom et accepte le manifeste de session uniquement en HTTPS depuis un hôte autorisé. Un échec du moteur laisse continuer le film et utilise une création côté lecteur compatible si une campagne de secours est disponible.

Les placements SSAI « sur pause » sont refusés : une annonce de pause apparaît quand le client arrête le flux et ne constitue pas un segment à insérer dans le manifeste.

## Mesure et validation

Les campagnes côté lecteur rapportent demande, remplissage, impression, démarrage, quartiles, complétion, ignorer, clic et erreur. Pour les campagnes SSAI, le lecteur mesure l’impression/démarrage au début du pré-roll ou lorsqu’il atteint un repère mid-roll, puis la complétion lorsque la position du manifeste dépasse une durée de création déclarée. Les mesures quartiles SSAI dépendent des événements disponibles sur le moteur configuré.

Les rapports admin sont alimentés par les événements du lecteur et les vues/revenus enregistrés par le backend. Sans moteur configuré, le tableau admin affiche SSAI désactivé; aucun secret, endpoint ou déploiement n’est fourni par cette modification. Après configuration, vérifier les placements, les sous-titres, l’audio et le DRM Widevine, FairPlay, PlayReady sur appareils réels.
