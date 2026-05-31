import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:app_links/app_links.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';

import '../config/app_config.dart';

class AuthUser {
  const AuthUser({
    required this.id,
    this.email,
    this.fullName,
    this.organizationId,
    this.organizationName,
    this.role,
  });

  factory AuthUser.fromJson(Map<String, dynamic> json) {
    return AuthUser(
      id: (json['id'] ?? json['authUserId'] ?? '').toString(),
      email: json['email'] as String?,
      fullName: json['fullName'] as String?,
      organizationId: json['organizationId'] as String?,
      organizationName: json['organizationName'] as String?,
      role: json['role'] as String?,
    );
  }

  final String id;
  final String? email;
  final String? fullName;
  final String? organizationId;
  final String? organizationName;
  final String? role;

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'email': email,
      'fullName': fullName,
      'organizationId': organizationId,
      'organizationName': organizationName,
      'role': role,
    };
  }
}

class AuthSession {
  const AuthSession({
    required this.user,
    this.cookieHeader,
    this.csrfToken,
    this.accessToken,
    this.refreshToken,
  });

  factory AuthSession.fromJson(Map<String, dynamic> json) {
    return AuthSession(
      user: AuthUser.fromJson(json['user'] as Map<String, dynamic>),
      cookieHeader: json['cookieHeader'] as String?,
      csrfToken: json['csrfToken'] as String?,
      accessToken: json['accessToken'] as String?,
      refreshToken: json['refreshToken'] as String?,
    );
  }

  final AuthUser user;
  final String? cookieHeader;
  final String? csrfToken;
  final String? accessToken;
  final String? refreshToken;

  Map<String, dynamic> toJson() {
    return {
      'user': user.toJson(),
      'cookieHeader': cookieHeader,
      'csrfToken': csrfToken,
      'accessToken': accessToken,
      'refreshToken': refreshToken,
    };
  }
}

class AuthService {
  AuthService._();

  static final AuthService instance = AuthService._();
  static const _sessionKey = 'rezeki_auth_session';

  final ValueNotifier<AuthSession?> session = ValueNotifier<AuthSession?>(null);
  final ValueNotifier<String?> authError = ValueNotifier<String?>(null);
  SharedPreferences? _preferences;
  StreamSubscription<Uri>? _linkSubscription;

  Future<void> initialize() async {
    _preferences = await SharedPreferences.getInstance();
    final rawSession = _preferences?.getString(_sessionKey);
    await _listenForAuthCallbacks();
    if (rawSession == null) return;

    try {
      final decoded = jsonDecode(rawSession) as Map<String, dynamic>;
      session.value = AuthSession.fromJson(decoded);
    } catch (_) {
      await _preferences?.remove(_sessionKey);
    }
  }

  Future<void> signInWithEmail({
    required String email,
    required String password,
  }) async {
    final response = await _post(
      AppConfig.apiUri('/auth/login'),
      headers: const {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
      },
      body: jsonEncode({
        'email': email,
        'password': password,
      }),
    );

    final decoded = _decodeResponse(response);
    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw AuthServiceException(_extractError(decoded));
    }

    final data = decoded['data'];
    if (data is! Map<String, dynamic>) {
      throw const AuthServiceException('Login response was not recognized.');
    }

    final userJson = data['user'] is Map<String, dynamic>
        ? data['user'] as Map<String, dynamic>
        : data;

    final authSession = AuthSession(
      user: AuthUser.fromJson(userJson),
      cookieHeader: _extractCookieHeader(response),
      csrfToken: decoded['csrfToken'] as String?,
      accessToken: data['accessToken'] as String?,
      refreshToken: data['refreshToken'] as String?,
    );

    if (authSession.user.id.isEmpty) {
      throw const AuthServiceException('Login response did not include a user.');
    }

