import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:immolink/core/theme/app_theme.dart';
import 'package:immolink/core/theme/app_colors.dart';
import 'package:immolink/core/providers/theme_provider.dart';

void main() {
  group('Dark Mode Tests', () {
    testWidgets('App should apply dark theme when theme mode is dark', (WidgetTester tester) async {
      // Create a container for Riverpod
      final container = ProviderContainer(
        overrides: [
          themeModeProvider.overrideWith((ref) => 'dark'),
        ],
      );

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: Consumer(
            builder: (context, ref, child) {
              final themeMode = ref.watch(themeModeProvider);
              return MaterialApp(
                theme: AppTheme.lightTheme,
                darkTheme: AppTheme.darkTheme,
                themeMode: themeMode == 'dark' ? ThemeMode.dark : ThemeMode.light,
                home: const Scaffold(
                  body: Text('Test'),
                ),
              );
            },
          ),
        ),
      );

      // Get the theme from the MaterialApp
      final BuildContext context = tester.element(find.byType(MaterialApp));
      final ThemeData theme = Theme.of(context);

      // Verify dark theme is applied
      expect(theme.brightness, equals(Brightness.dark));
      expect(theme.scaffoldBackgroundColor, equals(AppColors.darkPrimaryBackground));
    });

    testWidgets('Theme should have dark colors for all components', (WidgetTester tester) async {
      // Verify dark theme colors
      final darkTheme = AppTheme.darkTheme;
      
      expect(darkTheme.brightness, equals(Brightness.dark));
      expect(darkTheme.scaffoldBackgroundColor, equals(AppColors.darkPrimaryBackground));
      expect(darkTheme.cardTheme.color, equals(AppColors.darkSurfaceCards));
      expect(darkTheme.colorScheme.surface, equals(AppColors.darkSurfaceCards));
      expect(darkTheme.colorScheme.background, equals(AppColors.darkPrimaryBackground));
    });

    test('Dark theme colors should be different from light theme colors', () {
      // Verify that dark colors are actually different from light colors
      expect(AppColors.darkPrimaryBackground, isNot(equals(AppColors.primaryBackground)));
      expect(AppColors.darkSurfaceCards, isNot(equals(AppColors.surfaceCards)));
      expect(AppColors.darkTextPrimary, isNot(equals(AppColors.textPrimary)));
      expect(AppColors.darkTextSecondary, isNot(equals(AppColors.textSecondary)));
    });

    test('Dark theme should have proper contrast colors', () {
      // Verify dark theme colors are appropriate for dark backgrounds
      expect(AppColors.darkPrimaryBackground.computeLuminance(), lessThan(0.1));
      expect(AppColors.darkSurfaceCards.computeLuminance(), lessThan(0.2));
      expect(AppColors.darkTextPrimary.computeLuminance(), greaterThan(0.8));
    });
  });
}