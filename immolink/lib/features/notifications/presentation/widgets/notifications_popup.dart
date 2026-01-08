import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../presentation/providers/notifications_provider.dart';
import '../../domain/models/app_notification.dart';

final notificationsPopupVisibleProvider = StateProvider<bool>((_) => false);

class NotificationsPopup extends ConsumerStatefulWidget {
  const NotificationsPopup({super.key});

  @override
  ConsumerState<NotificationsPopup> createState() => _NotificationsPopupState();
}

class _NotificationsPopupState extends ConsumerState<NotificationsPopup>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 160))
      ..forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final asyncList = ref.watch(notificationsProvider);
    final theme = Theme.of(context);
    return FadeTransition(
      opacity: CurvedAnimation(parent: _controller, curve: Curves.easeOut),
      child: ScaleTransition(
        scale: CurvedAnimation(parent: _controller, curve: Curves.easeOutBack),
        child: Material(
          elevation: 10,
          clipBehavior: Clip.antiAlias,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          color: theme.colorScheme.surface,
          child: LayoutBuilder(
            builder: (context, constraints) {
              final screenWidth = MediaQuery.of(context).size.width;
              // Responsive width: on narrow screens use almost full width
              final maxWidth = screenWidth < 500 ? screenWidth - 24 : 420.0;
              final maxHeight = screenWidth < 500
                  ? MediaQuery.of(context).size.height * 0.7
                  : 480.0;
              return ConstrainedBox(
                constraints:
                    BoxConstraints(maxWidth: maxWidth, maxHeight: maxHeight),
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: theme.brightness == Brightness.dark
                          ? [
                              theme.colorScheme.surface,
                              Colors.black.withValues(alpha: 0.4)
                            ]
                          : [
                              theme.colorScheme.surface,
                              theme.colorScheme.surfaceContainerHighest
                                  .withValues(alpha: 0.15)
                            ],
                    ),
                    border: Border.all(
                      color: theme.brightness == Brightness.dark
                          ? Colors.white.withValues(alpha: 0.06)
                          : Colors.black.withValues(alpha: 0.05),
                    ),
                  ),
                  child: asyncList.when(
                    loading: () => _buildSectionWrapper(
                      context,
                      child: const SizedBox(
                          height: 160,
                          child: Center(
                              child:
                                  CircularProgressIndicator(strokeWidth: 2))),
                    ),
                    error: (e, _) => _buildSectionWrapper(
                      context,
                      child: SizedBox(
                        height: 140,
                        child: Center(
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(Icons.error_outline,
                                  size: 32, color: Colors.redAccent),
                              const SizedBox(height: 8),
                              Text('Failed to load',
                                  style: theme.textTheme.titleSmall?.copyWith(
                                    color: theme.colorScheme.onSurface,
                                  )),
                              Text('$e',
                                  style: theme.textTheme.bodySmall?.copyWith(
                                    color: theme.colorScheme.onSurface
                                        .withValues(alpha: 0.7),
                                  )),
                            ],
                          ),
                        ),
                      ),
                    ),
                    data: (list) {
                      if (list.isEmpty) {
                        return _buildSectionWrapper(
                          context,
                          child: SizedBox(
                            height: 160,
                            child: Center(
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(Icons.notifications_off_outlined,
                                      size: 40, color: theme.disabledColor),
                                  const SizedBox(height: 10),
                                  Text('You\'re all caught up',
                                      style:
                                          theme.textTheme.titleSmall?.copyWith(
                                        color: theme.colorScheme.onSurface,
                                      )),
                                  Text('No notifications yet',
                                      style:
                                          theme.textTheme.bodySmall?.copyWith(
                                        color: theme.colorScheme.onSurface
                                            .withValues(alpha: 0.7),
                                      )),
                                ],
                              ),
                            ),
                          ),
                        );
                      }

                      final grouped = _groupByDay(list.take(50).toList());

                      return Column(
                        children: [
                          _HeaderBar(
                              onClose: () => ref
                                  .read(notificationsPopupVisibleProvider
                                      .notifier)
                                  .state = false,
                              ref: ref),
                          const Divider(height: 1),
                          Expanded(
                            child: ScrollConfiguration(
                              behavior: const _NoGlowScrollBehavior(),
                              child: ListView.builder(
                                physics: const AlwaysScrollableScrollPhysics(
                                    parent: BouncingScrollPhysics()),
                                padding:
                                    const EdgeInsets.symmetric(vertical: 8),
                                itemCount: grouped.length,
                                itemBuilder: (context, index) {
                                  final entry = grouped[index];
                                  return _DaySection(
                                    label: entry.label,
                                    notifications: entry.items,
                                    onTap: (n) {
                                      ref
                                          .read(notificationsProvider.notifier)
                                          .markSingleRead(n.id);
                                      ref
                                          .read(
                                              notificationsPopupVisibleProvider
                                                  .notifier)
                                          .state = false;
                                    },
                                  );
                                },
                              ),
                            ),
                          ),
                          _ViewAllButton(onTap: () {
                            ref
                                .read(
                                    notificationsPopupVisibleProvider.notifier)
                                .state = false;
                            if (context.mounted) context.push('/notifications');
                          }),
                        ],
                      );
                    },
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }

  List<_GroupedDay> _groupByDay(List<AppNotification> list) {
    final now = DateTime.now();
    final Map<String, List<AppNotification>> buckets = {};
    for (final n in list) {
      final dt = n.timestamp;
      String label;
      final isToday =
          dt.year == now.year && dt.month == now.month && dt.day == now.day;
      final yesterday = now.subtract(const Duration(days: 1));
      final isYesterday = dt.year == yesterday.year &&
          dt.month == yesterday.month &&
          dt.day == yesterday.day;
      if (isToday) {
        label = 'Today';
      } else if (isYesterday) {
        label = 'Yesterday';
      } else {
        label =
            '${dt.year}/${dt.month.toString().padLeft(2, '0')}/${dt.day.toString().padLeft(2, '0')}';
      }
      buckets.putIfAbsent(label, () => []).add(n);
    }
    final ordered = <_GroupedDay>[];
    for (final key in buckets.keys) {
      ordered.add(_GroupedDay(
          label: key,
          items: buckets[key]!
            ..sort((a, b) => b.timestamp.compareTo(a.timestamp))));
    }
    // Keep relative ordering by newest first across groups
    ordered.sort(
        (a, b) => b.items.first.timestamp.compareTo(a.items.first.timestamp));
    return ordered;
  }

  Widget _buildSectionWrapper(BuildContext context, {required Widget child}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _HeaderBar(
            onClose: () => ref
                .read(notificationsPopupVisibleProvider.notifier)
                .state = false,
            ref: ref),
        const Divider(height: 1),
        Expanded(child: child),
      ],
    );
  }
}

