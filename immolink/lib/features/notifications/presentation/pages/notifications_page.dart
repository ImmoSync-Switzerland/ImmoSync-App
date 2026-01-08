import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:immosync/core/theme/app_typography.dart';
import '../providers/notifications_provider.dart';
import '../../domain/models/app_notification.dart';

class NotificationsPage extends ConsumerWidget {
  const NotificationsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return const NotificationsScreen();
  }
}

class NotificationsScreen extends ConsumerStatefulWidget {
  const NotificationsScreen({super.key});

  static const _bgTop = Color(0xFF0A1128);
  static const _bgBottom = Colors.black;
  static const _card = Color(0xFF1C1C1E);
  static const _primaryBlue = Color(0xFF3B82F6);

  @override
  ConsumerState<NotificationsScreen> createState() =>
      _NotificationsScreenState();
}

enum _NotificationType { rent, alert, info }

sealed class _NotificationsListRow {
  const _NotificationsListRow();
}

class _NotificationsHeaderRow extends _NotificationsListRow {
  const _NotificationsHeaderRow(this.title);
  final String title;
}

class _NotificationsItemRow extends _NotificationsListRow {
  const _NotificationsItemRow(this.notification);
  final AppNotification notification;
}

class _NotificationsScreenState extends ConsumerState<NotificationsScreen> {
  @override
  Widget build(BuildContext context) {
    final asyncList = ref.watch(notificationsProvider);
    final topInset = MediaQuery.of(context).padding.top + kToolbarHeight;

    return Scaffold(
      extendBodyBehindAppBar: true,
      extendBody: true,
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        systemOverlayStyle: const SystemUiOverlayStyle(
          statusBarColor: Colors.transparent,
          statusBarIconBrightness: Brightness.light,
          statusBarBrightness: Brightness.dark,
        ),
        surfaceTintColor: Colors.transparent,
        backgroundColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        flexibleSpace: const DecoratedBox(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                NotificationsScreen._bgTop,
                NotificationsScreen._bgBottom
              ],
            ),
          ),
        ),
        title: Text(
          'Notifications',
          style: AppTypography.pageTitle.copyWith(color: Colors.white),
        ),
        leading: IconButton(
          icon: const Icon(Icons.chevron_left, color: Colors.white, size: 32),
          onPressed: () => context.pop(),
        ),
        actions: [
          asyncList.when(
            loading: () => const SizedBox.shrink(),
            error: (_, __) => const SizedBox.shrink(),
            data: (list) {
              final hasUnread = list.any((n) => !n.read);
              return TextButton(
                onPressed: (!hasUnread)
                    ? null
                    : () =>
                        ref.read(notificationsProvider.notifier).markAllRead(),
                style: TextButton.styleFrom(
                  foregroundColor: hasUnread
                      ? NotificationsScreen._primaryBlue
                      : Colors.white54,
                  textStyle: const TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: 13,
                  ),
                ),
                child: const Text('Mark all as read'),
              );
            },
          ),
          const SizedBox(width: 6),
        ],
      ),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [NotificationsScreen._bgTop, NotificationsScreen._bgBottom],
          ),
        ),
        child: Padding(
          padding: EdgeInsets.only(top: topInset),
          child: asyncList.when(
            loading: () => const Center(
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: NotificationsScreen._primaryBlue,
              ),
            ),
            error: (e, _) => Center(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Text(
                  'Failed to load notifications\n$e',
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: Colors.white70,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ),
            data: (list) {
              if (list.isEmpty) return _buildEmptyState();
              final rows = _buildRows(list);
              return ListView.builder(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 120),
                itemCount: rows.length,
                itemBuilder: (context, index) {
                  final row = rows[index];
                  return switch (row) {
                    _NotificationsHeaderRow(:final title) => Padding(
                        padding: const EdgeInsets.fromLTRB(4, 14, 4, 10),
                        child: Text(
                          title,
                          style: const TextStyle(
                            color: Colors.white60,
                            fontWeight: FontWeight.w800,
                            fontSize: 12,
                            letterSpacing: 0.2,
                          ),
                        ),
                      ),
                    _NotificationsItemRow(:final notification) => Padding(
                        padding: const EdgeInsets.only(bottom: 10),
                        child: _buildItem(notification),
                      ),
                  };
                },
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _buildItem(AppNotification n) {
    return InkWell(
      borderRadius: BorderRadius.circular(18),
      onTap: () =>
          ref.read(notificationsProvider.notifier).markSingleRead(n.id),
      child: BentoCard(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _IconBubble(type: _mapType(n.type)),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    n.title,
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w800,
                      fontSize: 14,
                      letterSpacing: -0.1,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    n.body,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: Colors.white60,
                      fontWeight: FontWeight.w600,
                      fontSize: 12,
                      height: 1.35,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 10),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  _formatRelativeTime(n.timestamp),
                  style: const TextStyle(
                    color: Colors.white54,
                    fontWeight: FontWeight.w700,
                    fontSize: 11,
                  ),
                ),
                const SizedBox(height: 10),
                if (!n.read)
                  Container(
                    width: 8,
                    height: 8,
                    decoration: const BoxDecoration(
                      color: NotificationsScreen._primaryBlue,
                      shape: BoxShape.circle,
                    ),
                  )
                else
                  const SizedBox(height: 8, width: 8),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.notifications_off_outlined,
              size: 72,
              color: Colors.white.withValues(alpha: 0.22),
            ),
            const SizedBox(height: 14),
            const Text(
              'No new notifications',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.white70,
                fontWeight: FontWeight.w800,
                fontSize: 16,
                letterSpacing: -0.2,
              ),
            ),
          ],
        ),
      ),
    );
  }

  List<_NotificationsListRow> _buildRows(List<AppNotification> list) {
    if (list.isEmpty) return const [];

    final now = DateTime.now();
    bool isSameDay(DateTime a, DateTime b) =>
        a.year == b.year && a.month == b.month && a.day == b.day;

    final today = <AppNotification>[];
    final yesterday = <AppNotification>[];

    for (final n in list..sort((a, b) => b.timestamp.compareTo(a.timestamp))) {
      if (isSameDay(n.timestamp, now)) {
        today.add(n);
      } else if (isSameDay(
          n.timestamp, now.subtract(const Duration(days: 1)))) {
        yesterday.add(n);
      } else {
        yesterday.add(n);
      }
    }

    final rows = <_NotificationsListRow>[];
    if (today.isNotEmpty) {
      rows.add(const _NotificationsHeaderRow('Today'));
      rows.addAll(today.map(_NotificationsItemRow.new));
    }
    if (yesterday.isNotEmpty) {
      rows.add(const _NotificationsHeaderRow('Yesterday'));
      rows.addAll(yesterday.map(_NotificationsItemRow.new));
    }
    return rows;
  }

  _NotificationType _mapType(String type) {
    final t = type.toLowerCase();
    if (t.contains('rent') || t.contains('payment') || t.contains('invoice')) {
      return _NotificationType.rent;
    }
    if (t.contains('maintenance') ||
        t.contains('alert') ||
        t.contains('urgent')) {
      return _NotificationType.alert;
    }
    return _NotificationType.info;
  }

  String _formatRelativeTime(DateTime dt) {
    final now = DateTime.now();
    final diff = now.difference(dt);
    if (diff.inMinutes < 1) return 'now';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    return '${diff.inDays}d ago';
  }
}

class BentoCard extends StatelessWidget {
  const BentoCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(14),
  });

  final Widget child;
  final EdgeInsets padding;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: padding,
      decoration: BoxDecoration(
        color: NotificationsScreen._card,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.08),
          width: 1,
        ),
      ),
      child: child,
    );
  }
}

class _IconBubble extends StatelessWidget {
  const _IconBubble({required this.type});
  final _NotificationType type;

  @override
  Widget build(BuildContext context) {
    final (Color bg, IconData icon, Color fg) = switch (type) {
      _NotificationType.rent => (
          Colors.green.withValues(alpha: 0.18),
          Icons.attach_money_rounded,
          Colors.greenAccent
        ),
      _NotificationType.alert => (
          Colors.red.withValues(alpha: 0.18),
          Icons.warning_amber_rounded,
          Colors.redAccent
        ),
      _NotificationType.info => (
          NotificationsScreen._primaryBlue.withValues(alpha: 0.18),
          Icons.info_outline_rounded,
          NotificationsScreen._primaryBlue
        ),
    };

    return Container(
      width: 42,
      height: 42,
      decoration: BoxDecoration(
        color: bg,
        shape: BoxShape.circle,
        border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
      ),
      child: Icon(icon, color: fg, size: 20),
    );
  }
}
