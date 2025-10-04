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
  AppLocalizations.of(context)!; // ensure localization loaded (reserved for future use)
  final asyncData = ref.watch(supportRequestsProvider);
  final loc = AppLocalizations.of(context)!;
    return Scaffold(
      backgroundColor: colors.primaryBackground,
    appBar: AppBar(
  title: Text(loc.supportRequests, style: TextStyle(color: colors.textPrimary)),
        backgroundColor: colors.primaryBackground,
        elevation: 0,
        iconTheme: IconThemeData(color: colors.textPrimary),
        actions: [
          IconButton(
            tooltip: 'Open Tickets',
            onPressed: () => context.push('/tickets/open'),
            icon: Icon(Icons.filter_list, color: colors.textPrimary),
          )
        ],
      ),
      body: asyncData.when(
    data: (list) => list.isEmpty
      ? Center(child: Text(loc.noSupportRequests, style: TextStyle(color: colors.textSecondary)))
            : ListView.separated(
                padding: const EdgeInsets.all(16),
                itemCount: list.length,
                separatorBuilder: (_, __) => const SizedBox(height: 12),
                itemBuilder: (ctx, i) {
                  final r = list[i];
                  return Card(
                    color: colors.surfaceCards,
                    child: ListTile(
                      title: Text(r.subject, style: TextStyle(color: colors.textPrimary, fontWeight: FontWeight.w600)),
                      subtitle: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(r.category, style: TextStyle(color: colors.textSecondary, fontSize: 12)),
                          const SizedBox(height:4),
                          Row(
                            children: [
                              _badge(_localizedStatus(context, r.status), _statusColor(colors, r.status), colors),
                              const SizedBox(width: 8),
                              _badge(r.priority, _priorityColor(r.priority), colors, outline: true),
                            ],
                          )
                        ],
                      ),
                      trailing: Text(
                        _formatDate(r.createdAt),
                        style: TextStyle(fontSize: 12, color: colors.textSecondary),
                      ),
                      onTap: () => context.push('/support-requests/${r.id}'),
                    ),
                  );
                },
              ),
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, st) => Center(child: Text('${loc.error}: $e', style: TextStyle(color: colors.error))),
      ),
    );
  }

  String _formatDate(DateTime dt) {
    return '${dt.year}-${dt.month.toString().padLeft(2,'0')}-${dt.day.toString().padLeft(2,'0')}';
  }

  Widget _badge(String text, Color bg, DynamicAppColors colors, {bool outline=false}) {
    final style = TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: outline ? bg : colors.textOnAccent);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: outline ? Colors.transparent : bg,
        borderRadius: BorderRadius.circular(12),
        border: outline ? Border.all(color: bg, width: 1) : null,
      ),
      child: Text(text, style: style),
    );
  }

  Color _statusColor(DynamicAppColors colors, String status) {
    switch (status) {
      case 'open': return Colors.orange;
      case 'in_progress': return Colors.blue;
      case 'closed': return Colors.green;
      default: return colors.primaryAccent;
    }
  }

  Color _priorityColor(String priority) {
    switch (priority.toLowerCase()) {
      case 'low': return Colors.green;
      case 'medium': return Colors.orange;
      case 'high': return Colors.red;
      case 'urgent': return Colors.purple;
      default: return Colors.grey;
    }
  }

  String _localizedStatus(BuildContext context, String status) {
    final l = AppLocalizations.of(context)!;
    switch (status) {
      case 'open': return l.supportRequestStatusOpen;
      case 'in_progress': return l.supportRequestStatusInProgress;
      case 'closed': return l.supportRequestStatusClosed;
      default: return status;
    }
  }
}