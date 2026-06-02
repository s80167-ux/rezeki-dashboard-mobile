# Android Release

## App Identity

- Application ID: `my.rezeki.dashboard`
- App label: `Rezeki Dashboard`
- Deep link callback: `my.rezeki.dashboard://login-callback/`

## Required Dart Defines

- `REZEKI_API_BASE_URL`
- `REZEKI_GOOGLE_SERVER_CLIENT_ID`

Production builds should use an `https://.../api` base URL.

## Debug Checks

Run before preparing a release:

```powershell
flutter analyze
flutter test
```

For local Android debug runs:

```powershell
.\run_dev.bat
```

## Launcher Icon

- Source logo kept at `assets/logo.png`
- Android launcher icon source generated as `assets/app_icon.png`
- Regenerate Android icons after changing the source image:

```powershell
flutter pub run flutter_launcher_icons
```

## Signing Setup

Do not commit keystores, `android/key.properties`, or passwords.

1. Create a keystore locally:

```powershell
keytool -genkeypair -v -keystore android/app/upload-keystore.jks -alias upload -keyalg RSA -keysize 2048 -validity 10000
```

2. Copy the template and fill in local values:

```powershell
copy android\key.properties.example android\key.properties
```

3. Update `android/key.properties`:

```properties
storePassword=YOUR_STORE_PASSWORD
keyPassword=YOUR_KEY_PASSWORD
keyAlias=upload
storeFile=app/upload-keystore.jks
```

`android/app/build.gradle.kts` will only attach the release signing config when `android/key.properties` exists.

## Build Commands

Release APK:

```powershell
flutter build apk --release --dart-define=REZEKI_API_BASE_URL=https://YOUR-BACKEND/api --dart-define=REZEKI_GOOGLE_SERVER_CLIENT_ID=YOUR_WEB_CLIENT_ID.apps.googleusercontent.com
```

Release AAB:

```powershell
flutter build appbundle --release --dart-define=REZEKI_API_BASE_URL=https://YOUR-BACKEND/api --dart-define=REZEKI_GOOGLE_SERVER_CLIENT_ID=YOUR_WEB_CLIENT_ID.apps.googleusercontent.com
```

## Internal Beta Smoke Test

1. Install the release APK or internal-app-sharing build on a physical Android device.
2. Confirm the launcher label shows `Rezeki Dashboard`.
3. Confirm the launcher icon is the branded Rezeki icon.
4. Log in with email/password.
5. Log in with Google.
6. Open Dashboard, Inbox, Contacts, Sales, and More.
7. Verify Inbox loads, search works, and pull-to-refresh works.
8. Verify opening a conversation, reply, forward, and create-sales still work.
9. Verify the production build points at an HTTPS API base URL.
10. Verify no keystore files or secrets were added to git.
