import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../../l10n/app_localizations.dart';
import 'package:immosync/core/widgets/user_avatar.dart';
import 'package:immosync/features/auth/presentation/providers/auth_provider.dart';
import '../../providers/settings_provider.dart';
import '../../../../core/providers/navigation_provider.dart';
import '../../../../core/providers/dynamic_colors_provider.dart';
import '../../../../core/widgets/common_bottom_nav.dart';

class SettingsPage extends ConsumerWidget {
  const SettingsPage({super.key});
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentUser = ref.watch(currentUserProvider);
    final settings = ref.watch(settingsProvider);
    final colors = ref.watch(dynamicColorsProvider);
    final l10n = AppLocalizations.of(context)!;

    // Set navigation index to Profile (4) when this page is loaded
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(routeAwareNavigationProvider.notifier).setIndex(4);
    });

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
            inherit: true,
          ),
        ),
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios, color: colors.textPrimary),
          onPressed: () {
            // Navigate back to dashboard instead of popping
            context.go('/home');
          },
        ),
      ),
      bottomNavigationBar: const CommonBottomNav(),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [colors.primaryBackground, colors.surfaceCards],
          ),
        ),
        child: ListView(
          padding: const EdgeInsets.all(16.0),
          children: [
            _buildProfileSection(context, ref, currentUser, l10n),
            const SizedBox(height: 24),
            _buildPreferencesSection(context, ref, settings, l10n),
            const SizedBox(height: 24),
            _buildSecuritySection(context, ref, l10n),
            const SizedBox(height: 24),
            _buildNotificationsSection(context, ref, settings, l10n),
            const SizedBox(height: 24),
            _buildSupportSection(context, ref, l10n),
            const SizedBox(height: 24),
            // Debug section only visible in debug mode
            if (kDebugMode) ...[
              _buildDebugSection(context, ref, l10n),
              const SizedBox(height: 24),
            ],
            _buildLogoutButton(context, ref, l10n),
          ],
        ),
      ),
    );
  }

  Widget _buildProfileSection(
      BuildContext context, WidgetRef ref, user, AppLocalizations l10n) {
    final colors = ref.watch(dynamicColorsProvider);
    return Card(
      elevation: 4,
      color: colors.surfaceCards,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              l10n.profile,
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: colors.textPrimary,
                inherit: true,
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                UserAvatar(
                    imageRef: user?.profileImage,
                    name: user?.fullName,
                    size: 80),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        user?.fullName ?? 'User',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: colors.textPrimary,
                          inherit: true,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        user?.email ?? 'email@example.com',
                        style: TextStyle(
                          fontSize: 16,
                          color: colors.textSecondary,
                          inherit: true,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: colors.accentLight,
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Text(
                          user?.role.toUpperCase() ?? 'ROLE',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: colors.primaryAccent,
                            inherit: true,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            OutlinedButton(
              onPressed: () {
                context.push('/edit-profile');
              },
              style: OutlinedButton.styleFrom(
                side: BorderSide(color: colors.primaryAccent),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: Text(
                l10n.editProfile,
                style: TextStyle(color: colors.primaryAccent, inherit: true),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPreferencesSection(BuildContext context, WidgetRef ref,
      AppSettings settings, AppLocalizations l10n) {
    final colors = ref.watch(dynamicColorsProvider);
    return Card(
      elevation: 4,
      color: colors.surfaceCards,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              l10n.preferences,
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: colors.textPrimary,
                inherit: true,
              ),
            ),
            const SizedBox(height: 16),
            _buildSettingItem(
              context,
              l10n.language,
              _getLanguageDisplayName(settings.language, l10n),
              Icons.language,
              () {
                _showLanguageSelectionDialog(context, ref, l10n);
              },
              ref,
            ),
            Divider(color: colors.dividerSeparator),
            _buildSettingItem(
              context,
              l10n.theme,
              _getThemeName(settings.theme, l10n),
              Icons.brightness_6,
              () {
                _showThemeSelectionDialog(context, ref, l10n);
              },
              ref,
            ),
            Divider(color: colors.dividerSeparator),
            _buildSettingItem(
              context,
              l10n.currency,
              settings.currency,
              Icons.attach_money,
              () {
                _showCurrencySelectionDialog(context, ref, l10n);
              },
              ref,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSecuritySection(
      BuildContext context, WidgetRef ref, AppLocalizations l10n) {
    final colors = ref.watch(dynamicColorsProvider);
    return Card(
      elevation: 4,
      color: colors.surfaceCards,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              l10n.security,
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: colors.textPrimary,
                inherit: true,
              ),
            ),
            const SizedBox(height: 16),
            _buildSettingItem(
              context,
              l10n.changePassword,
              '',
              Icons.lock,
              () {
                context.push('/change-password');
              },
              ref,
            ),
            Divider(color: colors.dividerSeparator),
            _buildSettingItem(
              context,
              l10n.twoFactorAuth,
              l10n.disabled,
              Icons.security,
              () {
                context.push('/two-factor-auth');
              },
              ref,
            ),
            Divider(color: colors.dividerSeparator),
            _buildSettingItem(
              context,
              l10n.privacySettings,
              '',
              Icons.privacy_tip,
              () {
                context.push('/privacy-settings');
              },
              ref,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNotificationsSection(BuildContext context, WidgetRef ref,
      AppSettings settings, AppLocalizations l10n) {
    final colors = ref.watch(dynamicColorsProvider);
    return Card(
      elevation: 4,
      color: colors.surfaceCards,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              l10n.notifications,
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: colors.textPrimary,
                inherit: true,
              ),
            ),
            const SizedBox(height: 16),
            SwitchListTile(
              title: Text(l10n.emailNotifications,
                  style: TextStyle(color: colors.textPrimary, inherit: true)),
              subtitle: Text(l10n.receiveUpdatesEmail,
                  style: TextStyle(color: colors.textSecondary, inherit: true)),
              value: settings.emailNotifications,
              onChanged: (value) {
                ref
                    .read(settingsProvider.notifier)
                    .updateEmailNotifications(value);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                      content: Text(
                          '${l10n.emailNotifications} ${value ? l10n.enabled : l10n.disabled}')),
                );
              },
              secondary: Icon(Icons.email, color: colors.primaryAccent),
            ),
            Divider(color: colors.dividerSeparator),
            SwitchListTile(
              title: Text(l10n.pushNotifications,
                  style: TextStyle(color: colors.textPrimary, inherit: true)),
              subtitle: Text(l10n.pushNotificationSubtitle,
                  style: TextStyle(color: colors.textSecondary, inherit: true)),
              value: settings.pushNotifications,
              onChanged: (value) {
                ref
                    .read(settingsProvider.notifier)
                    .updatePushNotifications(value);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                      content: Text(
                          '${l10n.pushNotifications} ${value ? l10n.enabled : l10n.disabled}')),
                );
              },
              secondary: Icon(Icons.notifications, color: colors.primaryAccent),
            ),
            Divider(color: colors.dividerSeparator),
            SwitchListTile(
              title: Text(l10n.paymentReminders,
                  style: TextStyle(color: colors.textPrimary, inherit: true)),
              subtitle: Text(l10n.paymentReminderSubtitle,
                  style: TextStyle(color: colors.textSecondary, inherit: true)),
              value: settings.paymentReminders,
              onChanged: (value) {
                ref
                    .read(settingsProvider.notifier)
                    .updatePaymentReminders(value);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                      content: Text(
                          '${l10n.paymentReminders} ${value ? l10n.enabled : l10n.disabled}')),
                );
              },
              secondary: Icon(Icons.payment, color: colors.primaryAccent),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSupportSection(
      BuildContext context, WidgetRef ref, AppLocalizations l10n) {
    final colors = ref.watch(dynamicColorsProvider);
    return Card(
      elevation: 4,
      color: colors.surfaceCards,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              l10n.about,
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: colors.textPrimary,
                inherit: true,
              ),
            ),
            const SizedBox(height: 16),
            _buildSettingItem(
              context,
              l10n.helpCenter,
              '',
              Icons.help,
              () {
                context.push('/help-center');
              },
              ref,
            ),
            Divider(color: colors.dividerSeparator),
            _buildSettingItem(
              context,
              l10n.contactSupport,
              '',
              Icons.support_agent,
              () {
                context.push('/contact-support');
              },
              ref,
            ),
            Divider(color: colors.dividerSeparator),
            _buildSettingItem(
              context,
              l10n.termsOfService,
              '',
              Icons.description,
              () {
                context.push('/terms-of-service');
              },
              ref,
            ),
            Divider(color: colors.dividerSeparator),
            _buildSettingItem(
              context,
              l10n.privacyPolicy,
              '',
              Icons.policy,
              () {
                context.push('/privacy-policy');
              },
              ref,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLogoutButton(
      BuildContext context, WidgetRef ref, AppLocalizations l10n) {
    final colors = ref.watch(dynamicColorsProvider);
    return ElevatedButton(
      onPressed: () {
        ref.read(authProvider.notifier).logout();
        context.go('/login');
      },
      style: ElevatedButton.styleFrom(
        backgroundColor: colors.error,
        padding: const EdgeInsets.symmetric(vertical: 16),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
      ),
      child: Text(
        l10n.logout,
        style: TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.bold,
          color: colors.textOnAccent,
          inherit: true,
        ),
      ),
    );
  }

  Widget _buildSettingItem(
    BuildContext context,
    String title,
    String subtitle,
    IconData icon,
    VoidCallback onTap,
    WidgetRef ref,
  ) {
    final colors = ref.watch(dynamicColorsProvider);
    return ListTile(
      leading: Icon(icon, color: colors.primaryAccent),
      title: Text(title,
          style: TextStyle(color: colors.textPrimary, inherit: true)),
      subtitle: subtitle.isNotEmpty
          ? Text(subtitle,
              style: TextStyle(color: colors.textSecondary, inherit: true))
          : null,
      trailing: Icon(Icons.chevron_right, color: colors.textTertiary),
      onTap: onTap,
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
      BuildContext context, WidgetRef ref, AppLocalizations l10n) {
    final colors = ref.watch(dynamicColorsProvider);
    final languages = {
      l10n.english: 'en',
      l10n.german: 'de',
      l10n.french: 'fr',
      l10n.italian: 'it'
    };
    final settingsNotifier = ref.read(settingsProvider.notifier);

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: colors.surfaceCards,
        title: Text(l10n.selectLanguage,
            style: TextStyle(color: colors.textPrimary, inherit: true)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: languages.entries
              .map((entry) => ListTile(
                    title: Text(entry.key,
                        style: TextStyle(
                            color: colors.textPrimary, inherit: true)),
                    onTap: () async {
                      await settingsNotifier.updateLanguage(entry.value);
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                              content: Text(l10n.languageChangedTo(entry.key))),
                        );
                        Navigator.pop(context);
                      }
                    },
                  ))
              .toList(),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(l10n.cancel,
                style: TextStyle(color: colors.primaryAccent, inherit: true)),
          ),
        ],
      ),
    );
  }

  void _showThemeSelectionDialog(
      BuildContext context, WidgetRef ref, AppLocalizations l10n) {
    final colors = ref.watch(dynamicColorsProvider);
    final themes = {
      l10n.light: 'light',
      l10n.dark: 'dark',
      l10n.system: 'system'
    };
    final settingsNotifier = ref.read(settingsProvider.notifier);

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: colors.surfaceCards,
        title: Text(l10n.selectTheme,
            style: TextStyle(color: colors.textPrimary, inherit: true)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: themes.entries
              .map((entry) => ListTile(
                    title: Text(entry.key,
                        style: TextStyle(
                            color: colors.textPrimary, inherit: true)),
                    trailing: Icon(
                      entry.value == 'light'
                          ? Icons.light_mode
                          : entry.value == 'dark'
                              ? Icons.dark_mode
                              : Icons.brightness_auto,
                      color: colors.primaryAccent,
                    ),
                    onTap: () async {
                      await settingsNotifier.updateTheme(entry.value);
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                              content: Text(l10n.themeChangedTo(entry.key))),
                        );
                        Navigator.pop(context);
                      }
                    },
                  ))
              .toList(),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(l10n.cancel,
                style: TextStyle(color: colors.primaryAccent, inherit: true)),
          ),
        ],
      ),
    );
  }

  void _showCurrencySelectionDialog(
      BuildContext context, WidgetRef ref, AppLocalizations l10n) {
    final colors = ref.watch(dynamicColorsProvider);
    final currencies = ['CHF', 'EUR', 'USD', 'GBP'];
    final settingsNotifier = ref.read(settingsProvider.notifier);

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: colors.surfaceCards,
        title: Text(l10n.selectCurrency,
            style: TextStyle(color: colors.textPrimary, inherit: true)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: currencies
              .map((currency) => ListTile(
                    title: Text(currency,
                        style: TextStyle(
                            color: colors.textPrimary, inherit: true)),
                    onTap: () async {
                      await settingsNotifier.updateCurrency(currency);
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                              content: Text(l10n.currencyChangedTo(currency))),
                        );
                        Navigator.pop(context);
                      }
                    },
                  ))
              .toList(),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(l10n.cancel,
                style: TextStyle(color: colors.primaryAccent, inherit: true)),
          ),
        ],
      ),
    );
  }

  Widget _buildDebugSection(
      BuildContext context, WidgetRef ref, AppLocalizations l10n) {
    final colors = ref.watch(dynamicColorsProvider);
    return Card(
      elevation: 4,
      color: colors.surfaceCards,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.bug_report, color: colors.primaryAccent),
                const SizedBox(width: 8),
                Text(
                  'Debug Tools',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: colors.textPrimary,
                    inherit: true,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: Icon(Icons.analytics, color: colors.primaryAccent),
              title: Text(
                'Matrix Logs',
                style: TextStyle(color: colors.textPrimary, inherit: true),
              ),
              subtitle: Text(
                'View Matrix client logs and debug info',
                style: TextStyle(color: colors.textSecondary, inherit: true),
              ),
              trailing: Icon(Icons.arrow_forward_ios,
                  color: colors.textSecondary, size: 16),
              onTap: () {
                context.push('/debug/matrix-logs');
              },
            ),
          ],
        ),
      ),
    );
  }
}
