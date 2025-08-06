import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:immolink/features/auth/presentation/pages/login_page.dart';
import 'package:immolink/features/auth/presentation/pages/register_page.dart';
import 'package:immolink/features/auth/presentation/providers/auth_provider.dart';
import 'package:immolink/features/chat/presentation/pages/chat_page.dart';
import 'package:immolink/features/chat/presentation/pages/conversations_list_page.dart';
import 'package:immolink/features/chat/presentation/pages/address_book_page.dart';
import 'package:immolink/features/home/presentation/pages/home_page.dart';
import 'package:immolink/features/maintenance/presentation/pages/maintenance_management_page.dart';
import 'package:immolink/features/maintenance/presentation/pages/maintenance_request_page.dart';
import 'package:immolink/features/maintenance/presentation/pages/maintenance_request_detail_page.dart';
import 'package:immolink/features/payment/presentation/pages/make_payment_page.dart';
import 'package:immolink/features/payment/presentation/pages/payment_history_page.dart';
import 'package:immolink/features/payment/presentation/pages/auto_payment_setup_page.dart';
import 'package:immolink/features/property/domain/models/property.dart';
import 'package:immolink/features/property/presentation/pages/add_property_page.dart';
import 'package:immolink/features/property/presentation/pages/property_details_page.dart';
import 'package:immolink/features/property/presentation/pages/property_list_page.dart';
import 'package:immolink/features/reports/presentation/pages/reports_page.dart';
import 'package:immolink/features/settings/presentation/pages/settings_page.dart';
import 'package:immolink/features/settings/presentation/pages/change_password_page.dart';
import 'package:immolink/features/settings/presentation/pages/two_factor_auth_page.dart';
import 'package:immolink/features/settings/presentation/pages/privacy_settings_page.dart';
import 'package:immolink/features/settings/presentation/pages/help_center_page.dart';
import 'package:immolink/features/settings/presentation/pages/contact_support_page.dart';
import 'package:immolink/features/settings/presentation/pages/terms_of_service_page.dart';
import 'package:immolink/features/settings/presentation/pages/privacy_policy_page.dart';
import 'package:immolink/features/profile/presentation/pages/edit_profile_page.dart';
import 'package:immolink/features/profile/presentation/pages/profile_page.dart';
import 'package:immolink/features/search/presentation/pages/tenant_search_page.dart';
import 'package:immolink/features/tenant/presentation/pages/tenants_page.dart';
import 'package:immolink/features/tenant/presentation/pages/tenant_services_booking_page.dart';
import 'package:immolink/features/landlord/presentation/pages/landlord_services_setup_page.dart';

final routerProvider = Provider<GoRouter>((ref) {
  final authState = ref.watch(authProvider);

  return GoRouter(
    initialLocation: authState.isAuthenticated ? '/home' : '/login',
    routes: [
      GoRoute(
        path: '/login',
        builder: (context, state) => const LoginPage(),
      ),
      GoRoute(
        path: '/register',
        builder: (context, state) => const RegisterPage(),
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
        ),
      ),
      GoRoute(
        path: '/conversations',
        builder: (context, state) => const ConversationsListPage(),
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
      // Landlord services setup route
      GoRoute(
        path: '/landlord/services',
        builder: (context, state) => const LandlordServicesSetupPage(),
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
      // Search route
      GoRoute(
        path: '/search',
        builder: (context, state) => const TenantSearchPage(),
      ),
      // Tenant Search route
      GoRoute(
        path: '/tenant-search',
        builder: (context, state) => const TenantSearchPage(),
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
                child: Text('Invalid chat parameters'),
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

      if (!authState.isAuthenticated && !isLoggingIn && !isRegistering) {
        return '/login';
      }

      if (authState.isAuthenticated && isLoggingIn) {
        return '/home';
      }

      return null;
    },
  );
});

