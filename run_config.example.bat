@echo off

rem Copy this file to run_config.local.bat and update the values.
rem Do NOT commit run_config.local.bat.

rem For actual Railway backend, use:
rem set "REZEKI_API_BASE_URL=https://YOUR-RAILWAY-BACKEND-DOMAIN.up.railway.app/api"

rem For Android emulator local backend, use:
rem set "REZEKI_API_BASE_URL=http://10.0.2.2:4000/api"

rem For physical Android phone local backend, use:
rem set "REZEKI_API_BASE_URL=http://YOUR-PC-LAN-IP:4000/api"

set "REZEKI_API_BASE_URL=https://YOUR-RAILWAY-BACKEND-DOMAIN.up.railway.app/api"
set "REZEKI_DEVICE_ID=YOUR_ANDROID_DEVICE_ID"
set "REZEKI_GOOGLE_SERVER_CLIENT_ID=YOUR_WEB_CLIENT_ID.apps.googleusercontent.com"
