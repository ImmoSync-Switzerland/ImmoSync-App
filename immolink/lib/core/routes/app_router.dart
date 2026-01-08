import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:immosync/features/auth/presentation/pages/login_page.dart';
import 'package:immosync/features/auth/presentation/pages/complete_profile_page.dart';
import 'package:immosync/features/auth/presentation/pages/forgot_password_page.dart';
import 'package:immosync/features/auth/presentation/providers/auth_provider.dart';
import 'package:immosync/features/chat/presentation/pages/chat_detail_screen.dart';
import 'package:immosync/features/chat/presentation/pages/messages_screen.dart';
import 'package:immosync/features/chat/presentation/pages/address_book_page.dart';
import 'package:immosync/features/home/presentation/pages/home_page.dart';
import 'package:immosync/features/maintenance/presentation/pages/maintenance_management_page.dart';
import 'package:immosync/features/maintenance/presentation/pages/maintenance_request_page.dart';
import 'package:immosync/features/maintenance/presentation/pages/maintenance_request_detail_page.dart';
import 'package:immosync/features/maintenance/presentation/pages/tenant_maintenance_screen.dart';
import 'package:immosync/features/maintenance/domain/models/maintenance_request.dart';
import 'package:immosync/features/payment/presentation/pages/make_payment_page.dart';
import 'package:immosync/features/payment/presentation/pages/payment_history_page.dart';
import 'package:immosync/features/payment/presentation/pages/auto_payment_setup_page.dart';
import 'package:immosync/features/property/domain/models/property.dart';
import 'package:immosync/features/property/presentation/pages/add_property_screen.dart';
import 'package:immosync/features/property/presentation/pages/property_details_page.dart';
import 'package:immosync/features/home/presentation/pages/properties_screen.dart';
import 'package:immosync/features/documents/presentation/pages/documents_screen.dart';
import 'package:immosync/features/reports/presentation/pages/reports_page.dart';
import 'package:immosync/features/settings/presentation/pages/change_password_page.dart';
import 'package:immosync/features/settings/presentation/pages/two_factor_auth_page.dart';
import 'package:immosync/features/settings/presentation/pages/privacy_settings_page.dart';
import 'package:immosync/features/settings/presentation/pages/help_center_page.dart';
import 'package:immosync/features/settings/presentation/pages/contact_support_page.dart';
import 'package:immosync/features/settings/presentation/pages/terms_of_service_page.dart';
import 'package:immosync/features/settings/presentation/pages/privacy_policy_page.dart';
import 'package:immosync/features/settings/presentation/pages/settings_screen.dart';
import 'package:immosync/features/profile/presentation/pages/edit_profile_page.dart';
import 'package:immosync/features/profile/presentation/pages/profile_screen.dart';
import 'package:immosync/features/tenant/presentation/pages/tenants_page.dart';
import 'package:immosync/features/search/presentation/pages/search_screen.dart';
import 'package:immosync/features/tenant/presentation/pages/tenant_services_booking_page.dart';
import 'package:immosync/features/services/presentation/pages/services_screen.dart';
import 'package:immosync/features/landlord/presentation/pages/revenue_details_page.dart';
import 'package:immosync/features/landlord/presentation/pages/outstanding_payments_page.dart';
import 'package:immosync/features/payment/presentation/pages/payments_screen.dart';
import 'package:immosync/features/subscription/presentation/pages/landlord_subscription_page.dart';
import 'package:immosync/features/subscription/presentation/pages/subscription_payment_page.dart';
import 'package:immosync/features/subscription/presentation/pages/subscription_screen.dart';
import 'package:immosync/features/subscription/domain/models/subscription.dart';
import 'package:immosync/features/payment/presentation/pages/tenant_payment_page.dart';
import 'package:immosync/features/payment/presentation/pages/landlord_connect_setup_page.dart';
import 'package:immosync/features/payment/presentation/pages/landlord_connect_dashboard_page.dart';
import 'package:immosync/features/notifications/presentation/pages/notifications_page.dart';
import 'package:immosync/features/support/presentation/pages/support_requests_page.dart';
import 'package:immosync/features/support/presentation/pages/support_request_detail_page.dart';
import 'package:immosync/features/support/presentation/pages/open_tickets_page.dart';
import 'package:immosync/features/reports/presentation/pages/revenue_detail_page.dart';
import 'package:immosync/features/debug/matrix_logs_viewer.dart';
import 'package:immosync/features/debug/matrix_test_standalone.dart';
import 'package:immosync/features/auth/presentation/pages/sign_up_screen.dart';
import 'package:immosync/features/auth/presentation/pages/splash_screen.dart';

