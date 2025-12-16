import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../../l10n/app_localizations.dart';
import '../../../../core/providers/dynamic_colors_provider.dart';
import '../../../../core/widgets/common_bottom_nav.dart';
import '../../../home/presentation/models/dashboard_design.dart';
import '../../../home/presentation/pages/glass_dashboard_shared.dart';
import '../../../settings/providers/settings_provider.dart';
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
      provider: service.contactInfo,
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
    final design = dashboardDesignFromId(
      ref.watch(settingsProvider).dashboardDesign,
    );
    final bool glassMode = design == DashboardDesign.glass;

    // Get tenant properties to find landlords
    final tenantPropertiesAsync = ref.watch(tenantPropertiesProvider);

    final Widget content = tenantPropertiesAsync.when(
      data: (properties) {
        if (properties.isEmpty) {
          return _buildNoPropertiesState(l10n, colors, glassMode: glassMode);
        }

        final landlordIds =
            properties.map((p) => p.landlordId).toSet().toList();
        return _buildServicesView(
          landlordIds,
          l10n,
          colors,
          glassMode: glassMode,
        );
      },
      loading: () => _buildLoadingState(l10n, colors, glassMode: glassMode),
      error: (error, stack) =>
          _buildPropertiesError(error, l10n, colors, glassMode: glassMode),
    );

    if (glassMode) {
      return GlassPageScaffold(
        title: l10n.services,
        body: content,
      );
    }

    return Scaffold(
      backgroundColor: Colors.transparent,
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: Text(l10n.services),
        backgroundColor: colors.surfaceCards.withValues(alpha: 0.95),
        foregroundColor: colors.textPrimary,
        elevation: 0,
        systemOverlayStyle: SystemUiOverlayStyle.dark,
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              colors.primaryBackground,
              colors.surfaceSecondary,
            ],
          ),
        ),
        child: SafeArea(child: content),
      ),
      bottomNavigationBar: const CommonBottomNav(),
    );
  }

  Widget _buildNoPropertiesState(
    AppLocalizations l10n,
    DynamicAppColors colors, {
    required bool glassMode,
  }) {
    final titleColor = _primaryTextColor(colors, glassMode);
    final subtitleColor = _secondaryTextColor(colors, glassMode);
    final iconColor =
        glassMode ? Colors.white.withValues(alpha: 0.85) : colors.textTertiary;

    final content = Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(
          Icons.home_outlined,
          size: 80,
          color: iconColor,
        ),
        const SizedBox(height: 20),
        Text(
          l10n.tenantServicesNoPropertiesTitle,
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w600,
            color: titleColor,
          ),
        ),
        const SizedBox(height: 12),
        Text(
          l10n.tenantServicesNoPropertiesBody,
          style: TextStyle(
            fontSize: 14,
            color: subtitleColor,
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );

    if (glassMode) {
      return Center(
        child: GlassContainer(
          padding: const EdgeInsets.all(28),
          child: content,
        ),
      );
    }

    return Center(
      child: Container(
        padding: const EdgeInsets.all(28),
        decoration: BoxDecoration(
          color: colors.surfaceCards.withValues(alpha: 0.95),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: colors.borderLight),
          boxShadow: [
            BoxShadow(
              color: colors.shadowColor,
              blurRadius: 20,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: content,
      ),
    );
  }

  Widget _buildLoadingState(
    AppLocalizations l10n,
    DynamicAppColors colors, {
    required bool glassMode,
  }) {
    final loader = Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        SizedBox(
          width: 36,
          height: 36,
          child: CircularProgressIndicator(
            strokeWidth: 3,
            valueColor: AlwaysStoppedAnimation<Color>(
              glassMode ? Colors.white : colors.primaryAccent,
            ),
          ),
        ),
        const SizedBox(height: 16),
        Text(
          l10n.loading,
          style: TextStyle(
            color: _primaryTextColor(colors, glassMode),
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );

    if (glassMode) {
      return Center(
        child: GlassContainer(
          padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 28),
          child: loader,
        ),
      );
    }

    return Center(
      child: Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: colors.surfaceCards.withValues(alpha: 0.95),
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: colors.shadowColor,
              blurRadius: 20,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: loader,
      ),
    );
  }

  Widget _buildPropertiesError(
    Object error,
    AppLocalizations l10n,
    DynamicAppColors colors, {
    required bool glassMode,
  }) {
    final Color foreground = glassMode ? Colors.white : colors.textPrimary;
    final Color secondary =
        glassMode ? Colors.white.withValues(alpha: 0.8) : colors.textSecondary;
    final content = Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: glassMode
                ? Colors.white.withValues(alpha: 0.12)
                : colors.error.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(Icons.error_outline,
              size: 48, color: glassMode ? Colors.white : colors.error),
        ),
        const SizedBox(height: 16),
        Text(
          l10n.tenantServicesErrorLoadingProperties,
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w700,
            color: foreground,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          error.toString(),
          style: TextStyle(fontSize: 14, color: secondary),
          textAlign: TextAlign.center,
        ),
      ],
    );

    if (glassMode) {
      return Center(
        child: GlassContainer(
          padding: const EdgeInsets.all(28),
          child: content,
        ),
      );
    }

    return Center(
      child: Container(
        margin: const EdgeInsets.all(20),
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: colors.surfaceCards.withValues(alpha: 0.95),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: colors.borderLight),
          boxShadow: [
            BoxShadow(
              color: colors.shadowColor,
              blurRadius: 20,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: content,
      ),
    );
  }

  Widget _buildServicesView(
      List<String> landlordIds, AppLocalizations l10n, DynamicAppColors colors,
      {required bool glassMode}) {
    // For now, get services from the first landlord
    // In a real implementation, you might want to combine services from all landlords
    final firstLandlordId = landlordIds.first;
    final servicesAsync =
        ref.watch(tenantAvailableServicesProvider(firstLandlordId));

    return servicesAsync.when(
      data: (services) {
        final tenantServices =
            services.map(TenantService.fromServiceModel).toList();

        return Column(
          children: [
            _buildHeader(l10n, colors, glassMode: glassMode),
            _buildSearchAndFilter(l10n, colors, glassMode: glassMode),
            Expanded(
              child: tenantServices.isEmpty
                  ? _buildEmptyState(l10n, colors, glassMode: glassMode)
                  : _buildServicesList(
                      tenantServices,
                      l10n,
                      colors,
                      glassMode: glassMode,
                    ),
            ),
          ],
        );
      },
      loading: () => _buildLoadingState(l10n, colors, glassMode: glassMode),
      error: (error, stack) => _buildServicesError(
        error,
        l10n,
        colors,
        firstLandlordId,
        glassMode: glassMode,
      ),
    );
  }

  Widget _buildHeader(
    AppLocalizations l10n,
    DynamicAppColors colors, {
    required bool glassMode,
  }) {
    final titleStyle = TextStyle(
      fontSize: 20,
      fontWeight: FontWeight.w800,
      color: glassMode ? Colors.white : Colors.white,
      letterSpacing: -0.5,
    );
    final subtitleStyle = TextStyle(
      fontSize: 14,
      color: glassMode
          ? Colors.white.withValues(alpha: 0.85)
          : Colors.white.withValues(alpha: 0.9),
      height: 1.4,
      fontWeight: FontWeight.w500,
    );

    final child = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: glassMode ? 0.25 : 0.2),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(
                Icons.business_center_outlined,
                color: Colors.white,
                size: 24,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Text(
                l10n.tenantServicesHeaderTitle,
                style: titleStyle,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Text(
          l10n.tenantServicesHeaderSubtitle,
          style: subtitleStyle,
        ),
      ],
    );

    if (glassMode) {
      return Padding(
        padding: const EdgeInsets.fromLTRB(8, 8, 8, 20),
        child: GlassContainer(
          padding: const EdgeInsets.all(24),
          child: child,
        ),
      );
    }

    return Container(
      margin: const EdgeInsets.all(20),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            colors.primaryAccent,
            colors.primaryAccent.withValues(alpha: 0.8),
          ],
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: colors.primaryAccent.withValues(alpha: 0.3),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: child,
    );
  }

  Widget _buildSearchAndFilter(
    AppLocalizations l10n,
    DynamicAppColors colors, {
    required bool glassMode,
  }) {
    final inputDecoration = BoxDecoration(
      color: glassMode
          ? Colors.white.withValues(alpha: 0.12)
          : colors.surfaceCards.withValues(alpha: 0.95),
      borderRadius: BorderRadius.circular(16),
      border: Border.all(
        color: glassMode
            ? Colors.white.withValues(alpha: 0.24)
            : colors.borderLight,
      ),
      boxShadow: glassMode
          ? null
          : [
              BoxShadow(
                color: colors.shadowColor,
                blurRadius: 12,
                offset: const Offset(0, 2),
              ),
            ],
    );

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        children: [
          Container(
            decoration: inputDecoration,
            child: TextField(
              onChanged: (value) => setState(() => _searchQuery = value),
              decoration: InputDecoration(
                hintText: l10n.tenantServicesSearchHint,
                hintStyle: TextStyle(
                  color: glassMode
                      ? Colors.white.withValues(alpha: 0.75)
                      : colors.textTertiary,
                  fontWeight: FontWeight.w500,
                ),
                prefixIcon: Icon(
                  Icons.search,
                  color: glassMode ? Colors.white : colors.primaryAccent,
                  size: 22,
                ),
                border: InputBorder.none,
                contentPadding:
                    const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
              ),
              style: TextStyle(
                color: _primaryTextColor(colors, glassMode),
                fontSize: 15,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          const SizedBox(height: 16),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                _buildCategoryChip(
                  'all',
                  l10n.tenantServicesCategoryAll,
                  colors,
                  glassMode: glassMode,
                ),
                const SizedBox(width: 10),
                _buildCategoryChip(
                  'maintenance',
                  l10n.tenantServicesCategoryMaintenance,
                  colors,
                  glassMode: glassMode,
                ),
                const SizedBox(width: 10),
                _buildCategoryChip(
                  'cleaning',
                  l10n.tenantServicesCategoryCleaning,
                  colors,
                  glassMode: glassMode,
                ),
                const SizedBox(width: 10),
                _buildCategoryChip(
                  'repair',
                  l10n.tenantServicesCategoryRepair,
                  colors,
                  glassMode: glassMode,
                ),
                const SizedBox(width: 10),
                _buildCategoryChip(
                  'general',
                  l10n.tenantServicesCategoryGeneral,
                  colors,
                  glassMode: glassMode,
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
        ],
      ),
    );
  }

  Widget _buildCategoryChip(
    String category,
    String label,
    DynamicAppColors colors, {
    required bool glassMode,
  }) {
    final isSelected = _selectedCategory == category;
    return GestureDetector(
      onTap: () {
        HapticFeedback.lightImpact();
        setState(() => _selectedCategory = category);
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        decoration: BoxDecoration(
          gradient: !glassMode && isSelected
              ? LinearGradient(
                  colors: [
                    colors.primaryAccent,
                    colors.primaryAccent.withValues(alpha: 0.8),
                  ],
                )
              : null,
          color: glassMode
              ? (isSelected
                  ? Colors.white.withValues(alpha: 0.28)
                  : Colors.white.withValues(alpha: 0.12))
              : (isSelected
                  ? null
                  : colors.surfaceCards.withValues(alpha: 0.95)),
          borderRadius: BorderRadius.circular(25),
          border: Border.all(
            color: glassMode
                ? Colors.white.withValues(alpha: isSelected ? 0.45 : 0.24)
                : (isSelected ? colors.primaryAccent : colors.borderLight),
            width: isSelected ? 1.8 : 1,
          ),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: glassMode
                        ? Colors.white.withValues(alpha: 0.22)
                        : colors.primaryAccent.withValues(alpha: 0.3),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ]
              : null,
        ),
        child: Text(
          label,
          style: TextStyle(
            color: glassMode
                ? Colors.white
                : (isSelected ? Colors.white : colors.textPrimary),
            fontSize: 14,
            fontWeight: isSelected ? FontWeight.w700 : FontWeight.w600,
            letterSpacing: -0.2,
          ),
        ),
      ),
    );
  }

  Widget _buildServicesList(
    List<TenantService> services,
    AppLocalizations l10n,
    DynamicAppColors colors, {
    required bool glassMode,
  }) {
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
      return _buildEmptyState(l10n, colors, glassMode: glassMode);
    }

    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      itemCount: filteredServices.length,
      itemBuilder: (context, index) {
        return Padding(
          padding: const EdgeInsets.only(bottom: 16),
          child: _buildServiceCard(
            filteredServices[index],
            l10n,
            colors,
            glassMode: glassMode,
          ),
        );
      },
    );
  }

  Widget _buildServicesError(
    Object error,
    AppLocalizations l10n,
    DynamicAppColors colors,
    String landlordId, {
    required bool glassMode,
  }) {
    final Color primary = _primaryTextColor(colors, glassMode);
    final Color secondary = _secondaryTextColor(colors, glassMode);

    final child = Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(
          Icons.error_outline,
          size: 64,
          color: glassMode ? Colors.white : colors.error,
        ),
        const SizedBox(height: 16),
        Text(
          l10n.tenantServicesErrorLoadingServices,
          style: TextStyle(fontSize: 18, color: primary),
        ),
        const SizedBox(height: 8),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          child: Text(
            error.toString(),
            style: TextStyle(fontSize: 14, color: secondary),
            textAlign: TextAlign.center,
          ),
        ),
        const SizedBox(height: 16),
        ElevatedButton(
          onPressed: () =>
              ref.invalidate(tenantAvailableServicesProvider(landlordId)),
          style: ElevatedButton.styleFrom(
            backgroundColor: glassMode ? Colors.white : colors.primaryAccent,
            foregroundColor: glassMode ? Colors.black87 : colors.textOnAccent,
          ),
          child: Text(l10n.retry),
        ),
      ],
    );

    if (glassMode) {
      return Center(
        child: GlassContainer(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 28),
          child: child,
        ),
      );
    }

    return Center(child: child);
  }

  Widget _buildServiceCard(
    TenantService service,
    AppLocalizations l10n,
    DynamicAppColors colors, {
    required bool glassMode,
  }) {
    final borderRadius = BorderRadius.circular(20);
    final primary = _primaryTextColor(colors, glassMode);
    final secondary = _secondaryTextColor(colors, glassMode);
    final iconColor = glassMode ? Colors.white : colors.primaryAccent;

    final child = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: glassMode
                      ? [
                          Colors.white.withValues(alpha: 0.25),
                          Colors.white.withValues(alpha: 0.12),
                        ]
                      : [
                          colors.primaryAccent.withValues(alpha: 0.2),
                          colors.primaryAccent.withValues(alpha: 0.1),
                        ],
                ),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: glassMode
                      ? Colors.white.withValues(alpha: 0.3)
                      : colors.primaryAccent.withValues(alpha: 0.2),
                ),
              ),
              child: Icon(service.icon, color: iconColor, size: 24),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    service.name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.w700,
                      color: primary,
                      letterSpacing: -0.3,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    service.provider,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 13,
                      color: secondary,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: glassMode
                ? Colors.white.withValues(alpha: 0.12)
                : colors.primaryAccent.withValues(alpha: 0.05),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: glassMode
                  ? Colors.white.withValues(alpha: 0.2)
                  : colors.borderLight,
            ),
          ),
          child: Text(
            service.description,
            style: TextStyle(
              fontSize: 13,
              color: secondary,
              height: 1.5,
              fontWeight: FontWeight.w500,
            ),
            maxLines: 3,
            overflow: TextOverflow.ellipsis,
          ),
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: colors.success.withValues(
                        alpha: glassMode ? 0.25 : 0.12,
                      ),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(
                      Icons.check_circle_outline,
                      size: 16,
                      color: glassMode ? Colors.white : colors.success,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    l10n.available,
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: glassMode ? Colors.white : colors.success,
                    ),
                  ),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: glassMode
                      ? [
                          Colors.white.withValues(alpha: 0.85),
                          Colors.white.withValues(alpha: 0.65),
                        ]
                      : [
                          colors.success,
                          colors.success.withValues(alpha: 0.8),
                        ],
                ),
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: glassMode
                        ? Colors.white.withValues(alpha: 0.2)
                        : colors.success.withValues(alpha: 0.3),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Text(
                'CHF ${service.price.toStringAsFixed(0)}',
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  color: glassMode ? Colors.black87 : Colors.white,
                  letterSpacing: -0.3,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            onPressed: service.isAvailable
                ? () {
                    HapticFeedback.mediumImpact();
                    _showBookingDialog(
                      context,
                      service,
                      colors,
                      glassMode: glassMode,
                    );
                  }
                : null,
            style: ElevatedButton.styleFrom(
              backgroundColor: glassMode ? Colors.white : colors.primaryAccent,
              foregroundColor: glassMode ? Colors.black87 : Colors.white,
              disabledBackgroundColor: glassMode
                  ? Colors.white.withValues(alpha: 0.3)
                  : colors.textTertiary,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              elevation: 0,
              padding: const EdgeInsets.symmetric(vertical: 16),
              shadowColor: glassMode
                  ? Colors.transparent
                  : colors.primaryAccent.withValues(alpha: 0.3),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.calendar_today,
                  size: 18,
                  color: glassMode ? Colors.black87 : Colors.white,
                ),
                const SizedBox(width: 8),
                Text(
                  service.isAvailable
                      ? l10n.tenantServicesBookServiceButton
                      : l10n.tenantServicesUnavailableLabel,
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    letterSpacing: -0.3,
                    color: glassMode ? Colors.black87 : Colors.white,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );

    if (glassMode) {
      return GlassContainer(
        padding: const EdgeInsets.all(20),
        child: child,
      );
    }

    return Container(
      decoration: BoxDecoration(
        color: colors.surfaceCards.withValues(alpha: 0.95),
        borderRadius: borderRadius,
        border: Border.all(color: colors.borderLight),
        boxShadow: [
          BoxShadow(
            color: colors.shadowColor,
            blurRadius: 15,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: child,
      ),
    );
  }

  Widget _buildEmptyState(
    AppLocalizations l10n,
    DynamicAppColors colors, {
    required bool glassMode,
  }) {
    final titleColor = _primaryTextColor(colors, glassMode);
    final subtitleColor = _secondaryTextColor(colors, glassMode);
    final iconColor =
        glassMode ? Colors.white.withValues(alpha: 0.85) : colors.textTertiary;

    final content = Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(
          Icons.business_center_outlined,
          size: 64,
          color: iconColor,
        ),
        const SizedBox(height: 16),
        Text(
          l10n.tenantServicesNoServicesTitle,
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w600,
            color: titleColor,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          l10n.tenantServicesNoServicesBody,
          style: TextStyle(
            fontSize: 14,
            color: subtitleColor,
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );

    if (glassMode) {
      return Center(
        child: GlassContainer(
          padding: const EdgeInsets.all(28),
          child: content,
        ),
      );
    }

    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [content],
      ),
    );
  }

  void _showBookingDialog(
    BuildContext context,
    TenantService service,
    DynamicAppColors colors, {
    required bool glassMode,
  }) {
    final l10n = AppLocalizations.of(context)!;
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(l10n.tenantServicesBookDialogTitle(service.name)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              l10n.tenantServicesServiceLine(service.name),
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 8),
            Text(
              l10n.tenantServicesProviderLine(service.provider.isNotEmpty
                  ? service.provider
                  : l10n.tenantServicesServiceProviderLabel),
              style: TextStyle(color: colors.textSecondary),
            ),
            const SizedBox(height: 8),
            Text(
              l10n.tenantServicesPriceLine(
                  'CHF ${service.price.toStringAsFixed(2)}'),
              style: TextStyle(color: colors.textSecondary),
            ),
            const SizedBox(height: 16),
            Text(
              l10n.tenantServicesContactInfoLabel,
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 4),
            Text(
              service.contactInfo.isNotEmpty
                  ? service.contactInfo
                  : l10n.tenantServicesContactInfoUnavailable,
              style: TextStyle(color: colors.textSecondary),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text(l10n.cancel),
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
            child: Text(l10n.tenantServicesContactProviderButton),
          ),
        ],
      ),
    );
  }

  void _showBookingConfirmation(
      BuildContext context, TenantService service, DynamicAppColors colors) {
    final l10n = AppLocalizations.of(context)!;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          l10n.tenantServicesContactInfoProvided(
            service.name,
            service.provider.isNotEmpty
                ? service.provider
                : l10n.tenantServicesServiceProviderLabel,
          ),
        ),
        backgroundColor: colors.success,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        margin: const EdgeInsets.all(16),
      ),
    );
  }

  Color _primaryTextColor(DynamicAppColors colors, bool glassMode) =>
      glassMode ? Colors.white : colors.textPrimary;

  Color _secondaryTextColor(DynamicAppColors colors, bool glassMode) =>
      glassMode ? Colors.white.withValues(alpha: 0.8) : colors.textSecondary;
}
