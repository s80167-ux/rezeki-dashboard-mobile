import 'dart:convert';

import '../config/app_config.dart';
import 'auth_service.dart';
import 'service_cache.dart';

class QuickReply {
  const QuickReply({
    required this.id,
    required this.title,
    required this.body,
    this.category,
    this.isActive = true,
  });

  factory QuickReply.fromJson(Map<String, dynamic> json) {
    return QuickReply(
      id: (json['id'] ?? '').toString(),
      title: _readString(json['title'], fallback: 'Quick reply'),
      body: _readString(json['body'], fallback: ''),
      category: _readNullableString(json['category']),
      isActive: json['isActive'] != false && json['is_active'] != false,
    );
  }

  final String id;
  final String title;
  final String body;
  final String? category;
  final bool isActive;

  static String _readString(Object? value, {required String fallback}) {
    if (value is String && value.trim().isNotEmpty) return value.trim();
    return fallback;
  }

  static String? _readNullableString(Object? value) {
    if (value is String && value.trim().isNotEmpty) return value.trim();
    return null;
  }
}

class QuickRepliesService {
  const QuickRepliesService({required this.authService});

  static const Duration _cacheTtl = Duration(seconds: 60);
  static final Map<String, ServiceCacheEntry<List<QuickReply>>> _cache = {};

  final AuthService authService;

  Future<List<QuickReply>> fetchQuickReplies({
    bool forceRefresh = false,
  }) async {
    final session = authService.session.value;
    final organizationId = session?.user.organizationId;
    final query = <String, String>{};
    if (organizationId != null && organizationId.isNotEmpty) {
      query['organization_id'] = organizationId;
    }
    final cacheKey = organizationId == null || organizationId.isEmpty
        ? 'no-org'
        : organizationId;
    final cached = _cache[cacheKey];
    if (!forceRefresh && cached != null && cached.isFresh(_cacheTtl)) {
      return cached.value;
    }

    final url = AppConfig.apiUri(
      '/mobile/v1/quick-replies',
    ).replace(queryParameters: query.isEmpty ? null : query);
    final response = await authService.authenticatedGet(url);
    final decoded = _decodeObject(response.body);

    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw QuickRepliesServiceException(_extractError(decoded));
    }

    final data = decoded['data'];
    if (data is! List) {
      throw const QuickRepliesServiceException(
        'Quick replies response was not recognized.',
      );
    }

    final replies = data
        .whereType<Map<String, dynamic>>()
        .map(QuickReply.fromJson)
        .where((reply) => reply.id.isNotEmpty && reply.body.isNotEmpty)
        .toList();
    _cache[cacheKey] = ServiceCacheEntry(
      value: replies,
      savedAt: DateTime.now(),
    );
    return replies;
  }

  Future<void> recordUsage({
    required String templateId,
    required String conversationId,
  }) async {
    final response = await authService.authenticatedPost(
      AppConfig.apiUri('/mobile/v1/quick-replies/$templateId/usage'),
      body: jsonEncode({'conversationId': conversationId}),
    );
    final decoded = _decodeObject(response.body);

    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw QuickRepliesServiceException(_extractError(decoded));
    }
  }

  Map<String, dynamic> _decodeObject(String body) {
    if (body.isEmpty) return <String, dynamic>{};
    final decoded = jsonDecode(body);
    if (decoded is Map<String, dynamic>) return decoded;
    return <String, dynamic>{};
  }

  String _extractError(Map<String, dynamic> decoded) {
    final error = decoded['error'];
    if (error is String && error.isNotEmpty) return error;

    final message = decoded['message'];
    if (message is String && message.isNotEmpty) return message;

    return 'Unable to load quick replies.';
  }
}

class QuickRepliesServiceException implements Exception {
  const QuickRepliesServiceException(this.message);

  final String message;

  @override
  String toString() => message;
}
