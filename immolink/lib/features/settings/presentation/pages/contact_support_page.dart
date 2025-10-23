import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../../../../../l10n/app_localizations.dart';
import '../../../../core/providers/dynamic_colors_provider.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../../../../core/config/db_config.dart';

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

  @override
  void dispose() {
    _subjectController.dispose();
    _messageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final colors = ref.watch(dynamicColorsProvider);

    return Scaffold(
      backgroundColor: colors.primaryBackground,
      appBar: AppBar(
        backgroundColor: colors.primaryBackground,
        elevation: 0,
        title: Text(
          l10n.contactSupport,
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
            _buildHeaderCard(l10n, colors),
            const SizedBox(height: 24),
            _buildQuickContactSection(context, l10n, colors),
            const SizedBox(height: 24),
            _buildSupportForm(l10n, colors),
            const SizedBox(height: 24),
            _buildSupportInfoCard(l10n, colors),
          ],
        ),
      ),
    );
  }

  Widget _buildHeaderCard(AppLocalizations l10n, DynamicAppColors colors) {
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
                  Icons.support_agent,
                  color: colors.primaryAccent,
                  size: 28,
                ),
                const SizedBox(width: 12),
                Text(
                  l10n.weAreHereToHelp,
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
              l10n.supportTeamDescription,
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

  Widget _buildQuickContactSection(
      BuildContext context, AppLocalizations l10n, DynamicAppColors colors) {
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
              l10n.quickContact,
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: colors.textPrimary,
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: _buildQuickContactButton(
                    l10n.emailUs,
                    Icons.email,
                    () => _launchEmail(l10n),
                    colors: colors,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildQuickContactButton(
                    l10n.callUs,
                    Icons.phone,
                    () => _launchPhone(l10n),
                    colors: colors,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildQuickContactButton(
      String title, IconData icon, VoidCallback onTap,
      {bool fullWidth = false, required DynamicAppColors colors}) {
    return ElevatedButton.icon(
      onPressed: onTap,
      icon: Icon(icon, color: colors.textOnAccent),
      label: Text(title, style: TextStyle(color: colors.textOnAccent)),
      style: ElevatedButton.styleFrom(
        backgroundColor: colors.primaryAccent,
        padding: const EdgeInsets.symmetric(vertical: 12),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
        minimumSize: fullWidth ? const Size(double.infinity, 48) : null,
      ),
    );
  }

  Widget _buildSupportForm(AppLocalizations l10n, DynamicAppColors colors) {
    final currentUser = ref.watch(currentUserProvider);

    return Card(
      elevation: 4,
      color: colors.surfaceCards,
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
                l10n.submitSupportRequest,
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: colors.textPrimary,
                ),
              ),
              const SizedBox(height: 16),
              Text(
                l10n.supportFormDescription,
                style: TextStyle(
                  fontSize: 14,
                  color: colors.textSecondary,
                ),
              ),
              const SizedBox(height: 20),

              // User Info (Read-only)
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: colors.primaryBackground.withValues(alpha: 0.5),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      l10n.accountInformation,
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        color: colors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                        '${l10n.name}: ${currentUser?.fullName ?? l10n.notAvailable}',
                        style: TextStyle(color: colors.textSecondary)),
                    Text(
                        '${l10n.email}: ${currentUser?.email ?? l10n.notAvailable}',
                        style: TextStyle(color: colors.textSecondary)),
                    Text(
                        '${l10n.role}: ${currentUser?.role ?? l10n.notAvailable}',
                        style: TextStyle(color: colors.textSecondary)),
                  ],
                ),
              ),
              const SizedBox(height: 20),

              // Category dropdown
              _buildStyledDropdown(
                context: context,
                colors: colors,
                label: l10n.category,
                value: _selectedCategory,
                items: _getLocalizedCategories(l10n)
                    .map((c) => DropdownMenuItem(
                          value: c.key,
                          child: Text(c.value, overflow: TextOverflow.ellipsis),
                        ))
                    .toList(),
                onChanged: (v) => setState(() => _selectedCategory = v!),
              ),
              const SizedBox(height: 16),

              // Priority dropdown
              _buildStyledDropdown(
                context: context,
                colors: colors,
                label: l10n.priority,
                value: _selectedPriority,
                items: _getLocalizedPriorities(l10n)
                    .map((p) => DropdownMenuItem(
                          value: p.key,
                          child: Row(
                            children: [
                              Container(
                                width: 12,
                                height: 12,
                                decoration: BoxDecoration(
                                  color: _getPriorityColor(p.key),
                                  shape: BoxShape.circle,
                                ),
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  p.value,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                        ))
                    .toList(),
                onChanged: (v) => setState(() => _selectedPriority = v!),
              ),
              const SizedBox(height: 16),

              // Subject field
              TextFormField(
                controller: _subjectController,
                decoration: InputDecoration(
                  labelText: l10n.subject,
                  hintText: l10n.subjectHint,
                  border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8)),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: BorderSide(color: colors.primaryAccent),
                  ),
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return l10n.pleaseEnterSubject;
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
                  labelText: l10n.describeYourIssue,
                  hintText: l10n.issueDescriptionHint,
                  border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8)),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: BorderSide(color: colors.primaryAccent),
                  ),
                  alignLabelWithHint: true,
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return l10n.pleaseDescribeIssue;
                  }
                  if (value.trim().length < 10) {
                    return l10n.provideMoreDetails;
                  }
                  return null;
                },
              ),
              const SizedBox(height: 24),

              // Submit button
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed:
                      _isSubmitting ? null : () => _submitSupportRequest(l10n),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: colors.primaryAccent,
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
                            valueColor: AlwaysStoppedAnimation<Color>(
                                colors.textOnAccent),
                          ),
                        )
                      : Text(
                          l10n.submitRequest,
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: colors.textOnAccent,
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

  Widget _buildSupportInfoCard(AppLocalizations l10n, DynamicAppColors colors) {
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
              l10n.supportInformation,
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: colors.textPrimary,
              ),
            ),
            const SizedBox(height: 16),
            _buildInfoRow(Icons.schedule, l10n.responseTime,
                l10n.responseTimeInfo, colors),
            _buildInfoRow(Icons.language, l10n.languages,
                l10n.languagesSupported, colors),
            _buildInfoRow(Icons.support, l10n.supportHours,
                l10n.supportHoursInfo, colors),
            _buildInfoRow(
                Icons.emergency, l10n.emergency, l10n.emergencyInfo, colors),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(
      IconData icon, String title, String info, DynamicAppColors colors) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Icon(icon, color: colors.primaryAccent, size: 20),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    color: colors.textPrimary,
                  ),
                ),
                Text(
                  info,
                  style: TextStyle(
                    fontSize: 12,
                    color: colors.textSecondary,
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

  List<MapEntry<String, String>> _getLocalizedCategories(
      AppLocalizations l10n) {
    return [
      MapEntry('General', l10n.general),
      MapEntry('Account & Settings', l10n.accountAndSettings),
      MapEntry('Property Management', l10n.propertyManagement),
      MapEntry('Payments & Billing', l10n.paymentsBilling),
      MapEntry('Technical Issues', l10n.technicalIssues),
      MapEntry('Security Concerns', l10n.securityConcerns),
      MapEntry('Feature Request', l10n.featureRequest),
      MapEntry('Bug Report', l10n.bugReport),
    ];
  }

  List<MapEntry<String, String>> _getLocalizedPriorities(
      AppLocalizations l10n) {
    return [
      MapEntry('Low', l10n.low),
      MapEntry('Medium', l10n.medium),
      MapEntry('High', l10n.high),
      MapEntry('Urgent', l10n.urgent),
    ];
  }

  Future<void> _launchEmail(AppLocalizations l10n) async {
    final Uri emailUri = Uri(
      scheme: 'mailto',
      path: 'info@immosync.ch',
      query: 'subject=ImmoSync Support Request',
    );

    if (await canLaunchUrl(emailUri)) {
      await launchUrl(emailUri);
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(l10n.couldNotOpenEmail)),
        );
      }
    }
  }

  Future<void> _launchPhone(AppLocalizations l10n) async {
    // Remove spaces for URI format, keep display formatting elsewhere if needed
    final Uri phoneUri = Uri(scheme: 'tel', path: '+41763919400');

    if (await canLaunchUrl(phoneUri)) {
      await launchUrl(phoneUri);
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(l10n.couldNotOpenPhone)),
        );
      }
    }
  }

  Future<void> _submitSupportRequest(AppLocalizations l10n) async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isSubmitting = true;
    });

    // Simulate API call
    try {
      final user = ref.read(currentUserProvider);
      final apiBase = DbConfig.apiUrl;
      final uri = Uri.parse('$apiBase/support-requests');
      final body = {
        'subject': _subjectController.text.trim(),
        'message': _messageController.text.trim(),
        'category': _selectedCategory,
        'priority': _selectedPriority,
        'userId': user?.id,
        'meta': {
          'appVersion': '1.0.0',
          'platform': Theme.of(context).platform.name,
        }
      };
      final resp = await http.post(
        uri,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(body),
      );
      if (resp.statusCode < 200 || resp.statusCode >= 300) {
        throw Exception('Failed (${resp.statusCode})');
      }
    } catch (e) {
      if (mounted) {
        final colors = ref.read(dynamicColorsProvider);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${l10n.error}: ${e.toString()}'),
            backgroundColor: colors.error,
          ),
        );
      }
    }

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
      final colors = ref.read(dynamicColorsProvider);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(l10n.supportRequestSubmitted),
          backgroundColor: colors.success,
        ),
      );
    }
  }

  Widget _buildStyledDropdown({
    required BuildContext context,
    required DynamicAppColors colors,
    required String label,
    required String value,
    required List<DropdownMenuItem<String>> items,
    required ValueChanged<String?> onChanged,
  }) {
    return DropdownButtonFormField<String>(
      // ignore: deprecated_member_use
      value: value,
      isExpanded: true,
      dropdownColor: colors.surfaceCards,
      iconEnabledColor: colors.textPrimary,
      style: TextStyle(color: colors.textPrimary, fontSize: 14),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: TextStyle(color: colors.textSecondary),
        filled: true,
        fillColor: colors.primaryBackground.withValues(alpha: 0.6),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide:
              BorderSide(color: colors.primaryAccent.withValues(alpha: 0.3)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: colors.primaryAccent),
        ),
      ),
      items: items,
      onChanged: onChanged,
    );
  }
}