class _HeaderBar extends StatelessWidget {
  final VoidCallback onClose;
  final WidgetRef ref;
  const _HeaderBar({required this.onClose, required this.ref});

  void _handleBack(BuildContext context) {
    final navigator = Navigator.of(context);
    if (navigator.canPop()) {
      navigator.pop();
    } else {
      onClose();
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isLoading = ref.watch(notificationsProvider).isLoading;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: theme.brightness == Brightness.dark
            ? theme.colorScheme.surface.withValues(alpha: 0.92)
            : theme.colorScheme.surface.withValues(alpha: 0.9),
      ),
      child: Row(
        children: [
          IconButton(
            visualDensity: VisualDensity.compact,
            onPressed: () => _handleBack(context),
            icon: Icon(
              Icons.chevron_left,
              size: 18,
              color: theme.colorScheme.onSurface,
            ),
          ),
          const SizedBox(width: 4),
          Icon(Icons.notifications, size: 18, color: theme.colorScheme.primary),
          const SizedBox(width: 8),
          Text('Notifications',
              style: theme.textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.w600,
                color: theme.colorScheme.onSurface,
              )),
          const Spacer(),
          if (isLoading)
            const SizedBox(
              width: 20,
              height: 20,
              child: Padding(
                padding: EdgeInsets.all(2),
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
            )
          else
            Tooltip(
              message: 'Refresh',
              child: IconButton(
                visualDensity: VisualDensity.compact,
                onPressed: () async {
                  final ok =
                      await ref.read(notificationsProvider.notifier).refresh();
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(
                            ok ? 'Notifications refreshed' : 'Refresh failed'),
                        duration: const Duration(seconds: 2),
                      ),
                    );
                  }
                },
                icon: const Icon(Icons.refresh, size: 18),
              ),
            ),
          Tooltip(
            message: 'Mark all read',
            child: IconButton(
              visualDensity: VisualDensity.compact,
              onPressed: () async {
                final updated = await ref
                    .read(notificationsProvider.notifier)
                    .markAllRead();
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(updated > 0
                          ? 'Marked $updated as read'
                          : 'No unread notifications'),
                      duration: const Duration(seconds: 2),
                    ),
                  );
                }
              },
              icon: const Icon(Icons.done_all, size: 18),
            ),
          ),
          Tooltip(
            message: 'Close',
            child: IconButton(
              visualDensity: VisualDensity.compact,
              onPressed: onClose,
              icon: const Icon(Icons.close, size: 18),
            ),
          ),
        ],
      ),
    );
  }
}

