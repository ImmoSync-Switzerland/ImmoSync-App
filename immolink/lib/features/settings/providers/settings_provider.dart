import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../core/providers/locale_provider.dart';
import '../../../core/providers/currency_provider.dart';
import '../../../core/providers/theme_provider.dart';

// Settings state model
class AppSettings {
  final String language;
  final String theme;
  final String currency;
  final bool emailNotifications;
  final bool pushNotifications;
  final bool paymentReminders;

  AppSettings({
    this.language = 'en',
    this.theme = 'light',
    this.currency = 'CHF',
    this.emailNotifications = true,
    this.pushNotifications = true,
    this.paymentReminders = true,
  });

  AppSettings copyWith({
    String? language,
    String? theme,
    String? currency,
    bool? emailNotifications,
    bool? pushNotifications,
    bool? paymentReminders,
  }) {
    return AppSettings(
      language: language ?? this.language,
      theme: theme ?? this.theme,
      currency: currency ?? this.currency,
      emailNotifications: emailNotifications ?? this.emailNotifications,
      pushNotifications: pushNotifications ?? this.pushNotifications,
      paymentReminders: paymentReminders ?? this.paymentReminders,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'language': language,
      'theme': theme,
      'currency': currency,
      'emailNotifications': emailNotifications,
      'pushNotifications': pushNotifications,
      'paymentReminders': paymentReminders,
    };
  }

  factory AppSettings.fromMap(Map<String, dynamic> map) {
    return AppSettings(
      language: map['language'] ?? 'en',
      theme: map['theme'] ?? 'light',
      currency: map['currency'] ?? 'CHF',
      emailNotifications: map['emailNotifications'] ?? true,
      pushNotifications: map['pushNotifications'] ?? true,
      paymentReminders: map['paymentReminders'] ?? true,
    );
  }
}

// Settings notifier
class SettingsNotifier extends StateNotifier<AppSettings> {
  final Ref ref;

  SettingsNotifier(this.ref) : super(AppSettings()) {
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final language = prefs.getString('language') ?? 'en';
      final theme = prefs.getString('theme') ?? 'light';
      final currency = prefs.getString('currency') ?? 'CHF';
      final emailNotifications = prefs.getBool('emailNotifications') ?? true;
      final pushNotifications = prefs.getBool('pushNotifications') ?? true;
      final paymentReminders = prefs.getBool('paymentReminders') ?? true;

      state = AppSettings(
        language: language,
        theme: theme,
        currency: currency,
        emailNotifications: emailNotifications,
        pushNotifications: pushNotifications,
        paymentReminders: paymentReminders,
      );

      // Update providers with loaded settings
      _updateProviders();
    } catch (e) {
      // If there's an error loading settings, keep defaults
      print('Error loading settings: $e');
    }
  }

  void _updateProviders() {
    // Update locale provider
    ref.read(localeProvider.notifier).updateLanguage(state.language);

    // Update currency provider
    ref.read(currencyProvider.notifier).setCurrency(state.currency);

    // Update theme provider
    ref.read(themeModeProvider.notifier).updateTheme(state.theme);
  }

  Future<void> _saveSettings() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('language', state.language);
      await prefs.setString('theme', state.theme);
      await prefs.setString('currency', state.currency);
      await prefs.setBool('emailNotifications', state.emailNotifications);
      await prefs.setBool('pushNotifications', state.pushNotifications);
      await prefs.setBool('paymentReminders', state.paymentReminders);
    } catch (e) {
      print('Error saving settings: $e');
    }
  }

  Future<void> updateLanguage(String language) async {
    state = state.copyWith(language: language);
    await _saveSettings();
    ref.read(localeProvider.notifier).updateLanguage(language);
  }

  Future<void> updateTheme(String theme) async {
    state = state.copyWith(theme: theme);
    await _saveSettings();
    ref.read(themeModeProvider.notifier).updateTheme(theme);
  }

  Future<void> updateCurrency(String currency) async {
    state = state.copyWith(currency: currency);
    await _saveSettings();
    ref.read(currencyProvider.notifier).setCurrency(currency);
  }

  Future<void> updateEmailNotifications(bool enabled) async {
    state = state.copyWith(emailNotifications: enabled);
    await _saveSettings();
  }

  Future<void> updatePushNotifications(bool enabled) async {
    state = state.copyWith(pushNotifications: enabled);
    await _saveSettings();
  }

  Future<void> updatePaymentReminders(bool enabled) async {
    state = state.copyWith(paymentReminders: enabled);
    await _saveSettings();
  }

  Future<void> resetToDefaults() async {
    state = AppSettings();
    await _saveSettings();
  }
}

// Provider
final settingsProvider =
    StateNotifierProvider<SettingsNotifier, AppSettings>((ref) {
  return SettingsNotifier(ref);
});
