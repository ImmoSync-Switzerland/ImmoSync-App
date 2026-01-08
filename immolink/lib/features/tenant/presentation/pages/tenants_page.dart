import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../../core/widgets/user_avatar.dart';
import '../../../../../l10n/app_localizations.dart';
import '../../../chat/domain/models/contact_user.dart';
import '../../../chat/presentation/providers/contact_providers.dart';
import '../../../property/domain/models/property.dart';
import '../../../property/presentation/providers/property_providers.dart';
import '../../../property/presentation/widgets/email_invite_tenant_dialog.dart';

class TenantsPage extends ConsumerStatefulWidget {
  const TenantsPage({super.key});

  @override
  ConsumerState<TenantsPage> createState() => _TenantsPageState();
}

class _TenantsPageState extends ConsumerState<TenantsPage> {
  final TextEditingController _searchController = TextEditingController();
  String _filter = 'All';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final contactsAsync = ref.watch(userContactsProvider);
    final propertiesAsync = ref.watch(landlordPropertiesProvider);
    final l10n = AppLocalizations.of(context)!;
    final media = MediaQuery.of(context);
    final bottomPadding = media.viewInsets.bottom + 100;

    final slivers = <Widget>[
      SliverPadding(
        padding: const EdgeInsets.only(bottom: 18),
        sliver: SliverToBoxAdapter(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _Header(
                title: l10n.tenantManagement,
                onBack: () =>
                    context.canPop() ? context.pop() : context.go('/home'),
              ),
              const SizedBox(height: 16),
              _SearchBar(
                controller: _searchController,
                hint: l10n.searchTenants,
                onChanged: (_) => setState(() {}),
              ),
              const SizedBox(height: 12),
              _Filters(
                active: _filter,
                onChanged: (value) => setState(() => _filter = value),
              ),
            ],
          ),
        ),
      ),
    ];

    contactsAsync.when(
      data: (contacts) => propertiesAsync.when(
        data: (properties) {
          final tenants = _mapTenants(contacts, properties);
          final filtered =
              _applyFilters(tenants, _filter, _searchController.text);
          slivers.addAll([
            SliverPadding(
              padding: const EdgeInsets.only(bottom: 16),
              sliver: SliverToBoxAdapter(
                child: _StatsGrid(
                  totalTenants: tenants.length,
                  occupiedUnits:
                      properties.where((p) => p.tenantIds.isNotEmpty).length,
                ),
              ),
            ),
            filtered.isEmpty
                ? _statusSliver(
                    _EmptyState(text: l10n.noTenantsFound),
                    bottomPadding,
                  )
                : SliverPadding(
                    padding: EdgeInsets.only(bottom: bottomPadding),
                    sliver: SliverList.builder(
                      itemCount: filtered.length,
                      itemBuilder: (context, index) => Padding(
                        padding: EdgeInsets.only(
                          bottom: index == filtered.length - 1 ? 0 : 12,
                        ),
                        child: _TenantCard(tenant: filtered[index]),
                      ),
                    ),
                  ),
          ]);
        },
        loading: () =>
            slivers.add(_statusSliver(const _LoadingState(), bottomPadding)),
        error: (_, __) => slivers.add(
          _statusSliver(
            _ErrorState(
              title: l10n.couldNotLoadTenants,
              retryLabel: l10n.retry,
              onRetry: _refresh,
            ),
            bottomPadding,
          ),
        ),
      ),
      loading: () =>
          slivers.add(_statusSliver(const _LoadingState(), bottomPadding)),
      error: (_, __) => slivers.add(
        _statusSliver(
          _ErrorState(
            title: l10n.couldNotLoadTenants,
            retryLabel: l10n.retry,
            onRetry: _refresh,
          ),
          bottomPadding,
        ),
      ),
    );

    return Scaffold(
      extendBody: true,
      resizeToAvoidBottomInset: true,
      backgroundColor: Colors.transparent,
      floatingActionButton: _AddTenantFab(
        label: l10n.addTenant,
        onTap: () async {
          HapticFeedback.mediumImpact();

          final propsAsync = propertiesAsync;
          final properties = propsAsync.asData?.value;
          if (properties == null) {
            // Still loading / error state - keep UX minimal.
            return;
          }

          if (properties.isEmpty) {
            // Can't invite without a property.
            if (!mounted) return;
            context.push('/add-property');
            return;
          }

          String propertyId;
          if (properties.length == 1) {
            propertyId = properties.first.id;
          } else {
            final selected = await showDialog<String>(
              context: context,
              builder: (ctx) => _SelectPropertyDialog(properties: properties),
            );
            if (!mounted) return;
            if (selected == null || selected.isEmpty) return;
            propertyId = selected;
          }

          if (!mounted) return;
          showDialog(
            context: context,
            builder: (ctx) => EmailInviteTenantDialog(propertyId: propertyId),
          );
        },
      ),
      body: Stack(
        children: [
          const _DeepNavyBackground(),
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 22, 20, 0),
              child: CustomScrollView(
                keyboardDismissBehavior:
                    ScrollViewKeyboardDismissBehavior.onDrag,
                slivers: slivers,
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _refresh() {
    ref.invalidate(userContactsProvider);
    ref.invalidate(landlordPropertiesProvider);
  }

  Widget _statusSliver(Widget child, double bottomPadding) {
    return SliverPadding(
      padding: EdgeInsets.only(bottom: bottomPadding),
      sliver: SliverFillRemaining(
        hasScrollBody: false,
        child: Center(child: child),
      ),
    );
  }

  List<_TenantView> _mapTenants(
    List<ContactUser> contacts,
    List<Property> properties,
  ) {
    return contacts.map((tenant) {
      final propertyLabel = _resolvePropertyLabel(tenant, properties);
      final normalizedStatus = _normalizedStatus(tenant, propertyLabel != null);
      final avatarUrl = tenant.profileImageUrl ?? tenant.profileImage;

      return _TenantView(
        name: tenant.fullName.isNotEmpty ? tenant.fullName : tenant.email,
        email: tenant.email,
        property: propertyLabel ?? 'Unassigned',
        status: normalizedStatus,
        avatarUrl: avatarUrl,
        id: tenant.id,
      );
    }).toList();
  }

  List<_TenantView> _applyFilters(
    List<_TenantView> tenants,
    String filter,
    String query,
  ) {
    final queryLower = query.trim().toLowerCase();
    final filtered = tenants.where((tenant) {
      final matchesQuery = queryLower.isEmpty ||
          tenant.name.toLowerCase().contains(queryLower) ||
          tenant.email.toLowerCase().contains(queryLower) ||
          tenant.property.toLowerCase().contains(queryLower);
      final matchesFilter = switch (filter) {
        'Active' => tenant.status == 'Active',
        'Inactive' => tenant.status != 'Active',
        _ => true,
      };
      return matchesQuery && matchesFilter;
    }).toList();

    filtered
        .sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));
    return filtered;
  }

  String _normalizedStatus(ContactUser tenant, bool hasAssignment) {
    final raw = tenant.status?.toLowerCase();
    if (raw == 'active') return 'Active';
    if (raw == 'inactive') return 'Inactive';
    if (raw == 'available') return 'Inactive';
    return hasAssignment ? 'Active' : 'Inactive';
  }

  String? _resolvePropertyLabel(ContactUser tenant, List<Property> properties) {
    Property? match;
    if (tenant.properties.isNotEmpty) {
      match = _findPropertyById(properties, tenant.properties.first);
    }
    match ??= _findPropertyForTenant(tenant.id, properties);
    return match != null ? _formatProperty(match) : null;
  }

  Property? _findPropertyById(List<Property> properties, String id) {
    for (final property in properties) {
      if (property.id == id) return property;
    }
    return null;
  }

  Property? _findPropertyForTenant(String tenantId, List<Property> properties) {
    for (final property in properties) {
      if (property.tenantIds.contains(tenantId)) return property;
    }
    return null;
  }

  String _formatProperty(Property property) {
    final street = property.address.street.trim();
    final city = property.address.city.trim();
    if (street.isNotEmpty && city.isNotEmpty) return '$street, $city';
    if (street.isNotEmpty) return street;
    if (city.isNotEmpty) return city;
    return 'Property';
  }
}

