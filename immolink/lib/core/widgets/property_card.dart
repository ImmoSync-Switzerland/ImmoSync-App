import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import '../theme/app_spacing.dart';
import '../theme/app_typography.dart';

class PropertyCardData {
  final String id;
  final String title;
  final String location;
  final String distance;
  final double rating;
  final String dates;
  final String price;
  final String imageUrl;
  final bool isWishlisted;

  const PropertyCardData({
    required this.id,
    required this.title,
    required this.location,
    required this.distance,
    required this.rating,
    required this.dates,
    required this.price,
    required this.imageUrl,
    this.isWishlisted = false,
  });
}

class PropertyCard extends StatelessWidget {
  final PropertyCardData property;
  final VoidCallback? onTap;
  final VoidCallback? onWishlistTap;

  const PropertyCard({
    super.key,
    required this.property,
    this.onTap,
    this.onWishlistTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.symmetric(
            horizontal: AppSpacing.horizontalPadding),
        decoration: BoxDecoration(
          color: AppColors.primaryBackground,
          borderRadius: BorderRadius.circular(AppBorderRadius.cardsButtons),
          boxShadow: const [
            BoxShadow(
              color: AppColors.shadowColor,
              blurRadius: 12,
              offset: Offset(0, 4),
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
                  child: Image.network(
                    property.imageUrl,
                    height: AppSizes.propertyCardImageHeight,
                    width: double.infinity,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) => Container(
                      height: AppSizes.propertyCardImageHeight,
                      color: AppColors.surfaceCards,
                      child: const Icon(
                        Icons.image_not_supported,
                        color: AppColors.textPlaceholder,
                        size: AppSizes.iconLarge,
                      ),
                    ),
                  ),
                ),
                // Wishlist button
                Positioned(
                  top: AppSpacing.md,
                  right: AppSpacing.md,
                  child: GestureDetector(
                    onTap: onWishlistTap,
                    child: Container(
                      width: AppSizes.iconLarge,
                      height: AppSizes.iconLarge,
                      decoration: const BoxDecoration(
                        color: AppColors.overlayWhite,
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        property.isWishlisted
                            ? Icons.favorite
                            : Icons.favorite_border,
                        color: property.isWishlisted
                            ? AppColors.error
                            : AppColors.textPrimary,
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
                    property.title,
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
                          '${property.location} • ${property.distance}',
                          style: AppTypography.caption,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: AppSpacing.xs),

                  // Rating
                  Row(
                    children: [
                      const Icon(
                        Icons.star,
                        size: AppSizes.iconSmall,
                        color: AppColors.warning,
                      ),
                      const SizedBox(width: AppSpacing.xs),
                      Text(
                        property.rating.toStringAsFixed(1),
                        style: AppTypography.caption,
                      ),
                    ],
                  ),

                  const SizedBox(height: AppSpacing.xs),

                  // Dates
                  Row(
                    children: [
                      const Icon(
                        Icons.calendar_today_outlined,
                        size: AppSizes.iconSmall,
                        color: AppColors.textSecondary,
                      ),
                      const SizedBox(width: AppSpacing.xs),
                      Text(
                        property.dates,
                        style: AppTypography.caption,
                      ),
                    ],
                  ),

                  const SizedBox(height: AppSpacing.md),

                  // Price
                  Text(
                    property.price,
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
