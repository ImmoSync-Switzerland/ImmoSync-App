import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:immosync/features/auth/presentation/providers/auth_provider.dart';
import 'package:immosync/features/auth/presentation/providers/user_role_provider.dart';
import 'package:immosync/features/home/presentation/pages/landlord_dashboard.dart';
import 'package:immosync/features/home/presentation/pages/tenant_dashboard.dart';

class HomePage extends ConsumerWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Add debug prints to trace the flow
    print('Building HomePage');
    
    ref.listen<AuthState>(authProvider, (previous, current) {
      print('Auth state changed: ${current.isAuthenticated}');
      if (!current.isAuthenticated) {
        context.go('/login');
      }
    });

    final userRole = ref.watch(userRoleProvider);
    print('Current user role: $userRole');

    // Add null check and loading state
    if (userRole.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }

    return userRole == 'landlord' 
        ? const LandlordDashboard()
        : const TenantDashboard();
  }
}
