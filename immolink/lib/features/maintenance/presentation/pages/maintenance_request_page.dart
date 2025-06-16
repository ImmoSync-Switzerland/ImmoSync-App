import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:immolink/features/auth/presentation/providers/auth_provider.dart';
import 'package:immolink/features/maintenance/domain/models/maintenance_request.dart';
import 'package:immolink/features/maintenance/presentation/providers/maintenance_providers.dart';
import 'package:immolink/features/property/presentation/providers/property_providers.dart';

class MaintenanceRequestPage extends ConsumerStatefulWidget {
  final String? propertyId;

  const MaintenanceRequestPage({super.key, this.propertyId});

  @override
  ConsumerState<MaintenanceRequestPage> createState() => _MaintenanceRequestPageState();
}

class _MaintenanceRequestPageState extends ConsumerState<MaintenanceRequestPage> {
  final _formKey = GlobalKey<FormState>();
  final _descriptionController = TextEditingController();
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
    _descriptionController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final currentUser = ref.watch(currentUserProvider);
    final userProperties = ref.watch(tenantPropertiesProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Report Maintenance Issue'),
        flexibleSpace: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [Colors.blue.shade700, Colors.blue.shade900],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
        ),
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Colors.blue.shade50, Colors.white],
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: userProperties.when(
            data: (properties) {
              // If no properties are available
              if (properties.isEmpty) {
                return const Center(
                  child: Text(
                    'You have no properties to report maintenance for.',
                    style: TextStyle(fontSize: 18),
                  ),
                );
              }

              // If propertyId was not provided or is invalid, use the first property
              if (_selectedPropertyId == null || 
                  !properties.any((p) => p.id == _selectedPropertyId)) {
                _selectedPropertyId = properties.first.id;
              }

              return Form(
                key: _formKey,
                child: ListView(
                  children: [
                    Card(
                      elevation: 4,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Property',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 8),
                            DropdownButtonFormField<String>(
                              value: _selectedPropertyId,
                              decoration: InputDecoration(
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                contentPadding: const EdgeInsets.symmetric(
                                  horizontal: 12,
                                  vertical: 8,
                                ),
                              ),
                              items: properties.map((property) {
                                return DropdownMenuItem<String>(
                                  value: property.id,
                                  child: Text(property.address.street),
                                );
                              }).toList(),
                              onChanged: (value) {
                                setState(() {
                                  _selectedPropertyId = value;
                                });
                              },
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Card(
                      elevation: 4,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Issue Details',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 16),
                            DropdownButtonFormField<String>(
                              value: _selectedCategory,
                              decoration: InputDecoration(
                                labelText: 'Category',
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(8),
                                ),
                              ),
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
                            const SizedBox(height: 16),
                            DropdownButtonFormField<String>(
                              value: _selectedPriority,
                              decoration: InputDecoration(
                                labelText: 'Priority',
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(8),
                                ),
                              ),
                              items: _priorities.map((priority) {
                                return DropdownMenuItem<String>(
                                  value: priority,
                                  child: Text(priority),
                                );
                              }).toList(),
                              onChanged: (value) {
                                setState(() {
                                  _selectedPriority = value;
                                });
                              },
                            ),
                            const SizedBox(height: 16),
                            TextFormField(
                              controller: _descriptionController,
                              decoration: InputDecoration(
                                labelText: 'Description',
                                hintText: 'Please describe the issue in detail',
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(8),
                                ),
                              ),
                              maxLines: 5,
                              validator: (value) {
                                if (value == null || value.isEmpty) {
                                  return 'Please enter a description';
                                }
                                return null;
                              },
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton.icon(
                              onPressed: () {
                                // TODO: Implement image upload
                              },
                              icon: const Icon(Icons.photo_camera),
                              label: const Text('Add Photos'),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.grey.shade200,
                                foregroundColor: Colors.black87,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),
                    ElevatedButton(
                      onPressed: () {
                        if (_formKey.currentState!.validate()) {
                          _submitMaintenanceRequest(currentUser!.id);
                        }
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blue.shade700,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      child: const Text(
                        'Submit Request',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ],
                ),
              );
            },
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (error, stack) => Center(
              child: Text('Error loading properties: $error'),
            ),
          ),
        ),
      ),
    );
  }
  void _submitMaintenanceRequest(String tenantId) async {
    if (_selectedPropertyId == null) return;

    final maintenanceRequest = MaintenanceRequest(
      id: '', // Will be assigned by the database
      propertyId: _selectedPropertyId!,
      tenantId: tenantId,
      landlordId: '', // Will be populated by backend based on property
      title: _selectedCategory ?? 'Maintenance Request',
      description: _descriptionController.text,
      category: _selectedCategory?.toLowerCase() ?? 'other',
      priority: _selectedPriority?.toLowerCase() ?? 'medium',
      status: 'pending',
      location: 'Not specified', // Could be enhanced with a location field
      requestedDate: DateTime.now(),
    );

    try {
      ref.read(maintenanceServiceProvider).createMaintenanceRequest(maintenanceRequest);
      
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Maintenance request submitted successfully'),
          backgroundColor: Colors.green,
        ),
      );
      
      context.pop();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to submit request: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }
}

