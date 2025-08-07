import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/common_bottom_nav.dart';
import '../../../../core/providers/navigation_provider.dart';
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

  @override
  Widget build(BuildContext context) {
    final currentUser = ref.watch(currentUserProvider);
    final propertiesAsync = ref.watch(tenantPropertiesProvider);
    
    return Scaffold(
      backgroundColor: Colors.transparent,
      extendBodyBehindAppBar: true,
      appBar: _buildAppBar(currentUser?.fullName ?? 'Tenant'),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              const Color(0xFFF8FAFC), // Sehr helles Grau
              const Color(0xFFF1F5F9), // Leicht dunkleres Grau
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
                      color: AppColors.primaryAccent,
                      backgroundColor: Colors.white,
                      child: SingleChildScrollView(
                        physics: const AlwaysScrollableScrollPhysics(),
                        padding: const EdgeInsets.all(20),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _buildWelcomeSection(currentUser?.fullName ?? 'Tenant'),
                            const SizedBox(height: 24),
                            _buildSearchBar(),
                            const SizedBox(height: 24),
                            if (properties.isNotEmpty) 
                              _buildPropertyCard(properties.first)
                            else
                              _buildNoPropertyCard(),
                            const SizedBox(height: 24),
                            _buildQuickActions(),
                            const SizedBox(height: 24),
                            _buildRecentActivity(),
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
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Color(0xFFF8F9FA),
                  Color(0xFFFFFFFF),
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
                      color: Colors.white.withValues(alpha: 0.9),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: Colors.grey.withValues(alpha: 0.2),
                        width: 1,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.1),
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
                            valueColor: AlwaysStoppedAnimation<Color>(AppColors.primaryAccent),
                            strokeWidth: 3,
                          ),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'Loading your dashboard...',
                          style: TextStyle(
                            color: AppColors.textPrimary,
                            fontSize: 16,
                            fontWeight: FontWeight.w500,
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
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    Color(0xFFF8F9FA),
                    Color(0xFFFFFFFF),
                  ],
                ),
              ),
              child: Center(
                child: Container(
                  margin: const EdgeInsets.all(20),
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.9),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: Colors.grey.withValues(alpha: 0.2),
                      width: 1,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.1),
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
                          color: AppColors.error.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Icon(Icons.error_outline, size: 48, color: AppColors.error),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'Error loading dashboard',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        error.toString(),
                        style: TextStyle(
                          fontSize: 14,
                          color: AppColors.textSecondary,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 20),
                      Container(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              AppColors.primaryAccent,
                              AppColors.primaryAccent.withValues(alpha: 0.8),
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

  PreferredSizeWidget _buildAppBar(String name) {
    return AppBar(
      backgroundColor: const Color(0xFFF8FAFC),
      elevation: 0,
      systemOverlayStyle: SystemUiOverlayStyle.dark,
      centerTitle: true,
      actions: [
        Container(
          margin: const EdgeInsets.only(right: 16, top: 8, bottom: 8),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(8),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.08),
                blurRadius: 12,
                offset: const Offset(0, 4),
                spreadRadius: 0,
              ),
            ],
          ),
          child: IconButton(
            icon: Icon(Icons.notifications_outlined, color: const Color(0xFF64748B), size: 22),
            onPressed: () => HapticFeedback.lightImpact(),
          ),
        ),
      ],
    );
  }

  Widget _buildWelcomeSection(String userName) {
    return Container(
      padding: const EdgeInsets.all(32),
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
                        color: const Color(0xFF64748B),
                        fontWeight: FontWeight.w500,
                        letterSpacing: -0.1,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      userName,
                      style: TextStyle(
                        fontSize: 32,
                        fontWeight: FontWeight.w800,
                        color: const Color(0xFF0F172A),
                        letterSpacing: -0.8,
                        height: 1.1,
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
                Text(
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
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchBar() {
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
          context.push('/tenant-search');
        },
        decoration: InputDecoration(
          hintText: 'Search properties, maintenance, messages...',
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
          suffixIcon: Container(
            margin: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: const Color(0xFFF1F5F9),
              borderRadius: BorderRadius.circular(8),
            ),
            child: IconButton(
              onPressed: () {
                HapticFeedback.lightImpact();
                // TODO: Show filter options for tenant
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
        ),
      ),
    );
  }

  Widget _buildPropertyCard(Property property) {
    return GestureDetector(
      onTap: () {
        HapticFeedback.lightImpact();
        context.push('/property/${property.id}');
      },
      child: Container(
        padding: const EdgeInsets.all(32.0),
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
                      color: const Color(0xFF0F172A),
                      letterSpacing: -0.6,
                    ),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: const Color(0xFFDCFCE7), // Grün Background
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    'ACTIVE',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: const Color(0xFF10B981),
                      letterSpacing: 0.5,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 28),
            Container(
              padding: const EdgeInsets.all(24.0),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: const Color(0xFFE2E8F0),
                  width: 1,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.04),
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
                          color: const Color(0xFFF1F5F9),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Icon(
                          Icons.location_on_outlined, 
                          size: 20, 
                          color: const Color(0xFF3B82F6),
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
                                color: const Color(0xFF0F172A),
                                letterSpacing: -0.3,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              '${property.address.city}, ${property.address.postalCode}',
                              style: TextStyle(
                                fontSize: 14,
                                color: const Color(0xFF64748B),
                                fontWeight: FontWeight.w500,
                                letterSpacing: -0.1,
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
                                color: const Color(0xFF64748B),
                                letterSpacing: 0.5,
                              ),
                            ),
                            const SizedBox(height: 6),
                            Text(
                              '\$${property.rentAmount.toStringAsFixed(0)}',
                              style: TextStyle(
                                fontSize: 24,
                                fontWeight: FontWeight.w800,
                                color: const Color(0xFF10B981),
                                letterSpacing: -0.6,
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
                                color: const Color(0xFF64748B),
                                letterSpacing: 0.5,
                              ),
                            ),
                            const SizedBox(height: 6),
                            Text(
                              '${property.details.size} m²',
                              style: TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.w700,
                                color: const Color(0xFF0F172A),
                                letterSpacing: -0.4,
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

  Widget _buildNoPropertyCard() {
    return Container(
      padding: const EdgeInsets.all(32.0),
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
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: const Color(0xFFFEF3C7), // Gelb Background
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              Icons.home_work_outlined,
              color: const Color(0xFFF59E0B),
              size: 48,
            ),
          ),
          const SizedBox(height: 24),
          Text(
            'No Property Assigned',
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w800,
              color: const Color(0xFF0F172A),
              letterSpacing: -0.6,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            'Contact your landlord to get access to your rental property information.',
            style: TextStyle(
              fontSize: 15,
              color: const Color(0xFF64748B),
              fontWeight: FontWeight.w500,
              letterSpacing: -0.1,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 16),
            decoration: BoxDecoration(
              color: const Color(0xFF3B82F6),
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF3B82F6).withValues(alpha: 0.3),
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

  Widget _buildQuickActions() {
    return Container(
      padding: const EdgeInsets.all(32.0),
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
                    color: const Color(0xFF0F172A),
                    letterSpacing: -0.6,
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
                            AppColors.error,
                            () {
                              HapticFeedback.mediumImpact();
                              context.push('/maintenance/request');
                            },
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _buildActionCard(
                            'Messages',
                            Icons.chat_bubble_outline,
                            AppColors.success,
                            () {
                              HapticFeedback.mediumImpact();
                              context.push('/conversations');
                            },
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
                            AppColors.primaryAccent,
                            () {
                              HapticFeedback.mediumImpact();
                              context.push('/payments/auto-setup');
                            },
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _buildActionCard(
                            'Book Services',
                            Icons.room_service_outlined,
                            AppColors.info,
                            () {
                              HapticFeedback.mediumImpact();
                              context.push('/tenant/services');
                            },
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
                            AppColors.warning,
                            () {
                              HapticFeedback.mediumImpact();
                              context.push('/payments/history');
                            },
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _buildActionCard(
                            'Settings',
                            Icons.settings_outlined,
                            AppColors.luxuryGold,
                            () {
                              HapticFeedback.mediumImpact();
                              context.push('/settings');
                            },
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
                            AppColors.error,
                            () {
                              HapticFeedback.mediumImpact();
                              context.push('/maintenance/request');
                            },
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: _buildActionCard(
                            'Messages',
                            Icons.chat_bubble_outline,
                            AppColors.success,
                            () {
                              HapticFeedback.mediumImpact();
                              context.push('/conversations');
                            },
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: _buildActionCard(
                            'Auto Payment',
                            Icons.payment_outlined,
                            AppColors.primaryAccent,
                            () {
                              HapticFeedback.mediumImpact();
                              context.push('/payments/auto-setup');
                            },
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
                            AppColors.info,
                            () {
                              HapticFeedback.mediumImpact();
                              context.push('/tenant/services');
                            },
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: _buildActionCard(
                            'Payment History',
                            Icons.history_outlined,
                            AppColors.warning,
                            () {
                              HapticFeedback.mediumImpact();
                              context.push('/payments/history');
                            },
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: _buildActionCard(
                            'Settings',
                            Icons.settings_outlined,
                            AppColors.luxuryGold,
                            () {
                              HapticFeedback.mediumImpact();
                              context.push('/settings');
                            },
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

  Widget _buildActionCard(String title, IconData icon, Color iconColor, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              iconColor.withValues(alpha: 0.15),
              iconColor.withValues(alpha: 0.08),
            ],
          ),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: iconColor.withValues(alpha: 0.2),
            width: 1,
          ),
          boxShadow: [
            BoxShadow(
              color: iconColor.withValues(alpha: 0.15),
              blurRadius: 16,
              offset: const Offset(0, 6),
              spreadRadius: 0,
            ),
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.04),
              blurRadius: 8,
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
                color: Colors.white.withValues(alpha: 0.9),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: Colors.white.withValues(alpha: 0.6),
                  width: 1,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.white.withValues(alpha: 0.8),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                    spreadRadius: 0,
                  ),
                ],
              ),
              child: Icon(
                icon, 
                size: 24,
                color: iconColor,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              title,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w700,
                color: const Color(0xFF0F172A),
                letterSpacing: -0.2,
              ),
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRecentActivity() {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
          colors: [
            AppColors.surfaceCards,
            AppColors.luxuryGradientStart,
          ],
        ),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: AppColors.borderLight,
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: AppColors.shadowColor,
            blurRadius: 20,
            offset: const Offset(0, 8),
            spreadRadius: 0,
          ),
          BoxShadow(
            color: Colors.white.withValues(alpha: 0.9),
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
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 20),
            Consumer(
              builder: (context, ref, child) {
                final activitiesAsync = ref.watch(recentActivitiesProvider);
                
                return activitiesAsync.when(
                  data: (activities) {
                    if (activities.isEmpty) {
                      return _buildEmptyActivityState();
                    }
                    
                    return Column(
                      children: activities.take(3).map((activity) => 
                        Padding(
                          padding: const EdgeInsets.only(bottom: 16),
                          child: _buildActivityItem(activity),
                        )
                      ).toList(),
                    );
                  },
                  loading: () => Center(
                    child: SizedBox(
                      width: 24,
                      height: 24,
                      child: CircularProgressIndicator(
                        valueColor: AlwaysStoppedAnimation<Color>(AppColors.primaryAccent),
                        strokeWidth: 2,
                      ),
                    ),
                  ),
                  error: (error, stack) => _buildEmptyActivityState(),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyActivityState() {
    return Container(
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppColors.textSecondary.withValues(alpha: 0.1),
            AppColors.textSecondary.withValues(alpha: 0.05),
          ],
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: AppColors.textSecondary.withValues(alpha: 0.15),
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
                  AppColors.textSecondary.withValues(alpha: 0.15),
                  AppColors.textSecondary.withValues(alpha: 0.05),
                ],
              ),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: AppColors.textSecondary.withValues(alpha: 0.2),
                width: 1,
              ),
            ),
            child: Icon(
              Icons.history_rounded,
              size: 32,
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'No Recent Activity',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Your recent activities will appear here',
            style: TextStyle(
              fontSize: 14,
              color: AppColors.textSecondary.withValues(alpha: 0.8),
              fontWeight: FontWeight.w500,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildActivityItem(Activity activity) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppColors.surfaceCards,
            _getActivityColor(activity.type).withValues(alpha: 0.02),
          ],
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: _getActivityColor(activity.type).withValues(alpha: 0.1),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: AppColors.shadowColor,
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
                  _getActivityColor(activity.type).withValues(alpha: 0.2),
                  _getActivityColor(activity.type).withValues(alpha: 0.1),
                ],
              ),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              _getActivityIcon(activity.type),
              color: _getActivityColor(activity.type),
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
                    color: AppColors.textPrimary,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                Text(
                  activity.description,
                  style: TextStyle(
                    fontSize: 12,
                    color: AppColors.textSecondary,
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
              color: AppColors.textSecondary,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Color _getActivityColor(String type) {
    switch (type.toLowerCase()) {
      case 'payment':
        return AppColors.success;
      case 'maintenance':
        return AppColors.warning;
      case 'message':
        return AppColors.info;
      case 'service':
        return AppColors.primaryAccent;
      case 'property':
        return AppColors.luxuryGold;
      default:
        return AppColors.textSecondary;
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
