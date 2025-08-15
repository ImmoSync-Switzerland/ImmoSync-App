import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/providers/dynamic_colors_provider.dart';

// Privacy settings state
class PrivacySettings {
  final bool showProfile;
  final bool showContactInfo;
  final bool allowPropertySearch;
  final bool shareAnalytics;
  final bool receiveMarketing;
  final bool dataExport;

  const PrivacySettings({
    this.showProfile = true,
    this.showContactInfo = false,
    this.allowPropertySearch = true,
    this.shareAnalytics = true,
    this.receiveMarketing = false,
    this.dataExport = false,
  });

  PrivacySettings copyWith({
    bool? showProfile,
    bool? showContactInfo,
    bool? allowPropertySearch,
    bool? shareAnalytics,
    bool? receiveMarketing,
    bool? dataExport,
  }) {
    return PrivacySettings(
      showProfile: showProfile ?? this.showProfile,
      showContactInfo: showContactInfo ?? this.showContactInfo,
      allowPropertySearch: allowPropertySearch ?? this.allowPropertySearch,
      shareAnalytics: shareAnalytics ?? this.shareAnalytics,
      receiveMarketing: receiveMarketing ?? this.receiveMarketing,
      dataExport: dataExport ?? this.dataExport,
    );
  }
}

// Privacy settings notifier
class PrivacySettingsNotifier extends StateNotifier<PrivacySettings> {
  PrivacySettingsNotifier() : super(const PrivacySettings());

  void updateShowProfile(bool value) {
    state = state.copyWith(showProfile: value);
  }

  void updateShowContactInfo(bool value) {
    state = state.copyWith(showContactInfo: value);
  }

  void updateAllowPropertySearch(bool value) {
    state = state.copyWith(allowPropertySearch: value);
  }

  void updateShareAnalytics(bool value) {
    state = state.copyWith(shareAnalytics: value);
  }

  void updateReceiveMarketing(bool value) {
    state = state.copyWith(receiveMarketing: value);
  }

  void updateDataExport(bool value) {
    state = state.copyWith(dataExport: value);
  }
}

// Provider
final privacySettingsProvider = StateNotifierProvider<PrivacySettingsNotifier, PrivacySettings>((ref) {
  return PrivacySettingsNotifier();
});

