import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../../l10n/app_localizations.dart';
import '../../../../core/providers/dynamic_colors_provider.dart';
import '../../../../core/widgets/common_bottom_nav.dart';
import '../../../services/domain/models/service.dart' as ServiceModel;
import '../../../services/presentation/providers/service_providers.dart';
import '../../../property/presentation/providers/property_providers.dart';

// UI Service model for display
class TenantService {
  final String id;
  final String name;
  final String description;
  final String category;
  final double price;
  final String provider;
  final String contactInfo;
  final IconData icon;
  final bool isAvailable;

  TenantService({
    required this.id,
    required this.name,
    required this.description,
    required this.category,
    required this.price,
    required this.provider,
    required this.contactInfo,
    required this.icon,
    this.isAvailable = true,
  });

  factory TenantService.fromServiceModel(ServiceModel.Service service) {
    return TenantService(
      id: service.id,
      name: service.name,
      description: service.description,
      category: service.category,
      price: service.price,
      provider: service.contactInfo.isNotEmpty
          ? service.contactInfo
          : 'Service Provider',
      contactInfo: service.contactInfo,
      icon: _getIconForCategory(service.category),
      isAvailable: service.availability == 'available',
    );
  }

  static IconData _getIconForCategory(String category) {
    switch (category.toLowerCase()) {
      case 'maintenance':
        return Icons.build_outlined;
      case 'cleaning':
        return Icons.cleaning_services_outlined;
      case 'repair':
        return Icons.handyman_outlined;
      case 'general':
        return Icons.room_service_outlined;
      default:
        return Icons.miscellaneous_services_outlined;
    }
  }
}

class TenantServicesBookingPage extends ConsumerStatefulWidget {
  const TenantServicesBookingPage({super.key});

  @override
  ConsumerState<TenantServicesBookingPage> createState() =>
      _TenantServicesBookingPageState();
}

