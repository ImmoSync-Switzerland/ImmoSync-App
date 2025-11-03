import 'package:flutter/material.dart';
import 'package:immosync/l10n/app_localizations.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:immosync/core/widgets/app_top_bar.dart';
import 'package:immosync/features/auth/presentation/providers/auth_provider.dart';
import 'package:immosync/features/property/domain/models/property.dart';
import 'package:immosync/features/home/domain/services/dashboard_service.dart';
import 'package:immosync/features/chat/domain/models/conversation.dart';
import 'package:immosync/features/maintenance/domain/models/maintenance_request.dart';
import 'package:immosync/features/subscription/presentation/providers/subscription_providers.dart';
import '../../../../core/providers/dynamic_colors_provider.dart';
import '../../../../core/utils/category_utils.dart';
import '../../../../features/property/presentation/providers/property_providers.dart';
import '../../../../core/providers/currency_provider.dart';
import '../../../../core/widgets/common_bottom_nav.dart';
import '../../../../core/widgets/mongo_image.dart';
import '../../../../core/utils/image_resolver.dart';
import 'package:immosync/core/widgets/user_avatar.dart';

class LandlordDashboard extends ConsumerStatefulWidget {
  const LandlordDashboard({super.key});

  @override
  ConsumerState<LandlordDashboard> createState() => _LandlordDashboardState();
}

