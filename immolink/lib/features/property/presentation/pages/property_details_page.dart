import 'package:flutter/material.dart';
import 'package:immosync/l10n/app_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geocoding/geocoding.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:immosync/features/property/presentation/widgets/email_invite_tenant_dialog.dart';
import 'package:immosync/core/widgets/mongo_image.dart';
import '../../domain/models/property.dart';
import '../providers/property_providers.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../../../../core/providers/dynamic_colors_provider.dart';
import '../../../../core/utils/image_resolver.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/providers/currency_provider.dart';

class PropertyDetailsPage extends ConsumerWidget {
  final String propertyId;

  const PropertyDetailsPage({required this.propertyId, super.key});

  String _getImageUrl(String imageIdOrPath) => resolvePropertyImage(imageIdOrPath);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final propertyAsync = ref.watch(propertyProvider(propertyId));
    return Scaffold(
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
                  _buildStats(context, property, ref),
                  const SizedBox(height: 24),
                  _buildDescription(context, property),
                  const SizedBox(height: 24),
                  _buildAmenities(context, property, ref),
                  const SizedBox(height: 24),
                  _buildLocation(context, property, ref),
                  const SizedBox(height: 24),
                  _buildFinancialDetails(context, property, ref),
                  const SizedBox(height: 100),
                ],
              ),
            ),
          ],
        ),
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, st) => Center(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Text(
              // Fallback generic error message key (adjust if specific key exists)
              AppLocalizations.of(context)!.error,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: Colors.red),
            ),
          ),
        ),
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
      builder: (ctx) => EmailInviteTenantDialog(propertyId: property.id),
    );
  }

  Widget _buildHeader(BuildContext context, Property property, WidgetRef ref) {
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
                  '${property.address.street}',
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
          const SizedBox(height: 8),
          Text(
            '${property.address.city}, ${property.address.postalCode}',
            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                  color: Colors.grey[600],
                ),
          ),
          const SizedBox(height: 16),
          Text(
            '${ref.read(currencyProvider.notifier).formatAmount(property.rentAmount)}/month',
            style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                  color: ref.read(dynamicColorsProvider).primaryAccent,
                  fontWeight: FontWeight.bold,
                ),
          ),
        ],
      ),
    );
  }

  Widget _buildStats(BuildContext context, Property property, WidgetRef ref) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: [
          Expanded(            child: _buildStatCard(
              context,
              Icons.square_foot,
              '${property.details.size} m²',
              AppLocalizations.of(context)!.rooms, // Using existing key for now
              ref,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: _buildStatCard(
              context,
              Icons.bed,
              '${property.details.rooms}',
              AppLocalizations.of(context)!.rooms,
              ref,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: _buildStatCard(
              context,
              Icons.home,
              property.tenantIds.length.toString(),
              AppLocalizations.of(context)!.tenants,
              ref,
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
    WidgetRef ref,
  ) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: ref.read(dynamicColorsProvider).surfaceSecondary,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          Icon(icon, color: ref.read(dynamicColorsProvider).primaryAccent, size: 24),
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
                  color: ref.read(dynamicColorsProvider).textSecondary,
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

  Widget _buildAmenities(BuildContext context, Property property, WidgetRef ref) {
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
                  color: ref.read(dynamicColorsProvider).primaryAccent.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      _getAmenityIcon(amenity),
                      size: 16,
                      color: ref.read(dynamicColorsProvider).primaryAccent,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      amenity,
                      style: TextStyle(
                        color: ref.read(dynamicColorsProvider).primaryAccent,
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                        inherit: true,
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

  Widget _buildLocation(BuildContext context, Property property, WidgetRef ref) {
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
                builder: (context, snapshot) {                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return Container(
                      color: Colors.grey[100],
                      child: const Center(child: CircularProgressIndicator()),
                    );
                  } else if (snapshot.hasError || !snapshot.hasData) {
                    return Container(
                      color: Colors.grey[100],
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.map,
                            size: 48,
                            color: Colors.grey[400],
                          ),
                          const SizedBox(height: 8),
                          Text(
                            AppLocalizations.of(context)!.location,
                            style: TextStyle(
                              color: Colors.grey[600],
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 16),
                            child: Text(
                              '${property.address.street}\n${property.address.city}, ${property.address.postalCode}\n${property.address.country}',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                color: Colors.grey[600],
                                fontSize: 12,
                              ),
                            ),
                          ),
                        ],
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
                            snippet: '${property.address.city}, ${property.address.postalCode}',
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
                color: ref.read(dynamicColorsProvider).primaryAccent.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: ref.read(dynamicColorsProvider).primaryAccent.withValues(alpha: 0.3),
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.directions,
                    color: ref.read(dynamicColorsProvider).primaryAccent,
                    size: 20,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          AppLocalizations.of(context)!.getDirections,
                          style: TextStyle(
                            color: ref.read(dynamicColorsProvider).primaryAccent,
                            fontWeight: FontWeight.w600,
                            fontSize: 14,
                            inherit: true,
                          ),
                        ),
                        Text(
                          '${property.address.street}, ${property.address.city}',
                          style: TextStyle(
                            color: ref.read(dynamicColorsProvider).textSecondary,
                            fontSize: 12,
                            inherit: true,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Icon(
                    Icons.open_in_new,
                    color: ref.read(dynamicColorsProvider).primaryAccent,
                    size: 16,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }  Future<LatLng?> _getLocationFromAddress(Address address) async {
    try {
      debugPrint('Trying to geocode: ${address.street}, ${address.city}, ${address.postalCode}, ${address.country}');
      
      // First try Google Maps Geocoding API directly
      final googleLocation = await _tryGoogleGeocodingAPI(address);
      if (googleLocation != null) {
        debugPrint('Google Geocoding successful: ${googleLocation.latitude}, ${googleLocation.longitude}');
        return googleLocation;
      }
      
      // Then try the built-in geocoding service
      final location = await _tryBuiltInGeocoding(address);
      if (location != null) {
        debugPrint('Built-in geocoding successful: ${location.latitude}, ${location.longitude}');
        return location;
      }
      
      // Fallback: Use approximate coordinates for Swiss cities
      final fallbackLocation = _getSwissCityCoordinates(address.city);
      if (fallbackLocation != null) {
        debugPrint('Using fallback coordinates for ${address.city}');
        return fallbackLocation;
      }
      
      debugPrint('Geocoding failed, returning null');
      return null;
    } catch (e) {
      debugPrint('Error getting location: $e');
      return null;
    }
  }

  // Try Google Maps Geocoding API directly
  Future<LatLng?> _tryGoogleGeocodingAPI(Address address) async {
    try {
      const apiKey = 'AIzaSyBn2DBnF5XDD-X4JkrT0XKDJSAZwydyNY4';
      final query = Uri.encodeComponent('${address.street}, ${address.city}, ${address.postalCode}, ${address.country}');
      final url = 'https://maps.googleapis.com/maps/api/geocode/json?address=$query&key=$apiKey';
      
      debugPrint('Trying Google Geocoding API: $url');
      
      final response = await http.get(Uri.parse(url));
      
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        
        if (data['status'] == 'OK' && data['results'].isNotEmpty) {
          final location = data['results'][0]['geometry']['location'];
          return LatLng(location['lat'].toDouble(), location['lng'].toDouble());
        } else {
          debugPrint('Google Geocoding API error: ${data['status']} - ${data['error_message'] ?? 'No error message'}');
        }
      } else {
        debugPrint('Google Geocoding API HTTP error: ${response.statusCode}');
      }
    } catch (e) {
      debugPrint('Google Geocoding API exception: $e');
    }
    return null;
  }  // Fallback coordinates for common Swiss cities and specific addresses
  LatLng? _getSwissCityCoordinates(String city) {
    final coordinates = {
      'Therwil': LatLng(47.4976342, 7.5536007), // Updated with exact coordinates
      'Hinterkirchweg 78, Therwil': LatLng(47.4976342, 7.5536007), // Exact coordinates from Google API
      'Basel': LatLng(47.5596, 7.5886),
      'Zürich': LatLng(47.3769, 8.5417),
      'Bern': LatLng(46.9481, 7.4474),
      'Geneva': LatLng(46.2044, 6.1432),
      'Lausanne': LatLng(46.5197, 6.6323),
      'Winterthur': LatLng(47.4979, 8.7240),
      'Lucerne': LatLng(47.0502, 8.3093),
      // Add more cities as needed
    };
    
    // Try exact match first
    if (coordinates.containsKey(city)) {
      return coordinates[city];
    }
    
    // Try case-insensitive match
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
          debugPrint('Trying geocoding query: $query');
          final locations = await locationFromAddress(query);
          
          if (locations.isNotEmpty) {
            final location = locations.first;
            debugPrint('Found location: ${location.latitude}, ${location.longitude}');
            return LatLng(location.latitude, location.longitude);
          }
        } catch (e) {
          debugPrint('Query "$query" failed: $e');
          continue;
        }
      }
    } catch (e) {
      debugPrint('Built-in geocoding failed: $e');
    }
    return null;
  }

  void _openMapsApp(LatLng location) async {
    final url = 'https://www.google.com/maps/search/?api=1&query=${location.latitude},${location.longitude}';
    if (await canLaunchUrl(Uri.parse(url))) {
      await launchUrl(Uri.parse(url));
    }
  }

  Widget _buildFinancialDetails(BuildContext context, Property property, WidgetRef ref) {
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
                      ref.read(currencyProvider.notifier).formatAmount(property.rentAmount),
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
                      ref.read(currencyProvider.notifier).formatAmount(property.outstandingPayments),
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
    final currentUser = ref.watch(currentUserProvider);
    final isLandlord = currentUser?.role == 'landlord';
    
    return SliverAppBar(
      expandedHeight: 300,
      pinned: true,
      backgroundColor: Colors.white,
      iconTheme: const IconThemeData(color: Colors.white),
      actions: isLandlord ? [
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
      ] : null,      flexibleSpace: FlexibleSpaceBar(
        background: property.imageUrls.isNotEmpty
            ? PageView.builder(
                itemCount: property.imageUrls.length,
                itemBuilder: (context, index) {
                  final imageIdOrPath = property.imageUrls[index];
                  
                  // Check if it's a MongoDB ObjectId (24 hex characters)
                  if (imageIdOrPath.length == 24 && RegExp(r'^[a-fA-F0-9]+$').hasMatch(imageIdOrPath)) {
                    final resolved = _getImageUrl(imageIdOrPath);
                    return MongoImage(
                      imageId: resolved,
                      fit: BoxFit.cover,
                      loadingWidget: Container(
                        color: Colors.grey[300],
                        child: const Center(
                          child: CircularProgressIndicator(),
                        ),
                      ),
                      errorWidget: Container(
                        color: Colors.grey[300],
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(
                              Icons.broken_image,
                              size: 64,
                              color: Colors.grey,
                            ),
                            const SizedBox(height: 8),
                            Text(
                              AppLocalizations.of(context)!.failedToLoadImage,
                              style: TextStyle(
                                color: Colors.grey[600],
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ],
                        ),
                      ),
                    );
                  } else {
                    // Fallback for old image paths
                    final imageUrl = _getImageUrl(imageIdOrPath);
                    if (imageUrl.isEmpty) {
                      return Container(
                        color: Colors.grey[300],
                        child: const Center(
                          child: Icon(Icons.image_not_supported, size: 48, color: Colors.grey),
                        ),
                      );
                    }
                    return Image.network(
                      imageUrl,
                      fit: BoxFit.cover,
                      headers: const {
                        'Cache-Control': 'no-cache',
                      },
                      loadingBuilder: (context, child, loadingProgress) {
                        if (loadingProgress == null) return child;
                        return Container(
                          color: Colors.grey[300],
                          child: Center(
                            child: CircularProgressIndicator(
                              value: loadingProgress.expectedTotalBytes != null
                                  ? loadingProgress.cumulativeBytesLoaded /
                                      loadingProgress.expectedTotalBytes!
                                  : null,
                            ),
                          ),
                        );
                      },
                      errorBuilder: (context, error, stackTrace) {
                        debugPrint('Error loading image: $imageUrl - $error');
                        return Container(
                          color: Colors.grey[300],
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.broken_image,
                                size: 64,
                                color: Colors.grey,
                              ),
                              SizedBox(height: 8),
                              Text(
                                AppLocalizations.of(context)!.failedToLoadImage,
                                style: TextStyle(
                                  color: Colors.grey[600],
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                ),
                                textAlign: TextAlign.center,
                              ),
                              const SizedBox(height: 4),
                              Text(
                                'URL: $imageUrl',
                                style: TextStyle(
                                  color: Colors.grey[600],
                                  fontSize: 10,
                                ),
                                textAlign: TextAlign.center,
                              ),
                            ],
                          ),
                        );
                      },
                    );
                  }
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
  }  Widget _buildContactButton(BuildContext context, Property property, WidgetRef ref) {
    final currentUser = ref.watch(currentUserProvider);
    
    if (currentUser?.role == 'landlord' && property.status == 'available') {
      return FloatingActionButton.extended(
        onPressed: () => _showInviteTenantDialog(context, property),
        backgroundColor: ref.read(dynamicColorsProvider).primaryAccent,
        icon: const Icon(Icons.person_add, color: Colors.white),
        label: Text(
          AppLocalizations.of(context)!.inviteTenant,
          style: const TextStyle(color: Colors.white),
        ),
      );
    }
    
    // Return empty container instead of message button
    return const SizedBox.shrink();
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
