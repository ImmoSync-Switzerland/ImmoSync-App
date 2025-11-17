import 'dart:async';
// For PlatformDispatcher
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_stripe/flutter_stripe.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart' as dotenv;
import 'core/notifications/fcm_service.dart';
import '../l10n/app_localizations.dart';
import 'package:immosync/core/routes/app_router.dart';
import 'package:immosync/core/services/database_service.dart';
import 'package:immosync/core/theme/app_theme.dart';
import 'package:immosync/core/providers/theme_provider.dart';
import 'package:immosync/core/providers/locale_provider.dart';
import 'package:immosync/features/settings/providers/settings_provider.dart';
import 'package:immosync/l10n_helper.dart';
import 'package:immosync/core/config/db_config.dart';
import 'package:immosync/features/auth/presentation/providers/auth_provider.dart';
import 'package:immosync/features/chat/infrastructure/matrix_chat_service.dart';
import 'package:immosync/features/chat/infrastructure/matrix_frb_events_adapter.dart';
import 'package:immosync/core/services/deep_link_service.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:immosync/frb_generated.dart';

void main() async {
  bool _appStarted = false; // track if primary runApp already executed
  // Global Flutter error hooks for richer diagnostics
  FlutterError.onError = (FlutterErrorDetails details) {
    debugPrint('FlutterError caught: ${details.exceptionAsString()}');
    if (details.stack != null) {
      debugPrint(details.stack.toString());
    }
    Zone.current.handleUncaughtError(
        details.exception, details.stack ?? StackTrace.empty);
  };
  // Platform dispatcher errors (async / isolates)
  PlatformDispatcher.instance.onError = (error, stack) {
    debugPrint('PlatformDispatcher error: $error');
    debugPrint(stack.toString());
    return false; // allow default handling too
  };

  runZonedGuarded(() async {
    final stopwatch = Stopwatch()..start();
    debugPrint('--- App startup sequence begin ---');
    WidgetsFlutterBinding.ensureInitialized();
    debugPrint('[Startup] Widgets binding ensured');

    // Step 1: Load .env (optional) to allow runtime configuration on desktop/dev
    try {
      await dotenv.dotenv.load(fileName: '.env');
      debugPrint('[Startup] .env loaded');
    } catch (e) {
      debugPrint('[Startup][INFO] .env not loaded (optional): $e');
    }

    // Step 2: Firebase (deferred errors tolerated)
    try {
      // Skip Firebase initialization on Windows as it's not fully supported
      if (defaultTargetPlatform == TargetPlatform.windows) {
        debugPrint(
            '[Startup][INFO] Firebase initialization skipped on Windows platform');
      } else {
        await Firebase.initializeApp(
          options: DefaultFirebaseOptions.currentPlatform,
        );
        debugPrint('[Startup] Firebase initialized');
      }
    } catch (e, st) {
      debugPrint('[Startup][WARN] Firebase init failed: $e');
      debugPrint(st.toString());
    }

    // Step 3: Stripe (only on supported platforms: web, Android, iOS)
    try {
      final isStripeSupported = kIsWeb ||
          (!kIsWeb &&
              (defaultTargetPlatform == TargetPlatform.android ||
                  defaultTargetPlatform == TargetPlatform.iOS));
      if (!isStripeSupported) {
        debugPrint(
            '[Startup][INFO] Stripe unsupported on this platform (${defaultTargetPlatform.name}) – skipping Stripe init');
      } else {
        const stripeKey = String.fromEnvironment('STRIPE_PUBLISHABLE_KEY');
        if (stripeKey.isEmpty) {
          debugPrint(
              '[Startup][INFO] Stripe key missing – skipping Stripe init');
        } else {
          Stripe.publishableKey = stripeKey;
          await Stripe.instance.applySettings();
          debugPrint('[Startup] Stripe initialized');
        }
      }
    } catch (e, st) {
      debugPrint('[Startup][WARN] Stripe init failed: $e');
      debugPrint(st.toString());
    }

    // Step 4: Config print
    try {
      DbConfig.printConfig();
    } catch (e, st) {
      debugPrint('[Startup][WARN] DbConfig print failed: $e');
      debugPrint(st.toString());
    }

    // Step 5: Database connect (non‑fatal)
    try {
      await DatabaseService.instance.connect();
      debugPrint('[Startup] Database connect success');
    } catch (e, st) {
      debugPrint('[Startup][WARN] Database connect failed: $e');
      debugPrint(st.toString());
    }

    // Step 6: Initialize flutter_rust_bridge before any FRB usage
    // This must run before widgets/providers that call into the bridge (e.g., subscribeEvents)
    try {
      // Only initialize Rust bridge on platforms where it's available
      // For now, skip on mobile platforms where the native library might not be built
      if (defaultTargetPlatform == TargetPlatform.windows ||
          defaultTargetPlatform == TargetPlatform.linux ||
          defaultTargetPlatform == TargetPlatform.macOS) {
        await RustLib.init();
        debugPrint('[Startup] flutter_rust_bridge initialized');
      } else {
        debugPrint(
            '[Startup][INFO] flutter_rust_bridge initialization skipped on ${defaultTargetPlatform.name}');
      }
    } catch (e, st) {
      debugPrint('[Startup][WARN] flutter_rust_bridge init failed: $e');
      debugPrint(st.toString());
      // Don't re-throw, continue without Rust bridge on mobile
    }

    // Run app – heavy providers will lazy load AFTER first frame
    try {
      runApp(const ProviderScope(child: ImmoSync()));
      _appStarted = true;
      debugPrint(
          '[Startup] runApp completed in ${stopwatch.elapsedMilliseconds} ms');
    } catch (e, st) {
      debugPrint('[Startup][FATAL] runApp threw: $e');
      debugPrint(st.toString());
      rethrow; // allow zone to show fallback UI (before UI exists)
    }
  }, (error, stack) {
    debugPrint('--- Uncaught during startup ---');
    debugPrint('Error: $error');
    debugPrint(stack.toString());
    if (!_appStarted) {
      // Only show fallback UI if primary app not started yet
      runApp(
        MaterialApp(
          debugShowCheckedModeBanner: false,
          home: Scaffold(
            body: Padding(
              padding: const EdgeInsets.all(16),
              child: SingleChildScrollView(
                child: Text(
                  'App initialization failed:\n$error\n\nStack trace (truncated):\n${stack.toString().split("\n").take(12).join("\n")}',
                  style: const TextStyle(fontSize: 14),
                ),
              ),
            ),
          ),
        ),
      );
    } else {
      // After app started just log; optionally could update an error notifier
      debugPrint('[Post-startup error] $error');
    }
  });
}

