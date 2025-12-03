// Clean TenantsPage implementation (deduplicated, no deprecated Radio usage)
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../../../l10n/app_localizations.dart';
import '../../../../core/providers/dynamic_colors_provider.dart';
import '../../../../core/providers/currency_provider.dart';
import '../../../chat/domain/models/contact_user.dart';
import '../../../chat/presentation/providers/contact_providers.dart';
import '../../../property/domain/models/property.dart';
import '../../../property/presentation/providers/property_providers.dart';

class TenantsPage extends ConsumerStatefulWidget {
  const TenantsPage({super.key});
  @override
  ConsumerState<TenantsPage> createState() => _TenantsPageState();
}

class _TenantsPageState extends ConsumerState<TenantsPage> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  String _tenantFilter = 'all';
  String _sortKey = 'name'; // name | status

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colors = ref.watch(dynamicColorsProvider);
    final contactsAsync = ref.watch(userContactsProvider);
    final propertiesAsync = ref.watch(landlordPropertiesProvider);
    final l10n = AppLocalizations.of(context)!;
    return Scaffold(
      backgroundColor: colors.primaryBackground,
      appBar: _buildAppBar(colors, l10n),
      floatingActionButton: _buildFAB(colors, l10n),
      body: RefreshIndicator(
        onRefresh: () async {
          ref.invalidate(userContactsProvider);
          ref.invalidate(landlordPropertiesProvider);
        },
        color: colors.primaryAccent,
        child: CustomScrollView(
          slivers: [
            SliverToBoxAdapter(child: _buildSearchBar(colors, l10n)),
            SliverToBoxAdapter(child: _buildFilterChips(colors, l10n)),
            SliverToBoxAdapter(
              child: contactsAsync.when(
                data: (contacts) => propertiesAsync.when(
                  data: (properties) => _buildStatsSection(
                      _sortTenants(_filterTenants(contacts)),
                      properties,
                      colors,
                      l10n),
                  loading: () => const SizedBox.shrink(),
                  error: (_, __) => const SizedBox.shrink(),
                ),
                loading: () => const SizedBox.shrink(),
                error: (_, __) => const SizedBox.shrink(),
              ),
            ),
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 100),
              sliver: contactsAsync.when(
                data: (contacts) => propertiesAsync.when(
                  data: (properties) => _buildTenantsList(
                      _sortTenants(_filterTenants(contacts)),
                      properties,
                      l10n,
                      colors),
                  loading: () => SliverFillRemaining(
                      child: _buildLoadingState(colors, l10n)),
                  error: (_, __) => SliverFillRemaining(
                      child: _buildErrorState(colors, l10n)),
                ),
                loading: () => SliverFillRemaining(
                    child: _buildLoadingState(colors, l10n)),
                error: (_, __) =>
                    SliverFillRemaining(child: _buildErrorState(colors, l10n)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  PreferredSizeWidget _buildAppBar(
          DynamicAppColors colors, AppLocalizations l10n) =>
      AppBar(
        title: Text(l10n.tenantManagement),
        backgroundColor: colors.surfaceCards,
        elevation: 0,
        leading: IconButton(
            icon: Icon(Icons.arrow_back_ios_new, color: colors.textPrimary),
            onPressed: () =>
                context.canPop() ? context.pop() : context.go('/home')),
        actions: [
          IconButton(
              icon: const Icon(Icons.filter_list_rounded),
              onPressed: _showFilterOptions,
              tooltip: l10n.filter)
        ],
      );

  Widget _buildStatsSection(
      List<ContactUser> tenants,
      List<Property> properties,
      DynamicAppColors colors,
      AppLocalizations l10n) {
    final occupied = properties.where((p) => p.status == 'rented').length;
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 20),
      child: Column(
        children: [
          _buildLargeStatCard(
            title: l10n.tenantManagement,
            subtitle: l10n.manageTenantDescription,
            icon: Icons.people,
            gradient: [
              const Color(0xFF4A90E2),
              const Color(0xFF357ABD),
            ],
            colors: colors,
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _buildSmallStatCard(
                  label: l10n.totalTenants,
                  value: tenants.length.toString(),
                  icon: Icons.people_outline,
                  gradient: [
                    colors.primaryAccent,
                    colors.primaryAccent.withValues(alpha: 0.7),
                  ],
                  colors: colors,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildSmallStatCard(
                  label: l10n.occupiedUnits,
                  value: occupied.toString(),
                  icon: Icons.home_outlined,
                  gradient: [
                    colors.success,
                    colors.success.withValues(alpha: 0.7),
                  ],
                  colors: colors,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSearchBar(DynamicAppColors colors, AppLocalizations l10n) =>
      Container(
        margin: const EdgeInsets.fromLTRB(16, 16, 16, 8),
        decoration: BoxDecoration(
          color: colors.surfaceCards,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
              color: colors.borderLight.withValues(alpha: 0.5), width: 1),
          boxShadow: [
            BoxShadow(
                color: colors.shadowColor.withValues(alpha: 0.06),
                blurRadius: 12,
                offset: const Offset(0, 4))
          ],
        ),
        child: TextField(
          controller: _searchController,
          onChanged: (v) => setState(() => _searchQuery = v),
          style: TextStyle(
              color: colors.textPrimary,
              fontSize: 15,
              fontWeight: FontWeight.w500),
          decoration: InputDecoration(
            hintText: l10n.searchTenants,
            hintStyle: TextStyle(
                color: colors.textTertiary,
                fontSize: 15,
                fontWeight: FontWeight.w400),
            prefixIcon: Container(
                padding: const EdgeInsets.all(12),
                child: Icon(Icons.search_outlined,
                    color: colors.primaryAccent, size: 20)),
            suffixIcon: _searchQuery.isNotEmpty
                ? IconButton(
                    icon:
                        Icon(Icons.clear, color: colors.textTertiary, size: 20),
                    onPressed: () {
                      _searchController.clear();
                      setState(() => _searchQuery = '');
                    })
                : null,
            border: InputBorder.none,
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
          ),
        ),
      );

  Widget _buildFilterChips(DynamicAppColors colors, AppLocalizations l10n) =>
      Padding(
        padding: const EdgeInsets.fromLTRB(16, 4, 16, 0),
        child: Row(
          children: [
            _buildChoiceChip(
                label: 'All',
                selected: _tenantFilter == 'all',
                onTap: () => setState(() => _tenantFilter = 'all'),
                colors: colors),
            const SizedBox(width: 8),
            _buildChoiceChip(
                label: 'Active',
                selected: _tenantFilter == 'active',
                onTap: () => setState(() => _tenantFilter = 'active'),
                colors: colors),
            const SizedBox(width: 8),
            _buildChoiceChip(
                label: 'Inactive',
                selected: _tenantFilter == 'inactive',
                onTap: () => setState(() => _tenantFilter = 'inactive'),
                colors: colors),
            const Spacer(),
            PopupMenuButton<String>(
              tooltip: 'Sort',
              color: colors.surfaceCards,
              onSelected: (v) => setState(() => _sortKey = v),
              itemBuilder: (c) => [
                PopupMenuItem(
                  value: 'name',
                  child: Row(children: [
                    Icon(Icons.sort_by_alpha,
                        size: 18,
                        color: _sortKey == 'name'
                            ? colors.primaryAccent
                            : colors.textSecondary),
                    const SizedBox(width: 8),
                    Text(l10n.tenantSortNameAz)
                  ]),
                ),
                PopupMenuItem(
                  value: 'status',
                  child: Row(children: [
                    Icon(Icons.compare_arrows,
                        size: 18,
                        color: _sortKey == 'status'
                            ? colors.primaryAccent
                            : colors.textSecondary),
                    const SizedBox(width: 8),
                    Text(l10n.status)
                  ]),
                ),
              ],
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: colors.primaryBackground,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                      color: colors.borderLight.withValues(alpha: 0.5),
                      width: 1),
                ),
                child: Row(children: [
                  Icon(Icons.sort_rounded, size: 18, color: colors.textPrimary),
                  const SizedBox(width: 6),
                  Text(
                    _sortKey == 'name' ? l10n.name : l10n.status,
                    style: TextStyle(
                        color: colors.textPrimary,
                        fontWeight: FontWeight.w600,
                        fontSize: 12),
                  ),
                ]),
              ),
            ),
          ],
        ),
      );

  Widget _buildChoiceChip({
    required String label,
    required bool selected,
    required VoidCallback onTap,
    required DynamicAppColors colors,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeOut,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: selected
              ? colors.primaryAccent.withValues(alpha: 0.12)
              : colors.primaryBackground,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(
            color: selected ? colors.primaryAccent : colors.borderLight,
            width: 1,
          ),
        ),
        child: Row(children: [
          if (selected) ...[
            Icon(Icons.check, size: 16, color: colors.primaryAccent),
            const SizedBox(width: 6),
          ],
          Text(
            label,
            style: TextStyle(
              color: selected ? colors.primaryAccent : colors.textPrimary,
              fontWeight: FontWeight.w600,
              fontSize: 12,
            ),
          ),
        ]),
      ),
    );
  }

  Widget _buildLargeStatCard({
    required String title,
    required String subtitle,
    required IconData icon,
    required List<Color> gradient,
    required DynamicAppColors colors,
  }) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: gradient,
        ),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: gradient[0].withValues(alpha: 0.3),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Icon(icon, color: Colors.white, size: 32),
          ),
          const SizedBox(width: 20),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 22,
                    fontWeight: FontWeight.w700,
                    letterSpacing: -0.5,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  subtitle,
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.9),
                    fontSize: 13,
                    fontWeight: FontWeight.w400,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSmallStatCard({
    required String label,
    required String value,
    required IconData icon,
    required List<Color> gradient,
    required DynamicAppColors colors,
  }) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: gradient,
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: gradient[0].withValues(alpha: 0.25),
            blurRadius: 16,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: Colors.white, size: 24),
          ),
          const SizedBox(height: 16),
          Text(
            value,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 32,
              fontWeight: FontWeight.w700,
              letterSpacing: -1,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.85),
              fontSize: 13,
              fontWeight: FontWeight.w500,
              letterSpacing: 0.3,
            ),
          ),
        ],
      ),
    );
  }

  SliverList _buildTenantsList(
      List<ContactUser> tenants,
      List<Property> properties,
      AppLocalizations l10n,
      DynamicAppColors colors) {
    if (tenants.isEmpty) {
      return SliverList(
        delegate: SliverChildListDelegate([
          _buildEmptyState(colors, l10n),
        ]),
      );
    }
    return SliverList(
      delegate: SliverChildBuilderDelegate(
        (_, i) {
          final t = tenants[i];
          final props = _getTenantProperties(t, properties);
          return Padding(
            padding: const EdgeInsets.only(bottom: 16),
            child: _buildTenantCard(t, props, l10n, colors),
          );
        },
        childCount: tenants.length,
      ),
    );
  }

  Widget _buildTenantCard(ContactUser tenant, List<Property> tenantProperties,
      AppLocalizations l10n, DynamicAppColors colors) {
    final hasProps = tenantProperties.isNotEmpty;
    final status = tenant.status ?? (hasProps ? 'active' : 'available');
    final statusColor =
        status == 'active' ? const Color(0xFF10B981) : const Color(0xFFF59E0B);
    return GestureDetector(
      onTap: () {
        HapticFeedback.lightImpact();
        _showTenantDetails(tenant, tenantProperties);
      },
      child: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                statusColor.withValues(alpha: 0.12),
                statusColor.withValues(alpha: 0.05),
              ]),
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(
                color: statusColor.withValues(alpha: 0.15),
                blurRadius: 20,
                offset: const Offset(0, 10))
          ],
        ),
        child: Column(children: [
          Container(
            padding: const EdgeInsets.all(20),
            child: Column(children: [
              Row(children: [
                Container(
                    width: 60,
                    height: 60,
                    decoration: BoxDecoration(
                        gradient: LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            colors: [
                              statusColor,
                              statusColor.withValues(alpha: 0.8)
                            ]),
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                              color: statusColor.withValues(alpha: 0.3),
                              blurRadius: 12,
                              offset: const Offset(0, 6))
                        ]),
                    child: Center(
                        child: Text(
                            (tenant.fullName.isNotEmpty
                                    ? tenant.fullName[0]
                                    : 'T')
                                .toUpperCase(),
                            style: const TextStyle(
                                color: Colors.white,
                                fontSize: 24,
                                fontWeight: FontWeight.w700)))),
                const SizedBox(width: 16),
                Expanded(
                    child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                      Text(tenant.fullName,
                          style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w700,
                              color: colors.textPrimary,
                              letterSpacing: -0.5)),
                      const SizedBox(height: 6),
                      Text(tenant.email,
                          style: TextStyle(
                              fontSize: 14, color: colors.textSecondary)),
                    ])),
                Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    decoration: BoxDecoration(
                        color: statusColor,
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: [
                          BoxShadow(
                              color: statusColor.withValues(alpha: 0.3),
                              blurRadius: 8,
                              offset: const Offset(0, 4))
                        ]),
                    child: Text(
                        status == 'active'
                            ? l10n.active.toUpperCase()
                            : l10n.available.toUpperCase(),
                        style: const TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            color: Colors.white,
                            letterSpacing: 1))),
              ]),
            ]),
          ),
          if (hasProps) ...[
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.5),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: statusColor.withValues(alpha: 0.2),
                  width: 1.5,
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(children: [
                    Icon(Icons.home_outlined, size: 18, color: statusColor),
                    const SizedBox(width: 8),
                    Text(l10n.assignedProperties,
                        style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                            color: colors.textPrimary,
                            letterSpacing: 0.3))
                  ]),
                  const SizedBox(height: 16),
                  ...tenantProperties.map((p) => Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: Row(
                        children: [
                          Container(
                            width: 6,
                            height: 6,
                            decoration: BoxDecoration(
                              color: statusColor,
                              shape: BoxShape.circle,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                              child: Text(p.address.street,
                                  style: TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w500,
                                      color: colors.textPrimary))),
                          Text(
                              ref
                                  .read(currencyProvider.notifier)
                                  .formatAmount(p.rentAmount),
                              style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w700,
                                  color: statusColor))
                        ],
                      ))),
                ],
              ),
            ),
          ],
          Container(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
            child: Row(children: [
              Expanded(
                  child: _buildActionButton(
                      l10n.message,
                      Icons.chat_bubble_outline,
                      colors.primaryAccent,
                      () => _messageTenant(tenant))),
              const SizedBox(width: 12),
              Expanded(
                  child: _buildActionButton(l10n.call, Icons.phone_outlined,
                      colors.success, () => _callTenant(tenant))),
              const SizedBox(width: 12),
              Expanded(
                  child: _buildActionButton(
                      l10n.details,
                      Icons.info_outline,
                      colors.textSecondary,
                      () => _showTenantDetails(tenant, tenantProperties))),
            ]),
          ),
        ]),
      ),
    );
  }

  Widget _buildActionButton(
          String label, IconData icon, Color color, VoidCallback onPressed) =>
      GestureDetector(
        onTap: onPressed,
        child: Container(
            padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 8),
            decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.6),
                borderRadius: BorderRadius.circular(16),
                border:
                    Border.all(color: color.withValues(alpha: 0.3), width: 1.5),
                boxShadow: [
                  BoxShadow(
                      color: color.withValues(alpha: 0.1),
                      blurRadius: 10,
                      offset: const Offset(0, 4))
                ]),
            child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
              Icon(icon, size: 18, color: color),
              const SizedBox(width: 8),
              Text(label,
                  style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: color,
                      letterSpacing: 0.4))
            ])),
      );

  Widget _buildEmptyState(DynamicAppColors colors, AppLocalizations l10n) =>
      Center(
        child: Padding(
            padding: const EdgeInsets.all(40),
            child:
                Column(mainAxisAlignment: MainAxisAlignment.center, children: [
              Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                      gradient: LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [
                            colors.primaryAccent.withValues(alpha: 0.1),
                            colors.primaryAccent.withValues(alpha: 0.05)
                          ]),
                      shape: BoxShape.circle),
                  child: Icon(Icons.people_outline,
                      size: 48, color: colors.primaryAccent)),
              const SizedBox(height: 24),
              Text(l10n.noTenantsYet,
                  style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w600,
                      color: colors.textPrimary)),
              const SizedBox(height: 8),
              Text(l10n.addPropertiesInviteTenants,
                  style: TextStyle(fontSize: 14, color: colors.textSecondary),
                  textAlign: TextAlign.center),
              const SizedBox(height: 24),
              ElevatedButton.icon(
                  onPressed: () {
                    HapticFeedback.mediumImpact();
                    context.push('/add-property');
                  },
                  style: ElevatedButton.styleFrom(
                      backgroundColor: colors.primaryAccent,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(
                          horizontal: 24, vertical: 12),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12))),
                  icon: const Icon(Icons.add_home),
                  label: Text(l10n.addProperty)),
            ])),
      );

  Widget _buildLoadingState(DynamicAppColors colors, AppLocalizations l10n) =>
      Center(
        child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
          CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(colors.primaryAccent)),
          const SizedBox(height: 16),
          Text(l10n.loadingTenants),
        ]),
      );

  Widget _buildErrorState(DynamicAppColors colors, AppLocalizations l10n) =>
      Center(
        child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
          Icon(Icons.error_outline, size: 48, color: colors.error),
          const SizedBox(height: 16),
          Text(l10n.errorLoadingTenants,
              style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: colors.textPrimary)),
          const SizedBox(height: 8),
          Text(l10n.pleaseTryAgainLater,
              style: TextStyle(fontSize: 14, color: colors.textSecondary)),
          const SizedBox(height: 16),
          ElevatedButton(
              onPressed: () {
                ref.invalidate(userContactsProvider);
                ref.invalidate(landlordPropertiesProvider);
              },
              style: ElevatedButton.styleFrom(
                  backgroundColor: colors.primaryAccent,
                  foregroundColor: Colors.white),
              child: Text(l10n.retryLoading)),
        ]),
      );

  Widget _buildFAB(DynamicAppColors colors, AppLocalizations l10n) => Container(
        decoration: BoxDecoration(
            gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  colors.primaryAccent,
                  colors.primaryAccent.withValues(alpha: 0.8)
                ]),
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                  color: colors.primaryAccent.withValues(alpha: 0.3),
                  blurRadius: 16,
                  offset: const Offset(0, 8))
            ]),
        child: FloatingActionButton(
            onPressed: () {
              HapticFeedback.mediumImpact();
              context.push('/add-property');
            },
            backgroundColor: Colors.transparent,
            elevation: 0,
            child: Icon(Icons.add_home, color: colors.textOnAccent, size: 28)),
      );

  List<ContactUser> _filterTenants(List<ContactUser> tenants) {
    Iterable<ContactUser> filtered = tenants;
    switch (_tenantFilter) {
      case 'active':
        filtered = filtered
            .where((t) => (t.status == 'active') || t.properties.isNotEmpty);
        break;
      case 'inactive':
        filtered = filtered
            .where((t) => (t.status != 'active') && t.properties.isEmpty);
        break;
      case 'property_type':
        break; // placeholder
      case 'all':
      default:
        break;
    }
    if (_searchQuery.isNotEmpty) {
      final q = _searchQuery.toLowerCase();
      filtered = filtered.where(
        (t) =>
            t.fullName.toLowerCase().contains(q) ||
            t.email.toLowerCase().contains(q) ||
            t.properties.any((p) => p.toLowerCase().contains(q)),
      );
    }
    return filtered.toList();
  }

  List<ContactUser> _sortTenants(List<ContactUser> tenants) {
    final list = [...tenants];
    if (_sortKey == 'status') {
      list.sort((a, b) {
        final aActive = (a.status == 'active') || a.properties.isNotEmpty;
        final bActive = (b.status == 'active') || b.properties.isNotEmpty;
        if (aActive == bActive) {
          return a.fullName.toLowerCase().compareTo(b.fullName.toLowerCase());
        }
        return aActive ? -1 : 1; // active first
      });
    } else {
      list.sort((a, b) =>
          a.fullName.toLowerCase().compareTo(b.fullName.toLowerCase()));
    }
    return list;
  }

  List<Property> _getTenantProperties(ContactUser tenant, List<Property> all) =>
      all.where((p) => p.tenantIds.contains(tenant.id)).toList();

  void _messageTenant(ContactUser tenant) {
    HapticFeedback.lightImpact();
    final colors = ref.read(dynamicColorsProvider);
    final l10n = AppLocalizations.of(context)!;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(l10n.tenantStartingConversation(tenant.fullName)),
        backgroundColor: colors.primaryAccent,
        action: SnackBarAction(
          label: l10n.openChat,
          textColor: Colors.white,
          onPressed: () => context.push('/conversations'),
        ),
      ),
    );
  }

  void _callTenant(ContactUser tenant) {
    final colors = ref.read(dynamicColorsProvider);
    final l10n = AppLocalizations.of(context)!;
    if (tenant.phone.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(l10n.tenantNoPhoneAvailable(tenant.fullName)),
          backgroundColor: colors.warning,
        ),
      );
      return;
    }
    showDialog(
      context: context,
      builder: (c) => AlertDialog(
        backgroundColor: colors.surfaceCards,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(l10n.tenantCallTitle(tenant.fullName),
            style: TextStyle(color: colors.textPrimary)),
        content: Text(l10n.tenantCallConfirmation(tenant.phone),
            style: TextStyle(color: colors.textSecondary)),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(c).pop(),
            child: Text(l10n.cancel,
                style: TextStyle(color: colors.textSecondary)),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.of(c).pop();
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
                    content: Text(l10n.tenantCallError(e.toString())),
                    backgroundColor: colors.error,
                  ),
                );
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: colors.success,
              foregroundColor: Colors.white,
            ),
            child: Text(l10n.call),
          )
        ],
      ),
    );
  }

  void _showTenantDetails(ContactUser tenant, List<Property> tenantProperties) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => Consumer(
        builder: (context, ref, _) {
          final colors = ref.watch(dynamicColorsProvider);
          return Container(
            height: MediaQuery.of(context).size.height * 0.7,
            decoration: BoxDecoration(
              color: colors.surfaceCards,
              borderRadius:
                  const BorderRadius.vertical(top: Radius.circular(24)),
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
                                    colors.primaryAccent.withValues(alpha: 0.7)
                                  ],
                                ),
                                shape: BoxShape.circle,
                              ),
                              child: Center(
                                child: Text(
                                  tenant.fullName[0].toUpperCase(),
                                  style: const TextStyle(
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
                              icon:
                                  Icon(Icons.close, color: colors.textTertiary),
                            ),
                          ],
                        ),
                        const SizedBox(height: 24),
                        _buildDetailSection(
                          'Contact Information',
                          [
                            _buildDetailItem('Email', tenant.email,
                                Icons.email_outlined, colors),
                            if (tenant.phone.isNotEmpty)
                              _buildDetailItem('Phone', tenant.phone,
                                  Icons.phone_outlined, colors),
                          ],
                          colors,
                        ),
                        const SizedBox(height: 24),
                        if (tenantProperties.isNotEmpty)
                          _buildDetailSection(
                            'Assigned Properties',
                            tenantProperties
                                .map((p) => _buildPropertyDetailItem(p, colors))
                                .toList(),
                            colors,
                          )
                        else
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
                                Icon(Icons.warning_outlined,
                                    color: colors.warning),
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

  Widget _buildDetailSection(
          String title, List<Widget> children, DynamicAppColors colors) =>
      Column(
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

  Widget _buildDetailItem(
          String label, String value, IconData icon, DynamicAppColors colors) =>
      Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: colors.primaryBackground,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: colors.borderLight, width: 1),
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

  Widget _buildPropertyDetailItem(Property property, DynamicAppColors colors) =>
      Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: colors.primaryBackground,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: colors.borderLight, width: 1),
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
              ref
                  .read(currencyProvider.notifier)
                  .formatAmount(property.rentAmount),
              style: TextStyle(
                fontSize: 14,
                color: colors.success,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(width: 8),
            IconButton(
              onPressed: () => _showRemoveTenantDialog(property),
              icon: Icon(Icons.remove_circle_outline,
                  color: colors.error, size: 20),
              style: IconButton.styleFrom(
                backgroundColor: colors.error.withValues(alpha: 0.1),
                minimumSize: const Size(32, 32),
                padding: const EdgeInsets.all(4),
              ),
            ),
          ],
        ),
      );

  void _showFilterOptions() {
    String temp = _tenantFilter;
    final l10n = AppLocalizations.of(context)!;
    showDialog(
      context: context,
      builder: (c) => StatefulBuilder(
        builder: (c, setStateDialog) => AlertDialog(
          title: Text(l10n.tenantFilterTitle),
          content: _FilterOptionList(
            selected: temp,
            onSelect: (val) {
              setStateDialog(() => temp = val);
              setState(() => _tenantFilter = val);
              Navigator.of(c).pop();
            },
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(c).pop(),
              child: Text(l10n.close),
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
      builder: (c) => AlertDialog(
        backgroundColor: colors.surfaceCards,
        title: Text(l10n.removeTenant,
            style: TextStyle(color: colors.textPrimary)),
        content: Text(l10n.removeTenantConfirmation,
            style: TextStyle(color: colors.textSecondary)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(c),
            child:
                Text(l10n.cancel, style: TextStyle(color: colors.textTertiary)),
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

  Future<void> _removeTenantFromProperty(Property property) async {
    final colors = ref.read(dynamicColorsProvider);
    final l10n = AppLocalizations.of(context)!;
    Navigator.pop(context); // dialog
    Navigator.pop(context); // bottom sheet
    try {
      final contacts = ref.read(userContactsProvider);
      if (contacts.hasValue) {
        final tenants = contacts.value!;
        final tenant = tenants.firstWhere(
          (t) => property.tenantIds.contains(t.id),
          orElse: () => throw Exception('Tenant not found'),
        );
        await ref
            .read(tenantRemovalProvider.notifier)
            .removeTenant(property.id, tenant.id);
        ref.invalidate(userContactsProvider);
        ref.invalidate(landlordPropertiesProvider);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(l10n.tenantRemovedSuccessfully),
              backgroundColor: colors.success,
            ),
          );
        }
      }
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(l10n.failedToRemoveTenant),
            backgroundColor: colors.error,
          ),
        );
      }
    }
  }
}

