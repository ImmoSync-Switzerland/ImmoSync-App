import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class LocaleProvider extends ChangeNotifier {
  Locale _locale = const Locale('en');

  Locale get locale => _locale;

  void setLocale(Locale locale) {
    if (_locale == locale) return;
    _locale = locale;
    notifyListeners();
  }

  void setLanguageCode(String languageCode) {
    setLocale(Locale(languageCode));
  }

  String get languageName => getLanguageName(_locale.languageCode);
}

final localeProvider =
    ChangeNotifierProvider<LocaleProvider>((ref) => LocaleProvider());

// Helper to get language name from code
String getLanguageName(String code) {
  switch (code) {
    case 'en':
      return 'English';
    case 'de':
      return 'Deutsch';
    case 'fr':
      return 'Français';
    case 'it':
      return 'Italiano';
    default:
      return 'English';
  }
}
