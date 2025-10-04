import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:immosync/features/auth/presentation/pages/login_page.dart';
import 'package:immosync/features/auth/presentation/pages/enhanced_register_page.dart';
import 'package:immosync/features/auth/presentation/pages/complete_profile_page.dart';
import 'package:immosync/features/auth/presentation/pages/forgot_password_page.dart';
import 'package:immosync/features/auth/presentation/providers/auth_provider.dart';
import 'package:immosync/features/chat/presentation/pages/chat_page.dart';
import 'package:immosync/features/chat/presentation/pages/conversations_tabbed_page.dart';
import 'package:immosync/features/chat/presentation/pages/address_book_page.dart';
import 'package:immosync/features/home/presentation/pages/home_page.dart';
import 'package:immosync/features/maintenance/presentation/pages/maintenance_management_page.dart';
import 'package:immosync/features/maintenance/presentation/pages/maintenance_request_page.dart';
import 'package:immosync/features/maintenance/presentation/pages/maintenance_request_detail_page.dart';
import 'package:immosync/features/maintenance/presentation/pages/tenant_maintenance_requests_page.dart';
import 'package:immosync/features/payment/presentation/pages/make_payment_page.dart';
import 'package:immosync/features/payment/presentation/pages/payment_history_page.dart';
import 'package:immosync/features/payment/presentation/pages/auto_payment_setup_page.dart';
import 'package:immosync/features/property/domain/models/property.dart';
import 'package:immosync/features/property/presentation/pages/add_property_page.dart';
import 'package:immosync/features/property/presentation/pages/property_details_page.dart';
import 'package:immosync/features/property/presentation/pages/property_list_page.dart';
import 'package:immosync/features/tenant/presentation/pages/tenant_documents_page.dart';
import 'package:immosync/features/reports/presentation/pages/reports_page.dart';
import 'package:immosync/features/settings/presentation/pages/settings_page.dart';
import 'package:immosync/features/settings/presentation/pages/change_password_page.dart';
import 'package:immosync/features/settings/presentation/pages/two_factor_auth_page.dart';
import 'package:immosync/features/settings/presentation/pages/privacy_settings_page.dart';
import 'package:immosync/features/settings/presentation/pages/help_center_page.dart';
import 'package:immosync/features/settings/presentation/pages/contact_support_page.dart';
import 'package:immosync/features/settings/presentation/pages/terms_of_service_page.dart';
import 'package:immosync/features/settings/presentation/pages/privacy_policy_page.dart';
import 'package:immosync/features/profile/presentation/pages/edit_profile_page.dart';
import 'package:immosync/features/profile/presentation/pages/profile_page.dart';
import 'package:immosync/features/tenant/presentation/pages/tenants_page.dart';
import 'package:immosync/features/search/presentation/pages/universal_search_page.dart';
import 'package:immosync/features/tenant/presentation/pages/tenant_services_booking_page.dart';
import 'package:immosync/features/landlord/presentation/pages/landlord_services_booking_page.dart';
import 'package:immosync/features/landlord/presentation/pages/landlord_documents_page.dart';
import 'package:immosync/features/subscription/presentation/pages/landlord_subscription_page.dart';
import 'package:immosync/features/subscription/presentation/pages/subscription_payment_page.dart';
import 'package:immosync/features/subscription/domain/models/subscription.dart';
import 'package:immosync/features/payment/presentation/pages/tenant_payment_page.dart';
import 'package:immosync/features/payment/presentation/pages/landlord_connect_setup_page.dart';
import 'package:immosync/features/payment/presentation/pages/landlord_connect_dashboard_page.dart';
import 'package:immosync/features/notifications/presentation/pages/notifications_page.dart';
import 'package:immosync/features/support/presentation/pages/support_requests_page.dart';
import 'package:immosync/features/support/presentation/pages/support_request_detail_page.dart';
import 'package:immosync/features/support/presentation/pages/open_tickets_page.dart';

