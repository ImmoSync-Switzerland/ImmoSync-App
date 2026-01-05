import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../../../l10n/app_localizations.dart';
import '../../../../core/providers/dynamic_colors_provider.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
// Removed direct API usage; rely on SupportRequestService
import '../../../support/domain/services/support_request_service.dart';

const _bgTop = Color(0xFF0A1128);
const _bgBottom = Colors.black;
const _bentoCard = Color(0xFF1C1C1E);
const _primaryBlue = Color(0xFF3B82F6);
const _fieldFill = Color(0xFF2C2C2E);

class ContactSupportPage extends ConsumerStatefulWidget {
  const ContactSupportPage({super.key});

  @override
  ConsumerState<ContactSupportPage> createState() => _ContactSupportPageState();
}

class _ContactSupportPageState extends ConsumerState<ContactSupportPage> {
  @override
  Widget build(BuildContext context) {
    return const ContactSupportScreen();
  }
}

class ContactSupportScreen extends ConsumerStatefulWidget {
  const ContactSupportScreen({super.key});

  @override
  ConsumerState<ContactSupportScreen> createState() =>
      _ContactSupportScreenState();
}

class _ContactSupportScreenState extends ConsumerState<ContactSupportScreen> {
  final _formKey = GlobalKey<FormState>();
  final _subjectController = TextEditingController();
  final _messageController = TextEditingController();
  final _subjectFocus = FocusNode();
  final _messageFocus = FocusNode();
  String _selectedCategory = 'Payment Issue';
  String _selectedPriority = 'Medium';
  bool _isSubmitting = false;

