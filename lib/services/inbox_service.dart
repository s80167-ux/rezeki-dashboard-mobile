import 'dart:async';
import 'dart:convert';

import 'package:http/http.dart' as http;

import '../config/app_config.dart';
import 'auth_service.dart';

class InboxConversation {
  const InboxConversation({
    required this.id,
    required this.contactName,
    required this.lastMessagePreview,
    required this.unreadCount,
    this.contactId,
    this.whatsappAccountId,
    this.whatsappAccountLabel,
    this.lastMessageAt,
    this.channel,
    this.avatarUrl,
    this.leadStatus,
    this.tag,
  });

  factory InboxConversation.fromJson(Map<String, dynamic> json) {
    return InboxConversation(
      id: (json['id'] ?? '').toString(),
      contactId: _readNullableString(json['contact_id'] ?? json['contactId']),
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
      leadStatus: _formatNullableStatus(
        json['lead_status'] ??
            json['leadStatus'] ??
            json['contact_status'] ??
            json['contactStatus'],
      ),
      tag: _readNullableString(
        json['tag'] ??
            json['contact_tag'] ??
            json['contactTag'] ??
            json['source_label'] ??
            json['sourceLabel'],
      ),
    );
  }

  final String id;
  final String? contactId;
  final String contactName;
  final String lastMessagePreview;
  final int unreadCount;
  final String? whatsappAccountId;
  final String? whatsappAccountLabel;
  final DateTime? lastMessageAt;
  final String? channel;
  final String? avatarUrl;
  final String? leadStatus;
  final String? tag;

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

  static String? _formatNullableStatus(Object? value) {
    final raw = _readNullableString(value);
    if (raw == null) return null;
    return raw
        .split('_')
        .where((part) => part.isNotEmpty)
        .map((part) => '${part[0].toUpperCase()}${part.substring(1)}')
        .join(' ');
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
    this.contentJson,
    this.externalMessageId,
    this.ackStatus,
  });

  factory InboxMessage.fromJson(Map<String, dynamic> json) {
    return InboxMessage(
      id: (json['id'] ?? '').toString(),
      direction: (json['direction'] ?? 'system').toString(),
      messageType: (json['message_type'] ?? json['messageType'] ?? 'text')
          .toString(),
      contentText: _readContent(json),
      contentJson: json['content_json'] ?? json['contentJson'],
      sentAt: _readDate(json['sent_at'] ?? json['sentAt']),
      externalMessageId: _readNullableString(
        json['external_message_id'] ?? json['externalMessageId'],
      ),
      ackStatus: _readNullableString(json['ack_status'] ?? json['ackStatus']),
    );
  }

  final String id;
  final String direction;
  final String messageType;
  final String contentText;
  final Object? contentJson;
  final DateTime? sentAt;
  final String? externalMessageId;
  final String? ackStatus;

  bool get isOutgoing => direction == 'outgoing';
  bool get isSystem => direction == 'system';
  MessageAttachmentPresentation get presentation {
    return MessageAttachmentPresentation.fromMessage(this);
  }

  static String _readContent(Map<String, dynamic> json) {
    final text = json['content_text'] ?? json['contentText'];
    if (text is String && text.trim().isNotEmpty) return text.trim();

    final rawText = _readRawMessageText(
      json['content_json'] ?? json['contentJson'],
    );
    if (rawText != null) return rawText;

    final type = json['message_type'] ?? json['messageType'];
    if (type is String && type.trim().isNotEmpty) return '[${type.trim()}]';

    return '[message]';
  }

  static String? _readRawMessageText(Object? contentJson) {
    final rawMessage = _unwrapRawMessage(
      _rawMessageNode(_asRecord(contentJson)),
    );
    if (rawMessage == null) return null;

    return _asString(rawMessage['conversation']) ??
        _asString(_asRecord(rawMessage['extendedTextMessage'])?['text']) ??
        _asString(_asRecord(rawMessage['imageMessage'])?['caption']) ??
        _asString(_asRecord(rawMessage['videoMessage'])?['caption']) ??
        _asString(_asRecord(rawMessage['documentMessage'])?['caption']) ??
        _asString(
          _asRecord(
            rawMessage['templateButtonReplyMessage'],
          )?['selectedDisplayText'],
        ) ??
        _asString(
          _asRecord(
            rawMessage['buttonsResponseMessage'],
          )?['selectedDisplayText'],
        ) ??
        _asString(_asRecord(rawMessage['listResponseMessage'])?['title']) ??
        _asString(_asRecord(rawMessage['reactionMessage'])?['text']);
  }

  static Map<String, dynamic>? _rawMessageNode(Map<String, dynamic>? content) {
    final message = _asRecord(content?['message']);
    if (message != null) return message;
    return _asRecord(_asRecord(content?['rawPayload'])?['message']);
  }

  static Map<String, dynamic>? _unwrapRawMessage(
    Map<String, dynamic>? node, [
    int depth = 0,
  ]) {
    if (node == null || depth > 8) return node;
    final wrapped =
        _asRecord(_asRecord(node['ephemeralMessage'])?['message']) ??
        _asRecord(_asRecord(node['viewOnceMessage'])?['message']) ??
        _asRecord(_asRecord(node['viewOnceMessageV2'])?['message']) ??
        _asRecord(_asRecord(node['viewOnceMessageV2Extension'])?['message']) ??
        _asRecord(_asRecord(node['documentWithCaptionMessage'])?['message']) ??
        _asRecord(_asRecord(node['editedMessage'])?['message']) ??
        _asRecord(
          _asRecord(
            _asRecord(node['protocolMessage'])?['editedMessage'],
          )?['message'],
        );
    return wrapped == null ? node : _unwrapRawMessage(wrapped, depth + 1);
  }

  static Map<String, dynamic>? _asRecord(Object? value) {
    if (value is Map<String, dynamic>) return value;
    if (value is Map) return Map<String, dynamic>.from(value);
    return null;
  }

  static String? _asString(Object? value) {
    if (value is String && value.trim().isNotEmpty) return value.trim();
    return null;
  }

  static DateTime? _readDate(Object? value) {
    if (value is! String || value.isEmpty) return null;
    return DateTime.tryParse(value)?.toLocal();
  }

  static String? _readNullableString(Object? value) {
    if (value is String && value.trim().isNotEmpty) return value.trim();
    return null;
  }
}

