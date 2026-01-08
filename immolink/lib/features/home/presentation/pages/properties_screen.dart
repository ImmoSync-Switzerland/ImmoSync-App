import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:immosync/core/providers/navigation_provider.dart';
import 'package:immosync/core/utils/image_resolver.dart';
import 'package:immosync/core/widgets/glass_nav_bar.dart';
import 'package:immosync/core/widgets/mongo_image.dart';
import 'package:immosync/features/auth/presentation/providers/user_role_provider.dart';
import 'package:immosync/features/property/domain/models/property.dart';
import 'package:immosync/features/property/presentation/providers/property_providers.dart';
import 'package:immosync/l10n/app_localizations.dart';

enum _PropertyStatusFilter { all, occupied, vacant, maintenance }

/// Properties page styled in the same Dark Bento system used on the dashboard.
class PropertiesScreen extends ConsumerStatefulWidget {
  const PropertiesScreen({super.key});

  @override
  ConsumerState<PropertiesScreen> createState() => _PropertiesScreenState();
}

class _PropertiesScreenState extends ConsumerState<PropertiesScreen> {
  String _searchQuery = '';
  _PropertyStatusFilter _statusFilter = _PropertyStatusFilter.all;

  void _openSearchSheet(AppLocalizations l10n) {
    final controller = TextEditingController(text: _searchQuery);

    showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (sheetContext) {
        final bottomInset = MediaQuery.of(sheetContext).viewInsets.bottom;

        void updateQuery() {
          final next = controller.text.trim();
          if (!mounted) return;
          setState(() => _searchQuery = next);
        }

        return Padding(
          padding: EdgeInsets.only(left: 12, right: 12, bottom: bottomInset),
          child: _BentoSheet(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  l10n.searchProperties,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w900,
                    fontSize: 14,
                    letterSpacing: -0.1,
                  ),
                ),
                const SizedBox(height: 10),
                TextField(
                  controller: controller,
                  autofocus: true,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w700,
                  ),
                  textInputAction: TextInputAction.search,
                  decoration: InputDecoration(
                    hintText: l10n.searchProperties,
                    hintStyle: const TextStyle(
                      color: Colors.white54,
                      fontWeight: FontWeight.w600,
                    ),
                    prefixIcon: const Icon(
                      Icons.search_rounded,
                      color: Colors.white70,
                    ),
                    suffixIcon: controller.text.trim().isEmpty
                        ? null
                        : IconButton(
                            onPressed: () {
                              controller.clear();
                              updateQuery();
                            },
                            icon: const Icon(
                              Icons.close_rounded,
                              color: Colors.white70,
                            ),
                            tooltip: l10n.close,
                          ),
                    filled: true,
                    fillColor: Colors.white.withValues(alpha: 0.06),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),
                      borderSide: BorderSide.none,
                    ),
                  ),
                  onChanged: (_) => updateQuery(),
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    Text(
                      l10n.filter,
                      style: const TextStyle(
                        color: Colors.white70,
                        fontWeight: FontWeight.w700,
                        fontSize: 12,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        _filterLabel(l10n, _statusFilter),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        textAlign: TextAlign.right,
                        style: const TextStyle(
                          color: Colors.white54,
                          fontWeight: FontWeight.w700,
                          fontSize: 12,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _openFilterSheet(AppLocalizations l10n) {
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) {
        final options = <_PropertyStatusFilter>[
          _PropertyStatusFilter.all,
          _PropertyStatusFilter.occupied,
          _PropertyStatusFilter.vacant,
          _PropertyStatusFilter.maintenance,
        ];

        return Padding(
          padding: const EdgeInsets.fromLTRB(12, 0, 12, 0),
          child: _BentoSheet(
            child: SafeArea(
              top: false,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    l10n.filter,
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w900,
                      fontSize: 14,
                      letterSpacing: -0.1,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Flexible(
                    child: ListView.separated(
                      shrinkWrap: true,
                      itemCount: options.length,
                      separatorBuilder: (_, __) => Divider(
                        height: 1,
                        color: Colors.white.withValues(alpha: 0.06),
                      ),
                      itemBuilder: (context, index) {
                        final value = options[index];
                        final label = _filterLabel(l10n, value);
                        return ListTile(
                          contentPadding: EdgeInsets.zero,
                          title: Text(
                            label,
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w800,
                              fontSize: 13,
                            ),
                          ),
                          trailing: value == _statusFilter
                              ? const Icon(
                                  Icons.check_rounded,
                                  color: Colors.white,
                                )
                              : null,
                          onTap: () {
                            if (!mounted) return;
                            setState(() => _statusFilter = value);
                            Navigator.of(sheetContext).pop();
                          },
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final userRole = ref.watch(userRoleProvider);
    final propertiesAsync = userRole == 'tenant'
        ? ref.watch(tenantPropertiesProvider)
        : ref.watch(landlordPropertiesProvider);
    final showAddProperty = userRole == 'landlord';

    // Keep bottom nav in sync with the current tab
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(routeAwareNavigationProvider.notifier).setIndex(1);
    });

    return Scaffold(
      extendBody: true,
      backgroundColor: Colors.transparent,
      floatingActionButton: showAddProperty ? const _AddPropertyFab() : null,
      bottomNavigationBar: const AppGlassNavBar(),
      body: Stack(
        children: [
          const _BentoBackground(),
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _HeaderBar(
                    onSearch: () => _openSearchSheet(l10n),
                    onFilter: () => _openFilterSheet(l10n),
                  ),
                  const SizedBox(height: 20),
                  Expanded(
                    child: propertiesAsync.when(
                      loading: () => const _LoadingList(),
                      error: (err, _) => _ErrorState(message: err.toString()),
                      data: (items) {
                        final normalizedQuery = _searchQuery.toLowerCase();
                        final filtered = items.where((item) {
                          if (normalizedQuery.isNotEmpty) {
                            final haystack = <String?>[
                              item.address.street,
                              item.address.city,
                              item.address.postalCode,
                              item.address.country,
                              item.id,
                            ].whereType<String>().join(' ').toLowerCase();
                            if (!haystack.contains(normalizedQuery)) {
                              return false;
                            }
                          }

                          final statusLower = item.status.toLowerCase();
                          switch (_statusFilter) {
                            case _PropertyStatusFilter.all:
                              return true;
                            case _PropertyStatusFilter.occupied:
                              return item.tenantIds.isNotEmpty;
                            case _PropertyStatusFilter.vacant:
                              return item.tenantIds.isEmpty ||
                                  statusLower.contains('vacant') ||
                                  statusLower.contains('available');
                            case _PropertyStatusFilter.maintenance:
                              return statusLower.contains('maint');
                          }
                        }).toList();

                        if (items.isEmpty || filtered.isEmpty) {
                          return _EmptyState(isTenant: userRole == 'tenant');
                        }

                        return ListView.builder(
                          padding: const EdgeInsets.only(bottom: 120),
                          itemCount: filtered.length,
                          itemBuilder: (context, index) {
                            final item = filtered[index];
                            return Padding(
                              padding: const EdgeInsets.only(bottom: 16),
                              child: _PropertyCard(item: item),
                            );
                          },
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _HeaderBar extends StatelessWidget {
  const _HeaderBar({required this.onSearch, required this.onFilter});

  final VoidCallback onSearch;
  final VoidCallback onFilter;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Row(
      children: [
        Text(
          l10n.propertyOverview,
          style: GoogleFonts.inter(
            color: Colors.white,
            fontSize: 22,
            fontWeight: FontWeight.w800,
            letterSpacing: -0.1,
          ),
        ),
        const Spacer(),
        _CircleIconButton(
          icon: Icons.search_rounded,
          onTap: onSearch,
        ),
        const SizedBox(width: 10),
        _CircleIconButton(
          icon: Icons.tune_rounded,
          onTap: onFilter,
        ),
      ],
    );
  }
}

class _PropertyCard extends StatelessWidget {
  const _PropertyCard({required this.item});

  final Property item;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final statusLabel = _statusLabelFor(item, l10n);
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(18),
        onTap: () => context.push('/property/${item.id}'),
        child: _BentoCard(
          padding: const EdgeInsets.all(14),
          child: Row(
            children: [
              _PropertyImage(imageIds: item.imageUrls),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      item.address.street.isNotEmpty
                          ? item.address.street
                          : l10n.unknownProperty,
                      style: GoogleFonts.inter(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 6),
                    Text(
                      '${item.address.postalCode} ${item.address.city}',
                      style: GoogleFonts.inter(
                        color: Colors.white.withValues(alpha: 0.72),
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              if (statusLabel.isNotEmpty)
                _StatusPill(
                  label: statusLabel,
                  color: _statusColor(item.status),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _PropertyImage extends StatelessWidget {
  const _PropertyImage({required this.imageIds});

  final List<String> imageIds;

  @override
  Widget build(BuildContext context) {
    final hasImage = imageIds.isNotEmpty && imageIds.first.isNotEmpty;
    final resolved = hasImage ? resolvePropertyImage(imageIds.first) : '';

    final Widget content = resolved.isEmpty
        ? _placeholder()
        : MongoImage(
            imageId: resolved,
            width: 64,
            height: 64,
            fit: BoxFit.cover,
            errorWidget: _placeholder(),
            loadingWidget: _loading(),
          );

    return ClipRRect(
      borderRadius: BorderRadius.circular(14),
      child: SizedBox(width: 64, height: 64, child: content),
    );
  }

  Widget _placeholder() {
    return Container(
      color: const Color(0xFF1F2937),
      child: const Icon(Icons.home_rounded, color: Colors.white54, size: 24),
    );
  }

  Widget _loading() {
    return Container(
      color: const Color(0xFF1F2937),
      alignment: Alignment.center,
      child: const SizedBox(
        width: 16,
        height: 16,
        child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white70),
      ),
    );
  }
}

class _StatusPill extends StatelessWidget {
  const _StatusPill({required this.label, required this.color});

  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: const BoxConstraints(minHeight: 26),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            color.withValues(alpha: 0.9),
            color.withValues(alpha: 0.65),
          ],
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
        boxShadow: [
          BoxShadow(
            color: color.withValues(alpha: 0.28),
            blurRadius: 16,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Text(
        label,
        style: GoogleFonts.inter(
          color: Colors.white,
          fontWeight: FontWeight.w700,
          fontSize: 12,
          letterSpacing: 0.1,
        ),
      ),
    );
  }
}

class _BentoCard extends StatelessWidget {
  const _BentoCard({required this.child, this.padding});

  final Widget child;
  final EdgeInsetsGeometry? padding;

  @override
  Widget build(BuildContext context) {
    const radius = 18.0;
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(radius),
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color(0xFF1A1A1F),
            Color(0xFF111118),
          ],
        ),
        border: Border.all(color: Colors.white.withValues(alpha: 0.06)),
        boxShadow: const [
          BoxShadow(
            color: Color(0x22000000),
            blurRadius: 18,
            offset: Offset(0, 10),
          ),
        ],
      ),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(radius - 2),
          gradient: const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Color(0x3318181E),
              Color(0x191C1C22),
            ],
          ),
        ),
        child: Padding(
          padding: padding ?? const EdgeInsets.all(16),
          child: child,
        ),
      ),
    );
  }
}

class _AddPropertyFab extends StatelessWidget {
  const _AddPropertyFab();

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 18, right: 6),
      decoration: const BoxDecoration(
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color: Color(0x552B8CFF),
            blurRadius: 22,
            spreadRadius: 2,
            offset: Offset(0, 10),
          ),
        ],
        gradient: LinearGradient(
          colors: [Color(0xFF3B82F6), Color(0xFF2563EB)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: FloatingActionButton(
        elevation: 0,
        backgroundColor: Colors.transparent,
        onPressed: () => context.push('/add-property'),
        child: const Icon(Icons.add_rounded, size: 28, color: Colors.white),
      ),
    );
  }
}

class _CircleIconButton extends StatelessWidget {
  const _CircleIconButton({required this.icon, required this.onTap});

  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white.withValues(alpha: 0.06),
      shape: const CircleBorder(),
      child: InkWell(
        customBorder: const CircleBorder(),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(10),
          child: Icon(icon, color: Colors.white, size: 20),
        ),
      ),
    );
  }
}

Color _statusColor(String status) {
  final lower = status.toLowerCase();
  if (lower.contains('vacant') || lower.contains('available')) {
    return const Color(0xFFF97316);
  }
  if (lower.contains('maint')) {
    return const Color(0xFFEAB308);
  }
  return const Color(0xFF10B981);
}

String _statusLabelFor(Property property, AppLocalizations l10n) {
  final statusLower = property.status.toLowerCase();
  if (statusLower.contains('maint')) return l10n.maintenance;
  if (statusLower.contains('rented')) return l10n.occupied;
  if (statusLower.contains('available') || statusLower.contains('vacant')) {
    return l10n.vacant;
  }
  if (property.tenantIds.isNotEmpty) return l10n.occupied;
  if (property.tenantIds.isEmpty) return l10n.vacant;

  final raw = property.status.trim();
  if (raw.isEmpty) return '';
  return raw[0].toUpperCase() + raw.substring(1);
}

String _filterLabel(AppLocalizations l10n, _PropertyStatusFilter value) {
  switch (value) {
    case _PropertyStatusFilter.all:
      return l10n.all;
    case _PropertyStatusFilter.occupied:
      return l10n.occupied;
    case _PropertyStatusFilter.vacant:
      return l10n.vacant;
    case _PropertyStatusFilter.maintenance:
      return l10n.maintenance;
  }
}

class _BentoSheet extends StatelessWidget {
  const _BentoSheet({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color(0xFF1A1A1F),
            Color(0xFF111118),
          ],
        ),
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.08),
          width: 1,
        ),
        boxShadow: const [
          BoxShadow(
            color: Color(0x22000000),
            blurRadius: 18,
            offset: Offset(0, 10),
          ),
        ],
      ),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: const BorderRadius.vertical(top: Radius.circular(18)),
          gradient: const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Color(0x3318181E),
              Color(0x191C1C22),
            ],
          ),
        ),
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 18),
        child: child,
      ),
    );
  }
}

