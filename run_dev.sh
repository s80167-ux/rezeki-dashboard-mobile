#!/bin/bash
set -euo pipefail

REZEKI_DEVICE_ID="${REZEKI_DEVICE_ID:-HMRG8HA679WGRO6H}"

if [ -f "$(dirname "$0")/run_config.local.sh" ]; then
  # shellcheck source=/dev/null
  source "$(dirname "$0")/run_config.local.sh"
fi

if [ -z "${REZEKI_API_BASE_URL:-}" ]; then
  case "$REZEKI_DEVICE_ID" in
    emulator-*)
      REZEKI_API_BASE_URL="http://10.0.2.2:4000/api"
      ;;
    windows|linux|macos|chrome|edge|web-server)
      REZEKI_API_BASE_URL="http://localhost:4000/api"
      ;;
    *)
      local_ip="$(hostname -I 2>/dev/null | awk '{print $1}')"
      REZEKI_API_BASE_URL="${local_ip:+http://$local_ip:4000/api}"
      REZEKI_API_BASE_URL="${REZEKI_API_BASE_URL:-http://localhost:4000/api}"
      ;;
  esac
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
if [ "${REZEKI_SKIP_API_CHECK:-0}" = "1" ]; then
  echo "API preflight: skipped"
fi
flutter run -d "$REZEKI_DEVICE_ID" \
  --dart-define=REZEKI_API_BASE_URL="$REZEKI_API_BASE_URL" \
  --dart-define=REZEKI_GOOGLE_SERVER_CLIENT_ID="$REZEKI_GOOGLE_SERVER_CLIENT_ID"