class MessageAttachmentPresentation {
  const MessageAttachmentPresentation({
    required this.kind,
    required this.title,
    required this.isMedia,
    this.label,
    this.caption,
    this.mimeType,
    this.fileName,
    this.dataBase64,
    this.downloadUrl,
    this.details = const [],
  });

  factory MessageAttachmentPresentation.fromMessage(InboxMessage message) {
    final content = _asRecord(message.contentJson);
    final outboundMedia = _asRecord(content?['outboundMedia']);
    final rawMessage = _unwrapRawMessage(_rawMessageNode(content));
    final kind = _resolveKind(message.messageType, outboundMedia, rawMessage);
    final contentText = _cleanText(message.contentText);

    if (kind == 'text') {
      return MessageAttachmentPresentation(
        kind: kind,
        title: contentText ?? 'Message',
        isMedia: false,
      );
    }

    final node = _nodeForKind(rawMessage, kind);
    final mimeType =
        _asString(node?['mimetype']) ?? _asString(outboundMedia?['mimeType']);
    final fileName =
        _asString(node?['fileName']) ?? _asString(outboundMedia?['fileName']);
    final dataBase64 = _asString(outboundMedia?['dataBase64']);
    final title = switch (kind) {
      'image' => contentText ?? fileName ?? 'Photo received',
      'video' => contentText ?? fileName ?? 'Video received',
      'audio' => fileName ?? 'Audio message',
      'document' => fileName ?? 'Document received',
      'sticker' => 'Sticker',
      'location' => _asString(node?['name']) ?? 'Shared location',
      'contact' => _asString(node?['displayName']) ?? 'Shared contact',
      'reaction' => _asString(node?['text']) ?? 'Reaction',
      _ => contentText ?? '$kind message',
    };
    final seconds = _asNumber(node?['seconds']);
    final fileLength =
        _asNumber(node?['fileLength']) ??
        _asNumber(outboundMedia?['fileSizeBytes']);
    final formattedFileSize = _formatFileSize(fileLength);

    return MessageAttachmentPresentation(
      kind: kind,
      label: _labelForKind(kind),
      title: title,
      caption: contentText == title ? null : contentText,
      details: [
        ?mimeType,
        ?formattedFileSize,
        if (seconds != null) '${seconds.round()} sec',
      ],
      isMedia: true,
      mimeType: mimeType,
      fileName: fileName,
      dataBase64: dataBase64,
      downloadUrl: _asString(node?['url']),
    );
  }

