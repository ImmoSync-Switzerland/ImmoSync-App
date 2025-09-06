import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import '../theme/app_spacing.dart';
import '../theme/app_typography.dart';

class CategoryTab {
  final String label;
  final IconData? icon;
  final String? badge;

  const CategoryTab({
    required this.label,
    this.icon,
    this.badge,
  });
}

class CategoryTabs extends StatelessWidget {
  final List<CategoryTab> tabs;
  final int selectedIndex;
  final ValueChanged<int> onTabSelected;
  final bool scrollable;

  const CategoryTabs({
    super.key,
    required this.tabs,
    required this.selectedIndex,
    required this.onTabSelected,
    this.scrollable = true,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 48,
      padding:
          const EdgeInsets.symmetric(vertical: AppSpacing.tabVerticalPadding),
      child: scrollable
          ? ListView.separated(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.horizontalPadding),
              itemCount: tabs.length,
              separatorBuilder: (context, index) =>
                  const SizedBox(width: AppSpacing.sm),
              itemBuilder: (context, index) => _buildTab(index),
            )
          : Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: tabs
                  .asMap()
                  .entries
                  .map((entry) => _buildTab(entry.key))
                  .toList(),
            ),
    );
  }

  Widget _buildTab(int index) {
    final tab = tabs[index];
    final isSelected = index == selectedIndex;

    return GestureDetector(
      onTap: () => onTabSelected(index),
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.lg,
          vertical: AppSpacing.sm,
        ),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.accentLight : AppColors.surfaceCards,
          borderRadius: BorderRadius.circular(AppBorderRadius.cardsButtons),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (tab.icon != null) ...[
              Icon(
                tab.icon,
                size: AppSizes.iconSmall,
                color: isSelected
                    ? AppColors.primaryAccent
                    : AppColors.textSecondary,
              ),
              const SizedBox(width: AppSpacing.xs),
            ],
            Text(
              tab.label,
              style: isSelected
                  ? AppTypography.tabActive
                  : AppTypography.tabInactive,
            ),
            if (tab.badge != null) ...[
              const SizedBox(width: AppSpacing.xs),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.xs,
                  vertical: 2,
                ),
                decoration: BoxDecoration(
                  color: isSelected
                      ? AppColors.primaryAccent
                      : AppColors.textSecondary,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  tab.badge!,
                  style: AppTypography.caption.copyWith(
                    color: Colors.white,
                    fontSize: 10,
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
