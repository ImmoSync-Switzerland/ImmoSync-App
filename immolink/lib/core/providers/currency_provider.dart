import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

class CurrencyNotifier extends StateNotifier<String> {
  CurrencyNotifier() : super('CHF');

  void setCurrency(String currency) {
    state = currency;
  }

  String formatAmount(double amount) {
    switch (state) {
      case 'EUR':
        return NumberFormat.currency(locale: 'de_DE', symbol: '€')
            .format(amount);
      case 'USD':
        return NumberFormat.currency(locale: 'en_US', symbol: '\$')
            .format(amount);
      case 'GBP':
        return NumberFormat.currency(locale: 'en_GB', symbol: '£')
            .format(amount);
      case 'CHF':
      default:
        return NumberFormat.currency(locale: 'de_CH', symbol: 'CHF ')
            .format(amount);
    }
  }

  String getSymbol() {
    switch (state) {
      case 'EUR':
        return '€';
      case 'USD':
        return '\$';
      case 'GBP':
        return '£';
      case 'CHF':
      default:
        return 'CHF';
    }
  }
}

final currencyProvider = StateNotifierProvider<CurrencyNotifier, String>((ref) {
  return CurrencyNotifier();
});

// Helper extension for easy currency formatting
extension CurrencyFormatting on double {
  String toCurrency(String currency) {
    switch (currency) {
      case 'EUR':
        return NumberFormat.currency(locale: 'de_DE', symbol: '€').format(this);
      case 'USD':
        return NumberFormat.currency(locale: 'en_US', symbol: '\$')
            .format(this);
      case 'GBP':
        return NumberFormat.currency(locale: 'en_GB', symbol: '£').format(this);
      case 'CHF':
      default:
        return NumberFormat.currency(locale: 'de_CH', symbol: 'CHF ')
            .format(this);
    }
  }
}