  final String kind;
  final String? label;
  final String title;
  final String? caption;
  final List<String> details;
  final bool isMedia;
  final String? mimeType;
  final String? fileName;
  final String? dataBase64;
  final String? downloadUrl;

  bool get hasImagePreview =>
      kind == 'image' &&
      dataBase64 != null &&
      dataBase64!.isNotEmpty &&
      mimeType != null &&
      mimeType!.startsWith('image/');

  static String? _cleanText(String value) {
    final trimmed = value.trim();
    if (trimmed.isEmpty) return null;
    if (trimmed.startsWith('[') && trimmed.endsWith(']')) return null;
    return trimmed;
  }

  static Map<String, dynamic>? _asRecord(Object? value) {
    if (value is Map<String, dynamic>) return value;
    if (value is Map) return Map<String, dynamic>.from(value);
    return null;
  }

  static String? _asString(Object? value) {
    if (value is String && value.trim().isNotEmpty) return value.trim();
    return null;
  }

  static num? _asNumber(Object? value) {
    if (value is num) return value;
    if (value is String) return num.tryParse(value);
    return null;
  }

  static Map<String, dynamic>? _rawMessageNode(Map<String, dynamic>? content) {
    final message = _asRecord(content?['message']);
    if (message != null) return message;
    return _asRecord(_asRecord(content?['rawPayload'])?['message']);
  }

  static Map<String, dynamic>? _unwrapRawMessage(
    Map<String, dynamic>? node, [
    int depth = 0,
  ]) {
    if (node == null || depth > 8) return node;
    final wrapped =
        _asRecord(_asRecord(node['ephemeralMessage'])?['message']) ??
        _asRecord(_asRecord(node['viewOnceMessage'])?['message']) ??
        _asRecord(_asRecord(node['viewOnceMessageV2'])?['message']) ??
        _asRecord(_asRecord(node['documentWithCaptionMessage'])?['message']);
    return wrapped == null ? node : _unwrapRawMessage(wrapped, depth + 1);
  }

  static String _resolveKind(
    String messageType,
    Map<String, dynamic>? outboundMedia,
    Map<String, dynamic>? rawMessage,
  ) {
    final outboundKind = _asString(outboundMedia?['kind']);
    if (outboundKind != null) return _normalizeKind(outboundKind);

    final normalized = _normalizeKind(messageType);
    if (normalized != 'system') return normalized;

    if (_asRecord(rawMessage?['imageMessage']) != null) return 'image';
    if (_asRecord(rawMessage?['videoMessage']) != null) return 'video';
    if (_asRecord(rawMessage?['audioMessage']) != null ||
        _asRecord(rawMessage?['pttMessage']) != null) {
      return 'audio';
    }
    if (_asRecord(rawMessage?['documentMessage']) != null) return 'document';
    if (_asRecord(rawMessage?['stickerMessage']) != null) return 'sticker';
    if (_asRecord(rawMessage?['locationMessage']) != null) return 'location';
    if (_asRecord(rawMessage?['contactMessage']) != null ||
        _asRecord(rawMessage?['contactsArrayMessage']) != null) {
      return 'contact';
    }
    if (_asRecord(rawMessage?['reactionMessage']) != null) return 'reaction';
    return 'text';
  }

  static String _normalizeKind(String value) {
    switch (value) {
      case 'conversation':
      case 'extendedTextMessage':
      case 'text':
        return 'text';
      case 'imageMessage':
      case 'image':
        return 'image';
      case 'videoMessage':
      case 'video':
        return 'video';
      case 'audioMessage':
      case 'pttMessage':
      case 'audio':
        return 'audio';
      case 'documentMessage':
      case 'document':
        return 'document';
      case 'stickerMessage':
      case 'sticker':
        return 'sticker';
      case 'locationMessage':
      case 'location':
        return 'location';
      case 'contactMessage':
      case 'contactsArrayMessage':
      case 'contact':
        return 'contact';
      case 'reactionMessage':
      case 'reaction':
        return 'reaction';
      default:
        return value.isEmpty || value == 'unknown' ? 'system' : value;
    }
  }

