import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import '../../../../core/providers/dynamic_colors_provider.dart';

class HelpCenterPage extends ConsumerWidget {
  const HelpCenterPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final colors = ref.watch(dynamicColorsProvider);
    
    return Scaffold(
      backgroundColor: colors.primaryBackground,
      appBar: AppBar(
        backgroundColor: colors.primaryBackground,
        elevation: 0,
        title: Text(
          l10n.helpCenter,
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
            _buildWelcomeCard(l10n, colors),
            const SizedBox(height: 24),
            _buildQuickLinksSection(context, l10n, colors, ref),
            const SizedBox(height: 24),
            _buildFAQSection(context, l10n, colors),
            const SizedBox(height: 24),
            _buildGuidesSection(context, l10n, colors, ref),
            const SizedBox(height: 24),
            _buildContactSection(context, l10n, colors),
          ],
        ),
      ),
    );
  }

  Widget _buildWelcomeCard(AppLocalizations l10n, DynamicAppColors colors) {
    return Card(
      elevation: 4,
      color: colors.surfaceCards,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              colors.primaryAccent.withValues(alpha: 0.1),
              colors.accentLight.withValues(alpha: 0.1),
            ],
          ),
        ),
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.help_outline,
                  color: colors.primaryAccent,
                  size: 28,
                ),
                const SizedBox(width: 12),
                Text(
                  l10n.welcomeToHelpCenter,
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: colors.textPrimary,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Text(
              l10n.helpCenterDescription,
              style: TextStyle(
                fontSize: 16,
                color: colors.textSecondary,
                height: 1.5,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildQuickLinksSection(BuildContext context, AppLocalizations l10n, DynamicAppColors colors, WidgetRef ref) {
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
              l10n.quickLinks,
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: colors.textPrimary,
              ),
            ),
            const SizedBox(height: 16),
            _buildQuickLinkItem(
              context,
              l10n.gettingStarted,
              l10n.gettingStartedDescription,
              Icons.play_circle_outline,
              () => _showGettingStartedDialog(context, l10n, ref),
              colors,
            ),
            _buildQuickLinkItem(
              context,
              l10n.accountSettings,
              l10n.accountSettingsDescription,
              Icons.settings,
              () => context.push('/settings'),
              colors,
            ),
            _buildQuickLinkItem(
              context,
              l10n.propertyManagement,
              l10n.propertyManagementDescription,
              Icons.home,
              () => _showPropertyManagementDialog(context, l10n, ref),
              colors,
            ),
            _buildQuickLinkItem(
              context,
              l10n.paymentsBilling,
              l10n.paymentsBillingDescription,
              Icons.payment,
              () => _showPaymentsDialog(context, l10n, ref),
              colors,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildQuickLinkItem(BuildContext context, String title, String subtitle, IconData icon, VoidCallback onTap, DynamicAppColors colors) {
    return ListTile(
      leading: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: colors.primaryAccent.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(icon, color: colors.primaryAccent),
      ),
      title: Text(title, style: TextStyle(color: colors.textPrimary, fontWeight: FontWeight.w600)),
      subtitle: Text(subtitle, style: TextStyle(color: colors.textSecondary)),
      trailing: Icon(Icons.chevron_right, color: colors.textTertiary),
      onTap: onTap,
    );
  }

  Widget _buildFAQSection(BuildContext context, AppLocalizations l10n, DynamicAppColors colors) {
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
              l10n.frequentlyAskedQuestions,
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: colors.textPrimary,
              ),
            ),
            const SizedBox(height: 16),
            _buildFAQItem(
              l10n.howToAddProperty,
              l10n.howToAddPropertyAnswer,
              colors,
            ),
            _buildFAQItem(
              l10n.howToInviteTenant,
              l10n.howToInviteTenantAnswer,
              colors,
            ),
            _buildFAQItem(
              l10n.howToChangeCurrency,
              l10n.howToChangeCurrencyAnswer,
              colors,
            ),
            _buildFAQItem(
              l10n.howToEnable2FA,
              l10n.howToEnable2FAAnswer,
              colors,
            ),
            _buildFAQItem(
              l10n.howToExportData,
              l10n.howToExportDataAnswer,
              colors,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFAQItem(String question, String answer, DynamicAppColors colors) {
    return ExpansionTile(
      title: Text(
        question,
        style: TextStyle(
          color: colors.textPrimary,
          fontWeight: FontWeight.w600,
        ),
      ),
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
          child: Text(
            answer,
            style: TextStyle(
              color: colors.textSecondary,
              height: 1.5,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildGuidesSection(BuildContext context, AppLocalizations l10n, DynamicAppColors colors, WidgetRef ref) {
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
              l10n.userGuides,
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: colors.textPrimary,
              ),
            ),
            const SizedBox(height: 16),
            _buildGuideItem(
              l10n.landlordGuide,
              l10n.landlordGuideDescription,
              Icons.business,
              () => _showLandlordGuideDialog(context, l10n, ref),
              colors,
            ),
            _buildGuideItem(
              l10n.tenantGuide,
              l10n.tenantGuideDescription,
              Icons.person,
              () => _showTenantGuideDialog(context, l10n, ref),
              colors,
            ),
            _buildGuideItem(
              l10n.securityBestPractices,
              l10n.securityBestPracticesDescription,
              Icons.security,
              () => _showSecurityGuideDialog(context, l10n, ref),
              colors,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildGuideItem(String title, String subtitle, IconData icon, VoidCallback onTap, DynamicAppColors colors) {
    return ListTile(
      leading: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: colors.accentLight.withValues(alpha: 0.2),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(icon, color: colors.primaryAccent),
      ),
      title: Text(title, style: TextStyle(color: colors.textPrimary, fontWeight: FontWeight.w600)),
      subtitle: Text(subtitle, style: TextStyle(color: colors.textSecondary)),
      trailing: Icon(Icons.chevron_right, color: colors.textTertiary),
      onTap: onTap,
    );
  }

  Widget _buildContactSection(BuildContext context, AppLocalizations l10n, DynamicAppColors colors) {
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
              l10n.needMoreHelp,
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: colors.textPrimary,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              l10n.needMoreHelpDescription,
              style: TextStyle(
                fontSize: 14,
                color: colors.textSecondary,
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () => context.push('/contact-support'),
                    icon: Icon(Icons.support_agent, color: colors.textOnAccent),
                    label: Text(l10n.contactSupport, style: TextStyle(color: colors.textOnAccent)),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: colors.primaryAccent,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _showGettingStartedDialog(BuildContext context, AppLocalizations l10n, WidgetRef ref) {
    final colors = ref.read(dynamicColorsProvider);
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: colors.surfaceCards,
        title: Text(l10n.gettingStarted, style: TextStyle(color: colors.textPrimary)),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(l10n.gettingStartedWelcome, style: TextStyle(color: colors.textPrimary)),
              const SizedBox(height: 16),
              ...[l10n.gettingStartedStep1, l10n.gettingStartedStep2, l10n.gettingStartedStep3, l10n.gettingStartedStep4].map(
                (step) => Padding(
                  padding: const EdgeInsets.symmetric(vertical: 4),
                  child: Text(step, style: TextStyle(color: colors.textSecondary)),
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(l10n.gotIt, style: TextStyle(color: colors.primaryAccent)),
          ),
        ],
      ),
    );
  }

  void _showPropertyManagementDialog(BuildContext context, AppLocalizations l10n, WidgetRef ref) {
    final colors = ref.read(dynamicColorsProvider);
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: colors.surfaceCards,
        title: Text(l10n.propertyManagement, style: TextStyle(color: colors.textPrimary)),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(l10n.propertyManagementGuide, style: TextStyle(color: colors.textPrimary)),
              const SizedBox(height: 16),
              ...[l10n.propertyManagementTip1, l10n.propertyManagementTip2, l10n.propertyManagementTip3, l10n.propertyManagementTip4, l10n.propertyManagementTip5].map(
                (tip) => Padding(
                  padding: const EdgeInsets.symmetric(vertical: 4),
                  child: Text(tip, style: TextStyle(color: colors.textSecondary)),
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(l10n.gotIt, style: TextStyle(color: colors.primaryAccent)),
          ),
        ],
      ),
    );
  }

  void _showPaymentsDialog(BuildContext context, AppLocalizations l10n, WidgetRef ref) {
    final colors = ref.read(dynamicColorsProvider);
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: colors.surfaceCards,
        title: Text(l10n.paymentsBilling, style: TextStyle(color: colors.textPrimary)),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(l10n.paymentsGuide, style: TextStyle(color: colors.textPrimary)),
              const SizedBox(height: 16),
              ...[l10n.paymentsTip1, l10n.paymentsTip2, l10n.paymentsTip3, l10n.paymentsTip4, l10n.paymentsTip5].map(
                (tip) => Padding(
                  padding: const EdgeInsets.symmetric(vertical: 4),
                  child: Text(tip, style: TextStyle(color: colors.textSecondary)),
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(l10n.gotIt, style: TextStyle(color: colors.primaryAccent)),
          ),
        ],
      ),
    );
  }

  void _showLandlordGuideDialog(BuildContext context, AppLocalizations l10n, WidgetRef ref) {
    final colors = ref.read(dynamicColorsProvider);
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: colors.surfaceCards,
        title: Text(l10n.landlordGuide, style: TextStyle(color: colors.textPrimary)),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(l10n.landlordGuideContent, style: TextStyle(color: colors.textPrimary)),
              const SizedBox(height: 16),
              ...[l10n.landlordTip1, l10n.landlordTip2, l10n.landlordTip3, l10n.landlordTip4, l10n.landlordTip5, l10n.landlordTip6].map(
                (tip) => Padding(
                  padding: const EdgeInsets.symmetric(vertical: 4),
                  child: Text(tip, style: TextStyle(color: colors.textSecondary)),
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(l10n.gotIt, style: TextStyle(color: colors.primaryAccent)),
          ),
        ],
      ),
    );
  }

  void _showTenantGuideDialog(BuildContext context, AppLocalizations l10n, WidgetRef ref) {
    final colors = ref.read(dynamicColorsProvider);
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: colors.surfaceCards,
        title: Text(l10n.tenantGuide, style: TextStyle(color: colors.textPrimary)),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(l10n.tenantGuideContent, style: TextStyle(color: colors.textPrimary)),
              const SizedBox(height: 16),
              ...[l10n.tenantTip1, l10n.tenantTip2, l10n.tenantTip3, l10n.tenantTip4, l10n.tenantTip5, l10n.tenantTip6].map(
                (tip) => Padding(
                  padding: const EdgeInsets.symmetric(vertical: 4),
                  child: Text(tip, style: TextStyle(color: colors.textSecondary)),
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(l10n.gotIt, style: TextStyle(color: colors.primaryAccent)),
          ),
        ],
      ),
    );
  }

  void _showSecurityGuideDialog(BuildContext context, AppLocalizations l10n, WidgetRef ref) {
    final colors = ref.read(dynamicColorsProvider);
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: colors.surfaceCards,
        title: Text(l10n.securityBestPractices, style: TextStyle(color: colors.textPrimary)),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(l10n.securityGuideContent, style: TextStyle(color: colors.textPrimary)),
              const SizedBox(height: 16),
              ...[l10n.securityTip1, l10n.securityTip2, l10n.securityTip3, l10n.securityTip4, l10n.securityTip5, l10n.securityTip6].map(
                (tip) => Padding(
                  padding: const EdgeInsets.symmetric(vertical: 4),
                  child: Text(tip, style: TextStyle(color: colors.textSecondary)),
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(l10n.gotIt, style: TextStyle(color: colors.primaryAccent)),
          ),
        ],
      ),
    );
  }
}