  @override
  void dispose() {
    _subjectController.dispose();
    _messageController.dispose();
    _subjectFocus.dispose();
    _messageFocus.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final topPadding = MediaQuery.of(context).padding.top;

    return Scaffold(
      extendBodyBehindAppBar: true,
      extendBody: true,
      backgroundColor: Colors.transparent,
      body: AnnotatedRegion<SystemUiOverlayStyle>(
        value: const SystemUiOverlayStyle(
          statusBarColor: Colors.transparent,
          statusBarIconBrightness: Brightness.light,
          statusBarBrightness: Brightness.dark,
        ),
        child: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [_bgTop, _bgBottom],
            ),
          ),
          child: ListView(
            padding: EdgeInsets.fromLTRB(16, topPadding + 8, 16, 120),
            children: [
              SizedBox(
                height: kToolbarHeight,
                child: Row(
                  children: [
                    IconButton(
                      icon: const Icon(
                        Icons.arrow_back_ios_new_rounded,
                        color: Colors.white,
                      ),
                      onPressed: () {
                        if (context.canPop()) {
                          context.pop();
                          return;
                        }
                        // If opened as a root route (deep link), ensure a safe fallback.
                        context.go('/home');
                      },
                    ),
                    Expanded(
                      child: Center(
                        child: Text(
                          l10n.contactSupport,
                          style: AppTypography.pageTitle.copyWith(
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 48),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              _buildHeaderCard(l10n),
              const SizedBox(height: 24),
              _buildQuickContactSection(l10n),
              const SizedBox(height: 24),
              _buildSupportForm(l10n),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeaderCard(AppLocalizations l10n) {
    return Card(
      elevation: 0,
      color: _bentoCard,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(18),
        side: BorderSide(color: Colors.white.withValues(alpha: 0.08), width: 1),
      ),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(18),
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              _primaryBlue.withValues(alpha: 0.12),
              Colors.white.withValues(alpha: 0.04),
            ],
          ),
        ),
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(
                  Icons.support_agent,
                  color: _primaryBlue,
                  size: 28,
                ),
                const SizedBox(width: 12),
                Text(
                  l10n.weAreHereToHelp,
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Text(
              l10n.supportTeamDescription,
              style: const TextStyle(
                fontSize: 16,
                color: Colors.white70,
                height: 1.5,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildQuickContactSection(AppLocalizations l10n) {
    return Card(
      elevation: 0,
      color: _bentoCard,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(18),
        side: BorderSide(color: Colors.white.withValues(alpha: 0.08), width: 1),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              l10n.quickContact,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.white,
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
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildQuickContactButton(
                    l10n.callUs,
                    Icons.phone,
                    () => _launchPhone(l10n),
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
      {bool fullWidth = false}) {
    return ElevatedButton.icon(
      onPressed: onTap,
      icon: Icon(icon, color: Colors.white),
      label: Text(title, style: const TextStyle(color: Colors.white)),
      style: ElevatedButton.styleFrom(
        backgroundColor: _primaryBlue,
        padding: const EdgeInsets.symmetric(vertical: 12),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
        minimumSize: fullWidth ? const Size(double.infinity, 48) : null,
      ),
    );
  }

  InputDecoration _darkFieldDecoration({
    required String label,
    required String hint,
    Widget? suffixIcon,
    bool alignLabelWithHint = false,
  }) {
    return InputDecoration(
      labelText: label,
      hintText: hint,
      filled: true,
      fillColor: _fieldFill,
      alignLabelWithHint: alignLabelWithHint,
      labelStyle: const TextStyle(color: Colors.white70),
      hintStyle: TextStyle(color: Colors.white.withValues(alpha: 0.38)),
      counterStyle: TextStyle(color: Colors.white.withValues(alpha: 0.38)),
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide.none,
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide.none,
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: _primaryBlue.withValues(alpha: 0.9)),
      ),
      suffixIcon: suffixIcon,
    );
  }

  Widget _buildSupportForm(AppLocalizations l10n) {
    final currentUser = ref.watch(currentUserProvider);

    final displayName = (currentUser?.fullName.isNotEmpty ?? false)
        ? currentUser!.fullName
        : 'Fabian Boni';
    final displayRole = (currentUser?.role.isNotEmpty ?? false)
        ? currentUser!.role
        : 'Landlord';
    final displayAccountId =
        (currentUser?.id.isNotEmpty ?? false) ? currentUser!.id : '2568 8421';

    return Card(
      elevation: 0,
      color: _bentoCard,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(18),
        side: BorderSide(color: Colors.white.withValues(alpha: 0.08), width: 1),
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
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 16),
              Text(
                l10n.supportFormDescription,
                style: const TextStyle(
                  fontSize: 14,
                  color: Colors.white70,
                ),
              ),
              const SizedBox(height: 20),

              // User Info (Read-only)
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: _fieldFill,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: Colors.white.withValues(alpha: 0.08),
                    width: 1,
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      l10n.accountInformation,
                      style: const TextStyle(
                        fontWeight: FontWeight.w600,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      '$displayName ($displayRole)',
                      style: const TextStyle(color: Colors.white70),
                    ),
                    Text(
                      'Account ID: $displayAccountId',
                      style: const TextStyle(color: Colors.white70),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),

              Text(
                l10n.category,
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.65),
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 8),
              _buildCategoryChips(),
              const SizedBox(height: 16),

              Text(
                l10n.priority,
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.65),
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 8),
              _buildPriorityChips(l10n),
              const SizedBox(height: 16),

              // Subject field
              TextFormField(
                controller: _subjectController,
                focusNode: _subjectFocus,
                textInputAction: TextInputAction.next,
                onFieldSubmitted: (_) => _messageFocus.requestFocus(),
                style: const TextStyle(color: Colors.white),
                decoration: _darkFieldDecoration(
                  label: l10n.subject,
                  hint: l10n.subjectHint,
                  suffixIcon: _subjectController.text.isEmpty
                      ? null
                      : IconButton(
                          icon: Icon(
                            Icons.clear,
                            color: Colors.white.withValues(alpha: 0.6),
                          ),
                          onPressed: () {
                            _subjectController.clear();
                            setState(() {});
                          },
                        ),
                ),
                maxLength: 120,
                autovalidateMode: AutovalidateMode.onUserInteraction,
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return l10n.pleaseEnterSubject;
                  }
                  return null;
                },
                onChanged: (_) => setState(() {}),
              ),
              const SizedBox(height: 16),

              // Message field
              TextFormField(
                controller: _messageController,
                maxLines: 6,
                focusNode: _messageFocus,
                style: const TextStyle(color: Colors.white),
                decoration: _darkFieldDecoration(
                  label: l10n.describeYourIssue,
                  hint: l10n.issueDescriptionHint,
                  alignLabelWithHint: true,
                  suffixIcon: _messageController.text.isEmpty
                      ? null
                      : IconButton(
                          icon: Icon(
                            Icons.clear,
                            color: Colors.white.withValues(alpha: 0.6),
                          ),
                          onPressed: () {
                            _messageController.clear();
                            setState(() {});
                          },
                        ),
                ),
                maxLength: 1500,
                autovalidateMode: AutovalidateMode.onUserInteraction,
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return l10n.pleaseDescribeIssue;
                  }
                  if (value.trim().length < 10) {
                    return l10n.provideMoreDetails;
                  }
                  return null;
                },
                onChanged: (_) => setState(() {}),
              ),
              const SizedBox(height: 24),

              // Submit button
              SizedBox(
                width: double.infinity,
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        _primaryBlue,
                        _primaryBlue.withValues(alpha: 0.7),
                      ],
                    ),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: ElevatedButton(
                    onPressed: _isSubmitting
                        ? null
                        : () => _submitSupportRequest(l10n),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.transparent,
                      disabledBackgroundColor: Colors.transparent,
                      shadowColor: Colors.transparent,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                    child: _isSubmitting
                        ? const SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor:
                                  AlwaysStoppedAnimation<Color>(Colors.white),
                            ),
                          )
                        : Text(
                            l10n.submitRequest,
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
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

  Widget _buildCategoryChips() {
    const categories = <String>[
      'Payment Issue',
      'Technical Support',
      'Contract',
      'Security Concerns',
    ];

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: categories.map((category) {
          final isSelected = _selectedCategory == category;
          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: ChoiceChip(
              label: Text(category),
              selected: isSelected,
              onSelected: (_) => setState(() => _selectedCategory = category),
              selectedColor: _primaryBlue.withValues(alpha: 0.22),
              backgroundColor: _fieldFill,
              labelStyle: TextStyle(
                color: isSelected ? Colors.white : Colors.white70,
                fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
              ),
              shape: StadiumBorder(
                side: BorderSide(
                  color: isSelected
                      ? _primaryBlue
                      : Colors.white.withValues(alpha: 0.12),
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildPriorityChips(AppLocalizations l10n) {
    final entries = <MapEntry<String, String>>[
      MapEntry('Low', l10n.low),
      MapEntry('Medium', l10n.medium),
      MapEntry('High', l10n.high),
    ];

    return Row(
      children: entries.map((e) {
        final isSelected = _selectedPriority == e.key;
        final selectedColor = _getPriorityColor(e.key);
        return Expanded(
          child: Padding(
            padding: EdgeInsets.only(
              right: e.key == 'High' ? 0 : 10,
            ),
            child: ChoiceChip(
              label: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 8,
                    height: 8,
                    decoration: BoxDecoration(
                      color: isSelected
                          ? selectedColor
                          : Colors.white.withValues(alpha: 0.25),
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Flexible(
                    child: Text(
                      e.value,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
              selected: isSelected,
              onSelected: (_) => setState(() => _selectedPriority = e.key),
              selectedColor: _fieldFill,
              backgroundColor: _fieldFill,
              labelStyle: TextStyle(
                color: isSelected ? selectedColor : Colors.white70,
                fontWeight: isSelected ? FontWeight.w700 : FontWeight.w600,
              ),
              shape: StadiumBorder(
                side: BorderSide(
                  color: isSelected
                      ? selectedColor
                      : Colors.white.withValues(alpha: 0.12),
                ),
              ),
            ),
          ),
        );
      }).toList(),
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
      default:
        return Colors.grey;
    }
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

    try {
      // Use centralized service to handle auth headers, retries, and proxy fallback
      final service = ref.read(supportRequestServiceProvider);
      final subject = _subjectController.text.trim();
      final message = _messageController.text.trim();
      await service.create(
        subject: subject,
        message: message,
        category: _selectedCategory,
        priority: _selectedPriority,
      );

      if (mounted) {
        // Clear form on success
        _subjectController.clear();
        _messageController.clear();
        setState(() {
          _selectedCategory = 'Payment Issue';
          _selectedPriority = 'Medium';
        });

        final colors = ref.read(dynamicColorsProvider);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(l10n.supportRequestSubmitted),
            backgroundColor: colors.success,
          ),
        );
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
    } finally {
      if (mounted) {
        setState(() {
          _isSubmitting = false;
        });
      }
    }
  }
}
