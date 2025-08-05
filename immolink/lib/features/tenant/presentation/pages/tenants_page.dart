import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../chat/domain/models/contact_user.dart';
import '../../../chat/presentation/providers/contact_providers.dart';
import '../../../property/domain/models/property.dart';
import '../../../property/presentation/providers/property_providers.dart';
import '../../../../core/providers/currency_provider.dart';

class TenantsPage extends ConsumerStatefulWidget {
  const TenantsPage({super.key});

  @override
  ConsumerState<TenantsPage> createState() => _TenantsPageState();
}

class _TenantsPageState extends ConsumerState<TenantsPage> with TickerProviderStateMixin {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  late AnimationController _animationController;
  late Animation<double> _slideAnimation;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );
    _slideAnimation = Tween<double>(begin: 30.0, end: 0.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeOut),
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );
    _animationController.forward();
  }

  @override
  void dispose() {
    _searchController.dispose();
    _animationController.dispose();
    super.dispose();
  }  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final contactsAsync = ref.watch(allTenantsProvider);
    final propertiesAsync = ref.watch(landlordPropertiesProvider);

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: _buildAppBar(),
      body: AnimatedBuilder(
        animation: _animationController,
        builder: (context, child) {
          return Transform.translate(
            offset: Offset(0, _slideAnimation.value),
            child: Opacity(
              opacity: _fadeAnimation.value,
              child: RefreshIndicator(              onRefresh: () async {
                HapticFeedback.lightImpact();
                ref.invalidate(allTenantsProvider);
                ref.invalidate(landlordPropertiesProvider);
                await Future.delayed(const Duration(milliseconds: 500));
              },
                color: Theme.of(context).colorScheme.primary,
                backgroundColor: Theme.of(context).scaffoldBackgroundColor,
                child: Column(
                  children: [
                    _buildHeader(),
                    _buildSearchBar(),
                    Expanded(
                      child: contactsAsync.when(
                        data: (tenants) {
                          final filteredTenants = _filterTenants(tenants);
                          return propertiesAsync.when(
                            data: (properties) => _buildTenantsContent(filteredTenants, properties, l10n),
                            loading: () => const Center(child: CircularProgressIndicator()),
                            error: (error, _) => _buildErrorState(),
                          );
                        },
                        loading: () => _buildLoadingState(),
                        error: (error, _) => _buildErrorState(),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
      floatingActionButton: _buildFAB(),
    );
  }
  PreferredSizeWidget _buildAppBar() {
    final l10n = AppLocalizations.of(context)!;
    return AppBar(
      backgroundColor: AppColors.primaryBackground,
      elevation: 0,
      title: Text(
        l10n.tenants,
        style: TextStyle(
          color: AppColors.textPrimary,
          fontSize: 18,
          fontWeight: FontWeight.w600,
        ),
      ),      leading: IconButton(
        icon: Icon(Icons.arrow_back_ios, color: AppColors.textPrimary),
        onPressed: () {
          if (context.canPop()) {
            context.pop();
          } else {
            context.go('/home');
          }
        },
      ),
      actions: [
        IconButton(
          icon: Icon(Icons.filter_list_outlined, color: AppColors.textPrimary),
          onPressed: () {
            HapticFeedback.lightImpact();
            _showFilterOptions();
          },
        ),
      ],
    );
  }
  Widget _buildHeader() {
    final l10n = AppLocalizations.of(context)!;
    return Container(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            l10n.tenantManagement,
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.w700,
              color: AppColors.textPrimary,
              letterSpacing: -0.5,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            l10n.manageTenantDescription,
            style: TextStyle(
              fontSize: 16,
              color: AppColors.textSecondary,
              letterSpacing: -0.2,
            ),
          ),
        ],
      ),
    );
  }
  Widget _buildSearchBar() {
    final l10n = AppLocalizations.of(context)!;
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
          colors: [
            AppColors.surfaceCards,
            AppColors.luxuryGradientStart,
          ],
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: AppColors.borderLight,
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: AppColors.shadowColor,
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: TextField(
        controller: _searchController,
        onChanged: (value) {
          setState(() {
            _searchQuery = value;
          });
        },
        style: TextStyle(
          color: AppColors.textPrimary,
          fontSize: 15,
          fontWeight: FontWeight.w500,
        ),
        decoration: InputDecoration(
          hintText: l10n.searchTenants,
          hintStyle: TextStyle(
            color: AppColors.textTertiary,
            fontSize: 15,
            fontWeight: FontWeight.w400,
          ),
          prefixIcon: Container(
            padding: const EdgeInsets.all(12),
            child: Icon(
              Icons.search_outlined,
              color: AppColors.primaryAccent,
              size: 20,
            ),
          ),
          suffixIcon: _searchQuery.isNotEmpty
              ? IconButton(
                  icon: Icon(
                    Icons.clear,
                    color: AppColors.textTertiary,
                    size: 20,
                  ),
                  onPressed: () {
                    _searchController.clear();
                    setState(() {
                      _searchQuery = '';
                    });
                  },
                )
              : null,
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        ),
      ),
    );
  }

  Widget _buildTenantsContent(List<ContactUser> tenants, List<Property> properties, AppLocalizations l10n) {
    if (tenants.isEmpty) {
      return _buildEmptyState();
    }

    return Column(
      children: [
        _buildStatsCards(tenants, properties),
        const SizedBox(height: 16),
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            itemCount: tenants.length,
            itemBuilder: (context, index) {
              final tenant = tenants[index];
              final tenantProperties = _getTenantProperties(tenant, properties);
              return Padding(
                padding: const EdgeInsets.only(bottom: 16),
                child: _buildTenantCard(tenant, tenantProperties, l10n),
              );
            },
          ),
        ),
      ],
    );
  }
  Widget _buildStatsCards(List<ContactUser> tenants, List<Property> properties) {
    final l10n = AppLocalizations.of(context)!;
    final totalTenants = tenants.length;
    final occupiedProperties = properties.where((p) => p.status == 'rented').length;
    final pendingIssues = 2; // Mock data - would come from maintenance requests

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Row(
        children: [
          Expanded(
            child: _buildStatCard(
              l10n.totalTenants,
              totalTenants.toString(),
              Icons.people_outline,
              AppColors.primaryAccent,
            ),
          ),
          const SizedBox(width: 12),          Expanded(
            child: _buildStatCard(
              l10n.occupiedUnits,
              occupiedProperties.toString(),
              Icons.home_outlined,
              AppColors.success,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: _buildStatCard(
              l10n.pendingIssues,
              pendingIssues.toString(),
              Icons.warning_outlined,
              AppColors.warning,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard(String title, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppColors.surfaceCards,
            color.withValues(alpha: 0.03),
          ],
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: color.withValues(alpha: 0.15),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: color.withValues(alpha: 0.08),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: color, size: 20),
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w700,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            title,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: AppColors.textTertiary,
              letterSpacing: 0.5,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
  Widget _buildTenantCard(ContactUser tenant, List<Property> tenantProperties, AppLocalizations l10n) {
    final hasProperties = tenantProperties.isNotEmpty;
    // Use status from backend if available, otherwise fall back to property-based logic
    final tenantStatus = tenant.status ?? (hasProperties ? 'active' : 'available');
    final statusColor = tenantStatus == 'active' ? AppColors.success : AppColors.warning;

    return GestureDetector(
      onTap: () {
        HapticFeedback.lightImpact();
        _showTenantDetails(tenant, tenantProperties);
      },
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              AppColors.surfaceCards,
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
              color: AppColors.shadowColor,
              blurRadius: 16,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Column(
          children: [
            Row(
              children: [
                Container(
                  width: 60,
                  height: 60,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        statusColor,
                        statusColor.withValues(alpha: 0.7),
                      ],
                    ),
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: statusColor.withValues(alpha: 0.3),
                      width: 2,
                    ),
                  ),
                  child: Center(
                    child: Text(
                      tenant.fullName.isNotEmpty ? tenant.fullName[0].toUpperCase() : 'T',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 24,
                        fontWeight: FontWeight.w700,
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
                        tenant.fullName,
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                          color: AppColors.textPrimary,
                          letterSpacing: -0.3,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        tenant.email,
                        style: TextStyle(
                          fontSize: 14,
                          color: AppColors.textSecondary,
                        ),
                      ),
                      if (tenant.phone.isNotEmpty) ...[
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            Icon(
                              Icons.phone_outlined,
                              size: 14,
                              color: AppColors.textTertiary,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              tenant.phone,
                              style: TextStyle(
                                fontSize: 14,
                                color: AppColors.textSecondary,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: statusColor.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: statusColor.withValues(alpha: 0.2),
                      width: 1,
                    ),
                  ),                  child: Text(
                    tenantStatus == 'active' ? l10n.active.toUpperCase() : l10n.available.toUpperCase(),
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: statusColor,
                      letterSpacing: 0.5,
                    ),
                  ),
                ),
              ],
            ),
            if (hasProperties) ...[
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColors.success.withValues(alpha: 0.05),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: AppColors.success.withValues(alpha: 0.1),
                    width: 1,
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(
                          Icons.home_outlined,
                          size: 16,
                          color: AppColors.success,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          l10n.assignedProperties,
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: AppColors.success,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    ...tenantProperties.map((property) => Padding(
                      padding: const EdgeInsets.only(bottom: 4),
                      child: Row(
                        children: [
                          const SizedBox(width: 24),
                          Expanded(
                            child: Text(
                              property.address.street,
                              style: TextStyle(
                                fontSize: 13,
                                color: AppColors.textSecondary,
                              ),
                            ),
                          ),
                          Text(
                            ref.read(currencyProvider.notifier).formatAmount(property.rentAmount),
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: AppColors.success,
                            ),
                          ),
                        ],
                      ),
                    )),
                  ],
                ),
              ),
            ],
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: _buildActionButton(
                    l10n.message,
                    Icons.chat_bubble_outline,
                    AppColors.primaryAccent,
                    () => _messageTenant(tenant),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildActionButton(
                    l10n.call,
                    Icons.phone_outlined,
                    AppColors.success,
                    () => _callTenant(tenant),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildActionButton(
                    l10n.details,
                    Icons.info_outline,
                    AppColors.textSecondary,
                    () => _showTenantDetails(tenant, tenantProperties),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActionButton(String label, IconData icon, Color color, VoidCallback onPressed) {
    return GestureDetector(
      onTap: onPressed,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: color.withValues(alpha: 0.2),
            width: 1,
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 16, color: color),
            const SizedBox(width: 6),
            Text(
              label,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: color,
              ),
            ),
          ],
        ),
      ),
    );
  }
  Widget _buildEmptyState() {
    final l10n = AppLocalizations.of(context)!;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(40),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    AppColors.primaryAccent.withValues(alpha: 0.1),
                    AppColors.primaryAccent.withValues(alpha: 0.05),
                  ],
                ),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.people_outline,
                size: 48,
                color: AppColors.primaryAccent,
              ),
            ),
            const SizedBox(height: 24),
            Text(
              l10n.noTenantsYet,
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w600,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              l10n.addPropertiesInviteTenants,
              style: TextStyle(
                fontSize: 14,
                color: AppColors.textSecondary,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: () {
                HapticFeedback.mediumImpact();
                context.push('/add-property');
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primaryAccent,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              icon: const Icon(Icons.add_home),
              label: Text(l10n.addProperty),
            ),
          ],
        ),
      ),
    );
  }
  Widget _buildLoadingState() {
    final l10n = AppLocalizations.of(context)!;
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const CircularProgressIndicator(
            valueColor: AlwaysStoppedAnimation<Color>(AppColors.primaryAccent),
          ),
          const SizedBox(height: 16),
          Text(l10n.loadingTenants),
        ],
      ),
    );
  }

  Widget _buildErrorState() {
    final l10n = AppLocalizations.of(context)!;
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.error_outline, size: 48, color: AppColors.error),
          const SizedBox(height: 16),
          Text(
            l10n.errorLoadingTenants,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: AppColors.textPrimary,
            ),
          ),          const SizedBox(height: 8),
          Text(
            l10n.pleaseTryAgainLater,
            style: TextStyle(
              fontSize: 14,
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: () {
              ref.invalidate(allTenantsProvider);
              ref.invalidate(landlordPropertiesProvider);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primaryAccent,
              foregroundColor: Colors.white,
            ),
            child: Text(l10n.retryLoading),
          ),
        ],
      ),
    );
  }

  Widget _buildFAB() {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppColors.primaryAccent,
            AppColors.primaryAccent.withValues(alpha: 0.8),
          ],
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: AppColors.primaryAccent.withValues(alpha: 0.3),
            blurRadius: 16,
            offset: const Offset(0, 8),
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
          Icons.add_home,
          color: AppColors.textOnAccent,
          size: 28,
        ),
      ),
    );
  }

  List<ContactUser> _filterTenants(List<ContactUser> tenants) {
    if (_searchQuery.isEmpty) {
      return tenants;
    }
    
    return tenants.where((tenant) {
      final searchLower = _searchQuery.toLowerCase();
      return tenant.fullName.toLowerCase().contains(searchLower) ||
             tenant.email.toLowerCase().contains(searchLower) ||
             tenant.properties.any((property) => 
                 property.toLowerCase().contains(searchLower));
    }).toList();
  }

  List<Property> _getTenantProperties(ContactUser tenant, List<Property> allProperties) {
    return allProperties.where((property) {
      return property.tenantIds.contains(tenant.id);
    }).toList();
  }

  void _messageTenant(ContactUser tenant) {
    HapticFeedback.lightImpact();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Starting conversation with ${tenant.fullName}...'),
        backgroundColor: AppColors.primaryAccent,
        action: SnackBarAction(
          label: 'Open Chat',
          textColor: Colors.white,
          onPressed: () => context.push('/conversations'),
        ),
      ),
    );
  }

  void _callTenant(ContactUser tenant) {
    if (tenant.phone.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('No phone number available for ${tenant.fullName}'),
          backgroundColor: AppColors.warning,
        ),
      );
      return;
    }

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: AppColors.surfaceCards,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          title: Text(
            'Call ${tenant.fullName}',
            style: TextStyle(color: AppColors.textPrimary),
          ),
          content: Text(
            'Do you want to call ${tenant.phone}?',
            style: TextStyle(color: AppColors.textSecondary),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text('Cancel', style: TextStyle(color: AppColors.textSecondary)),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.of(context).pop();
                // TODO: Implement actual phone call functionality
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Phone call functionality will be implemented'),
                    backgroundColor: AppColors.success,
                  ),
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.success,
                foregroundColor: Colors.white,
              ),
              child: const Text('Call'),
            ),
          ],
        );
      },
    );
  }

  void _showTenantDetails(ContactUser tenant, List<Property> tenantProperties) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => Container(
        height: MediaQuery.of(context).size.height * 0.7,
        decoration: BoxDecoration(
          color: AppColors.surfaceCards,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Column(
          children: [
            Container(
              margin: const EdgeInsets.only(top: 12),
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: AppColors.textTertiary,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          width: 60,
                          height: 60,
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                              colors: [
                                AppColors.primaryAccent,
                                AppColors.primaryAccent.withValues(alpha: 0.7),
                              ],
                            ),
                            shape: BoxShape.circle,
                          ),
                          child: Center(
                            child: Text(
                              tenant.fullName[0].toUpperCase(),
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 24,
                                fontWeight: FontWeight.w700,
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
                                tenant.fullName,
                                style: TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.w700,
                                  color: AppColors.textPrimary,
                                ),
                              ),
                              Text(
                                'Tenant Details',
                                style: TextStyle(
                                  fontSize: 14,
                                  color: AppColors.textSecondary,
                                ),
                              ),
                            ],
                          ),
                        ),
                        IconButton(
                          onPressed: () => Navigator.pop(context),
                          icon: Icon(Icons.close, color: AppColors.textTertiary),
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),
                    // Contact Information
                    _buildDetailSection('Contact Information', [
                      _buildDetailItem('Email', tenant.email, Icons.email_outlined),
                      if (tenant.phone.isNotEmpty)
                        _buildDetailItem('Phone', tenant.phone, Icons.phone_outlined),
                    ]),
                    const SizedBox(height: 24),
                    // Properties
                    if (tenantProperties.isNotEmpty) ...[
                      _buildDetailSection('Assigned Properties', 
                        tenantProperties.map((property) => 
                          _buildPropertyDetailItem(property)
                        ).toList()
                      ),
                    ] else ...[
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: AppColors.warning.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: AppColors.warning.withValues(alpha: 0.2),
                            width: 1,
                          ),
                        ),
                        child: Row(
                          children: [
                            Icon(Icons.warning_outlined, color: AppColors.warning),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                'No properties assigned to this tenant',
                                style: TextStyle(
                                  fontSize: 14,
                                  color: AppColors.warning,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailSection(String title, List<Widget> children) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: AppColors.textPrimary,
          ),
        ),
        const SizedBox(height: 12),
        ...children,
      ],
    );
  }

  Widget _buildDetailItem(String label, String value, IconData icon) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.primaryBackground,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: AppColors.borderLight,
          width: 1,
        ),
      ),
      child: Row(
        children: [
          Icon(icon, color: AppColors.primaryAccent, size: 20),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(
                  fontSize: 12,
                  color: AppColors.textTertiary,
                  fontWeight: FontWeight.w500,
                ),
              ),
              Text(
                value,
                style: TextStyle(
                  fontSize: 14,
                  color: AppColors.textPrimary,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildPropertyDetailItem(Property property) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.primaryBackground,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: AppColors.borderLight,
          width: 1,
        ),
      ),
      child: Row(
        children: [
          Icon(Icons.home_outlined, color: AppColors.success, size: 20),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  property.address.street,
                  style: TextStyle(
                    fontSize: 14,
                    color: AppColors.textPrimary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Text(
                  '${property.address.city}, ${property.address.postalCode}',
                  style: TextStyle(
                    fontSize: 12,
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          Text(
            ref.read(currencyProvider.notifier).formatAmount(property.rentAmount),
            style: TextStyle(
              fontSize: 14,
              color: AppColors.success,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  void _showFilterOptions() {
    // TODO: Implement filter options (Active/Inactive, Property type, etc.)
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Filter options will be implemented'),
        backgroundColor: AppColors.primaryAccent,
      ),
    );
  }
}
