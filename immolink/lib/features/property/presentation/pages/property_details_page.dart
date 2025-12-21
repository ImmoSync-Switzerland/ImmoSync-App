import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geocoding/geocoding.dart';
import 'package:go_router/go_router.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:http/http.dart' as http;
import 'package:url_launcher/url_launcher.dart';

import 'package:immosync/core/providers/currency_provider.dart';
import 'package:immosync/core/providers/dynamic_colors_provider.dart';
import 'package:immosync/core/theme/app_spacing.dart';
import 'package:immosync/core/utils/image_resolver.dart';
import 'package:immosync/core/widgets/mongo_image.dart';
import 'package:immosync/features/auth/presentation/providers/auth_provider.dart';
import 'package:immosync/features/home/presentation/models/dashboard_design.dart';
import 'package:immosync/features/home/presentation/pages/glass_dashboard_shared.dart';
import 'package:immosync/features/property/domain/models/property.dart';
import 'package:immosync/features/property/presentation/providers/property_providers.dart';
import 'package:immosync/features/property/presentation/widgets/email_invite_tenant_dialog.dart';
import 'package:immosync/features/settings/providers/settings_provider.dart';
import 'package:immosync/l10n/app_localizations.dart';

class PropertyDetailsPage extends ConsumerWidget {
  const PropertyDetailsPage({required this.propertyId, super.key});

  final String propertyId;

  String _getImageUrl(String imageIdOrPath) =>
      resolvePropertyImage(imageIdOrPath);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final colors = ref.watch(dynamicColorsProvider);
    final design =
        dashboardDesignFromId(ref.watch(settingsProvider).dashboardDesign);
    final glassMode = design == DashboardDesign.glass;
    final propertyAsync = ref.watch(propertyProvider(propertyId));