  static Map<String, dynamic>? _nodeForKind(
    Map<String, dynamic>? rawMessage,
    String kind,
  ) {
    switch (kind) {
      case 'image':
        return _asRecord(rawMessage?['imageMessage']);
      case 'video':
        return _asRecord(rawMessage?['videoMessage']);
      case 'audio':
        return _asRecord(rawMessage?['audioMessage']) ??
            _asRecord(rawMessage?['pttMessage']);
      case 'document':
        return _asRecord(rawMessage?['documentMessage']);
      case 'location':
        return _asRecord(rawMessage?['locationMessage']);
      case 'contact':
        return _asRecord(rawMessage?['contactMessage']);
      case 'reaction':
        return _asRecord(rawMessage?['reactionMessage']);
      default:
        return null;
    }
  }

  static String? _labelForKind(String kind) {
    return switch (kind) {
      'image' => 'Image',
      'video' => 'Video',
      'audio' => 'Audio',
      'document' => 'Document',
      'sticker' => 'Sticker',
      'location' => 'Location',
      'contact' => 'Contact',
      'reaction' => 'Reaction',
      _ => null,
    };
  }

  static String? _formatFileSize(num? bytes) {
    if (bytes == null || bytes <= 0) return null;
    const units = ['B', 'KB', 'MB', 'GB'];
    var size = bytes.toDouble();
    var unitIndex = 0;
    while (size >= 1024 && unitIndex < units.length - 1) {
      size /= 1024;
      unitIndex += 1;
    }
    final precision = size >= 10 || unitIndex == 0 ? 0 : 1;
    return '${size.toStringAsFixed(precision)} ${units[unitIndex]}';
  }
}

class AiInboxSuggestion {
  const AiInboxSuggestion({
    required this.label,
    required this.body,
    required this.confidence,
  });

  factory AiInboxSuggestion.fromJson(Map<String, dynamic> json) {
    return AiInboxSuggestion(
      label: _readString(json['label'], 'Suggested reply'),
      body: _readString(json['body'], ''),
      confidence: _readConfidence(json['confidence']),
    );
  }

  final String label;
  final String body;
  final double confidence;

  static String _readString(Object? value, String fallback) {
    if (value is String && value.trim().isNotEmpty) return value.trim();
    return fallback;
  }

  static double _readConfidence(Object? value) {
    if (value is num) return value.toDouble().clamp(0, 1);
    if (value is String) return (double.tryParse(value) ?? 0).clamp(0, 1);
    return 0;
  }
}

class AiInboxIntent {
  const AiInboxIntent({
    required this.label,
    required this.confidence,
    required this.sentiment,
    required this.urgency,
  });

  factory AiInboxIntent.fromJson(Map<String, dynamic>? json) {
    return AiInboxIntent(
      label: _readString(json?['label'], 'unknown'),
      confidence: AiInboxSuggestion._readConfidence(json?['confidence']),
      sentiment: _readString(json?['sentiment'], 'neutral'),
      urgency: _readString(json?['urgency'], 'low'),
    );
  }

  final String label;
  final double confidence;
  final String sentiment;
  final String urgency;

  String get displayLabel => label
      .split('_')
      .where((part) => part.isNotEmpty)
      .map((part) => '${part[0].toUpperCase()}${part.substring(1)}')
      .join(' ');

  static String _readString(Object? value, String fallback) {
    if (value is String && value.trim().isNotEmpty) return value.trim();
    return fallback;
  }
}

class AiInboxReview {
  const AiInboxReview({
    required this.spamRisk,
    required this.readability,
    required this.ctaClarity,
    required this.warnings,
    required this.tips,
  });

  factory AiInboxReview.fromJson(Map<String, dynamic>? json) {
    return AiInboxReview(
      spamRisk: _readString(json?['spamRisk'], 'low'),
      readability: _readString(json?['readability'], 'easy'),
      ctaClarity: _readString(json?['ctaClarity'], 'good'),
      warnings: _readStringList(json?['warnings']),
      tips: _readStringList(json?['tips']),
    );
  }

