import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:intl/intl.dart';
import '../../../../core/providers/dynamic_colors_provider.dart';
import '../../../../core/widgets/common_bottom_nav.dart';
import '../../../../core/providers/navigation_provider.dart';
import '../../../../core/providers/currency_provider.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../../../property/presentation/providers/property_providers.dart';
import '../../../property/domain/models/property.dart';
import '../providers/activity_provider.dart';
import '../../domain/models/activity.dart';

class TenantDashboard extends ConsumerStatefulWidget {
  const TenantDashboard({super.key});

  @override
  ConsumerState<TenantDashboard> createState() => _TenantDashboardState();
}

class _TenantDashboardState extends ConsumerState<TenantDashboard> 
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<double> _slideAnimation;

  // Helper method for responsive font sizes
  double _getResponsiveFontSize(BuildContext context, double baseFontSize) {
    final screenWidth = MediaQuery.of(context).size.width;
    if (screenWidth < 360) {
      return baseFontSize * 0.85; // Smaller phones
    } else if (screenWidth < 400) {
      return baseFontSize * 0.9;  // Medium phones
    }
    return baseFontSize; // Tablets and larger
  }

  @override
  void initState() {
    super.initState();
    // Set navigation index to Dashboard (0) when this page is loaded
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(routeAwareNavigationProvider.notifier).setIndex(0);
      // Refresh data when returning to dashboard
      ref.invalidate(tenantPropertiesProvider);
    });
    
    _setupAnimations();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Refresh data when dependencies change (e.g., when returning to this page)
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.invalidate(tenantPropertiesProvider);
    });
  }

  void _setupAnimations() {
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    );
    
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0)
        .animate(CurvedAnimation(parent: _animationController, curve: Curves.easeOut));
    
    _slideAnimation = Tween<double>(begin: 30.0, end: 0.0)
        .animate(CurvedAnimation(parent: _animationController, curve: Curves.easeOut));
    
    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  String _getGreeting(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final hour = DateTime.now().hour;
    if (hour < 12) {
      return l10n.goodMorning;
    } else if (hour < 17) {
      return l10n.goodAfternoon;
    }
    return l10n.goodEvening;
  }

  String _formatCurrency(double amount, String currency) {
    final format = NumberFormat.currency(
      symbol: _getCurrencySymbol(currency),
      decimalDigits: 0,
    );
    return format.format(amount);
  }

  String _getCurrencySymbol(String currency) {
    switch (currency.toUpperCase()) {
      case 'USD':
        return '\$';
      case 'EUR':
        return '€';
      case 'CHF':
        return 'CHF ';
      default:
        return '\$';
    }
  }

  @override
  Widget build(BuildContext context) {
    final currentUser = ref.watch(currentUserProvider);
    final propertiesAsync = ref.watch(tenantPropertiesProvider);
    final currency = ref.watch(currencyProvider);
    final colors = ref.watch(dynamicColorsProvider);
    
    return Scaffold(
      backgroundColor: Colors.transparent,
      extendBodyBehindAppBar: true,
      appBar: _buildAppBar(currentUser?.fullName ?? 'Tenant', colors),
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
        child: SafeArea(
        child: propertiesAsync.when(
          data: (properties) {
            return AnimatedBuilder(
              animation: _animationController,
              builder: (context, child) {
                return Transform.translate(
                  offset: Offset(0, _slideAnimation.value),
                  child: Opacity(
                    opacity: _fadeAnimation.value,
                    child: RefreshIndicator(
                      onRefresh: () async {
                        HapticFeedback.lightImpact();
                        ref.invalidate(tenantPropertiesProvider);
                        await Future.delayed(const Duration(seconds: 1));
                      },
                      color: colors.primaryAccent,
                      backgroundColor: Colors.white,
                      child: SingleChildScrollView(
                        physics: const AlwaysScrollableScrollPhysics(),
                        padding: const EdgeInsets.all(20),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _buildWelcomeSection(currentUser?.fullName ?? 'Tenant', colors),
                            const SizedBox(height: 24),
                            _buildSearchBar(colors),
                            const SizedBox(height: 24),
                            if (properties.isNotEmpty) 
                              _buildPropertyCard(properties.first, currency, colors)
                            else
                              _buildNoPropertyCard(colors),
                            const SizedBox(height: 24),
                            _buildQuickActions(colors),
                            const SizedBox(height: 24),
                            _buildRecentActivity(colors),
                            const SizedBox(height: 100), // Increased padding for bottom nav
                          ],
                        ),
                      ),
                    ),
                  ),
                );
              },
            );
          },
          loading: () => Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  colors.surfaceCards,
                  colors.surfaceSecondary,
                ],
              ),
            ),
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: colors.surfaceCards.withValues(alpha: 0.95),
                      borderRadius: BorderRadius.circular(16),
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
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        SizedBox(
                          width: 32,
                          height: 32,
                          child: CircularProgressIndicator(
                            valueColor: AlwaysStoppedAnimation<Color>(colors.primaryAccent),
                            strokeWidth: 3,
                          ),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'Loading your dashboard...',
                          style: TextStyle(
                            color: colors.textPrimary,
                            fontSize: 16,
                            fontWeight: FontWeight.w500,
                            inherit: true,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          error: (error, stackTrace) {
            print('Tenant Dashboard Error: $error');
            print('Stack trace: $stackTrace');
            return Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    colors.surfaceCards,
                    colors.surfaceSecondary,
                  ],
                ),
              ),
              child: Center(
                child: Container(
                  margin: const EdgeInsets.all(20),
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: colors.surfaceCards.withValues(alpha: 0.95),
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
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: colors.error.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Icon(Icons.error_outline, size: 48, color: colors.error),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'Error loading dashboard',
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
                          color: colors.textSecondary,
                          inherit: true,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 20),
                      Container(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              colors.primaryAccent,
                              colors.primaryAccent.withValues(alpha: 0.8),
                            ],
                          ),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: ElevatedButton(
                          onPressed: () {
                            ref.invalidate(tenantPropertiesProvider);
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.transparent,
                            shadowColor: Colors.transparent,
                            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          child: const Text(
                            'Retry',
                            style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        ),
        ),
      ),
      bottomNavigationBar: const CommonBottomNav(),
    );
  }

  PreferredSizeWidget _buildAppBar(String name, DynamicAppColors colors) {
    return AppBar(
      backgroundColor: colors.primaryBackground,
      elevation: 0,
      systemOverlayStyle: colors.isDark ? SystemUiOverlayStyle.light : SystemUiOverlayStyle.dark,
      centerTitle: true,
      actions: [
        Container(
          margin: const EdgeInsets.only(right: 16, top: 8, bottom: 8),
          decoration: BoxDecoration(
            color: colors.surfaceCards,
            borderRadius: BorderRadius.circular(8),
            boxShadow: [
              BoxShadow(
                color: colors.shadowColor,
                blurRadius: 12,
                offset: const Offset(0, 4),
                spreadRadius: 0,
              ),
            ],
          ),
          child: IconButton(
            icon: Icon(Icons.notifications_outlined, color: colors.textSecondary, size: 22),
            onPressed: () => HapticFeedback.lightImpact(),
          ),
        ),
      ],
    );
  }

  Widget _buildWelcomeSection(String userName, DynamicAppColors colors) {
    return Container(
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        color: colors.surfaceCards,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: colors.shadowColor,
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
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: const Color(0xFF3B82F6),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  Icons.waving_hand_rounded,
                  color: Colors.white,
                  size: 24,
                ),
              ),
              const SizedBox(width: 20),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _getGreeting(context),
                      style: TextStyle(
                        fontSize: 14,
                        color: colors.textSecondary,
                        fontWeight: FontWeight.w500,
                        letterSpacing: -0.1,
                        inherit: true,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      userName,
                      style: TextStyle(
                        fontSize: _getResponsiveFontSize(context, 32),
                        fontWeight: FontWeight.w800,
                        color: colors.textPrimary,
                        letterSpacing: -0.8,
                        height: 1.1,
                        inherit: true,
                      ),
                      overflow: TextOverflow.ellipsis,
                      maxLines: 2,
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: const Color(0xFFDCFCE7), // Grün Background
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 8,
                      height: 8,
                      decoration: BoxDecoration(
                        color: const Color(0xFF10B981),
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      'Online',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: const Color(0xFF10B981),
                        letterSpacing: 0.5,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            decoration: BoxDecoration(
              color: const Color(0xFFF1F5F9),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.home_outlined,
                  color: const Color(0xFF3B82F6),
                  size: 20,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Your rental space awaits',
                    style: TextStyle(
                      fontSize: 15,
                      color: const Color(0xFF3B82F6),
                      fontWeight: FontWeight.w600,
                      letterSpacing: -0.2,
                    ),
                    overflow: TextOverflow.ellipsis,
                    maxLines: 2,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchBar(DynamicAppColors colors) {
    return Container(
      decoration: BoxDecoration(
        color: colors.surfaceCards,
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
        onTap: () {
          HapticFeedback.lightImpact();
          context.push('/tenant-search');
        },
        decoration: InputDecoration(
          hintText: 'Search properties, maintenance, messages...',
          hintStyle: TextStyle(
            color: colors.textSecondary,
            fontSize: 15,
            fontWeight: FontWeight.w500,
            letterSpacing: -0.1,
            inherit: true,
          ),
          prefixIcon: Container(
            padding: const EdgeInsets.all(12),
            child: Icon(
              Icons.search_outlined, 
              color: colors.textSecondary,
              size: 20,
            ),
          ),
          suffixIcon: Container(
            margin: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: colors.surfaceSecondary.withValues(alpha: 0.5),
              borderRadius: BorderRadius.circular(8),
            ),
            child: IconButton(
              onPressed: () {
                HapticFeedback.lightImpact();
                // TODO: Show filter options for tenant
              },
              icon: Icon(
                Icons.filter_list_outlined,
                color: colors.textSecondary,
                size: 18,
              ),
            ),
          ),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
        ),
        style: TextStyle(
          color: colors.textPrimary,
          fontSize: 15,
          fontWeight: FontWeight.w500,
          letterSpacing: -0.1,
          inherit: true,
        ),
      ),
    );
  }

  Widget _buildPropertyCard(Property property, String currency, DynamicAppColors colors) {
    return GestureDetector(
      onTap: () {
        HapticFeedback.lightImpact();
        context.push('/property/${property.id}');
      },
      child: Container(
        padding: const EdgeInsets.all(32.0),
        decoration: BoxDecoration(
          color: colors.surfaceCards,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: colors.shadowColor,
              blurRadius: 24,
              offset: const Offset(0, 8),
              spreadRadius: 0,
            ),
            BoxShadow(
              color: colors.shadowColor.withValues(alpha: 0.04),
              blurRadius: 6,
              offset: const Offset(0, 2),
              spreadRadius: 0,
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: colors.primaryAccent,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    Icons.home_outlined,
                    color: Colors.white,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 20),
                Expanded(
                  child: Text(
                    'Your Property',
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.w800,
                      color: colors.textPrimary,
                      letterSpacing: -0.6,
                      inherit: true,
                    ),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: colors.success.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    'ACTIVE',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: colors.success,
                      letterSpacing: 0.5,
                      inherit: true,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 28),
            Container(
              padding: const EdgeInsets.all(24.0),
              decoration: BoxDecoration(
                color: colors.surfaceSecondary,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: colors.borderLight,
                  width: 1,
                ),
                boxShadow: [
                  BoxShadow(
                    color: colors.shadowColor,
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                    spreadRadius: 0,
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
                          color: colors.surfaceCards,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Icon(
                          Icons.location_on_outlined, 
                          size: 20, 
                          color: colors.primaryAccent,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              property.address.street,
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.w700,
                                color: colors.textPrimary,
                                letterSpacing: -0.3,
                                inherit: true,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              '${property.address.city}, ${property.address.postalCode}',
                              style: TextStyle(
                                fontSize: 14,
                                color: colors.textSecondary,
                                fontWeight: FontWeight.w500,
                                letterSpacing: -0.1,
                                inherit: true,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Monthly Rent',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: colors.textTertiary,
                                letterSpacing: 0.5,
                                inherit: true,
                              ),
                            ),
                            const SizedBox(height: 6),
                            Text(
                              _formatCurrency(property.rentAmount, currency),
                              style: TextStyle(
                                fontSize: 24,
                                fontWeight: FontWeight.w800,
                                color: colors.success,
                                letterSpacing: -0.6,
                                inherit: true,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 20),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Property Size',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: colors.textTertiary,
                                letterSpacing: 0.5,
                                inherit: true,
                              ),
                            ),
                            const SizedBox(height: 6),
                            Text(
                              '${property.details.size} m²',
                              style: TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.w700,
                                color: colors.textPrimary,
                                letterSpacing: -0.4,
                                inherit: true,
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
          ],
        ),
      ),
    );
  }

  Widget _buildNoPropertyCard(DynamicAppColors colors) {
    return Container(
      padding: const EdgeInsets.all(32.0),
      decoration: BoxDecoration(
        color: colors.surfaceCards,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: colors.shadowColor,
            blurRadius: 24,
            offset: const Offset(0, 8),
            spreadRadius: 0,
          ),
          BoxShadow(
            color: colors.shadowColor.withValues(alpha: 0.04),
            blurRadius: 6,
            offset: const Offset(0, 2),
            spreadRadius: 0,
          ),
        ],
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: colors.warning.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              Icons.home_work_outlined,
              color: colors.warning,
              size: 48,
            ),
          ),
          const SizedBox(height: 24),
          Text(
            'No Property Assigned',
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w800,
              color: colors.textPrimary,
              letterSpacing: -0.6,
              inherit: true,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            'Contact your landlord to get access to your rental property information.',
            style: TextStyle(
              fontSize: 15,
              color: colors.textSecondary,
              fontWeight: FontWeight.w500,
              letterSpacing: -0.1,
              inherit: true,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 16),
            decoration: BoxDecoration(
              color: colors.primaryAccent,
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: colors.primaryAccent.withValues(alpha: 0.3),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                  spreadRadius: 0,
                ),
              ],
            ),
            child: Text(
              'Contact Landlord',
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w600,
                color: Colors.white,
                letterSpacing: -0.1,
              ),
              textAlign: TextAlign.center,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickActions(DynamicAppColors colors) {
    return Container(
      padding: const EdgeInsets.all(24.0), // Reduced from 32.0
      decoration: BoxDecoration(
        color: colors.surfaceCards,
        borderRadius: BorderRadius.circular(14), // Reduced from 16
        boxShadow: [
          BoxShadow(
            color: colors.shadowColor,
            blurRadius: 20, // Reduced from 24
            offset: const Offset(0, 6), // Reduced from 8
            spreadRadius: 0,
          ),
          BoxShadow(
            color: colors.shadowColor.withValues(alpha: 0.04),
            blurRadius: 6,
            offset: const Offset(0, 2),
            spreadRadius: 0,
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: colors.primaryAccent,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  Icons.flash_on_outlined,
                  color: Colors.white,
                  size: 24,
                ),
              ),
              const SizedBox(width: 20),
              Expanded(
                child: Text(
                  'Quick Actions',
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w800,
                    color: colors.textPrimary,
                    letterSpacing: -0.6,
                    inherit: true,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 28),
          // Use a more compact grid layout for mobile
          LayoutBuilder(
            builder: (context, constraints) {
              if (constraints.maxWidth < 400) {
                // Mobile layout - 2 columns
                return Column(
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: _buildActionCard(
                            'Maintenance',
                            Icons.build_circle_outlined,
                            colors.error,
                            () {
                              HapticFeedback.mediumImpact();
                              context.push('/tenant/maintenance');
                            },
                            colors,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _buildActionCard(
                            'Messages',
                            Icons.chat_bubble_outline,
                            colors.success,
                            () {
                              HapticFeedback.mediumImpact();
                              context.push('/conversations');
                            },
                            colors,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: _buildActionCard(
                            'Auto Payment',
                            Icons.payment_outlined,
                            colors.primaryAccent,
                            () {
                              HapticFeedback.mediumImpact();
                              context.push('/payments/auto-setup');
                            },
                            colors,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _buildActionCard(
                            'Book Services',
                            Icons.room_service_outlined,
                            colors.info,
                            () {
                              HapticFeedback.mediumImpact();
                              context.push('/tenant/services');
                            },
                            colors,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: _buildActionCard(
                            'Payment History',
                            Icons.history_outlined,
                            colors.warning,
                            () {
                              HapticFeedback.mediumImpact();
                              context.push('/payments/history');
                            },
                            colors,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _buildActionCard(
                            'Settings',
                            Icons.settings_outlined,
                            colors.luxuryGold,
                            () {
                              HapticFeedback.mediumImpact();
                              context.push('/settings');
                            },
                            colors,
                          ),
                        ),
                      ],
                    ),
                  ],
                );
              } else {
                // Tablet/desktop layout - 3 columns
                return Column(
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: _buildActionCard(
                            'Maintenance',
                            Icons.build_circle_outlined,
                            colors.error,
                            () {
                              HapticFeedback.mediumImpact();
                              context.push('/tenant/maintenance');
                            },
                            colors,
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: _buildActionCard(
                            'Messages',
                            Icons.chat_bubble_outline,
                            colors.success,
                            () {
                              HapticFeedback.mediumImpact();
                              context.push('/conversations');
                            },
                            colors,
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: _buildActionCard(
                            'Auto Payment',
                            Icons.payment_outlined,
                            colors.primaryAccent,
                            () {
                              HapticFeedback.mediumImpact();
                              context.push('/payments/auto-setup');
                            },
                            colors,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          child: _buildActionCard(
                            'Book Services',
                            Icons.room_service_outlined,
                            colors.info,
                            () {
                              HapticFeedback.mediumImpact();
                              context.push('/tenant/services');
                            },
                            colors,
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: _buildActionCard(
                            'Payment History',
                            Icons.history_outlined,
                            colors.warning,
                            () {
                              HapticFeedback.mediumImpact();
                              context.push('/payments/history');
                            },
                            colors,
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: _buildActionCard(
                            'Settings',
                            Icons.settings_outlined,
                            colors.luxuryGold,
                            () {
                              HapticFeedback.mediumImpact();
                              context.push('/settings');
                            },
                            colors,
                          ),
                        ),
                      ],
                    ),
                  ],
                );
              }
            },
          ),
        ],
      ),
    );
  }

  Widget _buildActionCard(String title, IconData icon, Color iconColor, VoidCallback onTap, DynamicAppColors colors) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(14), // Reduced from 20
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              iconColor.withValues(alpha: 0.08),
              iconColor.withValues(alpha: 0.04),
            ],
          ),
          borderRadius: BorderRadius.circular(14), // Reduced from 16
          border: Border.all(
            color: iconColor.withValues(alpha: 0.15),
            width: 1,
          ),
          boxShadow: [
            BoxShadow(
              color: iconColor.withValues(alpha: 0.15),
              blurRadius: 12, // Reduced from 16
              offset: const Offset(0, 4), // Reduced from 6
              spreadRadius: 0,
            ),
            BoxShadow(
              color: colors.shadowColor.withValues(alpha: 0.04),
              blurRadius: 6, // Reduced from 8
              offset: const Offset(0, 2),
              spreadRadius: 0,
            ),
          ],
        ),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(12), // Reduced from 16
              decoration: BoxDecoration(
                color: colors.surfaceCards,
                borderRadius: BorderRadius.circular(10), // Reduced from 12
                border: Border.all(
                  color: colors.borderLight.withValues(alpha: 0.5),
                  width: 1,
                ),
                boxShadow: [
                  BoxShadow(
                    color: colors.shadowColor.withValues(alpha: 0.1),
                    blurRadius: 6, // Reduced from 8
                    offset: const Offset(0, 2),
                    spreadRadius: 0,
                  ),
                ],
              ),
              child: Icon(
                icon, 
                size: 20, // Reduced from 24
                color: iconColor,
              ),
            ),
            const SizedBox(height: 12), // Reduced from 16
            Text(
              title,
              style: TextStyle(
                fontSize: 13, // Reduced from 14
                fontWeight: FontWeight.w700,
                color: colors.textPrimary,
                letterSpacing: -0.2,
                inherit: true,
              ),
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRecentActivity(DynamicAppColors colors) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
          colors: [
            colors.surfaceCards,
            colors.luxuryGradientStart,
          ],
        ),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: colors.borderLight,
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: colors.shadowColor,
            blurRadius: 20,
            offset: const Offset(0, 8),
            spreadRadius: 0,
          ),
          BoxShadow(
            color: colors.overlayWhite,
            blurRadius: 1,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Recent Activity',
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.w700,
                color: colors.textPrimary,
                inherit: true,
              ),
            ),
            const SizedBox(height: 20),
            Consumer(
              builder: (context, ref, child) {
                final activitiesAsync = ref.watch(recentActivitiesProvider);
                
                return activitiesAsync.when(
                  data: (activities) {
                    if (activities.isEmpty) {
                      return _buildEmptyActivityState(colors);
                    }
                    
                    return Column(
                      children: activities.take(3).map((activity) => 
                        Padding(
                          padding: const EdgeInsets.only(bottom: 16),
                          child: _buildActivityItem(activity, colors),
                        )
                      ).toList(),
                    );
                  },
                  loading: () => Center(
                    child: SizedBox(
                      width: 24,
                      height: 24,
                      child: CircularProgressIndicator(
                        valueColor: AlwaysStoppedAnimation<Color>(colors.primaryAccent),
                        strokeWidth: 2,
                      ),
                    ),
                  ),
                  error: (error, stack) => _buildEmptyActivityState(colors),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyActivityState(DynamicAppColors colors) {
    return Container(
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            colors.textSecondary.withValues(alpha: 0.1),
            colors.textSecondary.withValues(alpha: 0.05),
          ],
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: colors.textSecondary.withValues(alpha: 0.15),
          width: 1,
        ),
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  colors.textSecondary.withValues(alpha: 0.15),
                  colors.textSecondary.withValues(alpha: 0.05),
                ],
              ),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: colors.textSecondary.withValues(alpha: 0.2),
                width: 1,
              ),
            ),
            child: Icon(
              Icons.history_rounded,
              size: 32,
              color: colors.textSecondary,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'No Recent Activity',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: colors.textSecondary,
              inherit: true,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Your recent activities will appear here',
            style: TextStyle(
              fontSize: 14,
              color: colors.textSecondary.withValues(alpha: 0.8),
              fontWeight: FontWeight.w500,
              inherit: true,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildActivityItem(Activity activity, DynamicAppColors colors) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            colors.surfaceCards,
            _getActivityColor(activity.type, colors).withValues(alpha: 0.02),
          ],
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: _getActivityColor(activity.type, colors).withValues(alpha: 0.1),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: colors.shadowColor,
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  _getActivityColor(activity.type, colors).withValues(alpha: 0.2),
                  _getActivityColor(activity.type, colors).withValues(alpha: 0.1),
                ],
              ),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              _getActivityIcon(activity.type),
              color: _getActivityColor(activity.type, colors),
              size: 20,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  activity.title,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: colors.textPrimary,
                    inherit: true,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                Text(
                  activity.description,
                  style: TextStyle(
                    fontSize: 12,
                    color: colors.textSecondary,
                    inherit: true,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Text(
            activity.timeAgo,
            style: TextStyle(
              fontSize: 12,
              color: colors.textSecondary,
              fontWeight: FontWeight.w500,
              inherit: true,
            ),
          ),
        ],
      ),
    );
  }

  Color _getActivityColor(String type, DynamicAppColors colors) {
    switch (type.toLowerCase()) {
      case 'payment':
        return colors.success;
      case 'maintenance':
        return colors.warning;
      case 'message':
        return colors.info;
      case 'service':
        return colors.primaryAccent;
      case 'property':
        return colors.luxuryGold;
      default:
        return colors.textSecondary;
    }
  }

  IconData _getActivityIcon(String type) {
    switch (type.toLowerCase()) {
      case 'payment':
        return Icons.payment_rounded;
      case 'maintenance':
        return Icons.build_rounded;
      case 'message':
        return Icons.chat_bubble_rounded;
      case 'service':
        return Icons.room_service_rounded;
      case 'property':
        return Icons.home_rounded;
      default:
        return Icons.notifications_rounded;
    }
  }
}
