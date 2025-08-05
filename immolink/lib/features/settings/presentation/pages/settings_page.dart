import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:immolink/features/auth/presentation/providers/auth_provider.dart';
import '../../providers/settings_provider.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/providers/navigation_provider.dart';
import '../../../../core/providers/locale_provider.dart';
import '../../../../core/widgets/common_bottom_nav.dart';

class SettingsPage extends ConsumerWidget {
  const SettingsPage({super.key});
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentUser = ref.watch(currentUserProvider);
    final settings = ref.watch(settingsProvider);
    final l10n = AppLocalizations.of(context)!;
    
    // Set navigation index to Profile (4) when this page is loaded
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(routeAwareNavigationProvider.notifier).setIndex(4);
    });
    
    return Scaffold(
      backgroundColor: AppColors.primaryBackground,
      appBar: AppBar(
        backgroundColor: AppColors.primaryBackground,
        elevation: 0,
        title: Text(
          l10n.settings,
          style: TextStyle(
            color: AppColors.textPrimary,
            fontSize: 18,
            fontWeight: FontWeight.w600,
          ),
        ),
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios, color: AppColors.textPrimary),
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
            colors: [AppColors.primaryBackground, AppColors.surfaceCards],
          ),
        ),
        child: ListView(
          padding: const EdgeInsets.all(16.0),
          children: [
            _buildProfileSection(context, ref, currentUser, l10n),
            const SizedBox(height: 24),
            _buildPreferencesSection(context, ref, settings, l10n),
            const SizedBox(height: 24),
            _buildSecuritySection(context, l10n),
            const SizedBox(height: 24),
            _buildNotificationsSection(context, ref, settings, l10n),
            const SizedBox(height: 24),
            _buildSupportSection(context, l10n),
            const SizedBox(height: 24),
            _buildLogoutButton(context, ref, l10n),
          ],
        ),
      ),
    );
  }

  Widget _buildProfileSection(BuildContext context, WidgetRef ref, user, AppLocalizations l10n) {
    return Card(
      elevation: 4,
      color: AppColors.surfaceCards,
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
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                CircleAvatar(
                  radius: 40,
                  backgroundColor: AppColors.primaryAccent.withValues(alpha: 0.2),
                  child: Text(
                    user?.fullName.substring(0, 1) ?? 'U',
                    style: TextStyle(
                      fontSize: 30,
                      fontWeight: FontWeight.bold,
                      color: AppColors.primaryAccent,
                    ),
                  ),
                ),
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
                          color: AppColors.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        user?.email ?? 'email@example.com',
                        style: TextStyle(
                          fontSize: 16,
                          color: AppColors.textSecondary,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.accentLight,
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Text(
                          user?.role.toUpperCase() ?? 'ROLE',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: AppColors.primaryAccent,
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
                side: BorderSide(color: AppColors.primaryAccent),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: Text(
                l10n.editProfile,
                style: TextStyle(color: AppColors.primaryAccent),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPreferencesSection(BuildContext context, WidgetRef ref, AppSettings settings, AppLocalizations l10n) {
    return Card(
      elevation: 4,
      color: AppColors.surfaceCards,
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
                color: AppColors.textPrimary,
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
            ),
            Divider(color: AppColors.dividerSeparator),
            _buildSettingItem(
              context,
              l10n.theme,
              _getThemeName(settings.theme, l10n),
              Icons.brightness_6,
              () {
                _showThemeSelectionDialog(context, ref, l10n);
              },
            ),
            Divider(color: AppColors.dividerSeparator),
            _buildSettingItem(
              context,
              l10n.currency,
              settings.currency,
              Icons.attach_money,
              () {
                _showCurrencySelectionDialog(context, ref, l10n);
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSecuritySection(BuildContext context, AppLocalizations l10n) {
    return Card(
      elevation: 4,
      color: AppColors.surfaceCards,
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
                color: AppColors.textPrimary,
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
            ),
            Divider(color: AppColors.dividerSeparator),
            _buildSettingItem(
              context,
              l10n.twoFactorAuth,
              l10n.disabled,
              Icons.security,
              () {
                context.push('/two-factor-auth');
              },
            ),
            Divider(color: AppColors.dividerSeparator),
            _buildSettingItem(
              context,
              l10n.privacySettings,
              '',
              Icons.privacy_tip,
              () {
                context.push('/privacy-settings');
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNotificationsSection(BuildContext context, WidgetRef ref, AppSettings settings, AppLocalizations l10n) {
    return Card(
      elevation: 4,
      color: AppColors.surfaceCards,
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
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 16),
            SwitchListTile(
              title: Text(l10n.emailNotifications, style: TextStyle(color: AppColors.textPrimary)),
              subtitle: Text(l10n.receiveUpdatesEmail, style: TextStyle(color: AppColors.textSecondary)),
              value: settings.emailNotifications,
              onChanged: (value) {
                ref.read(settingsProvider.notifier).updateEmailNotifications(value);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('${l10n.emailNotifications} ${value ? l10n.enabled : l10n.disabled}')),
                );
              },
              secondary: Icon(Icons.email, color: AppColors.primaryAccent),
            ),
            Divider(color: AppColors.dividerSeparator),
            SwitchListTile(
              title: Text(l10n.pushNotifications, style: TextStyle(color: AppColors.textPrimary)),
              subtitle: Text(l10n.pushNotificationSubtitle, style: TextStyle(color: AppColors.textSecondary)),
              value: settings.pushNotifications,
              onChanged: (value) {
                ref.read(settingsProvider.notifier).updatePushNotifications(value);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('${l10n.pushNotifications} ${value ? l10n.enabled : l10n.disabled}')),
                );
              },
              secondary: Icon(Icons.notifications, color: AppColors.primaryAccent),
            ),
            Divider(color: AppColors.dividerSeparator),
            SwitchListTile(
              title: Text(l10n.paymentReminders, style: TextStyle(color: AppColors.textPrimary)),
              subtitle: Text(l10n.paymentReminderSubtitle, style: TextStyle(color: AppColors.textSecondary)),
              value: settings.paymentReminders,
              onChanged: (value) {
                ref.read(settingsProvider.notifier).updatePaymentReminders(value);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('${l10n.paymentReminders} ${value ? l10n.enabled : l10n.disabled}')),
                );
              },
              secondary: Icon(Icons.payment, color: AppColors.primaryAccent),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSupportSection(BuildContext context, AppLocalizations l10n) {
    return Card(
      elevation: 4,
      color: AppColors.surfaceCards,
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
                color: AppColors.textPrimary,
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
            ),
            Divider(color: AppColors.dividerSeparator),
            _buildSettingItem(
              context,
              l10n.contactSupport,
              '',
              Icons.support_agent,
              () {
                context.push('/contact-support');
              },
            ),
            Divider(color: AppColors.dividerSeparator),
            _buildSettingItem(
              context,
              l10n.termsOfService,
              '',
              Icons.description,
              () {
                context.push('/terms-of-service');
              },
            ),
            Divider(color: AppColors.dividerSeparator),
            _buildSettingItem(
              context,
              l10n.privacyPolicy,
              '',
              Icons.policy,
              () {
                context.push('/privacy-policy');
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLogoutButton(BuildContext context, WidgetRef ref, AppLocalizations l10n) {
    return ElevatedButton(
      onPressed: () {
        ref.read(authProvider.notifier).logout();
        context.go('/login');
      },
      style: ElevatedButton.styleFrom(
        backgroundColor: AppColors.error,
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
          color: AppColors.textOnAccent,
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
  ) {
    return ListTile(
      leading: Icon(icon, color: AppColors.primaryAccent),
      title: Text(title, style: TextStyle(color: AppColors.textPrimary)),
      subtitle: subtitle.isNotEmpty ? Text(subtitle, style: TextStyle(color: AppColors.textSecondary)) : null,
      trailing: Icon(Icons.chevron_right, color: AppColors.textTertiary),
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
  void _showLanguageSelectionDialog(BuildContext context, WidgetRef ref, AppLocalizations l10n) {
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
        backgroundColor: AppColors.surfaceCards,
        title: Text(l10n.selectLanguage, style: TextStyle(color: AppColors.textPrimary)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: languages.entries.map((entry) => ListTile(
            title: Text(entry.key, style: TextStyle(color: AppColors.textPrimary)),
            onTap: () async {
              await settingsNotifier.updateLanguage(entry.value);
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text(l10n.languageChangedTo(entry.key))),
                );
                Navigator.pop(context);
              }
            },
          )).toList(),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(l10n.cancel, style: TextStyle(color: AppColors.primaryAccent)),
          ),
        ],
      ),
    );
  }  void _showThemeSelectionDialog(BuildContext context, WidgetRef ref, AppLocalizations l10n) {
    final themes = {
      l10n.light: 'light', 
      l10n.dark: 'dark', 
      l10n.system: 'system'
    };
    final settingsNotifier = ref.read(settingsProvider.notifier);
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.surfaceCards,
        title: Text(l10n.selectTheme, style: TextStyle(color: AppColors.textPrimary)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: themes.entries.map((entry) => ListTile(
            title: Text(entry.key, style: TextStyle(color: AppColors.textPrimary)),
            trailing: Icon(
              entry.value == 'light' ? Icons.light_mode :
              entry.value == 'dark' ? Icons.dark_mode : Icons.brightness_auto,
              color: AppColors.primaryAccent,
            ),
            onTap: () async {
              await settingsNotifier.updateTheme(entry.value);
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text(l10n.themeChangedTo(entry.key))),
                );
                Navigator.pop(context);
              }
            },
          )).toList(),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(l10n.cancel, style: TextStyle(color: AppColors.primaryAccent)),
          ),
        ],
      ),
    );
  }
  void _showCurrencySelectionDialog(BuildContext context, WidgetRef ref, AppLocalizations l10n) {
    final currencies = ['CHF', 'EUR', 'USD', 'GBP'];
    final settingsNotifier = ref.read(settingsProvider.notifier);
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.surfaceCards,
        title: Text(l10n.selectCurrency, style: TextStyle(color: AppColors.textPrimary)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: currencies.map((currency) => ListTile(
            title: Text(currency, style: TextStyle(color: AppColors.textPrimary)),
            onTap: () async {
              await settingsNotifier.updateCurrency(currency);
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text(l10n.currencyChangedTo(currency))),
                );
                Navigator.pop(context);
              }
            },
          )).toList(),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(l10n.cancel, style: TextStyle(color: AppColors.primaryAccent)),
          ),
        ],
      ),
    );
  }
}
