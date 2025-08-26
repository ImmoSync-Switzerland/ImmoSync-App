import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_stripe/flutter_stripe.dart';
import 'package:firebase_core/firebase_core.dart';
import '../l10n/app_localizations.dart';
import 'package:immosync/core/routes/app_router.dart';
import 'package:immosync/core/services/database_service.dart';
import 'package:immosync/core/theme/app_theme.dart';
import 'package:immosync/core/providers/theme_provider.dart';
import 'package:immosync/core/providers/locale_provider.dart';
import 'package:immosync/features/settings/providers/settings_provider.dart';
import 'package:immosync/l10n_helper.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart' as dotenv;
import 'package:immosync/core/config/db_config.dart';

void main() async {
  // Wrap everything in a try-catch to prevent immediate crashes
  runZonedGuarded(() async {
    WidgetsFlutterBinding.ensureInitialized();
    
    // Initialize Firebase
    try {
      await Firebase.initializeApp();
      print('Firebase initialized successfully');
    } catch (e) {
      print('Firebase initialization failed: $e');
      // Don't crash the app, just log the error
    }
    
    // Environment loading with fallback
    bool envLoaded = false;
    try {
      await dotenv.dotenv.load(fileName: ".env");
      envLoaded = true;
      print('Environment file loaded successfully');
    } catch (e) {
      print('Failed to load .env file: $e');
      print('Using default configuration');
    }
    
    // Initialize Stripe with more robust error handling
    try {
      final stripeKey = envLoaded ? dotenv.dotenv.env['STRIPE_PUBLISHABLE_KEY'] : null;
      if (stripeKey != null && stripeKey.isNotEmpty) {
        Stripe.publishableKey = stripeKey;
        await Stripe.instance.applySettings();
        print('Stripe initialized successfully');
      } else {
        print('Stripe key not found in environment, payment features disabled');
      }
    } catch (e) {
      print('Stripe initialization failed: $e');
      // Don't crash the app, just log the error
    }
    
    // Print configuration for debugging
    try {
      DbConfig.printConfig();
    } catch (e) {
      print('DbConfig error: $e');
    }
    
    // Database connection with error handling
    try {
      await DatabaseService.instance.connect();
      print('Database connected successfully');
    } catch (e) {
      print('Database connection failed: $e');
      print('App will run in offline mode');
    }
    
    runApp(const ProviderScope(child: ImmoSync()));
  }, (error, stack) {
    print('Uncaught error in main: $error');
    print('Stack trace: $stack');
    // Try to run a minimal version of the app
    runApp(
      MaterialApp(
        home: Scaffold(
          body: Center(
            child: Text('App initialization failed: $error'),
          ),
        ),
      ),
    );
  });
}

class ImmoSync extends ConsumerWidget {
  const ImmoSync({super.key});
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(routerProvider);
    final currentLocale = ref.watch(localeProvider);
    final themeMode = ref.watch(themeModeProvider);
    
    // Ensure settings are loaded
    ref.watch(settingsProvider);
    
    // Determine which theme mode to use
    ThemeMode appThemeMode;
    switch (themeMode) {
      case 'light':
        appThemeMode = ThemeMode.light;
        break;
      case 'dark':
        appThemeMode = ThemeMode.dark;
        break;
      case 'system':
        appThemeMode = ThemeMode.system;
        break;
      default:
        appThemeMode = ThemeMode.light;
    }
    
    return MaterialApp.router(
      routerConfig: router,
      title: 'ImmoSync',
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: appThemeMode,
      locale: currentLocale,
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: L10n.all,
    );
  }
}

