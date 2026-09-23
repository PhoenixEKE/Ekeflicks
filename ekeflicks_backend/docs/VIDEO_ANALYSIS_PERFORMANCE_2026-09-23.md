# EKEFLICKS — point téléchargement et analyse vidéo

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

Ces constats décrivent le code GitHub, pas une vérification de l'image actuellement
déployée. Aucun temps de production récent n'a été fourni ou mesuré dans cette session.

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
Un test de suppression du fichier partiel est ajouté à la suite existante de
matérialisation ; cette suite Django complète n'a pas été exécutée localement.

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

## Suite à prioriser après les mesures

Les sondes cadence et images clés parcourent encore séparément le même fichier.
Une lecture commune des paquets pourrait réduire les lectures et la sortie
FFprobe ; elle nécessite des tests d'équivalence CFR/VFR, B-frames, timestamps
manquants, durées partielles et timeouts. Leur sortie est actuellement capturée
entièrement en mémoire : le plafond de 500 timestamps concerne seulement le
rapport final. Prioriser cette piste si `probe_parallel_wall` reste significatif.
Sinon, cibler l'étape dominante mesurée, sans diminuer les contrôles qualité.

Cette proposition n'effectue ni migration, ni fusion dans main, ni déploiement.
