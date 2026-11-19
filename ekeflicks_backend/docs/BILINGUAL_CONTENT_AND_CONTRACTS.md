# Traductions FR/EN des contenus et documents

## DeepL

1. Créer un compte DeepL API (Developer/API Free ou Growth selon le volume).
2. Dans le compte DeepL, ouvrir **Account → API Keys & Limits → Create key**.
3. Sur le serveur, ajouter dans `ekeflicks_backend/.env` (ne jamais committer cette valeur) :

   ```env
   DEEPL_AUTH_KEY=<clé API>
   DEEPL_API_URL=https://api-free.deepl.com/v2/translate
   ```

   Utiliser l’URL API indiquée par DeepL si le forfait exige un autre endpoint.
4. Redémarrer les workers Celery après mise à jour de l’environnement.

Les traductions de contenu, genres et cahier des charges sont déclenchées après enregistrement. Les textes sources restent la référence. Chaque traduction stocke l’empreinte de ses sources; une modification rend la traduction précédente obsolète jusqu’à la fin de la nouvelle tâche. Une erreur DeepL est réessayée par Celery.

Après avoir configuré la clé et redémarré Celery, traduire aussi les fiches déjà enregistrées avec la commande :

    docker compose exec -T django python manage.py translate_existing_metadata

## Nouvelle version du contrat

Le contenu source du contrat reste en français. À chaque sauvegarde d’un brouillon, Celery prépare automatiquement le texte anglais et associe les deux langues à l’empreinte exacte du contenu source. La version française est conservée à l’identique. Dans l’administration, vérifier le JSON `canonical_content_translations`, relire le titre et le texte anglais, puis mettre `reviewed` à `true` sur l’entrée `en`. La publication est refusée tant que les traductions françaises et anglaises ne correspondent pas aux empreintes du titre et du texte contractuel actuels et que l’anglais n’est pas marqué comme vérifié. Après publication, le texte et la version sont immuables; les métadonnées de traduction peuvent être complétées. Toute modification de fond demande une nouvelle version.

Pour traduire la version déjà publiée, sélectionner cette version dans l’administration, puis utiliser l’action **Generate or refresh bilingual draft translation**. Relire ensuite l’anglais et marquer son entrée comme vérifiée.

Un contrat en attente est présenté dans la langue sélectionnée. Le PDF effectivement présenté est conservé avec son empreinte; le PDF signé n’est jamais régénéré ou remplacé par une traduction ultérieure.

## Rémunération producteur

Le contrat v2 indique 1 000 FCFA pour 1 000 vues éligibles, 60 % des revenus publicitaires nets attribués au contenu, et un seuil de paiement de 50 000 FCFA. Au taux BCEAO de 655,957 FCFA pour 1 EUR, les valeurs initiales sont environ 1,524490 EUR / 1 000 vues et 76,224509 EUR de seuil.

Le contrat ne donne pas de durée minimale de visionnage : il renvoie aux règles techniques. La règle actuellement configurable est 30 % de la durée du film ou de l’épisode. Les réglages globaux sont administrables dans `ProducerRevenueSetting`. Les revenus publicitaires doivent être enregistrés par contenu avec le montant net effectivement encaissé; le système calcule et réserve la part du producteur. L’import automatisé depuis une régie publicitaire dépendra du connecteur de cette régie.
