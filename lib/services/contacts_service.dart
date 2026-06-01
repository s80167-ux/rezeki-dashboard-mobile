import 'dart:convert';

import '../config/app_config.dart';
import 'auth_service.dart';
import 'service_cache.dart';

class CrmContact {
  const CrmContact({
    required this.id,
    required this.name,
    required this.phone,
    required this.status,
    required this.tag,
    required this.hasPhone,
    required this.hasCompany,
    required this.hasWhatsAppSource,
    this.email,
    this.companyName,
    this.notes,
    this.sourceLabels = const [],
    this.avatarUrl,
    this.displayName,
  });

  factory CrmContact.fromJson(Map<String, dynamic> json) {
    final displayName = _nullableString(
      json['display_name'] ?? json['displayName'],
    );
    final name = _firstString([
      displayName,
      json['primary_phone_e164'],
      json['primary_phone_normalized'],
    ]);
    final phone = _firstString([
      json['primary_phone_e164'],
      json['primary_phone_normalized'],
      json['primaryPhoneE164'],
      json['primaryPhoneNormalized'],
    ]);
    final companyName = _firstString([
      json['company_name'],
      json['companyName'],
    ]);
    final sourceCount = _readInt(
      json['whatsapp_source_count'] ?? json['whatsappSourceCount'],
    );
    final sourceLabels = _readSourceLabels(
      json['whatsapp_sources'] ?? json['whatsappSources'],
    );

    return CrmContact(
      id: (json['id'] ?? '').toString(),
      name: name.isEmpty ? 'Unknown Contact' : name,
      phone: phone.isEmpty ? 'No phone' : phone,
      status: _formatStatus(json['status']),
      tag: companyName.isNotEmpty
          ? companyName
          : sourceCount > 0
          ? '$sourceCount WhatsApp'
          : 'CRM',
      hasPhone: phone.isNotEmpty,
      hasCompany: companyName.isNotEmpty,
      hasWhatsAppSource: sourceCount > 0,
      email: _nullableString(json['email']),
      companyName: companyName.isEmpty ? null : companyName,
      notes: _nullableString(json['notes']),
      sourceLabels: sourceLabels,
      avatarUrl: _nullableString(
        json['primary_avatar_url'] ?? json['primaryAvatarUrl'],
      ),
      displayName: displayName,
    );
  }

  final String id;
  final String name;
  final String phone;
  final String status;
  final String tag;
  final bool hasPhone;
  final bool hasCompany;
  final bool hasWhatsAppSource;
  final String? email;
  final String? companyName;
  final String? notes;
  final List<String> sourceLabels;
  final String? avatarUrl;
  final String? displayName;

  bool matchesSearch(String search) {
    final normalized = search.trim().toLowerCase();
    if (normalized.isEmpty) return true;
    return '$name $phone $tag'.toLowerCase().contains(normalized);
  }

  bool matchesFilter(String filter) {
    switch (filter) {
      case 'WhatsApp':
        return hasWhatsAppSource;
      case 'Company':
        return hasCompany;
      case 'No Phone':
        return !hasPhone;
      case 'All':
      default:
        return true;
    }
  }

  static String _firstString(List<Object?> values) {
    for (final value in values) {
      if (value is String && value.trim().isNotEmpty) return value.trim();
    }
    return '';
  }

  static int _readInt(Object? value) {
    if (value is int) return value;
    if (value is num) return value.toInt();
    if (value is String) return int.tryParse(value) ?? 0;
    return 0;
  }

  static String? _nullableString(Object? value) {
    if (value is String && value.trim().isNotEmpty) return value.trim();
    return null;
  }

  static List<String> _readSourceLabels(Object? value) {
    if (value is! List) return const [];
    return value
        .whereType<Map<String, dynamic>>()
        .map((source) => _nullableString(source['label']))
        .whereType<String>()
        .toList();
  }

  static String _formatStatus(Object? value) {
    if (value is! String || value.trim().isEmpty) return 'Active';
    return value
        .trim()
        .split('_')
        .where((part) => part.isNotEmpty)
        .map((part) => '${part[0].toUpperCase()}${part.substring(1)}')
        .join(' ');
  }
}

class ContactsService {
  const ContactsService({required this.authService});

  static const Duration _cacheTtl = Duration(seconds: 45);
  static final Map<String, ServiceCacheEntry<List<CrmContact>>> _contactsCache =
      {};

  final AuthService authService;

