import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../../l10n/app_localizations.dart';
import 'package:go_router/go_router.dart';
import 'package:immosync/features/auth/presentation/providers/auth_provider.dart';
import 'package:immosync/features/maintenance/domain/models/maintenance_request.dart';
import 'package:immosync/features/maintenance/presentation/providers/maintenance_providers.dart';
import 'package:immosync/features/property/presentation/providers/property_providers.dart';

@Deprecated('Use SubmitMaintenanceRequestScreen')
class MaintenanceRequestPage extends SubmitMaintenanceRequestScreen {
  const MaintenanceRequestPage({super.key, super.propertyId});
}

/// Tenant Maintenance: premium "New Request" form.
/// Alias for clarity across the app.
class NewRequestScreen extends SubmitMaintenanceRequestScreen {
  const NewRequestScreen({super.key, super.propertyId});
}

class SubmitMaintenanceRequestScreen extends ConsumerStatefulWidget {
  final String? propertyId;

  const SubmitMaintenanceRequestScreen({super.key, this.propertyId});

  @override
  ConsumerState<SubmitMaintenanceRequestScreen> createState() =>
      _SubmitMaintenanceRequestScreenState();
}

class _SubmitMaintenanceRequestScreenState
    extends ConsumerState<SubmitMaintenanceRequestScreen> {
  static const Color _bgStart = Color(0xFF0A1128);
  static const Color _bgEnd = Colors.black;
  static const Color _cardBg = Color(0xFF1C1C1E);
  static const Color _fieldBg = Color(0xFF2C2C2E);
  static const Color _textPrimary = Colors.white;
  static const Color _textSecondary = Color(0xFFA7A7A7);
  static const Color _border = Color(0x1AFFFFFF);
  static const Color _accent = Color(0xFFFFA000);
  static const Color _accentDeep = Color(0xFFF4511E);

  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  String? _selectedPropertyId;
  String? _selectedCategory;
  String? _selectedPriority;

  final List<String> _categories = [
    'Plumbing',
    'Electrical',
    'Heating',
    'Appliances',
    'General',
  ];

  final List<String> _priorities = ['Low', 'Medium', 'High', 'Emergency'];

  // Helper method to convert display names to internal values
  String _getCategoryValue(String displayName) {
    switch (displayName) {
      case 'Plumbing':
        return 'plumbing';
      case 'Electrical':
        return 'electrical';
      case 'Heating':
        return 'heating';
      case 'Appliances':
        return 'appliances';
      case 'General':
      default:
        return 'other';
    }
  }

  String _getPriorityValue(String displayName) {
    switch (displayName) {
      case 'Low':
        return 'low';
      case 'Medium':
        return 'medium';
      case 'High':
        return 'high';
      case 'Emergency':
        return 'urgent';
      default:
        return 'medium';
    }
  }

  @override
  void initState() {
    super.initState();
    _selectedPropertyId = widget.propertyId;
    _selectedCategory = _categories.first;
    _selectedPriority = _priorities[1]; // Default to Medium
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final properties = ref.watch(tenantPropertiesProvider);
    final l10n = AppLocalizations.of(context);

    return Scaffold(
      extendBody: true,
      backgroundColor: Colors.transparent,
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [_bgStart, _bgEnd],
          ),
        ),
        child: SafeArea(
          child: GestureDetector(
            behavior: HitTestBehavior.translucent,
            onTap: () => FocusManager.instance.primaryFocus?.unfocus(),
            child: Stack(
              children: [
                // Atmospheric glow blob (top-left)
                Positioned(
                  top: -180,
                  left: -160,
                  child: IgnorePointer(
                    child: Container(
                      width: 420,
                      height: 420,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: RadialGradient(
                          colors: [
                            const Color(0xFF6D28D9).withValues(alpha: 0.22),
                            const Color(0xFF2563EB).withValues(alpha: 0.14),
                            Colors.transparent,
                          ],
                          stops: const [0.0, 0.55, 1.0],
                        ),
                      ),
                    ),
                  ),
                ),

                SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(20, 16, 20, 120),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // Nav
                      Align(
                        alignment: Alignment.centerLeft,
                        child: _BackButtonCircle(onTap: () => context.pop()),
                      ),
                      const SizedBox(height: 16),

                      // Header card
                      const BentoCard(
                        child: Row(
                          children: [
                            _GlassIconBubble(
                              icon: Icons.handyman_outlined,
                            ),
                            SizedBox(width: 14),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'New Request',
                                    style: TextStyle(
                                      fontSize: 20,
                                      fontWeight: FontWeight.w800,
                                      color: _textPrimary,
                                    ),
                                  ),
                                  SizedBox(height: 4),
                                  Text(
                                    'Report an issue with your property.',
                                    style: TextStyle(
                                      fontSize: 13,
                                      fontWeight: FontWeight.w500,
                                      color: _textSecondary,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),

                      // Inputs
                      BentoCard(
                        child: Form(
                          key: _formKey,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              const _SectionLabel('Property'),
                              const SizedBox(height: 10),
                              properties.when(
                                data: (propertyList) =>
                                    _PremiumDropdown<String>(
                                  initialValue: _selectedPropertyId,
                                  hintText: 'Select a property',
                                  items: propertyList
                                      .map(
                                        (property) => DropdownMenuItem<String>(
                                          value: property.id,
                                          child: Text(
                                            '${property.address.street}, ${property.address.city}',
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                        ),
                                      )
                                      .toList(),
                                  onChanged: (value) {
                                    setState(() => _selectedPropertyId = value);
                                  },
                                ),
                                loading: () => const Center(
                                  child: Padding(
                                    padding: EdgeInsets.symmetric(vertical: 12),
                                    child: CircularProgressIndicator(
                                        color: _accent),
                                  ),
                                ),
                                error: (error, _) => Text(
                                  'Error loading properties: $error',
                                  style:
                                      const TextStyle(color: Colors.redAccent),
                                ),
                              ),
                              const SizedBox(height: 18),
                              const _SectionLabel('Issue Title'),
                              const SizedBox(height: 10),
                              _PremiumTextField(
                                controller: _titleController,
                                hintText: 'Brief title for the issue',
                                validator: (value) {
                                  if (value == null || value.isEmpty) {
                                    return 'Please enter a title';
                                  }
                                  return null;
                                },
                              ),
                              const SizedBox(height: 18),
                              const _SectionLabel('Category'),
                              const SizedBox(height: 10),
                              _PremiumDropdown<String>(
                                initialValue: _selectedCategory,
                                hintText: 'Select a category',
                                items: _categories
                                    .map(
                                      (category) => DropdownMenuItem<String>(
                                        value: category,
                                        child: Text(category),
                                      ),
                                    )
                                    .toList(),
                                onChanged: (value) {
                                  setState(() => _selectedCategory = value);
                                },
                              ),
                              const SizedBox(height: 18),
                              const _SectionLabel('Description'),
                              const SizedBox(height: 10),
                              _PremiumTextField(
                                controller: _descriptionController,
                                hintText: 'Describe the issue in detail...',
                                minLines: 4,
                                maxLines: 6,
                                validator: (value) {
                                  if (value == null || value.isEmpty) {
                                    return 'Please enter a description';
                                  }
                                  return null;
                                },
                              ),
                              const SizedBox(height: 18),
                              const _SectionLabel('Priority'),
                              const SizedBox(height: 10),
                              _PremiumPriorityChips(
                                value: _selectedPriority,
                                onChanged: (next) {
                                  setState(() => _selectedPriority = next);
                                },
                              ),
                              const SizedBox(height: 22),
                              _GlowGradientButton(
                                label: l10n?.submitRequest ?? 'Submit Request',
                                onTap: _submitRequest,
                              ),
                            ],
                          ),
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
    );
  }

  Future<void> _submitRequest() async {
    if (_formKey.currentState!.validate()) {
      if (_selectedPropertyId == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(AppLocalizations.of(context)!.pleaseSelectProperty),
            backgroundColor: Colors.redAccent,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
          ),
        );
        return;
      }

      try {
        // Show loading indicator
        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (context) => Center(
            child: BentoCard(
              padding: const EdgeInsets.all(18),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: const [
                  CircularProgressIndicator(color: _accent),
                  SizedBox(height: 14),
                  Text(
                    'Submitting request...',
                    style: TextStyle(color: _textPrimary, fontSize: 14),
                  ),
                ],
              ),
            ),
          ),
        );

        final maintenanceService = ref.read(maintenanceServiceProvider);
        final currentUser = ref.read(currentUserProvider);
        final properties = ref.read(tenantPropertiesProvider);

        if (currentUser?.id == null) {
          throw Exception('User not authenticated');
        }

        // Get the selected property to extract landlord ID
        String? landlordId;
        properties.whenData((propertyList) {
          final selectedProperty = propertyList.firstWhere(
            (property) => property.id == _selectedPropertyId,
            orElse: () => throw Exception('Selected property not found'),
          );
          landlordId = selectedProperty.landlordId;
        });

        if (landlordId == null) {
          throw Exception('Could not determine property landlord');
        }

        final request = MaintenanceRequest(
          id: '', // Will be set by backend
          propertyId: _selectedPropertyId!,
          tenantId: currentUser!.id,
          landlordId: landlordId!,
          title: _titleController.text.trim(),
          description: _descriptionController.text.trim(),
          category: _getCategoryValue(_selectedCategory!),
          priority: _getPriorityValue(_selectedPriority!),
          status: 'pending',
          location: '',
          requestedDate: DateTime.now(),
        );

        await maintenanceService.createMaintenanceRequest(request);

        // Close loading dialog
        if (context.mounted) {
          Navigator.of(context).pop();

          // Refresh maintenance requests providers to show the new request
          ref.invalidate(tenantMaintenanceRequestsProvider);
          ref.invalidate(landlordMaintenanceRequestsProvider);

          // Show success message and navigate back
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(AppLocalizations.of(context)!
                  .maintenanceRequestSubmittedSuccessfully),
              backgroundColor: Colors.green,
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
          );

          context.pop();
        }
      } catch (e) {
        // Close loading dialog
        if (context.mounted) {
          Navigator.of(context).pop();

          // Show error message
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                  '${AppLocalizations.of(context)!.failedToSubmitRequest}: $e'),
              backgroundColor: Colors.redAccent,
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
          );
        }
      }
    }
  }
}

class BentoCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry padding;

  const BentoCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(20),
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: padding,
      decoration: BoxDecoration(
        color: _SubmitMaintenanceRequestScreenState._cardBg,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: _SubmitMaintenanceRequestScreenState._border,
          width: 1,
        ),
      ),
      child: child,
    );
  }
}

class _BackButtonCircle extends StatelessWidget {
  final VoidCallback onTap;
  const _BackButtonCircle({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(18),
      child: Container(
        width: 44,
        height: 44,
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: Colors.white.withValues(alpha: 0.12),
            width: 1,
          ),
        ),
        child: const Icon(
          Icons.arrow_back_ios_new,
          size: 18,
          color: _SubmitMaintenanceRequestScreenState._textPrimary,
        ),
      ),
    );
  }
}

class _SectionLabel extends StatelessWidget {
  final String text;
  const _SectionLabel(this.text);

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: const TextStyle(
        fontSize: 14,
        fontWeight: FontWeight.w700,
        color: _SubmitMaintenanceRequestScreenState._textPrimary,
      ),
    );
  }
}

class _PremiumTextField extends StatelessWidget {
  final TextEditingController controller;
  final String hintText;
  final int? minLines;
  final int maxLines;
  final String? Function(String?)? validator;

  const _PremiumTextField({
    required this.controller,
    required this.hintText,
    this.minLines,
    this.maxLines = 1,
    this.validator,
  });

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      minLines: minLines,
      maxLines: maxLines,
      validator: validator,
      style: const TextStyle(
          color: _SubmitMaintenanceRequestScreenState._textPrimary),
      cursorColor: _SubmitMaintenanceRequestScreenState._accent,
      decoration: InputDecoration(
        hintText: hintText,
        hintStyle: const TextStyle(
          color: _SubmitMaintenanceRequestScreenState._textSecondary,
          fontWeight: FontWeight.w500,
        ),
        filled: true,
        fillColor: _SubmitMaintenanceRequestScreenState._fieldBg,
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(
            color: _SubmitMaintenanceRequestScreenState._accent
                .withValues(alpha: 0.55),
            width: 1.2,
          ),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: Colors.redAccent),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: Colors.redAccent, width: 1.5),
        ),
      ),
    );
  }
}

