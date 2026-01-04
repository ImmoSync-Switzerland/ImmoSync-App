import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geocoding/geocoding.dart';

import 'package:immosync/core/providers/currency_provider.dart';
import 'package:immosync/core/providers/dynamic_colors_provider.dart';
import 'package:immosync/core/utils/image_resolver.dart';
import 'package:immosync/core/widgets/mongo_image.dart';
import 'package:immosync/features/auth/presentation/providers/auth_provider.dart';
import 'package:immosync/features/property/domain/models/property.dart';
import 'package:immosync/features/property/presentation/providers/property_providers.dart';
import 'package:immosync/features/property/presentation/widgets/email_invite_tenant_dialog.dart';
import 'package:immosync/l10n/app_localizations.dart';

class PropertyDetailsPage extends ConsumerWidget {
  const PropertyDetailsPage({super.key, required this.propertyId});

  final String propertyId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final propertyAsync = ref.watch(propertyProvider(propertyId));
    final colors = ref.watch(dynamicColorsProvider);
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      extendBody: true,
      backgroundColor: Colors.transparent,
      body: Stack(
        children: [
          const _BentoBackground(),
          propertyAsync.when(
            data: (property) =>
                _buildDarkBentoPage(context, ref, property, colors, l10n),
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (_, __) => Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Text(
                  l10n.somethingWentWrong,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w700,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDarkBentoPage(
    BuildContext context,
    WidgetRef ref,
    Property property,
    DynamicAppColors colors,
    AppLocalizations l10n,
  ) {
    final actions = <Widget>[];
    final currentUser = ref.watch(currentUserProvider);
    if (currentUser?.role == 'landlord') {
      actions.add(
        IconButton(
          icon: const Icon(Icons.edit, color: Colors.white),
          onPressed: () => context.push('/add-property', extra: property),
        ),
      );
    }

    return Scaffold(
      extendBody: true,
      backgroundColor: Colors.transparent,
      floatingActionButton: _buildContactButton(
        context,
        property,
        ref,
        colors,
        l10n,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 18, 20, 140),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  IconButton(
                    onPressed: () => Navigator.of(context).maybePop(),
                    icon: const Icon(
                      Icons.arrow_back_ios_new_rounded,
                      color: Colors.white,
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    l10n.propertyDetails,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.w800,
                      letterSpacing: -0.2,
                    ),
                  ),
                  const Spacer(),
                  if (actions.isNotEmpty) ...actions,
                ],
              ),
              const SizedBox(height: 18),
              _BentoCard(
                padding: EdgeInsets.zero,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Stack(
                      children: [
                        _HeroImage(imageIds: property.imageUrls),
                        Positioned(
                          top: 12,
                          left: 12,
                          child: _buildStatusChip(
                            context,
                            status: property.status,
                            colors: colors,
                          ),
                        ),
                      ],
                    ),
                    Padding(
                      padding: const EdgeInsets.fromLTRB(16, 16, 16, 18),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            _primaryTitle(property, l10n),
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 22,
                              fontWeight: FontWeight.w800,
                              letterSpacing: -0.3,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            _locationSubtitle(property) ?? '',
                            style: TextStyle(
                              color: Colors.white.withValues(alpha: 0.72),
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(height: 14),
                          Row(
                            children: [
                              Icon(
                                Icons.payments_rounded,
                                color: colors.luxuryGold,
                                size: 20,
                              ),
                              const SizedBox(width: 8),
                              Text(
                                '${ref.read(currencyProvider.notifier).formatAmount(property.rentAmount)}/${l10n.monthlyInterval}',
                                style: TextStyle(
                                  color: colors.luxuryGold,
                                  fontSize: 18,
                                  fontWeight: FontWeight.w800,
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
              const SizedBox(height: 16),
              _KeyFeaturesRow(property: property, l10n: l10n),
              const SizedBox(height: 16),
              _BentoSection(
                title: l10n.description,
                child: Text(
                  _buildDescriptionText(property, l10n),
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.82),
                    fontSize: 14,
                    height: 1.5,
                  ),
                ),
              ),
              if (property.details.amenities.isNotEmpty) ...[
                const SizedBox(height: 16),
                _BentoSection(
                  title: l10n.amenities,
                  child: Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: property.details.amenities
                        .map(
                          (a) => Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 8,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.06),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: Colors.white.withValues(alpha: 0.08),
                              ),
                            ),
                            child: Text(
                              a,
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.w700,
                                fontSize: 12,
                              ),
                            ),
                          ),
                        )
                        .toList(),
                  ),
                ),
              ],
              const SizedBox(height: 16),
              _LocationMapSection(
                property: property,
                l10n: l10n,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget? _buildContactButton(
    BuildContext context,
    Property property,
    WidgetRef ref,
    DynamicAppColors colors,
    AppLocalizations l10n,
  ) {
    final currentUser = ref.watch(currentUserProvider);
    final isLandlord = currentUser?.role == 'landlord';

    if (isLandlord && property.status == 'available') {
      return FloatingActionButton.extended(
        onPressed: () => _showInviteTenantDialog(context, property),
        backgroundColor: colors.primaryAccent,
        foregroundColor: colors.textOnAccent,
        icon: const Icon(Icons.person_add),
        label: Text(l10n.inviteTenant),
      );
    }

    return null;
  }

  void _showInviteTenantDialog(BuildContext context, Property property) {
    showDialog(
      context: context,
      builder: (ctx) => EmailInviteTenantDialog(propertyId: property.id),
    );
  }

  Widget _buildStatusChip(
    BuildContext context, {
    required String status,
    required DynamicAppColors colors,
  }) {
    final statusColor = _getStatusColor(status, colors);
    final label = _getStatusText(context, status);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: statusColor.withValues(alpha: 0.18),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: statusColor.withValues(alpha: 0.35)),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: colors.textOnAccent,
          fontSize: 12,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  Color _getStatusColor(String status, DynamicAppColors colors) {
    switch (status.toLowerCase()) {
      case 'available':
        return colors.success;
      case 'rented':
        return colors.info;
      case 'maintenance':
        return colors.warning;
      default:
        return colors.textTertiary;
    }
  }

  String _getStatusText(BuildContext context, String status) {
    switch (status.toLowerCase()) {
      case 'available':
        return AppLocalizations.of(context)!.available;
      case 'rented':
        return AppLocalizations.of(context)!.occupied;
      case 'maintenance':
        return AppLocalizations.of(context)!.maintenance;
      default:
        return status;
    }
  }

  String _primaryTitle(Property property, AppLocalizations l10n) {
    final street = property.address.street.trim();
    if (street.isNotEmpty) {
      return street;
    }

    final city = property.address.city.trim();
    final postal = property.address.postalCode.trim();
    if (city.isNotEmpty && postal.isNotEmpty) {
      return '$city, $postal';
    }
    if (city.isNotEmpty) {
      return city;
    }
    if (postal.isNotEmpty) {
      return postal;
    }
    return l10n.propertyDetails;
  }

  String? _locationSubtitle(Property property) {
    final city = property.address.city.trim();
    final postal = property.address.postalCode.trim();
    if (city.isEmpty && postal.isEmpty) {
      return null;
    }
    if (city.isNotEmpty && postal.isNotEmpty) {
      return '$city, $postal';
    }
    if (city.isNotEmpty) {
      return city;
    }
    return postal;
  }

  String _buildDescriptionText(Property property, AppLocalizations l10n) {
    final city = property.address.city.trim();
    final rooms = property.details.rooms;
    final size = property.details.size;

    if (city.isEmpty && rooms == 0 && size == 0) {
      return l10n.description;
    }

    final roomPart = rooms > 0 ? '$rooms ${l10n.rooms.toLowerCase()}' : '';
    final sizePart = size > 0 ? '${size.toStringAsFixed(0)} m²' : '';
    final cityPart = city.isNotEmpty ? city : l10n.location;

    final pieces = [roomPart, sizePart].where((p) => p.isNotEmpty).join(' · ');
    final detailsText = pieces.isNotEmpty ? pieces : l10n.description;
    return '$detailsText in $cityPart';
  }
}

class _HeroImage extends StatelessWidget {
  const _HeroImage({required this.imageIds});

  final List<String> imageIds;

  @override
  Widget build(BuildContext context) {
    final hasImage = imageIds.isNotEmpty && imageIds.first.isNotEmpty;
    final resolved = hasImage ? resolvePropertyImage(imageIds.first) : '';

    return ClipRRect(
      borderRadius: BorderRadius.circular(18),
      child: SizedBox(
        height: 220,
        width: double.infinity,
        child: Stack(
          fit: StackFit.expand,
          children: [
            resolved.isEmpty
                ? Container(color: const Color(0xFF111118))
                : MongoImage(
                    imageId: resolved,
                    fit: BoxFit.cover,
                    loadingWidget: Container(
                      color: const Color(0xFF111118),
                      alignment: Alignment.center,
                      child: const CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white70,
                      ),
                    ),
                    errorWidget: Container(
                      color: const Color(0xFF111118),
                      alignment: Alignment.center,
                      child: const Icon(
                        Icons.home_rounded,
                        color: Colors.white54,
                        size: 32,
                      ),
                    ),
                  ),
            Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.black.withValues(alpha: 0.45),
                    Colors.black.withValues(alpha: 0.18),
                    Colors.black.withValues(alpha: 0.55),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _KeyFeaturesRow extends StatelessWidget {
  const _KeyFeaturesRow({required this.property, required this.l10n});

  final Property property;
  final AppLocalizations l10n;

  @override
  Widget build(BuildContext context) {
    final items = [
      (
        icon: Icons.meeting_room_rounded,
        label: l10n.rooms,
        value: property.details.rooms > 0
            ? property.details.rooms.toString()
            : '-',
      ),
      (
        icon: Icons.square_foot_rounded,
        label: l10n.size,
        value: property.details.size > 0
            ? '${property.details.size.toStringAsFixed(0)} m²'
            : '-',
      ),
      (
        icon: Icons.verified_rounded,
        label: l10n.status,
        value: property.status.isNotEmpty ? property.status : '-',
      ),
    ];

    return Row(
      children: [
        for (var i = 0; i < items.length; i++) ...[
          Expanded(
            child: _FeatureCard(
              icon: items[i].icon,
              label: items[i].label,
              value: items[i].value,
            ),
          ),
          if (i != items.length - 1) const SizedBox(width: 12),
        ],
      ],
    );
  }
}

class _FeatureCard extends StatelessWidget {
  const _FeatureCard({
    required this.icon,
    required this.label,
    required this.value,
  });

  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return _BentoCard(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Icon(icon, color: Colors.white, size: 24),
          const SizedBox(height: 10),
          Text(
            label,
            style: const TextStyle(
              color: Colors.white70,
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            value,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }
}

class _BentoSection extends StatelessWidget {
  const _BentoSection({required this.title, required this.child});

  final String title;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return _BentoCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 12),
          child,
        ],
      ),
    );
  }
}

class _BentoCard extends StatelessWidget {
  const _BentoCard(
      {required this.child, this.padding = const EdgeInsets.all(16)});

  final Widget child;
  final EdgeInsets padding;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color(0xFF1A2234),
            Color(0xFF131828),
          ],
        ),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.28),
            blurRadius: 24,
            offset: const Offset(0, 16),
          ),
        ],
      ),
      child: Padding(padding: padding, child: child),
    );
  }
}

