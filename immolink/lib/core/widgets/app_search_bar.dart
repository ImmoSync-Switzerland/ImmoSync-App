import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import '../theme/app_spacing.dart';
import '../theme/app_typography.dart';

class AppSearchBar extends StatelessWidget {
  final String hintText;
  final TextEditingController? controller;
  final ValueChanged<String>? onChanged;
  final VoidCallback? onTap;
  final bool readOnly;
  final Widget? prefixIcon;
  final Widget? suffixIcon;

  const AppSearchBar({
    super.key,
    this.hintText = 'Search apart, hotel, etc.',
    this.controller,
    this.onChanged,
    this.onTap,
    this.readOnly = false,
    this.prefixIcon,
    this.suffixIcon,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: AppSizes.searchBarHeight,
      decoration: BoxDecoration(
        color: AppColors.surfaceCards,
        borderRadius:
            BorderRadius.circular(AppSizes.searchBarHeight / 2), // Pill shape
      ),
      child: TextField(
        controller: controller,
        onChanged: onChanged,
        onTap: onTap,
        readOnly: readOnly,
        style: AppTypography.body,
        decoration: InputDecoration(
          hintText: hintText,
          hintStyle: AppTypography.body.copyWith(
            color: AppColors.textPlaceholder,
          ),
          prefixIcon: prefixIcon ??
              const Icon(
                Icons.search,
                size: AppSizes.iconSmall,
                color: AppColors.textPlaceholder,
              ),
          suffixIcon: suffixIcon,
          border: InputBorder.none,
          enabledBorder: InputBorder.none,
          focusedBorder: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.searchBarPadding,
            vertical: 0,
          ),
        ),
      ),
    );
  }
}