  final String spamRisk;
  final String readability;
  final String ctaClarity;
  final List<String> warnings;
  final List<String> tips;

  static String _readString(Object? value, String fallback) {
    if (value is String && value.trim().isNotEmpty) return value.trim();
    return fallback;
  }

  static List<String> _readStringList(Object? value) {
    if (value is! List) return const [];
    return value
        .whereType<String>()
        .map((item) => item.trim())
        .where((item) => item.isNotEmpty)
        .toList();
  }
}

class AiInboxAssistResult {
  const AiInboxAssistResult({
    required this.action,
    required this.intent,
    required this.suggestedReplies,
    required this.review,
    this.summary,
    this.recommendedAction,
  });

  factory AiInboxAssistResult.fromJson(Map<String, dynamic> json) {
    final intentJson = json['intent'];
    final reviewJson = json['review'];
    final suggestions = json['suggestedReplies'];

    return AiInboxAssistResult(
      action: (json['action'] ?? '').toString(),
      intent: AiInboxIntent.fromJson(
        intentJson is Map<String, dynamic> ? intentJson : null,
      ),
      summary: _readNullableString(json['summary']),
      suggestedReplies: suggestions is List
          ? suggestions
                .whereType<Map<String, dynamic>>()
                .map(AiInboxSuggestion.fromJson)
                .where((suggestion) => suggestion.body.isNotEmpty)
                .toList()
          : const [],
      recommendedAction: _readNullableString(json['recommendedAction']),
      review: AiInboxReview.fromJson(
        reviewJson is Map<String, dynamic> ? reviewJson : null,
      ),
    );
  }

  final String action;
  final AiInboxIntent intent;
  final String? summary;
  final List<AiInboxSuggestion> suggestedReplies;
  final String? recommendedAction;
  final AiInboxReview review;

  static String? _readNullableString(Object? value) {
    if (value is String && value.trim().isNotEmpty) return value.trim();
    return null;
  }
}

class AiAssistAvailability {
  const AiAssistAvailability({required this.isEnabled});

  factory AiAssistAvailability.fromJson(Map<String, dynamic> json) {
    final value = json['isEnabled'] ?? json['is_enabled'];
    return AiAssistAvailability(isEnabled: value == true);
  }

  final bool isEnabled;
}

class WhatsAppSource {
  const WhatsAppSource({
    required this.id,
    required this.label,
    this.phoneNumber,
    this.status,
  });

  factory WhatsAppSource.fromJson(Map<String, dynamic> json) {
    final label = _firstString([
      json['label'],
      json['name'],
      json['display_name'],
      json['displayName'],
      json['phone_number'],
      json['phoneNumber'],
    ]);

    return WhatsAppSource(
      id: (json['id'] ?? '').toString(),
      label: label.isEmpty ? 'WhatsApp source' : label,
      phoneNumber: _readNullableString(
        json['phone_number'] ??
            json['phoneNumber'] ??
            json['phone_number_normalized'] ??
            json['phoneNumberNormalized'],
      ),
      status: _readNullableString(json['status']),
    );
  }

  final String id;
  final String label;
  final String? phoneNumber;
  final String? status;

  String get subtitle {
    final parts = [
      if (phoneNumber != null && phoneNumber!.isNotEmpty) phoneNumber!,
      if (status != null && status!.isNotEmpty) status!,
    ];
    return parts.join(' - ');
  }

  static String _firstString(List<Object?> values) {
    for (final value in values) {
      if (value is String && value.trim().isNotEmpty) return value.trim();
    }
    return '';
  }

  static String? _readNullableString(Object? value) {
    if (value is String && value.trim().isNotEmpty) return value.trim();
    return null;
  }
}

class InboxService {
  const InboxService({required this.authService});

  final AuthService authService;

