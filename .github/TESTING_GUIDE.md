# ImmoLink Testing Strategy

## Test Structure

```
test/
├── features/           # Feature-specific tests
│   ├── auth_test.dart
│   ├── property_test.dart
│   ├── chat_test.dart
│   ├── payment_test.dart
│   ├── maintenance_test.dart
│   └── document_test.dart
├── models_test.dart    # Data model tests
├── services_test.dart  # Service layer tests
└── widget_test.dart    # Widget tests

integration_test/
└── app_test.dart       # End-to-end tests
```

## Test Coverage Goals

- **Overall**: ≥70%
- **Models**: ≥80%
- **Services**: ≥75%
- **Providers**: ≥70%
- **Widgets**: ≥60%

## Running Tests

### All Tests
```bash
flutter test
```

### Specific Test File
```bash
flutter test test/features/auth_test.dart
```

### With Coverage
```bash
flutter test --coverage
```

### Integration Tests
```bash
flutter test integration_test/
```

## Writing Tests

### Unit Test Example

```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';

void main() {
  group('AuthService', () {
    late AuthService authService;
    late MockHttpClient mockClient;

    setUp(() {
      mockClient = MockHttpClient();
      authService = AuthService(client: mockClient);
    });

    test('login should return user on success', () async {
      // Arrange
      when(mockClient.post(any, body: anyNamed('body')))
          .thenAnswer((_) async => Response('{"user": {...}}', 200));

      // Act
      final result = await authService.login('email', 'password');

      // Assert
      expect(result, isA<User>());
    });
  });
}
```

### Widget Test Example

```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/material.dart';

void main() {
  testWidgets('LoginButton should trigger login', (tester) async {
    // Arrange
    bool loginCalled = false;
    await tester.pumpWidget(
      MaterialApp(
        home: LoginButton(onPressed: () => loginCalled = true),
      ),
    );

    // Act
    await tester.tap(find.byType(ElevatedButton));
    await tester.pump();

    // Assert
    expect(loginCalled, isTrue);
  });
}
```

### Integration Test Example

```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('complete login flow', (tester) async {
    // Launch app
    await tester.pumpWidget(MyApp());

    // Navigate to login
    await tester.tap(find.text('Login'));
    await tester.pumpAndSettle();

    // Enter credentials
    await tester.enterText(find.byKey(Key('email')), 'test@example.com');
    await tester.enterText(find.byKey(Key('password')), 'password123');

    // Submit
    await tester.tap(find.text('Sign In'));
    await tester.pumpAndSettle();

    // Verify navigation to dashboard
    expect(find.text('Dashboard'), findsOneWidget);
  });
}
```

## Mocking

Use `mockito` for mocking dependencies:

```bash
flutter pub run build_runner build
```

This generates mock classes from annotations:

```dart
import 'package:mockito/annotations.dart';

@GenerateMocks([HttpClient, AuthService])
void main() {
  // Use MockHttpClient, MockAuthService
}
```

## Best Practices

1. **AAA Pattern**: Arrange, Act, Assert
2. **Isolation**: Each test should be independent
3. **Naming**: Use descriptive test names
4. **Coverage**: Aim for edge cases, not just happy paths
5. **Speed**: Keep unit tests fast (< 1s each)
6. **Mocking**: Mock external dependencies (API, DB)
7. **Cleanup**: Use `setUp()` and `tearDown()`

## CI/CD Integration

Tests run automatically on:
- Every push to `main` or `develop`
- Every pull request
- Manual workflow dispatch

See `.github/workflows/flutter_ci.yml` for configuration.

## Debugging Tests

### Verbose Output
```bash
flutter test --verbose
```

### Run Single Test
```bash
flutter test test/features/auth_test.dart --name="login should succeed"
```

### Update Golden Files
```bash
flutter test --update-goldens
```

## Resources

- [Flutter Testing Guide](https://docs.flutter.dev/testing)
- [Mockito Package](https://pub.dev/packages/mockito)
- [Integration Testing](https://docs.flutter.dev/testing/integration-tests)
