#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

if [ -f "$SCRIPT_DIR/run_config.local.sh" ]; then
  # shellcheck source=/dev/null
  source "$SCRIPT_DIR/run_config.local.sh"
fi

if [ -z "${REZEKI_GOOGLE_SERVER_CLIENT_ID:-}" ]; then
  echo "Missing REZEKI_GOOGLE_SERVER_CLIENT_ID."
  echo
  echo "Create run_config.local.sh next to this script with:"
  echo "export REZEKI_GOOGLE_SERVER_CLIENT_ID=\"YOUR_WEB_CLIENT_ID.apps.googleusercontent.com\""
  echo
  exit 1
fi

echo "Checking Rezeki Dashboard Flutter app..."
echo "API: ${REZEKI_API_BASE_URL:-http://10.0.2.2:4000/api}"
echo

flutter analyze
flutter test

echo
echo "Checks passed."