  Stream<InboxUpdateEvent> watchInboxEvents() {
    final controller = StreamController<InboxUpdateEvent>();
    http.Client? client;

    Future<void> connect() async {
      var reconnectDelay = const Duration(seconds: 2);

      while (!controller.isClosed) {
        final session = authService.session.value;
        if (session == null) {
          controller.addError(const AuthServiceException('Please log in again.'));
          return;
        }

        client = http.Client();

        try {
          final request = http.Request(
            'GET',
            AppConfig.apiUri('/mobile/inbox/events'),
          );
          request.headers.addAll(_sseHeaders(session));

          final response = await client!.send(request);

          if (response.statusCode == 401) {
            const message = 'Your session expired. Please log in again.';
            await authService.clearLocalSession(message: message);
            controller.addError(const AuthServiceException(message));
            return;
          }

          if (response.statusCode < 200 || response.statusCode >= 300) {
            controller.addError(
              InboxServiceException(
                'Inbox realtime connection failed (${response.statusCode}).',
              ),
            );
            await _waitBeforeReconnect(controller, reconnectDelay);
            reconnectDelay = _nextReconnectDelay(reconnectDelay);
            continue;
          }

          reconnectDelay = const Duration(seconds: 2);
          var eventName = 'message';
          final dataLines = <String>[];

          await for (final line
              in response.stream.transform(utf8.decoder).transform(
                    const LineSplitter(),
                  )) {
            if (controller.isClosed) return;

            if (line.isEmpty) {
              final event = _parseSseEvent(eventName, dataLines);
              if (event != null) {
                controller.add(event);
              }
              eventName = 'message';
              dataLines.clear();
              continue;
            }

            if (line.startsWith(':')) {
              continue;
            }

            if (line.startsWith('event:')) {
              eventName = line.substring('event:'.length).trim();
              continue;
            }

            if (line.startsWith('data:')) {
              dataLines.add(line.substring('data:'.length).trimLeft());
            }
          }
        } catch (error) {
          if (!controller.isClosed) {
            controller.addError(
              InboxServiceException('Inbox realtime disconnected: $error'),
            );
          }
        } finally {
          client?.close();
          client = null;
        }

        await _waitBeforeReconnect(controller, reconnectDelay);
        reconnectDelay = _nextReconnectDelay(reconnectDelay);
      }
    }

    controller.onListen = () {
      unawaited(connect());
    };
    controller.onCancel = () {
      client?.close();
    };

    return controller.stream;
  }

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

  Future<InboxConversation?> fetchConversationForContact(
    String contactId,
  ) async {
    final conversations = await fetchConversations();
    for (final conversation in conversations) {
      if (conversation.contactId == contactId) return conversation;
    }
    return null;
  }

  Future<List<WhatsAppSource>> fetchWhatsappSources() async {
    final session = authService.session.value;
    final query = <String, String>{};
    final organizationId = session?.user.organizationId;
    if (organizationId != null && organizationId.isNotEmpty) {
      query['organization_id'] = organizationId;
    }

    final url = AppConfig.apiUri(
      '/admin/whatsapp-accounts',
    ).replace(queryParameters: query.isEmpty ? null : query);
    final response = await authService.authenticatedGet(url);
    final decoded = _decodeObject(response.body);

    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw InboxServiceException(_extractError(decoded));
    }

    final data = decoded['data'];
    if (data is! List) {
      throw const InboxServiceException(
        'WhatsApp sources response was not recognized.',
      );
    }