    await _saveSession(authSession);
  }

  Future<void> signOut() async {
    final currentSession = session.value;
    if (currentSession != null) {
      try {
        await _post(
          AppConfig.apiUri('/auth/logout'),
          headers: _authHeaders(currentSession),
        );
      } catch (_) {
        // Local logout should still complete if the API is offline.
      }
    }

    await _preferences?.remove(_sessionKey);
    session.value = null;
  }

  Future<void> startGoogleSignIn() async {
    if (AppConfig.googleClientId.isEmpty) {
      throw const AuthServiceException(
        'Google sign-in is not configured. Set REZEKI_GOOGLE_CLIENT_ID.',
      );
    }

    authError.value = null;
    final googleSignIn = GoogleSignIn(
      scopes: const ['email', 'profile'],
      clientId: AppConfig.googleClientId,
      serverClientId: AppConfig.googleServerClientId,
    );

    final GoogleSignInAccount? account;
    try {
      account = await googleSignIn.signIn();
    } on PlatformException catch (e) {
      throw AuthServiceException(_mapGooglePlatformError(e));
    }

    if (account == null) {
      throw const AuthServiceException('Google sign-in was cancelled.');
    }

    final GoogleSignInAuthentication authentication;
    try {
      authentication = await account.authentication;
    } on PlatformException catch (e) {
      throw AuthServiceException(_mapGooglePlatformError(e));
    }
    final idToken = authentication.idToken;
    if (idToken == null || idToken.isEmpty) {
      throw const AuthServiceException(
        'Google did not return an ID token for this app.',
      );
    }

    await _signInWithGoogleIdToken(idToken);
  }

  Future<void> startBrowserGoogleSignIn() async {
    authError.value = null;
    final startUrl = AppConfig.apiUri('/auth/google/start').replace(
      queryParameters: {
        'mobile_redirect_to': AppConfig.mobileAuthCallbackUrl,
      },
    );

    final launched = await launchUrl(
      startUrl,
      mode: LaunchMode.externalApplication,
    );

    if (!launched) {
      throw const AuthServiceException('Could not open Google sign-in.');
    }
  }

  Future<void> _signInWithGoogleIdToken(String idToken) async {
    final response = await _post(
      AppConfig.apiUri('/auth/google/mobile'),
      headers: const {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
      },
      body: jsonEncode({
        'idToken': idToken,
      }),
    );

    final decoded = _decodeResponse(response);
    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw AuthServiceException(_extractError(decoded));
    }

    final data = decoded['data'];
    if (data is! Map<String, dynamic> || data['user'] is! Map<String, dynamic>) {
      throw const AuthServiceException('Google login response was not recognized.');
    }

    final authSession = AuthSession(
      user: AuthUser.fromJson(data['user'] as Map<String, dynamic>),
      cookieHeader: _extractCookieHeader(response),
      csrfToken: decoded['csrfToken'] as String?,
      accessToken: data['accessToken'] as String?,
      refreshToken: data['refreshToken'] as String?,
    );

    if (authSession.user.id.isEmpty) {
      throw const AuthServiceException(
        'Google login response did not include a user.',
      );
    }

    await _saveSession(authSession);
  }

  Future<void> _listenForAuthCallbacks() async {
    final appLinks = AppLinks();
    _linkSubscription ??= appLinks.uriLinkStream.listen(
      _handleAuthCallback,
      onError: (_) {
        authError.value = 'Google sign-in callback could not be read.';
      },
    );

    final initialLink = await appLinks.getInitialLink();
    if (initialLink != null) {
      await _handleAuthCallback(initialLink);
    }
  }

  Future<void> _handleAuthCallback(Uri uri) async {
    if (uri.scheme != 'com.example.rezeki_dashboard_app' ||
        uri.host != 'login-callback') {
      return;
    }

    final status = uri.queryParameters['status'];
    if (status != 'success') {
      authError.value = _mapGoogleError(uri.queryParameters['error']);
      return;
    }

    final accessToken = uri.queryParameters['access_token'];
    final refreshToken = uri.queryParameters['refresh_token'];
    final csrfToken = uri.queryParameters['csrf_token'];
    final rawUser = uri.queryParameters['user'];

    if (accessToken == null || refreshToken == null || rawUser == null) {
      authError.value = 'Google sign-in response was incomplete.';
      return;
    }

    try {
      final decodedUser = jsonDecode(rawUser) as Map<String, dynamic>;
      final authSession = AuthSession(
        user: AuthUser.fromJson(decodedUser),
        accessToken: accessToken,
        refreshToken: refreshToken,
        csrfToken: csrfToken,
      );
      await _saveSession(authSession);
    } catch (_) {
      authError.value = 'Google sign-in response was not recognized.';
    }
  }

  Map<String, String> _authHeaders(AuthSession authSession) {
    final headers = <String, String>{
      'Accept': 'application/json',
      'Content-Type': 'application/json',
    };

    if (authSession.cookieHeader != null) {
      headers['Cookie'] = authSession.cookieHeader!;
    }
    if (authSession.csrfToken != null) {
      headers['x-csrf-token'] = authSession.csrfToken!;
    }
    if (authSession.accessToken != null) {
      headers['Authorization'] = 'Bearer ${authSession.accessToken}';
    }

    return headers;
  }

  Future<http.Response> _post(
    Uri url, {
    Map<String, String>? headers,
    Object? body,
  }) async {
    try {
      final response = await http
          .post(url, headers: headers, body: body)
          .timeout(const Duration(seconds: 15));
      return response;
    } on TimeoutException {
      throw const AuthServiceException(
        'Server is not responding. Check your network or API URL.',
      );
    } on SocketException {
      throw const AuthServiceException(
        'Cannot connect to server. Check your network or API URL.',
      );
    } on http.ClientException catch (e) {
      throw AuthServiceException('Network error: ${e.message}');
    }
  }

  Map<String, dynamic> _decodeResponse(http.Response response) {
    if (response.body.isEmpty) return <String, dynamic>{};
    final decoded = jsonDecode(response.body);
    if (decoded is Map<String, dynamic>) return decoded;
    return <String, dynamic>{'message': 'Unexpected server response.'};
  }

  String _extractError(Map<String, dynamic> decoded) {
    final error = decoded['error'];
    if (error is String && error.isNotEmpty) return error;

    final message = decoded['message'];
    if (message is String && message.isNotEmpty) return message;

    return 'Unable to sign in. Please check your email and password.';
  }

  String? _extractCookieHeader(http.Response response) {
    final setCookie = response.headers['set-cookie'];
    if (setCookie == null || setCookie.isEmpty) return null;

    return setCookie
        .split(',')
        .map((cookie) => cookie.split(';').first.trim())
        .where((cookie) => cookie.isNotEmpty)
        .join('; ');
  }

  Future<void> _saveSession(AuthSession authSession) async {
    await _preferences?.setString(_sessionKey, jsonEncode(authSession.toJson()));
    session.value = authSession;
  }

  String _mapGoogleError(String? code) {
    switch (code) {
      case 'google_account_not_linked':
        return 'This Google account is not linked to a CRM workspace.';
      case 'google_signup_pending':
        return 'Your Google signup request is pending approval.';
      case 'google_login_failed':
      default:
        return 'Google sign-in failed. Please try again.';
    }
  }

  String _mapGooglePlatformError(PlatformException error) {
    final details = error.details?.toString() ?? '';
    final message = error.message ?? '';
    final raw = '$message $details'.toLowerCase();

    if (raw.contains('10') || raw.contains('developer_error')) {
      return 'Google native sign-in is not configured for this Android package/SHA-1.';
    }

    if (raw.contains('12501') || raw.contains('canceled')) {
      return 'Google sign-in was cancelled.';
    }

    if (message.isNotEmpty) {
      return message;
    }

    return 'Google sign-in failed before reaching the CRM API.';
  }
}

class AuthServiceException implements Exception {
  const AuthServiceException(this.message);

  final String message;

  @override
  String toString() => message;
}