class _LoadingList extends StatelessWidget {
  const _LoadingList();

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      padding: const EdgeInsets.only(bottom: 120),
      itemCount: 4,
      itemBuilder: (_, __) => const Padding(
        padding: EdgeInsets.only(bottom: 16),
        child: _SkeletonCard(),
      ),
    );
  }
}

class _SkeletonCard extends StatelessWidget {
  const _SkeletonCard();

  @override
  Widget build(BuildContext context) {
    return _BentoCard(
      padding: const EdgeInsets.all(14),
      child: Row(
        children: [
          Container(
            width: 64,
            height: 64,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.06),
              borderRadius: BorderRadius.circular(14),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _skeletonLine(width: 180),
                const SizedBox(height: 8),
                _skeletonLine(width: 120),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _skeletonLine({required double width}) {
    return Container(
      width: width,
      height: 12,
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(8),
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState({required this.isTenant});

  final bool isTenant;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.home_work_outlined, color: Colors.white54, size: 40),
          const SizedBox(height: 12),
          Text(
            isTenant ? l10n.noPropertiesAssigned : l10n.noPropertiesFound,
            style: GoogleFonts.inter(
              color: Colors.white,
              fontSize: 15,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            isTenant ? l10n.contactLandlordForAccess : l10n.addFirstProperty,
            style: GoogleFonts.inter(
              color: Colors.white70,
              fontSize: 13,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

class _ErrorState extends StatelessWidget {
  const _ErrorState({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.error_outline, color: Colors.orangeAccent, size: 40),
          const SizedBox(height: 10),
          Text(
            l10n.somethingWentWrong,
            style: GoogleFonts.inter(
              color: Colors.white,
              fontSize: 15,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            message,
            style: GoogleFonts.inter(
              color: Colors.white70,
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}

class _BentoBackground extends StatelessWidget {
  const _BentoBackground();

  @override
  Widget build(BuildContext context) {
    return const Positioned.fill(
      child: DecoratedBox(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Color(0xFF0A1128),
              Color(0xFF050505),
            ],
          ),
        ),
        child: Stack(
          children: [
            _GlowOrb(
              color: Color(0x3310B981),
              size: 420,
              offset: Offset(-80, -60),
              blur: 120,
            ),
            _GlowOrb(
              color: Color(0x333B82F6),
              size: 480,
              offset: Offset(-50, 420),
              blur: 140,
            ),
            _GlowOrb(
              color: Color(0x332E1065),
              size: 360,
              offset: Offset(200, 520),
              blur: 120,
            ),
          ],
        ),
      ),
    );
  }
}

class _GlowOrb extends StatelessWidget {
  const _GlowOrb({
    required this.color,
    required this.size,
    required this.offset,
    required this.blur,
  });

  final Color color;
  final double size;
  final Offset offset;
  final double blur;

  @override
  Widget build(BuildContext context) {
    return Positioned(
      left: offset.dx,
      top: offset.dy,
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: color,
              blurRadius: blur,
              spreadRadius: blur * 0.25,
            ),
          ],
        ),
      ),
    );
  }
}
