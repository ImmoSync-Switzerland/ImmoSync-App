import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:immolink/features/property/domain/models/property.dart';
import 'package:immolink/features/property/presentation/widgets/property_card.dart';
import 'package:immolink/core/widgets/app_button.dart';
import 'package:immolink/core/theme/app_spacing.dart';

void main() {
  group('Layout Tests', () {
    testWidgets('PropertyCard handles long text without overflow', (WidgetTester tester) async {
      // Create a property with very long address to test overflow handling
      final property = Property(
        id: 'test-id',
        landlordId: 'landlord-id',
        tenantIds: [],
        address: Address(
          street: 'This is a very long street address that should be handled properly without causing overflow issues in the UI',
          city: 'A Very Long City Name That Should Be Truncated',
          postalCode: '12345',
          country: 'Switzerland',
        ),
        rentAmount: 2500.0,
        details: PropertyDetails(
          size: 100.0,
          rooms: 3,
          amenities: ['Parking', 'Elevator'],
        ),
        status: 'available',
        imageUrls: [],
        outstandingPayments: 0.0,
      );

      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            home: Scaffold(
              body: Container(
                width: 300, // Constrained width to test overflow
                child: PropertyCard(
                  property: property,
                  onTap: () {},
                ),
              ),
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Verify that the PropertyCard renders without RenderFlex overflow
      expect(tester.takeException(), isNull);
      
      // Verify that text is properly truncated
      expect(find.byType(PropertyCard), findsOneWidget);
      expect(find.text('€2500/month'), findsOneWidget);
    });

    testWidgets('AppButton has minimum touch target height', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: AppButton.primary(
              text: 'Test Button',
              onPressed: () {},
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Find the button and verify its height meets accessibility guidelines
      final buttonFinder = find.byType(ElevatedButton);
      expect(buttonFinder, findsOneWidget);
      
      final renderBox = tester.renderObject<RenderBox>(buttonFinder);
      
      // Button should be at least 44pt high for accessibility
      expect(renderBox.size.height, greaterThanOrEqualTo(44.0));
    });

    testWidgets('Consistent spacing uses AppSpacing constants', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Column(
              children: [
                SizedBox(height: AppSpacing.lg),
                Text('Test Text'),
                SizedBox(height: AppSpacing.md),
                Text('Another Text'),
              ],
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Verify that AppSpacing constants are available and have expected values
      expect(AppSpacing.lg, equals(16.0));
      expect(AppSpacing.md, equals(12.0));
      expect(AppSpacing.sm, equals(8.0));
    });

    testWidgets('Container with proper bottom padding for navigation', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ListView(
              children: [
                Container(height: 100, color: Colors.red),
                Container(height: 100, color: Colors.green),
                Container(height: 100, color: Colors.blue),
                SizedBox(height: 100), // Bottom padding for navigation
              ],
            ),
            bottomNavigationBar: BottomNavigationBar(
              items: [
                BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Home'),
                BottomNavigationBarItem(icon: Icon(Icons.search), label: 'Search'),
              ],
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Verify the layout renders without issues
      expect(tester.takeException(), isNull);
      expect(find.byType(BottomNavigationBar), findsOneWidget);
    });
  });
}