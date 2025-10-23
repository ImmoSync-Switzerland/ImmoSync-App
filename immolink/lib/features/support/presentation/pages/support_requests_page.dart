import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../../core/providers/dynamic_colors_provider.dart';
import '../providers/support_request_providers.dart';
import 'package:go_router/go_router.dart';

class SupportRequestsPage extends ConsumerWidget {
  const SupportRequestsPage({super.key});
  
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = ref.watch(dynamicColorsProvider);
    final asyncData = ref.watch(supportRequestsProvider);
    final loc = AppLocalizations.of(context)!;
    
    return Scaffold(
      backgroundColor: colors.primaryBackground,
      appBar: AppBar(
        title: Text(
          loc.supportRequests,
          style: TextStyle(
            color: colors.textPrimary,
            fontSize: 18,
            fontWeight: FontWeight.w600,
          ),
        ),
        backgroundColor: colors.primaryBackground,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios, color: colors.textPrimary),
          onPressed: () => context.pop(),
        ),
        actions: [
          IconButton(
            tooltip: loc.filter,
            onPressed: () => context.push('/tickets/open'),
            icon: Icon(Icons.filter_list, color: colors.textPrimary),
          )
        ],
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [colors.primaryBackground, colors.surfaceCards],
          ),
        ),
        child: asyncData.when(
          data: (list) => list.isEmpty
              ? _buildEmptyState(loc, colors)
              : RefreshIndicator(
                  onRefresh: () async {
                    ref.invalidate(supportRequestsProvider);
                  },
                  child: ListView.separated(
                    padding: const EdgeInsets.all(16),
                    itemCount: list.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 16),
                    itemBuilder: (ctx, i) {
                      final r = list[i];
                      return _buildRequestCard(ctx, r, colors, loc);
                    },
                  ),
                ),
          loading: () => Center(
            child: CircularProgressIndicator(color: colors.primaryAccent),
          ),
          error: (e, st) => _buildErrorState(e, colors, loc),
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => context.push('/settings/contact-support'),
        backgroundColor: colors.primaryAccent,
        icon: Icon(Icons.add, color: colors.textOnAccent),
        label: Text(
          loc.contactSupport,
          style: TextStyle(color: colors.textOnAccent, fontWeight: FontWeight.w600),
        ),
      ),
    );
  }

  Widget _buildEmptyState(AppLocalizations loc, DynamicAppColors colors) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.support_agent_outlined,
            size: 80,
            color: colors.textSecondary.withValues(alpha: 0.5),
          ),
          const SizedBox(height: 16),
          Text(
            loc.noSupportRequests,
            style: TextStyle(
              color: colors.textSecondary,
              fontSize: 16,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            loc.submitSupportRequest,
            style: TextStyle(
              color: colors.textSecondary.withValues(alpha: 0.7),
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorState(Object error, DynamicAppColors colors, AppLocalizations loc) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline, size: 64, color: colors.error),
            const SizedBox(height: 16),
            Text(
              '${loc.error}: $error',
              style: TextStyle(color: colors.error),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRequestCard(BuildContext context, dynamic request, DynamicAppColors colors, AppLocalizations loc) {
    return Card(
      elevation: 2,
      color: colors.surfaceCards,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: InkWell(
        onTap: () => context.push('/support-requests/${request.id}'),
        borderRadius: BorderRadius.circular(16),
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                colors.surfaceCards,
                colors.surfaceCards.withValues(alpha: 0.8),
              ],
            ),
          ),
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header row with status and priority
                Row(
                  children: [
                    _buildStatusBadge(request.status, colors, loc),
                    const SizedBox(width: 8),
                    _buildPriorityBadge(request.priority, colors),
                    const Spacer(),
                    Icon(
                      Icons.arrow_forward_ios,
                      size: 16,
                      color: colors.textSecondary,
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                // Subject
                Text(
                  request.subject,
                  style: TextStyle(
                    color: colors.textPrimary,
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 8),
                // Category
                Row(
                  children: [
                    Icon(Icons.category_outlined, size: 14, color: colors.textSecondary),
                    const SizedBox(width: 4),
                    Text(
                      request.category,
                      style: TextStyle(
                        color: colors.textSecondary,
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                // Footer with date
                Row(
                  children: [
                    Icon(Icons.access_time, size: 14, color: colors.textSecondary),
                    const SizedBox(width: 4),
                    Text(
                      _formatDate(request.createdAt),
                      style: TextStyle(
                        fontSize: 12,
                        color: colors.textSecondary,
                      ),
                    ),
                    if (request.notes != null && request.notes.isNotEmpty) ...[
                      const SizedBox(width: 16),
                      Icon(Icons.comment_outlined, size: 14, color: colors.textSecondary),
                      const SizedBox(width: 4),
                      Text(
                        '${request.notes.length}',
                        style: TextStyle(
                          fontSize: 12,
                          color: colors.textSecondary,
                        ),
                      ),
                    ],
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildStatusBadge(String status, DynamicAppColors colors, AppLocalizations loc) {
    final statusColor = _statusColor(colors, status);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: statusColor.withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: statusColor, width: 1),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(
              color: statusColor,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 6),
          Text(
            _localizedStatus(loc, status),
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: statusColor,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPriorityBadge(String priority, DynamicAppColors colors) {
    final priorityColor = _priorityColor(priority);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: priorityColor.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        priority,
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w600,
          color: priorityColor,
        ),
      ),
    );
  }

  String _formatDate(DateTime dt) {
    final now = DateTime.now();
    final diff = now.difference(dt);
    
    if (diff.inDays == 0) {
      if (diff.inHours == 0) {
        return '${diff.inMinutes}m ago';
      }
      return '${diff.inHours}h ago';
    } else if (diff.inDays == 1) {
      return 'Yesterday';
    } else if (diff.inDays < 7) {
      return '${diff.inDays}d ago';
    }
    
    return '${dt.day}.${dt.month}.${dt.year}';
  }

  Color _statusColor(DynamicAppColors colors, String status) {
    switch (status.toLowerCase()) {
      case 'open':
        return Colors.orange;
      case 'in_progress':
        return Colors.blue;
      case 'closed':
        return Colors.green;
      default:
        return colors.primaryAccent;
    }
  }

  Color _priorityColor(String priority) {
    switch (priority.toLowerCase()) {
      case 'low':
        return Colors.green;
      case 'medium':
        return Colors.orange;
      case 'high':
        return Colors.red;
      case 'urgent':
        return Colors.purple;
      default:
        return Colors.grey;
    }
  }

  String _localizedStatus(AppLocalizations loc, String status) {
    switch (status.toLowerCase()) {
      case 'open':
        return loc.supportRequestStatusOpen;
      case 'in_progress':
        return loc.supportRequestStatusInProgress;
      case 'closed':
        return loc.supportRequestStatusClosed;
      default:
        return status;
    }
  }
}
