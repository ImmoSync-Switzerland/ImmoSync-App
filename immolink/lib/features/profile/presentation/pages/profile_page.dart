import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../../l10n/app_localizations.dart';
import 'package:immosync/features/auth/presentation/providers/auth_provider.dart';
import 'package:immosync/features/property/domain/models/property.dart';
import '../../../../core/providers/dynamic_colors_provider.dart';
import '../../../../core/widgets/user_avatar.dart';

class ProfilePage extends ConsumerWidget {
  const ProfilePage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final currentUser = ref.watch(currentUserProvider);
    final colors = ref.watch(dynamicColorsProvider);

    return Scaffold(
      backgroundColor: colors.primaryBackground,
      appBar: AppBar(
        title: Text(
          l10n.profile,
          style: TextStyle(
            color: colors.textPrimary,
            fontSize: 18,
            fontWeight: FontWeight.w600,
          ),
        ),
        backgroundColor: colors.primaryBackground,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios, color: colors.textPrimary),
          onPressed: () {
            if (context.canPop()) {
              context.pop();
            } else {
              context.go('/home');
            }
          },
        ),
        actions: [
          IconButton(
            icon: Icon(Icons.edit, color: colors.textPrimary),
            onPressed: () => context.push('/edit-profile'),
            tooltip: l10n.editProfile,
          ),
        ],
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [colors.primaryBackground, colors.surfaceCards],
          ),
        ),
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              _buildProfileHeader(context, l10n, currentUser, colors),
              const SizedBox(height: 24),
              _buildUserInfoSection(context, l10n, currentUser, colors),
              const SizedBox(height: 24),
              _buildQuickActionsSection(context, l10n, colors),
              const SizedBox(height: 24),
              _buildAccountSection(context, l10n, ref, colors),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildProfileHeader(BuildContext context, AppLocalizations l10n, user,
      DynamicAppColors colors) {
    return Card(
      elevation: 4,
      color: colors.surfaceCards,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              colors.primaryAccent.withValues(alpha: 0.1),
              colors.accentLight.withValues(alpha: 0.1),
            ],
          ),
        ),
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            Stack(
              children: [
                UserAvatar(
                  imageRef: user?.profileImage,
                  name: user?.fullName,
                  size: 100,
                ),
                Positioned(
                  bottom: 0,
                  right: 0,
                  child: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: colors.primaryAccent,
                      shape: BoxShape.circle,
                      border: Border.all(color: colors.surfaceCards, width: 3),
                    ),
                    child: Icon(
                      Icons.verified,
                      color: colors.textOnAccent,
                      size: 20,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Text(
              user?.fullName ?? l10n.profile,
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: colors.textPrimary,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              user?.email ?? '',
              style: TextStyle(
                fontSize: 14,
                color: colors.textSecondary,
              ),
            ),
            const SizedBox(height: 12),
            _buildRoleBadge(user?.role ?? 'tenant', colors, l10n),
          ],
        ),
      ),
    );
  }

  Widget _buildRoleBadge(
      String role, DynamicAppColors colors, AppLocalizations l10n) {
    final isLandlord = role.toLowerCase() == 'landlord';
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: isLandlord
            ? colors.primaryAccent.withValues(alpha: 0.2)
            : Colors.blue.withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isLandlord ? colors.primaryAccent : Colors.blue,
          width: 1,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            isLandlord ? Icons.business : Icons.home,
            size: 16,
            color: isLandlord ? colors.primaryAccent : Colors.blue,
          ),
          const SizedBox(width: 8),
          Text(
            isLandlord ? l10n.landlord : l10n.tenant,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: isLandlord ? colors.primaryAccent : Colors.blue,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildUserInfoSection(BuildContext context, AppLocalizations l10n,
      user, DynamicAppColors colors) {
    return Card(
      elevation: 4,
      color: colors.surfaceCards,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              l10n.accountInformation,
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: colors.textPrimary,
              ),
            ),
            const SizedBox(height: 20),
            _buildInfoRow(
              Icons.person_outline,
              l10n.name,
              user?.fullName ?? l10n.notAvailable,
              colors,
            ),
            const Divider(height: 24),
            _buildInfoRow(
              Icons.email_outlined,
              l10n.email,
              user?.email ?? l10n.notAvailable,
              colors,
            ),
            if (user?.address != null &&
                (user!.address.street.isNotEmpty ||
                    user.address.city.isNotEmpty ||
                    user.address.postalCode.isNotEmpty)) ...[
              const Divider(height: 24),
              _buildInfoRow(
                Icons.location_on_outlined,
                l10n.address,
                _formatAddress(user.address),
                colors,
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(
      IconData icon, String label, String value, DynamicAppColors colors) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: colors.primaryAccent.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, color: colors.primaryAccent, size: 20),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(
                  fontSize: 12,
                  color: colors.textSecondary,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                value,
                style: TextStyle(
                  fontSize: 15,
                  color: colors.textPrimary,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildQuickActionsSection(
      BuildContext context, AppLocalizations l10n, DynamicAppColors colors) {
    return Card(
      elevation: 4,
      color: colors.surfaceCards,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              l10n.quickActions,
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: colors.textPrimary,
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: _buildActionButton(
                    context,
                    icon: Icons.edit,
                    label: l10n.editProfile,
                    colors: colors,
                    onTap: () => context.push('/edit-profile'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildActionButton(
                    context,
                    icon: Icons.lock_outline,
                    label: l10n.changePassword,
                    colors: colors,
                    onTap: () => context.push('/change-password'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActionButton(
    BuildContext context, {
    required IconData icon,
    required String label,
    required DynamicAppColors colors,
    required VoidCallback onTap,
  }) {
    return Material(
      color: colors.primaryAccent.withValues(alpha: 0.1),
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
          child: Column(
            children: [
              Icon(icon, color: colors.primaryAccent, size: 28),
              const SizedBox(height: 8),
              Text(
                label,
                style: TextStyle(
                  fontSize: 12,
                  color: colors.textPrimary,
                  fontWeight: FontWeight.w600,
                ),
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAccountSection(BuildContext context, AppLocalizations l10n,
      WidgetRef ref, DynamicAppColors colors) {
    return Card(
      elevation: 4,
      color: colors.surfaceCards,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: [
          _buildMenuTile(
            context,
            icon: Icons.settings_outlined,
            title: l10n.settings,
            subtitle: l10n.appSettings,
            colors: colors,
            onTap: () => context.push('/settings'),
          ),
          Divider(
              height: 1, color: colors.textSecondary.withValues(alpha: 0.1)),
          _buildMenuTile(
            context,
            icon: Icons.help_outline,
            title: l10n.helpCenter,
            subtitle: l10n.helpCenterDescription,
            colors: colors,
            onTap: () => context.push('/help-center'),
          ),
          Divider(
              height: 1, color: colors.textSecondary.withValues(alpha: 0.1)),
          _buildMenuTile(
            context,
            icon: Icons.logout_outlined,
            title: l10n.logout,
            subtitle: l10n.signOutOfAccount,
            colors: colors,
            onTap: () => _handleLogout(context, ref, l10n),
            isDestructive: true,
          ),
        ],
      ),
    );
  }

  Widget _buildMenuTile(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String subtitle,
    required DynamicAppColors colors,
    required VoidCallback onTap,
    bool isDestructive = false,
  }) {
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      leading: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: isDestructive
              ? Colors.red.withValues(alpha: 0.1)
              : colors.primaryAccent.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(
          icon,
          color: isDestructive ? Colors.red : colors.primaryAccent,
          size: 24,
        ),
      ),
      title: Text(
        title,
        style: TextStyle(
          fontWeight: FontWeight.w600,
          color: isDestructive ? Colors.red : colors.textPrimary,
          fontSize: 15,
        ),
      ),
      subtitle: Text(
        subtitle,
        style: TextStyle(
          color: colors.textSecondary,
          fontSize: 12,
        ),
      ),
      trailing: Icon(
        Icons.chevron_right,
        color: colors.textSecondary,
      ),
      onTap: onTap,
    );
  }

  String _formatAddress(Address address) {
    final parts = <String>[];
    if (address.street.isNotEmpty) parts.add(address.street);
    if (address.postalCode.isNotEmpty && address.city.isNotEmpty) {
      parts.add('${address.postalCode} ${address.city}');
    } else if (address.city.isNotEmpty) {
      parts.add(address.city);
    } else if (address.postalCode.isNotEmpty) {
      parts.add(address.postalCode);
    }
    if (address.country.isNotEmpty) parts.add(address.country);
    return parts.isEmpty ? '' : parts.join(', ');
  }

  void _handleLogout(
      BuildContext context, WidgetRef ref, AppLocalizations l10n) {
    showDialog(
      context: context,
      builder: (ctx) {
        final colors = ref.watch(dynamicColorsProvider);
        return AlertDialog(
          backgroundColor: colors.surfaceCards,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: Text(l10n.confirmLogout,
              style: TextStyle(color: colors.textPrimary)),
          content: Text(l10n.logoutConfirmation,
              style: TextStyle(color: colors.textSecondary)),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(),
              child: Text(l10n.cancel,
                  style: TextStyle(color: colors.textSecondary)),
            ),
            TextButton(
              onPressed: () {
                Navigator.of(ctx).pop();
                ref.read(authProvider.notifier).logout();
                context.go('/login');
              },
              child: Text(
                l10n.logout,
                style: const TextStyle(
                    color: Colors.red, fontWeight: FontWeight.w600),
              ),
            ),
          ],
        );
      },
    );
  }
}
