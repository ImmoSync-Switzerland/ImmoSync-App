import 'package:flutter_test/flutter_test.dart';
import 'package:immosync/features/chat/domain/models/chat_message.dart';
import 'package:immosync/features/chat/domain/models/conversation.dart';
import 'package:immosync/features/chat/infrastructure/matrix_timeline_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('ChatMessage parsing', () {
    test('fromMap hydrates encrypted payload correctly', () {
      final now = DateTime.now().toUtc();
      final map = {
        '_id': 'event-123',
        'senderId': 'user_a',
        'receiverId': 'user_b',
        'content': '',
        'timestamp': now.toIso8601String(),
        'messageType': 'text',
        'e2ee': {
          'ciphertext': 'cipher',
          'iv': 'iv',
          'tag': 'tag',
          'v': 1,
        },
      };

      final message = ChatMessage.fromMap(map);
      expect(message.id, 'event-123');
      expect(message.senderId, 'user_a');
      expect(message.receiverId, 'user_b');
      expect(message.isEncrypted, isTrue);
      expect(message.e2ee, isNotNull);
      expect(message.e2ee!['ciphertext'], 'cipher');
      expect(
          message.timestamp.millisecondsSinceEpoch, now.millisecondsSinceEpoch);
    });
  });

  group('Conversation parsing', () {
    test('resolves other participant avatar gracefully', () {
      final data = {
        '_id': 'conv-1',
        'propertyId': 'prop',
        'landlordId': 'land',
        'tenantId': 'ten',
        'propertyAddress': 'Test Street',
        'lastMessage': 'Hello',
        'lastMessageTime': DateTime.now().toIso8601String(),
        'otherParticipantId': 'user_b',
        'otherParticipantAvatar': 'https://example.com/avatar.png',
      };

      final conversation = Conversation.fromMap(data);
      expect(conversation.id, 'conv-1');
      expect(conversation.otherParticipantId, 'user_b');
      expect(conversation.getOtherParticipantAvatarRef(),
          'https://example.com/avatar.png');
    });
  });

  group('Matrix timeline buffer', () {
    test('snapshot returns sorted copy', () {
      final service = MatrixTimelineService.instance;
      const roomId = 'room-test-sorted';

      service.pushLocal(
        roomId,
        ChatMessage(
          id: '2',
          senderId: 'b',
          receiverId: 'a',
          content: 'second',
          timestamp: DateTime.now().add(const Duration(seconds: 1)),
        ),
      );
      service.pushLocal(
        roomId,
        ChatMessage(
          id: '1',
          senderId: 'a',
          receiverId: 'b',
          content: 'first',
          timestamp: DateTime.now(),
        ),
      );

      final snapshot = service.snapshot(roomId);
      expect(snapshot, isNotNull);
      expect(snapshot, hasLength(2));
      expect(snapshot!.first.id, '1');
      expect(snapshot.last.id, '2');

      // Ensure returned list is a defensive copy
      snapshot.first = snapshot.first;
      final snapshotAgain = service.snapshot(roomId);
      expect(snapshotAgain!.first.id, '1');
    });

    test('ingestMatrixEvent prevents duplicates', () {
      final service = MatrixTimelineService.instance;
      const roomId = 'room-test-duplicate';

      final msg = ChatMessage(
        id: 'dup',
        senderId: 'a',
        receiverId: 'b',
        content: 'hello',
        timestamp: DateTime.now(),
      );

      service.ingestMatrixEvent(roomId, msg);
      service.ingestMatrixEvent(roomId, msg);

      final snapshot = service.snapshot(roomId);
      expect(snapshot, isNotNull);
      expect(snapshot, hasLength(1));
    });
  });
}
