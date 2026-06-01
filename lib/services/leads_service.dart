import 'dart:convert';

import '../config/app_config.dart';
import 'auth_service.dart';
import 'contacts_service.dart';

class SalesLead {
  const SalesLead({
    required this.id,
    required this.contactId,
    required this.status,
    required this.displayStatus,
    required this.name,
    required this.phone,
    this.source,
    this.temperature,
    this.assignedUserId,
    this.createdAt,
    this.updatedAt,
  });

  factory SalesLead.fromJson(Map<String, dynamic> json) {
    final status = _readString(json['status'], fallback: 'new_lead');
    final contactId = _readString(
      json['contact_id'] ?? json['contactId'],
      fallback: '',
    );
    final name = _readString(
      json['contact_name'] ?? json['contactName'],
      fallback: 'Unknown Contact',
    );
    final phone = _readString(
      json['primary_phone_normalized'] ??
          json['primaryPhoneNormalized'] ??
          json['primary_phone_e164'] ??
          json['primaryPhoneE164'],
      fallback: 'No phone',
    );

    return SalesLead(
      id: (json['id'] ?? '').toString(),
      contactId: contactId,
      status: status,
      displayStatus: formatStatus(status),
      name: name,
      phone: phone,
      source: _nullableString(json['source']),
      temperature: _nullableString(json['temperature']),
      assignedUserId: _nullableString(
        json['assigned_user_id'] ?? json['assignedUserId'],
      ),
      createdAt: _readDate(json['created_at'] ?? json['createdAt']),
      updatedAt: _readDate(json['updated_at'] ?? json['updatedAt']),
    );
  }

  final String id;
  final String contactId;
  final String status;
  final String displayStatus;
  final String name;
  final String phone;
  final String? source;
  final String? temperature;
  final String? assignedUserId;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  CrmContact toContactStub() {
    return CrmContact(
      id: contactId,
      name: name,
      phone: phone,
      status: displayStatus,
      tag: source ?? temperatureLabel ?? 'Lead',
      hasPhone: phone != 'No phone',
      hasCompany: false,
      hasWhatsAppSource: false,
    );
  }

  String? get temperatureLabel {
    final value = temperature;
    if (value == null || value.isEmpty) return null;
    return value[0].toUpperCase() + value.substring(1);
  }

  static String formatStatus(String status) {
    switch (status.trim().toLowerCase()) {
      case 'new_lead':
        return 'New Lead';
      case 'contacted':
        return 'Contacted';
      case 'interested':
        return 'Interested';
      case 'processing':
        return 'Processing';
      case 'closed_won':
        return 'Closed Won';
      case 'closed_lost':
        return 'Closed Lost';
      default:
        return status
            .trim()
            .split('_')
            .where((part) => part.isNotEmpty)
            .map((part) => '${part[0].toUpperCase()}${part.substring(1)}')
            .join(' ');
    }
  }

  static String _readString(Object? value, {required String fallback}) {
    if (value is String && value.trim().isNotEmpty) return value.trim();
    return fallback;
  }

  static String? _nullableString(Object? value) {
    if (value is String && value.trim().isNotEmpty) return value.trim();
    return null;
  }

  static DateTime? _readDate(Object? value) {
    if (value is! String || value.isEmpty) return null;
    return DateTime.tryParse(value)?.toLocal();
  }
}

class LeadsService {
  const LeadsService({required this.authService});

  final AuthService authService;

  Future<List<SalesLead>> fetchLeads() async {
    final session = authService.session.value;
    final query = <String, String>{};
    final organizationId = session?.user.organizationId;
    if (organizationId != null && organizationId.isNotEmpty) {
      query['organization_id'] = organizationId;
    }

    final url = AppConfig.apiUri(
      '/leads',
    ).replace(queryParameters: query.isEmpty ? null : query);
    final response = await authService.authenticatedGet(url);
    final decoded = _decodeObject(response.body);

    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw LeadsServiceException(_extractError(decoded));
    }

    final data = decoded['data'];
    if (data is! List) {
      throw const LeadsServiceException('Leads response was not recognized.');
    }

    return data
        .whereType<Map<String, dynamic>>()
        .map(SalesLead.fromJson)
        .where((lead) => lead.id.isNotEmpty && lead.contactId.isNotEmpty)
        .toList();
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

    return 'Unable to load leads.';
  }
}

class LeadsServiceException implements Exception {
  const LeadsServiceException(this.message);

  final String message;

  @override
  String toString() => message;
}
