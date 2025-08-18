import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../../l10n/app_localizations.dart';
import '../../../../core/providers/dynamic_colors_provider.dart';
import '../../../../core/widgets/common_bottom_nav.dart';
import '../../../services/domain/models/service.dart' as ServiceModel;
import '../../../services/presentation/providers/service_providers.dart';
import '../../../auth/presentation/providers/auth_provider.dart';

// UI Service model for landlord setup
class LandlordService {
  final String id;
  final String name;
  final String description;
  final String category;
  final double price;
  final String provider;
  final String contactInfo;
  final String schedule;
  final bool isActive;

  LandlordService({
    required this.id,
    required this.name,
    required this.description,
    required this.category,
    required this.price,
    required this.provider,
    required this.contactInfo,
    required this.schedule,
    this.isActive = true,
  });

  factory LandlordService.fromServiceModel(ServiceModel.Service service) {
    return LandlordService(
      id: service.id,
      name: service.name,
      description: service.description,
      category: service.category,
      price: service.price,
      provider: service.contactInfo.split('\n').first, // Extract provider name from contact info
      contactInfo: service.contactInfo,
      schedule: 'As needed', // Default schedule since backend doesn't have this field
      isActive: service.availability == 'available',
    );
  }

  ServiceModel.Service toServiceModel(String landlordId) {
    return ServiceModel.Service(
      id: id,
      name: name,
      description: description,
      category: category,
      availability: isActive ? 'available' : 'unavailable',
      landlordId: landlordId,
      price: price,
      contactInfo: contactInfo,
    );
  }
}

class LandlordServicesSetupPage extends ConsumerStatefulWidget {
  const LandlordServicesSetupPage({super.key});

  @override
  ConsumerState<LandlordServicesSetupPage> createState() => _LandlordServicesSetupPageState();
}

class _LandlordServicesSetupPageState extends ConsumerState<LandlordServicesSetupPage> {
  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final colors = ref.watch(dynamicColorsProvider);
    final user = ref.watch(currentUserProvider);
    
    if (user == null) {
      return Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }
    
    final servicesAsync = ref.watch(landlordServicesProvider);
    