class _PremiumDropdown<T> extends StatelessWidget {
  final T? initialValue;
  final String hintText;
  final List<DropdownMenuItem<T>> items;
  final ValueChanged<T?> onChanged;

  const _PremiumDropdown({
    required this.initialValue,
    required this.hintText,
    required this.items,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return DropdownButtonFormField<T>(
      initialValue: initialValue,
      items: items,
      onChanged: onChanged,
      dropdownColor: _SubmitMaintenanceRequestScreenState._fieldBg,
      iconEnabledColor: _SubmitMaintenanceRequestScreenState._textSecondary,
      style: const TextStyle(
          color: _SubmitMaintenanceRequestScreenState._textPrimary),
      decoration: InputDecoration(
        filled: true,
        fillColor: _SubmitMaintenanceRequestScreenState._fieldBg,
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        hintText: hintText,
        hintStyle: const TextStyle(
          color: _SubmitMaintenanceRequestScreenState._textSecondary,
          fontWeight: FontWeight.w500,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(
            color: _SubmitMaintenanceRequestScreenState._accent
                .withValues(alpha: 0.55),
            width: 1.2,
          ),
        ),
      ),
    );
  }
}

class _PremiumPriorityChips extends StatelessWidget {
  final String? value;
  final ValueChanged<String> onChanged;

