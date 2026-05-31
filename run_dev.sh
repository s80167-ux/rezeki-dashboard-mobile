#!/bin/bash
set -euo pipefail

REZEKI_API_BASE_URL="${REZEKI_API_BASE_URL:-http://192.168.68.139:4000/api}"
REZEKI_DEVICE_ID="${REZEKI_DEVICE_ID:-HMRG8HA679WGRO6H}"

if [ -f "$(dirname "$0")/run_config.local.sh" ]; then
  # shellcheck source=/dev/null
  source "$(dirname "$0")/run_config.local.sh"
fi

if [ -z "${REZEKI_GOOGLE_SERVER_CLIENT_ID:-}" ]; then
  echo "Missing REZEKI_GOOGLE_SERVER_CLIENT_ID."
  echo
  echo "Create run_config.local.sh next to this script with:"
  echo 'export REZEKI_GOOGLE_SERVER_CLIENT_ID="YOUR_WEB_CLIENT_ID.apps.googleusercontent.com"'
  echo
  exit 1
fi

echo "Running Rezeki Dashboard with local backend..."
flutter run -d "$REZEKI_DEVICE_ID" \
  --dart-define=REZEKI_API_BASE_URL="$REZEKI_API_BASE_URL" \
  --dart-define=REZEKI_GOOGLE_SERVER_CLIENT_ID="$REZEKI_GOOGLE_SERVER_CLIENT_ID"
