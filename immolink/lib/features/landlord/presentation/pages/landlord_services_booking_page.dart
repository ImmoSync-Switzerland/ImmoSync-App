import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../../l10n/app_localizations.dart';
import '../../../../core/providers/dynamic_colors_provider.dart';
import '../../../../core/widgets/common_bottom_nav.dart';
import '../../../services/domain/models/service.dart' as ServiceModel;
import '../../../services/presentation/providers/service_providers.dart';

// UI Service model for landlord booking
class BookableService {
  final String id;
  final String name;
  final String description;
  final String category;
  final double price;
  final String provider;
  final String contactInfo;
  final IconData icon;
  final bool isAvailable;

  BookableService({
    required this.id,
    required this.name,
    required this.description,
    required this.category,
    required this.price,
    required this.provider,
    required this.contactInfo,
    required this.icon,
    this.isAvailable = true,
  });

  factory BookableService.fromServiceModel(ServiceModel.Service service) {
    return BookableService(
      id: service.id,
      name: service.name,
      description: service.description,
      category: service.category,
      price: service.price,
      provider: service.contactInfo.isNotEmpty ? service.contactInfo : 'Service Provider',
      contactInfo: service.contactInfo,
      icon: _getIconForCategory(service.category),
      isAvailable: service.availability == 'available',
    );
  }

  static IconData _getIconForCategory(String category) {
    switch (category.toLowerCase()) {
      case 'maintenance':
        return Icons.build_outlined;
      case 'cleaning':
        return Icons.cleaning_services_outlined;
      case 'repair':
        return Icons.handyman_outlined;
      case 'security':
        return Icons.security_outlined;
      case 'gardening':
        return Icons.grass_outlined;
      case 'utilities':
        return Icons.electrical_services_outlined;
      case 'general':
        return Icons.room_service_outlined;
      default:
        return Icons.miscellaneous_services_outlined;
    }
  }
}

class LandlordServicesBookingPage extends ConsumerStatefulWidget {
  const LandlordServicesBookingPage({super.key});

  @override
  ConsumerState<LandlordServicesBookingPage> createState() => _LandlordServicesBookingPageState();
}

class _LandlordServicesBookingPageState extends ConsumerState<LandlordServicesBookingPage> {
  String _selectedCategory = 'all';
  String _searchQuery = '';

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final colors = ref.watch(dynamicColorsProvider);
    
    // Get all available services (admin-managed)
    final servicesAsync = ref.watch(allAvailableServicesProvider);
    
