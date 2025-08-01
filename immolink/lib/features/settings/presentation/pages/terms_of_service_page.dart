import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/app_colors.dart';

class TermsOfServicePage extends ConsumerWidget {
  const TermsOfServicePage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      backgroundColor: AppColors.primaryBackground,
      appBar: AppBar(
        backgroundColor: AppColors.primaryBackground,
        elevation: 0,
        title: Text(
          'Terms of Service',
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
                    'ImmoLink Terms of Service',
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
                    'Welcome to ImmoLink. These Terms of Service ("Terms") govern your use of the ImmoLink application and services. By accessing or using ImmoLink, you agree to be bound by these Terms.',
                  ),
                  
                  _buildSection(
                    '2. Description of Service',
                    'ImmoLink is a property management platform that connects landlords and tenants, facilitating property management, rent collection, maintenance requests, and communication between parties.',
                  ),
                  
                  _buildSection(
                    '3. User Accounts',
                    'To use ImmoLink, you must create an account. You are responsible for:\n\n• Providing accurate and complete information\n• Maintaining the security of your account credentials\n• All activities that occur under your account\n• Notifying us immediately of any unauthorized use',
                  ),
                  
                  _buildSection(
                    '4. Acceptable Use',
                    'You agree to use ImmoLink only for lawful purposes and in accordance with these Terms. You may not:\n\n• Violate any applicable laws or regulations\n• Infringe on intellectual property rights\n• Transmit harmful or malicious content\n• Attempt to gain unauthorized access to the system\n• Use the service for fraudulent activities',
                  ),
                  
                  _buildSection(
                    '5. Property Listings and Information',
                    'Landlords are responsible for the accuracy of property information they provide. ImmoLink does not verify property details, and users should conduct their own due diligence.',
                  ),
                  
                  _buildSection(
                    '6. Payment Terms',
                    'Payment processing is handled through third-party providers. ImmoLink is not responsible for payment disputes between landlords and tenants, but we may assist in resolving conflicts.',
                  ),
                  
                  _buildSection(
                    '7. Privacy and Data Protection',
                    'Your privacy is important to us. Please review our Privacy Policy, which explains how we collect, use, and protect your information.',
                  ),
                  
                  _buildSection(
                    '8. Intellectual Property',
                    'ImmoLink and its content are protected by copyright, trademark, and other intellectual property laws. Users retain ownership of content they upload but grant ImmoLink a license to use it for service provision.',
                  ),
                  
                  _buildSection(
                    '9. Termination',
                    'Either party may terminate an account at any time. Upon termination, your access to the service will cease, and we may delete your data in accordance with our data retention policy.',
                  ),
                  
                  _buildSection(
                    '10. Limitation of Liability',
                    'ImmoLink provides the service "as is" without warranties. We are not liable for any indirect, incidental, or consequential damages arising from your use of the service.',
                  ),
                  
                  _buildSection(
                    '11. Dispute Resolution',
                    'Any disputes arising from these Terms will be resolved through binding arbitration in accordance with the laws of Switzerland.',
                  ),
                  
                  _buildSection(
                    '12. Changes to Terms',
                    'We may modify these Terms at any time. We will notify users of significant changes via email or app notification. Continued use of the service constitutes acceptance of the modified Terms.',
                  ),
                  
                  _buildSection(
                    '13. Contact Information',
                    'If you have questions about these Terms, please contact us at:\n\nEmail: legal@immolink.com\nAddress: ImmoLink AG, Bahnhofstrasse 1, 8001 Zurich, Switzerland',
                  ),
                  
                  const SizedBox(height: 24),
                  
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
                              'Important Note',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                color: AppColors.primaryAccent,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'This is a sample Terms of Service document for demonstration purposes. In a production environment, these terms should be reviewed and customized by legal professionals to ensure compliance with applicable laws and regulations.',
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