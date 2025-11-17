import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/property_providers.dart';
import '../../../auth/domain/models/user.dart';
import '../../../chat/presentation/providers/invitation_provider.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../../../../core/theme/app_colors.dart';

class InviteTenantDialog extends ConsumerStatefulWidget {
  final String propertyId;

  const InviteTenantDialog({required this.propertyId, super.key});

  @override
  ConsumerState<InviteTenantDialog> createState() => _InviteTenantDialogState();
}

class _InviteTenantDialogState extends ConsumerState<InviteTenantDialog> {
  final _searchController = TextEditingController();
  String _searchQuery = '';

  @override
  Widget build(BuildContext context) {
    final tenantsAsync = ref.watch(availableTenantsProvider(widget.propertyId));

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Container(
        width: MediaQuery.of(context).size.width * 0.8,
        height: MediaQuery.of(context).size.height * 0.7,
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Text(
              'Select Tenant',
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: 16),
            _buildSearchBar(),
            const SizedBox(height: 16),
            Expanded(
              child: tenantsAsync.when(
// In the _buildTenantList method where we filter tenants
                data: (tenants) => _buildTenantList(
                  tenants
                      .where((tenant) => tenant.fullName
                          .toLowerCase()
                          .contains(_searchQuery.toLowerCase()))
                      .toList(),
                ),
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (error, _) => Center(child: Text('Error: $error')),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSearchBar() {
    return TextField(
      controller: _searchController,
      decoration: InputDecoration(
        hintText: 'Search tenants...',
        prefixIcon: const Icon(Icons.search),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        filled: true,
        fillColor: Colors.grey[100],
      ),
      onChanged: (value) {
        setState(() {
          _searchQuery = value;
        });
      },
    );
  }

  Widget _buildTenantList(List<User> tenants) {
    return ListView.builder(
      itemCount: tenants.length,
      itemBuilder: (context, index) {
        final tenant = tenants[index];
        print('Building tenant item: ${tenant.id}'); // Debug print

        return Card(
          margin: const EdgeInsets.symmetric(vertical: 4),
          child: ListTile(
            leading: CircleAvatar(
              child: Text(tenant.fullName[0].toUpperCase()),
            ),
            title: Text(tenant.fullName),
            subtitle: Text(tenant.email),
            onTap: () => _inviteTenant(tenant),
          ),
        );
      },
    );
  }

  void _inviteTenant(User tenant) async {
    print(
        '[InviteTenantDialog] _inviteTenant called for tenant: ${tenant.fullName} (${tenant.id})');

    final currentUser = ref.read(currentUserProvider);
    print('[InviteTenantDialog] Current user: ${currentUser?.id}');

    if (currentUser == null) {
      print('[InviteTenantDialog] Current user is null, showing error');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('User not authenticated')),
      );
      return;
    }

    try {
      print(
          '[InviteTenantDialog] Calling sendInvitation - propertyId: ${widget.propertyId}, landlordId: ${currentUser.id}, tenantId: ${tenant.id}');
      await ref.read(invitationNotifierProvider.notifier).sendInvitation(
            propertyId: widget.propertyId,
            landlordId: currentUser.id,
            tenantId: tenant.id,
            message:
                'Hello! I would like to invite you to rent my property. Please let me know if you are interested.',
          );
      print('[InviteTenantDialog] sendInvitation completed successfully');

      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Invitation sent to ${tenant.fullName}'),
            backgroundColor: AppColors.success,
          ),
        );
      }
    } catch (error, stackTrace) {
      print('[InviteTenantDialog] Error sending invitation: $error');
      print('[InviteTenantDialog] Stack trace: $stackTrace');

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to send invitation: $error'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }
}