class _SelectPropertyDialog extends StatelessWidget {
  const _SelectPropertyDialog({required this.properties});

  final List<Property> properties;

  String _propertyLabel(Property property) {
    final street = property.address.street.trim();
    if (street.isNotEmpty) return street;

    final city = property.address.city.trim();
    final postal = property.address.postalCode.trim();
    if (city.isNotEmpty && postal.isNotEmpty) return '$city, $postal';
    if (city.isNotEmpty) return city;
    return property.id;
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return SimpleDialog(
      title: Text(l10n.pleaseSelectProperty),
      children: [
        for (final p in properties)
          SimpleDialogOption(
            onPressed: () => Navigator.of(context).pop(p.id),
            child: Text(_propertyLabel(p)),
          ),
      ],
    );
  }
}

class _TenantView {
  _TenantView({
    required this.name,
    required this.email,
    required this.property,
    required this.status,
    required this.id,
    this.avatarUrl,
  });

  final String name;
  final String email;
  final String property;
  final String status;
  final String id;
  final String? avatarUrl;
}

class _Header extends StatelessWidget {
  const _Header({required this.title, required this.onBack});

  final String title;
  final VoidCallback onBack;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        IconButton(
          onPressed: onBack,
          icon: const Icon(Icons.chevron_left, color: Colors.white70, size: 32),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            title,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 24,
              fontWeight: FontWeight.w800,
              letterSpacing: -0.2,
            ),
          ),
        ),
      ],
    );
  }
}

