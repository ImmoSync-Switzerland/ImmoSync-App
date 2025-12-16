import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../../l10n/app_localizations.dart';
import '../../../../core/providers/dynamic_colors_provider.dart';
import '../../../../core/widgets/common_bottom_nav.dart';
import '../../../home/presentation/models/dashboard_design.dart';
import '../../../home/presentation/pages/glass_dashboard_shared.dart';
import '../../../settings/providers/settings_provider.dart';
import '../../../services/domain/models/service.dart' as ServiceModel;
import '../../../services/presentation/providers/service_providers.dart';

// UI Service model for landlord booking
class BookableService {
  final String id;
  final String name;
  final String description;
  final String category;
  final double price;
  final String provider;
  final String contactInfo;
  final IconData icon;
  final bool isAvailable;

  BookableService({
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

  factory BookableService.fromServiceModel(ServiceModel.Service service) {
    return BookableService(
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
      case 'security':
        return Icons.security_outlined;
      case 'gardening':
        return Icons.grass_outlined;
      case 'utilities':
        return Icons.electrical_services_outlined;
      case 'general':
        return Icons.room_service_outlined;
      default:
        return Icons.miscellaneous_services_outlined;
    }
  }
}

class LandlordServicesBookingPage extends ConsumerStatefulWidget {
  const LandlordServicesBookingPage({super.key});

  @override
  ConsumerState<LandlordServicesBookingPage> createState() =>
      _LandlordServicesBookingPageState();
}

class _LandlordServicesBookingPageState
    extends ConsumerState<LandlordServicesBookingPage> {
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

    // Get all available services (admin-managed)
    final servicesAsync = ref.watch(allAvailableServicesProvider);

    final Widget content = servicesAsync.when(
      data: (services) {
        final bookableServices =
            services.map(BookableService.fromServiceModel).toList();
        return Column(
          children: [
            _buildHeader(colors, glassMode: glassMode),
            _buildSearchAndFilter(l10n, colors, glassMode: glassMode),
            Expanded(
              child: bookableServices.isEmpty
                  ? _buildEmptyState(l10n, colors, glassMode: glassMode)
                  : _buildServicesList(
                      bookableServices,
                      l10n,
                      colors,
                      glassMode: glassMode,
                    ),
            ),
          ],
        );
      },
      loading: () => _buildLoadingState(l10n, colors, glassMode: glassMode),
      error: (error, stack) => _buildErrorState(
        error,
        l10n,
        colors,
        glassMode: glassMode,
      ),
    );

    final actions = <Widget>[
      IconButton(
        icon: const Icon(Icons.refresh),
        color: glassMode ? Colors.white : colors.textPrimary,
        tooltip: l10n.refresh,
        onPressed: () => ref.invalidate(allAvailableServicesProvider),
      ),
    ];

    if (glassMode) {
      return GlassPageScaffold(
        title: l10n.services,
        actions: actions,
        body: content,
      );
    }

    return Scaffold(
      backgroundColor: Colors.transparent,
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: Text(
          l10n.services,
          style: const TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w700,
            letterSpacing: -0.5,
          ),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: IconThemeData(color: colors.textPrimary),
        actions: actions,
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: colors.createGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: SafeArea(child: content),
      ),
      bottomNavigationBar: const CommonBottomNav(),
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
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: _primaryTextColor(colors, glassMode),
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
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.08),
              blurRadius: 18,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: loader,
      ),
    );
  }

  Widget _buildErrorState(
    Object error,
    AppLocalizations l10n,
    DynamicAppColors colors, {
    required bool glassMode,
  }) {
    final Color primary = _primaryTextColor(colors, glassMode);
    final Color secondary = _secondaryTextColor(colors, glassMode);

    final body = Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(
          Icons.error_outline,
          size: 64,
          color: glassMode ? Colors.white : colors.error,
        ),
        const SizedBox(height: 16),
        Text(
          'Fehler beim Laden der Services',
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
          onPressed: () => ref.invalidate(allAvailableServicesProvider),
          style: ElevatedButton.styleFrom(
            backgroundColor: glassMode ? Colors.white : colors.primaryAccent,
            foregroundColor: glassMode ? Colors.black87 : colors.textOnAccent,
          ),
          child: const Text('Erneut versuchen'),
        ),
      ],
    );

    if (glassMode) {
      return Center(
        child: GlassContainer(
          padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 30),
          child: body,
        ),
      );
    }

    return Center(child: body);
  }

  Widget _buildHeader(DynamicAppColors colors, {required bool glassMode}) {
    if (glassMode) {
      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 12),
        child: GlassContainer(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.24),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: const Icon(
                      Icons.room_service_outlined,
                      color: Colors.white,
                      size: 28,
                    ),
                  ),
                  const SizedBox(width: 16),
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Verf“bare Services',
                          style: TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.w900,
                            color: Colors.white,
                            letterSpacing: -0.5,
                          ),
                        ),
                        SizedBox(height: 6),
                        Text(
                          'Buchen Sie professionelle Services',
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.white,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      );
    }

    return Container(
      width: double.infinity,
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            colors.primaryAccent,
            colors.primaryAccent.withValues(alpha: 0.8),
          ],
        ),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: colors.primaryAccent.withValues(alpha: 0.3),
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
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: const Icon(
                  Icons.room_service_outlined,
                  color: Colors.white,
                  size: 28,
                ),
              ),
              const SizedBox(width: 16),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Verfügbare Services',
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.w900,
                        color: Colors.white,
                        letterSpacing: -0.5,
                      ),
                    ),
                    SizedBox(height: 6),
                    Text(
                      'Buchen Sie professionelle Services',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.white,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSearchAndFilter(
    AppLocalizations l10n,
    DynamicAppColors colors, {
    required bool glassMode,
  }) {
    final BoxDecoration fieldDecoration = BoxDecoration(
      color: glassMode ? Colors.white.withValues(alpha: 0.12) : Colors.white,
      borderRadius: BorderRadius.circular(16),
      border: glassMode
          ? Border.all(color: Colors.white.withValues(alpha: 0.24))
          : null,
      boxShadow: glassMode
          ? null
          : [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.08),
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
            ],
    );

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        children: [
          Container(
            decoration: fieldDecoration,
            child: TextField(
              onChanged: (value) =>
                  setState(() => _searchQuery = value.toLowerCase()),
              decoration: InputDecoration(
                hintText: 'Services durchsuchen...',
                hintStyle: TextStyle(
                  color: glassMode
                      ? Colors.white.withValues(alpha: 0.75)
                      : colors.textSecondary.withValues(alpha: 0.6),
                  fontSize: 15,
                ),
                prefixIcon: Icon(
                  Icons.search,
                  color: glassMode ? Colors.white : colors.primaryAccent,
                  size: 22,
                ),
                filled: true,
                fillColor: glassMode ? Colors.transparent : Colors.white,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: BorderSide.none,
                ),
                contentPadding:
                    const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
              ),
              style: TextStyle(
                color: _primaryTextColor(colors, glassMode),
                fontSize: 15,
              ),
            ),
          ),
          const SizedBox(height: 16),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                _buildCategoryChip('all', 'Alle', colors, glassMode: glassMode),
                const SizedBox(width: 8),
                _buildCategoryChip('maintenance', 'Wartung', colors,
                    glassMode: glassMode),
                const SizedBox(width: 8),
                _buildCategoryChip('cleaning', 'Reinigung', colors,
                    glassMode: glassMode),
                const SizedBox(width: 8),
                _buildCategoryChip('repair', 'Reparatur', colors,
                    glassMode: glassMode),
                const SizedBox(width: 8),
                _buildCategoryChip('security', 'Sicherheit', colors,
                    glassMode: glassMode),
                const SizedBox(width: 8),
                _buildCategoryChip('gardening', 'Garten', colors,
                    glassMode: glassMode),
                const SizedBox(width: 8),
                _buildCategoryChip('utilities', 'Versorgung', colors,
                    glassMode: glassMode),
              ],
            ),
          ),
          const SizedBox(height: 8),
        ],
      ),
    );
  }

  Widget _buildCategoryChip(
      String category, String label, DynamicAppColors colors,
      {required bool glassMode}) {
    final isSelected = _selectedCategory == category;
    return GestureDetector(
      onTap: () => setState(() => _selectedCategory = category),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
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
                  ? Colors.white.withValues(alpha: 0.3)
                  : Colors.white.withValues(alpha: 0.14))
              : (isSelected ? null : Colors.white),
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(
              color: isSelected
                  ? (glassMode
                      ? Colors.white.withValues(alpha: 0.22)
                      : colors.primaryAccent.withValues(alpha: 0.3))
                  : Colors.black.withValues(alpha: glassMode ? 0.03 : 0.05),
              blurRadius: isSelected ? 8 : 4,
              offset: Offset(0, isSelected ? 4 : 2),
            ),
          ],
        ),
        child: Text(
          label,
          style: TextStyle(
            color: glassMode
                ? Colors.white
                : (isSelected ? Colors.white : colors.textPrimary),
            fontWeight: isSelected ? FontWeight.w700 : FontWeight.w600,
            fontSize: 14,
            letterSpacing: 0.2,
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState(
    AppLocalizations l10n,
    DynamicAppColors colors, {
    required bool glassMode,
  }) {
    final titleColor = _primaryTextColor(colors, glassMode);
    final secondary = _secondaryTextColor(colors, glassMode);
    final iconColor = glassMode ? Colors.white : colors.primaryAccent;

    final content = Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: glassMode
                ? Colors.white.withValues(alpha: 0.18)
                : colors.primaryAccent.withValues(alpha: 0.1),
            shape: BoxShape.circle,
          ),
          child: Icon(
            Icons.room_service_outlined,
            size: 48,
            color: iconColor,
          ),
        ),
        const SizedBox(height: 20),
        Text(
          'Keine Services verfuegbar',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w600,
            color: titleColor,
          ),
        ),
        const SizedBox(height: 12),
        Text(
          'Derzeit sind keine Services zum Buchen verfuegbar.\\nPruefen Sie spaeter erneut.',
          style: TextStyle(
            fontSize: 14,
            color: secondary,
            height: 1.4,
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

    return Center(child: content);
  }

  Widget _buildServicesList(
    List<BookableService> services,
    AppLocalizations l10n,
    DynamicAppColors colors, {
    required bool glassMode,
  }) {
    final filteredServices = services.where((service) {
      final matchesCategory = _selectedCategory == 'all' ||
          service.category.toLowerCase() == _selectedCategory;
      final matchesSearch = _searchQuery.isEmpty ||
          service.name.toLowerCase().contains(_searchQuery) ||
          service.description.toLowerCase().contains(_searchQuery) ||
          service.provider.toLowerCase().contains(_searchQuery);
      return matchesCategory && matchesSearch && service.isAvailable;
    }).toList();

    if (filteredServices.isEmpty) {
      final titleColor = _primaryTextColor(colors, glassMode);
      final secondary = _secondaryTextColor(colors, glassMode);

      final widget = Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.search_off,
            size: 64,
            color: glassMode ? Colors.white : colors.textSecondary,
          ),
          const SizedBox(height: 16),
          Text(
            'Keine Services gefunden',
            style: TextStyle(fontSize: 18, color: titleColor),
          ),
          const SizedBox(height: 8),
          Text(
            'Versuchen Sie es mit anderen Suchbegriffen.',
            style: TextStyle(fontSize: 14, color: secondary),
            textAlign: TextAlign.center,
          ),
        ],
      );

      if (glassMode) {
        return Center(
          child: GlassContainer(
            padding: const EdgeInsets.all(28),
            child: widget,
          ),
        );
      }

      return Center(child: widget);
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: filteredServices.length,
      itemBuilder: (context, index) {
        final service = filteredServices[index];
        return _buildServiceCard(service, colors, glassMode: glassMode);
      },
    );
  }

  Widget _buildServiceCard(
    BookableService service,
    DynamicAppColors colors, {
    required bool glassMode,
  }) {
    final primary = _primaryTextColor(colors, glassMode);
    final secondary = _secondaryTextColor(colors, glassMode);
    final accent = glassMode ? Colors.white : colors.primaryAccent;
    final successGradient = glassMode
        ? [
            Colors.white.withValues(alpha: 0.85),
            Colors.white.withValues(alpha: 0.65)
          ]
        : [colors.success, colors.success.withValues(alpha: 0.8)];

    final cardBody = Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: glassMode
                        ? [
                            Colors.white.withValues(alpha: 0.25),
                            Colors.white.withValues(alpha: 0.12)
                          ]
                        : [
                            accent.withValues(alpha: 0.15),
                            accent.withValues(alpha: 0.08)
                          ],
                  ),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Icon(
                  service.icon,
                  color: accent,
                  size: 28,
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
                        fontWeight: FontWeight.w800,
                        color: primary,
                        letterSpacing: -0.3,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: glassMode
                            ? Colors.white.withValues(alpha: 0.24)
                            : accent.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        service.category.toUpperCase(),
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: accent,
                          letterSpacing: 0.8,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                decoration: BoxDecoration(
                  gradient: LinearGradient(colors: successGradient),
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: glassMode
                          ? Colors.white.withValues(alpha: 0.2)
                          : colors.success.withValues(alpha: 0.3),
                      blurRadius: 8,
                      offset: const Offset(0, 3),
                    ),
                  ],
                ),
                child: Text(
                  'CHF ',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                    color: glassMode ? Colors.black87 : Colors.white,
                    letterSpacing: 0.3,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            service.description,
            style: TextStyle(
              fontSize: 14,
              color: secondary,
              height: 1.5,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: glassMode
                  ? Colors.white.withValues(alpha: 0.12)
                  : colors.primaryBackground.withValues(alpha: 0.5),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: glassMode
                    ? Colors.white.withValues(alpha: 0.2)
                    : Colors.transparent,
              ),
            ),
            child: Row(
              children: [
                Icon(Icons.business, size: 18, color: accent),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    service.provider,
                    style: TextStyle(
                      fontSize: 14,
                      color: primary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          SizedBox(
            width: double.infinity,
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: glassMode
                      ? [
                          Colors.white.withValues(alpha: 0.85),
                          Colors.white.withValues(alpha: 0.7)
                        ]
                      : [
                          colors.primaryAccent,
                          colors.primaryAccent.withValues(alpha: 0.85)
                        ],
                ),
                borderRadius: BorderRadius.circular(14),
                boxShadow: [
                  BoxShadow(
                    color: glassMode
                        ? Colors.white.withValues(alpha: 0.2)
                        : colors.primaryAccent.withValues(alpha: 0.3),
                    blurRadius: 12,
                    offset: const Offset(0, 6),
                  ),
                ],
              ),
              child: ElevatedButton(
                onPressed: () =>
                    _showBookingDialog(service, glassMode: glassMode),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.transparent,
                  foregroundColor: glassMode ? Colors.black87 : Colors.white,
                  shadowColor: Colors.transparent,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
                child: const Text(
                  'Service buchen',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.3,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );

    if (glassMode) {
      return Padding(
        padding: const EdgeInsets.only(bottom: 16),
        child: GlassContainer(
          padding: EdgeInsets.zero,
          child: cardBody,
        ),
      );
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.08),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: cardBody,
    );
  }

  void _showBookingDialog(BookableService service, {required bool glassMode}) {
    final colors = ref.read(dynamicColorsProvider);

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor:
            glassMode ? Colors.black.withValues(alpha: 0.75) : null,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Service buchen'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Sie moechten "" buchen?',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: glassMode
                    ? Colors.white.withValues(alpha: 0.08)
                    : colors.primaryBackground,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: glassMode
                      ? Colors.white.withValues(alpha: 0.18)
                      : colors.borderLight,
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(service.icon, color: colors.primaryAccent, size: 20),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          service.name,
                          style: const TextStyle(fontWeight: FontWeight.w600),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    service.description,
                    style: TextStyle(
                      fontSize: 14,
                      color: glassMode
                          ? Colors.white.withValues(alpha: 0.85)
                          : colors.textSecondary,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Preis:',
                        style: TextStyle(fontWeight: FontWeight.w600),
                      ),
                      Text(
                        'CHF ',
                        style: TextStyle(
                          fontWeight: FontWeight.w700,
                          color: glassMode ? Colors.white : colors.success,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'Ein Mitarbeiter wird sich in Kuerze mit Ihnen in Verbindung setzen, um die Details zu klaeren.',
              style: TextStyle(
                fontSize: 14,
                color: glassMode
                    ? Colors.white.withValues(alpha: 0.8)
                    : colors.textSecondary,
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Abbrechen'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(context).pop();
              _bookService(service);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: glassMode ? Colors.white : colors.primaryAccent,
              foregroundColor: glassMode ? Colors.black87 : Colors.white,
            ),
            child: const Text('Buchen'),
          ),
        ],
      ),
    );
  }

  void _bookService(BookableService service) {
    final colors = ref.read(dynamicColorsProvider);

    // In a real implementation, this would create a booking request
    // For now, we'll just show a success message
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.check_circle, color: Colors.white),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                'Buchungsanfrage für "${service.name}" wurde gesendet!',
                style: const TextStyle(fontWeight: FontWeight.w600),
              ),
            ),
          ],
        ),
        backgroundColor: colors.success,
        duration: const Duration(seconds: 4),
        action: SnackBarAction(
          label: 'Details',
          textColor: Colors.white,
          onPressed: () {
            // Navigate to booking details or chat
          },
        ),
      ),
    );
  }

  Color _primaryTextColor(DynamicAppColors colors, bool glassMode) =>
      glassMode ? Colors.white : colors.textPrimary;

  Color _secondaryTextColor(DynamicAppColors colors, bool glassMode) =>
      glassMode ? Colors.white.withValues(alpha: 0.8) : colors.textSecondary;
}
