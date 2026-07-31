#!/usr/bin/env bash

set -Eeuo pipefail

usage() {
  cat <<'EOF'
Usage: scripts/nettoyer_depot.sh [--apply] [--root CHEMIN]

Supprime les artefacts retires lors du nettoyage EkeFlicks :
  - backend/test_media (medias et segments generes par les tests) ;
  - sauvegardes Python historiques (*.old et *.save ciblees) ;
  - rapport de build Android suivi par erreur ;
  - copie de provider et ancien ecran TV orphelins.

Par securite, le script est en mode simulation par defaut. Utiliser --apply pour
effectuer les suppressions. CHEMIN doit etre la racine d'un depot EkeFlicks.
EOF
}

apply=false
root='.'

while (($#)); do
  case "$1" in
    --apply)
      apply=true
      shift
      ;;
    --root)
      [[ $# -ge 2 ]] || { echo 'Erreur: --root attend un chemin.' >&2; exit 2; }
      root=$2
      shift 2
      ;;
    -h|--help)
      usage
      exit 0
      ;;
    *)
      echo "Erreur: option inconnue: $1" >&2
      usage >&2
      exit 2
      ;;
  esac
done

root=$(cd "$root" 2>/dev/null && pwd -P) || {
  echo "Erreur: repertoire inaccessible: $root" >&2
  exit 2
}

# Evite une suppression dans un mauvais repertoire ou a la racine du serveur.
if [[ ! -f "$root/ekeflicks_backend/backend/manage.py" ]] ||
   [[ ! -f "$root/plateforme_client/pubspec.yaml" ]]; then
  echo "Erreur: $root ne ressemble pas a la racine du depot EkeFlicks." >&2
  exit 3
fi

targets=(
  'ekeflicks_backend/backend/test_media'
  'ekeflicks_backend/backend/config/settings.py.save'
  'ekeflicks_backend/backend/config/urls.py.old'
  'ekeflicks_backend/backend/core/models/users.py.old'
  'plateforme_client/android/build/reports/problems/problems-report.html'
  'plateforme_client/lib/providers/profile_provider copy.dart'
  'plateforme_client/lib/ui/users/tv_post_login_page'
)

declare -a existing=()
file_count=0

for relative in "${targets[@]}"; do
  absolute="$root/$relative"
  if [[ -d "$absolute" ]]; then
    count=$(find "$absolute" -type f -print | wc -l | tr -d ' ')
    file_count=$((file_count + count))
    existing+=("$relative/ ($count fichier(s))")
  elif [[ -e "$absolute" || -L "$absolute" ]]; then
    file_count=$((file_count + 1))
    existing+=("$relative")
  fi
done

if ((${#existing[@]} == 0)); then
  echo "Depot deja propre: aucun des artefacts cibles n'existe dans $root."
  exit 0
fi

echo "Racine: $root"
echo "Fichiers detectes: $file_count"
printf '  - %s\n' "${existing[@]}"

if [[ "$apply" != true ]]; then
  echo
  echo 'Simulation uniquement: aucun fichier supprime.'
  echo "Relancer avec --apply --root '$root' pour confirmer."
  exit 0
fi

for relative in "${targets[@]}"; do
  absolute="$root/$relative"
  if [[ -e "$absolute" || -L "$absolute" ]]; then
    rm -rf -- "$absolute"
  fi
done

echo "Nettoyage termine: $file_count fichier(s) supprime(s)."

# Informe sans echouer si le depot source est encore gere par Git.
if git -C "$root" rev-parse --is-inside-work-tree >/dev/null 2>&1; then
  echo 'Verifier les suppressions avec: git status --short'
fi
