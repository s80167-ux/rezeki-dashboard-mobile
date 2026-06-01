@echo off
setlocal

if exist "%~dp0run_config.local.bat" (
  call "%~dp0run_config.local.bat"
)

if "%REZEKI_API_BASE_URL%"=="" (
  echo Missing REZEKI_API_BASE_URL.
  echo Copy run_config.example.bat to run_config.local.bat and set your Railway backend URL.
  exit /b 1
)

if /I not "%REZEKI_API_BASE_URL:~0,8%"=="https://" (
  echo REZEKI_API_BASE_URL must start with https:// for Railway backend runs.
  echo Current value: %REZEKI_API_BASE_URL%
  exit /b 1
)

if /I not "%REZEKI_API_BASE_URL:~-4%"=="/api" (
  echo REZEKI_API_BASE_URL must end with /api.
  echo Current value: %REZEKI_API_BASE_URL%
  exit /b 1
)

if "%REZEKI_GOOGLE_SERVER_CLIENT_ID%"=="" (
  echo Missing REZEKI_GOOGLE_SERVER_CLIENT_ID.
  echo Set it in run_config.local.bat. Do not commit that file.
  exit /b 1
)

if "%REZEKI_DEVICE_ID%"=="" (
  echo Missing REZEKI_DEVICE_ID.
  echo Set it in run_config.local.bat.
  exit /b 1
)

echo Running Rezeki Dashboard with Railway backend...
echo API: %REZEKI_API_BASE_URL%
echo Device: %REZEKI_DEVICE_ID%
echo.

flutter run -d "%REZEKI_DEVICE_ID%" --dart-define=REZEKI_API_BASE_URL="%REZEKI_API_BASE_URL%" --dart-define=REZEKI_GOOGLE_SERVER_CLIENT_ID="%REZEKI_GOOGLE_SERVER_CLIENT_ID%"
