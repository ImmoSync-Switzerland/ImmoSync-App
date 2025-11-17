import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../../l10n/app_localizations.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geocoding/geocoding.dart';
import 'package:url_launcher/url_launcher.dart';

import 'package:immosync/features/property/presentation/widgets/email_invite_tenant_dialog.dart';
import '../../domain/models/property.dart';
import '../providers/property_providers.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/providers/currency_provider.dart';
import '../../../../core/providers/dynamic_colors_provider.dart';

class PropertyDetailsPage extends ConsumerWidget {
  final String propertyId;

  const PropertyDetailsPage({required this.propertyId, super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final propertyAsync = ref.watch(propertyProvider(propertyId));

    return Scaffold(
      backgroundColor: Colors.white,
      body: propertyAsync.when(
        data: (property) => CustomScrollView(
          slivers: [
            _buildAppBar(property, ref),
            SliverToBoxAdapter(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildHeader(context, property, ref),
                  const SizedBox(height: 16),
                  _buildStats(context, property),
                  const SizedBox(height: 24),
                  _buildDescription(context, property),
                  const SizedBox(height: 24),
                  _buildAmenities(context, property),
                  const SizedBox(height: 24),
                  _buildLocation(context, property),
                  const SizedBox(height: 24),
                  _buildFinancialDetails(context, property, ref),
                  const SizedBox(height: 100), // Bottom padding for FAB
                ],
              ),
            ),
          ],
        ),
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stack) => Center(child: Text('Error: $error')),
      ),
      floatingActionButton: propertyAsync.when(
        data: (property) => _buildContactButton(context, property, ref),
        loading: () => null,
        error: (_, __) => null,
      ),
    );
  }

  void _showInviteTenantDialog(BuildContext context, Property property) {
    showDialog(
      context: context,
      builder: (context) => EmailInviteTenantDialog(propertyId: property.id),
    );
  }

  Widget _buildHeader(BuildContext context, Property property, WidgetRef ref) {
    final street = property.address.street.trim();
    final cityPostal =
        '${property.address.city}, ${property.address.postalCode}';
    final hasStreet = street.isNotEmpty;
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  hasStreet ? street : cityPostal,
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: _getStatusColor(property.status),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  _getStatusText(context, property.status),
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          if (hasStreet) ...[
            const SizedBox(height: 8),
            Text(
              cityPostal,
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                    color: Colors.grey[600],
                  ),
            ),
          ],
          const SizedBox(height: 16),
          Text(
            '${ref.read(currencyProvider.notifier).formatAmount(property.rentAmount)}/${AppLocalizations.of(context)!.monthlyInterval}',
            style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                  color: AppColors.primaryAccent,
                  fontWeight: FontWeight.bold,
                ),
          ),
        ],
      ),
    );
  }

  Widget _buildStats(BuildContext context, Property property) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: [
          Expanded(
            child: _buildStatCard(
              context,
              Icons.square_foot,
              '${property.details.size} m²',
              AppLocalizations.of(context)!.rooms, // Using existing key for now
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: _buildStatCard(
              context,
              Icons.bed,
              '${property.details.rooms}',
              AppLocalizations.of(context)!.rooms,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: _buildStatCard(
              context,
              Icons.home,
              property.tenantIds.length.toString(),
              AppLocalizations.of(context)!.tenants,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard(
    BuildContext context,
    IconData icon,
    String value,
    String label,
  ) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          Icon(icon, color: AppColors.primaryAccent, size: 24),
          const SizedBox(height: 8),
          Text(
            value,
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
          ),
          Text(
            label,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Colors.grey[600],
                ),
          ),
        ],
      ),
    );
  }

  Widget _buildDescription(BuildContext context, Property property) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            AppLocalizations.of(context)!.description,
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
          ),
          const SizedBox(height: 12),
          Text(
            'Beautiful property located in ${property.address.city}. This spacious ${property.details.rooms}-room apartment offers ${property.details.size} m² of living space.',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Colors.grey[700],
                  height: 1.5,
                ),
          ),
        ],
      ),
    );
  }

  Widget _buildAmenities(BuildContext context, Property property) {
    if (property.details.amenities.isEmpty) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            AppLocalizations.of(context)!.amenities,
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: property.details.amenities.map((amenity) {
              return Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: AppColors.primaryAccent.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      _getAmenityIcon(amenity),
                      size: 16,
                      color: AppColors.primaryAccent,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      amenity,
                      style: const TextStyle(
                        color: AppColors.primaryAccent,
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildLocation(BuildContext context, Property property) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            AppLocalizations.of(context)!.location,
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
          ),
          const SizedBox(height: 12),
          Container(
            height: 200,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.grey[300]!),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: FutureBuilder<LatLng?>(
                future: _getLocationFromAddress(property.address),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  } else if (snapshot.hasError || !snapshot.hasData) {
                    return Container(
                      color: Colors.grey[100],
                      child: Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.location_off,
                              size: 48,
                              color: Colors.grey[400],
                            ),
                            const SizedBox(height: 8),
                            Text(
                              AppLocalizations.of(context)!.noProperties,
                              style: TextStyle(color: Colors.grey[600]),
                            ),
                          ],
                        ),
                      ),
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
                            snippet:
                                '${property.address.city}, ${property.address.postalCode}',
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
                color: AppColors.primaryAccent.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: AppColors.primaryAccent.withValues(alpha: 0.3),
                ),
              ),
              child: Row(
                children: [
                  const Icon(
                    Icons.directions,
                    color: AppColors.primaryAccent,
                    size: 20,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          AppLocalizations.of(context)!.getDirections,
                          style: const TextStyle(
                            color: AppColors.primaryAccent,
                            fontWeight: FontWeight.w600,
                            fontSize: 14,
                          ),
                        ),
                        Text(
                          '${property.address.street}, ${property.address.city}',
                          style: TextStyle(
                            color: Colors.grey[600],
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const Icon(
                    Icons.open_in_new,
                    color: AppColors.primaryAccent,
                    size: 16,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<LatLng?> _getLocationFromAddress(Address address) async {
    try {
      // First try the built-in geocoding service
      final location = await _tryBuiltInGeocoding(address);
      if (location != null) {
        return location;
      }

      return null;
    } catch (e) {
      debugPrint('Error getting location: $e');
      return null;
    }
  }

  Future<LatLng?> _tryBuiltInGeocoding(Address address) async {
    try {
      final query =
          '${address.street}, ${address.city}, ${address.postalCode}, ${address.country}';
      final locations = await locationFromAddress(query);

      if (locations.isNotEmpty) {
        final location = locations.first;
        return LatLng(location.latitude, location.longitude);
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

  Widget _buildFinancialDetails(
      BuildContext context, Property property, WidgetRef ref) {
    final colors = ref.watch(dynamicColorsProvider);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            AppLocalizations.of(context)!.financialDetails,
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: colors.textPrimary,
                ),
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: colors.surfaceCards,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      AppLocalizations.of(context)!.monthlyRent,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: colors.textSecondary,
                          ),
                    ),
                    Text(
                      ref
                          .read(currencyProvider.notifier)
                          .formatAmount(property.rentAmount),
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: colors.textPrimary,
                          ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      AppLocalizations.of(context)!.outstandingPayments,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: colors.textSecondary,
                          ),
                    ),
                    Text(
                      ref
                          .read(currencyProvider.notifier)
                          .formatAmount(property.outstandingPayments),
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: property.outstandingPayments > 0
                                ? colors.error
                                : colors.success,
                          ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAppBar(Property property, WidgetRef ref) {
    return SliverAppBar(
      expandedHeight: 300,
      pinned: true,
      backgroundColor: Colors.white,
      iconTheme: const IconThemeData(color: Colors.white),
      actions: [
        Container(
          margin: const EdgeInsets.only(right: 16),
          decoration: BoxDecoration(
            color: Colors.black.withValues(alpha: 0.3),
            borderRadius: BorderRadius.circular(20),
          ),
          child: IconButton(
            icon: const Icon(Icons.edit, color: Colors.white),
            onPressed: () {
              GoRouter.of(ref.context).push('/add-property', extra: property);
            },
          ),
        ),
      ],
      flexibleSpace: FlexibleSpaceBar(
        background: property.imageUrls.isNotEmpty
            ? PageView.builder(
                itemCount: property.imageUrls.length,
                itemBuilder: (context, index) {
                  return Image.network(
                    property.imageUrls[index],
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) {
                      return Container(
                        color: Colors.grey[300],
                        child: const Icon(
                          Icons.home,
                          size: 64,
                          color: Colors.grey,
                        ),
                      );
                    },
                  );
                },
              )
            : Container(
                color: Colors.grey[300],
                child: const Icon(
                  Icons.home,
                  size: 64,
                  color: Colors.grey,
                ),
              ),
      ),
    );
  }

  Widget _buildContactButton(
      BuildContext context, Property property, WidgetRef ref) {
    final currentUser = ref.watch(currentUserProvider);

    if (currentUser?.role == 'landlord' && property.status == 'available') {
      return FloatingActionButton.extended(
        onPressed: () => _showInviteTenantDialog(context, property),
        backgroundColor: AppColors.primaryAccent,
        icon: const Icon(Icons.person_add, color: Colors.white),
        label: Text(
          AppLocalizations.of(context)!.inviteTenant,
          style: const TextStyle(color: Colors.white),
        ),
      );
    }

    return FloatingActionButton.extended(
      onPressed: () {
        GoRouter.of(context).push('/chat/${property.landlordId}');
      },
      backgroundColor: AppColors.primaryAccent,
      icon: const Icon(Icons.chat, color: Colors.white),
      label: Text(
        AppLocalizations.of(context)!.messages,
        style: const TextStyle(color: Colors.white),
      ),
    );
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'available':
        return Colors.green;
      case 'rented':
        return Colors.blue;
      case 'maintenance':
        return Colors.orange;
      default:
        return Colors.grey;
    }
  }

  String _getStatusText(BuildContext context, String status) {
    switch (status) {
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
}