    return data
        .whereType<Map<String, dynamic>>()
        .map(WhatsAppSource.fromJson)
        .where((source) => source.id.isNotEmpty)
        .toList();
  }

  Future<InboxConversation> createConversationForContact({
    required String contactId,
    required String whatsappAccountId,
  }) async {
    final response = await authService.authenticatedPost(
      AppConfig.apiUri('/contacts/$contactId/conversation'),
      body: jsonEncode({'whatsappAccountId': whatsappAccountId}),
    );
    final decoded = _decodeObject(response.body);

    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw InboxServiceException(_extractError(decoded));
    }

    final data = decoded['data'];
    if (data is! Map<String, dynamic>) {
      throw const InboxServiceException(
        'Created conversation response was not recognized.',
      );
    }

    final conversation = InboxConversation.fromJson(data);
    if (conversation.id.isEmpty) {
      throw const InboxServiceException(
        'Created conversation was not recognized.',
      );
    }

    return conversation;
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

  Future<AiInboxAssistResult> requestAiAssist({
    required String conversationId,
    required String action,
    String? draft,
    String? tone,
  }) async {
    final session = authService.session.value;
    final organizationId = session?.user.organizationId;
    final payload = <String, dynamic>{
      'conversationId': conversationId,
      'action': action,
      if (organizationId != null && organizationId.isNotEmpty)
        'organizationId': organizationId,
      if (draft != null && draft.trim().isNotEmpty) 'draft': draft.trim(),
      if (tone != null && tone.trim().isNotEmpty) 'tone': tone.trim(),
    };

    final response = await authService.authenticatedPost(
      AppConfig.apiUri('/ai/inbox-assist'),
      body: jsonEncode(payload),
    );
    final decoded = _decodeObject(response.body);

    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw InboxServiceException(
        _extractError(decoded),
        code: _extractErrorCode(decoded),
      );
    }

    return AiInboxAssistResult.fromJson(decoded);
  }

  Future<AiAssistAvailability> fetchAiAssistAvailability() async {
    final session = authService.session.value;
    final query = <String, String>{};
    final organizationId = session?.user.organizationId;
    if (organizationId != null && organizationId.isNotEmpty) {
      query['organization_id'] = organizationId;
    }

    final url = AppConfig.apiUri(
      '/admin/organization-modules/ai_message_assist/status',
    ).replace(queryParameters: query.isEmpty ? null : query);
    final response = await authService.authenticatedGet(url);
    final decoded = _decodeObject(response.body);

    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw InboxServiceException(
        _extractError(decoded),
        code: _extractErrorCode(decoded),
      );
    }

    final data = decoded['data'];
    if (data is! Map<String, dynamic>) {
      throw const InboxServiceException(
        'AI Assist status response was not recognized.',
      );
    }

    return AiAssistAvailability.fromJson(data);
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

  String? _extractErrorCode(Map<String, dynamic> decoded) {
    final code = decoded['code'];
    if (code is String && code.isNotEmpty) return code;
    return null;
  }

  Map<String, String> _sseHeaders(AuthSession session) {
    final headers = <String, String>{
      'Accept': 'text/event-stream',
      'Cache-Control': 'no-cache',
    };

    if (session.cookieHeader != null) {
      headers['Cookie'] = session.cookieHeader!;
    }
    if (session.csrfToken != null) {
      headers['x-csrf-token'] = session.csrfToken!;
    }
    if (session.accessToken != null) {
      headers['Authorization'] = 'Bearer ${session.accessToken}';
    }

    return headers;
  }

  InboxUpdateEvent? _parseSseEvent(String eventName, List<String> dataLines) {
    if (eventName != 'inbox_update' || dataLines.isEmpty) {
      return null;
    }

    final decoded = jsonDecode(dataLines.join('\n'));
    if (decoded is! Map<String, dynamic>) {
      return null;
    }

    return InboxUpdateEvent.fromJson(decoded);
  }

  Duration _nextReconnectDelay(Duration current) {
    final nextSeconds = current.inSeconds * 2;
    return Duration(seconds: nextSeconds > 30 ? 30 : nextSeconds);
  }

  Future<void> _waitBeforeReconnect(
    StreamController<InboxUpdateEvent> controller,
    Duration delay,
  ) async {
    if (controller.isClosed) return;
    await Future<void>.delayed(delay);
  }
}

class InboxUpdateEvent {
  const InboxUpdateEvent({
    required this.type,
    required this.conversationId,
    required this.organizationId,
    required this.timestamp,
  });

  factory InboxUpdateEvent.fromJson(Map<String, dynamic> json) {
    return InboxUpdateEvent(
      type: (json['type'] ?? '').toString(),
      conversationId: (json['conversationId'] ?? '').toString(),
      organizationId: (json['organizationId'] ?? '').toString(),
      timestamp: DateTime.tryParse((json['timestamp'] ?? '').toString()) ??
          DateTime.now(),
    );
  }

  final String type;
  final String conversationId;
  final String organizationId;
  final DateTime timestamp;
}

class InboxServiceException implements Exception {
  const InboxServiceException(this.message, {this.code});

  final String message;
  final String? code;

  @override
  String toString() => message;
}
