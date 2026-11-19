#!/usr/bin/env bash

# Aligne la base PostgreSQL sur les migrations versionnees du backend Django.
set -Eeuo pipefail

SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
BACKEND_DIR="$(cd -- "${SCRIPT_DIR}/.." && pwd)"
BACKUP_DIR="${BACKUP_DIR:-${BACKEND_DIR}/backups}"
SKIP_BACKUP=false

usage() {
  cat <<'EOF'
Usage: ./scripts/update_database.sh [--no-backup] [--backup-dir CHEMIN]

Crée une sauvegarde PostgreSQL, affiche le plan Django, applique les migrations
versionnées puis vérifie le backend. À lancer depuis n'importe quel répertoire.

Options :
  --no-backup          Ne pas créer de sauvegarde (déconseillé en production).
  --backup-dir CHEMIN  Dossier de destination des sauvegardes.
  -h, --help           Afficher cette aide.
EOF
}

while (($#)); do
  case "$1" in
    --no-backup)
      SKIP_BACKUP=true
      shift
      ;;
    --backup-dir)
      [[ $# -ge 2 ]] || { echo "Erreur : --backup-dir exige un chemin." >&2; exit 2; }
      BACKUP_DIR="$2"
      shift 2
      ;;
    -h|--help)
      usage
      exit 0
      ;;
    *)
      echo "Erreur : option inconnue : $1" >&2
      usage >&2
      exit 2
      ;;
  esac
done

command -v docker >/dev/null 2>&1 || {
  echo "Erreur : Docker est requis." >&2
  exit 1
}

cd "$BACKEND_DIR"
[[ -f .env ]] || {
  echo "Erreur : ${BACKEND_DIR}/.env est absent (copiez .env.example puis configurez-le)." >&2
  exit 1
}
docker compose version >/dev/null 2>&1 || {
  echo "Erreur : le plugin Docker Compose est requis." >&2
  exit 1
}

echo "==> Démarrage et attente de PostgreSQL"
docker compose up -d --wait postgres

if [[ "$SKIP_BACKUP" == false ]]; then
  mkdir -p "$BACKUP_DIR"
  timestamp="$(date -u +'%Y%m%dT%H%M%SZ')"
  backup_file="${BACKUP_DIR}/ekeflicks_${timestamp}.dump"
  echo "==> Sauvegarde PostgreSQL : ${backup_file}"
  docker compose exec -T postgres sh -eu -c \
    'pg_dump --format=custom --no-owner --no-acl --username="$POSTGRES_USER" --dbname="$POSTGRES_DB"' \
    >"$backup_file"
  [[ -s "$backup_file" ]] || {
    echo "Erreur : la sauvegarde est vide." >&2
    rm -f "$backup_file"
    exit 1
  }
else
  echo "==> Sauvegarde ignorée (--no-backup)"
fi

echo "==> Vérification des modèles et du projet"
docker compose run --rm django python manage.py check
docker compose run --rm django python manage.py makemigrations --check --dry-run

echo "==> Plan des migrations"
docker compose run --rm django python manage.py migrate --plan

echo "==> Application des migrations versionnées"
docker compose run --rm django python manage.py migrate --noinput

echo "==> État final"
docker compose run --rm django python manage.py showmigrations
echo "Base de données mise à jour avec succès."
