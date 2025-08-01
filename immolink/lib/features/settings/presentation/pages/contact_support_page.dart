import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../auth/presentation/providers/auth_provider.dart';

class ContactSupportPage extends ConsumerStatefulWidget {
  const ContactSupportPage({super.key});

  @override
  ConsumerState<ContactSupportPage> createState() => _ContactSupportPageState();
}

class _ContactSupportPageState extends ConsumerState<ContactSupportPage> {
  final _formKey = GlobalKey<FormState>();
  final _subjectController = TextEditingController();
  final _messageController = TextEditingController();
  String _selectedCategory = 'General';
  String _selectedPriority = 'Medium';
  bool _isSubmitting = false;

  final List<String> _categories = [
    'General',
    'Account & Settings',
    'Property Management',
    'Payments & Billing',
    'Technical Issues',
    'Security Concerns',
    'Feature Request',
    'Bug Report',
  ];

  final List<String> _priorities = [
    'Low',
    'Medium',
    'High',
    'Urgent',
  ];

  @override
  void dispose() {
    _subjectController.dispose();
    _messageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.primaryBackground,
      appBar: AppBar(
        backgroundColor: AppColors.primaryBackground,
        elevation: 0,
        title: Text(
          'Contact Support',
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
            _buildHeaderCard(),
            const SizedBox(height: 24),
            _buildQuickContactSection(context),
            const SizedBox(height: 24),
            _buildSupportForm(),
            const SizedBox(height: 24),
            _buildSupportInfoCard(),
          ],
        ),
      ),
    );
  }

  Widget _buildHeaderCard() {
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
              AppColors.primaryAccent.withValues(alpha: 0.1),
              AppColors.accentLight.withValues(alpha: 0.1),
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
                  Icons.support_agent,
                  color: AppColors.primaryAccent,
                  size: 28,
                ),
                const SizedBox(width: 12),
                Text(
                  'We\'re Here to Help',
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
              'Our support team is ready to assist you with any questions or issues you may have. Choose how you\'d like to get in touch.',
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

  Widget _buildQuickContactSection(BuildContext context) {
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
              'Quick Contact',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: _buildQuickContactButton(
                    'Email Us',
                    Icons.email,
                    () => _launchEmail(),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildQuickContactButton(
                    'Call Us',
                    Icons.phone,
                    () => _launchPhone(),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            _buildQuickContactButton(
              'Live Chat',
              Icons.chat,
              () => _showLiveChatDialog(context),
              fullWidth: true,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildQuickContactButton(String title, IconData icon, VoidCallback onTap, {bool fullWidth = false}) {
    return ElevatedButton.icon(
      onPressed: onTap,
      icon: Icon(icon, color: AppColors.textOnAccent),
      label: Text(title, style: TextStyle(color: AppColors.textOnAccent)),
      style: ElevatedButton.styleFrom(
        backgroundColor: AppColors.primaryAccent,
        padding: const EdgeInsets.symmetric(vertical: 12),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
        minimumSize: fullWidth ? const Size(double.infinity, 48) : null,
      ),
    );
  }

  Widget _buildSupportForm() {
    final currentUser = ref.watch(currentUserProvider);

    return Card(
      elevation: 4,
      color: AppColors.surfaceCards,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Submit a Support Request',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 16),
              Text(
                'Fill out the form below and we\'ll get back to you as soon as possible.',
                style: TextStyle(
                  fontSize: 14,
                  color: AppColors.textSecondary,
                ),
              ),
              const SizedBox(height: 20),
              
              // User Info (Read-only)
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.primaryBackground.withValues(alpha: 0.5),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Account Information',
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text('Name: ${currentUser?.fullName ?? 'Not available'}', style: TextStyle(color: AppColors.textSecondary)),
                    Text('Email: ${currentUser?.email ?? 'Not available'}', style: TextStyle(color: AppColors.textSecondary)),
                    Text('Role: ${currentUser?.role ?? 'Not available'}', style: TextStyle(color: AppColors.textSecondary)),
                  ],
                ),
              ),
              const SizedBox(height: 20),

              // Category dropdown
              DropdownButtonFormField<String>(
                value: _selectedCategory,
                decoration: InputDecoration(
                  labelText: 'Category',
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: BorderSide(color: AppColors.primaryAccent),
                  ),
                ),
                items: _categories.map((category) => DropdownMenuItem(
                  value: category,
                  child: Text(category),
                )).toList(),
                onChanged: (value) {
                  setState(() {
                    _selectedCategory = value!;
                  });
                },
              ),
              const SizedBox(height: 16),

              // Priority dropdown
              DropdownButtonFormField<String>(
                value: _selectedPriority,
                decoration: InputDecoration(
                  labelText: 'Priority',
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: BorderSide(color: AppColors.primaryAccent),
                  ),
                ),
                items: _priorities.map((priority) => DropdownMenuItem(
                  value: priority,
                  child: Row(
                    children: [
                      Container(
                        width: 12,
                        height: 12,
                        decoration: BoxDecoration(
                          color: _getPriorityColor(priority),
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(priority),
                    ],
                  ),
                )).toList(),
                onChanged: (value) {
                  setState(() {
                    _selectedPriority = value!;
                  });
                },
              ),
              const SizedBox(height: 16),

              // Subject field
              TextFormField(
                controller: _subjectController,
                decoration: InputDecoration(
                  labelText: 'Subject',
                  hintText: 'Brief description of your issue',
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: BorderSide(color: AppColors.primaryAccent),
                  ),
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Please enter a subject';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),

              // Message field
              TextFormField(
                controller: _messageController,
                maxLines: 6,
                decoration: InputDecoration(
                  labelText: 'Describe your issue',
                  hintText: 'Please provide as much detail as possible to help us assist you better',
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: BorderSide(color: AppColors.primaryAccent),
                  ),
                  alignLabelWithHint: true,
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Please describe your issue';
                  }
                  if (value.trim().length < 10) {
                    return 'Please provide more details (at least 10 characters)';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 24),

              // Submit button
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _isSubmitting ? null : _submitSupportRequest,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primaryAccent,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child: _isSubmitting
                      ? SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation<Color>(AppColors.textOnAccent),
                          ),
                        )
                      : Text(
                          'Submit Request',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: AppColors.textOnAccent,
                          ),
                        ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSupportInfoCard() {
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
              'Support Information',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 16),
            _buildInfoRow(Icons.schedule, 'Response Time', 'Usually within 24 hours'),
            _buildInfoRow(Icons.language, 'Languages', 'English, German, French, Italian'),
            _buildInfoRow(Icons.support, 'Support Hours', 'Monday-Friday, 9:00-18:00 CET'),
            _buildInfoRow(Icons.emergency, 'Emergency', 'For urgent issues, call +41 800 123 456'),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String title, String info) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Icon(icon, color: AppColors.primaryAccent, size: 20),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary,
                  ),
                ),
                Text(
                  info,
                  style: TextStyle(
                    fontSize: 12,
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Color _getPriorityColor(String priority) {
    switch (priority) {
      case 'Low':
        return Colors.green;
      case 'Medium':
        return Colors.orange;
      case 'High':
        return Colors.red;
      case 'Urgent':
        return Colors.purple;
      default:
        return Colors.grey;
    }
  }

  Future<void> _launchEmail() async {
    final Uri emailUri = Uri(
      scheme: 'mailto',
      path: 'support@immolink.com',
      query: 'subject=ImmoLink Support Request',
    );
    
    if (await canLaunchUrl(emailUri)) {
      await launchUrl(emailUri);
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Could not open email app')),
        );
      }
    }
  }

  Future<void> _launchPhone() async {
    final Uri phoneUri = Uri(scheme: 'tel', path: '+41800123456');
    
    if (await canLaunchUrl(phoneUri)) {
      await launchUrl(phoneUri);
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Could not open phone app')),
        );
      }
    }
  }

  void _showLiveChatDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.surfaceCards,
        title: Text('Live Chat', style: TextStyle(color: AppColors.textPrimary)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.chat, size: 48, color: AppColors.primaryAccent),
            const SizedBox(height: 16),
            Text(
              'Live chat is currently available during business hours (Monday-Friday, 9:00-18:00 CET).',
              style: TextStyle(color: AppColors.textPrimary),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            Text(
              'For immediate assistance outside business hours, please use the support form or send us an email.',
              style: TextStyle(color: AppColors.textSecondary, fontSize: 12),
              textAlign: TextAlign.center,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Close', style: TextStyle(color: AppColors.textSecondary)),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Live chat feature will be available soon')),
              );
            },
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.primaryAccent),
            child: Text('Start Chat', style: TextStyle(color: AppColors.textOnAccent)),
          ),
        ],
      ),
    );
  }

  Future<void> _submitSupportRequest() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isSubmitting = true;
    });

    // Simulate API call
    await Future.delayed(const Duration(seconds: 2));

    if (mounted) {
      setState(() {
        _isSubmitting = false;
      });

      // Clear form
      _subjectController.clear();
      _messageController.clear();
      setState(() {
        _selectedCategory = 'General';
        _selectedPriority = 'Medium';
      });

      // Show success message
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Support request submitted successfully! We\'ll get back to you soon.'),
          backgroundColor: AppColors.success,
        ),
      );
    }
  }
}