import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

class LocaleNotifier extends StateNotifier<Locale> {
  LocaleNotifier() : super(const Locale('de')) {
    // Default to German
    _loadSavedLocale();
  }

  // Load saved locale from shared preferences
  Future<void> _loadSavedLocale() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final savedLanguage =
          prefs.getString('language') ?? 'de'; // Default to German
      updateLanguage(savedLanguage);
    } catch (e) {
      print('Error loading saved locale: $e');
    }
  }

  void setLocale(String languageCode) {
    state = Locale(languageCode);
  }

  void updateLanguage(String language) {
    switch (language) {
      case 'en':
        state = const Locale('en');
        break;
      case 'de':
        state = const Locale('de');
        break;
      case 'fr':
        state = const Locale('fr');
        break;
      case 'it':
        state = const Locale('it');
        break;
      default:
        state = const Locale('de'); // Default to German instead of English
    }
  }
}

final localeProvider = StateNotifierProvider<LocaleNotifier, Locale>((ref) {
  return LocaleNotifier();
});

// Helper to get language name from code
String getLanguageName(String code) {
  switch (code) {
    case 'en':
      return 'English';
    case 'de':
      return 'German';
    case 'fr':
      return 'French';
    case 'it':
      return 'Italian';
    default:
      return 'English';
  }
}