class _FilterOptionList extends StatelessWidget {
  final String selected;
  final ValueChanged<String> onSelect;
  const _FilterOptionList({required this.selected, required this.onSelect});
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    const options = [
      ('all', 'All Tenants', Icons.people_outline),
      ('active', 'Active Tenants', Icons.check_circle_outline),
      ('inactive', 'Inactive Tenants', Icons.pause_circle_outline),
      ('property_type', 'By Property Type', Icons.home_work_outlined),
    ];
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: options.map((o) {
        final isSelected = o.$1 == selected;
        return InkWell(
          onTap: () => onSelect(o.$1),
          borderRadius: BorderRadius.circular(12),
          child: Container(
            margin: const EdgeInsets.symmetric(vertical: 4),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              color: isSelected
                  ? theme.colorScheme.primary.withValues(alpha: 0.08)
                  : theme.colorScheme.surfaceContainerHighest
                      .withValues(alpha: 0.4),
              border: Border.all(
                  color: isSelected
                      ? theme.colorScheme.primary
                      : theme.dividerColor.withValues(alpha: 0.4)),
            ),
            child: Row(children: [
              Icon(o.$3,
                  size: 20,
                  color: isSelected
                      ? theme.colorScheme.primary
                      : theme.iconTheme.color),
              const SizedBox(width: 12),
              Expanded(
                  child: Text(o.$2,
                      style: theme.textTheme.bodyMedium?.copyWith(
                          fontWeight:
                              isSelected ? FontWeight.w600 : FontWeight.w500))),
              AnimatedContainer(
                duration: const Duration(milliseconds: 240),
                curve: Curves.easeOutCubic,
                width: 22,
                height: 22,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(
                      color: isSelected
                          ? theme.colorScheme.primary
                          : theme.dividerColor.withValues(alpha: 0.6),
                      width: 2),
                ),
                child: AnimatedOpacity(
                  duration: const Duration(milliseconds: 240),
                  opacity: isSelected ? 1 : 0,
                  child: Container(
                    margin: const EdgeInsets.all(3),
                    decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: theme.colorScheme.primary),
                  ),
                ),
              ),
            ]),
          ),
        );
      }).toList(),
    );
  }
}