class ImmoSync extends ConsumerWidget {
  const ImmoSync({super.key});
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Initialize deep link service
    final deepLinkService = ref.watch(deepLinkServiceProvider);
    // Initialize on first build
    WidgetsBinding.instance.addPostFrameCallback((_) {
      deepLinkService.initialize(ref);
    });

    // Start FCM service side effects and keep instance (skip on Windows)
    if (defaultTargetPlatform != TargetPlatform.windows) {
      final fcm = ref.watch(fcmServiceProvider);
      // Listen for auth userId changes (avoid triggering on every rebuild)
      ref.listen<AuthState>(authProvider, (prev, next) {
        if (prev?.userId != next.userId) {
          fcm.updateUserId(next.userId);
        }
      });
    }

    // Receive chat messages from native Matrix FRB stream only (no WS message ingestion)
    // Only on platforms where Rust bridge is available
    if (defaultTargetPlatform == TargetPlatform.windows ||
        defaultTargetPlatform == TargetPlatform.linux ||
        defaultTargetPlatform == TargetPlatform.macOS) {
      ref.watch(matrixFrbEventsAdapterProvider);
    }

    // Listen for auth userId changes (avoid triggering on every rebuild)
    ref.listen<AuthState>(authProvider, (prev, next) {
      if (prev?.userId != next.userId) {
        // Initialize and login Matrix bridge once user is known
        if (next.isAuthenticated && next.userId != null) {
          _initMatrixForUser(next.userId!);
        }
      }
    });
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

// Fire-and-forget Matrix init+login using backend-provisioned credentials
Future<void> _initMatrixForUser(String userId) async {
  try {
    final api = DbConfig.apiUrl;
    Future<Map<String, dynamic>?> fetchAccount() async {
      final r = await http.get(Uri.parse('$api/matrix/account/$userId'));
      if (r.statusCode != 200) return null;
      return json.decode(r.body) as Map<String, dynamic>;
    }

    var data = await fetchAccount();
    if (data == null) {
      // Try to provision the account then fetch again
      await http.post(Uri.parse('$api/matrix/provision'),
          headers: {'Content-Type': 'application/json'},
          body: json.encode({'userId': userId}));
      data = await fetchAccount();
    }
    if (data == null) return;
    final homeserver = (data['baseUrl'] as String?) ?? '';
    final username = data['username'] as String?;
    final password = data['password'] as String?;
    if (homeserver.isEmpty || username == null || password == null) return;
    // Centralized readiness (idempotent) avoids duplicate login/sync
    await MatrixChatService.instance.ensureReadyForUser(userId);
  } catch (e, st) {
    debugPrint('Matrix init/login failed: $e');
    debugPrint(st.toString());
  }
}