class _RouterRefreshNotifier extends ChangeNotifier {
  _RouterRefreshNotifier(this._ref) {
    _sub = _ref.listen<AuthState>(authProvider, (_, __) {
      notifyListeners();
    });
  }

  final Ref _ref;
  late final ProviderSubscription<AuthState> _sub;

  @override
  void dispose() {
    _sub.close();
    super.dispose();
  }
}

final routerProvider = Provider<GoRouter>((ref) {
  final refreshNotifier = _RouterRefreshNotifier(ref);
  ref.onDispose(refreshNotifier.dispose);

  return GoRouter(
    initialLocation: '/splash',
    refreshListenable: refreshNotifier,
    routes: [
      GoRoute(
        path: '/splash',
        builder: (context, state) => const SplashScreen(),
      ),
      GoRoute(
        path: '/login',
        builder: (context, state) => const _GermanOnly(child: LoginPage()),
      ),
      GoRoute(
        path: '/register',
        builder: (context, state) => const _GermanOnly(child: SignUpScreen()),
      ),
      GoRoute(
        path: '/complete-profile',
        builder: (context, state) =>
            const _GermanOnly(child: CompleteProfilePage()),
      ),
      GoRoute(
        path: '/forgot-password',
        builder: (context, state) =>
            const _GermanOnly(child: ForgotPasswordPage()),
      ),
      GoRoute(
        path: '/home',
        builder: (context, state) => const HomePage(),
      ),
      GoRoute(
        path: '/add-property',
        builder: (context, state) => AddPropertyScreen(
          propertyToEdit: state.extra as Property?,
        ),
      ),
      GoRoute(
        path: '/properties',
        builder: (context, state) => const PropertiesScreen(),
      ),
      GoRoute(
        path: '/documents',
        builder: (context, state) => const DocumentsScreen(),
      ),
      GoRoute(
        path: '/property/:id',
        builder: (context, state) => PropertyDetailsPage(
          propertyId: state.pathParameters['id']!,
        ),
      ),
      GoRoute(
        path: '/chat/:conversationId',
        builder: (context, state) => ChatDetailScreen(
          conversationId: state.pathParameters['conversationId']!,
          otherUserId: state.uri.queryParameters['otherUserId'],
          title: state.uri.queryParameters['otherUser'] ?? 'User',
          status: 'Online',
          avatarUrl: state.uri.queryParameters['otherAvatar'],
        ),
      ),
      GoRoute(
        path: '/conversations',
        builder: (context, state) => const MessagesScreen(),
      ),
      GoRoute(
        path: '/address-book',
        builder: (context, state) => const AddressBookPage(),
      ),
      // Maintenance routes
      GoRoute(
        path: '/maintenance/request',
        builder: (context, state) => NewRequestScreen(
          propertyId: state.uri.queryParameters['propertyId'],
        ),
      ),
      GoRoute(
        path: '/maintenance/manage',
        builder: (context, state) => const MaintenanceManagementPage(),
      ),
      GoRoute(
        path: '/tenant/maintenance',
        builder: (context, state) => const TenantMaintenanceScreen(),
      ),
      GoRoute(
        path: '/maintenance/:id',
        builder: (context, state) => MaintenanceRequestDetailPage(
          requestId: state.pathParameters['id']!,
          initialRequest: state.extra is MaintenanceRequest
              ? state.extra as MaintenanceRequest
              : null,
        ),
      ),
      // Payment routes
      GoRoute(
        path: '/payments/history',
        builder: (context, state) => const PaymentHistoryPage(),
      ),
      GoRoute(
        path: '/payments/make',
        builder: (context, state) => MakePaymentPage(
          propertyId: state.uri.queryParameters['propertyId'],
        ),
      ),
      // Auto payment setup route
      GoRoute(
        path: '/payments/auto-setup',
        builder: (context, state) => const AutoPaymentSetupPage(),
      ),
      // Tenant services booking route
      GoRoute(
        path: '/tenant/services',
        builder: (context, state) => const TenantServicesBookingPage(),
      ),
      // Landlord services booking route
      GoRoute(
        path: '/landlord/services',
        builder: (context, state) => const ServicesScreen(),
      ),
      // Landlord documents management route
      GoRoute(
        path: '/landlord/documents',
        builder: (context, state) => const DocumentsScreen(),
      ),
      // Landlord revenue details page
      GoRoute(
        path: '/landlord/revenue',
        builder: (context, state) => const RevenueDetailsPage(),
      ),
      // Landlord outstanding payments page
      GoRoute(
        path: '/landlord/outstanding',
        builder: (context, state) => const OutstandingPaymentsPage(),
      ),
      // Landlord payments page (Stripe Connect)
      GoRoute(
        path: '/landlord/payments',
        builder: (context, state) => const PaymentsScreen(),
      ),
      // Subscription routes
      GoRoute(
        path: '/subscription/landlord',
        builder: (context, state) => const LandlordSubscriptionPage(),
      ),
      GoRoute(
        path: '/subscription/management',
        builder: (context, state) => const SubscriptionScreen(),
      ),
      GoRoute(
        path: '/subscription/payment',
        builder: (context, state) {
          final planData = state.extra as Map<String, dynamic>?;

          if (planData == null) {
            return const Scaffold(
              body: Center(child: Text('Invalid subscription parameters')),
            );
          }

          return SubscriptionPaymentPage(
            plan: planData['plan'] as SubscriptionPlan,
            isYearly: planData['isYearly'] as bool,
          );
        },
      ),
      // Payment routes for tenants
      GoRoute(
        path: '/payments/tenant',
        builder: (context, state) {
          final property = state.extra as Property?;

          if (property == null) {
            return const Scaffold(
              body: Center(child: Text('Invalid payment parameters')),
            );
          }

          return TenantPaymentPage(
            property: property,
            paymentType: state.uri.queryParameters['type'] ?? 'rent',
          );
        },
      ),
      // Connect setup for landlords
      GoRoute(
        path: '/connect/setup',
        builder: (context, state) => const LandlordConnectSetupPage(),
      ),
      // Connect dashboard for landlords
      GoRoute(
        path: '/connect/dashboard',
        builder: (context, state) => const LandlordConnectDashboardPage(),
      ),
      // Settings route
      GoRoute(
        path: '/settings',
        builder: (context, state) => const SettingsScreen(),
      ),
      // Settings sub-routes
      GoRoute(
        path: '/two-factor-auth',
        builder: (context, state) => const TwoFactorAuthPage(),
      ),
      GoRoute(
        path: '/privacy-settings',
        builder: (context, state) => const PrivacySettingsScreen(),
      ),
      GoRoute(
        path: '/help-center',
        builder: (context, state) => const HelpCenterScreen(),
      ),
      GoRoute(
        path: '/contact-support',
        builder: (context, state) => const ContactSupportScreen(),
      ),
      GoRoute(
        path: '/terms-of-service',
        builder: (context, state) => const TermsOfServicePage(),
      ),
      GoRoute(
        path: '/privacy-policy',
        builder: (context, state) => const PrivacyPolicyPage(),
      ),
      // Change Password route
      GoRoute(
        path: '/change-password',
        builder: (context, state) => const ChangePasswordScreen(),
      ),
      // Two-Factor Authentication route
      GoRoute(
        path: '/two-factor-auth',
        builder: (context, state) => const TwoFactorAuthPage(),
      ),
      // Privacy Settings route
      GoRoute(
        path: '/privacy-settings',
        builder: (context, state) => const PrivacySettingsScreen(),
      ),
      // Help Center route
      GoRoute(
        path: '/help-center',
        builder: (context, state) => const HelpCenterScreen(),
      ),
      // Contact Support route
      GoRoute(
        path: '/contact-support',
        builder: (context, state) => const ContactSupportScreen(),
      ),
      // Contact Support route (alternative path)
      GoRoute(
        path: '/settings/contact-support',
        builder: (context, state) => const ContactSupportScreen(),
      ),
      // Debug Matrix Logs routes - always available
      GoRoute(
        path: '/debug/matrix-logs',
        builder: (context, state) => const MatrixLogsViewer(),
      ),
      GoRoute(
        path: '/debug/matrix-test',
        builder: (context, state) => const MatrixTestStandalone(),
      ),
      // Terms of Service route
      GoRoute(
        path: '/terms-of-service',
        builder: (context, state) => const TermsOfServicePage(),
      ),
      // Privacy Policy route
      GoRoute(
        path: '/privacy-policy',
        builder: (context, state) => const PrivacyPolicyPage(),
      ),
      // Edit Profile route
      GoRoute(
        path: '/edit-profile',
        builder: (context, state) => const EditProfilePage(),
      ),
      // Profile route
      GoRoute(
        path: '/profile',
        builder: (context, state) => const ProfileScreen(),
      ),
      GoRoute(
        path: '/notifications',
        builder: (context, state) => const NotificationsPage(),
      ),
      GoRoute(
        path: '/support-requests',
        builder: (context, state) => const SupportRequestsPage(),
      ),
      GoRoute(
        path: '/support-requests/:id',
        builder: (context, state) =>
            SupportRequestDetailPage(requestId: state.pathParameters['id']!),
      ),
      GoRoute(
        path: '/tickets/open',
        builder: (context, state) => const OpenTicketsPage(),
      ),
      // Search route
      GoRoute(
        path: '/search',
        builder: (context, state) => SearchScreen(
          initialQuery: state.uri.queryParameters['q'],
        ),
      ),
      // Reports route
      GoRoute(
        path: '/reports',
        builder: (context, state) => const ReportsPage(),
      ),
      GoRoute(
        path: '/reports/revenue-detail',
        builder: (context, state) => const RevenueDetailPage(),
      ),
      // Tenants route
      GoRoute(
        path: '/tenants',
        builder: (context, state) => const TenantsPage(),
      ),
      GoRoute(
        path: '/chat/new',
        builder: (context, state) {
          final otherUserId = state.uri.queryParameters['otherUserId'];
          final otherUserName = state.uri.queryParameters['otherUserName'];

          if (otherUserId == null || otherUserName == null) {
            return const Scaffold(
              body: Center(
                child: Text('Ungültige Chat-Parameter'),
              ),
            );
          }

          return ChatDetailScreen(
            conversationId: 'new',
            otherUserId: otherUserId,
            title: otherUserName,
            status: 'Online',
          );
        },
      ),
    ],
    redirect: (context, state) {
      final authState = ref.read(authProvider);
      final isSplash = state.matchedLocation == '/splash';
      final isLoggingIn = state.matchedLocation == '/login';
      final isRegistering = state.matchedLocation == '/register';
      final isForgotPassword = state.matchedLocation == '/forgot-password';
      final isCompleting = state.matchedLocation == '/complete-profile';

      if (!authState.isAuthenticated &&
          !isSplash &&
          !isLoggingIn &&
          !isRegistering &&
          !isForgotPassword) {
        if (isCompleting && authState.needsProfileCompletion) return null;
        return '/login';
      }

      if (authState.isAuthenticated &&
          (isSplash ||
              isLoggingIn ||
              isRegistering ||
              isForgotPassword ||
              isCompleting)) {
        return '/home';
      }

      return null;
    },
  );
});

// Wraps a subtree forcing locale to German regardless of global app locale.
class _GermanOnly extends StatelessWidget {
  final Widget child;
  const _GermanOnly({required this.child});

  @override
  Widget build(BuildContext context) {
    return Localizations.override(
      context: context,
      locale: const Locale('de'),
      child: child,
    );
  }
}
