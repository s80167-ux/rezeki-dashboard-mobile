class AppConfig {
  const AppConfig._();

  static final apiBaseUrl = _normalizeBaseUrl(
    const String.fromEnvironment(
    'REZEKI_API_BASE_URL',
    defaultValue: 'http://10.0.2.2:4000/api',
    ),
  );

  static const mobileAuthCallbackUrl =
      'com.example.rezeki_dashboard_app://login-callback/';

  /// OAuth web client ID used by Google Sign-In and backend ID token exchange.
  static const googleServerClientId = String.fromEnvironment(
    'REZEKI_GOOGLE_SERVER_CLIENT_ID',
  );

  static Uri apiUri(String path) {
    final normalizedBase = apiBaseUrl.endsWith('/')
        ? apiBaseUrl.substring(0, apiBaseUrl.length - 1)
        : apiBaseUrl;
    final normalizedPath = path.startsWith('/') ? path : '/$path';
    return Uri.parse('$normalizedBase$normalizedPath');
  }

  static String _normalizeBaseUrl(String value) {
    final trimmed = value.trim();
    if (trimmed.length >= 2 &&
        ((trimmed.startsWith('"') && trimmed.endsWith('"')) ||
            (trimmed.startsWith("'") && trimmed.endsWith("'")))) {
      return trimmed.substring(1, trimmed.length - 1).trim();
    }
    return trimmed;
  }
}