  Future<List<CrmContact>> fetchContacts({
    int? days,
    bool forceRefresh = false,
  }) async {
    final session = authService.session.value;
    final query = <String, String>{};
    final organizationId = session?.user.organizationId;
    if (organizationId != null && organizationId.isNotEmpty) {
      query['organization_id'] = organizationId;
    }
    if (days != null) {
      query['days'] = days.toString();
    }
    final cacheKey = _cacheKey(organizationId, days);
    final cached = _contactsCache[cacheKey];
    if (!forceRefresh && cached != null && cached.isFresh(_cacheTtl)) {
      return cached.value;
    }

    final url = AppConfig.apiUri(
      '/mobile/v1/contacts',
    ).replace(queryParameters: query.isEmpty ? null : query);
    final response = await authService.authenticatedGet(url);
    final decoded = _decodeObject(response.body);

    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw ContactsServiceException(_extractError(decoded));
    }

    final data = decoded['data'];
    if (data is! List) {
      throw const ContactsServiceException(
        'Contacts response was not recognized.',
      );
    }

    final contacts = data
        .whereType<Map<String, dynamic>>()
        .map(CrmContact.fromJson)
        .where((contact) => contact.id.isNotEmpty)
        .toList();
    _contactsCache[cacheKey] = ServiceCacheEntry(
      value: contacts,
      savedAt: DateTime.now(),
    );
    return contacts;
  }

  Future<CrmContact> fetchContact(String contactId) async {
    final session = authService.session.value;
    final query = <String, String>{};
    final organizationId = session?.user.organizationId;
    if (organizationId != null && organizationId.isNotEmpty) {
      query['organization_id'] = organizationId;
    }

    final url = AppConfig.apiUri(
      '/mobile/v1/contacts/$contactId',
    ).replace(queryParameters: query.isEmpty ? null : query);
    final response = await authService.authenticatedGet(url);
    final decoded = _decodeObject(response.body);

    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw ContactsServiceException(_extractError(decoded));
    }

    final data = decoded['data'];
    if (data is! Map<String, dynamic>) {
      throw const ContactsServiceException(
        'Contact response was not recognized.',
      );
    }

    if (data['is_merged'] == true) {
      throw const ContactsServiceException(
        'This contact has been merged in the CRM.',
      );
    }

    return CrmContact.fromJson(data);
  }

  Future<CrmContact> createContact({
    String? displayName,
    String? phoneNumber,
    String? email,
    String? companyName,
    String? notes,
  }) async {
    final response = await authService.authenticatedPost(
      AppConfig.apiUri('/contacts'),
      body: jsonEncode({
        'displayName': displayName,
        'phoneNumber': phoneNumber,
        'email': email,
        'companyName': companyName,
        'notes': notes,
      }),
    );
    final decoded = _decodeObject(response.body);

    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw ContactsServiceException(_extractError(decoded));
    }

    final data = decoded['data'];
    if (data is! Map<String, dynamic>) {
      throw const ContactsServiceException(
        'Created contact response was not recognized.',
      );
    }

    final contact = CrmContact.fromJson(data);
    _contactsCache.clear();
    return contact;
  }

  Future<CrmContact> updateContact({
    required String contactId,
    String? displayName,
    String? phoneNumber,
    String? email,
    String? companyName,
    String? notes,
  }) async {
    final session = authService.session.value;
    final query = <String, String>{};
    final organizationId = session?.user.organizationId;
    if (organizationId != null && organizationId.isNotEmpty) {
      query['organization_id'] = organizationId;
    }

    final url = AppConfig.apiUri(
      '/mobile/v1/contacts/$contactId',
    ).replace(queryParameters: query.isEmpty ? null : query);
    final response = await authService.authenticatedPatch(
      url,
      body: jsonEncode({
        'displayName': displayName,
        'phoneNumber': phoneNumber,
        'email': email,
        'companyName': companyName,
        'notes': notes,
      }),
    );
    final decoded = _decodeObject(response.body);

    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw ContactsServiceException(_extractError(decoded));
    }

    final data = decoded['data'];
    if (data is! Map<String, dynamic>) {
      throw const ContactsServiceException(
        'Updated contact response was not recognized.',
      );
    }

    final contact = CrmContact.fromJson(data);
    _contactsCache.clear();
    return contact;
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

    return 'Unable to load CRM contacts.';
  }

  String _cacheKey(String? organizationId, int? days) {
    final org = organizationId == null || organizationId.isEmpty
        ? 'no-org'
        : organizationId;
    return '$org|days:${days ?? 'all'}';
  }
}

class ContactsServiceException implements Exception {
  const ContactsServiceException(this.message);

  final String message;

  @override
  String toString() => message;
}
