import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import '../../domain/models/property.dart';
import '../providers/property_providers.dart';
import '../../../../core/providers/navigation_provider.dart';
import '../../../../core/providers/dynamic_colors_provider.dart';
import '../../../../core/widgets/common_bottom_nav.dart';
import '../../../../core/providers/currency_provider.dart';
import '../../../auth/presentation/providers/user_role_provider.dart';
import '../../../../core/widgets/mongo_image.dart';

class PropertyListPage extends ConsumerStatefulWidget {
  const PropertyListPage({super.key});

  @override
  ConsumerState<PropertyListPage> createState() => _PropertyListPageState();
}

class _PropertyListPageState extends ConsumerState<PropertyListPage> {
  String _searchQuery = '';
  String _statusFilter = 'all';
    @override
  void initState() {
    super.initState();
    // Set navigation index to Properties (1) when this page is loaded
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(routeAwareNavigationProvider.notifier).setIndex(1);
      
      // Check if there's a search query in the URL
      final uri = Uri.parse(ModalRoute.of(context)?.settings.name ?? '');
      final searchQuery = uri.queryParameters['search'];
      if (searchQuery != null && searchQuery.isNotEmpty) {
        setState(() {
          _searchQuery = searchQuery;
        });
      }
    });
  }
  
  @override
  Widget build(BuildContext context) {
    final colors = ref.watch(dynamicColorsProvider);
    final l10n = AppLocalizations.of(context)!;;
    final userRole = ref.watch(userRoleProvider);
    final propertiesAsync = userRole == 'tenant' 
        ? ref.watch(tenantPropertiesProvider)
        : ref.watch(landlordPropertiesProvider);
      return Scaffold(
      backgroundColor: colors.primaryBackground,
      appBar: _buildAppBar(l10n),
      bottomNavigationBar: const CommonBottomNav(),
      body: SafeArea(
        child: Column(
          children: [
            _buildSearchAndFilter(l10n),
            Expanded(
              child: propertiesAsync.when(
                data: (properties) => _buildPropertyList(_filterProperties(properties), l10n),
                loading: () => Center(
                  child: CircularProgressIndicator(
                    valueColor: AlwaysStoppedAnimation<Color>(colors.primaryAccent),
                  ),
                ),
                error: (error, stack) => _buildErrorState(error, l10n),
              ),
            ),
          ],
        ),
      ),
      // Only show FAB for landlords
      floatingActionButton: userRole == 'landlord' ? _buildFAB() : null,
    );
  }
  PreferredSizeWidget _buildAppBar(AppLocalizations l10n) {
    final colors = ref.watch(dynamicColorsProvider);
    return AppBar(
      backgroundColor: colors.primaryBackground,
      elevation: 0,
      systemOverlayStyle: SystemUiOverlayStyle.dark,
      title: Text(
        l10n.myProperties,
        style: TextStyle(
          color: colors.textPrimary,
          fontSize: 18,
          fontWeight: FontWeight.w600,
          letterSpacing: -0.3,
          inherit: true,
        ),
      ),
      centerTitle: true,      leading: IconButton(
        icon: Icon(Icons.arrow_back_ios, color: colors.textPrimary, size: 20),
        onPressed: () {
          HapticFeedback.lightImpact();
          if (context.canPop()) {
            context.pop();
          } else {
            context.go('/home');
          }
        },
      ),
    );
  }

  Widget _buildSearchAndFilter(AppLocalizations l10n) {
    return Container(
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          // Search bar with modern design matching dashboard
          Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.08),
                  blurRadius: 24,
                  offset: const Offset(0, 8),
                  spreadRadius: 0,
                ),
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.04),
                  blurRadius: 6,
                  offset: const Offset(0, 2),
                  spreadRadius: 0,
                ),
              ],
            ),
            child: TextField(
              onChanged: (value) => setState(() => _searchQuery = value),
              decoration: InputDecoration(
                hintText: l10n.searchProperties,
                hintStyle: TextStyle(
                  color: const Color(0xFF64748B),
                  fontSize: 15,
                  fontWeight: FontWeight.w500,
                  letterSpacing: -0.1,
                  inherit: true,
                ),
                prefixIcon: Container(
                  padding: const EdgeInsets.all(12),
                  child: Icon(
                    Icons.search_outlined, 
                    color: const Color(0xFF64748B),
                    size: 20,
                  ),
                ),
                suffixIcon: Container(
                  margin: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF1F5F9),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: IconButton(
                    onPressed: () {
                      HapticFeedback.lightImpact();
                      _showFilterDialog(context, l10n);
                    },
                    icon: Icon(
                      Icons.filter_list_outlined,
                      color: const Color(0xFF64748B),
                      size: 18,
                    ),
                  ),
                ),
                border: InputBorder.none,
                contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
              ),
              style: TextStyle(
                color: const Color(0xFF0F172A),
                fontSize: 15,
                fontWeight: FontWeight.w500,
                letterSpacing: -0.1,
                inherit: true,
              ),
            ),
          ),
          const SizedBox(height: 16),
          // Status filter with scrollable behavior
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                _buildFilterChip(_capitalizeFilter(l10n.all), 'all'),
                const SizedBox(width: 8),
                _buildFilterChip(_capitalizeFilter(l10n.available), 'available'),
                const SizedBox(width: 8),
                _buildFilterChip(_capitalizeFilter(l10n.rented), 'rented'),
                const SizedBox(width: 8),
                _buildFilterChip(_capitalizeFilter(l10n.maintenance), 'maintenance'),
                const SizedBox(width: 8), // Extra padding at the end
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChip(String label, String value) {
    final colors = ref.watch(dynamicColorsProvider);
    final isSelected = _statusFilter == value;
    return GestureDetector(
      onTap: () {
        HapticFeedback.lightImpact();
        setState(() => _statusFilter = value);
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        decoration: BoxDecoration(
          gradient: isSelected 
            ? LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  colors.primaryAccent,
                  colors.primaryAccent.withValues(alpha: 0.8),
                ],
              )
            : null,
          color: isSelected ? null : colors.surfaceCards,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected ? colors.primaryAccent : colors.dividerSeparator,
            width: 1,
          ),
          boxShadow: [
            BoxShadow(
              color: isSelected 
                ? colors.primaryAccent.withValues(alpha: 0.3)
                : Colors.black.withValues(alpha: 0.04),
              blurRadius: isSelected ? 12 : 6,
              offset: Offset(0, isSelected ? 6 : 2),
              spreadRadius: 0,
            ),
          ],
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isSelected ? Colors.white : const Color(0xFF64748B),
            fontSize: 14,
            fontWeight: FontWeight.w600,
            letterSpacing: -0.1,
            inherit: true,
          ),
        ),
      ),
    );
  }

  List<Property> _filterProperties(List<Property> properties) {
    var filtered = properties;
    
    // Filter by search query
    if (_searchQuery.isNotEmpty) {
      filtered = filtered.where((property) =>
        property.address.street.toLowerCase().contains(_searchQuery.toLowerCase()) ||
        property.address.city.toLowerCase().contains(_searchQuery.toLowerCase())
      ).toList();
    }
    
    // Filter by status
    if (_statusFilter != 'all') {
      filtered = filtered.where((property) => property.status == _statusFilter).toList();
    }
    
    return filtered;
  }

  Widget _buildPropertyList(List<Property> properties, AppLocalizations l10n) {
    final colors = ref.watch(dynamicColorsProvider);
    if (properties.isEmpty) {
      return _buildEmptyState(l10n);
    }
    
    return RefreshIndicator(
      onRefresh: () async {
        HapticFeedback.lightImpact();
        ref.invalidate(landlordPropertiesProvider);
        await Future.delayed(const Duration(seconds: 1));
      },
      color: colors.primaryAccent,
      child: ListView.builder(
        padding: const EdgeInsets.symmetric(horizontal: 20),
        itemCount: properties.length,
        itemBuilder: (context, index) {
          final property = properties[index];
          return Padding(
            padding: const EdgeInsets.only(bottom: 16),
            child: _buildPropertyCard(property, l10n),
          );
        },
      ),
    );
  }

  Widget _buildPropertyCard(Property property, AppLocalizations l10n) {
    final colors = ref.watch(dynamicColorsProvider);
    final statusColor = property.status == 'rented' ? colors.success : 
                      property.status == 'available' ? colors.primaryAccent : colors.warning;

    return GestureDetector(
      onTap: () {
        HapticFeedback.lightImpact();
        context.push('/property/${property.id}');
      },
      child: Container(
        padding: const EdgeInsets.all(16.0), // Reduced from 28.0 to 16.0
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              colors.surfaceCards,
              statusColor.withValues(alpha: 0.02),
            ],
          ),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: statusColor.withValues(alpha: 0.15),
            width: 1,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.08),
              blurRadius: 24,
              offset: const Offset(0, 8),
              spreadRadius: 0,
            ),
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.04),
              blurRadius: 6,
              offset: const Offset(0, 2),
              spreadRadius: 0,
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header with image and basic info
            Row(
              children: [
                Container(
                  width: 80,
                  height: 80,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: statusColor.withValues(alpha: 0.2),
                      width: 1,
                    ),
                    color: property.imageUrls.isEmpty 
                      ? statusColor.withValues(alpha: 0.1)
                      : null,
                  ),
                  clipBehavior: Clip.antiAlias,
                  child: property.imageUrls.isNotEmpty 
                    ? _buildPropertyImage(property.imageUrls.first)
                    : Icon(
                        Icons.home_outlined,
                        color: statusColor,
                        size: 32,
                      ),
                ),
                const SizedBox(width: 20),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        property.address.street,
                        style: TextStyle(
                          fontSize: 16, // Reduced from 18
                          fontWeight: FontWeight.w700,
                          color: colors.textPrimary,
                          letterSpacing: -0.3,
                          inherit: true,
                        ),
                        maxLines: 1, // Changed from 2 to 1 to prevent overflow
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 6),
                      Row(
                        children: [
                          Icon(
                            Icons.location_on_outlined,
                            size: 16,
                            color: colors.textSecondary,
                          ),
                          const SizedBox(width: 4),
                          Expanded(
                            child: Text(
                              '${property.address.city}, ${property.address.postalCode}',
                              style: TextStyle(
                                fontSize: 13, // Reduced from 14
                                color: colors.textSecondary,
                                fontWeight: FontWeight.w500,
                                letterSpacing: -0.1,
                                inherit: true,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 16),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: statusColor.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: statusColor.withValues(alpha: 0.2),
                      width: 1,
                    ),
                  ),
                  child: Text(
                    _getLocalizedStatus(property.status, l10n),
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: statusColor,
                      letterSpacing: 0.5,
                      inherit: true,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
            // Property details in modern card layout
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: const Color(0xFFF8FAFC),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: const Color(0xFFE2E8F0),
                  width: 1,
                ),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: _buildDetailColumn(
                      icon: Icons.attach_money,
                      label: l10n.monthlyRent,
                      value: ref.read(currencyProvider.notifier).formatAmount(property.rentAmount),
                      iconColor: colors.success,
                      isPrice: true,
                    ),
                  ),
                  Container(
                    width: 1,
                    height: 50,
                    color: const Color(0xFFE2E8F0),
                  ),
                  Expanded(
                    child: _buildDetailColumn(
                      icon: Icons.square_foot,
                      label: l10n.size,
                      value: '${property.details.size.toStringAsFixed(0)} m²',
                      iconColor: colors.primaryAccent,
                    ),
                  ),
                  Container(
                    width: 1,
                    height: 50,
                    color: const Color(0xFFE2E8F0),
                  ),
                  Expanded(
                    child: _buildDetailColumn(
                      icon: Icons.meeting_room,
                      label: l10n.rooms,
                      value: '${property.details.rooms}',
                      iconColor: colors.warning,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailColumn({
    required IconData icon,
    required String label,
    required String value,
    required Color iconColor,
    bool isPrice = false,
  }) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: iconColor.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(
            icon, 
            size: 16, 
            color: iconColor,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          value,
          style: TextStyle(
            fontSize: isPrice ? 16 : 15,
            fontWeight: FontWeight.w700,
            color: const Color(0xFF0F172A),
            letterSpacing: -0.2,
            inherit: true,
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 2),
        Text(
          label.toUpperCase(),
          style: TextStyle(
            fontSize: 10,
            fontWeight: FontWeight.w600,
            color: const Color(0xFF64748B),
            letterSpacing: 0.5,
            inherit: true,
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  Widget _buildEmptyState(AppLocalizations l10n) {
    final userRole = ref.watch(userRoleProvider);
    final colors = ref.watch(dynamicColorsProvider);
    
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.home_outlined,
            size: 64,
            color: colors.textTertiary.withValues(alpha: 0.5),
          ),
          const SizedBox(height: 16),          Text(
            userRole == 'tenant' ? l10n.noPropertiesAssigned : l10n.noPropertiesFound,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: colors.textPrimary,
              inherit: true,
            ),
          ),
          const SizedBox(height: 8),          Text(
            userRole == 'tenant' 
                ? l10n.contactLandlordForAccess 
                : l10n.addFirstProperty,
            style: TextStyle(
              fontSize: 14,
              color: colors.textTertiary,
              inherit: true,
            ),
          ),
          const SizedBox(height: 24),
          // Only show add property button for landlords
          if (userRole == 'landlord')
            ElevatedButton(
              onPressed: () {
                HapticFeedback.mediumImpact();
                context.push('/add-property');
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: colors.primaryAccent,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: Text(l10n.addProperty),
            ),
        ],
      ),
    );
  }

  Widget _buildErrorState(Object error, AppLocalizations l10n) {
    final colors = ref.watch(dynamicColorsProvider);
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(
            Icons.error_outline,
            size: 64,
            color: Colors.red,
          ),
          const SizedBox(height: 16),          Text(
            l10n.somethingWentWrong,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: colors.textPrimary,
              inherit: true,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            error.toString(),
            style: TextStyle(
              fontSize: 14,
              color: colors.textTertiary,
              inherit: true,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
          ElevatedButton(
            onPressed: () {
              HapticFeedback.mediumImpact();
              // Invalidate both providers to ensure proper refresh regardless of user role
              ref.invalidate(landlordPropertiesProvider);
              ref.invalidate(tenantPropertiesProvider);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: colors.primaryAccent,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            child: Text(l10n.retry),
          ),
        ],
      ),
    );
  }

  Widget _buildFAB() {
    final colors = ref.watch(dynamicColorsProvider);
    return FloatingActionButton(
      onPressed: () {
        HapticFeedback.mediumImpact();
        context.push('/add-property');
      },      backgroundColor: colors.primaryAccent,
      foregroundColor: Colors.white,
      elevation: 4,
      child: const Icon(Icons.add, size: 24),
    );
  }
  
  String _getLocalizedStatus(String status, AppLocalizations l10n) {
    switch (status.toLowerCase()) {
      case 'rented':
        return l10n.rented.toUpperCase();
      case 'available':
        return l10n.available.toUpperCase();
      default:
        return status.toUpperCase();
    }
  }

  String _capitalizeFilter(String text) {
    if (text.isEmpty) return text;
    return text[0].toUpperCase() + text.substring(1).toLowerCase();
  }

  void _showFilterDialog(BuildContext context, AppLocalizations l10n) {
    final colors = ref.watch(dynamicColorsProvider);
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l10n.filterProperties),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: Icon(Icons.all_inclusive, color: colors.primaryAccent),
              title: Text(l10n.all),
              onTap: () {
                Navigator.of(context).pop();
                setState(() => _statusFilter = 'all');
              },
            ),
            ListTile(
              leading: Icon(Icons.check_circle, color: colors.success),
              title: Text(l10n.available),
              onTap: () {
                Navigator.of(context).pop();
                setState(() => _statusFilter = 'available');
              },
            ),
            ListTile(
              leading: Icon(Icons.home, color: colors.primaryAccent),
              title: Text(l10n.rented),
              onTap: () {
                Navigator.of(context).pop();
                setState(() => _statusFilter = 'rented');
              },
            ),
            ListTile(
              leading: Icon(Icons.build, color: colors.warning),
              title: Text(l10n.maintenance),
              onTap: () {
                Navigator.of(context).pop();
                setState(() => _statusFilter = 'maintenance');
              },
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text(l10n.cancel),
          ),
        ],
      ),
    );
  }

  Widget _buildPropertyImage(String imageIdOrPath) {
    // Check if it's a MongoDB ObjectId (24 hex characters)
    if (imageIdOrPath.length == 24 && RegExp(r'^[a-fA-F0-9]+$').hasMatch(imageIdOrPath)) {
      return MongoImage(
        imageId: imageIdOrPath,
        fit: BoxFit.cover,
        width: 80,
        height: 80,
        loadingWidget: Container(
          color: Colors.grey[300],
          child: const Center(
            child: SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(strokeWidth: 2),
            ),
          ),
        ),
        errorWidget: Container(
          color: Colors.grey[200],
          child: const Icon(
            Icons.home_outlined,
            color: Colors.grey,
            size: 32,
          ),
        ),
      );
    } else {
      // Regular network image
      return Image.network(
        imageIdOrPath,
        fit: BoxFit.cover,
        width: 80,
        height: 80,
        loadingBuilder: (context, child, loadingProgress) {
          if (loadingProgress == null) return child;
          return Container(
            color: Colors.grey[300],
            child: const Center(
              child: SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
            ),
          );
        },
        errorBuilder: (context, error, stackTrace) {
          return Container(
            color: Colors.grey[200],
            child: const Icon(
              Icons.home_outlined,
              color: Colors.grey,
              size: 32,
            ),
          );
        },
      );
    }
  }
}

