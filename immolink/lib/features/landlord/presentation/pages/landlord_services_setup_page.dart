import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import '../../../../core/providers/dynamic_colors_provider.dart';
import '../../../../core/widgets/common_bottom_nav.dart';

// Service model for landlord setup
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
}

class LandlordServicesSetupPage extends ConsumerStatefulWidget {
  const LandlordServicesSetupPage({super.key});

  @override
  ConsumerState<LandlordServicesSetupPage> createState() => _LandlordServicesSetupPageState();
}

class _LandlordServicesSetupPageState extends ConsumerState<LandlordServicesSetupPage> {
  final List<LandlordService> _services = [
    LandlordService(
      id: '1',
      name: 'Trash Collection',
      description: 'Weekly trash and recycling pickup service',
      category: 'maintenance',
      price: 25.0,
      provider: 'City Waste Management',
      contactInfo: '(555) 123-4567',
      schedule: 'Weekly - Mondays',
    ),
    LandlordService(
      id: '2',
      name: 'Lawn Care',
      description: 'Professional lawn mowing and landscaping',
      category: 'maintenance',
      price: 45.0,
      provider: 'Green Thumb Landscaping',
      contactInfo: '(555) 234-5678',
      schedule: 'Bi-weekly - Saturdays',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    
    return Consumer(
      builder: (context, ref, child) {
        final colors = ref.watch(dynamicColorsProvider);
        
        return Scaffold(
          backgroundColor: colors.primaryBackground,
          appBar: _buildAppBar(l10n, colors),
          bottomNavigationBar: const CommonBottomNav(),
          body: SafeArea(
            child: Column(
              children: [
                _buildHeader(l10n, colors),
                Expanded(
                  child: _buildServicesList(l10n, colors),
                ),
              ],
            ),
          ),
          floatingActionButton: _buildFAB(l10n, colors),
        );
      },
    );
  }

  PreferredSizeWidget _buildAppBar(AppLocalizations l10n, DynamicAppColors colors) {
    return AppBar(
      backgroundColor: colors.primaryBackground,
      elevation: 0,
      systemOverlayStyle: SystemUiOverlayStyle.dark,
      leading: IconButton(
        icon: Icon(Icons.arrow_back_ios, color: colors.textPrimary, size: 20),
        onPressed: () {
          HapticFeedback.lightImpact();
          context.pop();
        },
      ),
      title: Text(
        'Tenant Services',
        style: TextStyle(
          color: colors.textPrimary,
          fontSize: 18,
          fontWeight: FontWeight.w600,
        ),
      ),
      centerTitle: true,
    );
  }

  Widget _buildHeader(AppLocalizations l10n, DynamicAppColors colors) {
    return Container(
      margin: const EdgeInsets.all(20),
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            colors.surfaceCards,
            colors.luxuryGradientStart,
          ],
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: colors.borderLight),
        boxShadow: [
          BoxShadow(
            color: colors.shadowColor,
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      colors.luxuryGold.withValues(alpha: 0.2),
                      colors.luxuryGold.withValues(alpha: 0.1),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  Icons.business_center_outlined,
                  color: colors.luxuryGold,
                  size: 24,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Text(
                  'Manage Services',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                    color: colors.textPrimary,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            'Set up and manage services that your tenants can book. Add service providers, set pricing, and control availability.',
            style: TextStyle(
              fontSize: 14,
              color: colors.textSecondary,
              height: 1.4,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildServicesList(AppLocalizations l10n, DynamicAppColors colors) {
    if (_services.isEmpty) {
      return _buildEmptyState(l10n, colors);
    }

    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      itemCount: _services.length,
      itemBuilder: (context, index) {
        return Padding(
          padding: const EdgeInsets.only(bottom: 16),
          child: _buildServiceCard(_services[index], l10n, colors),
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
            color: colors.shadowColor,
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        colors.primaryAccent.withValues(alpha: 0.2),
                        colors.primaryAccent.withValues(alpha: 0.1),
                      ],
                    ),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    _getCategoryIcon(service.category),
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
                        service.name,
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                          color: colors.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        service.provider,
                        style: TextStyle(
                          fontSize: 14,
                          color: colors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
                PopupMenuButton<String>(
                  icon: Icon(Icons.more_vert, color: colors.textSecondary),
                  onSelected: (value) => _handleServiceAction(value, service),
                  itemBuilder: (context) => [
                    PopupMenuItem(
                      value: 'edit',
                      child: Row(
                        children: [
                          Icon(Icons.edit_outlined, size: 20),
                          SizedBox(width: 12),
                          Text('Edit'),
                        ],
                      ),
                    ),
                    PopupMenuItem(
                      value: 'toggle',
                      child: Row(
                        children: [
                          Icon(
                            service.isActive ? Icons.pause_outlined : Icons.play_arrow_outlined,
                            size: 20,
                          ),
                          SizedBox(width: 12),
                          Text(service.isActive ? 'Disable' : 'Enable'),
                        ],
                      ),
                    ),
                    PopupMenuItem(
                      value: 'delete',
                      child: Row(
                        children: [
                          Icon(Icons.delete_outlined, size: 20, color: colors.error),
                          SizedBox(width: 12),
                          Text('Delete', style: TextStyle(color: colors.error)),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 16),
            Text(
              service.description,
              style: TextStyle(
                fontSize: 14,
                color: colors.textSecondary,
                height: 1.4,
              ),
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: colors.primaryAccent.withValues(alpha: 0.05),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: colors.primaryAccent.withValues(alpha: 0.1),
                ),
              ),
              child: Column(
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Price',
                              style: TextStyle(
                                fontSize: 12,
                                color: colors.textSecondary,
                              ),
                            ),
                            Text(
                              '\$${service.price.toStringAsFixed(0)}',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.w700,
                                color: colors.success,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Schedule',
                              style: TextStyle(
                                fontSize: 12,
                                color: colors.textSecondary,
                              ),
                            ),
                            Text(
                              service.schedule,
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                                color: colors.textPrimary,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: service.isActive 
                              ? colors.success.withValues(alpha: 0.1)
                              : colors.warning.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          service.isActive ? 'Active' : 'Inactive',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: service.isActive ? colors.success : colors.warning,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Icon(
                        Icons.phone_outlined,
                        size: 16,
                        color: colors.textSecondary,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        service.contactInfo,
                        style: TextStyle(
                          fontSize: 14,
                          color: colors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
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
          Icon(
            Icons.business_center_outlined,
            size: 64,
            color: colors.textSecondary.withValues(alpha: 0.5),
          ),
          const SizedBox(height: 16),
          Text(
            'No Services Set Up',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: colors.textPrimary,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Add services that your tenants can book',
            style: TextStyle(
              fontSize: 14,
              color: colors.textSecondary,
            ),
          ),
          const SizedBox(height: 24),
          ElevatedButton(
            onPressed: () => _showAddServiceDialog(context),
            style: ElevatedButton.styleFrom(
              backgroundColor: colors.primaryAccent,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            child: Text('Add Service'),
          ),
        ],
      ),
    );
  }

  Widget _buildFAB(AppLocalizations l10n, DynamicAppColors colors) {
    return FloatingActionButton(
      onPressed: () {
        HapticFeedback.mediumImpact();
        _showAddServiceDialog(context);
      },
      backgroundColor: colors.primaryAccent,
      foregroundColor: Colors.white,
      child: Icon(Icons.add, size: 24),
    );
  }

  IconData _getCategoryIcon(String category) {
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

  void _toggleServiceStatus(LandlordService service) {
    final colors = ref.read(dynamicColorsProvider);
    
    setState(() {
      final index = _services.indexWhere((s) => s.id == service.id);
      if (index >= 0) {
        _services[index] = LandlordService(
          id: service.id,
          name: service.name,
          description: service.description,
          category: service.category,
          price: service.price,
          provider: service.provider,
          contactInfo: service.contactInfo,
          schedule: service.schedule,
          isActive: !service.isActive,
        );
      }
    });
    
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          '${service.name} ${service.isActive ? 'disabled' : 'enabled'}',
        ),
        backgroundColor: colors.success,
      ),
    );
  }

  void _showDeleteConfirmation(BuildContext context, LandlordService service) {
    final colors = ref.read(dynamicColorsProvider);
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text('Delete Service'),
        content: Text(
          'Are you sure you want to delete "${service.name}"? This action cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              setState(() {
                _services.removeWhere((s) => s.id == service.id);
              });
              Navigator.of(context).pop();
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('Service deleted'),
                  backgroundColor: colors.success,
                ),
              );
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
    final isEditing = service != null;
    final formKey = GlobalKey<FormState>();
    
    String name = service?.name ?? '';
    String description = service?.description ?? '';
    String category = service?.category ?? 'maintenance';
    double price = service?.price ?? 0.0;
    String provider = service?.provider ?? '';
    String contactInfo = service?.contactInfo ?? '';
    String schedule = service?.schedule ?? '';

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
                  ],
                  onChanged: (value) => category = value ?? 'maintenance',
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
                    labelText: 'Contact Info',
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                  validator: (value) => value?.isEmpty ?? true ? 'Required' : null,
                  onSaved: (value) => contactInfo = value ?? '',
                ),
                const SizedBox(height: 16),
                TextFormField(
                  initialValue: price.toString(),
                  decoration: InputDecoration(
                    labelText: 'Price (\$)',
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
                const SizedBox(height: 16),
                TextFormField(
                  initialValue: schedule,
                  decoration: InputDecoration(
                    labelText: 'Schedule',
                    hintText: 'e.g., Weekly - Mondays',
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                  validator: (value) => value?.isEmpty ?? true ? 'Required' : null,
                  onSaved: (value) => schedule = value ?? '',
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
            onPressed: () {
              if (formKey.currentState?.validate() ?? false) {
                formKey.currentState?.save();
                
                final newService = LandlordService(
                  id: service?.id ?? DateTime.now().millisecondsSinceEpoch.toString(),
                  name: name,
                  description: description,
                  category: category,
                  price: price,
                  provider: provider,
                  contactInfo: contactInfo,
                  schedule: schedule,
                  isActive: service?.isActive ?? true,
                );

                setState(() {
                  if (isEditing) {
                    final index = _services.indexWhere((s) => s.id == service.id);
                    if (index >= 0) _services[index] = newService;
                  } else {
                    _services.add(newService);
                  }
                });

                Navigator.of(context).pop();
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(isEditing ? 'Service updated' : 'Service added'),
                    backgroundColor: colors.success,
                  ),
                );
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

