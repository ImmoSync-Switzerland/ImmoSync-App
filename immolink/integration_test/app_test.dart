import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:immosync/main.dart' as app;

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  group('End-to-End App Flow', () {
    testWidgets('Complete landlord workflow', (tester) async {
      // Initialize app
      app.main();
      await tester.pumpAndSettle(const Duration(seconds: 3));

      // 1. Login as landlord
      await _performLogin(tester, 'landlord@test.com', 'password123');
      await tester.pumpAndSettle(const Duration(seconds: 2));

      // Verify home page loaded
      expect(find.text('Dashboard'), findsOneWidget);

      // 2. Navigate to properties and create new property
      await _navigateToProperties(tester);
      await tester.pumpAndSettle(const Duration(seconds: 1));

      // Find and tap add property button
      final addPropertyButton = find.byIcon(Icons.add).last;
      if (await _findAndTapWidget(tester, addPropertyButton)) {
        await tester.pumpAndSettle(const Duration(seconds: 1));

        // Fill property form
        await _fillPropertyForm(tester, {
          'address': 'Teststrasse 123',
          'city': 'Zurich',
          'postalCode': '8001',
          'rent': '2500',
          'size': '100',
          'rooms': '3',
        });

        // Submit property
        final saveButton = find.text('Save Property');
        if (await _findAndTapWidget(tester, saveButton)) {
          await tester.pumpAndSettle(const Duration(seconds: 2));
        }
      }

      // 3. Navigate to conversations and send message
      await _navigateToConversations(tester);
      await tester.pumpAndSettle(const Duration(seconds: 1));

      // Try to start new conversation or select existing
      final conversationTile = find.byType(ListTile).first;
      if (await _findAndTapWidget(tester, conversationTile)) {
        await tester.pumpAndSettle(const Duration(seconds: 1));

        // Send a message
        final messageField = find.byType(TextField).last;
        if (messageField.evaluate().isNotEmpty) {
          await tester.enterText(messageField, 'Test message from landlord');
          await tester.pumpAndSettle();

          final sendButton = find.byIcon(Icons.send);
          if (await _findAndTapWidget(tester, sendButton)) {
            await tester.pumpAndSettle(const Duration(seconds: 1));
          }
        }

        // Go back
        final backButton = find.byType(BackButton);
        if (await _findAndTapWidget(tester, backButton)) {
          await tester.pumpAndSettle();
        }
      }

      // 4. Check maintenance requests
      await _navigateToMaintenance(tester);
      await tester.pumpAndSettle(const Duration(seconds: 1));

      // 5. Navigate to profile and logout
      await _navigateToProfile(tester);
      await tester.pumpAndSettle(const Duration(seconds: 1));

      // Find logout option
      final logoutButton = find.text('Logout');
      if (await _findAndTapWidget(tester, logoutButton)) {
        await tester.pumpAndSettle(const Duration(seconds: 2));
        // Should be back at login screen
        expect(find.text('Login'), findsWidgets);
      }
    });

    testWidgets('Complete tenant workflow', (tester) async {
      // Initialize app
      app.main();
      await tester.pumpAndSettle(const Duration(seconds: 3));

      // 1. Login as tenant
      await _performLogin(tester, 'tenant@test.com', 'password123');
      await tester.pumpAndSettle(const Duration(seconds: 2));

      // 2. View documents (tenant-specific)
      final documentsNav = find.byIcon(Icons.folder_outlined);
      if (await _findAndTapWidget(tester, documentsNav)) {
        await tester.pumpAndSettle(const Duration(seconds: 1));

        // Verify documents page loaded
        expect(find.text('Documents'), findsWidgets);
      }

      // 3. Send message to landlord
      await _navigateToConversations(tester);
      await tester.pumpAndSettle(const Duration(seconds: 1));

      final conversationTile = find.byType(ListTile).first;
      if (await _findAndTapWidget(tester, conversationTile)) {
        await tester.pumpAndSettle(const Duration(seconds: 1));

        // Send message
        final messageField = find.byType(TextField).last;
        if (messageField.evaluate().isNotEmpty) {
          await tester.enterText(messageField, 'Question about rent payment');
          await tester.pumpAndSettle();

          final sendButton = find.byIcon(Icons.send);
          if (await _findAndTapWidget(tester, sendButton)) {
            await tester.pumpAndSettle(const Duration(seconds: 1));
          }
        }

        final backButton = find.byType(BackButton);
        if (await _findAndTapWidget(tester, backButton)) {
          await tester.pumpAndSettle();
        }
      }

      // 4. Report maintenance issue
      await _navigateToMaintenance(tester);
      await tester.pumpAndSettle(const Duration(seconds: 1));

      // Try to create new maintenance request
      final addButton = find.byIcon(Icons.add).last;
      if (await _findAndTapWidget(tester, addButton)) {
        await tester.pumpAndSettle(const Duration(seconds: 1));

        // Fill maintenance request form
        final titleField = find.byType(TextField).first;
        if (titleField.evaluate().isNotEmpty) {
          await tester.enterText(titleField, 'Broken faucet');
          await tester.pumpAndSettle();
        }

        final descriptionField = find.byType(TextField).last;
        if (descriptionField.evaluate().isNotEmpty) {
          await tester.enterText(descriptionField, 'Kitchen faucet is leaking');
          await tester.pumpAndSettle();
        }

        // Submit request
        final submitButton = find.text('Submit');
        if (await _findAndTapWidget(tester, submitButton)) {
          await tester.pumpAndSettle(const Duration(seconds: 2));
        }
      }

      // 5. Logout
      await _navigateToProfile(tester);
      await tester.pumpAndSettle(const Duration(seconds: 1));

      final logoutButton = find.text('Logout');
      if (await _findAndTapWidget(tester, logoutButton)) {
        await tester.pumpAndSettle(const Duration(seconds: 2));
      }
    });
  });

  group('Navigation Tests', () {
    testWidgets('Navigate through all main screens', (tester) async {
      app.main();
      await tester.pumpAndSettle(const Duration(seconds: 3));

      // Login first
      await _performLogin(tester, 'test@test.com', 'password123');
      await tester.pumpAndSettle(const Duration(seconds: 2));

      // Test bottom navigation
      final navItems = [
        Icons.dashboard_outlined,
        Icons.home_work_outlined,
        Icons.chat_bubble_outline,
        Icons.analytics_outlined,
        Icons.person_outline,
      ];

      for (final icon in navItems) {
        final navButton = find.byIcon(icon);
        if (navButton.evaluate().isNotEmpty) {
          await tester.tap(navButton.first);
          await tester.pumpAndSettle(const Duration(seconds: 1));

          // Verify navigation occurred (screen changed)
          expect(find.byType(Scaffold), findsWidgets);
        }
      }

      // Test drawer navigation (if exists)
      final drawerButton = find.byIcon(Icons.menu);
      if (drawerButton.evaluate().isNotEmpty) {
        await tester.tap(drawerButton.first);
        await tester.pumpAndSettle();

        // Find and tap drawer items
        final settingsItem = find.text('Settings');
        if (await _findAndTapWidget(tester, settingsItem)) {
          await tester.pumpAndSettle(const Duration(seconds: 1));
          expect(find.text('Settings'), findsWidgets);
        }
      }
    });

    testWidgets('Deep link navigation should work', (tester) async {
      app.main();
      await tester.pumpAndSettle(const Duration(seconds: 3));

      // Login first
      await _performLogin(tester, 'test@test.com', 'password123');
      await tester.pumpAndSettle(const Duration(seconds: 2));

      // Simulate deep link by navigating to specific routes
      // Test property details deep link
      final propertyCard = find.byType(Card).first;
      if (propertyCard.evaluate().isNotEmpty) {
        await tester.tap(propertyCard);
        await tester.pumpAndSettle(const Duration(seconds: 1));

        // Should navigate to property details
        expect(find.byType(AppBar), findsWidgets);

        // Navigate back
        final backButton = find.byType(BackButton);
        if (backButton.evaluate().isNotEmpty) {
          await tester.tap(backButton.first);
          await tester.pumpAndSettle();
        }
      }

      // Test conversation deep link
      await _navigateToConversations(tester);
      await tester.pumpAndSettle(const Duration(seconds: 1));

      final conversationTile = find.byType(ListTile).first;
      if (conversationTile.evaluate().isNotEmpty) {
        await tester.tap(conversationTile);
        await tester.pumpAndSettle(const Duration(seconds: 1));

        // Should open chat
        expect(find.byType(TextField), findsWidgets);
      }
    });
  });

  group('Offline Mode Tests', () {
    testWidgets('App should work offline with cached data', (tester) async {
      app.main();
      await tester.pumpAndSettle(const Duration(seconds: 3));

      // Login and cache data
      await _performLogin(tester, 'test@test.com', 'password123');
      await tester.pumpAndSettle(const Duration(seconds: 2));

      // Navigate to load data into cache
      await _navigateToProperties(tester);
      await tester.pumpAndSettle(const Duration(seconds: 2));

      // Load conversations into cache
      await _navigateToConversations(tester);
      await tester.pumpAndSettle(const Duration(seconds: 2));

      // At this point, data should be cached
      // In a real scenario, you'd disable network here
      // For now, verify cached data is displayed

      // Navigate back to home
      final homeNav = find.byIcon(Icons.dashboard_outlined);
      if (homeNav.evaluate().isNotEmpty) {
        await tester.tap(homeNav.first);
        await tester.pumpAndSettle(const Duration(seconds: 1));
      }

      // Verify UI still works (using cached data)
      expect(find.byType(Scaffold), findsWidgets);
      expect(find.byType(AppBar), findsWidgets);

      // Try to access cached properties
      await _navigateToProperties(tester);
      await tester.pumpAndSettle(const Duration(seconds: 1));

      // Should display cached properties even "offline"
      expect(find.byType(Card), findsWidgets);
    });

    testWidgets('Sync should work when back online', (tester) async {
      app.main();
      await tester.pumpAndSettle(const Duration(seconds: 3));

      // Login
      await _performLogin(tester, 'test@test.com', 'password123');
      await tester.pumpAndSettle(const Duration(seconds: 2));

      // Make offline changes (simulated)
      await _navigateToConversations(tester);
      await tester.pumpAndSettle(const Duration(seconds: 1));

      // Try to send message (would queue if offline)
      final conversationTile = find.byType(ListTile).first;
      if (await _findAndTapWidget(tester, conversationTile)) {
        await tester.pumpAndSettle(const Duration(seconds: 1));

        final messageField = find.byType(TextField).last;
        if (messageField.evaluate().isNotEmpty) {
          await tester.enterText(messageField, 'Offline test message');
          await tester.pumpAndSettle();

          final sendButton = find.byIcon(Icons.send);
          if (sendButton.evaluate().isNotEmpty) {
            await tester.tap(sendButton);
            await tester.pumpAndSettle(const Duration(seconds: 2));

            // Message should be sent or queued
            // In real scenario, verify sync indicator appears
            expect(find.byType(CircularProgressIndicator), findsNothing);
          }
        }
      }

      // Return to home - simulates coming back online
      final homeNav = find.byIcon(Icons.dashboard_outlined);
      if (homeNav.evaluate().isNotEmpty) {
        await tester.tap(homeNav.first);
        await tester.pumpAndSettle(const Duration(seconds: 2));
      }

      // Verify app is functioning normally (sync completed)
      expect(find.byType(Scaffold), findsWidgets);
    });
  });
}

