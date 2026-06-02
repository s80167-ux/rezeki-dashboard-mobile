@echo off
setlocal

set "REZEKI_API_BASE_URL=http://10.0.2.2:4000/api"
set "REZEKI_DEVICE_ID=emulator-5554"

if exist "%~dp0run_config.local.bat" (
  call "%~dp0run_config.local.bat"
)

if "%REZEKI_GOOGLE_SERVER_CLIENT_ID%"=="" (
  echo Missing REZEKI_GOOGLE_SERVER_CLIENT_ID.
  echo.
  echo Create run_config.local.bat next to this script with:
  echo set "REZEKI_GOOGLE_SERVER_CLIENT_ID=YOUR_WEB_CLIENT_ID.apps.googleusercontent.com"
  echo.
  exit /b 1
)

if /I "%REZEKI_GOOGLE_SERVER_CLIENT_ID%"=="YOUR_WEB_CLIENT_ID.apps.googleusercontent.com" (
  echo REZEKI_GOOGLE_SERVER_CLIENT_ID is still the placeholder value.
  echo Set it to the real Google Web OAuth client ID in run_config.local.bat.
  echo.
  exit /b 1
)

echo Running Rezeki Dashboard...
echo API: %REZEKI_API_BASE_URL%
echo Device: %REZEKI_DEVICE_ID%
if /I "%REZEKI_SKIP_API_CHECK%"=="1" echo API preflight: skipped

call "%~dp0check_dev.bat"
if errorlevel 1 exit /b 1

flutter run -d "%REZEKI_DEVICE_ID%" ^
  --dart-define=REZEKI_API_BASE_URL=%REZEKI_API_BASE_URL% ^
  --dart-define=REZEKI_GOOGLE_SERVER_CLIENT_ID=%REZEKI_GOOGLE_SERVER_CLIENT_ID%
