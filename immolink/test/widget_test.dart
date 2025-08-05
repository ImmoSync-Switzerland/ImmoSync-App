import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:immolink/main.dart';
import 'package:immolink/features/chat/presentation/pages/conversations_list_page.dart';

void main() {
  testWidgets('Initial app test', (WidgetTester tester) async {
    // Build our app and trigger a frame.
    await tester.pumpWidget(
      const ProviderScope(
        child: ImmoLink(),
      ),
    );

    // Verify that our app renders without errors
    expect(find.byType(MaterialApp), findsOneWidget);
  });

  testWidgets('ConversationsListPage has only contact book button, no start new chat', (WidgetTester tester) async {
    // Create a test widget with the conversations page
    await tester.pumpWidget(
      const ProviderScope(
        child: MaterialApp(
          home: ConversationsListPage(),
        ),
      ),
    );

    // Wait for any async operations to complete
    await tester.pumpAndSettle();

    // Look for contacts icon (should exist)
    expect(find.byIcon(Icons.contacts_outlined), findsOneWidget);
    
    // Look for add_comment icon (should NOT exist - this was the "start new chat" button)
    expect(find.byIcon(Icons.add_comment_outlined), findsNothing);
    
    // Verify we still have the app bar
    expect(find.byType(AppBar), findsOneWidget);
  });
}