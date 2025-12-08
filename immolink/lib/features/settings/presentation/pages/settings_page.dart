import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:immosync/core/widgets/user_avatar.dart';
import 'package:immosync/features/auth/domain/models/user.dart';
import 'package:immosync/features/auth/presentation/providers/auth_provider.dart';
import 'package:immosync/features/home/presentation/models/dashboard_design.dart';
import 'package:immosync/features/home/presentation/pages/glass_dashboard_shared.dart';
import '../../../../../l10n/app_localizations.dart';
import '../../providers/settings_provider.dart';
import '../../../../core/providers/navigation_provider.dart';
import '../../../../core/providers/dynamic_colors_provider.dart';
import '../../../../core/widgets/common_bottom_nav.dart';

class SettingsPage extends ConsumerWidget {
  const SettingsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final User? user = ref.watch(currentUserProvider);
    final settings = ref.watch(settingsProvider);
    final colors = ref.watch(dynamicColorsProvider);
    final l10n = AppLocalizations.of(context)!;

    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(routeAwareNavigationProvider.notifier).setIndex(4);
    });

    final design = dashboardDesignFromId(settings.dashboardDesign);
    final bool glassMode = design == DashboardDesign.glass;

    final content = _buildSettingsContent(
      context: context,
      ref: ref,
      user: user,
      settings: settings,
      l10n: l10n,
      colors: colors,
      glassMode: glassMode,
    );

    if (glassMode) {
      return GlassPageScaffold(
        title: l10n.settings,
        onBack: () => context.go('/home'),
        body: content,
      );
    }

    return Scaffold(
      backgroundColor: colors.primaryBackground,
      appBar: AppBar(
        backgroundColor: colors.primaryBackground,
        elevation: 0,
        title: Text(
          l10n.settings,
          style: TextStyle(
            color: colors.textPrimary,
            fontSize: 18,
            fontWeight: FontWeight.w600,
          ),
        ),
        leading: IconButton(
          icon:
              Icon(Icons.arrow_back_ios_new_rounded, color: colors.textPrimary),
          onPressed: () => context.go('/home'),
        ),
      ),
      bottomNavigationBar: const CommonBottomNav(),
      body: SafeArea(child: content),
    );
  }

  Widget _buildSettingsContent({
    required BuildContext context,
    required WidgetRef ref,
    required User? user,
    required AppSettings settings,
    required AppLocalizations l10n,
    required DynamicAppColors colors,
    required bool glassMode,
  }) {
    final EdgeInsets padding = glassMode
        ? const EdgeInsets.fromLTRB(0, 8, 0, 160)
        : const EdgeInsets.fromLTRB(16, 12, 16, 28);

    return ListView(
      padding: padding,
      children: [
        _buildProfileSection(context, user, l10n, colors, glassMode),
        const SizedBox(height: 20),
        _buildPreferencesSection(
          context,
          ref,
          settings,
          l10n,
          colors,
          glassMode,
        ),
        const SizedBox(height: 20),
        _buildSecuritySection(context, ref, l10n, colors, glassMode),
        const SizedBox(height: 20),
        _buildNotificationsSection(
          context,
          ref,
          settings,
          l10n,
          colors,
          glassMode,
        ),
        const SizedBox(height: 20),
        _buildSupportSection(context, ref, l10n, colors, glassMode),
        if (kDebugMode) ...[
          const SizedBox(height: 20),
          _buildDebugSection(context, ref, colors, glassMode),
        ],
        const SizedBox(height: 24),
        _buildLogoutButton(context, ref, l10n, colors, glassMode),
      ],
    );
  }

  Widget _buildProfileSection(
    BuildContext context,
    User? user,
    AppLocalizations l10n,
    DynamicAppColors colors,
    bool glassMode,
  ) {
    final String displayName =
        user?.fullName.isNotEmpty == true ? user!.fullName : l10n.profile;
    final String displayEmail =
        user?.email.isNotEmpty == true ? user!.email : l10n.notAvailable;
    final String role = user?.role ?? '';
    final String? avatarRef = user?.profileImageUrl ?? user?.profileImage;
    final Color primaryColor = _primaryTextColor(colors, glassMode);
    final Color secondaryColor = _secondaryTextColor(colors, glassMode);
    final Color accentColor = glassMode ? Colors.white : colors.primaryAccent;

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
              UserAvatar(
                imageRef: avatarRef,
                name: displayName,
                size: 72,
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      displayName,
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.w700,
                        color: primaryColor,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 6),
                    Text(
                      displayEmail,
                      style: TextStyle(
                        fontSize: 14,
                        color: secondaryColor,
                      ),
                    ),
                    if (role.isNotEmpty) ...[
                      const SizedBox(height: 10),
                      _buildRoleChip(role, l10n, colors, glassMode),
                    ],
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Align(
            alignment: Alignment.centerLeft,
            child: OutlinedButton.icon(
              onPressed: () => context.push('/edit-profile'),
              icon: Icon(Icons.edit_outlined, color: accentColor, size: 18),
              label: Text(
                l10n.editProfile,
                style:
                    TextStyle(color: accentColor, fontWeight: FontWeight.w600),
              ),
              style: OutlinedButton.styleFrom(
                foregroundColor: accentColor,
                backgroundColor:
                    glassMode ? Colors.white.withValues(alpha: 0.12) : null,
                side: BorderSide(
                  color: glassMode
                      ? Colors.white.withValues(alpha: 0.4)
                      : colors.primaryAccent.withValues(alpha: 0.4),
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRoleChip(
    String role,
    AppLocalizations l10n,
    DynamicAppColors colors,
    bool glassMode,
  ) {
    final bool isLandlord = role.toLowerCase() == 'landlord';
    final Color accent = isLandlord ? colors.primaryAccent : colors.info;
    final IconData icon = isLandlord ? Icons.business : Icons.home_rounded;
    final Color background = glassMode
        ? accent.withValues(alpha: 0.2)
        : accent.withValues(alpha: 0.12);
    final Color borderColor = glassMode
        ? Colors.white.withValues(alpha: 0.45)
        : accent.withValues(alpha: 0.35);
    final Color textColor = glassMode ? Colors.white : accent;
    final Color iconColor = glassMode ? Colors.white : accent;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: borderColor),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: iconColor),
          const SizedBox(width: 6),
          Text(
            isLandlord ? l10n.landlord : l10n.tenant,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: textColor,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPreferencesSection(
    BuildContext context,
    WidgetRef ref,
    AppSettings settings,
    AppLocalizations l10n,
    DynamicAppColors colors,
    bool glassMode,
  ) {
    final Color primaryColor = _primaryTextColor(colors, glassMode);
    return _sectionCard(
      colors: colors,
      glassMode: glassMode,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            l10n.preferences,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: primaryColor,
            ),
          ),
          const SizedBox(height: 12),
          _buildSettingTile(
            context,
            title: l10n.language,
            subtitle: _getLanguageDisplayName(settings.language, l10n),
            icon: Icons.language,
            colors: colors,
            glassMode: glassMode,
            onTap: () => _showLanguageSelectionDialog(context, ref, l10n),
          ),
          _buildDivider(colors, glassMode),
          _buildSettingTile(
            context,
            title: l10n.theme,
            subtitle: _getThemeName(settings.theme, l10n),
            icon: Icons.brightness_6_outlined,
            colors: colors,
            glassMode: glassMode,
            onTap: () => _showThemeSelectionDialog(context, ref, l10n),
          ),
          _buildDivider(colors, glassMode),
          _buildSettingTile(
            context,
            title: l10n.dashboardDesign,
            subtitle: _getDashboardDesignName(settings.dashboardDesign, l10n),
            icon: Icons.dashboard_customize_outlined,
            colors: colors,
            glassMode: glassMode,
            onTap: () =>
                _showDashboardDesignSelectionDialog(context, ref, l10n),
          ),
          _buildDivider(colors, glassMode),
          _buildSettingTile(
            context,
            title: l10n.currency,
            subtitle: settings.currency,
            icon: Icons.payments_outlined,
            colors: colors,
            glassMode: glassMode,
            onTap: () => _showCurrencySelectionDialog(context, ref, l10n),
          ),
        ],
      ),
    );
  }

  Widget _buildSettingTile(
    BuildContext context, {
    required String title,
    required String subtitle,
    required IconData icon,
    required DynamicAppColors colors,
    required bool glassMode,
    required VoidCallback onTap,
  }) {
    final Color primaryColor = _primaryTextColor(colors, glassMode);
    final Color secondaryColor = _secondaryTextColor(colors, glassMode);
    final Color accentColor = glassMode ? Colors.white : colors.primaryAccent;
    final Color trailingColor =
        glassMode ? Colors.white.withValues(alpha: 0.7) : colors.textTertiary;

    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: glassMode
              ? Colors.white.withValues(alpha: 0.18)
              : colors.primaryAccent.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(12),
          border: glassMode
              ? Border.all(color: Colors.white.withValues(alpha: 0.2))
              : null,
        ),
        child: Icon(icon, color: accentColor, size: 20),
      ),
      title: Text(
        title,
        style: TextStyle(
          color: primaryColor,
          fontWeight: FontWeight.w600,
          fontSize: 15,
        ),
      ),
      subtitle: subtitle.isNotEmpty
          ? Text(
              subtitle,
              style: TextStyle(
                color: secondaryColor,
                fontSize: 12,
              ),
            )
          : null,
      trailing: Icon(
        Icons.chevron_right_rounded,
        color: trailingColor,
      ),
      onTap: onTap,
    );
  }

  Widget _buildSecuritySection(
    BuildContext context,
    WidgetRef ref,
    AppLocalizations l10n,
    DynamicAppColors colors,
    bool glassMode,
  ) {
    final Color primaryColor = _primaryTextColor(colors, glassMode);
    return _sectionCard(
      colors: colors,
      glassMode: glassMode,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            l10n.security,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: primaryColor,
            ),
          ),
          const SizedBox(height: 12),
          _buildSettingTile(
            context,
            title: l10n.changePassword,
            subtitle: '',
            icon: Icons.lock_outline,
            colors: colors,
            glassMode: glassMode,
            onTap: () => context.push('/change-password'),
          ),
          _buildDivider(colors, glassMode),
          _buildSettingTile(
            context,
            title: l10n.twoFactorAuth,
            subtitle: l10n.disabled,
            icon: Icons.security_outlined,
            colors: colors,
            glassMode: glassMode,
            onTap: () => context.push('/two-factor-auth'),
          ),
          _buildDivider(colors, glassMode),
          _buildSettingTile(
            context,
            title: l10n.privacySettings,
            subtitle: '',
            icon: Icons.privacy_tip_outlined,
            colors: colors,
            glassMode: glassMode,
            onTap: () => context.push('/privacy-settings'),
          ),
        ],
      ),
    );
  }

  Widget _buildNotificationsSection(
    BuildContext context,
    WidgetRef ref,
    AppSettings settings,
    AppLocalizations l10n,
    DynamicAppColors colors,
    bool glassMode,
  ) {
    final Color primaryColor = _primaryTextColor(colors, glassMode);
    return _sectionCard(
      colors: colors,
      glassMode: glassMode,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            l10n.notifications,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: primaryColor,
            ),
          ),
          const SizedBox(height: 4),
          _buildNotificationToggle(
            context,
            ref,
            icon: Icons.email_outlined,
            title: l10n.emailNotifications,
            subtitle: l10n.receiveUpdatesEmail,
            value: settings.emailNotifications,
            onChanged: (value) {
              ref
                  .read(settingsProvider.notifier)
                  .updateEmailNotifications(value);
              _showSnackBar(
                context,
                '${l10n.emailNotifications} ${value ? l10n.enabled : l10n.disabled}',
              );
            },
            colors: colors,
            glassMode: glassMode,
          ),
          _buildDivider(colors, glassMode),
          _buildNotificationToggle(
            context,
            ref,
            icon: Icons.notifications_outlined,
            title: l10n.pushNotifications,
            subtitle: l10n.pushNotificationSubtitle,
            value: settings.pushNotifications,
            onChanged: (value) {
              ref
                  .read(settingsProvider.notifier)
                  .updatePushNotifications(value);
              _showSnackBar(
                context,
                '${l10n.pushNotifications} ${value ? l10n.enabled : l10n.disabled}',
              );
            },
            colors: colors,
            glassMode: glassMode,
          ),
          _buildDivider(colors, glassMode),
          _buildNotificationToggle(
            context,
            ref,
            icon: Icons.payment_outlined,
            title: l10n.paymentReminders,
            subtitle: l10n.paymentReminderSubtitle,
            value: settings.paymentReminders,
            onChanged: (value) {
              ref.read(settingsProvider.notifier).updatePaymentReminders(value);
              _showSnackBar(
                context,
                '${l10n.paymentReminders} ${value ? l10n.enabled : l10n.disabled}',
              );
            },
            colors: colors,
            glassMode: glassMode,
          ),
        ],
      ),
    );
  }

  Widget _buildNotificationToggle(
    BuildContext context,
    WidgetRef ref, {
    required IconData icon,
    required String title,
    required String subtitle,
    required bool value,
    required ValueChanged<bool> onChanged,
    required DynamicAppColors colors,
    required bool glassMode,
  }) {
    final Color accent = glassMode ? Colors.white : colors.primaryAccent;
    final Color primaryColor = _primaryTextColor(colors, glassMode);
    final Color secondaryColor = _secondaryTextColor(colors, glassMode);
    final Color inactiveThumb =
        glassMode ? Colors.white.withValues(alpha: 0.6) : colors.borderLight;
    final Color inactiveTrack = glassMode
        ? Colors.white.withValues(alpha: 0.2)
        : colors.dividerSeparator;
    final theme = Theme.of(context);
    final CupertinoThemeData cupertinoTheme = CupertinoThemeData(
      primaryColor: accent,
      brightness: theme.brightness,
    );

    return Theme(
      data: theme.copyWith(cupertinoOverrideTheme: cupertinoTheme),
      child: SwitchListTile.adaptive(
        contentPadding: EdgeInsets.zero,
        value: value,
        onChanged: onChanged,
        inactiveThumbColor: inactiveThumb,
        inactiveTrackColor: inactiveTrack,
        title: Text(
          title,
          style: TextStyle(
            color: primaryColor,
            fontWeight: FontWeight.w600,
          ),
        ),
        subtitle: Text(
          subtitle,
          style: TextStyle(color: secondaryColor),
        ),
        secondary: Icon(icon, color: accent),
        trackColor: WidgetStateProperty.resolveWith(
          (states) => states.contains(WidgetState.selected)
              ? (glassMode
                  ? Colors.white.withValues(alpha: 0.35)
                  : accent.withValues(alpha: 0.35))
              : inactiveTrack,
        ),
        thumbColor: WidgetStateProperty.resolveWith(
          (states) =>
              states.contains(WidgetState.selected) ? accent : inactiveThumb,
        ),
      ),
    );
  }

  Widget _buildSupportSection(
    BuildContext context,
    WidgetRef ref,
    AppLocalizations l10n,
    DynamicAppColors colors,
    bool glassMode,
  ) {
    final Color primaryColor = _primaryTextColor(colors, glassMode);
    return _sectionCard(
      colors: colors,
      glassMode: glassMode,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            l10n.about,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: primaryColor,
            ),
          ),
          const SizedBox(height: 12),
          _buildSettingTile(
            context,
            title: l10n.helpCenter,
            subtitle: '',
            icon: Icons.help_outline,
            colors: colors,
            glassMode: glassMode,
            onTap: () => context.push('/help-center'),
          ),
          _buildDivider(colors, glassMode),
          _buildSettingTile(
            context,
            title: l10n.contactSupport,
            subtitle: '',
            icon: Icons.support_agent_outlined,
            colors: colors,
            glassMode: glassMode,
            onTap: () => context.push('/contact-support'),
          ),
          _buildDivider(colors, glassMode),
          _buildSettingTile(
            context,
            title: l10n.termsOfService,
            subtitle: '',
            icon: Icons.description_outlined,
            colors: colors,
            glassMode: glassMode,
            onTap: () => context.push('/terms-of-service'),
          ),
          _buildDivider(colors, glassMode),
          _buildSettingTile(
            context,
            title: l10n.privacyPolicy,
            subtitle: '',
            icon: Icons.privacy_tip_outlined,
            colors: colors,
            glassMode: glassMode,
            onTap: () => context.push('/privacy-policy'),
          ),
        ],
      ),
    );
  }

  Widget _buildDebugSection(
    BuildContext context,
    WidgetRef ref,
    DynamicAppColors colors,
    bool glassMode,
  ) {
    return _sectionCard(
      colors: colors,
      glassMode: glassMode,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: glassMode
                      ? Colors.white.withValues(alpha: 0.18)
                      : colors.primaryAccent.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(12),
                  border: glassMode
                      ? Border.all(color: Colors.white.withValues(alpha: 0.2))
                      : null,
                ),
                child: Icon(Icons.bug_report_outlined,
                    color: glassMode ? Colors.white : colors.primaryAccent,
                    size: 20),
              ),
              const SizedBox(width: 12),
              Text(
                'Debug Tools',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: _primaryTextColor(colors, glassMode),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ListTile(
            contentPadding: EdgeInsets.zero,
            leading: Icon(
              Icons.analytics_outlined,
              color: glassMode ? Colors.white : colors.primaryAccent,
            ),
            title: Text(
              'Matrix Logs',
              style: TextStyle(
                color: _primaryTextColor(colors, glassMode),
                fontWeight: FontWeight.w600,
              ),
            ),
            subtitle: Text(
              'View Matrix client logs and debug info',
              style: TextStyle(
                color: _secondaryTextColor(colors, glassMode),
              ),
            ),
            trailing: Icon(
              Icons.chevron_right_rounded,
              color: glassMode
                  ? Colors.white.withValues(alpha: 0.7)
                  : colors.textTertiary,
            ),
            onTap: () => context.push('/debug/matrix-logs'),
          ),
        ],
      ),
    );
  }

  Widget _buildLogoutButton(
    BuildContext context,
    WidgetRef ref,
    AppLocalizations l10n,
    DynamicAppColors colors,
    bool glassMode,
  ) {
    final Color background =
        glassMode ? Colors.redAccent.withValues(alpha: 0.85) : colors.error;
    return ElevatedButton.icon(
      onPressed: () {
        ref.read(authProvider.notifier).logout();
        context.go('/login');
      },
      icon: const Icon(Icons.logout_rounded, size: 18),
      label: Text(
        l10n.logout,
        style: TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w700,
          color: colors.textOnAccent,
        ),
      ),
      style: ElevatedButton.styleFrom(
        backgroundColor: background,
        foregroundColor: colors.textOnAccent,
        padding: const EdgeInsets.symmetric(vertical: 16),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(14),
        ),
        elevation: glassMode ? 6 : 2,
      ),
    );
  }

  void _showSnackBar(BuildContext context, String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  String _getThemeName(String theme, AppLocalizations l10n) {
    switch (theme) {
      case 'light':
        return l10n.light;
      case 'dark':
        return l10n.dark;
      case 'system':
        return l10n.system;
      default:
        return l10n.light;
    }
  }

  String _getDashboardDesignName(String designId, AppLocalizations l10n) {
    final design = dashboardDesignFromId(designId);
    return design.localizedName(l10n);
  }

  Color _primaryTextColor(DynamicAppColors colors, bool glassMode) =>
      glassMode ? Colors.white : colors.textPrimary;

  Color _secondaryTextColor(DynamicAppColors colors, bool glassMode) =>
      glassMode ? Colors.white.withValues(alpha: 0.8) : colors.textSecondary;

  String _getLanguageDisplayName(String languageCode, AppLocalizations l10n) {
    switch (languageCode) {
      case 'en':
        return l10n.english;
      case 'de':
        return l10n.german;
      case 'fr':
        return l10n.french;
      case 'it':
        return l10n.italian;
      default:
        return l10n.english;
    }
  }

  void _showLanguageSelectionDialog(
    BuildContext context,
    WidgetRef ref,
    AppLocalizations l10n,
  ) {
    final colors = ref.watch(dynamicColorsProvider);
    final languages = {
      l10n.english: 'en',
      l10n.german: 'de',
      l10n.french: 'fr',
      l10n.italian: 'it',
    };
    final settingsNotifier = ref.read(settingsProvider.notifier);

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: colors.surfaceWithElevation(2),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(
          l10n.selectLanguage,
          style: TextStyle(color: colors.textPrimary),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: languages.entries
              .map(
                (entry) => ListTile(
                  contentPadding: EdgeInsets.zero,
                  title: Text(
                    entry.key,
                    style: TextStyle(color: colors.textPrimary),
                  ),
                  onTap: () async {
                    await settingsNotifier.updateLanguage(entry.value);
                    if (context.mounted) {
                      _showSnackBar(context, l10n.languageChangedTo(entry.key));
                      Navigator.pop(context);
                    }
                  },
                ),
              )
              .toList(),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              l10n.cancel,
              style: TextStyle(color: colors.primaryAccent),
            ),
          ),
        ],
      ),
    );
  }

  void _showThemeSelectionDialog(
    BuildContext context,
    WidgetRef ref,
    AppLocalizations l10n,
  ) {
    final colors = ref.watch(dynamicColorsProvider);
    final themes = {
      l10n.light: 'light',
      l10n.dark: 'dark',
      l10n.system: 'system',
    };
    final settingsNotifier = ref.read(settingsProvider.notifier);

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: colors.surfaceWithElevation(2),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(
          l10n.selectTheme,
          style: TextStyle(color: colors.textPrimary),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: themes.entries
              .map(
                (entry) => ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: Icon(
                    entry.value == 'light'
                        ? Icons.light_mode
                        : entry.value == 'dark'
                            ? Icons.dark_mode
                            : Icons.brightness_auto,
                    color: colors.primaryAccent,
                  ),
                  title: Text(
                    entry.key,
                    style: TextStyle(color: colors.textPrimary),
                  ),
                  onTap: () async {
                    await settingsNotifier.updateTheme(entry.value);
                    if (context.mounted) {
                      _showSnackBar(context, l10n.themeChangedTo(entry.key));
                      Navigator.pop(context);
                    }
                  },
                ),
              )
              .toList(),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              l10n.cancel,
              style: TextStyle(color: colors.primaryAccent),
            ),
          ),
        ],
      ),
    );
  }

  void _showDashboardDesignSelectionDialog(
    BuildContext context,
    WidgetRef ref,
    AppLocalizations l10n,
  ) {
    final colors = ref.watch(dynamicColorsProvider);
    final settingsNotifier = ref.read(settingsProvider.notifier);
    final currentDesign =
        dashboardDesignFromId(ref.read(settingsProvider).dashboardDesign);

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: colors.surfaceWithElevation(2),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(
          l10n.selectDashboardDesign,
          style: TextStyle(color: colors.textPrimary),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: DashboardDesign.values
              .map(
                (design) => ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: Icon(
                    design == DashboardDesign.glass
                        ? Icons.blur_on
                        : Icons.view_quilt_outlined,
                    color: colors.primaryAccent,
                  ),
                  title: Text(
                    design.localizedName(l10n),
                    style: TextStyle(color: colors.textPrimary),
                  ),
                  trailing: design == currentDesign
                      ? Icon(Icons.check, color: colors.primaryAccent)
                      : null,
                  onTap: () async {
                    await settingsNotifier.updateDashboardDesign(design.id);
                    if (context.mounted) {
                      _showSnackBar(
                        context,
                        l10n.dashboardDesignChangedTo(
                          design.localizedName(l10n),
                        ),
                      );
                      Navigator.pop(context);
                    }
                  },
                ),
              )
              .toList(),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              l10n.cancel,
              style: TextStyle(color: colors.primaryAccent),
            ),
          ),
        ],
      ),
    );
  }

  void _showCurrencySelectionDialog(
    BuildContext context,
    WidgetRef ref,
    AppLocalizations l10n,
  ) {
    final colors = ref.watch(dynamicColorsProvider);
    final currencies = ['CHF', 'EUR', 'USD', 'GBP'];
    final settingsNotifier = ref.read(settingsProvider.notifier);

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: colors.surfaceWithElevation(2),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(
          l10n.selectCurrency,
          style: TextStyle(color: colors.textPrimary),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: currencies
              .map(
                (currency) => ListTile(
                  contentPadding: EdgeInsets.zero,
                  title: Text(
                    currency,
                    style: TextStyle(color: colors.textPrimary),
                  ),
                  onTap: () async {
                    await settingsNotifier.updateCurrency(currency);
                    if (context.mounted) {
                      _showSnackBar(context, l10n.currencyChangedTo(currency));
                      Navigator.pop(context);
                    }
                  },
                ),
              )
              .toList(),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              l10n.cancel,
              style: TextStyle(color: colors.primaryAccent),
            ),
          ),
        ],
      ),
    );
  }

  Widget _sectionCard({
    required DynamicAppColors colors,
    required bool glassMode,
    required Widget child,
    EdgeInsets padding = const EdgeInsets.fromLTRB(20, 16, 20, 20),
  }) {
    if (glassMode) {
      return GlassContainer(
        padding: padding,
        child: child,
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
            blurRadius: 18,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Padding(
        padding: padding,
        child: child,
      ),
    );
  }

  Widget _buildDivider(DynamicAppColors colors, bool glassMode) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 12),
      height: 1,
      color: glassMode
          ? Colors.white.withValues(alpha: 0.16)
          : colors.dividerSeparator,
    );
  }
}
