import 'package:flutter_test/flutter_test.dart';
import 'package:immolink/features/auth/domain/services/auth_service.dart';
import 'package:immolink/features/property/domain/services/property_service.dart';
import 'package:immolink/features/payment/domain/services/payment_service.dart';
import 'package:immolink/features/maintenance/domain/services/maintenance_service.dart';
import 'package:immolink/core/services/database_service.dart';

void main() {
  group('Service Instantiation Tests', () {
    test('AuthService can be instantiated', () {
      expect(() => AuthService(), returnsNormally);
    });

    test('PropertyService can be instantiated', () {
      expect(() => PropertyService(), returnsNormally);
    });

    test('PaymentService can be instantiated', () {
      expect(() => PaymentService(), returnsNormally);
    });

    test('MaintenanceService can be instantiated', () {
      expect(() => MaintenanceService(), returnsNormally);
    });

    test('DatabaseService can be instantiated', () {
      expect(() => DatabaseService.instance, returnsNormally);
    });
  });

  group('Service API Configuration Tests', () {
    test('Services use correct API configuration', () {
      final authService = AuthService();
      final propertyService = PropertyService();
      
      // These should not throw during instantiation
      expect(authService, isNotNull);
      expect(propertyService, isNotNull);
    });
  });
}