class PrivacySettingsPage extends ConsumerWidget {
  const PrivacySettingsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final privacySettings = ref.watch(privacySettingsProvider);
    final colors = ref.watch(dynamicColorsProvider);
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      backgroundColor: colors.primaryBackground,
      appBar: AppBar(
        backgroundColor: colors.primaryBackground,
        elevation: 0,
        title: Text(
          'Privacy Settings',
          style: TextStyle(
            color: colors.textPrimary,
            fontSize: 18,
            fontWeight: FontWeight.w600,
          ),
        ),
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios, color: colors.textPrimary),
          onPressed: () => context.pop(),
        ),
      ),
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
            _buildProfileVisibilitySection(context, ref, privacySettings, colors),
            const SizedBox(height: 24),
            _buildDataSharingSection(context, ref, privacySettings, colors),
            const SizedBox(height: 24),
            _buildMarketingSection(context, ref, privacySettings, colors),
            const SizedBox(height: 24),
            _buildDataManagementSection(context, ref, privacySettings, colors),
          ],
        ),
      ),
    );
  }

  Widget _buildProfileVisibilitySection(BuildContext context, WidgetRef ref, PrivacySettings settings, DynamicAppColors colors) {
    final l10n = AppLocalizations.of(context)!;
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
                Icon(Icons.visibility, color: colors.primaryAccent),
                const SizedBox(width: 12),
                Text(
                  l10n.publicProfile,
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: colors.textPrimary,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Text(
              'Kontrollieren Sie, wer Ihre Profilinformationen sehen kann und wie Sie anderen Benutzern angezeigt werden.',
              style: TextStyle(
                fontSize: 14,
                color: colors.textSecondary,
              ),
            ),
            const SizedBox(height: 16),
            SwitchListTile(
              title: Text('Profil anderen Benutzern zeigen', style: TextStyle(color: colors.textPrimary)),
              subtitle: Text(l10n.allowOtherUsersViewProfile, style: TextStyle(color: colors.textSecondary)),
              value: settings.showProfile,
              onChanged: (value) {
                ref.read(privacySettingsProvider.notifier).updateShowProfile(value);
              },
              secondary: Icon(Icons.person, color: colors.primaryAccent),
              activeColor: colors.primaryAccent,
            ),
            Divider(color: colors.dividerSeparator),
            SwitchListTile(
              title: Text('Kontaktinformationen anzeigen', style: TextStyle(color: colors.textPrimary)),
              subtitle: Text('E-Mail und Telefonnummer für verbundene Benutzer anzeigen', style: TextStyle(color: colors.textSecondary)),
              value: settings.showContactInfo,
              onChanged: (value) {
                ref.read(privacySettingsProvider.notifier).updateShowContactInfo(value);
              },
              secondary: Icon(Icons.contact_mail, color: colors.primaryAccent),
              activeColor: colors.primaryAccent,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDataSharingSection(BuildContext context, WidgetRef ref, PrivacySettings settings, DynamicAppColors colors) {
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
                Icon(Icons.share, color: colors.primaryAccent),
                const SizedBox(width: 12),
                Text(
                  'Data Sharing',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: colors.textPrimary,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Text(
              'Choose how your data is used to improve ImmoLink services.',
              style: TextStyle(
                fontSize: 14,
                color: colors.textSecondary,
              ),
            ),
            const SizedBox(height: 16),
            SwitchListTile(
              title: Text('Allow Property Search', style: TextStyle(color: colors.textPrimary)),
              subtitle: Text('Let other users find your properties in search results', style: TextStyle(color: colors.textSecondary)),
              value: settings.allowPropertySearch,
              onChanged: (value) {
                ref.read(privacySettingsProvider.notifier).updateAllowPropertySearch(value);
              },
              secondary: Icon(Icons.search, color: colors.primaryAccent),
              activeColor: colors.primaryAccent,
            ),
            Divider(color: colors.dividerSeparator),
            SwitchListTile(
              title: Text('Share Usage Analytics', style: TextStyle(color: colors.textPrimary)),
              subtitle: Text('Help improve ImmoLink by sharing anonymous usage data', style: TextStyle(color: colors.textSecondary)),
              value: settings.shareAnalytics,
              onChanged: (value) {
                ref.read(privacySettingsProvider.notifier).updateShareAnalytics(value);
              },
              secondary: Icon(Icons.analytics, color: colors.primaryAccent),
              activeColor: colors.primaryAccent,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMarketingSection(BuildContext context, WidgetRef ref, PrivacySettings settings, DynamicAppColors colors) {
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
                Icon(Icons.campaign, color: colors.primaryAccent),
                const SizedBox(width: 12),
                Text(
                  'Marketing & Communications',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: colors.textPrimary,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Text(
              'Control how we communicate with you about new features and offers.',
              style: TextStyle(
                fontSize: 14,
                color: colors.textSecondary,
              ),
            ),
            const SizedBox(height: 16),
            SwitchListTile(
              title: Text('Receive Marketing Emails', style: TextStyle(color: colors.textPrimary)),
              subtitle: Text('Get updates about new features, tips, and special offers', style: TextStyle(color: colors.textSecondary)),
              value: settings.receiveMarketing,
              onChanged: (value) {
                ref.read(privacySettingsProvider.notifier).updateReceiveMarketing(value);
              },
              secondary: Icon(Icons.email, color: colors.primaryAccent),
              activeColor: colors.primaryAccent,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDataManagementSection(BuildContext context, WidgetRef ref, PrivacySettings settings, DynamicAppColors colors) {
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
                Icon(Icons.folder_outlined, color: colors.primaryAccent),
                const SizedBox(width: 12),
                Text(
                  'Data Management',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: colors.textPrimary,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Text(
              'Manage your personal data and export your information.',
              style: TextStyle(
                fontSize: 14,
                color: colors.textSecondary,
              ),
            ),
            const SizedBox(height: 16),
            ListTile(
              leading: Icon(Icons.download, color: colors.primaryAccent),
              title: Text('Export My Data', style: TextStyle(color: colors.textPrimary)),
              subtitle: Text('Download a copy of your personal data', style: TextStyle(color: colors.textSecondary)),
              trailing: Icon(Icons.chevron_right, color: colors.textTertiary),
              onTap: () {
                _showDataExportDialog(context, ref);
              },
            ),
            Divider(color: colors.dividerSeparator),
            ListTile(
              leading: Icon(Icons.delete_forever, color: colors.error),
              title: Text('Delete Account', style: TextStyle(color: colors.error)),
              subtitle: Text('Permanently delete your account and all data', style: TextStyle(color: colors.textSecondary)),
              trailing: Icon(Icons.chevron_right, color: colors.textTertiary),
              onTap: () {
                _showDeleteAccountDialog(context, ref);
              },
            ),
          ],
        ),
      ),
    );
  }

  void _showDataExportDialog(BuildContext context, WidgetRef ref) {
    final colors = ref.read(dynamicColorsProvider);
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: colors.surfaceCards,
        title: Text('Export Your Data', style: TextStyle(color: colors.textPrimary)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'We will prepare a download link with all your personal data including:',
              style: TextStyle(color: colors.textPrimary),
            ),
            const SizedBox(height: 16),
            ...['Profile information', 'Property data', 'Messages and conversations', 'Payment history', 'Settings and preferences'].map(
              (item) => Padding(
                padding: const EdgeInsets.symmetric(vertical: 4),
                child: Row(
                  children: [
                    Icon(Icons.check, color: colors.primaryAccent, size: 16),
                    const SizedBox(width: 8),
                    Text(item, style: TextStyle(color: colors.textSecondary)),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'The export process may take up to 24 hours. You will receive an email with the download link.',
              style: TextStyle(color: colors.textSecondary, fontSize: 12),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Cancel', style: TextStyle(color: colors.textSecondary)),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Data export request submitted. You will receive an email with the download link.'),
                ),
              );
            },
            style: ElevatedButton.styleFrom(backgroundColor: colors.primaryAccent),
            child: Text('Request Export', style: TextStyle(color: colors.textOnAccent)),
          ),
        ],
      ),
    );
  }

  void _showDeleteAccountDialog(BuildContext context, WidgetRef ref) {
    final colors = ref.read(dynamicColorsProvider);
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: colors.surfaceCards,
        title: Text('Delete Account', style: TextStyle(color: colors.error)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Are you sure you want to delete your account?',
              style: TextStyle(color: colors.textPrimary, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 16),
            Text(
              'This action will permanently delete:',
              style: TextStyle(color: colors.textPrimary),
            ),
            const SizedBox(height: 8),
            ...['Your profile and all personal data', 'All properties and property data', 'Messages and conversations', 'Payment history', 'All uploaded documents and images'].map(
              (item) => Padding(
                padding: const EdgeInsets.symmetric(vertical: 4),
                child: Row(
                  children: [
                    Icon(Icons.warning, color: colors.error, size: 16),
                    const SizedBox(width: 8),
                    Expanded(child: Text(item, style: TextStyle(color: colors.textSecondary))),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: colors.error.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                'This action cannot be undone. Please export your data first if you want to keep a copy.',
                style: TextStyle(color: colors.error, fontSize: 12),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Cancel', style: TextStyle(color: colors.textSecondary)),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Account deletion request submitted. This feature will be available soon.'),
                ),
              );
            },
            style: ElevatedButton.styleFrom(backgroundColor: colors.error),
            child: Text('Delete Account', style: TextStyle(color: colors.textOnAccent)),
          ),
        ],
      ),
    );
  }
}