class _LocationMapSection extends StatelessWidget {
  const _LocationMapSection({
    required this.property,
    required this.l10n,
  });

  final Property property;
  final AppLocalizations l10n;

  static const LatLng _defaultLatLng =
      LatLng(47.3769, 8.5417); // Zurich fallback

  @override
  Widget build(BuildContext context) {
    final locationFuture = _resolveLocation();
    final addressText = _addressLine(property, l10n);

    return _BentoSection(
      title: l10n.location,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(14),
            child: SizedBox(
              height: 250,
              child: FutureBuilder<LatLng?>(
                future: locationFuture,
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(
                      child: CircularProgressIndicator(strokeWidth: 2),
                    );
                  }

                  final latLng = snapshot.data ?? _defaultLatLng;
                  return GoogleMap(
                    initialCameraPosition: CameraPosition(
                      target: latLng,
                      zoom: 14,
                    ),
                    zoomControlsEnabled: false,
                    myLocationButtonEnabled: false,
                    markers: {
                      Marker(
                        markerId: const MarkerId('property'),
                        position: latLng,
                      ),
                    },
                  );
                },
              ),
            ),
          ),
          const SizedBox(height: 12),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Icon(
                Icons.place_rounded,
                color: Colors.white,
                size: 18,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  addressText,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  String _addressLine(Property property, AppLocalizations l10n) {
    final street = property.address.street.trim();
    final city = property.address.city.trim();
    final postal = property.address.postalCode.trim();

    if (street.isEmpty && city.isEmpty && postal.isEmpty) {
      return l10n.location;
    }

    final cityPostal = [city, postal].where((p) => p.isNotEmpty).join(' ');
    return [street, cityPostal].where((p) => p.isNotEmpty).join(', ');
  }

  Future<LatLng?> _resolveLocation() async {
    final address = property.address;
    final parts = [
      address.street.trim(),
      address.postalCode.trim(),
      address.city.trim(),
      address.country.trim(),
    ].where((p) => p.isNotEmpty).join(', ');

    if (parts.isEmpty) return null;

    try {
      final locations = await locationFromAddress(parts);
      if (locations.isNotEmpty) {
        final loc = locations.first;
        return LatLng(loc.latitude, loc.longitude);
      }
    } catch (e) {
      debugPrint('[PropertyDetails] Geocoding failed for "$parts": $e');
    }

    return null;
  }
}

