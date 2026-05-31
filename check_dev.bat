@echo off
setlocal

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

echo Checking Rezeki Dashboard Flutter app...
echo API: %REZEKI_API_BASE_URL%
echo.

flutter analyze
if errorlevel 1 exit /b 1

flutter test
if errorlevel 1 exit /b 1

echo.
echo Checks passed.
