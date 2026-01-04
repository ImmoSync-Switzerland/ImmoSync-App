import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../../l10n/app_localizations.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/app_typography.dart';

const _bgTop = Color(0xFF0A1128);
const _bgBottom = Colors.black;
const _bentoCard = Color(0xFF1C1C1E);
const _primaryBlue = Color(0xFF3B82F6);
const _bentoBorderAlpha = 0.08;

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
final privacySettingsProvider =
    StateNotifierProvider<PrivacySettingsNotifier, PrivacySettings>((ref) {
  return PrivacySettingsNotifier();
});

class PrivacySettingsPage extends StatelessWidget {
  const PrivacySettingsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return const PrivacySettingsScreen();
  }
}

class PrivacySettingsScreen extends ConsumerWidget {
  const PrivacySettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(privacySettingsProvider);
    final l10n = AppLocalizations.of(context)!;
    final topInset = MediaQuery.of(context).padding.top + kToolbarHeight;

    return Scaffold(
      extendBodyBehindAppBar: true,
      extendBody: true,
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        systemOverlayStyle: const SystemUiOverlayStyle(
          statusBarColor: Colors.transparent,
          statusBarIconBrightness: Brightness.light,
          statusBarBrightness: Brightness.dark,
        ),
        surfaceTintColor: Colors.transparent,
        backgroundColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        flexibleSpace: const DecoratedBox(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [_bgTop, _bgBottom],
            ),
          ),
        ),
        title: Text(
          l10n.privacySettingsTitle,
          style: AppTypography.pageTitle.copyWith(color: Colors.white),
        ),
        leading: IconButton(
          icon:
              const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white),
          onPressed: () => context.pop(),
        ),
      ),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [_bgTop, _bgBottom],
          ),
        ),
        child: ListView(
          padding: EdgeInsets.fromLTRB(16, topInset + 16, 16, 120),
          children: [
            _bentoContainer(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _sectionHeader(
                      icon: Icons.visibility, title: 'Public Profile'),
                  const SizedBox(height: 12),
                  _toggleRow(
                    title: 'Show profile to others',
                    subtitle: 'Allow other users to view your profile.',
                    value: settings.showProfile,
                    onChanged: (value) => ref
                        .read(privacySettingsProvider.notifier)
                        .updateShowProfile(value),
                  ),
                  _divider(),
                  _toggleRow(
                    title: 'Show contact information',
                    subtitle: 'Display your contact details on your profile.',
                    value: settings.showContactInfo,
                    onChanged: (value) => ref
                        .read(privacySettingsProvider.notifier)
                        .updateShowContactInfo(value),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            _bentoContainer(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _sectionHeader(icon: Icons.share, title: 'Data Sharing'),
                  const SizedBox(height: 12),
                  _toggleRow(
                    title: 'Allow property search',
                    subtitle: 'Let properties be discoverable via search.',
                    value: settings.allowPropertySearch,
                    onChanged: (value) => ref
                        .read(privacySettingsProvider.notifier)
                        .updateAllowPropertySearch(value),
                  ),
                  _divider(),
                  _toggleRow(
                    title: 'Share usage analytics',
                    subtitle:
                        'Help improve the app by sharing anonymous usage data.',
                    value: settings.shareAnalytics,
                    onChanged: (value) => ref
                        .read(privacySettingsProvider.notifier)
                        .updateShareAnalytics(value),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            _bentoContainer(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _sectionHeader(
                    icon: Icons.campaign,
                    title: 'Marketing & Communications',
                  ),
                  const SizedBox(height: 12),
                  _toggleRow(
                    title: 'Receive marketing emails',
                    subtitle: 'Get product updates and promotional emails.',
                    value: settings.receiveMarketing,
                    onChanged: (value) => ref
                        .read(privacySettingsProvider.notifier)
                        .updateReceiveMarketing(value),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            _bentoContainer(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _sectionHeader(
                    icon: Icons.folder_outlined,
                    title: 'Data Management',
                  ),
                  const SizedBox(height: 12),
                  _actionRow(
                    title: 'Export my data',
                    subtitle: 'Download a copy of your account data.',
                    onTap: () => _showDataExportDialog(context, l10n),
                  ),
                  const SizedBox(height: 12),
                  Center(
                    child: TextButton(
                      onPressed: () => _showDeleteAccountDialog(context, l10n),
                      child: const Text(
                        'Delete Account',
                        style: TextStyle(
                          color: Colors.red,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _bentoContainer({required Widget child}) {
    return Container(
      decoration: BoxDecoration(
        color: _bentoCard,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: Colors.white.withValues(alpha: _bentoBorderAlpha),
          width: 1,
        ),
      ),
      padding: const EdgeInsets.all(16),
      child: child,
    );
  }

  // Overflow fix: Expanded + maxLines 2 + overflow visible to wrap instead of
  // causing a right overflow.
  Widget _sectionHeader({required IconData icon, required String title}) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, color: Colors.blue),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            title,
            maxLines: 2,
            overflow: TextOverflow.visible,
            softWrap: true,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
        ),
      ],
    );
  }

  Widget _toggleRow({
    required String title,
    required String subtitle,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  subtitle,
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Colors.white60,
                    fontSize: 12,
                    height: 1.25,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          Switch(
            value: value,
            onChanged: onChanged,
            activeThumbColor: Colors.blue,
            activeTrackColor: Colors.blue.withValues(alpha: 0.35),
            inactiveTrackColor: Colors.grey.withValues(alpha: 0.3),
          ),
        ],
      ),
    );
  }

  Widget _actionRow({
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 10),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    maxLines: 3,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: Colors.white60,
                      fontSize: 12,
                      height: 1.25,
                    ),
                  ),
                ],
              ),
            ),
            const Icon(Icons.chevron_right_rounded, color: Colors.white54),
          ],
        ),
      ),
    );
  }

  Widget _divider() {
    return Container(
      height: 1,
      color: Colors.white.withValues(alpha: 0.10),
    );
  }

  void _showDataExportDialog(BuildContext context, AppLocalizations l10n) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: _bentoCard,
        title: Text(
          l10n.privacyExportDialogTitle,
          style: const TextStyle(color: Colors.white),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              l10n.privacyExportDialogDescription,
              style: const TextStyle(color: Colors.white70),
            ),
            const SizedBox(height: 16),
            ...[
              l10n.privacyExportIncludesProfile,
              l10n.privacyExportIncludesProperty,
              l10n.privacyExportIncludesMessages,
              l10n.privacyExportIncludesPayments,
              l10n.privacyExportIncludesSettings,
            ].map(
              (item) => Padding(
                padding: const EdgeInsets.symmetric(vertical: 4),
                child: Row(
                  children: [
                    const Icon(Icons.check, color: _primaryBlue, size: 16),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        item,
                        style: const TextStyle(color: Colors.white70),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              l10n.privacyExportDialogNote,
              style: const TextStyle(color: Colors.white60, fontSize: 12),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              l10n.cancel,
              style: const TextStyle(color: Colors.white70),
            ),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text(l10n.privacyExportSuccess)),
              );
            },
            style: ElevatedButton.styleFrom(backgroundColor: _primaryBlue),
            child: Text(
              l10n.privacyExportButton,
              style: const TextStyle(color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }

  void _showDeleteAccountDialog(BuildContext context, AppLocalizations l10n) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: _bentoCard,
        title: Text(
          l10n.privacyDeleteDialogTitle,
          style: const TextStyle(color: Colors.redAccent),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              l10n.privacyDeleteDialogQuestion,
              style: const TextStyle(
                  color: Colors.white, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 16),
            Text(
              l10n.privacyDeleteDialogWarningTitle,
              style: const TextStyle(color: Colors.white70),
            ),
            const SizedBox(height: 8),
            ...[
              l10n.privacyDeleteDialogDeleteProfile,
              l10n.privacyDeleteDialogDeleteProperties,
              l10n.privacyDeleteDialogDeleteMessages,
              l10n.privacyDeleteDialogDeletePayments,
              l10n.privacyDeleteDialogDeleteDocuments,
            ].map(
              (item) => Padding(
                padding: const EdgeInsets.symmetric(vertical: 4),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Icon(Icons.warning,
                        color: Colors.redAccent, size: 16),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        item,
                        style: const TextStyle(color: Colors.white70),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.redAccent.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                l10n.privacyDeleteDialogIrreversible,
                style: const TextStyle(color: Colors.redAccent, fontSize: 12),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(l10n.cancel,
                style: const TextStyle(color: Colors.white70)),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text(l10n.privacyDeleteRequestSubmitted)),
              );
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.redAccent),
            child: Text(
              l10n.privacyDeleteButton,
              style: const TextStyle(color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }
}