class _BentoBackground extends StatelessWidget {
  const _BentoBackground();

  @override
  Widget build(BuildContext context) {
    return const Stack(
      fit: StackFit.expand,
      children: [
        DecoratedBox(
          decoration: BoxDecoration(color: Color(0xFF0B1220)),
        ),
        _GlowOrb(
          color: Color(0xFF0EA5E9),
          size: 320,
          alignment: Alignment(-0.8, -0.6),
          opacity: 0.18,
        ),
        _GlowOrb(
          color: Color(0xFF6366F1),
          size: 360,
          alignment: Alignment(0.9, -0.4),
          opacity: 0.16,
        ),
        _GlowOrb(
          color: Color(0xFFFFA94D),
          size: 400,
          alignment: Alignment(-0.6, 0.9),
          opacity: 0.12,
        ),
      ],
    );
  }
}

class _GlowOrb extends StatelessWidget {
  const _GlowOrb({
    required this.color,
    required this.size,
    required this.alignment,
    this.opacity = 0.14,
  });

  final Color color;
  final double size;
  final Alignment alignment;
  final double opacity;

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: alignment,
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: RadialGradient(
            colors: [
              color.withValues(alpha: opacity),
              color.withValues(alpha: 0.02),
              Colors.transparent,
            ],
            stops: const [0, 0.45, 1],
          ),
        ),
      ),
    );
  }
}