    return propertyAsync.when(
      data: (property) {
        return glassMode
            ? _buildGlassPage(context, ref, property, colors, l10n)
            : _buildClassicPage(context, ref, property, colors, l10n);
      },
      loading: () => glassMode
          ? GlassPageScaffold(
              title: l10n.propertyDetails,
              showBottomNav: false,
              body: Center(
                child: CircularProgressIndicator(
                  valueColor: AlwaysStoppedAnimation<Color>(
                    colors.primaryAccent,
                  ),
                ),
              ),
            )
          : Scaffold(
              backgroundColor: colors.primaryBackground,
              body: Center(
                child: CircularProgressIndicator(
                  valueColor: AlwaysStoppedAnimation<Color>(
                    colors.primaryAccent,
                  ),
                ),
              ),
            ),
      error: (error, stack) {
        final errorBody = _buildErrorState(context, colors, l10n, error,
            glassMode: glassMode);
        return glassMode
            ? GlassPageScaffold(
                title: l10n.propertyDetails,
                showBottomNav: false,
                body: errorBody,
              )
            : Scaffold(
                backgroundColor: colors.primaryBackground,
                body: errorBody,
              );
      },
    );
  }

  Widget _buildClassicPage(
    BuildContext context,
    WidgetRef ref,
    Property property,
    DynamicAppColors colors,
    AppLocalizations l10n,
  ) {
    return Scaffold(
      backgroundColor: colors.primaryBackground,
      body: CustomScrollView(
        slivers: [
          _buildClassicAppBar(context, ref, property, colors),
          SliverToBoxAdapter(
            child: Container(
              color: colors.primaryBackground,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildHeader(context, property, ref, colors, l10n),
                  const SizedBox(height: 16),
                  _buildStats(
                    context,
                    property,
                    ref,
                    colors,
                    l10n,
                    glassMode: false,
                  ),
                  const SizedBox(height: 24),
                  _buildDescription(
                    context,
                    property,
                    colors,
                    l10n,
                    glassMode: false,
                  ),
                  if (property.details.amenities.isNotEmpty) ...[
                    const SizedBox(height: 24),
                    _buildAmenities(
                      context,
                      property,
                      ref,
                      colors,
                      l10n,
                      glassMode: false,
                    ),
                  ],
                  const SizedBox(height: 24),
                  _buildLocation(
                    context,
                    property,
                    ref,
                    colors,
                    l10n,
                    glassMode: false,
                  ),
                  const SizedBox(height: 24),
                  _buildFinancialDetails(
                    context,
                    property,
                    ref,
                    colors,
                    l10n,
                    glassMode: false,
                  ),
                  const SizedBox(height: 100),
                ],
              ),
            ),
          ),
        ],
      ),
      floatingActionButton: _buildContactButton(
        context,
        property,
        ref,
        colors,
        l10n,
        glassMode: false,
      ),
    );
  }

  Widget _buildGlassPage(
    BuildContext context,
    WidgetRef ref,
    Property property,
    DynamicAppColors colors,
    AppLocalizations l10n,
  ) {
    final currentUser = ref.watch(currentUserProvider);
    final actions = <Widget>[];
    if (currentUser?.role == 'landlord') {
      actions.add(
        IconButton(
          icon: const Icon(Icons.edit, color: Colors.white),
          onPressed: () {
            GoRouter.of(context).push('/add-property', extra: property);
          },
        ),
      );
    }

    return GlassPageScaffold(
      title: l10n.propertyDetails,
      showBottomNav: false,
      actions: actions.isEmpty ? null : actions,
      floatingActionButton: _buildContactButton(
        context,
        property,
        ref,
        colors,
        l10n,
        glassMode: true,
      ),
      body: _buildGlassBody(context, ref, property, colors, l10n),
    );
  }

  Widget _buildGlassBody(
    BuildContext context,
    WidgetRef ref,
    Property property,
    DynamicAppColors colors,
    AppLocalizations l10n,
  ) {
    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.only(bottom: 140),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _buildGlassHeader(context, property, ref, colors, l10n),
          const SizedBox(height: 20),
          _buildStats(
            context,
            property,
            ref,
            colors,
            l10n,
            glassMode: true,
          ),
          const SizedBox(height: 20),
          _buildDescription(
            context,
            property,
            colors,
            l10n,
            glassMode: true,
          ),
          if (property.details.amenities.isNotEmpty) ...[
            const SizedBox(height: 20),
            _buildAmenities(
              context,
              property,
              ref,
              colors,
              l10n,
              glassMode: true,
            ),
          ],
          const SizedBox(height: 20),
          _buildLocation(
            context,
            property,
            ref,
            colors,
            l10n,
            glassMode: true,
          ),
          const SizedBox(height: 20),
          _buildFinancialDetails(
            context,
            property,
            ref,
            colors,
            l10n,
            glassMode: true,
          ),
        ],
      ),
    );
  }

  Widget _buildGlassHeader(
    BuildContext context,
    Property property,
    WidgetRef ref,
    DynamicAppColors colors,
    AppLocalizations l10n,
  ) {
    final rentText =
        ref.read(currencyProvider.notifier).formatAmount(property.rentAmount);
    final subtitle = _locationSubtitle(property);
    final subtitleColor = Colors.white.withValues(alpha: 0.78);

    return GlassContainer(
      padding: EdgeInsets.zero,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(24),
            child: SizedBox(
              height: 220,
              width: double.infinity,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  _buildImageCarousel(property, colors),
                  Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Colors.black.withValues(alpha: 0.55),
                          Colors.black.withValues(alpha: 0.25),
                          Colors.black.withValues(alpha: 0.68),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(22),
            child: Container(
              decoration: BoxDecoration(
                color: Colors.black.withValues(alpha: 0.35),
                borderRadius: BorderRadius.circular(20),
              ),
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildStatusChip(
                    context,
                    status: property.status,
                    colors: colors,
                    glassMode: true,
                  ),
                  const SizedBox(height: 14),
                  Text(
                    _primaryTitle(property, l10n),
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 22,
                      fontWeight: FontWeight.w700,
                      letterSpacing: -0.3,
                    ),
                  ),
                  if (subtitle != null) ...[
                    const SizedBox(height: 8),
                    Text(
                      subtitle,
                      style: TextStyle(
                        color: subtitleColor,
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                  const SizedBox(height: 18),
                  Row(
                    children: [
                      Icon(
                        Icons.payments_outlined,
                        size: 20,
                        color: colors.luxuryGold,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        '$rentText/${l10n.monthlyInterval}',
                        style: TextStyle(
                          color: colors.luxuryGold,
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader(
    BuildContext context,
    Property property,
    WidgetRef ref,
    DynamicAppColors colors,
    AppLocalizations l10n,
  ) {
    final rentText =
        ref.read(currencyProvider.notifier).formatAmount(property.rentAmount);
    final subtitle = _locationSubtitle(property);

    return Padding(
      padding: const EdgeInsets.all(AppSpacing.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  _primaryTitle(property, l10n),
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: colors.textPrimary,
                      ),
                ),
              ),
              _buildStatusChip(
                context,
                status: property.status,
                colors: colors,
                glassMode: false,
              ),
            ],
          ),
          if (subtitle != null) ...[
            const SizedBox(height: 8),
            Text(
              subtitle,
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                    color: colors.textSecondary,
                  ),
            ),
          ],
          const SizedBox(height: 16),
          Text(
            '$rentText/${l10n.monthlyInterval}',
            style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                  color: colors.primaryAccent,
                  fontWeight: FontWeight.bold,
                ),
          ),
        ],
      ),
    );
  }

  Widget _buildStats(
    BuildContext context,
    Property property,
    WidgetRef ref,
    DynamicAppColors colors,
    AppLocalizations l10n, {
    required bool glassMode,
  }) {
    final sizeText = '${property.details.size.toStringAsFixed(0)} m2';
    final roomsText = property.details.rooms.toString();
    final tenantsText = property.tenantIds.length.toString();

    final row = Row(
      children: [
        Expanded(
          child: _buildStatCard(
            context,
            icon: Icons.square_foot,
            value: sizeText,
            label: l10n.size,
            colors: colors,
            glassMode: glassMode,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _buildStatCard(
            context,
            icon: Icons.meeting_room,
            value: roomsText,
            label: l10n.rooms,
            colors: colors,
            glassMode: glassMode,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _buildStatCard(
            context,
            icon: Icons.people_alt_outlined,
            value: tenantsText,
            label: l10n.tenants,
            colors: colors,
            glassMode: glassMode,
          ),
        ),
      ],
    );

    if (glassMode) {
      return GlassContainer(child: row);
    }

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: row,
    );
  }

  Widget _buildStatCard(
    BuildContext context, {
    required IconData icon,
    required String value,
    required String label,
    required DynamicAppColors colors,
    required bool glassMode,
  }) {
    final textPrimary = glassMode ? Colors.white : colors.textPrimary;
    final textSecondary =
        glassMode ? Colors.white.withValues(alpha: 0.75) : colors.textSecondary;
    final iconColor = glassMode ? Colors.white : colors.primaryAccent;
    final backgroundColor =
        glassMode ? Colors.black.withValues(alpha: 0.25) : colors.surfaceCards;
    final borderColor =
        glassMode ? Colors.white.withValues(alpha: 0.35) : colors.borderLight;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: borderColor),
        boxShadow: glassMode
            ? null
            : [
                BoxShadow(
                  color: colors.shadowColor,
                  blurRadius: 14,
                  offset: const Offset(0, 6),
                ),
              ],
      ),
      child: Column(
        children: [
          Icon(
            icon,
            color: iconColor,
            size: 24,
          ),
          const SizedBox(height: 10),
          Text(
            value,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w700,
                  color: textPrimary,
                ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: textSecondary,
                ),
          ),
        ],
      ),
    );
  }

  Widget _buildDescription(
    BuildContext context,
    Property property,
    DynamicAppColors colors,
    AppLocalizations l10n, {
    required bool glassMode,
  }) {
    final titleColor = glassMode ? Colors.white : colors.textPrimary;
    final bodyColor =
        glassMode ? Colors.white.withValues(alpha: 0.82) : colors.textSecondary;

    final content = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          l10n.description,
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
                color: titleColor,
              ),
        ),
        const SizedBox(height: 12),
        Text(
          'Spacious ${property.details.rooms}-room property with ${property.details.size.toStringAsFixed(0)} m2 in ${property.address.city}.',
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: bodyColor,
                height: 1.5,
              ),
        ),
      ],
    );

    if (glassMode) {
      return GlassContainer(
        child: Container(
          decoration: BoxDecoration(
            color: Colors.black.withValues(alpha: 0.28),
            borderRadius: BorderRadius.circular(16),
          ),
          padding: const EdgeInsets.all(16),
          child: content,
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: content,
    );
  }

  Widget _buildAmenities(
    BuildContext context,
    Property property,
    WidgetRef ref,
    DynamicAppColors colors,
    AppLocalizations l10n, {
    required bool glassMode,
  }) {
    final titleColor = glassMode ? Colors.white : colors.textPrimary;
    final chipTextColor = glassMode ? Colors.white : colors.primaryAccent;

    final content = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          l10n.amenities,
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
                color: titleColor,
              ),
        ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: property.details.amenities.map((amenity) {
            return Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: glassMode
                    ? Colors.black.withValues(alpha: 0.24)
                    : colors.primaryAccent.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(20),
                border: glassMode
                    ? Border.all(color: Colors.white.withValues(alpha: 0.35))
                    : Border.all(
                        color: colors.primaryAccent.withValues(alpha: 0.25),
                      ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    _getAmenityIcon(amenity),
                    size: 16,
                    color: glassMode ? Colors.white : colors.primaryAccent,
                  ),
                  const SizedBox(width: 6),
                  Text(
                    amenity,
                    style: TextStyle(
                      color: chipTextColor,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            );
          }).toList(),
        ),
      ],
    );

    if (glassMode) {
      return GlassContainer(
        child: Container(
          decoration: BoxDecoration(
            color: Colors.black.withValues(alpha: 0.28),
            borderRadius: BorderRadius.circular(16),
          ),
          padding: const EdgeInsets.all(16),
          child: content,
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: content,
    );
  }

  Widget _buildLocation(
    BuildContext context,
    Property property,
    WidgetRef ref,
    DynamicAppColors colors,
    AppLocalizations l10n, {
    required bool glassMode,
  }) {
    final titleColor = glassMode ? Colors.white : colors.textPrimary;
    final addressText = _locationSubtitle(property) ?? '';
    final borderColor =
        glassMode ? Colors.white.withValues(alpha: 0.32) : colors.borderLight;
    final backgroundColor =
        glassMode ? Colors.black.withValues(alpha: 0.28) : colors.surfaceCards;

    final content = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          l10n.location,
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
                color: titleColor,
              ),
        ),
        const SizedBox(height: 12),
        Container(
          height: 200,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: borderColor),
            color: backgroundColor,
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: FutureBuilder<LatLng?>(
              future: _getLocationFromAddress(property.address),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return _buildMapLoading(colors);
                } else if (snapshot.hasError || !snapshot.hasData) {
                  return _buildMapPlaceholder(
                    context,
                    colors,
                    property,
                    l10n,
                    glassMode: glassMode,
                  );
                } else {
                  final location = snapshot.data!;
                  return GoogleMap(
                    initialCameraPosition: CameraPosition(
                      target: location,
                      zoom: 15.0,
                    ),
                    markers: {
                      Marker(
                        markerId: const MarkerId('property'),
                        position: location,
                        infoWindow: InfoWindow(
                          title: property.address.street,
                          snippet: addressText,
                        ),
                      ),
                    },
                    zoomControlsEnabled: false,
                    mapToolbarEnabled: false,
                    myLocationButtonEnabled: false,
                    onTap: (_) => _openMapsApp(location),
                  );
                }
              },
            ),
          ),
        ),
        const SizedBox(height: 12),
        GestureDetector(
          onTap: () async {
            final location = await _getLocationFromAddress(property.address);
            if (location != null) {
              _openMapsApp(location);
            }
          },
          child: Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: colors.primaryAccent.withValues(
                alpha: glassMode ? 0.25 : 0.1,
              ),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: colors.primaryAccent.withValues(
                  alpha: glassMode ? 0.45 : 0.3,
                ),
              ),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.directions,
                  color: colors.primaryAccent,
                  size: 20,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        l10n.getDirections,
                        style: TextStyle(
                          color: colors.primaryAccent,
                          fontWeight: FontWeight.w600,
                          fontSize: 14,
                        ),
                      ),
                      Text(
                        addressText,
                        style: TextStyle(
                          color: glassMode
                              ? Colors.white.withValues(alpha: 0.78)
                              : colors.textSecondary,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
                Icon(
                  Icons.open_in_new,
                  color: colors.primaryAccent,
                  size: 16,
                ),
              ],
            ),
          ),
        ),
      ],
    );

    if (glassMode) {
      return GlassContainer(
        child: Container(
          decoration: BoxDecoration(
            color: Colors.black.withValues(alpha: 0.26),
            borderRadius: BorderRadius.circular(16),
          ),
          padding: const EdgeInsets.all(16),
          child: content,
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: content,
    );
  }

  Widget _buildFinancialDetails(
    BuildContext context,
    Property property,
    WidgetRef ref,
    DynamicAppColors colors,
    AppLocalizations l10n, {
    required bool glassMode,
  }) {
    final rent =
        ref.read(currencyProvider.notifier).formatAmount(property.rentAmount);
    final outstanding = ref
        .read(currencyProvider.notifier)
        .formatAmount(property.outstandingPayments);
    final titleColor = glassMode ? Colors.white : colors.textPrimary;
    final labelColor =
        glassMode ? Colors.white.withValues(alpha: 0.78) : colors.textSecondary;
    final valueColor = glassMode ? Colors.white : colors.textPrimary;
    final outstandingColor =
        property.outstandingPayments > 0 ? colors.error : colors.success;
    final cardBackgroundColor =
        glassMode ? Colors.black.withValues(alpha: 0.38) : Colors.white;
    final cardBorderColor = glassMode
        ? Colors.white.withValues(alpha: 0.38)
        : colors.borderLight.withValues(alpha: 0.7);

    final content = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          l10n.financialDetails,
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
                color: titleColor,
              ),
        ),
        const SizedBox(height: 12),
        Container(
          decoration: BoxDecoration(
            color: cardBackgroundColor,
            borderRadius: BorderRadius.circular(16),
            border:
                Border.all(color: cardBorderColor, width: glassMode ? 1.2 : 1),
            boxShadow: glassMode
                ? null
                : [
                    BoxShadow(
                      color: colors.shadowColor.withValues(alpha: 0.12),
                      blurRadius: 20,
                      offset: const Offset(0, 10),
                    ),
                  ],
          ),
          child: Column(
            children: [
              _buildFinancialRow(
                label: l10n.monthlyRent,
                value: rent,
                labelColor: labelColor,
                valueColor: valueColor,
              ),
              Divider(
                color: glassMode
                    ? Colors.white.withValues(alpha: 0.12)
                    : colors.borderLight.withValues(alpha: 0.5),
                thickness: 1,
                height: 0,
              ),
              _buildFinancialRow(
                label: l10n.outstandingPayments,
                value: outstanding,
                labelColor: labelColor,
                valueColor: outstandingColor,
              ),
            ],
          ),
        ),
      ],
    );

    if (glassMode) {
      return GlassContainer(
        padding: const EdgeInsets.all(18),
        child: content,
      );
    }

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: content,
    );
  }

  Widget _buildFinancialRow({
    required String label,
    required String value,
    required Color labelColor,
    required Color valueColor,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      child: Row(
        children: [
          Expanded(
            child: Text(
              label,
              style: TextStyle(
                color: labelColor,
                fontSize: 14,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Text(
            value,
            style: TextStyle(
              color: valueColor,
              fontWeight: FontWeight.w700,
              fontSize: 16,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorState(
    BuildContext context,
    DynamicAppColors colors,
    AppLocalizations l10n,
    Object error, {
    required bool glassMode,
  }) {
    final content = Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(
          Icons.error_outline,
          size: 48,
          color: glassMode ? Colors.white : colors.error,
        ),
        const SizedBox(height: 12),
        Text(
          l10n.somethingWentWrong,
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: glassMode ? Colors.white : colors.textPrimary,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          error.toString(),
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 13,
            color: glassMode
                ? Colors.white.withValues(alpha: 0.85)
                : colors.textSecondary,
          ),
        ),
      ],
    );

    if (glassMode) {
      return Center(
        child: GlassContainer(
          padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 24),
          child: content,
        ),
      );
    }

    return Center(
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 24),
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
        decoration: BoxDecoration(
          color: colors.surfaceCards,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: colors.shadowColor,
              blurRadius: 16,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: content,
      ),
    );
  }

  SliverAppBar _buildClassicAppBar(
    BuildContext context,
    WidgetRef ref,
    Property property,
    DynamicAppColors colors,
  ) {
    final currentUser = ref.watch(currentUserProvider);
    final isLandlord = currentUser?.role == 'landlord';

    return SliverAppBar(
      expandedHeight: 320,
      pinned: true,
      backgroundColor: colors.surfaceCards,
      surfaceTintColor: colors.surfaceCards,
      iconTheme: const IconThemeData(color: Colors.white),
      flexibleSpace: FlexibleSpaceBar(
        background: _buildImageCarousel(property, colors),
      ),
      actions: isLandlord
          ? [
              Padding(
                padding: const EdgeInsets.only(right: 16, top: 12),
                child: _buildEditAction(context, property),
              ),
            ]
          : null,
    );
  }

  Widget _buildEditAction(BuildContext context, Property property) {
    return Material(
      color: Colors.black.withValues(alpha: 0.3),
      borderRadius: BorderRadius.circular(20),
      child: IconButton(
        icon: const Icon(Icons.edit, color: Colors.white),
        onPressed: () {
          GoRouter.of(context).push('/add-property', extra: property);
        },
      ),
    );
  }

  Widget? _buildContactButton(
    BuildContext context,
    Property property,
    WidgetRef ref,
    DynamicAppColors colors,
    AppLocalizations l10n, {
    required bool glassMode,
  }) {
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
    required bool glassMode,
  }) {
    final statusColor = _getStatusColor(status, colors);
    final label = _getStatusText(context, status);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: glassMode ? Colors.black.withValues(alpha: 0.42) : statusColor,
        borderRadius: BorderRadius.circular(20),
        border: glassMode
            ? Border.all(color: Colors.white.withValues(alpha: 0.35))
            : null,
      ),
      child: Text(
        label,
        style: TextStyle(
          color: glassMode ? Colors.white : colors.textOnAccent,
          fontSize: 12,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  Widget _buildImageCarousel(Property property, DynamicAppColors colors) {
    if (property.imageUrls.isEmpty) {
      return _buildImageFallback(colors);
    }

    return PageView.builder(
      itemCount: property.imageUrls.length,
      itemBuilder: (context, index) {
        final source = property.imageUrls[index];
        final resolved = _getImageUrl(source);

        if (resolved.isEmpty) {
          return _buildImageFallback(colors);
        }

        return MongoImage(
          imageId: resolved,
          fit: BoxFit.cover,
          loadingWidget: _buildImagePlaceholder(colors),
          errorWidget: _buildImageFallback(colors),
        );
      },
    );
  }

  Widget _buildImagePlaceholder(DynamicAppColors colors) {
    return Container(
      color: colors.surfaceSecondary,
      child: Center(
        child: CircularProgressIndicator(
          valueColor: AlwaysStoppedAnimation<Color>(colors.primaryAccent),
        ),
      ),
    );
  }

  Widget _buildImageFallback(DynamicAppColors colors) {
    return Container(
      color: colors.surfaceSecondary,
      child: Icon(
        Icons.home,
        size: 64,
        color: colors.textTertiary,
      ),
    );
  }

  Widget _buildMapLoading(DynamicAppColors colors) {
    return Container(
      color: colors.surfaceSecondary,
      child: Center(
        child: CircularProgressIndicator(
          valueColor: AlwaysStoppedAnimation<Color>(colors.primaryAccent),
        ),
      ),
    );
  }

  Widget _buildMapPlaceholder(
    BuildContext context,
    DynamicAppColors colors,
    Property property,
    AppLocalizations l10n, {
    required bool glassMode,
  }) {
    final textColor =
        glassMode ? Colors.black.withValues(alpha: 0.6) : colors.textSecondary;
    final background = glassMode
        ? Colors.white.withValues(alpha: 0.08)
        : colors.surfaceSecondary;

    return Container(
      color: background,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.location_off,
            size: 48,
            color: textColor,
          ),
          const SizedBox(height: 8),
          Text(
            l10n.location,
            style: TextStyle(
              color: textColor,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 4),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Text(
              '${property.address.street}\n${property.address.city}, ${property.address.postalCode}',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: textColor,
                fontSize: 12,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<LatLng?> _getLocationFromAddress(Address address) async {
    try {
      final googleLocation = await _tryGoogleGeocodingAPI(address);
      if (googleLocation != null) {
        return googleLocation;
      }

      final location = await _tryBuiltInGeocoding(address);
      if (location != null) {
        return location;
      }

      final fallbackLocation = _getSwissCityCoordinates(address.city);
      if (fallbackLocation != null) {
        return fallbackLocation;
      }

      return null;
    } catch (e) {
      debugPrint('Error getting location: $e');
      return null;
    }
  }

  Future<LatLng?> _tryGoogleGeocodingAPI(Address address) async {
    try {
      const apiKey = 'AIzaSyBn2DBnF5XDD-X4JkrT0XKDJSAZwydyNY4';
      final query = Uri.encodeComponent(
        '${address.street}, ${address.city}, ${address.postalCode}, ${address.country}',
      );
      final url =
          'https://maps.googleapis.com/maps/api/geocode/json?address=$query&key=$apiKey';

      final response = await http.get(Uri.parse(url));

      if (response.statusCode == 200) {
        final data = json.decode(response.body);

        if (data['status'] == 'OK' && data['results'].isNotEmpty) {
          final location = data['results'][0]['geometry']['location'];
          return LatLng(location['lat'].toDouble(), location['lng'].toDouble());
        }
      }
    } catch (e) {
      debugPrint('Google Geocoding API exception: $e');
    }
    return null;
  }

  LatLng? _getSwissCityCoordinates(String city) {
    final coordinates = {
      'Therwil': const LatLng(47.4976342, 7.5536007),
      'Hinterkirchweg 78, Therwil': const LatLng(47.4976342, 7.5536007),
      'Basel': const LatLng(47.5596, 7.5886),
      'Zurich': const LatLng(47.3769, 8.5417),
      'Bern': const LatLng(46.9481, 7.4474),
      'Geneva': const LatLng(46.2044, 6.1432),
      'Lausanne': const LatLng(46.5197, 6.6323),
      'Winterthur': const LatLng(47.4979, 8.7240),
      'Lucerne': const LatLng(47.0502, 8.3093),
    };

    if (coordinates.containsKey(city)) {
      return coordinates[city];
    }

    final cityLower = city.toLowerCase();
    for (final entry in coordinates.entries) {
      if (entry.key.toLowerCase() == cityLower) {
        return entry.value;
      }
    }

    return null;
  }

  Future<LatLng?> _tryBuiltInGeocoding(Address address) async {
    try {
      final queries = [
        '${address.street}, ${address.city}, ${address.postalCode}, ${address.country}',
        '${address.street}, ${address.city}, ${address.country}',
        '${address.city}, ${address.postalCode}, ${address.country}',
        '${address.city}, ${address.country}',
      ];

      for (final query in queries) {
        try {
          final locations = await locationFromAddress(query);
          if (locations.isNotEmpty) {
            final location = locations.first;
            return LatLng(location.latitude, location.longitude);
          }
        } catch (e) {
          continue;
        }
      }
    } catch (e) {
      debugPrint('Built-in geocoding failed: $e');
    }
    return null;
  }

  void _openMapsApp(LatLng location) async {
    final url =
        'https://www.google.com/maps/search/?api=1&query=${location.latitude},${location.longitude}';
    if (await canLaunchUrl(Uri.parse(url))) {
      await launchUrl(Uri.parse(url));
    }
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

  IconData _getAmenityIcon(String amenity) {
    switch (amenity.toLowerCase()) {
      case 'balcony':
        return Icons.balcony;
      case 'elevator':
        return Icons.elevator;
      case 'laundry':
        return Icons.local_laundry_service;
      case 'parking':
        return Icons.local_parking;
      case 'gym':
        return Icons.fitness_center;
      case 'pool':
        return Icons.pool;
      default:
        return Icons.check_circle;
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
}
