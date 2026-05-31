class AppConfig {
  const AppConfig._();

  static const apiBaseUrl = String.fromEnvironment(
    'REZEKI_API_BASE_URL',
    defaultValue: 'http://10.0.2.2:4000/api',
  );

  static const mobileAuthCallbackUrl =
      'com.example.rezeki_dashboard_app://login-callback/';

  /// OAuth client ID for the current platform (used by the Google Sign-In SDK).
  static const googleClientId = String.fromEnvironment(
    'REZEKI_GOOGLE_CLIENT_ID',
    defaultValue:
        '462104114788-i2a214q02ck5i162gmf5as9epiaokgj0.apps.googleusercontent.com',
  );

  /// OAuth web client ID used by the backend to verify ID tokens.
  static const googleServerClientId = String.fromEnvironment(
    'REZEKI_GOOGLE_SERVER_CLIENT_ID',
    defaultValue:
        '462104114788-i2a214q02ck5i162gmf5as9epiaokgj0.apps.googleusercontent.com',
  );

  static Uri apiUri(String path) {
    final normalizedBase = apiBaseUrl.endsWith('/')
        ? apiBaseUrl.substring(0, apiBaseUrl.length - 1)
        : apiBaseUrl;
    final normalizedPath = path.startsWith('/') ? path : '/$path';
    return Uri.parse('$normalizedBase$normalizedPath');
  }
}
