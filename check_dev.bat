@echo off
setlocal

if exist "%~dp0run_config.local.bat" (
  call "%~dp0run_config.local.bat"
)

if "%REZEKI_API_BASE_URL%"=="" (
  set "REZEKI_API_BASE_URL=http://10.0.2.2:4000/api"
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

echo Checking Rezeki Dashboard Flutter app...
echo API: %REZEKI_API_BASE_URL%
echo.

if /I "%REZEKI_SKIP_API_CHECK%"=="1" (
  echo Skipping API reachability check because REZEKI_SKIP_API_CHECK=1.
) else (
  powershell -NoProfile -ExecutionPolicy Bypass -Command "$url = [Uri]'%REZEKI_API_BASE_URL%'; $result = Test-NetConnection -ComputerName $url.Host -Port $url.Port -WarningAction SilentlyContinue; if ($result.TcpTestSucceeded) { Write-Host ('API reachable at ' + $url.Host + ':' + $url.Port); exit 0 }; $localHosts = @('localhost', '127.0.0.1') + @(Get-NetIPAddress -AddressFamily IPv4 -ErrorAction SilentlyContinue | Where-Object { $_.IPAddress -notlike '127.*' } | Select-Object -ExpandProperty IPAddress); if ($localHosts -contains $url.Host) { $listeners = Get-NetTCPConnection -State Listen -LocalPort $url.Port -ErrorAction SilentlyContinue; if (-not $listeners) { Write-Host ('No local server is listening on port ' + $url.Port + '.'); Write-Host 'Start the backend API before running the app.'; exit 2 }; $listenerAddresses = @($listeners | Select-Object -ExpandProperty LocalAddress -Unique); Write-Host ('Port ' + $url.Port + ' is listening on: ' + ($listenerAddresses -join ', ')); Write-Host 'Use http://localhost for desktop/web targets, or bind the backend to 0.0.0.0 for physical devices.'; exit 3 }; Write-Host ('API not reachable at ' + $url.Host + ':' + $url.Port); exit 1"
  if errorlevel 1 (
    echo.
    echo Start the backend API and make sure it is listening on %REZEKI_API_BASE_URL%.
    echo Set REZEKI_SKIP_API_CHECK=1 only if you need to run the Flutter UI without the backend.
    exit /b 1
  )
)

echo API reachability check passed.
echo.

flutter analyze
if errorlevel 1 exit /b 1

flutter test
if errorlevel 1 exit /b 1

echo.
echo Checks passed.
