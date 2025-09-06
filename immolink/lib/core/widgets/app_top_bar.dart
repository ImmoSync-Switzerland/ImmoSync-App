import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:immosync/features/notifications/presentation/widgets/notifications_popup.dart';
import 'package:immosync/features/notifications/presentation/providers/notifications_provider.dart';
import '../theme/app_colors.dart';
import '../theme/app_colors_dark.dart';
import '../theme/app_spacing.dart';
import '../theme/app_typography.dart';

class AppTopBar extends ConsumerStatefulWidget implements PreferredSizeWidget {
  final String? title;
  final String? location;
  final VoidCallback? onLocationTap;
  final VoidCallback? onNotificationTap;
  final VoidCallback? onRefresh;
  final Widget? leading;
  final bool showNotification;
  final bool showLocation;
  final bool showRefresh;

  const AppTopBar({
    super.key,
    this.title,
    this.location,
    this.onLocationTap,
    this.onNotificationTap,
    this.onRefresh,
    this.leading,
    this.showNotification = true,
    this.showLocation = false,
    this.showRefresh = false,
  });

  @override
  ConsumerState<AppTopBar> createState() => _AppTopBarState();

  @override
  Size get preferredSize => const Size.fromHeight(AppSizes.topAppBarHeight);
}

class _AppTopBarState extends ConsumerState<AppTopBar> {
  final GlobalKey _bellKey = GlobalKey();
  OverlayEntry? _notificationsOverlay;

  @override
  void initState() {
    super.initState();
  }

  void _togglePopup() {
  final visible = ref.read(notificationsPopupVisibleProvider);
  ref.read(notificationsPopupVisibleProvider.notifier).state = !visible;
  }

  void _showNotificationsOverlay() {
    if (_notificationsOverlay != null) return;
    final overlay = Overlay.of(context);
    _notificationsOverlay = OverlayEntry(
      builder: (context) {
        return Stack(
          children: [
            // Opaque barrier to block interactions behind and close on tap outside
            Positioned.fill(
              child: GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: () {
                  // Close via provider; listener will hide overlay
                  ref.read(notificationsPopupVisibleProvider.notifier).state = false;
                },
                child: const SizedBox.expand(),
              ),
            ),
            // Anchor popup below the app bar, aligned to right
            Positioned(
              top: AppSizes.topAppBarHeight + 4,
              right: 8,
              child: const NotificationsPopup(),
            ),
          ],
        );
      },
    );
    overlay.insert(_notificationsOverlay!);
  }

  void _hideNotificationsOverlay() {
    _notificationsOverlay?.remove();
    _notificationsOverlay = null;
  }

  @override
  void dispose() {
    _hideNotificationsOverlay();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Listen during build so Riverpod can manage the subscription lifecycle
    ref.listen<bool>(notificationsPopupVisibleProvider, (prev, next) {
      if (!mounted) return;
      if (next) {
        _showNotificationsOverlay();
      } else {
        _hideNotificationsOverlay();
      }
    });

    final popupVisible = ref.watch(notificationsPopupVisibleProvider);
    final notificationsAsync = ref.watch(notificationsProvider);
    final unreadCount = notificationsAsync.maybeWhen(
      data: (list) => list.where((n) => !n.read).length,
      orElse: () => 0,
    );
    return Stack(
      clipBehavior: Clip.none,
      children: [
        Container(
          height: AppSizes.topAppBarHeight,
          decoration: BoxDecoration(
            color: Theme.of(context).brightness == Brightness.dark
                ? AppColorsDark.appBarBackground
                : AppColors.primaryBackground,
            border: Border(
              bottom: BorderSide(
                color: Theme.of(context).brightness == Brightness.dark
                    ? AppColorsDark.dividerSeparator
                    : AppColors.dividerSeparator,
                width: 1,
              ),
            ),
          ),
          child: SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.horizontalPadding),
              child: Row(
                children: [
                  // Left: Hamburger or Back icon
                  if (widget.leading != null) ...[
                    widget.leading!
                  ] else if (widget.showRefresh) ...[
                    IconButton(
                      onPressed: widget.onRefresh,
                      icon: Icon(
                        Icons.refresh,
                        size: AppSizes.iconMedium,
                        color: Theme.of(context).brightness == Brightness.dark
                            ? AppColorsDark.textPrimary
                            : AppColors.textPrimary,
                      ),
                      tooltip: 'Refresh',
                    ),
                  ] else ...[
                    const SizedBox(
                        width:
                            AppSizes.iconMedium + 16), // spacer to keep layout
                  ],

                  // Center: Title or Location
                  Expanded(
                    child: Center(
                      child: widget.showLocation && widget.location != null
                          ? GestureDetector(
                              onTap: widget.onLocationTap,
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Text(
                                    widget.location!,
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
                          : widget.title != null
                              ? Text(
                                  widget.title!,
                                  style: AppTypography.subhead,
                                )
                              : const SizedBox.shrink(),
                    ),
                  ),

                  // Right: Notification bell
                  if (widget.showNotification)
                    Stack(
                      clipBehavior: Clip.none,
                      children: [
                        IconButton(
                          key: _bellKey,
                          onPressed: widget.onNotificationTap ?? _togglePopup,
                          icon: Icon(
                            popupVisible
                                ? Icons.notifications
                                : Icons.notifications_outlined,
                            size: AppSizes.iconMedium,
                            color:
                                Theme.of(context).brightness == Brightness.dark
                                    ? AppColorsDark.textPrimary
                                    : AppColors.textPrimary,
                          ),
                        ),
                        if (unreadCount > 0)
                          Positioned(
                            right: 6,
                            top: 6,
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 5, vertical: 2),
                              decoration: BoxDecoration(
                                color: Colors.redAccent,
                                borderRadius: BorderRadius.circular(10),
                              ),
                              constraints: const BoxConstraints(minWidth: 18),
                              child: Text(
                                unreadCount > 99
                                    ? '99+'
                                    : unreadCount.toString(),
                                textAlign: TextAlign.center,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ),
                      ],
                    ),
                ],
              ),
            ),
          ),
        ), // end Container
  // Popup is rendered via OverlayEntry now; nothing to render here
      ],
    );
  }
}
