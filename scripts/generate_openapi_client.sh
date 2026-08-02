#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
BACKEND="$ROOT/ekeflicks_backend/backend"
SCHEMA="$ROOT/ekeflicks_backend/openapi/ekeflicks-v1.json"
OUTPUT="$ROOT/plateforme_client"
IMAGE="${OPENAPI_GENERATOR_IMAGE:-openapitools/openapi-generator-cli:v7.14.0}"

mkdir -p "$(dirname "$SCHEMA")"
(
  cd "$BACKEND"
  DJANGO_SECRET_KEY="${DJANGO_SECRET_KEY:-schema-generation-only}" \
  DB_NAME="${DB_NAME:-schema}" DB_USER="${DB_USER:-schema}" \
  DB_PASSWORD="${DB_PASSWORD:-schema}" DB_HOST="${DB_HOST:-localhost}" \
    python manage.py generate_swagger "$SCHEMA" --format json --overwrite
)

# The container makes generation reproducible and does not require a global Java CLI.
docker run --rm \
  -v "$ROOT:/workspace" \
  "$IMAGE" generate \
  -i /workspace/ekeflicks_backend/openapi/ekeflicks-v1.json \
  -g dart-dio \
  -o /workspace/plateforme_client \
  -c /workspace/openapi-generator-config.yaml \
  --global-property apiDocs=false,modelDocs=false,apiTests=false,modelTests=false

dart format "$OUTPUT/lib/src"
echo "Schema et client EkeFlicks v1 regeneres."
