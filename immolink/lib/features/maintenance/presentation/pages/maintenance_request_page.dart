import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:immolink/features/auth/presentation/providers/auth_provider.dart';
import 'package:immolink/features/maintenance/domain/models/maintenance_request.dart';
import 'package:immolink/features/maintenance/presentation/providers/maintenance_providers.dart';
import 'package:immolink/features/property/presentation/providers/property_providers.dart';
import '../../../../core/theme/app_colors.dart';

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

    return Scaffold(
      backgroundColor: Colors.white,
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
                      color: Colors.white.withValues(alpha: 0.9),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: Colors.grey.withValues(alpha: 0.2),
                        width: 1,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.1),
                          blurRadius: 10,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: IconButton(
                      onPressed: () => context.pop(),
                      icon: const Icon(
                        Icons.arrow_back_ios_new,
                        color: AppColors.textPrimary,
                        size: 20,
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  const Expanded(
                    child: Text(
                      'Maintenance Request',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textPrimary,
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
                        color: Colors.white.withValues(alpha: 0.8),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: Colors.grey.withValues(alpha: 0.2),
                          width: 1,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.05),
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
                                  AppColors.primaryAccent.withValues(alpha: 0.1),
                                  AppColors.primaryAccent.withValues(alpha: 0.05),
                                ],
                              ),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: AppColors.primaryAccent.withValues(alpha: 0.2),
                                width: 1,
                              ),
                            ),
                            child: Icon(
                              Icons.build_circle_outlined,
                              color: AppColors.primaryAccent,
                              size: 24,
                            ),
                          ),
                          const SizedBox(width: 16),
                          const Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Submit Request',
                                  style: TextStyle(
                                    fontSize: 20,
                                    fontWeight: FontWeight.bold,
                                    color: AppColors.textPrimary,
                                  ),
                                ),
                                SizedBox(height: 4),
                                Text(
                                  'Describe your maintenance issue',
                                  style: TextStyle(
                                    fontSize: 14,
                                    color: AppColors.textSecondary,
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
                        color: Colors.white.withValues(alpha: 0.8),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: Colors.grey.withValues(alpha: 0.2),
                          width: 1,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.05),
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
                            const Text(
                              'Property',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                                color: AppColors.textPrimary,
                              ),
                            ),
                            const SizedBox(height: 12),
                            properties.when(
                              data: (propertyList) => Container(
                                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                                decoration: BoxDecoration(
                                  color: Colors.white.withValues(alpha: 0.7),
                                  border: Border.all(
                                    color: Colors.grey.withValues(alpha: 0.3),
                                    width: 1,
                                  ),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: DropdownButtonHideUnderline(
                                  child: DropdownButton<String>(
                                    value: _selectedPropertyId,
                                    hint: const Text(
                                      'Select a property',
                                      style: TextStyle(color: AppColors.textSecondary),
                                    ),
                                    isExpanded: true,
                                    style: const TextStyle(color: AppColors.textPrimary),
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
                                  style: const TextStyle(color: AppColors.error),
                                ),
                              ),
                            ),
                            const SizedBox(height: 20),

                            // Title Field
                            const Text(
                              'Title',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                                color: AppColors.textPrimary,
                              ),
                            ),
                            const SizedBox(height: 12),
                            TextFormField(
                              controller: _titleController,
                              style: const TextStyle(color: AppColors.textPrimary),
                              decoration: InputDecoration(
                                hintText: 'Brief title for the issue',
                                hintStyle: TextStyle(
                                  color: AppColors.textSecondary.withValues(alpha: 0.7),
                                ),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  borderSide: BorderSide(
                                    color: Colors.grey.withValues(alpha: 0.3),
                                  ),
                                ),
                                enabledBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  borderSide: BorderSide(
                                    color: Colors.grey.withValues(alpha: 0.3),
                                  ),
                                ),
                                focusedBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  borderSide: const BorderSide(
                                    color: AppColors.primaryAccent,
                                    width: 2,
                                  ),
                                ),
                                filled: true,
                                fillColor: Colors.white.withValues(alpha: 0.7),
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
                            const Text(
                              'Category',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                                color: AppColors.textPrimary,
                              ),
                            ),
                            const SizedBox(height: 12),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                              decoration: BoxDecoration(
                                color: Colors.white.withValues(alpha: 0.7),
                                border: Border.all(
                                  color: Colors.grey.withValues(alpha: 0.3),
                                  width: 1,
                                ),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: DropdownButtonHideUnderline(
                                child: DropdownButton<String>(
                                  value: _selectedCategory,
                                  isExpanded: true,
                                  style: const TextStyle(color: AppColors.textPrimary),
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
                            const Text(
                              'Priority',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                                color: AppColors.textPrimary,
                              ),
                            ),
                            const SizedBox(height: 12),
                            Wrap(
                              spacing: 8,
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
                                  backgroundColor: Colors.white.withValues(alpha: 0.7),
                                  selectedColor: chipColor.withValues(alpha: 0.2),
                                  checkmarkColor: chipColor,
                                  labelStyle: TextStyle(
                                    color: isSelected ? chipColor : AppColors.textPrimary,
                                    fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                                  ),
                                  side: BorderSide(
                                    color: isSelected ? chipColor : Colors.grey.withValues(alpha: 0.3),
                                    width: 1,
                                  ),
                                );
                              }).toList(),
                            ),
                            const SizedBox(height: 20),

                            // Location Field
                            const Text(
                              'Location in Property',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                                color: AppColors.textPrimary,
                              ),
                            ),
                            const SizedBox(height: 12),
                            TextFormField(
                              controller: _locationController,
                              style: const TextStyle(color: AppColors.textPrimary),
                              decoration: InputDecoration(
                                hintText: 'e.g., Kitchen, Bathroom, Living Room',
                                hintStyle: TextStyle(
                                  color: AppColors.textSecondary.withValues(alpha: 0.7),
                                ),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  borderSide: BorderSide(
                                    color: Colors.grey.withValues(alpha: 0.3),
                                  ),
                                ),
                                enabledBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  borderSide: BorderSide(
                                    color: Colors.grey.withValues(alpha: 0.3),
                                  ),
                                ),
                                focusedBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  borderSide: const BorderSide(
                                    color: AppColors.primaryAccent,
                                    width: 2,
                                  ),
                                ),
                                filled: true,
                                fillColor: Colors.white.withValues(alpha: 0.7),
                                contentPadding: const EdgeInsets.all(16),
                              ),
                            ),
                            const SizedBox(height: 20),

                            // Description Field
                            const Text(
                              'Description',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                                color: AppColors.textPrimary,
                              ),
                            ),
                            const SizedBox(height: 12),
                            TextFormField(
                              controller: _descriptionController,
                              style: const TextStyle(color: AppColors.textPrimary),
                              maxLines: 4,
                              decoration: InputDecoration(
                                hintText: 'Describe the maintenance issue in detail...',
                                hintStyle: TextStyle(
                                  color: AppColors.textSecondary.withValues(alpha: 0.7),
                                ),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  borderSide: BorderSide(
                                    color: Colors.grey.withValues(alpha: 0.3),
                                  ),
                                ),
                                enabledBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  borderSide: BorderSide(
                                    color: Colors.grey.withValues(alpha: 0.3),
                                  ),
                                ),
                                focusedBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  borderSide: const BorderSide(
                                    color: AppColors.primaryAccent,
                                    width: 2,
                                  ),
                                ),
                                filled: true,
                                fillColor: Colors.white.withValues(alpha: 0.7),
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
                                    AppColors.primaryAccent,
                                    AppColors.primaryAccent.withValues(alpha: 0.8),
                                  ],
                                ),
                                borderRadius: BorderRadius.circular(12),
                                boxShadow: [
                                  BoxShadow(
                                    color: AppColors.primaryAccent.withValues(alpha: 0.3),
                                    blurRadius: 15,
                                    offset: const Offset(0, 4),
                                  ),
                                ],
                              ),
                              child: ElevatedButton(
                                onPressed: _submitRequest,
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

  void _submitRequest() async {
    if (_formKey.currentState!.validate()) {
      if (_selectedPropertyId == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Please select a property'),
            backgroundColor: AppColors.error,
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
                color: Colors.white,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  CircularProgressIndicator(
                    valueColor: AlwaysStoppedAnimation<Color>(AppColors.primaryAccent),
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'Submitting request...',
                    style: TextStyle(
                      color: AppColors.textPrimary,
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

        if (currentUser?.id == null) {
          throw Exception('User not authenticated');
        }

        final request = MaintenanceRequest(
          id: '', // Will be set by backend
          propertyId: _selectedPropertyId!,
          tenantId: currentUser!.id,
          landlordId: '', // Will be set by backend
          title: _titleController.text.trim(),
          description: _descriptionController.text.trim(),
          category: _selectedCategory!,
          priority: _selectedPriority!,
          status: 'pending',
          location: _locationController.text.trim(),
          requestedDate: DateTime.now(),
        );

        await maintenanceService.createMaintenanceRequest(request);

        // Close loading dialog
        if (context.mounted) {
          Navigator.of(context).pop();
          
          // Show success message and navigate back
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: const Text('Maintenance request submitted successfully'),
              backgroundColor: AppColors.success,
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
              content: Text('Failed to submit request: $e'),
              backgroundColor: AppColors.error,
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
