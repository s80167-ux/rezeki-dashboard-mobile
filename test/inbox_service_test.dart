import 'package:flutter_test/flutter_test.dart';
import 'package:rezeki_dashboard_app/services/inbox_service.dart';

void main() {
  group('InboxMessage', () {
    test('reads inbound text from nested WhatsApp conversation payload', () {
      final message = InboxMessage.fromJson({
        'id': 'message-1',
        'direction': 'incoming',
        'message_type': 'text',
        'content_text': null,
        'content_json': {
          'message': {'conversation': 'Hello from WhatsApp'},
        },
        'sent_at': '2026-06-01T08:00:00.000Z',
      });

      expect(message.contentText, 'Hello from WhatsApp');
    });

    test('reads inbound text from nested WhatsApp extended text payload', () {
      final message = InboxMessage.fromJson({
        'id': 'message-2',
        'direction': 'incoming',
        'message_type': 'text',
        'content_text': null,
        'content_json': {
          'rawPayload': {
            'message': {
              'extendedTextMessage': {'text': 'Extended hello'},
            },
          },
        },
        'sent_at': '2026-06-01T08:00:00.000Z',
      });

      expect(message.contentText, 'Extended hello');
    });
  });
}
