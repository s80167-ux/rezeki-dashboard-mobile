# rezeki_dashboard_app

A new Flutter project.

## Local Run

Create a local config file from `run_config.example.bat`:

```powershell
copy run_config.example.bat run_config.local.bat
```

Edit `run_config.local.bat` and set `REZEKI_GOOGLE_SERVER_CLIENT_ID` to the Google Web OAuth client ID.
Set `REZEKI_API_BASE_URL` to the correct backend host for your target:

- Physical Android device: `http://YOUR_PC_LAN_IP:4000/api`
- Android emulator: `http://10.0.2.2:4000/api`
- Windows/web on the same machine: `http://localhost:4000/api`

The backend API is not included in this repository. It must be running separately on port `4000` before auth and data features will work.

Then run:

```powershell
.\run_dev.bat
```

Before reinstalling on the phone, run the short check script:

```powershell
.\check_dev.bat
```

If you only need to run the Flutter UI without the backend, add `set "REZEKI_SKIP_API_CHECK=1"` to `run_config.local.bat`.

## Android Google Sign-In Setup

Native Google Sign-In must have an Android OAuth client in the same Google Cloud project as the web client used by `REZEKI_GOOGLE_SERVER_CLIENT_ID`.

For the current Android package, register:

- Package name: `my.rezeki.dashboard`
- SHA-1: `52:3B:6D:63:1A:D3:8B:BD:20:8B:57:20:B6:A1:2D:99:E2:53:25:5B`
- SHA-256: `95:9D:13:DC:74:D1:CE:BC:CC:99:B8:15:4A:E8:50:4E:B9:D3:2B:DF:22:30:8F:1F:71:E3:9A:4D:B5:8F:81:70`

To refresh these values on this machine:

```powershell
$env:JAVA_HOME='C:\Program Files\Android\Android Studio\jbr'
cd android
.\gradlew.bat signingReport
```

If Google Sign-In fails with `Google native sign-in is not configured for this Android package/SHA-1`, confirm both the Android OAuth client above and the real Web OAuth client ID in `run_config.local.bat`.

## Running with Railway Backend

Copy `run_config.example.bat` to `run_config.local.bat`:

```powershell
copy run_config.example.bat run_config.local.bat
```

Replace `YOUR-RAILWAY-BACKEND-DOMAIN` with the actual Railway backend domain. Make sure the URL ends with `/api`, for example:

```bat
set "REZEKI_API_BASE_URL=https://YOUR-RAILWAY-BACKEND-DOMAIN.up.railway.app/api"
```

Then check the backend and run the app:

```powershell
.\check_backend.bat
.\run_prod.bat
```

## Android Release

Android release packaging, launcher icon generation, signing setup, and smoke-test steps are documented in [RELEASE.md](RELEASE.md).

## Getting Started

This project is a starting point for a Flutter application.

A few resources to get you started if this is your first Flutter project:

- [Learn Flutter](https://docs.flutter.dev/get-started/learn-flutter)
- [Write your first Flutter app](https://docs.flutter.dev/get-started/codelab)
- [Flutter learning resources](https://docs.flutter.dev/reference/learning-resources)

For help getting started with Flutter development, view the
[online documentation](https://docs.flutter.dev/), which offers tutorials,
samples, guidance on mobile development, and a full API reference.
