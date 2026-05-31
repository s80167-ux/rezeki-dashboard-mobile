# rezeki_dashboard_app

A new Flutter project.

## Local Run

Create a local config file from `run_config.example.bat`:

```powershell
copy run_config.example.bat run_config.local.bat
```

Edit `run_config.local.bat` and set `REZEKI_GOOGLE_SERVER_CLIENT_ID` to the Google Web OAuth client ID.

Then run:

```powershell
.\run_dev.bat
```

Before reinstalling on the phone, run the short check script:

```powershell
.\check_dev.bat
```

## Getting Started

This project is a starting point for a Flutter application.

A few resources to get you started if this is your first Flutter project:

- [Learn Flutter](https://docs.flutter.dev/get-started/learn-flutter)
- [Write your first Flutter app](https://docs.flutter.dev/get-started/codelab)
- [Flutter learning resources](https://docs.flutter.dev/reference/learning-resources)

For help getting started with Flutter development, view the
[online documentation](https://docs.flutter.dev/), which offers tutorials,
samples, guidance on mobile development, and a full API reference.
