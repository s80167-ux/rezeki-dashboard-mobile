#!/bin/bash
# Script to run Flutter app on a specific device with custom API base URL
device_id="HMRG8HA679WGRO6H"
api_url="http://192.168.68.139:4000/api"

flutter run -d "$device_id" --dart-define=REZEKI_API_BASE_URL="$api_url"