  const _PremiumPriorityChips({required this.value, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    final entries = <_PriorityEntry>[
      const _PriorityEntry(
        label: 'Low',
        borderColor: Color(0xFF22C55E),
      ),
      const _PriorityEntry(
        label: 'Medium',
        borderColor: _SubmitMaintenanceRequestScreenState._accent,
      ),
      const _PriorityEntry(
        label: 'High',
        borderColor: Color(0xFFF97316),
      ),
      const _PriorityEntry(
        label: 'Emergency',
        borderColor: Color(0xFFEF4444),
      ),
    ];

    return Wrap(
      spacing: 10,
      runSpacing: 10,
      children: entries.map((entry) {
        final bool selected = value == entry.label;
        final Color bg = selected ? Colors.transparent : Colors.transparent;
        final Color text = selected ? Colors.white : const Color(0xFF9A9A9A);
        final Color border = selected
            ? Colors.transparent
            : entry.borderColor.withValues(alpha: 0.65);

        final Gradient? selectedGradient = entry.label == 'Emergency'
            ? null
            : const LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  _SubmitMaintenanceRequestScreenState._accent,
                  _SubmitMaintenanceRequestScreenState._accentDeep,
                ],
              );

        final Color? selectedSolid =
            entry.label == 'Emergency' ? const Color(0xFFEF4444) : null;

        return InkWell(
          onTap: () => onChanged(entry.label),
          borderRadius: BorderRadius.circular(999),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color: selected ? selectedSolid : bg,
              gradient:
                  selected && selectedSolid == null ? selectedGradient : null,
              borderRadius: BorderRadius.circular(999),
              border: Border.all(color: border, width: 1),
            ),
            child: Text(
              entry.label,
              style: TextStyle(
                color: text,
                fontWeight: FontWeight.w700,
                fontSize: 12,
              ),
            ),
          ),
        );
      }).toList(),
    );
  }
}

class _PriorityEntry {
  final String label;
  final Color borderColor;

  const _PriorityEntry({
    required this.label,
    required this.borderColor,
  });
}

class _GlowGradientButton extends StatelessWidget {
  final String label;
  final VoidCallback onTap;

  const _GlowGradientButton({required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            begin: Alignment.centerLeft,
            end: Alignment.centerRight,
            colors: [
              _SubmitMaintenanceRequestScreenState._accent,
              _SubmitMaintenanceRequestScreenState._accentDeep,
            ],
          ),
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(
              color: _SubmitMaintenanceRequestScreenState._accent
                  .withValues(alpha: 0.28),
              blurRadius: 18,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: Center(
          child: Text(
            label,
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w800,
              fontSize: 15,
            ),
          ),
        ),
      ),
    );
  }
}

class _GlassIconBubble extends StatelessWidget {
  final IconData icon;
  const _GlassIconBubble({required this.icon});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 46,
      height: 46,
      decoration: BoxDecoration(
        color: _SubmitMaintenanceRequestScreenState._accent
            .withValues(alpha: 0.18),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: _SubmitMaintenanceRequestScreenState._accent
              .withValues(alpha: 0.28),
          width: 1,
        ),
      ),
      child: Icon(
        icon,
        size: 22,
        color: _SubmitMaintenanceRequestScreenState._accent,
      ),
    );
  }
}
