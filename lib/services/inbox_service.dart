import 'dart:convert';

import '../config/app_config.dart';
import 'auth_service.dart';

class InboxConversation {
  const InboxConversation({
    required this.id,
    required this.contactName,
    required this.lastMessagePreview,
    required this.unreadCount,
    this.whatsappAccountId,
    this.whatsappAccountLabel,
    this.lastMessageAt,
    this.channel,
    this.avatarUrl,
  });

  factory InboxConversation.fromJson(Map<String, dynamic> json) {
    return InboxConversation(
      id: (json['id'] ?? '').toString(),
      contactName: _readString(json, 'contact_name', 'contactName', 'Unknown'),
      lastMessagePreview: _readString(
        json,
        'last_message_preview',
        'lastMessagePreview',
        'No messages yet',
      ),
      unreadCount: _readInt(json['unread_count'] ?? json['unreadCount']),
      whatsappAccountId: _readNullableString(
        json['whatsapp_account_id'] ?? json['whatsappAccountId'],
      ),
      whatsappAccountLabel: _readNullableString(
        json['whatsapp_account_label'] ?? json['whatsappAccountLabel'],
      ),
      lastMessageAt: _readDate(
        json['last_message_at'] ?? json['lastMessageAt'],
      ),
      channel: (json['channel'] as String?)?.trim(),
      avatarUrl: _readNullableString(
        json['contact_avatar_url'] ?? json['contactAvatarUrl'],
      ),
    );
  }

  final String id;
  final String contactName;
  final String lastMessagePreview;
  final int unreadCount;
  final String? whatsappAccountId;
  final String? whatsappAccountLabel;
  final DateTime? lastMessageAt;
  final String? channel;
  final String? avatarUrl;

  String get sourceLabel {
    if (whatsappAccountLabel != null && whatsappAccountLabel!.isNotEmpty) {
      return whatsappAccountLabel!;
    }

    switch (channel) {
      case 'whatsapp':
      case null:
        return whatsappAccountId == null
            ? 'WhatsApp account not provided'
            : 'WhatsApp ${_shortId(whatsappAccountId!)}';
      case 'facebook':
        return 'Facebook';
      case 'instagram':
        return 'Instagram';
      case 'social':
        return 'Social';
      default:
        return channel!;
    }
  }

  String get sourceDescription {
    final normalizedChannel = channel ?? 'whatsapp';
    final channelLabel = normalizedChannel
        .split('_')
        .where((part) => part.isNotEmpty)
        .map((part) => '${part[0].toUpperCase()}${part.substring(1)}')
        .join(' ');

    if (whatsappAccountId == null || whatsappAccountId!.isEmpty) {
      return channelLabel.isEmpty ? sourceLabel : channelLabel;
    }

    return '$channelLabel • ${whatsappAccountLabel ?? _shortId(whatsappAccountId!)}';
  }

  bool get isUnread => unreadCount > 0;

  bool matchesSearch(String search) {
    final normalized = search.trim().toLowerCase();
    if (normalized.isEmpty) return true;
    return '$contactName $lastMessagePreview ${channel ?? ''}'
        .toLowerCase()
        .contains(normalized);
  }

  bool matchesFilter(String filter) {
    switch (filter) {
      case 'Unread':
        return isUnread;
      case 'WhatsApp':
        return channel == null || channel == 'whatsapp';
      case 'Social':
        return channel == 'social' ||
            channel == 'facebook' ||
            channel == 'instagram';
      case 'All':
      default:
        return true;
    }
  }

  static String _readString(
    Map<String, dynamic> json,
    String primaryKey,
    String secondaryKey,
    String fallback,
  ) {
    final value = json[primaryKey] ?? json[secondaryKey];
    if (value is String && value.trim().isNotEmpty) return value.trim();
    return fallback;
  }

  static int _readInt(Object? value) {
    if (value is int) return value;
    if (value is num) return value.toInt();
    if (value is String) return int.tryParse(value) ?? 0;
    return 0;
  }

  static String? _readNullableString(Object? value) {
    if (value is String && value.trim().isNotEmpty) return value.trim();
    return null;
  }

  static DateTime? _readDate(Object? value) {
    if (value is! String || value.isEmpty) return null;
    return DateTime.tryParse(value)?.toLocal();
  }

  static String _shortId(String value) {
    if (value.length <= 8) return value;
    return value.substring(value.length - 8);
  }
}

