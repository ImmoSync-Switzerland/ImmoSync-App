import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../../l10n/app_localizations.dart';
import 'package:go_router/go_router.dart';
import 'package:immosync/features/auth/presentation/providers/auth_provider.dart';
import 'package:immosync/features/maintenance/domain/models/maintenance_request.dart';
import 'package:immosync/features/maintenance/presentation/providers/maintenance_providers.dart';
import 'package:immosync/features/property/presentation/providers/property_providers.dart';
import '../../../../core/providers/dynamic_colors_provider.dart';

class MaintenanceRequestPage extends ConsumerStatefulWidget {
  final String? propertyId;

  const MaintenanceRequestPage({super.key, this.propertyId});

  @override
  ConsumerState<MaintenanceRequestPage> createState() => _MaintenanceRequestPageState();
}

class _MaintenanceRequestPageState extends ConsumerState<MaintenanceRequestPage> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _locationController = TextEditingController();
  String? _selectedPropertyId;
  String? _selectedCategory;
  String? _selectedPriority;

  final List<String> _categories = [
    'Plumbing',
    'Electrical',
    'Heating/Cooling',
    'Appliance',
    'Structural',
    'Pest Control',
    'Other'
  ];

  final List<String> _priorities = [
    'Low',
    'Medium',
    'High',
    'Emergency'
  ];

  // Helper method to convert display names to internal values
  String _getCategoryValue(String displayName) {
    switch (displayName) {
      case 'Plumbing':
        return 'plumbing';
      case 'Electrical':
        return 'electrical';
      case 'Heating/Cooling':
        return 'heating';
      case 'Appliance':
        return 'appliances';
      case 'Structural':
        return 'structural';
      case 'Pest Control':
        return 'pest_control';
      case 'Other':
        return 'other';
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
    _locationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final properties = ref.watch(tenantPropertiesProvider);
    final colors = ref.watch(dynamicColorsProvider);

    return Scaffold(
      backgroundColor: colors.primaryBackground,
      body: SafeArea(
        child: Column(
          children: [
            // Custom Header with Glassmorphism
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              child: Row(
                children: [
                  Container(
                    decoration: BoxDecoration(
                      color: colors.surfaceCards,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: colors.borderLight,
                        width: 1,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: colors.shadowColor,
                          blurRadius: 10,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: IconButton(
                      onPressed: () => context.pop(),
                      icon: Icon(
                        Icons.arrow_back_ios_new,
                        color: colors.textPrimary,
                        size: 20,
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Text(
                      'Maintenance Request',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: colors.textPrimary,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            
            // Content
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Header Card with Glassmorphism
                    Container(
                      padding: const EdgeInsets.all(24),
                      decoration: BoxDecoration(
                        color: colors.surfaceCards,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: colors.borderLight,
                          width: 1,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: colors.shadowColor,
                            blurRadius: 20,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: [
                                  colors.primaryAccent.withValues(alpha: 0.1),
                                  colors.primaryAccent.withValues(alpha: 0.05),
                                ],
                              ),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: colors.primaryAccent.withValues(alpha: 0.2),
                                width: 1,
                              ),
                            ),
                            child: Icon(
                              Icons.build_circle_outlined,
                              color: colors.primaryAccent,
                              size: 24,
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Submit Request',
                                  style: TextStyle(
                                    fontSize: 20,
                                    fontWeight: FontWeight.bold,
                                    color: colors.textPrimary,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  'Describe your maintenance issue',
                                  style: TextStyle(
                                    fontSize: 14,
                                    color: colors.textSecondary,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),

                    // Form Card with Glassmorphism
                    Container(
                      padding: const EdgeInsets.all(24),
                      decoration: BoxDecoration(
                        color: colors.surfaceCards,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: colors.borderLight,
                          width: 1,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: colors.shadowColor,
                            blurRadius: 20,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Form(
                        key: _formKey,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            // Property Selection
                            Text(
                              'Property',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                                color: colors.textPrimary,
                              ),
                            ),
                            const SizedBox(height: 12),
                            properties.when(
                              data: (propertyList) => Container(
                                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                                decoration: BoxDecoration(
                                  color: colors.surfaceCards,
                                  border: Border.all(
                                    color: colors.borderLight,
                                    width: 1,
                                  ),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: DropdownButtonHideUnderline(
                                  child: DropdownButton<String>(
                                    value: _selectedPropertyId,
                                    hint: Text(
                                      'Select a property',
                                      style: TextStyle(color: colors.textSecondary),
                                    ),
                                    isExpanded: true,
                                    style: TextStyle(color: colors.textPrimary),
                                    items: propertyList.map((property) {
                                      return DropdownMenuItem<String>(
                                        value: property.id,
                                        child: Text('${property.address.street}, ${property.address.city}'),
                                      );
                                    }).toList(),
                                    onChanged: (value) {
                                      setState(() {
                                        _selectedPropertyId = value;
                                      });
                                    },
                                  ),
                                ),
                              ),
                              loading: () => Container(
                                padding: const EdgeInsets.all(16),
                                child: const Center(child: CircularProgressIndicator()),
                              ),
                              error: (error, stack) => Container(
                                padding: const EdgeInsets.all(16),
                                child: Text(
                                  'Error loading properties: $error',
                                  style: TextStyle(color: colors.error),
                                ),
                              ),
                            ),
                            const SizedBox(height: 20),

                            // Title Field
                            Text(
                              'Title',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                                color: colors.textPrimary,
                              ),
                            ),
                            const SizedBox(height: 12),
                            TextFormField(
                              controller: _titleController,
                              style: TextStyle(color: colors.textPrimary),
                              decoration: InputDecoration(
                                hintText: 'Brief title for the issue',
                                hintStyle: TextStyle(
                                  color: colors.textSecondary.withValues(alpha: 0.7),
                                ),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  borderSide: BorderSide(
                                    color: colors.borderLight,
                                  ),
                                ),
                                enabledBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  borderSide: BorderSide(
                                    color: colors.borderLight,
                                  ),
                                ),
                                focusedBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  borderSide: BorderSide(
                                    color: colors.primaryAccent,
                                    width: 2,
                                  ),
                                ),
                                filled: true,
                                fillColor: colors.surfaceCards,
                                contentPadding: const EdgeInsets.all(16),
                              ),
                              validator: (value) {
                                if (value == null || value.isEmpty) {
                                  return 'Please enter a title';
                                }
                                return null;
                              },
                            ),
                            const SizedBox(height: 20),

                            // Category Selection
                            Text(
                              'Category',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                                color: colors.textPrimary,
                              ),
                            ),
                            const SizedBox(height: 12),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                              decoration: BoxDecoration(
                                color: colors.surfaceCards,
                                border: Border.all(
                                  color: colors.borderLight,
                                  width: 1,
                                ),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: DropdownButtonHideUnderline(
                                child: DropdownButton<String>(
                                  value: _selectedCategory,
                                  isExpanded: true,
                                  style: TextStyle(color: colors.textPrimary),
                                  items: _categories.map((category) {
                                    return DropdownMenuItem<String>(
                                      value: category,
                                      child: Text(category),
                                    );
                                  }).toList(),
                                  onChanged: (value) {
                                    setState(() {
                                      _selectedCategory = value;
                                    });
                                  },
                                ),
                              ),
                            ),
                            const SizedBox(height: 20),

                            // Priority Selection
                            Text(
                              'Priority',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                                color: colors.textPrimary,
                              ),
                            ),
                            const SizedBox(height: 12),
                            Wrap(
                              spacing: 12,
                              runSpacing: 8,
                              children: _priorities.map((priority) {
                                final isSelected = _selectedPriority == priority;
                                Color chipColor;
                                switch (priority) {
                                  case 'Emergency':
                                    chipColor = Colors.red;
                                    break;
                                  case 'High':
                                    chipColor = Colors.orange;
                                    break;
                                  case 'Medium':
                                    chipColor = Colors.blue;
                                    break;
                                  case 'Low':
                                  default:
                                    chipColor = Colors.green;
                                    break;
                                }
                                return FilterChip(
                                  label: Text(priority),
                                  selected: isSelected,
                                  onSelected: (selected) {
                                    setState(() {
                                      _selectedPriority = priority;
                                    });
                                  },
                                  backgroundColor: colors.surfaceCards,
                                  selectedColor: chipColor.withValues(alpha: 0.2),
                                  checkmarkColor: chipColor,
                                  labelStyle: TextStyle(
                                    color: isSelected ? chipColor : colors.textPrimary,
                                    fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                                  ),
                                  side: BorderSide(
                                    color: isSelected ? chipColor : colors.borderLight,
                                    width: 1,
                                  ),
                                );
                              }).toList(),
                            ),
                            const SizedBox(height: 20),

                            // Location Field
                            Text(
                              'Location in Property',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                                color: colors.textPrimary,
                              ),
                            ),
                            const SizedBox(height: 12),
                            TextFormField(
                              controller: _locationController,
                              style: TextStyle(color: colors.textPrimary),
                              decoration: InputDecoration(
                                hintText: 'e.g., Kitchen, Bathroom, Living Room',
                                hintStyle: TextStyle(
                                  color: colors.textSecondary.withValues(alpha: 0.7),
                                ),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  borderSide: BorderSide(
                                    color: colors.borderLight,
                                  ),
                                ),
                                enabledBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  borderSide: BorderSide(
                                    color: colors.borderLight,
                                  ),
                                ),
                                focusedBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  borderSide: BorderSide(
                                    color: colors.primaryAccent,
                                    width: 2,
                                  ),
                                ),
                                filled: true,
                                fillColor: colors.surfaceCards,
                                contentPadding: const EdgeInsets.all(16),
                              ),
                            ),
                            const SizedBox(height: 20),

                            // Description Field
                            Text(
                              'Description',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                                color: colors.textPrimary,
                              ),
                            ),
                            const SizedBox(height: 12),
                            TextFormField(
                              controller: _descriptionController,
                              style: TextStyle(color: colors.textPrimary),
                              maxLines: 4,
                              decoration: InputDecoration(
                                hintText: 'Describe the maintenance issue in detail...',
                                hintStyle: TextStyle(
                                  color: colors.textSecondary.withValues(alpha: 0.7),
                                ),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  borderSide: BorderSide(
                                    color: colors.borderLight,
                                  ),
                                ),
                                enabledBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  borderSide: BorderSide(
                                    color: colors.borderLight,
                                  ),
                                ),
                                focusedBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  borderSide: BorderSide(
                                    color: colors.primaryAccent,
                                    width: 2,
                                  ),
                                ),
                                filled: true,
                                fillColor: colors.surfaceCards,
                                contentPadding: const EdgeInsets.all(16),
                              ),
                              validator: (value) {
                                if (value == null || value.isEmpty) {
                                  return 'Please enter a description';
                                }
                                return null;
                              },
                            ),
                            const SizedBox(height: 32),

                            // Submit Button
                            Container(
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  colors: [
                                    colors.primaryAccent,
                                    colors.primaryAccent.withValues(alpha: 0.8),
                                  ],
                                ),
                                borderRadius: BorderRadius.circular(12),
                                boxShadow: [
                                  BoxShadow(
                                    color: colors.primaryAccent.withValues(alpha: 0.3),
                                    blurRadius: 15,
                                    offset: const Offset(0, 4),
                                  ),
                                ],
                              ),
                              child: ElevatedButton(
                                onPressed: () => _submitRequest(colors),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.transparent,
                                  shadowColor: Colors.transparent,
                                  padding: const EdgeInsets.symmetric(vertical: 16),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                ),
                                child: const Text(
                                  'Submit Request',
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w600,
                                    color: Colors.white,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _submitRequest(DynamicAppColors colors) async {
    if (_formKey.currentState!.validate()) {
      if (_selectedPropertyId == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(AppLocalizations.of(context)!.pleaseSelectProperty),
            backgroundColor: colors.error,
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
            child: Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: colors.surfaceCards,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  CircularProgressIndicator(
                    valueColor: AlwaysStoppedAnimation<Color>(colors.primaryAccent),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Submitting request...',
                    style: TextStyle(
                      color: colors.textPrimary,
                      fontSize: 16,
                    ),
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
          location: _locationController.text.trim(),
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
              content: Text(AppLocalizations.of(context)!.maintenanceRequestSubmittedSuccessfully),
              backgroundColor: colors.success,
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
              content: Text('${AppLocalizations.of(context)!.failedToSubmitRequest}: $e'),
              backgroundColor: colors.error,
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
