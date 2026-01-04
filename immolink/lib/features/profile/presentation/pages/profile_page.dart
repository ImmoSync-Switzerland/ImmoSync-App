import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:immosync/features/auth/domain/models/user.dart';
import 'package:immosync/features/auth/presentation/providers/auth_provider.dart';
import 'package:immosync/features/property/domain/models/property.dart';
import '../../../../../l10n/app_localizations.dart';
import '../../../../core/providers/dynamic_colors_provider.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/widgets/common_bottom_nav.dart';
import '../../../../core/widgets/user_avatar.dart';
import '../../../home/presentation/models/dashboard_design.dart';
import '../../../home/presentation/pages/glass_dashboard_shared.dart'
    show GlassContainer, GlassPageScaffold;
import '../../../settings/providers/settings_provider.dart';

class ProfilePage extends ConsumerWidget {
  const ProfilePage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final User? user = ref.watch(currentUserProvider);
    final colors = ref.watch(dynamicColorsProvider);
    final design = dashboardDesignFromId(
      ref.watch(settingsProvider).dashboardDesign,
    );
    final bool glassMode = design == DashboardDesign.glass;

    final Widget content = user == null
        ? _buildLoadingState(
            colors,
            l10n,
            glassMode: glassMode,
          )
        : SingleChildScrollView(
            padding: glassMode
                ? const EdgeInsets.fromLTRB(16, 12, 16, 120)
                : const EdgeInsets.fromLTRB(16, 12, 16, 32),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _buildProfileHeader(
                  context,
                  l10n,
                  user,
                  colors,
                  glassMode: glassMode,
                ),
                const SizedBox(height: 20),
                _buildUserInfoSection(
                  context,
                  l10n,
                  user,
                  colors,
                  glassMode: glassMode,
                ),
                const SizedBox(height: 20),
                _buildQuickActionsSection(
                  context,
                  l10n,
                  colors,
                  glassMode: glassMode,
                ),
                const SizedBox(height: 20),
                _buildAccountSection(
                  context,
                  l10n,
                  ref,
                  colors,
                  glassMode: glassMode,
                ),
              ],
            ),
          );

    if (glassMode) {
      return GlassPageScaffold(
        title: l10n.profile,
        actions: user == null
            ? null
            : [
                IconButton(
                  icon: const Icon(Icons.edit_outlined, color: Colors.white),
                  tooltip: l10n.editProfile,
                  onPressed: () => context.push('/edit-profile'),
                ),
              ],
        body: content,
      );
    }

    return Scaffold(
      backgroundColor: colors.primaryBackground,
      appBar: AppBar(
        backgroundColor: colors.primaryBackground,
        elevation: 0,
        title: Text(
          l10n.profile,
          style: AppTypography.pageTitle.copyWith(color: colors.textPrimary),
        ),
        leading: IconButton(
          icon:
              Icon(Icons.arrow_back_ios_new_rounded, color: colors.textPrimary),
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
            icon: Icon(Icons.edit_outlined, color: colors.textPrimary),
            onPressed: () => context.push('/edit-profile'),
            tooltip: l10n.editProfile,
          ),
        ],
      ),
      bottomNavigationBar: const CommonBottomNav(),
      body: SafeArea(child: content),
    );
  }

  Widget _buildLoadingState(
    DynamicAppColors colors,
    AppLocalizations l10n, {
    required bool glassMode,
  }) {
    final indicator = SizedBox(
      width: 32,
      height: 32,
      child: CircularProgressIndicator(
        strokeWidth: 2.5,
        valueColor: AlwaysStoppedAnimation<Color>(
          glassMode ? Colors.white : colors.primaryAccent,
        ),
      ),
    );

    final child = Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          indicator,
          const SizedBox(height: 12),
          Text(
            l10n.loading,
            style: TextStyle(
              color: glassMode
                  ? Colors.white.withValues(alpha: 0.85)
                  : colors.textSecondary,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );

    if (glassMode) {
      return Center(
        child: GlassContainer(
          padding: const EdgeInsets.all(24),
          child: child,
        ),
      );
    }

    return Center(child: child);
  }

  Widget _buildProfileHeader(
    BuildContext context,
    AppLocalizations l10n,
    User user,
    DynamicAppColors colors, {
    required bool glassMode,
  }) {
    final bool isValidated = user.isValidated;
    final String? avatarRef = user.profileImageUrl ?? user.profileImage;
    final titleColor = _primaryTextColor(colors, glassMode);
    final subtitleColor = _secondaryTextColor(colors, glassMode);
    final badgeBackground = glassMode
        ? Colors.white.withValues(alpha: 0.15)
        : colors.surfaceWithElevation(3);

    return _sectionCard(
      colors: colors,
      glassMode: glassMode,
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Stack(
                clipBehavior: Clip.none,
                children: [
                  UserAvatar(
                    imageRef: avatarRef,
                    name: user.fullName,
                    size: 90,
                  ),
                  if (isValidated)
                    Positioned(
                      bottom: -4,
                      right: -4,
                      child: Container(
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(
                          color: badgeBackground,
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: glassMode
                                ? Colors.white.withValues(alpha: 0.3)
                                : colors.primaryBackground,
                            width: 2,
                          ),
                        ),
                        child: Icon(
                          Icons.verified_rounded,
                          size: 18,
                          color:
                              glassMode ? Colors.white : colors.primaryAccent,
                        ),
                      ),
                    ),
                ],
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      user.fullName.isNotEmpty ? user.fullName : l10n.profile,
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.w700,
                        color: titleColor,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    if (user.email.isNotEmpty) ...[
                      const SizedBox(height: 6),
                      Text(
                        user.email,
                        style: TextStyle(
                          fontSize: 14,
                          color: subtitleColor,
                        ),
                      ),
                    ],
                    const SizedBox(height: 12),
                    _buildRoleBadge(
                      user.role,
                      colors,
                      l10n,
                      glassMode: glassMode,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildRoleBadge(
    String role,
    DynamicAppColors colors,
    AppLocalizations l10n, {
    required bool glassMode,
  }) {
    final isLandlord = role.toLowerCase() == 'landlord';
    final Color baseAccent = isLandlord ? colors.primaryAccent : colors.info;
    final Color accent = glassMode ? Colors.white : baseAccent;
    final IconData icon = isLandlord ? Icons.business : Icons.home_rounded;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(
        color: accent.withValues(alpha: glassMode ? 0.25 : 0.12),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: accent.withValues(alpha: 0.35)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: accent),
          const SizedBox(width: 8),
          Text(
            isLandlord ? l10n.landlord : l10n.tenant,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: accent,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildUserInfoSection(
    BuildContext context,
    AppLocalizations l10n,
    User user,
    DynamicAppColors colors, {
    required bool glassMode,
  }) {
    final String addressText = _formatAddress(user.address);

    return _sectionCard(
      colors: colors,
      glassMode: glassMode,
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            l10n.accountInformation,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: _primaryTextColor(colors, glassMode),
            ),
          ),
          const SizedBox(height: 18),
          _buildInfoRow(
            icon: Icons.person_outline,
            label: l10n.name,
            value: user.fullName.isNotEmpty ? user.fullName : l10n.notAvailable,
            colors: colors,
            glassMode: glassMode,
          ),
          const SizedBox(height: 16),
          _buildInfoRow(
            icon: Icons.email_outlined,
            label: l10n.email,
            value: user.email.isNotEmpty ? user.email : l10n.notAvailable,
            colors: colors,
            glassMode: glassMode,
          ),
          if (addressText.isNotEmpty) ...[
            const SizedBox(height: 16),
            _buildInfoRow(
              icon: Icons.location_on_outlined,
              label: l10n.address,
              value: addressText,
              colors: colors,
              glassMode: glassMode,
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildInfoRow({
    required IconData icon,
    required String label,
    required String value,
    required DynamicAppColors colors,
    required bool glassMode,
  }) {
    final Color iconColor = glassMode ? Colors.white : colors.primaryAccent;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: glassMode
                ? Colors.white.withValues(alpha: 0.2)
                : colors.primaryAccent.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(icon, color: iconColor, size: 20),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(
                  fontSize: 12,
                  color: _secondaryTextColor(colors, glassMode),
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                value,
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  color: _primaryTextColor(colors, glassMode),
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildQuickActionsSection(
    BuildContext context,
    AppLocalizations l10n,
    DynamicAppColors colors, {
    required bool glassMode,
  }) {
    return _sectionCard(
      colors: colors,
      glassMode: glassMode,
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            l10n.quickActions,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: _primaryTextColor(colors, glassMode),
            ),
          ),
          const SizedBox(height: 16),
          LayoutBuilder(
            builder: (context, constraints) {
              final bool narrow = constraints.maxWidth < 360;
              final double width = narrow
                  ? constraints.maxWidth
                  : (constraints.maxWidth - 12) / 2;
              return Wrap(
                spacing: 12,
                runSpacing: 12,
                children: [
                  _buildActionButton(
                    context,
                    label: l10n.editProfile,
                    icon: Icons.edit_outlined,
                    accent: colors.primaryAccent,
                    onTap: () => context.push('/edit-profile'),
                    width: width,
                    colors: colors,
                    glassMode: glassMode,
                  ),
                  _buildActionButton(
                    context,
                    label: l10n.changePassword,
                    icon: Icons.lock_outline,
                    accent: colors.info,
                    onTap: () => context.push('/change-password'),
                    width: width,
                    colors: colors,
                    glassMode: glassMode,
                  ),
                ],
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildActionButton(
    BuildContext context, {
    required String label,
    required IconData icon,
    required Color accent,
    required VoidCallback onTap,
    required double width,
    required DynamicAppColors colors,
    required bool glassMode,
  }) {
    final Color iconColor = glassMode ? Colors.white : accent;
    return SizedBox(
      width: width,
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 18),
          decoration: BoxDecoration(
            color: glassMode
                ? Colors.white.withValues(alpha: 0.1)
                : colors.surfaceWithElevation(1),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: glassMode
                  ? Colors.white.withValues(alpha: 0.2)
                  : colors.borderLight,
            ),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: accent.withValues(alpha: glassMode ? 0.3 : 0.12),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, size: 22, color: iconColor),
              ),
              const SizedBox(height: 10),
              Text(
                label,
                style: TextStyle(
                  fontSize: 13,
                  color: _primaryTextColor(colors, glassMode),
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

  Widget _buildAccountSection(
    BuildContext context,
    AppLocalizations l10n,
    WidgetRef ref,
    DynamicAppColors colors, {
    required bool glassMode,
  }) {
    return _sectionCard(
      colors: colors,
      glassMode: glassMode,
      padding: EdgeInsets.zero,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          _buildMenuTile(
            context,
            icon: Icons.settings_outlined,
            title: l10n.settings,
            subtitle: l10n.appSettings,
            colors: colors,
            onTap: () => context.push('/settings'),
            glassMode: glassMode,
          ),
          _buildDivider(colors, glassMode: glassMode),
          _buildMenuTile(
            context,
            icon: Icons.help_outline,
            title: l10n.helpCenter,
            subtitle: l10n.helpCenterDescription,
            colors: colors,
            onTap: () => context.push('/help-center'),
            glassMode: glassMode,
          ),
          _buildDivider(colors, glassMode: glassMode),
          _buildMenuTile(
            context,
            icon: Icons.logout,
            title: l10n.logout,
            subtitle: l10n.signOutOfAccount,
            colors: colors,
            onTap: () => _handleLogout(context, ref, l10n),
            glassMode: glassMode,
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
    required bool glassMode,
    bool isDestructive = false,
  }) {
    final Color baseAccent =
        isDestructive ? colors.error : colors.primaryAccent;
    final Color accent =
        glassMode && !isDestructive ? Colors.white : baseAccent;

    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 8),
      leading: Container(
        padding: const EdgeInsets.all(9),
        decoration: BoxDecoration(
          color: accent.withValues(alpha: glassMode ? 0.25 : 0.12),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Icon(icon, color: glassMode ? Colors.white : accent, size: 22),
      ),
      title: Text(
        title,
        style: TextStyle(
          fontWeight: FontWeight.w600,
          color: isDestructive && !glassMode
              ? colors.error
              : _primaryTextColor(colors, glassMode),
          fontSize: 15,
        ),
      ),
      subtitle: Text(
        subtitle,
        style: TextStyle(
          color: _secondaryTextColor(colors, glassMode),
          fontSize: 12,
        ),
      ),
      trailing: Icon(
        Icons.chevron_right_rounded,
        color: glassMode
            ? Colors.white.withValues(alpha: 0.7)
            : colors.textTertiary,
      ),
      onTap: onTap,
    );
  }

  Widget _buildDivider(
    DynamicAppColors colors, {
    required bool glassMode,
  }) {
    return Container(
      height: 1,
      color: glassMode
          ? Colors.white.withValues(alpha: 0.2)
          : colors.dividerSeparator,
    );
  }

  Widget _sectionCard({
    required DynamicAppColors colors,
    required Widget child,
    EdgeInsets padding = const EdgeInsets.all(20),
    bool glassMode = false,
  }) {
    if (glassMode) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: GlassContainer(
          width: double.infinity,
          padding: padding,
          child: child,
        ),
      );
    }

    return Container(
      decoration: BoxDecoration(
        color: colors.surfaceWithElevation(1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: colors.borderLight),
        boxShadow: [
          BoxShadow(
            color: colors.shadowColor.withValues(alpha: 0.08),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Padding(
        padding: padding,
        child: child,
      ),
    );
  }

  Color _primaryTextColor(DynamicAppColors colors, bool glassMode) =>
      glassMode ? Colors.white : colors.textPrimary;

  Color _secondaryTextColor(DynamicAppColors colors, bool glassMode) =>
      glassMode ? Colors.white.withValues(alpha: 0.8) : colors.textSecondary;

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
    return parts.join(', ');
  }

  void _handleLogout(
    BuildContext context,
    WidgetRef ref,
    AppLocalizations l10n,
  ) {
    showDialog(
      context: context,
      builder: (ctx) {
        final colors = ref.watch(dynamicColorsProvider);
        return AlertDialog(
          backgroundColor: colors.surfaceWithElevation(2),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: Text(
            l10n.confirmLogout,
            style: TextStyle(color: colors.textPrimary),
          ),
          content: Text(
            l10n.logoutConfirmation,
            style: TextStyle(color: colors.textSecondary),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(),
              child: Text(
                l10n.cancel,
                style: TextStyle(color: colors.textSecondary),
              ),
            ),
            TextButton(
              onPressed: () {
                Navigator.of(ctx).pop();
                ref.read(authProvider.notifier).logout();
                context.go('/login');
              },
              child: Text(
                l10n.logout,
                style: TextStyle(
                  color: colors.error,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}