class _DaySection extends StatelessWidget {
  final String label;
  final List<AppNotification> notifications;
  final void Function(AppNotification) onTap;
  const _DaySection(
      {required this.label, required this.notifications, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 6, 16, 4),
            child: Text(label,
                style: theme.textTheme.labelMedium?.copyWith(
                  color: theme.colorScheme.primary,
                  letterSpacing: 0.5,
                  fontWeight: FontWeight.w600,
                )),
          ),
          ...notifications
              .map((n) => _NotificationTile(notification: n, onTap: onTap)),
        ],
      ),
    );
  }
}

class _NotificationTile extends StatelessWidget {
  final AppNotification notification;
  final void Function(AppNotification) onTap;
  const _NotificationTile({required this.notification, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final n = notification;
    final iconData = _iconForType(n.type);
    final accent = _colorForType(theme, n.type);
    return InkWell(
      onTap: () => onTap(n),
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: n.read
              ? theme.colorScheme.surface
              : theme.colorScheme.primary.withValues(alpha: 0.06),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
              color:
                  n.read ? theme.dividerColor : accent.withValues(alpha: 0.4)),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                color: accent.withValues(alpha: 0.15),
                shape: BoxShape.circle,
              ),
              child: Icon(iconData, color: accent, size: 18),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          n.title.isEmpty ? '(No title)' : n.title,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: theme.textTheme.bodyMedium?.copyWith(
                            fontWeight:
                                n.read ? FontWeight.w500 : FontWeight.w600,
                            color: theme.colorScheme.onSurface,
                          ),
                        ),
                      ),
                      const SizedBox(width: 6),
                      Text(_formatTime(n.timestamp),
                          style: theme.textTheme.labelSmall?.copyWith(
                            color: theme.colorScheme.onSurface
                                .withValues(alpha: 0.6),
                          )),
                    ],
                  ),
                  if (n.body.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.only(top: 4),
                      child: Text(
                        n.body,
                        maxLines: 3,
                        overflow: TextOverflow.ellipsis,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onSurface
                              .withValues(alpha: 0.85),
                          height: 1.4,
                        ),
                      ),
                    ),
                  if (!n.read)
                    Padding(
                      padding: const EdgeInsets.only(top: 6),
                      child: Row(
                        children: [
                          Container(
                            width: 6,
                            height: 6,
                            decoration: BoxDecoration(
                                color: accent, shape: BoxShape.circle),
                          ),
                          const SizedBox(width: 6),
                          Text('Unread',
                              style: theme.textTheme.labelSmall
                                  ?.copyWith(color: accent)),
                        ],
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

  IconData _iconForType(String type) {
    switch (type) {
      case 'payment_reminder':
        return Icons.payment_outlined;
      case 'maintenance_request':
        return Icons.build_circle_outlined;
      case 'warning':
        return Icons.warning_amber_outlined;
      case 'success':
        return Icons.check_circle_outline;
      case 'chat':
        return Icons.chat_bubble_outline;
      default:
        return Icons.notifications_active_outlined;
    }
  }

  Color _colorForType(ThemeData theme, String type) {
    switch (type) {
      case 'payment_reminder':
        return Colors.orangeAccent;
      case 'maintenance_request':
        return Colors.teal;
      case 'warning':
        return Colors.redAccent;
      case 'success':
        return Colors.green;
      case 'chat':
        return theme.colorScheme.primary;
      default:
        return theme.colorScheme.primary;
    }
  }
}

class _ViewAllButton extends StatelessWidget {
  final VoidCallback onTap;
  const _ViewAllButton({required this.onTap});
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return InkWell(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 14),
        decoration: BoxDecoration(
          border: Border(
              top: BorderSide(
                  color: theme.dividerColor.withValues(
                      alpha: theme.brightness == Brightness.dark ? 0.4 : 1))),
        ),
        child: Center(
          child: Text('View all notifications',
              style: theme.textTheme.labelLarge?.copyWith(
                color: theme.colorScheme.primary,
                fontWeight: FontWeight.w600,
              )),
        ),
      ),
    );
  }
}

class _GroupedDay {
  final String label;
  final List<AppNotification> items;
  _GroupedDay({required this.label, required this.items});
}

class _NoGlowScrollBehavior extends ScrollBehavior {
  const _NoGlowScrollBehavior();
  @override
  Widget buildOverscrollIndicator(
          BuildContext context, Widget child, ScrollableDetails details) =>
      child;
}

String _formatTime(DateTime dt) {
  final now = DateTime.now();
  final diff = now.difference(dt);
  if (diff.inMinutes < 1) return 'now';
  if (diff.inMinutes < 60) return '${diff.inMinutes}m';
  if (diff.inHours < 24) return '${diff.inHours}h';
  if (diff.inDays < 7) return '${diff.inDays}d';
  return '${dt.month}/${dt.day}';
}