class _TenantServicesBookingPageState
    extends ConsumerState<TenantServicesBookingPage> {
  String _selectedCategory = 'all';
  String _searchQuery = '';

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final colors = ref.watch(dynamicColorsProvider);

    // Get tenant properties to find landlords
    final tenantPropertiesAsync = ref.watch(tenantPropertiesProvider);

    return Scaffold(
      backgroundColor: colors.primaryBackground,
      appBar: AppBar(
        title: Text(l10n.services),
        backgroundColor: colors.surfaceCards,
        foregroundColor: colors.textPrimary,
        elevation: 0,
      ),
      body: tenantPropertiesAsync.when(
        data: (properties) {
          if (properties.isEmpty) {
            return _buildNoPropertiesState(l10n, colors);
          }

          // Get unique landlord IDs from properties
          final landlordIds =
              properties.map((p) => p.landlordId).toSet().toList();

          return _buildServicesView(landlordIds, l10n, colors);
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stack) => Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.error_outline, size: 64, color: colors.error),
              const SizedBox(height: 16),
              Text(
                'Error loading properties',
                style: TextStyle(fontSize: 18, color: colors.textPrimary),
              ),
              const SizedBox(height: 8),
              Text(
                error.toString(),
                style: TextStyle(fontSize: 14, color: colors.textSecondary),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
      bottomNavigationBar: const CommonBottomNav(),
    );
  }

  Widget _buildNoPropertiesState(
      AppLocalizations l10n, DynamicAppColors colors) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.home_outlined,
            size: 80,
            color: colors.textTertiary,
          ),
          const SizedBox(height: 20),
          Text(
            'No Properties Assigned',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w600,
              color: colors.textPrimary,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            'You need to be assigned to a property to view available services.',
            style: TextStyle(
              fontSize: 14,
              color: colors.textSecondary,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildServicesView(List<String> landlordIds, AppLocalizations l10n,
      DynamicAppColors colors) {
    // For now, get services from the first landlord
    // In a real implementation, you might want to combine services from all landlords
    final firstLandlordId = landlordIds.first;
    final servicesAsync =
        ref.watch(tenantAvailableServicesProvider(firstLandlordId));

    return servicesAsync.when(
      data: (services) {
        final tenantServices =
            services.map((s) => TenantService.fromServiceModel(s)).toList();

        return Column(
          children: [
            _buildHeader(colors),
            _buildSearchAndFilter(l10n, colors),
            Expanded(
              child: tenantServices.isEmpty
                  ? _buildEmptyState(l10n, colors)
                  : _buildServicesList(tenantServices, l10n, colors),
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
              onPressed: () => ref
                  .invalidate(tenantAvailableServicesProvider(firstLandlordId)),
              child: Text('Retry'),
            ),
          ],
        ),
      ),
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
                padding: const EdgeInsets.all(8),
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
                  Icons.business_center_outlined,
                  color: colors.primaryAccent,
                  size: 18,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  'Available Services',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: colors.textPrimary,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            'Book services that your landlord has made available for tenants. All services are pre-approved and professionally managed.',
            style: TextStyle(
              fontSize: 12,
              color: colors.textSecondary,
              height: 1.3,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchAndFilter(AppLocalizations l10n, DynamicAppColors colors) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        children: [
          // Search bar
          Container(
            decoration: BoxDecoration(
              color: colors.surfaceCards,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: colors.borderLight),
            ),
            child: TextField(
              onChanged: (value) => setState(() => _searchQuery = value),
              decoration: InputDecoration(
                hintText: 'Search services...',
                hintStyle: TextStyle(color: colors.textTertiary),
                prefixIcon:
                    Icon(Icons.search, color: colors.textTertiary, size: 20),
                border: InputBorder.none,
                contentPadding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              ),
              style: TextStyle(color: colors.textPrimary, inherit: true),
            ),
          ),
          const SizedBox(height: 12),
          // Category filters
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                _buildCategoryChip('all', 'All', colors),
                const SizedBox(width: 8),
                _buildCategoryChip('maintenance', 'Maintenance', colors),
                const SizedBox(width: 8),
                _buildCategoryChip('cleaning', 'Cleaning', colors),
                const SizedBox(width: 8),
                _buildCategoryChip('repair', 'Repair', colors),
                const SizedBox(width: 8),
                _buildCategoryChip('general', 'General', colors),
              ],
            ),
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }

  Widget _buildCategoryChip(
      String category, String label, DynamicAppColors colors) {
    final isSelected = _selectedCategory == category;
    return GestureDetector(
      onTap: () => setState(() => _selectedCategory = category),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? colors.primaryAccent : colors.surfaceCards,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected ? colors.primaryAccent : colors.borderLight,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isSelected ? Colors.white : colors.textSecondary,
            fontSize: 13,
            fontWeight: FontWeight.w500,
          ),
        ),
      ),
    );
  }

  Widget _buildServicesList(List<TenantService> services, AppLocalizations l10n,
      DynamicAppColors colors) {
    final filteredServices = services.where((service) {
      final matchesCategory =
          _selectedCategory == 'all' || service.category == _selectedCategory;
      final matchesSearch = _searchQuery.isEmpty ||
          service.name.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          service.description
              .toLowerCase()
              .contains(_searchQuery.toLowerCase());
      return matchesCategory && matchesSearch;
    }).toList();

    if (filteredServices.isEmpty) {
      return _buildEmptyState(l10n, colors);
    }

    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      itemCount: filteredServices.length,
      itemBuilder: (context, index) {
        return Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: _buildServiceCard(filteredServices[index], l10n, colors),
        );
      },
    );
  }

  Widget _buildServiceCard(
      TenantService service, AppLocalizations l10n, DynamicAppColors colors) {
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
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: colors.borderLight),
        boxShadow: [
          BoxShadow(
            color: colors.primaryAccent.withValues(alpha: 0.08),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
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
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Icon(
                    service.icon,
                    color: colors.primaryAccent,
                    size: 18,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        service.name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                          color: colors.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        service.provider,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 12,
                          color: colors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: colors.success.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                            color: colors.success.withValues(alpha: 0.3)),
                      ),
                      child: Text(
                        'CHF ${service.price.toStringAsFixed(0)}',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: colors.success,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 10),
            Text(
              service.description,
              style: TextStyle(
                fontSize: 12,
                color: colors.textSecondary,
                height: 1.3,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(
                            Icons.access_time,
                            size: 14,
                            color: colors.textTertiary,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            'Available',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: colors.textPrimary,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                SizedBox(
                  height: 28,
                  child: ElevatedButton(
                    onPressed: service.isAvailable
                        ? () => _showBookingDialog(context, service, colors)
                        : null,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: colors.primaryAccent,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                      elevation: 0,
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                    ),
                    child: Text(
                      'Book',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
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
          Icon(
            Icons.business_center_outlined,
            size: 64,
            color: colors.textTertiary,
          ),
          const SizedBox(height: 16),
          Text(
            'No Services Available',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: colors.textPrimary,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Your landlord hasn\'t set up any services yet.',
            style: TextStyle(
              fontSize: 14,
              color: colors.textSecondary,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  void _showBookingDialog(
      BuildContext context, TenantService service, DynamicAppColors colors) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text('Book ${service.name}'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Service: ${service.name}',
              style: TextStyle(fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 8),
            Text(
              'Provider: ${service.provider}',
              style: TextStyle(color: colors.textSecondary),
            ),
            const SizedBox(height: 8),
            Text(
              'Price: CHF ${service.price.toStringAsFixed(2)}',
              style: TextStyle(color: colors.textSecondary),
            ),
            const SizedBox(height: 16),
            Text(
              'Contact Information:',
              style: TextStyle(fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 4),
            Text(
              service.contactInfo.isNotEmpty
                  ? service.contactInfo
                  : 'No contact info available',
              style: TextStyle(color: colors.textSecondary),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(context).pop();
              _showBookingConfirmation(context, service, colors);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: colors.primaryAccent,
              foregroundColor: Colors.white,
            ),
            child: Text('Contact Provider'),
          ),
        ],
      ),
    );
  }

  void _showBookingConfirmation(
      BuildContext context, TenantService service, DynamicAppColors colors) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          'Contact information for ${service.name} has been provided. Please reach out to ${service.provider} directly.',
        ),
        backgroundColor: colors.success,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        margin: const EdgeInsets.all(16),
      ),
    );
  }
}