class _SearchBar extends StatelessWidget {
  const _SearchBar({
    required this.controller,
    required this.onChanged,
    required this.hint,
  });

  final TextEditingController controller;
  final ValueChanged<String> onChanged;
  final String hint;

  @override
  Widget build(BuildContext context) {
    final border = OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: BorderSide.none,
    );

    return TextField(
      controller: controller,
      onChanged: onChanged,
      style: const TextStyle(color: Colors.white),
      cursorColor: Colors.white,
      decoration: InputDecoration(
        filled: true,
        fillColor: const Color(0xFF1C1C1E),
        hintText: hint,
        hintStyle: TextStyle(color: Colors.white.withValues(alpha: 0.65)),
        prefixIcon: const Icon(Icons.search, color: Colors.grey),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
        border: border,
        enabledBorder: border,
        focusedBorder: border,
      ),
    );
  }
}

class _Filters extends StatelessWidget {
  const _Filters({required this.active, required this.onChanged});

  final String active;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    final options = ['All', 'Active', 'Inactive'];
    return Wrap(
      spacing: 10,
      children: options.map((opt) {
        final selected = opt == active;
        return FilterChip(
          selected: selected,
          onSelected: (_) => onChanged(opt),
          label: Text(opt,
              style:
                  TextStyle(color: selected ? Colors.white : Colors.white70)),
          backgroundColor: const Color(0xFF1C1C1E),
          selectedColor: const Color(0xFF38BDF8),
          checkmarkColor: Colors.white,
          side: BorderSide(
              color: Colors.white.withValues(alpha: selected ? 0.0 : 0.08)),
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        );
      }).toList(),
    );
  }
}

class _StatsGrid extends StatelessWidget {
  const _StatsGrid({required this.totalTenants, required this.occupiedUnits});

  final int totalTenants;
  final int occupiedUnits;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: _StatCard(
            icon: Icons.people,
            iconColor: const Color(0xFF38BDF8),
            label: 'Total Tenants',
            value: totalTenants.toString(),
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: _StatCard(
            icon: Icons.home_rounded,
            iconColor: const Color(0xFF22C55E),
            label: 'Occupied Units',
            value: occupiedUnits.toString(),
          ),
        ),
      ],
    );
  }
}

class _StatCard extends StatelessWidget {
  const _StatCard({
    required this.icon,
    required this.iconColor,
    required this.label,
    required this.value,
  });

  final IconData icon;
  final Color iconColor;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return _BentoCard(
      padding: const EdgeInsets.all(12),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: iconColor.withValues(alpha: 0.16),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: iconColor, size: 28),
          ),
          const SizedBox(height: 10),
          Text(
            label,
            style: const TextStyle(
                color: Colors.white70, fontWeight: FontWeight.w600),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 6),
          Text(
            value,
            style: const TextStyle(
                color: Colors.white, fontSize: 18, fontWeight: FontWeight.w800),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}

class _TenantCard extends StatelessWidget {
  const _TenantCard({required this.tenant});

  final _TenantView tenant;

