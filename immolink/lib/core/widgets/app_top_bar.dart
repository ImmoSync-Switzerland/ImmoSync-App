import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../theme/app_colors.dart';
import '../theme/app_spacing.dart';
import '../theme/app_typography.dart';

class AppTopBar extends StatelessWidget implements PreferredSizeWidget {
  final String? title;
  final String? location;
  final VoidCallback? onLocationTap;
  final VoidCallback? onNotificationTap;
  final Widget? leading;
  final bool showNotification;
  final bool showLocation;

  const AppTopBar({
    super.key,
    this.title,
    this.location,
    this.onLocationTap,
    this.onNotificationTap,
    this.leading,
    this.showNotification = true,
    this.showLocation = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: AppSizes.topAppBarHeight,
      decoration: const BoxDecoration(
        color: AppColors.primaryBackground,
        border: Border(
          bottom: BorderSide(
            color: AppColors.dividerSeparator,
            width: 1,
          ),
        ),
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.horizontalPadding),
          child: Row(
            children: [
              // Left: Hamburger or Back icon
              if (leading != null)
                leading!
              else
                IconButton(
                  onPressed: () => Scaffold.of(context).openDrawer(),
                  icon: const Icon(
                    Icons.menu,
                    size: AppSizes.iconMedium,
                    color: AppColors.textPrimary,
                  ),
                ),
              
              // Center: Title or Location
              Expanded(
                child: Center(
                  child: showLocation && location != null
                      ? GestureDetector(
                          onTap: onLocationTap,
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                location!,
                                style: AppTypography.body,
                              ),
                              const SizedBox(width: AppSpacing.xs),
                              const Icon(
                                Icons.keyboard_arrow_down,
                                size: AppSizes.iconSmall,
                                color: AppColors.textSecondary,
                              ),
                            ],
                          ),
                        )
                      : title != null
                          ? Text(
                              title!,
                              style: AppTypography.subhead,
                            )
                          : const SizedBox.shrink(),
                ),
              ),
              
              // Right: Notification bell
              if (showNotification)
                IconButton(
                  onPressed: onNotificationTap ?? () => context.push('/notifications'),
                  icon: const Icon(
                    Icons.notifications_outlined,
                    size: AppSizes.iconMedium,
                    color: AppColors.textPrimary,
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Size get preferredSize => const Size.fromHeight(AppSizes.topAppBarHeight);
}
