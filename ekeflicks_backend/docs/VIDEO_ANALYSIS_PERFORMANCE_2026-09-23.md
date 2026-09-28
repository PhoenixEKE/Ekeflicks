# EKEFLICKS — point téléchargement et analyse vidéo

Finalisation de la proposition : 28 septembre 2026. Mesures locales réalisées le 23 septembre 2026.

Base inspectée : `PhoenixEKE/Ekeflicks`, branche `main`, commit
`227e557e9228943ef4afffa895743468b6f9c349` du 23 septembre 2026.
Checkpoint précédent : `0a48aee` (« G5-4C video analysis performance »).

## État vérifié dans le code

| Étape | Implémentation présente |
| --- | --- |
| Envoi du navigateur vers le stockage | Multipart, 3 workers, découpage du fichier navigateur ; confirmation après réception de toutes les parties. |
| Préparation de la source pour analyse | Chemin local réutilisé ; objet distant matérialisé dans le dossier temporaire de la tâche. |
| Contrôles vidéo et modération | Décodage vidéo partagé pour blackdetect/freezedetect et extraction des images ; contrôles en pleine résolution, échantillonnage modération toutes les 5 secondes. |
| Contrôles audio | Silence et loudness dans une branche exécutée en parallèle de la vidéo. |
| Cadence et images clés | Lecture des paquets sans décodage complet, deux sondes lancées en parallèle. |
| Mesures | Logs `G5_4_TIMING` par asset et étape ; logs `G5_4_QC_BRANCH` audio/vidéo. |

Les constats de code décrivent la branche proposée. Le 28 septembre, les logs fournis depuis le VPS ont mesuré une tâche à 675,607 s ; cela documente l'ancienne version déployée, pas la branche de cette PR. L'upload navigateur vers le stockage n'est pas chronométré dans ces logs.

## Correctif proposé : téléchargement S3 direct vers le fichier de travail

Avec le lecteur standard S3File de django-storages 1.14.6, `chunks()` déclenche
un téléchargement complet dans un SpooledTemporaryFile, puis recopie son contenu
vers le fichier utilisé par FFmpeg. Selon la configuration, ce spool reste en
mémoire ou déborde sur disque. Cette deuxième copie est évitable.

Le nouveau helper envoie le téléchargement géré par boto3 directement vers le
fichier de travail. Il conserve la clé déjà normalisée par le stockage, les
paramètres autorisés de téléchargement (dont ceux de chiffrement) et la
configuration de transfert existante. Les stockages avec gzip et les lecteurs
personnalisés conservent leur chemin de lecture habituel. En cas d'échec, le
fichier local partiel est supprimé et l'erreur remonte sans relancer un deuxième
téléchargement complet.

Gain attendu : suppression d'un tampon complet et d'une copie locale du master.
Le volume réseau du master reste identique. Aucun gain en secondes ou en
pourcentage n'est revendiqué avant mesure sur le VPS.

## Validation et mesure suivante

Six tests unitaires du helper exécutés avec succès localement : S3 direct,
paramètres/configuration conservés, copie générique, gzip, lecteur personnalisé,
erreur de transfert et objet vide (certains regroupés dans un même test).
Compilation Python et `git diff --check` réussis.
Le test de suppression du fichier partiel et la suite de matérialisation ont
ensuite été exécutés avec succès (voir validation consolidée ci-dessous).

Avant déploiement, exécuter les suites ciblées dans l'environnement backend :

```bash
python manage.py test apps.streaming.tests.test_source_download apps.streaming.tests.test_source_materialization apps.streaming.tests.test_frame_timing_probe apps.streaming.tests.test_trailer_analysis_task --settings=config.settings_test
```

Pour établir la référence sur le VPS (lecture seule, depuis `ekeflicks_backend`) :

```bash
docker compose logs --no-color --since 48h celery | grep -E 'G5_4_TIMING|G5_4_QC_BRANCH'
```