  @override
  Widget build(BuildContext context) {
    final statusColor = tenant.status == 'Active'
        ? const Color(0xFF22C55E)
        : const Color(0xFFEF4444);
    final statusBg = tenant.status == 'Active'
        ? const Color(0xFF22C55E).withValues(alpha: 0.12)
        : const Color(0xFFEF4444).withValues(alpha: 0.12);
    return _BentoCard(
      padding: const EdgeInsets.all(14),
      child: Row(
        children: [
          _Avatar(name: tenant.name, imageUrl: tenant.avatarUrl),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  tenant.name,
                  style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w800,
                      fontSize: 15),
                ),
                const SizedBox(height: 4),
                Text(
                  tenant.email,
                  style: const TextStyle(color: Colors.white70, fontSize: 12),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 6),
                Row(
                  children: [
                    Flexible(
                      child: Text(
                        'Assigned: ${tenant.property}',
                        style: const TextStyle(
                          color: Color(0xFF38BDF8),
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
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
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: statusBg,
              borderRadius: BorderRadius.circular(999),
              border: Border.all(color: statusColor.withValues(alpha: 0.5)),
            ),
            child: Text(
              tenant.status,
              style: TextStyle(
                  color: statusColor,
                  fontWeight: FontWeight.w800,
                  fontSize: 12),
            ),
          ),
        ],
      ),
    );
  }
}

class _Avatar extends StatelessWidget {
  const _Avatar({required this.name, this.imageUrl});

  final String name;
  final String? imageUrl;

  @override
  Widget build(BuildContext context) {
    final ref = (imageUrl ?? '').trim();
    final imageRef = ref.isEmpty ? null : ref;
    return Container(
      width: 44,
      height: 44,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: Colors.blue.withValues(alpha: 0.20),
        border:
            Border.all(color: Colors.white.withValues(alpha: 0.14), width: 1),
      ),
      child: ClipOval(
        child: UserAvatar(
          imageRef: imageRef,
          name: name,
          size: 44,
          bgColor: Colors.transparent,
          textColor: Colors.white,
          fallbackToCurrentUser: false,
        ),
      ),
    );
  }
}

class _AddTenantFab extends StatelessWidget {
  const _AddTenantFab({required this.label, required this.onTap});

  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        gradient: const LinearGradient(
          colors: [Color(0xFF38BDF8), Color(0xFF4F46E5)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        boxShadow: const [
          BoxShadow(
              color: Colors.black45, blurRadius: 16, offset: Offset(0, 8)),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.add, color: Colors.white),
                const SizedBox(width: 8),
                Text(
                  label,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _BentoCard extends StatelessWidget {
  const _BentoCard({required this.child, this.padding});

  final Widget child;
  final EdgeInsets? padding;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: padding ?? const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFF1C1C1E),
        borderRadius: BorderRadius.circular(16),
        border:
            Border.all(color: Colors.white.withValues(alpha: 0.12), width: 1),
        boxShadow: const [
          BoxShadow(
              color: Colors.black45, blurRadius: 18, offset: Offset(0, 12)),
        ],
      ),
      child: child,
    );
  }
}

class _DeepNavyBackground extends StatelessWidget {
  const _DeepNavyBackground();

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [Color(0xFF0B1224), Color(0xFF0F172A)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
        ),
        Positioned(
          top: -80,
          left: -40,
          child: _GlowCircle(
              color: const Color(0xFF38BDF8).withValues(alpha: 0.3)),
        ),
        Positioned(
          bottom: -60,
          right: -20,
          child: _GlowCircle(
              color: const Color(0xFF4F46E5).withValues(alpha: 0.25)),
        ),
      ],
    );
  }
}

class _GlowCircle extends StatelessWidget {
  const _GlowCircle({required this.color});

  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 220,
      height: 220,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: RadialGradient(
          colors: [color, color.withValues(alpha: 0.0)],
          stops: const [0.0, 1.0],
        ),
      ),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 120, sigmaY: 120),
        child: const SizedBox.expand(),
      ),
    );
  }
}

class _LoadingState extends StatelessWidget {
  const _LoadingState();

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: CircularProgressIndicator(color: Color(0xFF38BDF8)),
    );
  }
}

class _ErrorState extends StatelessWidget {
  const _ErrorState({
    required this.title,
    required this.retryLabel,
    required this.onRetry,
  });

  final String title;
  final String retryLabel;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.error_outline, color: Colors.white70, size: 48),
          const SizedBox(height: 12),
          Text(
            title,
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 8),
          TextButton(
            onPressed: onRetry,
            child: Text(
              retryLabel,
              style: const TextStyle(color: Color(0xFF38BDF8)),
            ),
          )
        ],
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Text(
        text,
        style:
            const TextStyle(color: Colors.white70, fontWeight: FontWeight.w700),
      ),
    );
  }
}
