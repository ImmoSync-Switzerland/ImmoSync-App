import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../../l10n/app_localizations.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../../core/providers/dynamic_colors_provider.dart';
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
    final colors = ref.watch(dynamicColorsProvider);
    final contactsAsync = ref.watch(userContactsProvider); // Changed from allTenantsProvider
    final propertiesAsync = ref.watch(landlordPropertiesProvider);

    return Scaffold(
      backgroundColor: colors.primaryBackground,
      appBar: _buildAppBar(colors),
      body: AnimatedBuilder(
        animation: _animationController,
        builder: (context, child) {
          return Transform.translate(
            offset: Offset(0, _slideAnimation.value),
            child: Opacity(
              opacity: _fadeAnimation.value,
              child: RefreshIndicator(              onRefresh: () async {
                HapticFeedback.lightImpact();
                ref.invalidate(userContactsProvider); // Changed from allTenantsProvider
                ref.invalidate(landlordPropertiesProvider);
                await Future.delayed(const Duration(milliseconds: 500));
              },
                color: colors.primaryAccent,
                backgroundColor: colors.primaryBackground,
                child: Column(
                  children: [
                    _buildHeader(colors),
                    _buildSearchBar(colors),
                    Expanded(
                      child: contactsAsync.when(
                        data: (tenants) {
                          final filteredTenants = _filterTenants(tenants);
                          return propertiesAsync.when(
                            data: (properties) => _buildTenantsContent(filteredTenants, properties, l10n, colors),
                            loading: () => const Center(child: CircularProgressIndicator()),
                            error: (error, _) => _buildErrorState(colors),
                          );
                        },
                        loading: () => _buildLoadingState(colors),
                        error: (error, _) => _buildErrorState(colors),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
      floatingActionButton: _buildFAB(colors),
    );
  }
  PreferredSizeWidget _buildAppBar(DynamicAppColors colors) {
    final l10n = AppLocalizations.of(context)!;
    return AppBar(
      backgroundColor: colors.primaryBackground,
      elevation: 0,
      title: Text(
        l10n.tenants,
        style: TextStyle(
          color: colors.textPrimary,
          fontSize: 18,
          fontWeight: FontWeight.w600,
          inherit: true,
        ),
      ),      leading: IconButton(
        icon: Icon(Icons.arrow_back_ios, color: colors.textPrimary),
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
          icon: Icon(Icons.filter_list_outlined, color: colors.textPrimary),
          onPressed: () {
            HapticFeedback.lightImpact();
            _showFilterOptions();
          },
        ),
      ],
    );
  }
  Widget _buildHeader(DynamicAppColors colors) {
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
              color: colors.textPrimary,
              letterSpacing: -0.5,
              inherit: true,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            l10n.manageTenantDescription,
            style: TextStyle(
              fontSize: 16,
              color: colors.textSecondary,
              letterSpacing: -0.2,
              inherit: true,
            ),
          ),
        ],
      ),
    );
  }
  Widget _buildSearchBar(DynamicAppColors colors) {
    final l10n = AppLocalizations.of(context)!;;
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
          colors: [
            colors.surfaceCards,
            colors.luxuryGradientStart,
          ],
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: colors.borderLight,
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: colors.shadowColor,
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
          color: colors.textPrimary,
          fontSize: 15,
          fontWeight: FontWeight.w500,
        ),
        decoration: InputDecoration(
          hintText: l10n.searchTenants,
          hintStyle: TextStyle(
            color: colors.textTertiary,
            fontSize: 15,
            fontWeight: FontWeight.w400,
          ),
          prefixIcon: Container(
            padding: const EdgeInsets.all(12),
            child: Icon(
              Icons.search_outlined,
              color: colors.primaryAccent,
              size: 20,
            ),
          ),
          suffixIcon: _searchQuery.isNotEmpty
              ? IconButton(
                  icon: Icon(
                    Icons.clear,
                    color: colors.textTertiary,
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

  Widget _buildTenantsContent(List<ContactUser> tenants, List<Property> properties, AppLocalizations l10n, DynamicAppColors colors) {
    if (tenants.isEmpty) {
      return _buildEmptyState(colors);
    }

    return Column(
      children: [
        _buildStatsCards(tenants, properties, colors),
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
                child: _buildTenantCard(tenant, tenantProperties, l10n, colors),
              );
            },
          ),
        ),
      ],
    );
  }
  Widget _buildStatsCards(List<ContactUser> tenants, List<Property> properties, DynamicAppColors colors) {
    final l10n = AppLocalizations.of(context)!;
    final totalTenants = tenants.length;
    final occupiedProperties = properties.where((p) => p.status == 'rented').length;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Row(
        children: [
          Expanded(
            child: _buildStatCard(
              l10n.totalTenants,
              totalTenants.toString(),
              Icons.people_outline,
              colors.primaryAccent,
              colors,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: _buildStatCard(
              l10n.occupiedUnits,
              occupiedProperties.toString(),
              Icons.home_outlined,
              colors.success,
              colors,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard(String title, String value, IconData icon, Color color, DynamicAppColors colors) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            colors.surfaceCards,
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
              color: colors.textPrimary,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            title,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: colors.textTertiary,
              letterSpacing: 0.5,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
  Widget _buildTenantCard(ContactUser tenant, List<Property> tenantProperties, AppLocalizations l10n, DynamicAppColors colors) {
    final hasProperties = tenantProperties.isNotEmpty;
    // Use status from backend if available, otherwise fall back to property-based logic
    final tenantStatus = tenant.status ?? (hasProperties ? 'active' : 'available');
    final statusColor = tenantStatus == 'active' ? colors.success : colors.warning;

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
              color: colors.shadowColor,
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
                          color: colors.textPrimary,
                          letterSpacing: -0.3,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        tenant.email,
                        style: TextStyle(
                          fontSize: 14,
                          color: colors.textSecondary,
                        ),
                      ),
                      if (tenant.phone.isNotEmpty) ...[
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            Icon(
                              Icons.phone_outlined,
                              size: 14,
                              color: colors.textTertiary,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              tenant.phone,
                              style: TextStyle(
                                fontSize: 14,
                                color: colors.textSecondary,
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
                  color: colors.success.withValues(alpha: 0.05),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: colors.success.withValues(alpha: 0.1),
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
                          color: colors.success,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          l10n.assignedProperties,
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: colors.success,
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
                                color: colors.textSecondary,
                              ),
                            ),
                          ),
                          Text(
                            ref.read(currencyProvider.notifier).formatAmount(property.rentAmount),
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: colors.success,
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
                    colors.primaryAccent,
                    () => _messageTenant(tenant),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildActionButton(
                    l10n.call,
                    Icons.phone_outlined,
                    colors.success,
                    () => _callTenant(tenant),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildActionButton(
                    l10n.details,
                    Icons.info_outline,
                    colors.textSecondary,
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
  Widget _buildEmptyState(DynamicAppColors colors) {
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
                    colors.primaryAccent.withValues(alpha: 0.1),
                    colors.primaryAccent.withValues(alpha: 0.05),
                  ],
                ),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.people_outline,
                size: 48,
                color: colors.primaryAccent,
              ),
            ),
            const SizedBox(height: 24),
            Text(
              l10n.noTenantsYet,
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w600,
                color: colors.textPrimary,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              l10n.addPropertiesInviteTenants,
              style: TextStyle(
                fontSize: 14,
                color: colors.textSecondary,
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
                backgroundColor: colors.primaryAccent,
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
  Widget _buildLoadingState(DynamicAppColors colors) {
    final l10n = AppLocalizations.of(context)!;
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularProgressIndicator(
            valueColor: AlwaysStoppedAnimation<Color>(colors.primaryAccent),
          ),
          const SizedBox(height: 16),
          Text(l10n.loadingTenants),
        ],
      ),
    );
  }

  Widget _buildErrorState(DynamicAppColors colors) {
    final l10n = AppLocalizations.of(context)!;
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.error_outline, size: 48, color: colors.error),
          const SizedBox(height: 16),
          Text(
            l10n.errorLoadingTenants,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: colors.textPrimary,
            ),
          ),          const SizedBox(height: 8),
          Text(
            l10n.pleaseTryAgainLater,
            style: TextStyle(
              fontSize: 14,
              color: colors.textSecondary,
            ),
          ),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: () {
              ref.invalidate(userContactsProvider); // Changed from allTenantsProvider
              ref.invalidate(landlordPropertiesProvider);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: colors.primaryAccent,
              foregroundColor: Colors.white,
            ),
            child: Text(l10n.retryLoading),
          ),
        ],
      ),
    );
  }

  Widget _buildFAB(DynamicAppColors colors) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            colors.primaryAccent,
            colors.primaryAccent.withValues(alpha: 0.8),
          ],
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: colors.primaryAccent.withValues(alpha: 0.3),
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
          color: colors.textOnAccent,
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
    final colors = ref.read(dynamicColorsProvider);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Starting conversation with ${tenant.fullName}...'),
        backgroundColor: colors.primaryAccent,
        action: SnackBarAction(
          label: 'Open Chat',
          textColor: Colors.white,
          onPressed: () => context.push('/conversations'),
        ),
      ),
    );
  }

  void _callTenant(ContactUser tenant) {
    final colors = ref.read(dynamicColorsProvider);
    if (tenant.phone.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('No phone number available for ${tenant.fullName}'),
          backgroundColor: colors.warning,
        ),
      );
      return;
    }

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: colors.surfaceCards,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          title: Text(
            'Call ${tenant.fullName}',
            style: TextStyle(color: colors.textPrimary, inherit: true),
          ),
          content: Text(
            'Do you want to call ${tenant.phone}?',
            style: TextStyle(color: colors.textSecondary, inherit: true),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text('Cancel', style: TextStyle(color: colors.textSecondary, inherit: true)),
            ),
            ElevatedButton(
              onPressed: () async {
                Navigator.of(context).pop();
                try {
                  final phoneUrl = Uri.parse('tel:${tenant.phone}');
                  if (await canLaunchUrl(phoneUrl)) {
                    await launchUrl(phoneUrl);
                  } else {
                    throw Exception('Could not launch phone dialer');
                  }
                } catch (e) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Could not make phone call: ${e.toString()}'),
                      backgroundColor: colors.error,
                    ),
                  );
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: colors.success,
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
      builder: (context) => Consumer(
        builder: (context, ref, child) {
          final colors = ref.watch(dynamicColorsProvider);
          return Container(
        height: MediaQuery.of(context).size.height * 0.7,
        decoration: BoxDecoration(
          color: colors.surfaceCards,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Column(
          children: [
            Container(
              margin: const EdgeInsets.only(top: 12),
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: colors.textTertiary,
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
                                colors.primaryAccent,
                                colors.primaryAccent.withValues(alpha: 0.7),
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
                                  color: colors.textPrimary,
                                ),
                              ),
                              Text(
                                'Tenant Details',
                                style: TextStyle(
                                  fontSize: 14,
                                  color: colors.textSecondary,
                                ),
                              ),
                            ],
                          ),
                        ),
                        IconButton(
                          onPressed: () => Navigator.pop(context),
                          icon: Icon(Icons.close, color: colors.textTertiary),
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),
                    // Contact Information
                    _buildDetailSection('Contact Information', [
                      _buildDetailItem('Email', tenant.email, Icons.email_outlined, colors),
                      if (tenant.phone.isNotEmpty)
                        _buildDetailItem('Phone', tenant.phone, Icons.phone_outlined, colors),
                    ], colors),
                    const SizedBox(height: 24),
                    // Properties
                    if (tenantProperties.isNotEmpty) ...[
                      _buildDetailSection('Assigned Properties', 
                        tenantProperties.map((property) => 
                          _buildPropertyDetailItem(property, colors)
                        ).toList(),
                        colors
                      ),
                    ] else ...[
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: colors.warning.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: colors.warning.withValues(alpha: 0.2),
                            width: 1,
                          ),
                        ),
                        child: Row(
                          children: [
                            Icon(Icons.warning_outlined, color: colors.warning),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                'No properties assigned to this tenant',
                                style: TextStyle(
                                  fontSize: 14,
                                  color: colors.warning,
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
      );
        },
      ),
    );
  }

  Widget _buildDetailSection(String title, List<Widget> children, DynamicAppColors colors) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: colors.textPrimary,
          ),
        ),
        const SizedBox(height: 12),
        ...children,
      ],
    );
  }

  Widget _buildDetailItem(String label, String value, IconData icon, DynamicAppColors colors) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colors.primaryBackground,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: colors.borderLight,
          width: 1,
        ),
      ),
      child: Row(
        children: [
          Icon(icon, color: colors.primaryAccent, size: 20),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(
                  fontSize: 12,
                  color: colors.textTertiary,
                  fontWeight: FontWeight.w500,
                ),
              ),
              Text(
                value,
                style: TextStyle(
                  fontSize: 14,
                  color: colors.textPrimary,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildPropertyDetailItem(Property property, DynamicAppColors colors) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colors.primaryBackground,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: colors.borderLight,
          width: 1,
        ),
      ),
      child: Row(
        children: [
          Icon(Icons.home_outlined, color: colors.success, size: 20),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  property.address.street,
                  style: TextStyle(
                    fontSize: 14,
                    color: colors.textPrimary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Text(
                  '${property.address.city}, ${property.address.postalCode}',
                  style: TextStyle(
                    fontSize: 12,
                    color: colors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          Text(
            ref.read(currencyProvider.notifier).formatAmount(property.rentAmount),
            style: TextStyle(
              fontSize: 14,
              color: colors.success,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(width: 8),
          Consumer(
            builder: (context, ref, child) {
              return IconButton(
                onPressed: () => _showRemoveTenantDialog(property),
                icon: Icon(
                  Icons.remove_circle_outline,
                  color: colors.error,
                  size: 20,
                ),
                style: IconButton.styleFrom(
                  backgroundColor: colors.error.withValues(alpha: 0.1),
                  minimumSize: const Size(32, 32),
                  padding: const EdgeInsets.all(4),
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  void _showFilterOptions() {
    String selectedFilter = 'all';
    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: const Text('Filter Tenants'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: Radio<String>(
                  value: 'all',
                  groupValue: selectedFilter,
                  onChanged: (String? value) {
                    if (value == null) return;
                    setState(() {
                      selectedFilter = value;
                    });
                    Navigator.of(context).pop();
                  },
                ),
                title: const Text('All Tenants'),
                onTap: () {
                  setState(() {
                    selectedFilter = 'all';
                  });
                  Navigator.of(context).pop();
                },
              ),
              ListTile(
                leading: Radio<String>(
                  value: 'active',
                  groupValue: selectedFilter,
                  onChanged: (String? value) {
                    if (value == null) return;
                    setState(() {
                      selectedFilter = value;
                    });
                    Navigator.of(context).pop();
                  },
                ),
                title: const Text('Active Tenants'),
                onTap: () {
                  setState(() {
                    selectedFilter = 'active';
                  });
                  Navigator.of(context).pop();
                },
              ),
              ListTile(
                leading: Radio<String>(
                  value: 'inactive',
                  groupValue: selectedFilter,
                  onChanged: (String? value) {
                    if (value == null) return;
                    setState(() {
                      selectedFilter = value;
                    });
                    Navigator.of(context).pop();
                  },
                ),
                title: const Text('Inactive Tenants'),
                onTap: () {
                  setState(() {
                    selectedFilter = 'inactive';
                  });
                  Navigator.of(context).pop();
                },
              ),
              ListTile(
                leading: Radio<String>(
                  value: 'property_type',
                  groupValue: selectedFilter,
                  onChanged: (String? value) {
                    if (value == null) return;
                    setState(() {
                      selectedFilter = value;
                  });
                  Navigator.of(context).pop();
                },
                ),
                title: const Text('By Property Type'),
                onTap: () {
                  setState(() {
                    selectedFilter = 'property_type';
                  });
                  Navigator.of(context).pop();
                },
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Close'),
            ),
          ],
        ),
      ),
    );
  }

  void _showRemoveTenantDialog(Property property) {
    final colors = ref.read(dynamicColorsProvider);
    final l10n = AppLocalizations.of(context)!;
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: colors.surfaceCards,
        title: Text(
          l10n.removeTenant,
          style: TextStyle(color: colors.textPrimary),
        ),
        content: Text(
          l10n.removeTenantConfirmation,
          style: TextStyle(color: colors.textSecondary),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              l10n.cancel,
              style: TextStyle(color: colors.textTertiary),
            ),
          ),
          ElevatedButton(
            onPressed: () => _removeTenantFromProperty(property),
            style: ElevatedButton.styleFrom(
              backgroundColor: colors.error,
              foregroundColor: Colors.white,
            ),
            child: Text(l10n.removeTenant),
          ),
        ],
      ),
    );
  }

  void _removeTenantFromProperty(Property property) async {
    final colors = ref.read(dynamicColorsProvider);
    final l10n = AppLocalizations.of(context)!;
    Navigator.pop(context); // Close dialog
    Navigator.pop(context); // Close tenant details
    
    try {
      // Find the current tenant that we're viewing
      final contactsAsync = ref.read(userContactsProvider); // Changed from allTenantsProvider
      if (contactsAsync.hasValue) {
        final tenants = contactsAsync.value!;
        final tenant = tenants.firstWhere(
          (t) => property.tenantIds.contains(t.id),
          orElse: () => throw Exception('Tenant not found'),
        );

        await ref.read(tenantRemovalProvider.notifier).removeTenant(
          property.id,
          tenant.id,
        );

        // Refresh the data
        ref.invalidate(userContactsProvider); // Changed from allTenantsProvider
        ref.invalidate(landlordPropertiesProvider);

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(l10n.tenantRemovedSuccessfully),
            backgroundColor: colors.success,
          ),
        );
      }
    } catch (error) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(l10n.failedToRemoveTenant),
          backgroundColor: colors.error,
        ),
      );
    }
  }
}
