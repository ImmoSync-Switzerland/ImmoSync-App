import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

// Provider to load saved theme preference
final savedThemeProvider = FutureProvider<String>((ref) async {
  try {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('theme') ?? 'light';
  } catch (e) {
    print('Error loading saved theme: $e');
    return 'light';
  }
});

// Theme mode provider that initializes with saved preference
final themeModeProvider = StateNotifierProvider<ThemeModeNotifier, String>((ref) {
  return ThemeModeNotifier(ref);
});

class ThemeModeNotifier extends StateNotifier<String> {
  final Ref ref;
  
  ThemeModeNotifier(this.ref) : super('light') {
    _initializeTheme();
  }

  void _initializeTheme() {
    ref.listen(savedThemeProvider, (previous, next) {
      next.when(
        data: (theme) => state = theme,
        loading: () => {},
        error: (error, stack) => print('Error loading theme: $error'),
      );
    });
  }

  void updateTheme(String theme) {
    state = theme;
  }
}

// Helper to get the current ThemeMode enum
ThemeMode getThemeMode(String mode) {
  switch (mode) {
    case 'light':
      return ThemeMode.light;
    case 'dark':
      return ThemeMode.dark;
    case 'system':
      return ThemeMode.system;
    default:
      return ThemeMode.light;
  }
}

// Provider to check if system is in dark mode
final systemBrightnessProvider = Provider<Brightness>((ref) {
  return WidgetsBinding.instance.platformDispatcher.platformBrightness;
});

// Provider that determines the effective theme (resolves 'system' to actual theme)
final effectiveThemeProvider = Provider<String>((ref) {
  final themeMode = ref.watch(themeModeProvider);
  
  if (themeMode == 'system') {
    final systemBrightness = ref.watch(systemBrightnessProvider);
    return systemBrightness == Brightness.dark ? 'dark' : 'light';
  }
  
  return themeMode;
});
