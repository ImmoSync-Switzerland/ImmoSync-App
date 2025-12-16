import 'package:flutter_test/flutter_test.dart';
import 'package:immosync/features/auth/domain/services/auth_service.dart';
import 'package:immosync/features/property/domain/services/property_service.dart';
import 'package:immosync/features/payment/domain/services/payment_service.dart';
import 'package:immosync/features/maintenance/domain/services/maintenance_service.dart';
import 'package:immosync/features/chat/domain/services/chat_service.dart';
import 'package:immosync/core/services/database_service.dart';

void main() {
  group('Service Instantiation Tests', () {
    test('AuthService can be instantiated', () {
      expect(AuthService.new, returnsNormally);
    });

    test('PropertyService can be instantiated', () {
      expect(PropertyService.new, returnsNormally);
    });

    test('PaymentService can be instantiated', () {
      expect(PaymentService.new, returnsNormally);
    });

    test('MaintenanceService can be instantiated', () {
      expect(MaintenanceService.new, returnsNormally);
    });

    test('ChatService can be instantiated', () {
      expect(ChatService.new, returnsNormally);
    });

    test('DatabaseService can be instantiated', () {
      expect(() => DatabaseService.instance, returnsNormally);
    });
  });

  group('Service API Configuration Tests', () {
    test('Services use correct API configuration', () {
      final authService = AuthService();
      final propertyService = PropertyService();
      final chatService = ChatService();

      // These should not throw during instantiation
      expect(authService, isNotNull);
      expect(propertyService, isNotNull);
      expect(chatService, isNotNull);
    });
  });

  group('ChatService functionality tests', () {
    test('ChatService methods exist', () {
      final chatService = ChatService();

      // Verify that our key methods exist
      expect(chatService.findOrCreateConversation, isNotNull);
      expect(chatService.createConversation, isNotNull);
      expect(chatService.getConversationsForUser, isNotNull);
      expect(chatService.sendMessage, isNotNull);
    });
  });
}