    return Scaffold(
      backgroundColor: colors.primaryBackground,
      appBar: AppBar(
        title: Text('Manage Services'),
        backgroundColor: colors.surfaceCards,
        foregroundColor: colors.textPrimary,
        elevation: 0,
      ),
      body: servicesAsync.when(
        data: (services) {
          final landlordServices = services.map((s) => LandlordService.fromServiceModel(s)).toList();
          
          return Column(
            children: [
              _buildHeader(colors),
              Expanded(
                child: landlordServices.isEmpty 
                  ? _buildEmptyState(l10n, colors)
                  : _buildServicesList(landlordServices, l10n, colors),
              ),
            ],
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stack) => Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.error_outline, size: 64, color: colors.error),
              const SizedBox(height: 16),
              Text(
                'Error loading services',
                style: TextStyle(fontSize: 18, color: colors.textPrimary),
              ),
              const SizedBox(height: 8),
              Text(
                error.toString(),
                style: TextStyle(fontSize: 14, color: colors.textSecondary),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () => ref.invalidate(landlordServicesProvider),
                child: Text('Retry'),
              ),
            ],
          ),
        ),
      ),
      floatingActionButton: _buildFAB(colors),
      bottomNavigationBar: const CommonBottomNav(),
    );
  }

  Widget _buildHeader(DynamicAppColors colors) {
    return Container(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      colors.luxuryGold.withValues(alpha: 0.2),
                      colors.luxuryGold.withValues(alpha: 0.1),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(
                  Icons.business_center_outlined,
                  color: colors.luxuryGold,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  'Manage Services',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: colors.textPrimary,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            'Set up and manage services that your tenants can book. Add service providers, set pricing, and control availability.',
            style: TextStyle(
              fontSize: 13,
              color: colors.textSecondary,
              height: 1.3,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildServicesList(List<LandlordService> services, AppLocalizations l10n, DynamicAppColors colors) {
    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      itemCount: services.length,
      itemBuilder: (context, index) {
        return Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: _buildServiceCard(services[index], l10n, colors),
        );
      },
    );
  }

  Widget _buildServiceCard(LandlordService service, AppLocalizations l10n, DynamicAppColors colors) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            colors.surfaceCards,
            colors.luxuryGradientStart,
          ],
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: colors.borderLight),
        boxShadow: [
          BoxShadow(
            color: colors.primaryAccent.withValues(alpha: 0.1),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        colors.primaryAccent.withValues(alpha: 0.2),
                        colors.primaryAccent.withValues(alpha: 0.1),
                      ],
                    ),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    _getIconForCategory(service.category),
                    color: colors.primaryAccent,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        service.name,
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: colors.textPrimary,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 2),
                      Text(
                        service.provider,
                        style: TextStyle(
                          fontSize: 13,
                          color: colors.textSecondary,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                PopupMenuButton<String>(
                  icon: Icon(Icons.more_vert, color: colors.textSecondary, size: 18),
                  onSelected: (value) => _handleServiceAction(value, service),
                  itemBuilder: (context) => [
                    PopupMenuItem(
                      value: 'edit',
                      child: Row(
                        children: [
                          Icon(Icons.edit_outlined, size: 18),
                          SizedBox(width: 10),
                          Text('Edit'),
                        ],
                      ),
                    ),
                    PopupMenuItem(
                      value: 'toggle',
                      child: Row(
                        children: [
                          Icon(
                            service.isActive ? Icons.visibility_off_outlined : Icons.visibility_outlined,
                            size: 18,
                          ),
                          SizedBox(width: 10),
                          Text(service.isActive ? 'Disable' : 'Enable'),
                        ],
                      ),
                    ),
                    PopupMenuItem(
                      value: 'delete',
                      child: Row(
                        children: [
                          Icon(Icons.delete_outline, size: 18, color: colors.error),
                          SizedBox(width: 10),
                          Text('Delete', style: TextStyle(color: colors.error)),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              service.description,
              style: TextStyle(
                fontSize: 13,
                color: colors.textSecondary,
                height: 1.3,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: service.isActive ? colors.success.withValues(alpha: 0.1) : colors.warning.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: service.isActive ? colors.success.withValues(alpha: 0.3) : colors.warning.withValues(alpha: 0.3),
                    ),
                  ),
                  child: Text(
                    service.isActive ? 'Active' : 'Inactive',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: service.isActive ? colors.success : colors.warning,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: colors.primaryAccent.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: colors.primaryAccent.withValues(alpha: 0.3)),
                  ),
                  child: Text(
                    'CHF ${service.price.toStringAsFixed(0)}',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: colors.primaryAccent,
                    ),
                  ),
                ),
                const Spacer(),
                Text(
                  service.category,
                  style: TextStyle(
                    fontSize: 11,
                    color: colors.textTertiary,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState(AppLocalizations l10n, DynamicAppColors colors) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  colors.luxuryGold.withValues(alpha: 0.1),
                  colors.luxuryGold.withValues(alpha: 0.05),
                ],
              ),
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.business_center_outlined,
              size: 48,
              color: colors.luxuryGold,
            ),
          ),
          const SizedBox(height: 20),
          Text(
            'No Services Yet',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w600,
              color: colors.textPrimary,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            'Start by adding services that your tenants can book.\nThis helps you provide additional value and convenience.',
            style: TextStyle(
              fontSize: 14,
              color: colors.textSecondary,
              height: 1.4,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: () => _showAddServiceDialog(context),
            icon: const Icon(Icons.add, size: 18),
            label: const Text('Add Your First Service'),
            style: ElevatedButton.styleFrom(
              backgroundColor: colors.primaryAccent,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFAB(DynamicAppColors colors) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            colors.luxuryGold,
            colors.luxuryGold.withValues(alpha: 0.8),
          ],
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: colors.luxuryGold.withValues(alpha: 0.3),
            blurRadius: 16,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: FloatingActionButton(
        onPressed: () {
          HapticFeedback.mediumImpact();
          _showAddServiceDialog(context);
        },
        backgroundColor: Colors.transparent,
        elevation: 0,
        child: const Icon(
          Icons.add,
          color: Colors.white,
          size: 28,
        ),
      ),
    );
  }

  IconData _getIconForCategory(String category) {
    switch (category.toLowerCase()) {
      case 'maintenance':
        return Icons.build_outlined;
      case 'cleaning':
        return Icons.cleaning_services_outlined;
      case 'repair':
        return Icons.handyman_outlined;
      default:
        return Icons.room_service_outlined;
    }
  }

  void _handleServiceAction(String action, LandlordService service) {
    switch (action) {
      case 'edit':
        _showEditServiceDialog(context, service);
        break;
      case 'toggle':
        _toggleServiceStatus(service);
        break;
      case 'delete':
        _showDeleteConfirmation(context, service);
        break;
    }
  }

  void _toggleServiceStatus(LandlordService service) async {
    final colors = ref.read(dynamicColorsProvider);
    final user = ref.read(currentUserProvider);
    
    if (user == null) return;
    
    try {
      final updatedService = service.toServiceModel(user.id).copyWith(
        availability: service.isActive ? 'unavailable' : 'available',
      );
      
      await ref.read(serviceNotifierProvider.notifier).updateService(updatedService);
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            '${service.name} ${service.isActive ? 'disabled' : 'enabled'}',
          ),
          backgroundColor: colors.success,
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error updating service: $e'),
          backgroundColor: colors.error,
        ),
      );
    }
  }

  void _showDeleteConfirmation(BuildContext context, LandlordService service) {
    final colors = ref.read(dynamicColorsProvider);
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text('Service löschen'),
        content: Text(
          'Are you sure you want to delete "${service.name}"? This action cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              try {
                await ref.read(serviceNotifierProvider.notifier).deleteService(service.id);
                Navigator.of(context).pop();
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Service gelöscht'),
                    backgroundColor: colors.success,
                  ),
                );
              } catch (e) {
                Navigator.of(context).pop();
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Error deleting service: $e'),
                    backgroundColor: colors.error,
                  ),
                );
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: colors.error,
              foregroundColor: Colors.white,
            ),
            child: Text('Delete'),
          ),
        ],
      ),
    );
  }

  void _showAddServiceDialog(BuildContext context) {
    _showServiceDialog(context, null);
  }

  void _showEditServiceDialog(BuildContext context, LandlordService service) {
    _showServiceDialog(context, service);
  }

  void _showServiceDialog(BuildContext context, LandlordService? service) {
    final colors = ref.read(dynamicColorsProvider);
    final user = ref.read(currentUserProvider);
    final isEditing = service != null;
    final formKey = GlobalKey<FormState>();
    
    if (user == null) return;
    
    String name = service?.name ?? '';
    String description = service?.description ?? '';
    String category = service?.category ?? 'maintenance';
    double price = service?.price ?? 0.0;
    String provider = service?.provider ?? '';
    String contactInfo = service?.contactInfo ?? '';

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(isEditing ? 'Edit Service' : 'Add Service'),
        content: SingleChildScrollView(
          child: Form(
            key: formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextFormField(
                  initialValue: name,
                  decoration: InputDecoration(
                    labelText: 'Service Name',
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                  validator: (value) => value?.isEmpty ?? true ? 'Required' : null,
                  onSaved: (value) => name = value ?? '',
                ),
                const SizedBox(height: 16),
                TextFormField(
                  initialValue: description,
                  decoration: InputDecoration(
                    labelText: 'Description',
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                  maxLines: 2,
                  validator: (value) => value?.isEmpty ?? true ? 'Required' : null,
                  onSaved: (value) => description = value ?? '',
                ),
                const SizedBox(height: 16),
                DropdownButtonFormField<String>(
                  value: category,
                  decoration: InputDecoration(
                    labelText: 'Category',
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                  items: [
                    DropdownMenuItem(value: 'maintenance', child: Text('Maintenance')),
                    DropdownMenuItem(value: 'cleaning', child: Text('Cleaning')),
                    DropdownMenuItem(value: 'repair', child: Text('Repair')),
                    DropdownMenuItem(value: 'general', child: Text('General')),
                  ],
                  onChanged: (value) => category = value ?? 'maintenance',
                ),
                const SizedBox(height: 16),
                TextFormField(
                  initialValue: provider,
                  decoration: InputDecoration(
                    labelText: 'Provider Name',
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                  validator: (value) => value?.isEmpty ?? true ? 'Required' : null,
                  onSaved: (value) => provider = value ?? '',
                ),
                const SizedBox(height: 16),
                TextFormField(
                  initialValue: contactInfo,
                  decoration: InputDecoration(
                    labelText: 'Contact Information',
                    hintText: 'Phone, email, or other contact details',
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                  maxLines: 2,
                  validator: (value) => value?.isEmpty ?? true ? 'Required' : null,
                  onSaved: (value) => contactInfo = value ?? '',
                ),
                const SizedBox(height: 16),
                TextFormField(
                  initialValue: price > 0 ? price.toString() : '',
                  decoration: InputDecoration(
                    labelText: 'Price (CHF)',
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                  keyboardType: TextInputType.number,
                  validator: (value) {
                    if (value?.isEmpty ?? true) return 'Required';
                    if (double.tryParse(value!) == null) return 'Invalid number';
                    return null;
                  },
                  onSaved: (value) => price = double.tryParse(value!) ?? 0.0,
                ),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              if (formKey.currentState?.validate() ?? false) {
                formKey.currentState?.save();
                
                try {
                  final serviceModel = ServiceModel.Service(
                    id: service?.id ?? '',
                    name: name,
                    description: description,
                    category: category,
                    availability: 'available',
                    landlordId: user.id,
                    price: price,
                    contactInfo: '$provider\n$contactInfo',
                  );

                  if (isEditing) {
                    await ref.read(serviceNotifierProvider.notifier).updateService(serviceModel);
                  } else {
                    await ref.read(serviceNotifierProvider.notifier).createService(serviceModel);
                  }

                  Navigator.of(context).pop();
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(isEditing ? 'Service updated' : 'Service added'),
                      backgroundColor: colors.success,
                    ),
                  );
                } catch (e) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Error: $e'),
                      backgroundColor: colors.error,
                    ),
                  );
                }
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: colors.primaryAccent,
              foregroundColor: Colors.white,
            ),
            child: Text(isEditing ? 'Update' : 'Add'),
          ),
        ],
      ),
    );
  }
}