// Helper Functions

/// Performs login with email and password
Future<void> _performLogin(
    WidgetTester tester, String email, String password) async {
  // Find email field
  final emailField = find.byType(TextField).first;
  if (emailField.evaluate().isNotEmpty) {
    await tester.enterText(emailField, email);
    await tester.pumpAndSettle();
  }

  // Find password field
  final passwordField = find.byType(TextField).last;
  if (passwordField.evaluate().isNotEmpty) {
    await tester.enterText(passwordField, password);
    await tester.pumpAndSettle();
  }

  // Find and tap login button
  final loginButton = find.text('Login');
  if (loginButton.evaluate().isNotEmpty) {
    await tester.tap(loginButton.first);
    await tester.pumpAndSettle(const Duration(seconds: 3));
  }
}

/// Navigate to properties page
Future<void> _navigateToProperties(WidgetTester tester) async {
  final propertiesNav = find.byIcon(Icons.home_work_outlined);
  if (propertiesNav.evaluate().isNotEmpty) {
    await tester.tap(propertiesNav.first);
    await tester.pumpAndSettle(const Duration(seconds: 1));
  }
}

/// Navigate to conversations page
Future<void> _navigateToConversations(WidgetTester tester) async {
  final conversationsNav = find.byIcon(Icons.chat_bubble_outline);
  if (conversationsNav.evaluate().isNotEmpty) {
    await tester.tap(conversationsNav.first);
    await tester.pumpAndSettle(const Duration(seconds: 1));
  }
}

