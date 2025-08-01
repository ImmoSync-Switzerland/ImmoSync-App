import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import '../../../../core/theme/app_colors.dart';

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
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      backgroundColor: AppColors.primaryBackground,
      appBar: AppBar(
        backgroundColor: AppColors.primaryBackground,
        elevation: 0,
        title: Text(
          'Privacy Settings',
          style: TextStyle(
            color: AppColors.textPrimary,
            fontSize: 18,
            fontWeight: FontWeight.w600,
          ),
        ),
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios, color: AppColors.textPrimary),
          onPressed: () => context.pop(),
        ),
      ),
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
            _buildProfileVisibilitySection(context, ref, privacySettings),
            const SizedBox(height: 24),
            _buildDataSharingSection(context, ref, privacySettings),
            const SizedBox(height: 24),
            _buildMarketingSection(context, ref, privacySettings),
            const SizedBox(height: 24),
            _buildDataManagementSection(context, ref, privacySettings),
          ],
        ),
      ),
    );
  }

  Widget _buildProfileVisibilitySection(BuildContext context, WidgetRef ref, PrivacySettings settings) {
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
            Row(
              children: [
                Icon(Icons.visibility, color: AppColors.primaryAccent),
                const SizedBox(width: 12),
                Text(
                  'Profile Visibility',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Text(
              'Control who can see your profile information and how you appear to other users.',
              style: TextStyle(
                fontSize: 14,
                color: AppColors.textSecondary,
              ),
            ),
            const SizedBox(height: 16),
            SwitchListTile(
              title: Text('Show Profile to Other Users', style: TextStyle(color: AppColors.textPrimary)),
              subtitle: Text('Allow other users to view your basic profile information', style: TextStyle(color: AppColors.textSecondary)),
              value: settings.showProfile,
              onChanged: (value) {
                ref.read(privacySettingsProvider.notifier).updateShowProfile(value);
              },
              secondary: Icon(Icons.person, color: AppColors.primaryAccent),
              activeColor: AppColors.primaryAccent,
            ),
            Divider(color: AppColors.dividerSeparator),
            SwitchListTile(
              title: Text('Show Contact Information', style: TextStyle(color: AppColors.textPrimary)),
              subtitle: Text('Display your email and phone number to connected users', style: TextStyle(color: AppColors.textSecondary)),
              value: settings.showContactInfo,
              onChanged: (value) {
                ref.read(privacySettingsProvider.notifier).updateShowContactInfo(value);
              },
              secondary: Icon(Icons.contact_mail, color: AppColors.primaryAccent),
              activeColor: AppColors.primaryAccent,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDataSharingSection(BuildContext context, WidgetRef ref, PrivacySettings settings) {
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
            Row(
              children: [
                Icon(Icons.share, color: AppColors.primaryAccent),
                const SizedBox(width: 12),
                Text(
                  'Data Sharing',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Text(
              'Choose how your data is used to improve ImmoLink services.',
              style: TextStyle(
                fontSize: 14,
                color: AppColors.textSecondary,
              ),
            ),
            const SizedBox(height: 16),
            SwitchListTile(
              title: Text('Allow Property Search', style: TextStyle(color: AppColors.textPrimary)),
              subtitle: Text('Let other users find your properties in search results', style: TextStyle(color: AppColors.textSecondary)),
              value: settings.allowPropertySearch,
              onChanged: (value) {
                ref.read(privacySettingsProvider.notifier).updateAllowPropertySearch(value);
              },
              secondary: Icon(Icons.search, color: AppColors.primaryAccent),
              activeColor: AppColors.primaryAccent,
            ),
            Divider(color: AppColors.dividerSeparator),
            SwitchListTile(
              title: Text('Share Usage Analytics', style: TextStyle(color: AppColors.textPrimary)),
              subtitle: Text('Help improve ImmoLink by sharing anonymous usage data', style: TextStyle(color: AppColors.textSecondary)),
              value: settings.shareAnalytics,
              onChanged: (value) {
                ref.read(privacySettingsProvider.notifier).updateShareAnalytics(value);
              },
              secondary: Icon(Icons.analytics, color: AppColors.primaryAccent),
              activeColor: AppColors.primaryAccent,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMarketingSection(BuildContext context, WidgetRef ref, PrivacySettings settings) {
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
            Row(
              children: [
                Icon(Icons.campaign, color: AppColors.primaryAccent),
                const SizedBox(width: 12),
                Text(
                  'Marketing & Communications',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Text(
              'Control how we communicate with you about new features and offers.',
              style: TextStyle(
                fontSize: 14,
                color: AppColors.textSecondary,
              ),
            ),
            const SizedBox(height: 16),
            SwitchListTile(
              title: Text('Receive Marketing Emails', style: TextStyle(color: AppColors.textPrimary)),
              subtitle: Text('Get updates about new features, tips, and special offers', style: TextStyle(color: AppColors.textSecondary)),
              value: settings.receiveMarketing,
              onChanged: (value) {
                ref.read(privacySettingsProvider.notifier).updateReceiveMarketing(value);
              },
              secondary: Icon(Icons.email, color: AppColors.primaryAccent),
              activeColor: AppColors.primaryAccent,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDataManagementSection(BuildContext context, WidgetRef ref, PrivacySettings settings) {
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
            Row(
              children: [
                Icon(Icons.folder_outlined, color: AppColors.primaryAccent),
                const SizedBox(width: 12),
                Text(
                  'Data Management',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Text(
              'Manage your personal data and export your information.',
              style: TextStyle(
                fontSize: 14,
                color: AppColors.textSecondary,
              ),
            ),
            const SizedBox(height: 16),
            ListTile(
              leading: Icon(Icons.download, color: AppColors.primaryAccent),
              title: Text('Export My Data', style: TextStyle(color: AppColors.textPrimary)),
              subtitle: Text('Download a copy of your personal data', style: TextStyle(color: AppColors.textSecondary)),
              trailing: Icon(Icons.chevron_right, color: AppColors.textTertiary),
              onTap: () {
                _showDataExportDialog(context);
              },
            ),
            Divider(color: AppColors.dividerSeparator),
            ListTile(
              leading: Icon(Icons.delete_forever, color: AppColors.error),
              title: Text('Delete Account', style: TextStyle(color: AppColors.error)),
              subtitle: Text('Permanently delete your account and all data', style: TextStyle(color: AppColors.textSecondary)),
              trailing: Icon(Icons.chevron_right, color: AppColors.textTertiary),
              onTap: () {
                _showDeleteAccountDialog(context);
              },
            ),
          ],
        ),
      ),
    );
  }

  void _showDataExportDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.surfaceCards,
        title: Text('Export Your Data', style: TextStyle(color: AppColors.textPrimary)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'We will prepare a download link with all your personal data including:',
              style: TextStyle(color: AppColors.textPrimary),
            ),
            const SizedBox(height: 16),
            ...['Profile information', 'Property data', 'Messages and conversations', 'Payment history', 'Settings and preferences'].map(
              (item) => Padding(
                padding: const EdgeInsets.symmetric(vertical: 4),
                child: Row(
                  children: [
                    Icon(Icons.check, color: AppColors.primaryAccent, size: 16),
                    const SizedBox(width: 8),
                    Text(item, style: TextStyle(color: AppColors.textSecondary)),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'The export process may take up to 24 hours. You will receive an email with the download link.',
              style: TextStyle(color: AppColors.textSecondary, fontSize: 12),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Cancel', style: TextStyle(color: AppColors.textSecondary)),
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
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.primaryAccent),
            child: Text('Request Export', style: TextStyle(color: AppColors.textOnAccent)),
          ),
        ],
      ),
    );
  }

  void _showDeleteAccountDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.surfaceCards,
        title: Text('Delete Account', style: TextStyle(color: AppColors.error)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Are you sure you want to delete your account?',
              style: TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 16),
            Text(
              'This action will permanently delete:',
              style: TextStyle(color: AppColors.textPrimary),
            ),
            const SizedBox(height: 8),
            ...['Your profile and all personal data', 'All properties and property data', 'Messages and conversations', 'Payment history', 'All uploaded documents and images'].map(
              (item) => Padding(
                padding: const EdgeInsets.symmetric(vertical: 4),
                child: Row(
                  children: [
                    Icon(Icons.warning, color: AppColors.error, size: 16),
                    const SizedBox(width: 8),
                    Expanded(child: Text(item, style: TextStyle(color: AppColors.textSecondary))),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.error.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                'This action cannot be undone. Please export your data first if you want to keep a copy.',
                style: TextStyle(color: AppColors.error, fontSize: 12),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Cancel', style: TextStyle(color: AppColors.textSecondary)),
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
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.error),
            child: Text('Delete Account', style: TextStyle(color: AppColors.textOnAccent)),
          ),
        ],
      ),
    );
  }
}