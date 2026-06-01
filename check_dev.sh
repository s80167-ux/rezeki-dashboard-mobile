#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

if [ -f "$SCRIPT_DIR/run_config.local.sh" ]; then
  # shellcheck source=/dev/null
  source "$SCRIPT_DIR/run_config.local.sh"
fi

if [ -z "${REZEKI_API_BASE_URL:-}" ]; then
  case "${REZEKI_DEVICE_ID:-}" in
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
  echo "export REZEKI_GOOGLE_SERVER_CLIENT_ID=\"YOUR_WEB_CLIENT_ID.apps.googleusercontent.com\""
  echo
  exit 1
fi

echo "Checking Rezeki Dashboard Flutter app..."
echo "API: ${REZEKI_API_BASE_URL}"
echo

if [ "${REZEKI_SKIP_API_CHECK:-0}" != "1" ]; then
  api_host="$(printf '%s' "$REZEKI_API_BASE_URL" | sed -E 's#^https?://([^/:]+).*$#\1#')"
  api_port="$(printf '%s' "$REZEKI_API_BASE_URL" | sed -E 's#^https?://[^/:]+:([0-9]+).*$#\1#')"
  api_port="${api_port:-4000}"

  if ! timeout 1 bash -c "</dev/tcp/$api_host/$api_port" 2>/dev/null; then
    echo "API not reachable at ${api_host}:${api_port}"
    echo "Start the backend API before running the app."
    echo "Set REZEKI_SKIP_API_CHECK=1 only if you need to run the Flutter UI without the backend."
    exit 1
  fi

  echo "API reachability check passed."
  echo
else
  echo "Skipping API reachability check because REZEKI_SKIP_API_CHECK=1."
  echo
fi

flutter analyze
flutter test

echo
echo "Checks passed."
