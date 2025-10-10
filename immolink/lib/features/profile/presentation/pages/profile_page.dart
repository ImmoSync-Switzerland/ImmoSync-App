import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../../l10n/app_localizations.dart';
import 'package:immosync/features/auth/presentation/providers/auth_provider.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/user_avatar.dart';

class ProfilePage extends ConsumerWidget {
  const ProfilePage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final currentUser = ref.watch(currentUserProvider);
    return Scaffold(
      backgroundColor: AppColors.primaryBackground,
      appBar: AppBar(
        title: Text(l10n.profile),
        backgroundColor: AppColors.surfaceCards,
        foregroundColor: AppColors.textPrimary,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            _buildProfileHeader(context, l10n, currentUser),
            const SizedBox(height: 24),
            _buildProfileOptions(context, l10n, ref),
          ],
        ),
      ),
    );
  }

  Widget _buildProfileHeader(
      BuildContext context, AppLocalizations l10n, currentUser) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: AppColors.surfaceCards,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: AppColors.shadowColor,
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          UserAvatar(
            imageRef:
                currentUser?.profileImage, // prefers profileImageUrl internally
            name: currentUser?.fullName,
            size: 100,
          ),
          const SizedBox(height: 16),
          Text(
            currentUser?.email ?? l10n.profile,
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            l10n.landlord,
            style: TextStyle(
              fontSize: 14,
              color: AppColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProfileOptions(
      BuildContext context, AppLocalizations l10n, WidgetRef ref) {
    return Column(
      children: [
        _buildOptionTile(
          context,
          icon: Icons.edit_outlined,
          title: l10n.editProfile,
          subtitle: l10n.updateYourInformation,
          onTap: () => context.push('/edit-profile'),
        ),
        const SizedBox(height: 12),
        _buildOptionTile(
          context,
          icon: Icons.settings_outlined,
          title: l10n.settings,
          subtitle: l10n.appSettings,
          onTap: () => context.push('/settings'),
        ),
        const SizedBox(height: 12),
        _buildOptionTile(
          context,
          icon: Icons.lock_outline,
          title: l10n.changePassword,
          subtitle: l10n.updatePassword,
          onTap: () => context.push('/change-password'),
        ),
        const SizedBox(height: 12),
        _buildOptionTile(
          context,
          icon: Icons.logout_outlined,
          title: l10n.logout,
          subtitle: l10n.signOutOfAccount,
          onTap: () => _handleLogout(context, ref),
          isDestructive: true,
        ),
      ],
    );
  }

  Widget _buildOptionTile(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
    bool isDestructive = false,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surfaceCards,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: AppColors.shadowColor,
            blurRadius: 4,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      child: ListTile(
        leading: Icon(
          icon,
          color: isDestructive ? Colors.red : AppColors.primaryAccent,
        ),
        title: Text(
          title,
          style: TextStyle(
            fontWeight: FontWeight.w600,
            color: isDestructive ? Colors.red : AppColors.textPrimary,
          ),
        ),
        subtitle: Text(
          subtitle,
          style: TextStyle(
            color: AppColors.textSecondary,
            fontSize: 12,
          ),
        ),
        trailing: Icon(
          Icons.chevron_right,
          color: AppColors.textTertiary,
        ),
        onTap: onTap,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
    );
  }

  void _handleLogout(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(AppLocalizations.of(context)!.confirmLogout),
        content: Text(AppLocalizations.of(context)!.logoutConfirmation),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text(AppLocalizations.of(context)!.cancel),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              ref.read(authProvider.notifier).logout();
              context.go('/login');
            },
            child: Text(
              AppLocalizations.of(context)!.logout,
              style: const TextStyle(color: Colors.red),
            ),
          ),
        ],
      ),
    );
  }
}