Comparer au moins trois analyses du même master avant/après dans les mêmes
conditions de charge. Distinguer : envoi navigateur, attente Celery,
`source_materialization`, `advanced_qc_with_moderation_extraction`,
`moderation_inference`, `probe_parallel_wall` et `total_analysis`.
Les deux temps de sonde sont parallèles : ne pas les additionner au temps mural
`probe_parallel_wall`. Les logs de branche QC n'ont pas d'asset : ne pas leur
attribuer un master si plusieurs analyses tournent simultanément.
Vérifier aussi l'identité du master et l'égalité des résultats de conformité,
des événements QC et des décisions de modération.

## Deuxième optimisation : une lecture de paquets commune

La proposition remplace, pour les masters, les deux processus FFprobe parallèles
par un seul processus lisant cadence et images clés. Les calculs QC existants
sont partagés avec les anciens helpers, conservés pour les trailers et la
comparaison. Les résultats et les tolérances CFR/VFR ne changent pas.

La sortie FFprobe est écrite dans un fichier temporaire automatiquement supprimé,
au lieu de conserver deux grandes chaînes stdout en mémoire. Les champs CSV sont
analysés une seule fois ; seules les lignes d'images clés sont gardées pour leur
calcul. Les échantillons numériques restent en mémoire pour la médiane exacte :
il ne s'agit pas d'une garantie de mémoire constante. Un scan échoué ou expiré
invalide les deux rapports et ignore les données partielles.

Le nouveau log `packet_probe_shared_wall` remplace les trois temps de la paire
pour les masters ; `analysis_pipeline.packet_probe_mode` indique `shared_scan`.
Comparer ce temps à l'ancien `probe_parallel_wall`, pas à la somme des deux sondes.

### Benchmark local reproductible

Fixture synthétique : 4 001 secondes, 25 fps, 160×90, H.264, **100 025 images**,
2 001 images clés, 1 511 866 octets ; FFprobe 6.1.1. Elle vérifie surtout le coût
CPU du parsing sur une longue séquence très compressible. Elle ne représente pas
un gros master UHD de production, ni le téléchargement depuis MinIO.

Résultat final sur **10 répétitions par méthode**, ordre alterné :

| Mesure | Ancienne paire parallèle | Lecture commune |
| --- | ---: | ---: |
| Temps médian des sondes | 0,491157 s | 0,434443 s |
| Résultats QC | Identiques | Identiques |

Réduction médiane locale : **11,55 % sur les sondes uniquement**. Cela représente
ici environ 0,057 seconde, pas 11,55 % du temps total d'analyse.
Une première variante à champs nommés et une variante qui découpait chaque ligne
deux fois ont été écartées après des mesures défavorables ou instables.
Les échantillons finaux sont dans `benchmarks/packet_probe_100025_frames.json`.

Reproduire la fixture dans un dossier temporaire :

```bash
ffmpeg -v error -f lavfi -i color=size=160x90:rate=25 -t 4001 -c:v libx264 -preset ultrafast -threads 1 -g 50 -bf 0 /tmp/packet-benchmark-100025.mp4
python manage.py benchmark_video_probes /tmp/packet-benchmark-100025.mp4 --repetitions 10 --settings=config.settings_test
```

La même commande accepte un master local existant pour mesurer les deux méthodes
sur le VPS. Elle ne modifie ni le fichier vidéo ni la base. Elle refuse les
résultats QC différents ou indisponibles. Elle mesure les sondes, sans uploader,
relancer une tâche Celery ni modifier un rapport de production.

## Mesure de secours sans master réel : benchmark synthétique

La commande `python manage.py benchmark_video_pipeline --synthetic --duration-seconds 2400` génère temporairement une mire mobile H.264 1080p de 40 minutes, avec son, une plage noire, une plage silencieuse et une image figée en fin de vidéo. Elle exécute les fonctions QC de production, l’extraction des images de modération, l’inférence IA et la sonde FFprobe commune. Le fichier est supprimé à la fin, aucun asset ni rapport n’est créé, et aucune écriture en base n’est faite.