final routerProvider = Provider<GoRouter>((ref) {
  final authState = ref.watch(authProvider);

  return GoRouter(
    initialLocation: '/login',
    routes: [
      GoRoute(
        path: '/login',
        builder: (context, state) => const _GermanOnly(child: LoginPage()),
      ),
      GoRoute(
        path: '/register',
        builder: (context, state) =>
            const _GermanOnly(child: EnhancedRegisterPage()),
      ),
      GoRoute(
        path: '/complete-profile',
        builder: (context, state) =>
            const _GermanOnly(child: CompleteProfilePage()),
      ),
      GoRoute(
        path: '/forgot-password',
  builder: (context, state) => const _GermanOnly(child: ForgotPasswordPage()),
      ),
      GoRoute(
        path: '/home',
        builder: (context, state) => HomePage(),
      ),
      GoRoute(
        path: '/add-property',
        builder: (context, state) => AddPropertyPage(
          propertyToEdit: state.extra as Property?,
        ),
      ),
      GoRoute(
        path: '/properties',
        builder: (context, state) => const PropertyListPage(),
      ),
      GoRoute(
        path: '/documents',
        builder: (context, state) => const TenantDocumentsPage(),
      ),
      GoRoute(
        path: '/property/:id',
        builder: (context, state) => PropertyDetailsPage(
          propertyId: state.pathParameters['id']!,
        ),
      ),
      GoRoute(
        path: '/chat/:conversationId',
        builder: (context, state) => ChatPage(
          conversationId: state.pathParameters['conversationId']!,
          otherUserName: state.uri.queryParameters['otherUser'] ?? 'User',
          otherUserId: state.uri.queryParameters['otherUserId'],
          otherUserAvatar: state.uri.queryParameters['otherAvatar'],
        ),
      ),
      GoRoute(
        path: '/conversations',
        builder: (context, state) => const ConversationsTabbedPage(),
      ),
      GoRoute(
        path: '/address-book',
        builder: (context, state) => const AddressBookPage(),
      ),
      // Maintenance routes
      GoRoute(
        path: '/maintenance/request',
        builder: (context, state) => MaintenanceRequestPage(
          propertyId: state.uri.queryParameters['propertyId'],
        ),
      ),
      GoRoute(
        path: '/maintenance/manage',
        builder: (context, state) => const MaintenanceManagementPage(),
      ),
      GoRoute(
        path: '/tenant/maintenance',
        builder: (context, state) => const TenantMaintenanceRequestsPage(),
      ),
      GoRoute(
        path: '/maintenance/:id',
        builder: (context, state) => MaintenanceRequestDetailPage(
          requestId: state.pathParameters['id']!,
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
        builder: (context, state) => const LandlordServicesBookingPage(),
      ),
      // Landlord documents management route
      GoRoute(
        path: '/landlord/documents',
        builder: (context, state) => const LandlordDocumentsPage(),
      ),
      // Subscription routes
      GoRoute(
        path: '/subscription/landlord',
        builder: (context, state) => const LandlordSubscriptionPage(),
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
        builder: (context, state) => const SettingsPage(),
      ),
      // Settings sub-routes
      GoRoute(
        path: '/two-factor-auth',
        builder: (context, state) => const TwoFactorAuthPage(),
      ),
      GoRoute(
        path: '/privacy-settings',
        builder: (context, state) => const PrivacySettingsPage(),
      ),
      GoRoute(
        path: '/help-center',
        builder: (context, state) => const HelpCenterPage(),
      ),
      GoRoute(
        path: '/contact-support',
        builder: (context, state) => const ContactSupportPage(),
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
        builder: (context, state) => const ChangePasswordPage(),
      ),
      // Two-Factor Authentication route
      GoRoute(
        path: '/two-factor-auth',
        builder: (context, state) => const TwoFactorAuthPage(),
      ),
      // Privacy Settings route
      GoRoute(
        path: '/privacy-settings',
        builder: (context, state) => const PrivacySettingsPage(),
      ),
      // Help Center route
      GoRoute(
        path: '/help-center',
        builder: (context, state) => const HelpCenterPage(),
      ),
      // Contact Support route
      GoRoute(
        path: '/contact-support',
        builder: (context, state) => const ContactSupportPage(),
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
        builder: (context, state) => const ProfilePage(),
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
        builder: (context, state) => SupportRequestDetailPage(requestId: state.pathParameters['id']!),
      ),
      GoRoute(
        path: '/tickets/open',
        builder: (context, state) => const OpenTicketsPage(),
      ),
      // Search route
      GoRoute(
        path: '/search',
        builder: (context, state) => const UniversalSearchPage(),
      ),
      // Reports route
      GoRoute(
        path: '/reports',
        builder: (context, state) => const ReportsPage(),
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

          return ChatPage(
            conversationId: 'new',
            otherUserId: otherUserId,
            otherUserName: otherUserName,
          );
        },
      ),
    ],
    redirect: (context, state) {
      final isLoggingIn = state.matchedLocation == '/login';
      final isRegistering = state.matchedLocation == '/register';
      final isForgotPassword = state.matchedLocation == '/forgot-password';
      final isCompleting = state.matchedLocation == '/complete-profile';

      if (!authState.isAuthenticated &&
          !isLoggingIn &&
          !isRegistering &&
          !isForgotPassword) {
        if (isCompleting && authState.needsProfileCompletion) return null;
        return '/login';
      }

      if (authState.isAuthenticated &&
          (isLoggingIn || isRegistering || isForgotPassword || isCompleting)) {
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
