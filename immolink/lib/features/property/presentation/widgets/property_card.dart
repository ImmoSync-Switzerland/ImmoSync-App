import 'package:flutter/material.dart';
import 'package:immosync/features/property/domain/models/property.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';

class PropertyCard extends StatelessWidget {
  final Property property;
  final VoidCallback onTap;
  final VoidCallback? onWishlistTap;
  final bool isWishlisted;

  const PropertyCard({
    required this.property,
    required this.onTap,
    this.onWishlistTap,
    this.isWishlisted = false,
    Key? key,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: AppSpacing.itemSeparation),
        decoration: BoxDecoration(
          color: AppColors.primaryBackground,
          borderRadius: BorderRadius.circular(AppBorderRadius.cardsButtons),
          boxShadow: [
            BoxShadow(
              color: AppColors.shadowColor,
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Image with wishlist button
            Stack(
              children: [
                ClipRRect(
                  borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(AppBorderRadius.cardsButtons),
                  ),
                  child: Container(
                    height: AppSizes.propertyCardImageHeight,
                    width: double.infinity,
                    color: AppColors.surfaceCards,
                    child: const Icon(
                      Icons.home,
                      color: AppColors.textPlaceholder,
                      size: AppSizes.iconLarge,
                    ),
                  ),
                ),
                // Wishlist button
                if (onWishlistTap != null)
                  Positioned(
                    top: AppSpacing.md,
                    right: AppSpacing.md,
                    child: GestureDetector(
                      onTap: onWishlistTap,
                      child: Container(
                        width: AppSizes.iconLarge,
                        height: AppSizes.iconLarge,
                        decoration: BoxDecoration(
                          color: AppColors.overlayWhite,
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          isWishlisted ? Icons.favorite : Icons.favorite_border,
                          color: isWishlisted ? AppColors.error : AppColors.textPrimary,
                          size: AppSizes.iconSmall,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
            
            // Content
            Padding(
              padding: const EdgeInsets.all(AppSpacing.lg),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Title
                  Text(
                    property.address.street,
                    style: AppTypography.subhead,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  
                  const SizedBox(height: AppSpacing.xs),
                  
                  // Location & Distance
                  Row(
                    children: [
                      const Icon(
                        Icons.location_on_outlined,
                        size: AppSizes.iconSmall,
                        color: AppColors.textSecondary,
                      ),
                      const SizedBox(width: AppSpacing.xs),
                      Expanded(
                        child: Text(
                          '${property.address.city}, ${property.address.postalCode}',
                          style: AppTypography.caption,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                  
                  const SizedBox(height: AppSpacing.xs),
                  
                  // Rating (mock data)
                  Row(
                    children: [
                      const Icon(
                        Icons.star,
                        size: AppSizes.iconSmall,
                        color: AppColors.warning,
                      ),
                      const SizedBox(width: AppSpacing.xs),
                      Text(
                        '4.5', // Mock rating
                        style: AppTypography.caption,
                      ),
                    ],
                  ),
                  
                  const SizedBox(height: AppSpacing.xs),
                  
                  // Dates (mock data)
                  Row(
                    children: [
                      const Icon(
                        Icons.calendar_today_outlined,
                        size: AppSizes.iconSmall,
                        color: AppColors.textSecondary,
                      ),
                      const SizedBox(width: AppSpacing.xs),
                      Text(
                        'Available now', // Mock availability
                        style: AppTypography.caption,
                      ),
                    ],
                  ),
                  
                  const SizedBox(height: AppSpacing.md),
                  
                  // Price
                  Text(
                    '€${property.rentAmount.toStringAsFixed(0)}/month',
                    style: AppTypography.heading2.copyWith(
                      color: AppColors.primaryAccent,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