Sur le VPS, après déploiement du commit candidat et lorsque le worker est libre :

```bash
docker compose exec -T celery python manage.py benchmark_video_pipeline --synthetic --duration-seconds 2400 --width 1920 --height 1080 --fps 25
```

La sortie JSON sépare le temps de génération (exclu du total d’analyse), le QC, la résolution/chargement du modèle, l’inférence et les sondes. Le test utilise la CPU du VPS et peut prendre plusieurs minutes ; le lancer sans autre analyse vidéo en cours. Il mesure le décodage/QC sur la durée visée, mais pas l’envoi producteur, le téléchargement depuis le stockage, la matérialisation de la source ni le commit DB. Le contenu synthétique ne reproduit pas exactement le poids, le mouvement ou la complexité d’un master réel ; il sert à comparer les versions sur la même machine, pas à confirmer le délai de bout en bout sous 3 minutes.

## Troisième optimisation : sous-échantillonner la détection des événements QC

Les mesures Celery partagées le 28 septembre montrent 675,607 s de tâche totale
(11 min 15 s), dont 493,946 s pour QC vidéo et extraction de modération. Le
matérialisation de la source a pris 93,588 s ; les sondes FFprobe parallèles
53,455 s ; l'inférence de modération 20,149 s. L'entrée comptait 688 images
pour la modération à raison d'une image toutes les 5 s, ce qui suggère environ
57 minutes, mais la durée réelle du fichier n'a pas été confirmée. Cette mesure
ne comprend pas l'envoi initial du producteur.

Sur une fixture synthétique H.264 1920×1080, le filtre complet
`blackdetect`/`freezedetect` a été limité à 5 images/s. Comparaison de cinq
exécutions sur la même fixture : temps médian du segment FFmpeg QC et extraction
modération de 1,0261 s à 0,5318 s, soit −48,17 % sur ce segment de cette fixture.
Le décodage source continue à lire le flux ; l'extraction des images de
modération à une image toutes les 5 s reste inchangée. Cette mesure ne permet
pas d'extrapoler un temps total sur un master de production ni d'affirmer que la
cible de 3 minutes est atteinte.

Les événements longs de la fixture restent détectés avec les mêmes nombres.
Leurs bornes peuvent être quantifiées à 0,2 s ; des événements proches des seuils
2 s (noir) ou 3 s (freeze) peuvent changer de classification. À valider sur des
masters réels et avec les équipes de contrôle avant déploiement. Le débit vidéo,
le coût de décodage et l'inférence ne sont pas supprimés par ce changement.
Le champ `analysis_pipeline.qc_detection_fps` enregistre la cadence de contrôle.

### Validation consolidée et état GitHub

- 44 tests ciblés : téléchargement direct, matérialisation (dont nettoyage du
  fichier partiel), cadence, sonde commune et comparaison de la détection QC à 5 fps.
- Comparaison avec de vrais fichiers FFmpeg : CFR, VFR, B-frames et UHD 3840×2160.
- Comparaison exacte des rapports sur la fixture longue de 100 025 images.
- La suite complète avec PostgreSQL et le déploiement VPS restent à valider.
- Le run CI `35834671258` de la première version de la PR échoue avant les tests
  backend : `phonenumbers` manque dans `requirements.lock.txt`, alors qu'il est
  déclaré dans `requirements.txt`. Le job producteurs a 22 tests réussis et
  5 échecs concernant `review_required` ; clients et administrateurs passent.
  Les fichiers à l'origine de ces blocages ne sont pas modifiés par cette PR.

La prochaine mesure doit porter sur le même master d'environ 40 minutes, en
comparant la branche actuellement déployée et cette branche candidate sous une
charge similaire. Chronométrer séparément l'upload, l'attente Celery, le
téléchargement, le QC, l'inférence et le temps total ; vérifier aussi les écarts
d'événements. Le seuil de moins de 3 minutes n'est pas démontré par les mesures
disponibles.

Cette proposition n'effectue ni migration, ni fusion dans main, ni déploiement.