class InboxMessage {
  const InboxMessage({
    required this.id,
    required this.direction,
    required this.messageType,
    required this.contentText,
    required this.sentAt,
  });

  factory InboxMessage.fromJson(Map<String, dynamic> json) {
    return InboxMessage(
      id: (json['id'] ?? '').toString(),
      direction: (json['direction'] ?? 'system').toString(),
      messageType: (json['message_type'] ?? json['messageType'] ?? 'text')
          .toString(),
      contentText: _readContent(json),
      sentAt: _readDate(json['sent_at'] ?? json['sentAt']),
    );
  }

  final String id;
  final String direction;
  final String messageType;
  final String contentText;
  final DateTime? sentAt;

  bool get isOutgoing => direction == 'outgoing';
  bool get isSystem => direction == 'system';

  static String _readContent(Map<String, dynamic> json) {
    final text = json['content_text'] ?? json['contentText'];
    if (text is String && text.trim().isNotEmpty) return text.trim();

    final type = json['message_type'] ?? json['messageType'];
    if (type is String && type.trim().isNotEmpty) return '[${type.trim()}]';

    return '[message]';
  }

  static DateTime? _readDate(Object? value) {
    if (value is! String || value.isEmpty) return null;
    return DateTime.tryParse(value)?.toLocal();
  }
}

class InboxService {
  const InboxService({required this.authService});

  final AuthService authService;

  Future<List<InboxConversation>> fetchConversations({int? days}) async {
    final session = authService.session.value;
    final query = <String, String>{};
    final organizationId = session?.user.organizationId;
    if (organizationId != null && organizationId.isNotEmpty) {
      query['organization_id'] = organizationId;
    }
    if (days != null) {
      query['days'] = days.toString();
    }

    final url = AppConfig.apiUri(
      '/inbox/threads',
    ).replace(queryParameters: query.isEmpty ? null : query);
    final response = await authService.authenticatedGet(url);
    final decoded = _decodeObject(response.body);

    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw InboxServiceException(_extractError(decoded));
    }

    final data = decoded['data'];
    if (data is! List) {
      throw const InboxServiceException('Inbox response was not recognized.');
    }

    return data
        .whereType<Map<String, dynamic>>()
        .map(InboxConversation.fromJson)
        .where((conversation) => conversation.id.isNotEmpty)
        .toList();
  }

  Future<List<InboxMessage>> fetchMessages(String conversationId) async {
    final session = authService.session.value;
    final query = <String, String>{};
    final organizationId = session?.user.organizationId;
    if (organizationId != null && organizationId.isNotEmpty) {
      query['organization_id'] = organizationId;
    }

    final url = AppConfig.apiUri(
      '/inbox/threads/$conversationId/messages',
    ).replace(queryParameters: query.isEmpty ? null : query);
    final response = await authService.authenticatedGet(url);
    final decoded = _decodeObject(response.body);

    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw InboxServiceException(_extractError(decoded));
    }

    final data = decoded['data'];
    if (data is! List) {
      throw const InboxServiceException(
        'Messages response was not recognized.',
      );
    }

    return data
        .whereType<Map<String, dynamic>>()
        .map(InboxMessage.fromJson)
        .where((message) => message.id.isNotEmpty)
        .toList();
  }

  Future<InboxMessage> sendMessage({
    required InboxConversation conversation,
    required String text,
  }) async {
    final whatsappAccountId = conversation.whatsappAccountId;
    if (whatsappAccountId == null || whatsappAccountId.isEmpty) {
      throw const InboxServiceException(
        'This conversation has no WhatsApp sender account.',
      );
    }

    final session = authService.session.value;
    final organizationId = session?.user.organizationId;
    final payload = <String, dynamic>{
      'whatsappAccountId': whatsappAccountId,
      'conversationId': conversation.id,
      'text': text,
      if (organizationId != null && organizationId.isNotEmpty)
        'organizationId': organizationId,
    };

    final response = await authService.authenticatedPost(
      AppConfig.apiUri('/messages/send'),
      body: jsonEncode(payload),
    );
    final decoded = _decodeObject(response.body);

    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw InboxServiceException(_extractError(decoded));
    }

    final data = decoded['data'];
    if (data is! Map<String, dynamic>) {
      throw const InboxServiceException('Send response was not recognized.');
    }

    return InboxMessage.fromJson(data);
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

    return 'Unable to load inbox conversations.';
  }
}

class InboxServiceException implements Exception {
  const InboxServiceException(this.message);

  final String message;

  @override
  String toString() => message;
}