class _LandlordDashboardState extends ConsumerState<LandlordDashboard>
    with TickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _slideAnimation;
  late Animation<double> _fadeAnimation;

  // Dashboard data
  final DashboardService _dashboardService = DashboardService();
  List<Conversation> _recentMessages = [];
  List<MaintenanceRequest> _recentMaintenanceRequests = [];
  bool _isLoadingDashboardData = false;
  String _propertyFilter = 'all'; // all, available, occupied, maintenance

  // Helper method for responsive font sizes
  double _getResponsiveFontSize(BuildContext context, double baseFontSize) {
    final screenWidth = MediaQuery.of(context).size.width;
    if (screenWidth < 360) {
      return baseFontSize * 0.85; // Smaller phones
    } else if (screenWidth < 400) {
      return baseFontSize * 0.9; // Medium phones
    }
    return baseFontSize; // Tablets and larger
  }

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    _slideAnimation = Tween<double>(begin: 30.0, end: 0.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeOut),
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );
    _animationController.forward();
    _loadDashboardData();
  }

  Future<void> _loadDashboardData() async {
    final currentUser = ref.read(currentUserProvider);
    if (currentUser == null) return;

    setState(() {
      _isLoadingDashboardData = true;
    });

    try {
      final dashboardData = await _dashboardService.getDashboardData(
        currentUser.id,
        landlordId: currentUser.id,
      );

      if (mounted) {
        setState(() {
          _recentMessages = dashboardData.recentMessages;
          _recentMaintenanceRequests = dashboardData.recentMaintenanceRequests;
          _isLoadingDashboardData = false;
        });
      }
    } catch (e) {
      print('Error loading dashboard data: $e');
      if (mounted) {
        setState(() {
          _isLoadingDashboardData = false;
        });
      }
    }
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final propertiesAsync = ref.watch(landlordPropertiesProvider);
    final currentUser = ref.watch(currentUserProvider);
    final colors = ref.watch(dynamicColorsProvider);
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      backgroundColor: Colors.transparent,
      extendBodyBehindAppBar: true,
      appBar: AppTopBar(
        title: null,
        leading: IconButton(
          tooltip: 'Refresh',
          icon: Icon(Icons.refresh, color: colors.primaryAccent, size: 22),
          onPressed: () {
            HapticFeedback.lightImpact();
            final t = ref.read(propertyRefreshTriggerProvider.notifier);
            t.state = t.state + 1;
            _loadDashboardData();
          },
        ),
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: colors.createGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: SafeArea(
          child: propertiesAsync.when(
            data: (properties) => AnimatedBuilder(
              animation: _animationController,
              builder: (context, child) {
                return Transform.translate(
                  offset: Offset(0, _slideAnimation.value),
                  child: Opacity(
                    opacity: _fadeAnimation.value,
                    child: RefreshIndicator(
                      onRefresh: () async {
                        HapticFeedback.lightImpact();
                        // Manually trigger property refresh
                        final t =
                            ref.read(propertyRefreshTriggerProvider.notifier);
                        t.state = t.state + 1;
                        // Also reload dashboard-specific aggregates
                        await _loadDashboardData();
                      },
                      color: colors.primaryAccent,
                      backgroundColor: colors.primaryBackground,
                      child: SingleChildScrollView(
                        physics: const AlwaysScrollableScrollPhysics(),
                        padding: const EdgeInsets.all(20),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _buildWelcomeSection(currentUser?.fullName ??
                                AppLocalizations.of(context)!.propertyManager),
                            const SizedBox(height: 32),
                            _buildSearchBar(),
                            const SizedBox(height: 32),
                            _buildFinancialOverview(properties, l10n),
                            const SizedBox(height: 24),
                            _buildQuickAccess(),
                            const SizedBox(height: 24),
                            _buildPropertyOverview(properties, l10n),
                            const SizedBox(height: 24),
                            _buildRecentMessages(),
                            const SizedBox(height: 24),
                            _buildMaintenanceRequests(),
                            const SizedBox(
                                height:
                                    100), // Increased padding for bottom nav + FAB
                          ],
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
            loading: () => Consumer(
              builder: (context, ref, child) {
                final colors = ref.watch(dynamicColorsProvider);
                return Center(
                  child: SizedBox(
                    width: 32,
                    height: 32,
                    child: CircularProgressIndicator(
                      valueColor:
                          AlwaysStoppedAnimation<Color>(colors.primaryAccent),
                      strokeWidth: 2.5,
                    ),
                  ),
                );
              },
            ),
            error: (error, stack) => Consumer(
              builder: (context, ref, child) {
                final colors = ref.watch(dynamicColorsProvider);
                return Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.error_outline, size: 48, color: colors.error),
                      const SizedBox(height: 16),
                      Text(
                        AppLocalizations.of(context)!.somethingWentWrong,
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                          color: colors.textPrimary,
                          inherit: true,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        AppLocalizations.of(context)!.pleaseTryAgainLater,
                        style: TextStyle(
                          fontSize: 14,
                          color: colors.textTertiary,
                          inherit: true,
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
        ),
      ),
      bottomNavigationBar: const CommonBottomNav(),
      floatingActionButton: _buildFAB(),
    );
  }

  // Removed legacy _buildAppBar (now using AppTopBar)
  Widget _buildWelcomeSection(String name) {
    final l10n = AppLocalizations.of(context)!;
    final colors = ref.watch(dynamicColorsProvider);

    final screenWidth = MediaQuery.of(context).size.width;
    final bool isSmall = screenWidth < 360;
    final bool isMedium = !isSmall && screenWidth < 400;
    final double cardPadding = isSmall ? 20 : (isMedium ? 24 : 32);
    final double iconSize = isSmall ? 20 : (isMedium ? 22 : 24);
    final double greetingFont = isSmall ? 12 : (isMedium ? 13 : 14);

    return Container(
      padding: EdgeInsets.all(cardPadding),
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
            color: colors.shadowColorMedium,
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
                  Icons.waving_hand_rounded,
                  color: colors.textOnAccent,
                  size: iconSize,
                ),
              ),
              const SizedBox(width: 20),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      l10n.goodMorning,
                      style: TextStyle(
                        fontSize: greetingFont,
                        color: colors.textSecondary,
                        fontWeight: FontWeight.w500,
                        letterSpacing: -0.1,
                        inherit: true,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      name,
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
            ],
          ),
          const SizedBox(height: 24),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            decoration: BoxDecoration(
              color: colors.accentLight.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.trending_up_rounded,
                  color: colors.primaryAccent,
                  size: 20,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    l10n.managePropertiesAndTenants,
                    style: TextStyle(
                      fontSize: 15,
                      color: colors.primaryAccent,
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

  Widget _buildSearchBar() {
    final l10n = AppLocalizations.of(context)!;
    return Container(
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
        onTap: () {
          HapticFeedback.lightImpact();
          context.push('/search');
        },
        decoration: InputDecoration(
          hintText: l10n.searchPropertiesTenantsMessages,
          hintStyle: TextStyle(
            color: const Color(0xFF64748B),
            fontSize: 15,
            fontWeight: FontWeight.w500,
            letterSpacing: -0.1,
          ),
          prefixIcon: Container(
            padding: const EdgeInsets.all(12),
            child: Icon(
              Icons.search_outlined,
              color: const Color(0xFF64748B),
              size: 20,
            ),
          ),
          border: InputBorder.none,
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
        ),
        style: TextStyle(
          color: const Color(0xFF0F172A),
          fontSize: 15,
          fontWeight: FontWeight.w500,
          letterSpacing: -0.1,
        ),
      ),
    );
  }

  Widget _buildFinancialOverview(
      List<Property> properties, AppLocalizations l10n) {
    final colors = ref.watch(dynamicColorsProvider);
    final totalRevenue = properties
        .where((p) => p.status == 'rented')
        .fold(0.0, (sum, p) => sum + p.rentAmount);

    final outstanding = properties
        .where((p) => p.status == 'rented')
        .fold(0.0, (sum, p) => sum + (p.outstandingPayments));

    return Container(
      padding: const EdgeInsets.all(24.0),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            const Color(0xFF059669).withValues(alpha: 0.95),
            const Color(0xFF10B981).withValues(alpha: 0.85),
          ],
        ),
        borderRadius: BorderRadius.circular(32),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF059669).withValues(alpha: 0.3),
            blurRadius: 20,
            offset: const Offset(0, 8),
            spreadRadius: 0,
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // Centered Icon and Title
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Icon(
              Icons.account_balance_wallet_outlined,
              color: Colors.white,
              size: 32,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            l10n.financialOverview,
            style: const TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.w900,
              color: Colors.white,
              letterSpacing: -0.6,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
          // Revenue Card
          _buildFinancialCard(
            l10n.monthlyRevenue,
            ref.read(currencyProvider.notifier).formatAmount(totalRevenue),
            Icons.trending_up_outlined,
            colors.success,
          ),
          const SizedBox(height: 16),
          // Outstanding Card
          _buildFinancialCard(
            l10n.outstanding,
            ref.read(currencyProvider.notifier).formatAmount(outstanding),
            Icons.warning_outlined,
            colors.warning,
          ),
        ],
      ),
    );
  }

  Widget _buildFinancialCard(
      String title, String amount, IconData icon, Color color) {
    final colors = ref.watch(dynamicColorsProvider);
    return GestureDetector(
      onTap: () {
        HapticFeedback.lightImpact();
        _navigateToFinancialDetails(title, amount);
      },
      child: Container(
        padding: const EdgeInsets.all(20.0),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.95),
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.1),
              blurRadius: 8,
              offset: const Offset(0, 2),
              spreadRadius: 0,
            ),
          ],
        ),
        child: Row(
          children: [
            // Icon on left
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: title.toLowerCase().contains('outstanding')
                    ? colors.warningLight
                    : colors.successLight,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                icon,
                size: 24,
                color: title.toLowerCase().contains('outstanding')
                    ? colors.warning
                    : colors.success,
              ),
            ),
            const SizedBox(width: 16),
            // Amount and label
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    amount,
                    style: TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.w900,
                      color: colors.textPrimary,
                      letterSpacing: -0.8,
                    ),
                    overflow: TextOverflow.ellipsis,
                    maxLines: 1,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    title.toUpperCase(),
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: colors.textSecondary,
                      letterSpacing: 0.8,
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              Icons.arrow_forward_ios,
              size: 16,
              color: colors.textSecondary,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildQuickAccess() {
    final colors = ref.watch(dynamicColorsProvider);
    return Container(
      padding: const EdgeInsets.all(24.0),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            const Color(0xFFEA580C).withValues(alpha: 0.95),
            const Color(0xFFDC2626).withValues(alpha: 0.85),
          ],
        ),
        borderRadius: BorderRadius.circular(32),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFFEA580C).withValues(alpha: 0.3),
            blurRadius: 20,
            offset: const Offset(0, 8),
            spreadRadius: 0,
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // Centered Icon and Title
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Icon(
              Icons.flash_on_outlined,
              color: Colors.white,
              size: 32,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            AppLocalizations.of(context)!.quickActions,
            style: const TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.w900,
              color: Colors.white,
              letterSpacing: -0.6,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
          // Action buttons in grid
          _buildSubscriptionAwareButton(
            AppLocalizations.of(context)!.addProperty,
            Icons.add_home_outlined,
            colors.primaryAccent,
            () {
              HapticFeedback.mediumImpact();
              context.push('/add-property');
            },
            isFullWidth: true,
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _buildQuickAccessButton(
                  AppLocalizations.of(context)!.messages,
                  Icons.chat_bubble_outline,
                  colors.success,
                  () {
                    HapticFeedback.mediumImpact();
                    context.push('/conversations');
                  },
                  isFullWidth: false,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildQuickAccessButton(
                  AppLocalizations.of(context)!.reports,
                  Icons.analytics_outlined,
                  colors.warning,
                  () {
                    HapticFeedback.mediumImpact();
                    context.push('/reports');
                  },
                  isFullWidth: false,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _buildQuickAccessButton(
                  AppLocalizations.of(context)!.maintenance,
                  Icons.build_circle_outlined,
                  colors.error,
                  () {
                    HapticFeedback.mediumImpact();
                    context.push('/maintenance/manage');
                  },
                  isFullWidth: false,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildQuickAccessButton(
                  AppLocalizations.of(context)!.tenants,
                  Icons.people_outline,
                  colors.luxuryGold,
                  () {
                    HapticFeedback.mediumImpact();
                    context.push('/tenants');
                  },
                  isFullWidth: false,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _buildQuickAccessButton(
                  AppLocalizations.of(context)!.payments,
                  Icons.account_balance_wallet_outlined,
                  const Color(0xFF10B981),
                  () {
                    HapticFeedback.mediumImpact();
                    context.push('/landlord/payments');
                  },
                  isFullWidth: false,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildQuickAccessButton(
                  AppLocalizations.of(context)!.documents,
                  Icons.folder_outlined,
                  const Color(0xFF8B5CF6),
                  () {
                    HapticFeedback.mediumImpact();
                    context.push('/landlord/documents');
                  },
                  isFullWidth: false,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildQuickAccessButton(
      String label, 
      IconData icon, 
      Color iconColor, 
      VoidCallback onPressed,
      {bool isFullWidth = false}) {
    final colors = ref.watch(dynamicColorsProvider);
    return GestureDetector(
      onTap: onPressed,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.95),
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.1),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: isFullWidth
            ? Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: iconColor.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(
                      icon,
                      size: 22,
                      color: iconColor,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      label,
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: colors.textPrimary,
                        letterSpacing: -0.2,
                        height: 1.2,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  Icon(
                    Icons.arrow_forward_ios,
                    size: 16,
                    color: colors.textSecondary,
                  ),
                ],
              )
            : Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: iconColor.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(
                      icon,
                      size: 22,
                      color: iconColor,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    label,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: colors.textPrimary,
                      letterSpacing: -0.2,
                      height: 1.2,
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

  Widget _buildSubscriptionAwareButton(
      String label, 
      IconData icon, 
      Color iconColor, 
      VoidCallback onPressed,
      {bool isFullWidth = false}) {
    final colors = ref.watch(dynamicColorsProvider);
    final subscriptionAsync = ref.watch(userSubscriptionProvider);

    return subscriptionAsync.when(
      data: (subscription) {
        final hasActiveSubscription =
            subscription != null && subscription.status == 'active';

        return GestureDetector(
          onTap: hasActiveSubscription
              ? onPressed
              : () => _showSubscriptionRequiredDialog(),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.95),
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.1),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: isFullWidth
                ? Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: hasActiveSubscription 
                              ? iconColor.withValues(alpha: 0.1)
                              : colors.textTertiary.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Stack(
                          alignment: Alignment.center,
                          children: [
                            Icon(
                              icon,
                              size: 22,
                              color: hasActiveSubscription
                                  ? iconColor
                                  : colors.textTertiary,
                            ),
                            if (!hasActiveSubscription)
                              Positioned(
                                top: -2,
                                right: -2,
                                child: Icon(
                                  Icons.lock,
                                  size: 12,
                                  color: colors.warning,
                                ),
                              ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              label,
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w700,
                                color: hasActiveSubscription
                                    ? colors.textPrimary
                                    : colors.textTertiary,
                                letterSpacing: -0.2,
                                height: 1.2,
                              ),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                            if (!hasActiveSubscription) ...[
                              const SizedBox(height: 4),
                              Text(
                                AppLocalizations.of(context)!.subscriptionRequired,
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w500,
                                  color: colors.warning,
                                  letterSpacing: -0.1,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                          ],
                        ),
                      ),
                      Icon(
                        Icons.arrow_forward_ios,
                        size: 16,
                        color: hasActiveSubscription ? colors.textSecondary : colors.textTertiary,
                      ),
                    ],
                  )
                : Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: hasActiveSubscription 
                              ? iconColor.withValues(alpha: 0.1)
                              : colors.textTertiary.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Stack(
                          alignment: Alignment.center,
                          children: [
                            Icon(
                              icon,
                              size: 22,
                              color: hasActiveSubscription
                                  ? iconColor
                                  : colors.textTertiary,
                            ),
                            if (!hasActiveSubscription)
                              Positioned(
                                top: -2,
                                right: -2,
                                child: Icon(
                                  Icons.lock,
                                  size: 12,
                                  color: colors.warning,
                                ),
                              ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        label,
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          color: hasActiveSubscription
                              ? colors.textPrimary
                              : colors.textTertiary,
                          letterSpacing: -0.2,
                          height: 1.2,
                        ),
                        textAlign: TextAlign.center,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      if (!hasActiveSubscription) ...[
                        const SizedBox(height: 4),
                        Text(
                          AppLocalizations.of(context)!.subscriptionRequired,
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w500,
                            color: colors.warning,
                            letterSpacing: -0.1,
                          ),
                          textAlign: TextAlign.center,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ],
                  ),
          ),
        );
      },
      loading: () => Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.95),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Center(child: CircularProgressIndicator()),
      ),
      error: (_, __) => _buildQuickAccessButton(label, icon, colors.textTertiary, () {}, isFullWidth: isFullWidth),
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

  String _getFilterDisplayName() {
    final l10n = AppLocalizations.of(context)!;
    switch (_propertyFilter) {
      case 'available':
        return l10n.available;
      case 'occupied':
        return l10n.occupied;
      case 'maintenance':
        return l10n.maintenance;
      default:
        return l10n.all;
    }
  }

  List<Property> _filterProperties(List<Property> properties) {
    switch (_propertyFilter) {
      case 'available':
        return properties.where((p) => p.status == 'available').toList();
      case 'occupied':
        return properties.where((p) => p.status == 'rented').toList();
      case 'maintenance':
        return properties.where((p) => p.status == 'maintenance').toList();
      case 'all':
      default:
        return properties;
    }
  }

  Widget _buildPropertyOverview(
      List<Property> properties, AppLocalizations l10n) {
    final colors = ref.watch(dynamicColorsProvider);
    final filteredProperties = _filterProperties(properties);
    return Container(
      padding: const EdgeInsets.all(24.0),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            const Color(0xFF3B82F6).withValues(alpha: 0.95),
            const Color(0xFF8B5CF6).withValues(alpha: 0.85),
          ],
        ),
        borderRadius: BorderRadius.circular(32),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF3B82F6).withValues(alpha: 0.3),
            blurRadius: 20,
            offset: const Offset(0, 8),
            spreadRadius: 0,
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Centered Header
          Column(
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Icon(
                  Icons.home_work_outlined,
                  color: Colors.white,
                  size: 32,
                ),
              ),
              const SizedBox(height: 16),
              Text(
                _propertyFilter == 'all'
                    ? l10n.properties
                    : '${l10n.properties} (${_getFilterDisplayName()})',
                style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.w900,
                  color: Colors.white,
                  letterSpacing: -0.6,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  '${filteredProperties.length} ${l10n.total}',
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                    letterSpacing: -0.1,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          ...filteredProperties.take(3).map((property) => Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: _buildPropertyCard(property),
              )),
          if (filteredProperties.length > 3)
            GestureDetector(
              onTap: () {
                HapticFeedback.lightImpact();
                context.push('/properties');
              },
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 16),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.95),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      l10n.viewAllProperties,
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        color: colors.primaryAccent,
                        letterSpacing: -0.1,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Icon(
                      Icons.arrow_forward_ios,
                      size: 14,
                      color: colors.primaryAccent,
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildPropertyCard(Property property) {
    final colors = ref.watch(dynamicColorsProvider);
    final statusColor = property.status == 'rented'
        ? colors.success
        : property.status == 'available'
            ? colors.primaryAccent
            : colors.warning;

    return GestureDetector(
      onTap: () {
        HapticFeedback.lightImpact();
        context.push('/property/${property.id}');
      },
      child: Container(
        padding: const EdgeInsets.all(16.0),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.95),
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.08),
              blurRadius: 8,
              offset: const Offset(0, 2),
              spreadRadius: 0,
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(14),
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
                      size: 24,
                    ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    property.address.street,
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      color: colors.textPrimary,
                      letterSpacing: -0.2,
                    ),
                    overflow: TextOverflow.ellipsis,
                    maxLines: 1,
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Icon(
                        Icons.attach_money,
                        size: 14,
                        color: colors.success,
                      ),
                      Expanded(
                        child: Text(
                          '${ref.read(currencyProvider.notifier).formatAmount(property.rentAmount)}/${AppLocalizations.of(context)!.monthlyInterval}',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: colors.success,
                            letterSpacing: -0.1,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
              decoration: BoxDecoration(
                color: statusColor.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: statusColor.withValues(alpha: 0.2),
                  width: 1,
                ),
              ),
              child: Text(
                _getLocalizedStatus(property.status),
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w600,
                  color: statusColor,
                  letterSpacing: 0.3,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRecentMessages() {
    return Container(
      padding: const EdgeInsets.all(24.0),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            const Color(0xFF059669).withValues(alpha: 0.95),
            const Color(0xFF10B981).withValues(alpha: 0.85),
          ],
        ),
        borderRadius: BorderRadius.circular(32),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF059669).withValues(alpha: 0.3),
            blurRadius: 20,
            offset: const Offset(0, 8),
            spreadRadius: 0,
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Centered Header
          Column(
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Icon(
                  Icons.chat_bubble_outline,
                  color: Colors.white,
                  size: 32,
                ),
              ),
              const SizedBox(height: 16),
              Text(
                AppLocalizations.of(context)!.recentMessages,
                style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.w900,
                  color: Colors.white,
                  letterSpacing: -0.6,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
          const SizedBox(height: 24),
          if (_isLoadingDashboardData)
            const Center(child: CircularProgressIndicator(color: Colors.white))
          else if (_recentMessages.isEmpty)
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                AppLocalizations.of(context)!.noRecentMessages,
                style: const TextStyle(
                  fontSize: 14,
                  color: Colors.white,
                ),
                textAlign: TextAlign.center,
              ),
            )
          else
            ..._recentMessages
                .map((conversation) => Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: _buildMessageItem(
                        conversation,
                      ),
                    ))
                .toList(),
        ],
      ),
    );
  }

  Widget _buildMessageItem(Conversation conversation) {
    final colors = ref.watch(dynamicColorsProvider);
    return GestureDetector(
      onTap: () => _navigateToChat(conversation),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.95),
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.08),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          children: [
            UserAvatar(
              imageRef: conversation.otherParticipantAvatar,
              name: conversation.otherParticipantName,
              size: 44,
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          conversation.otherParticipantName ?? 'Unknown User',
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w700,
                            color: colors.textPrimary,
                            letterSpacing: -0.2,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      Text(
                        _getTimeAgo(conversation.lastMessageTime),
                        style: TextStyle(
                          fontSize: 11,
                          color: colors.textTertiary,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    conversation.lastMessage,
                    style: TextStyle(
                      fontSize: 13,
                      color: colors.textSecondary,
                      letterSpacing: -0.1,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _navigateToFinancialDetails(String title, String amount) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('$title Details'),
        content: SizedBox(
          width: double.maxFinite,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Total Amount: $amount',
                  style: const TextStyle(
                      fontSize: 18, fontWeight: FontWeight.bold)),
              const SizedBox(height: 16),
              const Text('Breakdown:',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
              const SizedBox(height: 8),
              if (title.contains('Revenue')) ...[
                const Text('• Rent payments: \$8,500'),
                const Text('• Late fees: \$200'),
                const Text('• Service charges: \$300'),
              ] else if (title.contains('Expenses')) ...[
                const Text('• Maintenance: \$1,200'),
                const Text('• Utilities: \$800'),
                const Text('• Insurance: \$400'),
                const Text('• Property management: \$600'),
              ] else if (title.contains('Profit')) ...[
                const Text('• Total Revenue: \$9,000'),
                const Text('• Total Expenses: \$3,000'),
                const Text('• Net Profit: \$6,000'),
              ] else
                const Text('Detailed breakdown coming soon...'),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Close'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(context).pop();
              // Here you would navigate to full financial reports page
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                    content: Text('Full financial reports coming soon!')),
              );
            },
            child: const Text('View Full Report'),
          ),
        ],
      ),
    );
  }

  void _navigateToChat(Conversation conversation) async {
    final colors = ref.read(dynamicColorsProvider);
    try {
      // Navigate to chat page with conversation details
      final avatar = conversation.otherParticipantAvatar ?? '';
      context.push(
        '/chat/${conversation.id}?otherUser=${Uri.encodeComponent(conversation.otherParticipantName ?? 'Unknown User')}&otherUserId=${conversation.otherParticipantId ?? ''}&otherAvatar=${Uri.encodeComponent(avatar)}',
      );
    } catch (e) {
      // Handle any navigation errors
      print('Error navigating to chat: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
              'Chat kann nicht geöffnet werden. Bitte versuchen Sie es erneut.'),
          backgroundColor: colors.error,
        ),
      );
    }
  }

  Widget _buildMaintenanceRequests() {
    return Container(
      padding: const EdgeInsets.all(24.0),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            const Color(0xFFEA580C).withValues(alpha: 0.95),
            const Color(0xFFDC2626).withValues(alpha: 0.85),
          ],
        ),
        borderRadius: BorderRadius.circular(32),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFFEA580C).withValues(alpha: 0.3),
            blurRadius: 20,
            offset: const Offset(0, 8),
            spreadRadius: 0,
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Centered Header
          Column(
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Icon(
                  Icons.build_circle_outlined,
                  color: Colors.white,
                  size: 32,
                ),
              ),
              const SizedBox(height: 16),
              Text(
                AppLocalizations.of(context)!.maintenanceRequests,
                style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.w900,
                  color: Colors.white,
                  letterSpacing: -0.6,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
          const SizedBox(height: 24),
          if (_isLoadingDashboardData)
            const Center(child: CircularProgressIndicator(color: Colors.white))
          else if (_recentMaintenanceRequests
              .where((request) => request.status != 'completed')
              .isEmpty)
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                AppLocalizations.of(context)!.noPendingMaintenanceRequests,
                style: const TextStyle(
                  fontSize: 14,
                  color: Colors.white,
                ),
                textAlign: TextAlign.center,
              ),
            )
          else
            ..._recentMaintenanceRequests
                .where((request) => request.status != 'completed')
                .map((request) => Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: _buildMaintenanceCard(
                        request,
                        context,
                      ),
                    ))
                .toList(),
        ],
      ),
    );
  }

  Widget _buildMaintenanceCard(
      MaintenanceRequest request, BuildContext context) {
    final colors = ref.watch(dynamicColorsProvider);
    Color priorityColor = _getPriorityColor(request.priority);
    IconData icon = CategoryUtils.getCategoryIcon(request.category);

    return GestureDetector(
      onTap: () {
        context.push('/maintenance/${request.id}');
      },
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.95),
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.08),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: priorityColor.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: priorityColor, size: 24),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    request.title,
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      color: colors.textPrimary,
                      letterSpacing: -0.2,
                    ),
                    overflow: TextOverflow.ellipsis,
                    maxLines: 1,
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Icon(
                        Icons.location_on_outlined,
                        size: 13,
                        color: colors.textTertiary,
                      ),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Text(
                          request.location,
                          style: TextStyle(
                            fontSize: 13,
                            color: colors.textSecondary,
                            letterSpacing: -0.1,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
              decoration: BoxDecoration(
                color: priorityColor.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                request.priority.toUpperCase(),
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w600,
                  color: priorityColor,
                  letterSpacing: 0.3,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFAB() {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF3B82F6),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF3B82F6).withValues(alpha: 0.4),
            blurRadius: 20,
            offset: const Offset(0, 8),
            spreadRadius: 0,
          ),
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.12),
            blurRadius: 12,
            offset: const Offset(0, 4),
            spreadRadius: 0,
          ),
        ],
      ),
      child: FloatingActionButton(
        onPressed: () {
          HapticFeedback.mediumImpact();
          context.push('/add-property');
        },
        backgroundColor: Colors.transparent,
        elevation: 0,
        child: Icon(
          Icons.add_rounded,
          color: Colors.white,
          size: 28,
        ),
      ),
    );
  }

  String _getLocalizedStatus(String status) {
    final l10n = AppLocalizations.of(context)!;
    switch (status.toLowerCase()) {
      case 'rented':
        return l10n.rented.toUpperCase();
      case 'available':
        return l10n.available.toUpperCase();
      default:
        return status.toUpperCase();
    }
  }

  String _getTimeAgo(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);

    if (difference.inDays > 0) {
      return '${difference.inDays}d ago';
    } else if (difference.inHours > 0) {
      return '${difference.inHours}h ago';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes}m ago';
    } else {
      return 'Just now';
    }
  }

  void _showFilterDialog(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final colors = ref.read(dynamicColorsProvider);
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
                setState(() {
                  _propertyFilter = 'all';
                });
                // Trigger refresh of property data
                ref.invalidate(landlordPropertiesProvider);
              },
            ),
            ListTile(
              leading: Icon(Icons.check_circle, color: colors.success),
              title: Text(l10n.available),
              onTap: () {
                Navigator.of(context).pop();
                setState(() {
                  _propertyFilter = 'available';
                });
                ref.invalidate(landlordPropertiesProvider);
              },
            ),
            ListTile(
              leading: Icon(Icons.home, color: colors.info),
              title: Text(l10n.occupied),
              onTap: () {
                Navigator.of(context).pop();
                setState(() {
                  _propertyFilter = 'occupied';
                });
                ref.invalidate(landlordPropertiesProvider);
              },
            ),
            ListTile(
              leading: Icon(Icons.build, color: colors.warning),
              title: Text(l10n.maintenance),
              onTap: () {
                Navigator.of(context).pop();
                setState(() {
                  _propertyFilter = 'maintenance';
                });
                ref.invalidate(landlordPropertiesProvider);
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

  Color _getPriorityColor(String priority) {
    final colors = ref.watch(dynamicColorsProvider);
    switch (priority) {
      case 'urgent':
      case 'high':
        return colors.error;
      case 'medium':
        return colors.warning;
      case 'low':
        return colors.success;
      default:
        return colors.warning;
    }
  }

  Widget _buildPropertyImage(String imageIdOrPath) {
    final resolved = resolvePropertyImage(imageIdOrPath);
    if (resolved.isEmpty) {
      return Container(
        color: Colors.grey[200],
        alignment: Alignment.center,
        child: const Icon(Icons.home_outlined, color: Colors.grey, size: 24),
      );
    }
    // Always use MongoImage so Authorization headers and 401 retry apply
    return MongoImage(
      imageId: resolved,
      fit: BoxFit.cover,
      width: 60,
      height: 60,
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
          size: 24,
        ),
      ),
    );
  }
}
