import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../../l10n/app_localizations.dart';
import '../../domain/models/property.dart';
import '../providers/property_providers.dart';
import '../../../../core/providers/navigation_provider.dart';
import '../../../../core/providers/dynamic_colors_provider.dart';
import '../../../../core/widgets/common_bottom_nav.dart';
import '../../../../core/providers/currency_provider.dart';
import '../../../auth/presentation/providers/user_role_provider.dart';
import '../../../subscription/presentation/providers/subscription_providers.dart';
import '../../../../core/widgets/mongo_image.dart';
import '../../../../core/utils/image_resolver.dart';
import '../../../home/presentation/models/dashboard_design.dart';
import '../../../home/presentation/pages/glass_dashboard_shared.dart';
import '../../../settings/providers/settings_provider.dart';

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
    final l10n = AppLocalizations.of(context)!;
    final design = dashboardDesignFromId(
      ref.watch(settingsProvider).dashboardDesign,
    );
    final userRole = ref.watch(userRoleProvider);
    final propertiesAsync = userRole == 'tenant'
        ? ref.watch(tenantPropertiesProvider)
        : ref.watch(landlordPropertiesProvider);

    if (design == DashboardDesign.glass) {
      return _buildGlassScaffold(
        context: context,
        l10n: l10n,
        userRole: userRole,
        propertiesAsync: propertiesAsync,
      );
    }

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
                data: (properties) => _buildPropertyList(
                  _filterProperties(properties),
                  l10n,
                  userRole,
                ),
                loading: () => Center(
                  child: CircularProgressIndicator(
                    valueColor:
                        AlwaysStoppedAnimation<Color>(colors.primaryAccent),
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

  Widget _buildGlassScaffold({
    required BuildContext context,
    required AppLocalizations l10n,
    required String userRole,
    required AsyncValue<List<Property>> propertiesAsync,
  }) {
    final colors = ref.watch(dynamicColorsProvider);
    return GlassPageScaffold(
      title: l10n.myProperties,
      onBack: () {
        HapticFeedback.lightImpact();
        if (context.canPop()) {
          context.pop();
        } else {
          context.go('/home');
        }
      },
      floatingActionButton: userRole == 'landlord' ? _buildFAB() : null,
      body: Column(
        children: [
          _buildGlassSearchAndFilter(l10n),
          const SizedBox(height: 20),
          Expanded(
            child: propertiesAsync.when(
              data: (properties) {
                final filtered = _filterProperties(properties);
                if (filtered.isEmpty) {
                  return _buildGlassEmptyState(l10n, userRole);
                }
                return RefreshIndicator(
                  color: Colors.white,
                  backgroundColor: Colors.white.withValues(alpha: 0.12),
                  onRefresh: () async {
                    HapticFeedback.lightImpact();
                    if (userRole == 'landlord') {
                      ref.invalidate(landlordPropertiesProvider);
                    } else {
                      ref.invalidate(tenantPropertiesProvider);
                    }
                    await Future.delayed(const Duration(milliseconds: 400));
                  },
                  child: ListView.builder(
                    padding: const EdgeInsets.only(bottom: 140, top: 4),
                    itemCount: filtered.length,
                    itemBuilder: (context, index) => Padding(
                      padding: const EdgeInsets.only(bottom: 16),
                      child: _buildGlassPropertyCard(
                        context,
                        filtered[index],
                        colors,
                      ),
                    ),
                  ),
                );
              },
              loading: () => const Center(
                child: CircularProgressIndicator(
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                ),
              ),
              error: (error, _) => _buildGlassErrorState(error, l10n),
            ),
          ),
        ],
      ),
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
      centerTitle: true,
      leading: IconButton(
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

  Widget _buildGlassSearchAndFilter(AppLocalizations l10n) {
    return Column(
      children: [
        GlassContainer(
          padding: EdgeInsets.zero,
          child: Container(
            decoration: BoxDecoration(
              color: Colors.black.withValues(alpha: 0.32),
              borderRadius: BorderRadius.circular(18),
              border: Border.all(
                color: Colors.white.withValues(alpha: 0.45),
              ),
            ),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
            child: TextFormField(
              initialValue: _searchQuery,
              onChanged: (value) => setState(() => _searchQuery = value),
              cursorColor: Colors.white,
              style: GoogleFonts.poppins(
                color: Colors.white,
                fontSize: 15,
                fontWeight: FontWeight.w600,
              ),
              decoration: InputDecoration(
                icon: Icon(
                  Icons.search_rounded,
                  color: Colors.white.withValues(alpha: 0.92),
                ),
                filled: true,
                fillColor: Colors.white.withValues(alpha: 0.08),
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 14,
                ),
                hintText: l10n.searchProperties,
                hintStyle: GoogleFonts.poppins(
                  color: Colors.white.withValues(alpha: 0.8),
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
                border: InputBorder.none,
              ),
            ),
          ),
        ),
        const SizedBox(height: 18),
        SizedBox(
          height: 48,
          child: ListView(
            scrollDirection: Axis.horizontal,
            children: [
              _buildGlassFilterChip(_capitalizeFilter(l10n.all), 'all'),
              _buildGlassFilterChip(
                  _capitalizeFilter(l10n.available), 'available'),
              _buildGlassFilterChip(_capitalizeFilter(l10n.rented), 'rented'),
              _buildGlassFilterChip(
                  _capitalizeFilter(l10n.maintenance), 'maintenance'),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildGlassFilterChip(String label, String value) {
    final bool isSelected = _statusFilter == value;
    return GestureDetector(
      onTap: () {
        HapticFeedback.lightImpact();
        setState(() => _statusFilter = value);
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 220),
        margin: const EdgeInsets.only(right: 12),
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: isSelected
                ? Colors.white.withValues(alpha: 0.85)
                : Colors.white.withValues(alpha: 0.4),
            width: 1.2,
          ),
          color: isSelected
              ? Colors.white.withValues(alpha: 0.25)
              : Colors.white.withValues(alpha: 0.12),
        ),
        child: Text(
          label,
          style: GoogleFonts.poppins(
            color: Colors.white,
            fontSize: 13,
            fontWeight: FontWeight.w600,
            letterSpacing: -0.1,
          ),
        ),
      ),
    );
  }

  Widget _buildGlassPropertyCard(
    BuildContext context,
    Property property,
    DynamicAppColors colors,
  ) {
    final l10n = AppLocalizations.of(context)!;
    const textPrimary = Colors.white;
    final textSecondary = Colors.white.withValues(alpha: 0.75);
    final rentText =
        ref.read(currencyProvider.notifier).formatAmount(property.rentAmount);

    return GestureDetector(
      onTap: () {
        HapticFeedback.lightImpact();
        context.push('/property/${property.id}');
      },
      child: GlassContainer(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(16),
                  child: SizedBox(
                    width: 78,
                    height: 78,
                    child: property.imageUrls.isNotEmpty
                        ? _buildPropertyImage(property.imageUrls.first)
                        : Container(
                            color: Colors.black.withValues(alpha: 0.35),
                            child: const Icon(
                              Icons.home_outlined,
                              size: 30,
                              color: Colors.white70,
                            ),
                          ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        property.address.street,
                        style: GoogleFonts.poppins(
                          color: textPrimary,
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          letterSpacing: -0.3,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 6),
                      Row(
                        children: [
                          Icon(
                            Icons.location_on_outlined,
                            size: 14,
                            color: textSecondary,
                          ),
                          const SizedBox(width: 4),
                          Expanded(
                            child: Text(
                              '${property.address.city}, ${property.address.postalCode}',
                              style: GoogleFonts.poppins(
                                color: textSecondary,
                                fontSize: 12,
                                fontWeight: FontWeight.w500,
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
                const SizedBox(width: 12),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.35),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: Colors.white.withValues(alpha: 0.35),
                      width: 0.8,
                    ),
                  ),
                  child: Text(
                    _getLocalizedStatus(property.status, l10n),
                    style: GoogleFonts.poppins(
                      color: Colors.white,
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 0.4,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 18),
            Row(
              children: [
                Expanded(
                  child: _buildGlassMetric(
                    icon: Icons.attach_money,
                    label: l10n.monthlyRent,
                    value: rentText,
                    color: colors.success,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildGlassMetric(
                    icon: Icons.square_foot,
                    label: l10n.size,
                    value: '${property.details.size.toStringAsFixed(0)} m2',
                    color: colors.primaryAccent,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildGlassMetric(
                    icon: Icons.meeting_room,
                    label: l10n.rooms,
                    value: '${property.details.rooms}',
                    color: colors.warning,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildGlassMetric({
    required IconData icon,
    required String label,
    required String value,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.28),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.28),
          width: 0.8,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.25),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, size: 16, color: Colors.white),
          ),
          const SizedBox(height: 10),
          Text(
            value,
            style: GoogleFonts.poppins(
              color: Colors.white,
              fontWeight: FontWeight.w700,
              fontSize: 14,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label.toUpperCase(),
            style: GoogleFonts.poppins(
              color: Colors.white.withValues(alpha: 0.65),
              fontSize: 10,
              fontWeight: FontWeight.w600,
              letterSpacing: 0.5,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGlassEmptyState(AppLocalizations l10n, String userRole) {
    final bool isTenant = userRole == 'tenant';
    final headline =
        isTenant ? l10n.noPropertiesAssigned : l10n.noPropertiesFound;
    final subline =
        isTenant ? l10n.contactLandlordForAccess : l10n.addFirstProperty;

    return Center(
      child: GlassContainer(
        padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.home_work_outlined, size: 52, color: Colors.white),
            const SizedBox(height: 18),
            Text(
              headline,
              textAlign: TextAlign.center,
              style: GoogleFonts.poppins(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              subline,
              textAlign: TextAlign.center,
              style: GoogleFonts.poppins(
                color: Colors.white.withValues(alpha: 0.85),
                fontSize: 13,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildGlassErrorState(Object error, AppLocalizations l10n) {
    return Center(
      child: GlassContainer(
        padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.error_outline, size: 48, color: Colors.white),
            const SizedBox(height: 12),
            Text(
              l10n.somethingWentWrong,
              textAlign: TextAlign.center,
              style: GoogleFonts.poppins(
                color: Colors.white,
                fontWeight: FontWeight.w600,
                fontSize: 16,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              error.toString(),
              textAlign: TextAlign.center,
              style: GoogleFonts.poppins(
                color: Colors.white.withValues(alpha: 0.8),
                fontSize: 12,
              ),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () {
                HapticFeedback.lightImpact();
                ref.invalidate(landlordPropertiesProvider);
                ref.invalidate(tenantPropertiesProvider);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.white.withValues(alpha: 0.25),
                foregroundColor: Colors.white,
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: Text(
                l10n.retry,
                style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSearchAndFilter(AppLocalizations l10n) {
    final colors = ref.watch(dynamicColorsProvider);

    return Container(
      padding: const EdgeInsets.all(16), // Reduced from 20
      child: Column(
        children: [
          // Search bar with modern design matching dashboard
          Container(
            decoration: BoxDecoration(
              color: colors.surfaceCards,
              borderRadius: BorderRadius.circular(14), // Reduced from 16
              boxShadow: [
                BoxShadow(
                  color:
                      Colors.black.withValues(alpha: 0.06), // Reduced opacity
                  blurRadius: 20, // Reduced from 24
                  offset: const Offset(0, 6), // Reduced from 8
                  spreadRadius: 0,
                ),
                BoxShadow(
                  color:
                      Colors.black.withValues(alpha: 0.03), // Reduced opacity
                  blurRadius: 4, // Reduced from 6
                  offset: const Offset(0, 2),
                  spreadRadius: 0,
                ),
              ],
            ),
            child: TextField(
              onChanged: (value) => setState(() => _searchQuery = value),
              style: TextStyle(
                color: colors.textPrimary,
                fontSize: 14, // Reduced from 15
                fontWeight: FontWeight.w500,
              ),
              decoration: InputDecoration(
                hintText: l10n.searchProperties,
                hintStyle: TextStyle(
                  color: colors.textSecondary,
                  fontSize: 14, // Reduced from 15
                  fontWeight: FontWeight.w500,
                  letterSpacing: -0.1,
                  inherit: true,
                ),
                prefixIcon: Container(
                  padding: const EdgeInsets.all(10), // Reduced from 12
                  child: Icon(
                    Icons.search_outlined,
                    color: colors.textSecondary,
                    size: 18, // Reduced from 20
                  ),
                ),
                suffixIcon: Container(
                  margin: const EdgeInsets.all(6), // Reduced from 8
                  decoration: BoxDecoration(
                    color: colors.surfaceCards,
                    borderRadius: BorderRadius.circular(6), // Reduced from 8
                    border: Border.all(
                      color: colors.borderLight,
                      width: 1,
                    ),
                  ),
                  child: IconButton(
                    onPressed: () {
                      HapticFeedback.lightImpact();
                      _showFilterDialog(context, l10n);
                    },
                    icon: Icon(
                      Icons.filter_list_outlined,
                      color: colors.textSecondary,
                      size: 16, // Reduced from 18
                    ),
                  ),
                ),
                border: InputBorder.none,
                contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16, vertical: 14), // Reduced padding
              ),
            ),
          ),
          const SizedBox(height: 14), // Reduced from 16
          // Status filter with scrollable behavior
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                _buildFilterChip(_capitalizeFilter(l10n.all), 'all'),
                const SizedBox(width: 6), // Reduced from 8
                _buildFilterChip(
                    _capitalizeFilter(l10n.available), 'available'),
                const SizedBox(width: 6),
                _buildFilterChip(_capitalizeFilter(l10n.rented), 'rented'),
                const SizedBox(width: 6),
                _buildFilterChip(
                    _capitalizeFilter(l10n.maintenance), 'maintenance'),
                const SizedBox(width: 6), // Extra padding at the end
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
        padding: const EdgeInsets.symmetric(
            horizontal: 16, vertical: 10), // Reduced padding
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
          borderRadius: BorderRadius.circular(14), // Reduced from 16
          border: Border.all(
            color: isSelected ? colors.primaryAccent : colors.dividerSeparator,
            width: 1,
          ),
          boxShadow: [
            BoxShadow(
              color: isSelected
                  ? colors.primaryAccent.withValues(alpha: 0.3)
                  : Colors.black.withValues(alpha: 0.03), // Reduced opacity
              blurRadius: isSelected ? 10 : 4, // Reduced blur
              offset: Offset(0, isSelected ? 4 : 2), // Reduced offset
              spreadRadius: 0,
            ),
          ],
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isSelected ? Colors.white : const Color(0xFF64748B),
            fontSize: 13, // Reduced from 14
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
      filtered = filtered
          .where((property) =>
              property.address.street
                  .toLowerCase()
                  .contains(_searchQuery.toLowerCase()) ||
              property.address.city
                  .toLowerCase()
                  .contains(_searchQuery.toLowerCase()))
          .toList();
    }

    // Filter by status
    if (_statusFilter != 'all') {
      filtered = filtered
          .where((property) => property.status == _statusFilter)
          .toList();
    }

    return filtered;
  }

  Widget _buildPropertyList(
    List<Property> properties,
    AppLocalizations l10n,
    String userRole,
  ) {
    final colors = ref.watch(dynamicColorsProvider);
    if (properties.isEmpty) {
      return _buildEmptyState(l10n, userRole: userRole);
    }

    return RefreshIndicator(
      onRefresh: () async {
        HapticFeedback.lightImpact();
        if (userRole == 'landlord') {
          ref.invalidate(landlordPropertiesProvider);
        } else {
          ref.invalidate(tenantPropertiesProvider);
        }
        await Future.delayed(const Duration(milliseconds: 400));
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

    // Gradient colors based on status
    final gradientColors = property.status == 'rented'
        ? [
            const Color(0xFF059669).withValues(alpha: 0.95),
            const Color(0xFF10B981).withValues(alpha: 0.85),
          ]
        : property.status == 'available'
            ? [
                const Color(0xFF3B82F6).withValues(alpha: 0.95),
                const Color(0xFF8B5CF6).withValues(alpha: 0.85),
              ]
            : [
                const Color(0xFFF59E0B).withValues(alpha: 0.95),
                const Color(0xFFEA580C).withValues(alpha: 0.85),
              ];

    final shadowColor = property.status == 'rented'
        ? const Color(0xFF059669)
        : property.status == 'available'
            ? const Color(0xFF3B82F6)
            : const Color(0xFFF59E0B);

    return GestureDetector(
      onTap: () {
        HapticFeedback.lightImpact();
        context.push('/property/${property.id}');
      },
      child: Container(
        padding: const EdgeInsets.all(20.0),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: gradientColors,
          ),
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(
              color: shadowColor.withValues(alpha: 0.3),
              blurRadius: 20,
              offset: const Offset(0, 8),
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
                    color: Colors.white.withValues(alpha: 0.2),
                  ),
                  clipBehavior: Clip.antiAlias,
                  child: property.imageUrls.isNotEmpty
                      ? _buildPropertyImage(property.imageUrls.first)
                      : const Icon(
                          Icons.home_outlined,
                          color: Colors.white,
                          size: 32,
                        ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        property.address.street,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w800,
                          color: Colors.white,
                          letterSpacing: -0.4,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 6),
                      Row(
                        children: [
                          Icon(
                            Icons.location_on_outlined,
                            size: 14,
                            color: Colors.white.withValues(alpha: 0.85),
                          ),
                          const SizedBox(width: 4),
                          Expanded(
                            child: Text(
                              '${property.address.city}, ${property.address.postalCode}',
                              style: TextStyle(
                                fontSize: 13,
                                color: Colors.white.withValues(alpha: 0.85),
                                fontWeight: FontWeight.w500,
                                letterSpacing: -0.1,
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
                const SizedBox(width: 12),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    _getLocalizedStatus(property.status, l10n),
                    style: const TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                      letterSpacing: 0.5,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 18),
            // Property details in modern card layout
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.95),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: _buildDetailColumn(
                      icon: Icons.attach_money,
                      label: l10n.monthlyRent,
                      value: ref
                          .read(currencyProvider.notifier)
                          .formatAmount(property.rentAmount),
                      iconColor: colors.success,
                      isPrice: true,
                      colors: colors,
                    ),
                  ),
                  Container(
                    width: 1,
                    height: 44, // Reduced from 50
                    color: colors.borderLight,
                  ),
                  Expanded(
                    child: _buildDetailColumn(
                      icon: Icons.square_foot,
                      label: l10n.size,
                      value: '${property.details.size.toStringAsFixed(0)} m2',
                      iconColor: colors.primaryAccent,
                      colors: colors,
                    ),
                  ),
                  Container(
                    width: 1,
                    height: 44, // Reduced from 50
                    color: colors.borderLight,
                  ),
                  Expanded(
                    child: _buildDetailColumn(
                      icon: Icons.meeting_room,
                      label: l10n.rooms,
                      value: '${property.details.rooms}',
                      iconColor: colors.warning,
                      colors: colors,
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
    required DynamicAppColors colors,
    bool isPrice = false,
  }) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(6), // Reduced from 8
          decoration: BoxDecoration(
            color: iconColor.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(6), // Reduced from 8
          ),
          child: Icon(
            icon,
            size: 14, // Reduced from 16
            color: iconColor,
          ),
        ),
        const SizedBox(height: 6), // Reduced from 8
        Text(
          value,
          style: TextStyle(
            fontSize: isPrice ? 14 : 13, // Reduced from 16/15
            fontWeight: FontWeight.w700,
            color: colors.textPrimary,
            letterSpacing: -0.2,
            inherit: true,
          ),
          textAlign: TextAlign.center,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        const SizedBox(height: 2),
        Text(
          label.toUpperCase(),
          style: TextStyle(
            fontSize: 9, // Reduced from 10
            fontWeight: FontWeight.w600,
            color: colors.textSecondary,
            letterSpacing: 0.5,
            inherit: true,
          ),
          textAlign: TextAlign.center,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
      ],
    );
  }

  Widget _buildEmptyState(
    AppLocalizations l10n, {
    String? userRole,
  }) {
    final role = userRole ?? ref.watch(userRoleProvider);
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
          const SizedBox(height: 16),
          Text(
            role == 'tenant'
                ? l10n.noPropertiesAssigned
                : l10n.noPropertiesFound,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: colors.textPrimary,
              inherit: true,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            role == 'tenant'
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
          if (role == 'landlord')
            Consumer(
              builder: (context, ref, child) {
                final subscriptionAsync = ref.watch(userSubscriptionProvider);
                return subscriptionAsync.when(
                  data: (subscription) {
                    final hasActiveSubscription =
                        subscription != null && subscription.status == 'active';

                    return ElevatedButton(
                      onPressed: () {
                        HapticFeedback.mediumImpact();
                        if (hasActiveSubscription) {
                          context.push('/add-property');
                        } else {
                          _showSubscriptionRequiredDialog();
                        }
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: hasActiveSubscription
                            ? colors.primaryAccent
                            : colors.textTertiary,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(
                            horizontal: 24, vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          if (!hasActiveSubscription) ...[
                            const Icon(Icons.lock, size: 16),
                            const SizedBox(width: 8),
                          ],
                          Text(hasActiveSubscription
                              ? l10n.addProperty
                              : l10n.subscriptionRequired),
                        ],
                      ),
                    );
                  },
                  loading: () => ElevatedButton(
                    onPressed: () {},
                    style: ElevatedButton.styleFrom(
                      backgroundColor: colors.textTertiary,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(
                          horizontal: 24, vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    child: const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(
                          strokeWidth: 2, color: Colors.white),
                    ),
                  ),
                  error: (_, __) => const SizedBox.shrink(),
                );
              },
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
          const SizedBox(height: 16),
          Text(
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
    final subscriptionAsync = ref.watch(userSubscriptionProvider);

    return subscriptionAsync.when(
      data: (subscription) {
        final hasActiveSubscription =
            subscription != null && subscription.status == 'active';

        return FloatingActionButton(
          onPressed: () {
            HapticFeedback.mediumImpact();
            if (hasActiveSubscription) {
              context.push('/add-property');
            } else {
              _showSubscriptionRequiredDialog();
            }
          },
          backgroundColor: hasActiveSubscription
              ? colors.primaryAccent
              : colors.textTertiary,
          foregroundColor: Colors.white,
          elevation: 4,
          child: hasActiveSubscription
              ? const Icon(Icons.add, size: 24)
              : const Icon(Icons.lock, size: 24),
        );
      },
      loading: () => FloatingActionButton(
        onPressed: () {},
        backgroundColor: colors.textTertiary,
        foregroundColor: Colors.white,
        elevation: 4,
        child: const CircularProgressIndicator(
            strokeWidth: 2, color: Colors.white),
      ),
      error: (_, __) => FloatingActionButton(
        onPressed: () {},
        backgroundColor: colors.textTertiary,
        foregroundColor: Colors.white,
        elevation: 4,
        child: const Icon(Icons.error, size: 24),
      ),
    );
  }

  void _showSubscriptionRequiredDialog() {
    final colors = ref.read(dynamicColorsProvider);
    final l10n = AppLocalizations.of(context)!;
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: colors.surfaceCards,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            Icon(Icons.lock_outlined, color: colors.warning, size: 24),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                l10n.subscriptionRequired,
                style: TextStyle(
                  color: colors.textPrimary,
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              l10n.subscriptionRequiredMessage,
              style: TextStyle(
                color: colors.textSecondary,
                fontSize: 14,
                height: 1.4,
              ),
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: colors.primaryAccent.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                    color: colors.primaryAccent.withValues(alpha: 0.2)),
              ),
              child: Row(
                children: [
                  Icon(Icons.star_outline,
                      color: colors.primaryAccent, size: 20),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      l10n.subscriptionChoosePlanMessage,
                      style: TextStyle(
                        color: colors.primaryAccent,
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text(
              l10n.cancel,
              style: TextStyle(color: colors.textTertiary),
            ),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(context).pop();
              context.push('/subscription/landlord');
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: colors.primaryAccent,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8)),
            ),
            child: Text(l10n.viewPlans),
          ),
        ],
      ),
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
    final resolved = resolvePropertyImage(imageIdOrPath);
    if (resolved.isEmpty) {
      return Container(
        color: Colors.grey[200],
        child: const Icon(
          Icons.home_outlined,
          color: Colors.grey,
          size: 32,
        ),
      );
    }
    // Always load via MongoImage to attach auth headers and handle 401-retry
    return MongoImage(
      imageId: resolved,
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
  }
}
