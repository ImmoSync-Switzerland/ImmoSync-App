import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../../core/theme/app_colors.dart';

class HelpCenterPage extends ConsumerWidget {
  const HelpCenterPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      backgroundColor: AppColors.primaryBackground,
      appBar: AppBar(
        backgroundColor: AppColors.primaryBackground,
        elevation: 0,
        title: Text(
          'Help Center',
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
            _buildWelcomeCard(),
            const SizedBox(height: 24),
            _buildQuickLinksSection(context),
            const SizedBox(height: 24),
            _buildFAQSection(context),
            const SizedBox(height: 24),
            _buildGuidesSection(context),
            const SizedBox(height: 24),
            _buildContactSection(context),
          ],
        ),
      ),
    );
  }

  Widget _buildWelcomeCard() {
    return Card(
      elevation: 4,
      color: AppColors.surfaceCards,
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
              AppColors.primaryAccent.withOpacity(0.1),
              AppColors.accentLight.withOpacity(0.1),
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
                  color: AppColors.primaryAccent,
                  size: 28,
                ),
                const SizedBox(width: 12),
                Text(
                  'Welcome to Help Center',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Text(
              'Find answers to common questions, learn how to use ImmoLink features, and get support when you need it.',
              style: TextStyle(
                fontSize: 16,
                color: AppColors.textSecondary,
                height: 1.5,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildQuickLinksSection(BuildContext context) {
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
              'Quick Links',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 16),
            _buildQuickLinkItem(
              context,
              'Getting Started',
              'Learn the basics of using ImmoLink',
              Icons.play_circle_outline,
              () => _showGettingStartedDialog(context),
            ),
            _buildQuickLinkItem(
              context,
              'Account & Settings',
              'Manage your account and privacy settings',
              Icons.settings,
              () => context.push('/settings'),
            ),
            _buildQuickLinkItem(
              context,
              'Property Management',
              'How to add and manage properties',
              Icons.home,
              () => _showPropertyManagementDialog(context),
            ),
            _buildQuickLinkItem(
              context,
              'Payments & Billing',
              'Understanding payments and billing',
              Icons.payment,
              () => _showPaymentsDialog(context),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildQuickLinkItem(BuildContext context, String title, String subtitle, IconData icon, VoidCallback onTap) {
    return ListTile(
      leading: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: AppColors.primaryAccent.withOpacity(0.1),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(icon, color: AppColors.primaryAccent),
      ),
      title: Text(title, style: TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.w600)),
      subtitle: Text(subtitle, style: TextStyle(color: AppColors.textSecondary)),
      trailing: Icon(Icons.chevron_right, color: AppColors.textTertiary),
      onTap: onTap,
    );
  }

  Widget _buildFAQSection(BuildContext context) {
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
              'Frequently Asked Questions',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 16),
            _buildFAQItem(
              'How do I add a new property?',
              'Go to the Properties tab and tap the "+" button. Fill in the property details, add photos, and save.',
            ),
            _buildFAQItem(
              'How do I invite a tenant?',
              'Open a property and tap "Invite Tenant". Enter their email address and they will receive an invitation.',
            ),
            _buildFAQItem(
              'How do I change my currency?',
              'Go to Settings > Preferences > Currency and select your preferred currency.',
            ),
            _buildFAQItem(
              'How do I enable two-factor authentication?',
              'Go to Settings > Security > Two-Factor Authentication and follow the setup instructions.',
            ),
            _buildFAQItem(
              'How do I export my data?',
              'Go to Settings > Privacy Settings > Data Management > Export My Data.',
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFAQItem(String question, String answer) {
    return ExpansionTile(
      title: Text(
        question,
        style: TextStyle(
          color: AppColors.textPrimary,
          fontWeight: FontWeight.w600,
        ),
      ),
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
          child: Text(
            answer,
            style: TextStyle(
              color: AppColors.textSecondary,
              height: 1.5,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildGuidesSection(BuildContext context) {
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
              'User Guides',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 16),
            _buildGuideItem(
              'Landlord Guide',
              'Complete guide for landlords',
              Icons.business,
              () => _showLandlordGuideDialog(context),
            ),
            _buildGuideItem(
              'Tenant Guide',
              'Complete guide for tenants',
              Icons.person,
              () => _showTenantGuideDialog(context),
            ),
            _buildGuideItem(
              'Security Best Practices',
              'Keep your account secure',
              Icons.security,
              () => _showSecurityGuideDialog(context),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildGuideItem(String title, String subtitle, IconData icon, VoidCallback onTap) {
    return ListTile(
      leading: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: AppColors.accentLight.withOpacity(0.2),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(icon, color: AppColors.primaryAccent),
      ),
      title: Text(title, style: TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.w600)),
      subtitle: Text(subtitle, style: TextStyle(color: AppColors.textSecondary)),
      trailing: Icon(Icons.chevron_right, color: AppColors.textTertiary),
      onTap: onTap,
    );
  }

  Widget _buildContactSection(BuildContext context) {
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
              'Need More Help?',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'Can\'t find what you\'re looking for? Our support team is here to help.',
              style: TextStyle(
                fontSize: 14,
                color: AppColors.textSecondary,
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () => context.push('/contact-support'),
                    icon: Icon(Icons.support_agent, color: AppColors.textOnAccent),
                    label: Text('Contact Support', style: TextStyle(color: AppColors.textOnAccent)),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primaryAccent,
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

  void _showGettingStartedDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.surfaceCards,
        title: Text('Getting Started', style: TextStyle(color: AppColors.textPrimary)),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Welcome to ImmoLink! Here\'s how to get started:', style: TextStyle(color: AppColors.textPrimary)),
              const SizedBox(height: 16),
              ...['1. Complete your profile', '2. Add your first property', '3. Invite tenants or connect with landlords', '4. Start managing your properties'].map(
                (step) => Padding(
                  padding: const EdgeInsets.symmetric(vertical: 4),
                  child: Text(step, style: TextStyle(color: AppColors.textSecondary)),
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Got it', style: TextStyle(color: AppColors.primaryAccent)),
          ),
        ],
      ),
    );
  }

  void _showPropertyManagementDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.surfaceCards,
        title: Text('Property Management', style: TextStyle(color: AppColors.textPrimary)),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Managing properties in ImmoLink:', style: TextStyle(color: AppColors.textPrimary)),
              const SizedBox(height: 16),
              ...['• Add property details and photos', '• Set rental prices and terms', '• Invite tenants to view or rent', '• Track maintenance requests', '• Monitor payment status'].map(
                (tip) => Padding(
                  padding: const EdgeInsets.symmetric(vertical: 4),
                  child: Text(tip, style: TextStyle(color: AppColors.textSecondary)),
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Got it', style: TextStyle(color: AppColors.primaryAccent)),
          ),
        ],
      ),
    );
  }

  void _showPaymentsDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.surfaceCards,
        title: Text('Payments & Billing', style: TextStyle(color: AppColors.textPrimary)),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Understanding payments in ImmoLink:', style: TextStyle(color: AppColors.textPrimary)),
              const SizedBox(height: 16),
              ...['• View payment history and status', '• Set up automatic payment reminders', '• Track outstanding payments', '• Generate payment reports', '• Export payment data'].map(
                (tip) => Padding(
                  padding: const EdgeInsets.symmetric(vertical: 4),
                  child: Text(tip, style: TextStyle(color: AppColors.textSecondary)),
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Got it', style: TextStyle(color: AppColors.primaryAccent)),
          ),
        ],
      ),
    );
  }

  void _showLandlordGuideDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.surfaceCards,
        title: Text('Landlord Guide', style: TextStyle(color: AppColors.textPrimary)),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Complete guide for landlords:', style: TextStyle(color: AppColors.textPrimary)),
              const SizedBox(height: 16),
              ...['• Property portfolio management', '• Tenant screening and onboarding', '• Rent collection and tracking', '• Maintenance request handling', '• Financial reporting and analytics', '• Legal compliance and documentation'].map(
                (tip) => Padding(
                  padding: const EdgeInsets.symmetric(vertical: 4),
                  child: Text(tip, style: TextStyle(color: AppColors.textSecondary)),
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Got it', style: TextStyle(color: AppColors.primaryAccent)),
          ),
        ],
      ),
    );
  }

  void _showTenantGuideDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.surfaceCards,
        title: Text('Tenant Guide', style: TextStyle(color: AppColors.textPrimary)),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Complete guide for tenants:', style: TextStyle(color: AppColors.textPrimary)),
              const SizedBox(height: 16),
              ...['• Property search and viewing', '• Rental application process', '• Lease agreements and documentation', '• Rent payment and history', '• Maintenance request submission', '• Communication with landlords'].map(
                (tip) => Padding(
                  padding: const EdgeInsets.symmetric(vertical: 4),
                  child: Text(tip, style: TextStyle(color: AppColors.textSecondary)),
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Got it', style: TextStyle(color: AppColors.primaryAccent)),
          ),
        ],
      ),
    );
  }

  void _showSecurityGuideDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.surfaceCards,
        title: Text('Security Best Practices', style: TextStyle(color: AppColors.textPrimary)),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Keep your account secure:', style: TextStyle(color: AppColors.textPrimary)),
              const SizedBox(height: 16),
              ...['• Use a strong, unique password', '• Enable two-factor authentication', '• Review privacy settings regularly', '• Be cautious with shared information', '• Report suspicious activity immediately', '• Keep the app updated'].map(
                (tip) => Padding(
                  padding: const EdgeInsets.symmetric(vertical: 4),
                  child: Text(tip, style: TextStyle(color: AppColors.textSecondary)),
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Got it', style: TextStyle(color: AppColors.primaryAccent)),
          ),
        ],
      ),
    );
  }
}