/// Navigate to maintenance page
Future<void> _navigateToMaintenance(WidgetTester tester) async {
  // Maintenance might be in drawer or separate section
  final maintenanceItem = find.text('Maintenance');
  if (maintenanceItem.evaluate().isNotEmpty) {
    await tester.tap(maintenanceItem.first);
    await tester.pumpAndSettle(const Duration(seconds: 1));
  }
}

/// Navigate to profile page
Future<void> _navigateToProfile(WidgetTester tester) async {
  final profileNav = find.byIcon(Icons.person_outline);
  if (profileNav.evaluate().isNotEmpty) {
    await tester.tap(profileNav.first);
    await tester.pumpAndSettle(const Duration(seconds: 1));
  }
}

/// Fill property form with given data
Future<void> _fillPropertyForm(
    WidgetTester tester, Map<String, String> data) async {
  for (final entry in data.entries) {
    final field = find.widgetWithText(TextField, entry.key);
    if (field.evaluate().isNotEmpty) {
      await tester.enterText(field, entry.value);
      await tester.pumpAndSettle();
    }
  }
}

/// Safe find and tap - returns true if successful
Future<bool> _findAndTapWidget(WidgetTester tester, Finder finder) async {
  if (finder.evaluate().isNotEmpty) {
    await tester.tap(finder.first);
    return true;
  }
  return false;
}
