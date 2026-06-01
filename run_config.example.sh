#!/bin/bash

# For a physical device, use your PC's current LAN IP.
# For an Android emulator, use http://10.0.2.2:4000/api.
# For desktop/web on the same machine, use http://localhost:4000/api.
export REZEKI_API_BASE_URL="http://YOUR_PC_LAN_IP:4000/api"
export REZEKI_DEVICE_ID="HMRG8HA679WGRO6H"
export REZEKI_GOOGLE_SERVER_CLIENT_ID="YOUR_WEB_CLIENT_ID.apps.googleusercontent.com"
# Optional: export REZEKI_SKIP_API_CHECK=1 to run the Flutter UI without the backend.
