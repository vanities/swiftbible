#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")"/.. && pwd)"
ENV_FILE="$ROOT_DIR/supabase/.env"

if [[ ! -f "$ENV_FILE" ]]; then
  echo "supabase/.env not found. Copy supabase/.env.example and fill in real values." >&2
  exit 1
fi

set -o allexport
source "$ENV_FILE"
set +o allexport

if [[ -z "${NGROK_AUTHTOKEN:-}" || -z "${NGROK_DOMAIN:-}" ]]; then
  echo "NGROK_AUTHTOKEN and NGROK_DOMAIN must be set in supabase/.env" >&2
  exit 1
fi

if docker ps -a --format '{{.Names}}' | grep -q '^swiftbible-ngrok$'; then
  docker stop swiftbible-ngrok >/dev/null 2>&1 || true
fi

docker run -d --rm \
  --name swiftbible-ngrok \
  -e NGROK_AUTHTOKEN="$NGROK_AUTHTOKEN" \
  ngrok/ngrok:alpine \
  http --domain="$NGROK_DOMAIN" http://host.docker.internal:54321
