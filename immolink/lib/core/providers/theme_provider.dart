import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

// Theme mode provider to track current theme setting
final themeModeProvider = StateProvider<String>((ref) => 'light');

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
