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

    test(
      'reads mobile sort timestamp separately from provider sent timestamp',
      () {
        final message = InboxMessage.fromJson({
          'id': 'message-3',
          'direction': 'incoming',
          'message_type': 'text',
          'content_text': 'sweet dream',
          'sentAt': '2026-06-01T08:00:00.000Z',
          'createdAt': '2026-06-01T09:00:00.000Z',
          'sortAt': '2026-06-01T09:00:00.000Z',
        });

        expect(
          message.sentAt?.toUtc().toIso8601String(),
          '2026-06-01T08:00:00.000Z',
        );
        expect(
          message.createdAt?.toUtc().toIso8601String(),
          '2026-06-01T09:00:00.000Z',
        );
        expect(
          message.sortAt?.toUtc().toIso8601String(),
          '2026-06-01T09:00:00.000Z',
        );
        expect(
          message.timelineAt?.toUtc().toIso8601String(),
          '2026-06-01T09:00:00.000Z',
        );
      },
    );

    test('reads snake_case sort_at from inbox thread endpoint payload', () {
      final message = InboxMessage.fromJson({
        'id': 'message-sort-snake',
        'direction': 'incoming',
        'message_type': 'text',
        'content_text': 'Snake case sort',
        'sent_at': '2026-06-01T08:00:00.000Z',
        'sort_at': '2026-06-01T08:30:00.000Z',
      });

      expect(
        message.sortAt?.toUtc().toIso8601String(),
        '2026-06-01T08:30:00.000Z',
      );
      expect(
        message.timelineAt?.toUtc().toIso8601String(),
        '2026-06-01T08:30:00.000Z',
      );
    });

    test('sorts message timeline by sortAt then sentAt', () {
      final olderPreviewText = InboxMessage.fromJson({
        'id': 'message-1',
        'direction': 'incoming',
        'message_type': 'text',
        'content_text': 'Latest message preview text',
        'sentAt': '2026-06-01T08:00:00.000Z',
        'createdAt': '2026-06-01T10:30:00.000Z',
      });
      final latestBySortTime = InboxMessage.fromJson({
        'id': 'message-2',
        'direction': 'incoming',
        'message_type': 'text',
        'content_text': 'Actual latest message',
        'sentAt': '2026-06-01T09:00:00.000Z',
        'sortAt': '2026-06-01T11:00:00.000Z',
      });
      final withoutTimestamp = InboxMessage.fromJson({
        'id': 'message-3',
        'direction': 'incoming',
        'message_type': 'text',
        'content_text': 'Missing timestamps',
      });

      final messages = [latestBySortTime, withoutTimestamp, olderPreviewText]
        ..sort(InboxMessage.compareByTimelineAsc);

      expect(
        messages.map((message) => message.id).toList(),
        ['message-3', 'message-1', 'message-2'],
      );
    });

    test('sorts message timeline newest first for thread rendering', () {
      final oldest = InboxMessage.fromJson({
        'id': 'message-oldest',
        'direction': 'incoming',
        'message_type': 'text',
        'content_text': 'Oldest',
        'sentAt': '2026-06-01T08:00:00.000Z',
      });
      final latest = InboxMessage.fromJson({
        'id': 'message-latest',
        'direction': 'incoming',
        'message_type': 'text',
        'content_text': 'Latest',
        'sentAt': '2026-06-01T10:00:00.000Z',
      });
      final middle = InboxMessage.fromJson({
        'id': 'message-middle',
        'direction': 'incoming',
        'message_type': 'text',
        'content_text': 'Middle',
        'sentAt': '2026-06-01T09:00:00.000Z',
      });

      final messages = [middle, oldest, latest]
        ..sort(InboxMessage.compareByTimelineDesc);

      expect(
        messages.map((message) => message.id).toList(),
        ['message-latest', 'message-middle', 'message-oldest'],
      );
    });

    test('falls back to createdAt when no sentAt is available', () {
      final message = InboxMessage.fromJson({
        'id': 'message-4',
        'direction': 'outgoing',
        'message_type': 'text',
        'content_text': 'Queued only',
        'createdAt': '2026-06-01T12:30:00.000Z',
      });

      expect(
        message.timelineAt?.toUtc().toIso8601String(),
        '2026-06-01T12:30:00.000Z',
      );
    });
  });

  group('MessagePagination', () {
    test('reads backend pagination cursor response', () {
      final pagination = MessagePagination.fromJson({
        'limit': 20,
        'hasMore': true,
        'nextBefore': {
          'sentAt': '2026-06-01T08:00:00.000Z',
          'id': '00000000-0000-0000-0000-000000000001',
        },
      });

      expect(pagination.limit, 20);
      expect(pagination.hasMore, isTrue);
      expect(pagination.nextBefore?.sentAt, '2026-06-01T08:00:00.000Z');
      expect(pagination.nextBefore?.id, '00000000-0000-0000-0000-000000000001');
    });
  });

  group('InboxConversation', () {
    test('sorts latest conversations first', () {
      final older = InboxConversation.fromJson({
        'id': 'conversation-1',
        'contact_name': 'Older',
        'last_message_preview': 'Older message',
        'unread_count': 0,
        'last_message_at': '2026-06-01T08:00:00.000Z',
      });
      final latest = InboxConversation.fromJson({
        'id': 'conversation-2',
        'contact_name': 'Latest',
        'last_message_preview': 'Latest message',
        'unread_count': 1,
        'last_message_at': '2026-06-01T09:00:00.000Z',
      });
      final withoutTimestamp = InboxConversation.fromJson({
        'id': 'conversation-3',
        'contact_name': 'No timestamp',
        'last_message_preview': 'No timestamp message',
        'unread_count': 0,
      });

      final conversations = [older, withoutTimestamp, latest]
        ..sort(InboxConversation.compareByLatestMessageDesc);

      expect(
        conversations.map((conversation) => conversation.id).toList(),
        ['conversation-2', 'conversation-1', 'conversation-3'],
      );
    });
  });
}
