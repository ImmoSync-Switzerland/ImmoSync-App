import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/widgets/app_top_bar.dart';
import '../../../../core/widgets/app_search_bar.dart';
import '../../../../core/widgets/common_bottom_nav.dart';
import '../../../../core/providers/navigation_provider.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../../../property/presentation/providers/property_providers.dart';
import '../../../property/domain/models/property.dart';
import '../../../../core/providers/currency_provider.dart';

class CategoryTab {
  final String label;
  final IconData icon;

  const CategoryTab({
    required this.label,
    required this.icon,
  });
}

class TenantDashboard extends ConsumerStatefulWidget {
  const TenantDashboard({super.key});

  @override
  ConsumerState<TenantDashboard> createState() => _TenantDashboardState();
}

class _TenantDashboardState extends ConsumerState<TenantDashboard> {
  int _selectedCategoryIndex = 0;

  @override
  void initState() {
    super.initState();
    // Set navigation index to Dashboard (0) when this page is loaded
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(navigationIndexProvider.notifier).state = 0;
    });
  }

  final List<CategoryTab> _categories = [
    const CategoryTab(label: 'All', icon: Icons.home),
    const CategoryTab(label: 'Apartments', icon: Icons.apartment),
    const CategoryTab(label: 'Houses', icon: Icons.house),
    const CategoryTab(label: 'Studios', icon: Icons.single_bed),
  ];

  String _getGreeting() {
    final hour = DateTime.now().hour;
    if (hour < 12) {
      return 'Good morning';
    } else if (hour < 17) {
      return 'Good afternoon';
    }
    return 'Good evening';
  }  @override
  Widget build(BuildContext context) {
    final currentUser = ref.watch(currentUserProvider);
    final propertiesAsync = ref.watch(tenantPropertiesProvider);
    
    return Scaffold(
      backgroundColor: AppColors.primaryBackground,
      appBar: AppTopBar(
        location: 'Springfield, IL',
        showLocation: true,
        onLocationTap: () {
          // Handle location tap
        },
        onNotificationTap: () {
          // Handle notification tap
        },
      ),
      body: propertiesAsync.when(        data: (properties) => SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: AppSpacing.sectionSeparation),
              _buildHeader(currentUser?.fullName ?? 'Guest User'),
              const SizedBox(height: AppSpacing.sectionSeparation),
              _buildSearchBar(),
              const SizedBox(height: AppSpacing.itemSeparation),
              _buildCategoryTabs(),
              const SizedBox(height: AppSpacing.sectionSeparation),
              if (_getFilteredProperties(properties).isNotEmpty) 
                _buildPropertyCard(_getFilteredProperties(properties).first)
              else
                _buildNoPropertyCard(),
              const SizedBox(height: AppSpacing.sectionSeparation),
              _buildQuickActions(),
              const SizedBox(height: AppSpacing.sectionSeparation),
              _buildRecentActivity(),
              const SizedBox(height: AppSpacing.xxxl),
            ],
          ),
        ),
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.error_outline, size: 48, color: AppColors.error),
              const SizedBox(height: 16),
              Text('Error loading dashboard', style: AppTypography.subhead),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () => ref.invalidate(tenantPropertiesProvider),
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
      ),
      bottomNavigationBar: const CommonBottomNav(),
    );
  }

  Widget _buildHeader(String userName) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.horizontalPadding),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                _getGreeting(),
                style: AppTypography.body.copyWith(
                  color: AppColors.textSecondary,
                ),
              ),
              const SizedBox(height: AppSpacing.sm),
              Text(
                userName,
                style: AppTypography.heading1,
              ),
            ],
          ),
          Container(
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: AppColors.primaryBackground,
              boxShadow: [
                BoxShadow(
                  color: AppColors.shadowColor,
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: CircleAvatar(
              radius: 24,
              backgroundColor: AppColors.surfaceCards,              child: const Icon(
                Icons.person_outline,
                color: AppColors.textSecondary,
                size: AppSizes.iconMedium,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchBar() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.horizontalPadding),
      child: AppSearchBar(
        hintText: 'Search properties, locations...',
        onTap: () {
          // Navigate to search page or show search functionality
        },
        readOnly: true,
      ),
    );
  }
  Widget _buildCategoryTabs() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.horizontalPadding),
      child: Container(
        height: 48,
        decoration: BoxDecoration(
          color: AppColors.surfaceCards,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: AppColors.shadowColor,
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          children: _categories.asMap().entries.map((entry) {
            final index = entry.key;
            final category = entry.value;
            final isSelected = _selectedCategoryIndex == index;
            
            return Expanded(
              child: GestureDetector(
                onTap: () {
                  setState(() {
                    _selectedCategoryIndex = index;
                  });
                },
                child: Container(
                  margin: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    color: isSelected ? AppColors.primaryAccent : Colors.transparent,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Center(
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          category.icon,
                          size: 16,
                          color: isSelected ? Colors.white : AppColors.textSecondary,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          category.label,
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: isSelected ? Colors.white : AppColors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            );
          }).toList(),
        ),
      ),
    );
  }
  Widget _buildPropertyCard(Property property) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.horizontalPadding),
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.primaryBackground,
          borderRadius: BorderRadius.circular(12.0), // cardsButtons radius
          boxShadow: [
            BoxShadow(
              color: AppColors.shadowColor,
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          children: [
            ClipRRect(
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(12.0), // cardsButtons radius
              ),
              child: Container(
                height: 120.0, // propertyCardImageHeight
                width: double.infinity,
                color: AppColors.surfaceCards,
                child: const Icon(
                  Icons.home,
                  color: AppColors.textPlaceholder,
                  size: 32.0, // iconLarge
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(AppSpacing.lg),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    property.address.street,
                    style: AppTypography.subhead,
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  Row(
                    children: [                      const Icon(
                        Icons.location_on_outlined,
                        size: 16.0, // iconSmall
                        color: AppColors.textSecondary,
                      ),
                      const SizedBox(width: AppSpacing.xs),
                      Text(
                        '${property.address.city}, ${property.address.postalCode}',
                        style: AppTypography.body.copyWith(
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.lg),
                  _buildPropertyStatus(property),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNoPropertyCard() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.horizontalPadding),
      child: Container(        decoration: BoxDecoration(
          color: AppColors.primaryBackground,
          borderRadius: BorderRadius.circular(12.0), // cardsButtons
          boxShadow: [
            BoxShadow(
              color: AppColors.shadowColor,
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: Column(
            children: [
              Icon(
                Icons.home_outlined,
                size: 64,
                color: AppColors.textPlaceholder,
              ),
              const SizedBox(height: AppSpacing.md),
              Text(
                'No Property Assigned',
                style: AppTypography.subhead,
              ),
              const SizedBox(height: AppSpacing.sm),
              Text(
                'You haven\'t been assigned to any property yet. Contact your landlord for more information.',
                style: AppTypography.body.copyWith(
                  color: AppColors.textSecondary,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPropertyStatus(Property property) {
    return Row(
      children: [
        _buildStatusItem('Rent Status', 'Paid', AppColors.success),
        const SizedBox(width: AppSpacing.lg),
        _buildStatusItem('Rent Amount', ref.read(currencyProvider.notifier).formatAmount(property.rentAmount), AppColors.primaryAccent),
      ],
    );
  }

  Widget _buildStatusItem(String label, String value, Color color) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(AppSpacing.md),        decoration: BoxDecoration(
          color: color == AppColors.success ? AppColors.successLight : AppColors.accentLight,
          borderRadius: BorderRadius.circular(12.0),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: AppTypography.caption,
            ),
            const SizedBox(height: AppSpacing.xs),
            Text(
              value,
              style: AppTypography.subhead.copyWith(
                color: color,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildQuickActions() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.horizontalPadding),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Quick Actions',
            style: AppTypography.heading2,
          ),
          const SizedBox(height: AppSpacing.itemSeparation),
          Row(
            children: [
              _buildActionButton('Pay Rent', Icons.payment, AppColors.success),
              const SizedBox(width: AppSpacing.md),
              _buildActionButton('Report Issue', Icons.warning_rounded, AppColors.warning),
              const SizedBox(width: AppSpacing.md),
              _buildActionButton('Message Landlord', Icons.message, AppColors.primaryAccent, () {
                // Navigate to conversations list or create new chat
                context.push('/conversations');
              }),
            ],
          ),
        ],
      ),
    );
  }
  Widget _buildActionButton(String label, IconData icon, Color color, [VoidCallback? onTap]) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap ?? () {
          // Default navigation based on the action button
          if (label == 'Pay Rent') {
            context.push('/payments/make');
          } else if (label == 'Report Issue') {
            context.push('/maintenance/request');
          } else if (label == 'Message Landlord') {
            context.push('/conversations');
          }
        },
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: AppSpacing.lg),          decoration: BoxDecoration(
            color: AppColors.primaryBackground,
            borderRadius: BorderRadius.circular(12.0), // cardsButtons
            boxShadow: [
              BoxShadow(
                color: AppColors.shadowColor,
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                icon,
                color: color,
                size: 24.0, // iconMedium
              ),
              const SizedBox(height: AppSpacing.xs),
              Text(
                label,
                style: AppTypography.caption.copyWith(
                  color: AppColors.textPrimary,
                  fontWeight: FontWeight.w600,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildRecentActivity() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.horizontalPadding),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Recent Activity',
            style: AppTypography.heading2,
          ),
          const SizedBox(height: AppSpacing.itemSeparation),
          _buildActivityItem(
            'Rent Payment',
            'Payment processed successfully',
            Icons.payment,
            AppColors.success,
            '2h ago',
          ),
          const SizedBox(height: AppSpacing.md),
          _buildActivityItem(
            'Maintenance Request',
            'Submitted request for kitchen faucet',
            Icons.build,
            AppColors.warning,
            '1d ago',
          ),
          const SizedBox(height: AppSpacing.md),
          _buildActivityItem(
            'Message from Landlord',
            'New message about property inspection',
            Icons.message,
            AppColors.primaryAccent,
            '3d ago',
          ),
        ],
      ),
    );
  }

  Widget _buildActivityItem(String title, String description, IconData icon, Color color, String time) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),      decoration: BoxDecoration(
        color: AppColors.primaryBackground,
        borderRadius: BorderRadius.circular(12.0),
        boxShadow: [
          BoxShadow(
            color: AppColors.shadowColor,
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(AppSpacing.sm),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12.0),
            ),
            child: Icon(
              icon,
              color: color,
              size: 16.0,
            ),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: AppTypography.body.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Text(
                  description,
                  style: AppTypography.caption,
                ),
              ],
            ),
          ),
          Text(
            time,
            style: AppTypography.caption.copyWith(
              color: AppColors.textSecondary,
            ),
          ),
        ],
      ),
    );  }

  List<Property> _getFilteredProperties(List<Property> properties) {
    // Filter properties based on selected category
    switch (_selectedCategoryIndex) {
      case 0: // All
        return properties;
      case 1: // Apartments
        return properties.where((p) => 
          p.details.amenities.any((amenity) => 
            amenity.toLowerCase().contains('apartment') ||
            p.details.rooms >= 2
          )
        ).toList();
      case 2: // Houses
        return properties.where((p) => 
          p.details.amenities.any((amenity) => 
            amenity.toLowerCase().contains('house') ||
            amenity.toLowerCase().contains('garden') ||
            p.details.rooms >= 4
          )
        ).toList();
      case 3: // Studios
        return properties.where((p) => 
          p.details.rooms <= 2 &&
          p.details.size <= 50
        ).toList();
      default:
        return properties;
    }
  }
}
