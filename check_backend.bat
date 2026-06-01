@echo off
setlocal

if exist "%~dp0run_config.local.bat" (
  call "%~dp0run_config.local.bat"
)

if "%REZEKI_API_BASE_URL%"=="" (
  set "REZEKI_API_BASE_URL=http://10.0.2.2:4000/api"
)

set "REZEKI_HEALTH_URL=%REZEKI_API_BASE_URL%/health"

echo Checking backend health...
echo Health URL: %REZEKI_HEALTH_URL%
echo.

curl --fail --silent --show-error "%REZEKI_HEALTH_URL%"
if errorlevel 1 (
  echo.
  echo Backend is unreachable. Check REZEKI_API_BASE_URL in run_config.local.bat and make sure the backend is running.
  exit /b 1
)

echo.
echo Backend is reachable.
