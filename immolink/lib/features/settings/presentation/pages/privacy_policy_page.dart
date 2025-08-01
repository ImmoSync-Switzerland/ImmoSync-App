import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/app_colors.dart';

class PrivacyPolicyPage extends ConsumerWidget {
  const PrivacyPolicyPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      backgroundColor: AppColors.primaryBackground,
      appBar: AppBar(
        backgroundColor: AppColors.primaryBackground,
        elevation: 0,
        title: Text(
          'Privacy Policy',
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
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16.0),
          child: Card(
            elevation: 4,
            color: AppColors.surfaceCards,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            child: Padding(
              padding: const EdgeInsets.all(20.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'ImmoLink Privacy Policy',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Last updated: ${DateTime.now().toLocal().toString().split(' ')[0]}',
                    style: TextStyle(
                      fontSize: 14,
                      color: AppColors.textSecondary,
                    ),
                  ),
                  const SizedBox(height: 24),
                  
                  _buildSection(
                    '1. Introduction',
                    'ImmoLink AG ("we," "our," or "us") respects your privacy and is committed to protecting your personal data. This Privacy Policy explains how we collect, use, and safeguard your information when you use the ImmoLink application.',
                  ),
                  
                  _buildSection(
                    '2. Information We Collect',
                    'We collect several types of information:\n\n**Personal Information:**\n• Name, email address, phone number\n• Profile information and preferences\n• Account credentials\n\n**Property Information:**\n• Property details, addresses, photos\n• Rental agreements and lease information\n• Payment and financial data\n\n**Usage Information:**\n• App usage patterns and preferences\n• Device information and technical data\n• Location data (when permitted)',
                  ),
                  
                  _buildSection(
                    '3. How We Use Your Information',
                    'We use your information to:\n\n• Provide and maintain our services\n• Process transactions and payments\n• Communicate with you about your account\n• Send notifications and updates\n• Improve our services and user experience\n• Comply with legal obligations\n• Prevent fraud and ensure security',
                  ),
                  
                  _buildSection(
                    '4. Information Sharing',
                    'We may share your information in the following circumstances:\n\n• **With your consent** - when you explicitly agree to share information\n• **Between landlords and tenants** - necessary information for property management\n• **Service providers** - third-party companies that help us provide our services\n• **Legal requirements** - when required by law or to protect our rights\n• **Business transfers** - in case of merger, acquisition, or sale of assets',
                  ),
                  
                  _buildSection(
                    '5. Data Security',
                    'We implement appropriate technical and organizational measures to protect your personal data:\n\n• Encryption of sensitive data in transit and at rest\n• Regular security audits and assessments\n• Access controls and authentication\n• Employee training on data protection\n• Incident response procedures',
                  ),
                  
                  _buildSection(
                    '6. Data Retention',
                    'We retain your personal data only for as long as necessary to fulfill the purposes outlined in this policy or as required by law. When data is no longer needed, we securely delete or anonymize it.',
                  ),
                  
                  _buildSection(
                    '7. Your Rights',
                    'Under applicable data protection laws, you have the right to:\n\n• **Access** - request a copy of your personal data\n• **Rectification** - correct inaccurate or incomplete data\n• **Erasure** - request deletion of your personal data\n• **Portability** - receive your data in a structured format\n• **Restriction** - limit how we process your data\n• **Objection** - object to certain types of processing\n• **Withdraw consent** - revoke consent for data processing',
                  ),
                  
                  _buildSection(
                    '8. Cookies and Tracking',
                    'We use cookies and similar technologies to:\n\n• Remember your preferences and settings\n• Analyze app performance and usage\n• Provide personalized experiences\n• Ensure security and prevent fraud\n\nYou can control cookie settings through your device or browser settings.',
                  ),
                  
                  _buildSection(
                    '9. Third-Party Services',
                    'Our app may integrate with third-party services such as:\n\n• Payment processors (Stripe, PayPal)\n• Map services (Google Maps)\n• Analytics providers\n• Cloud storage providers\n\nEach third-party service has its own privacy policy governing the use of your information.',
                  ),
                  
                  _buildSection(
                    '10. International Transfers',
                    'Your data may be transferred to and processed in countries other than your own. We ensure appropriate safeguards are in place to protect your data in accordance with applicable laws.',
                  ),
                  
                  _buildSection(
                    '11. Children\'s Privacy',
                    'ImmoLink is not intended for use by children under 16 years of age. We do not knowingly collect personal information from children under 16.',
                  ),
                  
                  _buildSection(
                    '12. Changes to This Policy',
                    'We may update this Privacy Policy from time to time. We will notify you of any material changes by email or through the app. Your continued use of the service constitutes acceptance of the updated policy.',
                  ),
                  
                  _buildSection(
                    '13. Contact Us',
                    'If you have questions about this Privacy Policy or our data practices, please contact us:\n\n**Data Protection Officer**\nEmail: privacy@immolink.com\nPhone: +41 44 123 45 67\nAddress: ImmoLink AG, Bahnhofstrasse 1, 8001 Zurich, Switzerland\n\n**Supervisory Authority**\nYou can also contact the Swiss Federal Data Protection and Information Commissioner (FDPIC) if you have concerns about our data practices.',
                  ),
                  
                  const SizedBox(height: 24),
                  
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: AppColors.success.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(Icons.shield, color: AppColors.success),
                            const SizedBox(width: 8),
                            Text(
                              'Your Privacy Matters',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                color: AppColors.success,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'We are committed to protecting your privacy and giving you control over your personal data. You can manage your privacy settings in the app or contact us with any questions.',
                          style: TextStyle(
                            color: AppColors.textSecondary,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                  
                  const SizedBox(height: 16),
                  
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: AppColors.primaryAccent.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(Icons.info, color: AppColors.primaryAccent),
                            const SizedBox(width: 8),
                            Text(
                              'Sample Document',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                color: AppColors.primaryAccent,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'This is a sample Privacy Policy for demonstration purposes. In a production environment, this policy should be reviewed and customized by legal professionals to ensure compliance with applicable privacy laws such as GDPR, CCPA, and local regulations.',
                          style: TextStyle(
                            color: AppColors.textSecondary,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSection(String title, String content) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            content,
            style: TextStyle(
              fontSize: 14,
              color: AppColors.textSecondary,
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }
}