    return Scaffold(
      backgroundColor: colors.primaryBackground,
      appBar: AppBar(
        title: Text('Services'),
        backgroundColor: colors.surfaceCards,
        foregroundColor: colors.textPrimary,
        elevation: 0,
      ),
      body: servicesAsync.when(
        data: (services) {
          final bookableServices = services.map((s) => BookableService.fromServiceModel(s)).toList();
          
          return Column(
            children: [
              _buildHeader(colors),
              _buildSearchAndFilter(l10n, colors),
              Expanded(
                child: bookableServices.isEmpty 
                  ? _buildEmptyState(l10n, colors)
                  : _buildServicesList(bookableServices, l10n, colors),
              ),
            ],
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stack) => Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.error_outline, size: 64, color: colors.error),
              const SizedBox(height: 16),
              Text(
                'Fehler beim Laden der Services',
                style: TextStyle(fontSize: 18, color: colors.textPrimary),
              ),
              const SizedBox(height: 8),
              Text(
                error.toString(),
                style: TextStyle(fontSize: 14, color: colors.textSecondary),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () => ref.invalidate(allAvailableServicesProvider),
                child: Text('Erneut versuchen'),
              ),
            ],
          ),
        ),
      ),
      bottomNavigationBar: const CommonBottomNav(),
    );
  }

  Widget _buildHeader(DynamicAppColors colors) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: colors.surfaceCards,
        border: Border(
          bottom: BorderSide(color: colors.borderLight),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: colors.primaryAccent.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  Icons.room_service_outlined,
                  color: colors.primaryAccent,
                  size: 24,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Verfügbare Services',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w700,
                        color: colors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Buchen Sie Services für Ihre Immobilien',
                      style: TextStyle(
                        fontSize: 14,
                        color: colors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSearchAndFilter(AppLocalizations l10n, DynamicAppColors colors) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colors.surfaceCards,
        border: Border(
          bottom: BorderSide(color: colors.borderLight),
        ),
      ),
      child: Column(
        children: [
          TextField(
            onChanged: (value) => setState(() => _searchQuery = value.toLowerCase()),
            decoration: InputDecoration(
              hintText: 'Services durchsuchen...',
              hintStyle: TextStyle(color: colors.textSecondary),
              prefixIcon: Icon(Icons.search, color: colors.textSecondary),
              filled: true,
              fillColor: colors.primaryBackground,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide.none,
              ),
              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            ),
            style: TextStyle(color: colors.textPrimary),
          ),
          const SizedBox(height: 16),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                _buildCategoryChip('all', 'Alle', colors),
                const SizedBox(width: 8),
                _buildCategoryChip('maintenance', 'Wartung', colors),
                const SizedBox(width: 8),
                _buildCategoryChip('cleaning', 'Reinigung', colors),
                const SizedBox(width: 8),
                _buildCategoryChip('repair', 'Reparatur', colors),
                const SizedBox(width: 8),
                _buildCategoryChip('security', 'Sicherheit', colors),
                const SizedBox(width: 8),
                _buildCategoryChip('gardening', 'Garten', colors),
                const SizedBox(width: 8),
                _buildCategoryChip('utilities', 'Versorgung', colors),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCategoryChip(String category, String label, DynamicAppColors colors) {
    final isSelected = _selectedCategory == category;
    return GestureDetector(
      onTap: () => setState(() => _selectedCategory = category),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? colors.primaryAccent : colors.primaryBackground,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected ? colors.primaryAccent : colors.borderLight,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isSelected ? Colors.white : colors.textPrimary,
            fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
            fontSize: 14,
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState(AppLocalizations l10n, DynamicAppColors colors) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: colors.primaryAccent.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.room_service_outlined,
              size: 48,
              color: colors.primaryAccent,
            ),
          ),
          const SizedBox(height: 20),
          Text(
            'Keine Services verfügbar',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w600,
              color: colors.textPrimary,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            'Derzeit sind keine Services zum Buchen verfügbar.\nPrüfen Sie später erneut.',
            style: TextStyle(
              fontSize: 14,
              color: colors.textSecondary,
              height: 1.4,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildServicesList(List<BookableService> services, AppLocalizations l10n, DynamicAppColors colors) {
    final filteredServices = services.where((service) {
      final matchesCategory = _selectedCategory == 'all' || service.category.toLowerCase() == _selectedCategory;
      final matchesSearch = _searchQuery.isEmpty ||
          service.name.toLowerCase().contains(_searchQuery) ||
          service.description.toLowerCase().contains(_searchQuery) ||
          service.provider.toLowerCase().contains(_searchQuery);
      return matchesCategory && matchesSearch && service.isAvailable;
    }).toList();

    if (filteredServices.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.search_off, size: 64, color: colors.textSecondary),
            const SizedBox(height: 16),
            Text(
              'Keine Services gefunden',
              style: TextStyle(fontSize: 18, color: colors.textPrimary),
            ),
            const SizedBox(height: 8),
            Text(
              'Versuchen Sie es mit anderen Suchbegriffen.',
              style: TextStyle(fontSize: 14, color: colors.textSecondary),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: filteredServices.length,
      itemBuilder: (context, index) {
        final service = filteredServices[index];
        return _buildServiceCard(service, colors);
      },
    );
  }

  Widget _buildServiceCard(BookableService service, DynamicAppColors colors) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: colors.surfaceCards,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: colors.borderLight),
        boxShadow: [
          BoxShadow(
            color: colors.shadowColor,
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: colors.primaryAccent.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    service.icon,
                    color: colors.primaryAccent,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        service.name,
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                          color: colors.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        service.category.toUpperCase(),
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: colors.primaryAccent,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: colors.success.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    '€${service.price.toStringAsFixed(2)}',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: colors.success,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Text(
              service.description,
              style: TextStyle(
                fontSize: 14,
                color: colors.textSecondary,
                height: 1.4,
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Icon(
                  Icons.business,
                  size: 16,
                  color: colors.textSecondary,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    service.provider,
                    style: TextStyle(
                      fontSize: 14,
                      color: colors.textSecondary,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () => _showBookingDialog(service),
                style: ElevatedButton.styleFrom(
                  backgroundColor: colors.primaryAccent,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: Text(
                  'Service buchen',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showBookingDialog(BookableService service) {
    final colors = ref.read(dynamicColorsProvider);
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text('Service buchen'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Sie möchten "${service.name}" buchen?',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: colors.primaryBackground,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: colors.borderLight),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(service.icon, color: colors.primaryAccent, size: 20),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          service.name,
                          style: TextStyle(fontWeight: FontWeight.w600),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    service.description,
                    style: TextStyle(
                      fontSize: 14,
                      color: colors.textSecondary,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Preis:',
                        style: TextStyle(fontWeight: FontWeight.w600),
                      ),
                      Text(
                        '€${service.price.toStringAsFixed(2)}',
                        style: TextStyle(
                          fontWeight: FontWeight.w700,
                          color: colors.success,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'Ein Mitarbeiter wird sich in Kürze mit Ihnen in Verbindung setzen, um die Details zu klären.',
              style: TextStyle(
                fontSize: 14,
                color: colors.textSecondary,
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text('Abbrechen'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(context).pop();
              _bookService(service);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: colors.primaryAccent,
              foregroundColor: Colors.white,
            ),
            child: Text('Buchen'),
          ),
        ],
      ),
    );
  }

  void _bookService(BookableService service) {
    final colors = ref.read(dynamicColorsProvider);
    
    // In a real implementation, this would create a booking request
    // For now, we'll just show a success message
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(Icons.check_circle, color: Colors.white),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                'Buchungsanfrage für "${service.name}" wurde gesendet!',
                style: TextStyle(fontWeight: FontWeight.w600),
              ),
            ),
          ],
        ),
        backgroundColor: colors.success,
        duration: const Duration(seconds: 4),
        action: SnackBarAction(
          label: 'Details',
          textColor: Colors.white,
          onPressed: () {
            // Navigate to booking details or chat
          },
        ),
      ),
    );
  }
}
