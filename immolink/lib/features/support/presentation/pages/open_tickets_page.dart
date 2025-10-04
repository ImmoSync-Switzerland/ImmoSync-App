import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../../core/providers/dynamic_colors_provider.dart';
import '../../domain/models/support_request.dart';
import '../providers/open_support_requests_provider.dart';
import 'package:go_router/go_router.dart';
import 'package:immosync/features/maintenance/presentation/providers/maintenance_providers.dart';
import 'package:immosync/features/maintenance/domain/models/maintenance_request.dart';

class OpenTicketsPage extends ConsumerWidget {
  const OpenTicketsPage({super.key});
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = ref.watch(dynamicColorsProvider);
    final loc = AppLocalizations.of(context)!;
    final supportAsync = ref.watch(openSupportRequestsProvider);
    final maintAsync = ref.watch(landlordMaintenanceRequestsProvider); // adjust for tenant if needed
    return Scaffold(
      backgroundColor: colors.primaryBackground,
      appBar: AppBar(
        title: Text(loc.supportRequests, style: TextStyle(color: colors.textPrimary)),
        backgroundColor: colors.primaryBackground,
        iconTheme: IconThemeData(color: colors.textPrimary),
        actions: [
          IconButton(
            tooltip: 'Refresh',
            onPressed: () {
              ref.invalidate(openSupportRequestsProvider);
              ref.invalidate(landlordMaintenanceRequestsProvider);
            },
            icon: Icon(Icons.refresh, color: colors.textPrimary),
          )
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          ref.invalidate(openSupportRequestsProvider);
          ref.invalidate(landlordMaintenanceRequestsProvider);
          await Future.delayed(const Duration(milliseconds: 300));
        },
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            _sectionHeader(loc.supportRequests, colors),
            supportAsync.when(
              data: (list) => list.isEmpty
                  ? _empty(loc.noSupportRequests, colors)
                  : Column(children: list.map((r)=>_supportCard(context, r, colors, loc)).toList()),
              loading: () => const Padding(
                padding: EdgeInsets.symmetric(vertical: 16),
                child: Center(child: CircularProgressIndicator()),
              ),
              error: (e,st) => _error('${loc.error}: $e', colors),
            ),
            const SizedBox(height: 24),
            _sectionHeader(loc.maintenanceRequests, colors),
            maintAsync.when(
              data: (requests) {
                final filtered = requests.where((m)=> m.status=='pending' || m.status=='in_progress').toList()
                  ..sort((a,b)=>b.createdAt.compareTo(a.createdAt));
                if (filtered.isEmpty) return _empty(loc.noPendingMaintenanceRequests, colors);
                return Column(children: filtered.map((m)=>_maintenanceCard(context, m, colors, loc)).toList());
              },
              loading: () => const Padding(
                padding: EdgeInsets.symmetric(vertical: 16),
                child: Center(child: CircularProgressIndicator()),
              ),
              error: (e,st) => _error('${loc.error}: $e', colors),
            ),
          ],
        ),
      ),
    );
  }

  Widget _sectionHeader(String title, DynamicAppColors colors) => Padding(
    padding: const EdgeInsets.only(bottom: 8),
    child: Text(title, style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: colors.textPrimary)),
  );

  Widget _empty(String msg, DynamicAppColors colors) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 12),
    child: Text(msg, style: TextStyle(color: colors.textSecondary, fontStyle: FontStyle.italic)),
  );

  Widget _error(String msg, DynamicAppColors colors) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 12),
    child: Text(msg, style: TextStyle(color: colors.error)),
  );

  Widget _supportCard(BuildContext context, SupportRequest r, DynamicAppColors colors, AppLocalizations loc) {
    return Card(
      color: colors.surfaceCards,
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        title: Text(r.subject, style: TextStyle(color: colors.textPrimary, fontWeight: FontWeight.w600)),
        subtitle: Text(r.category, style: TextStyle(color: colors.textSecondary, fontSize: 12)),
        trailing: _statusDot(r.status, colors),
        onTap: () => context.push('/support-requests/${r.id}'),
      ),
    );
  }

  Widget _maintenanceCard(BuildContext context, MaintenanceRequest m, DynamicAppColors colors, AppLocalizations loc) {
    return Card(
      color: colors.surfaceCards,
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        title: Text(m.title, style: TextStyle(color: colors.textPrimary, fontWeight: FontWeight.w600)),
        subtitle: Text(m.category, style: TextStyle(color: colors.textSecondary, fontSize: 12)),
        trailing: _statusDot(m.status, colors),
        onTap: () => context.push('/maintenance/${m.id}'),
      ),
    );
  }

  Widget _statusDot(String status, DynamicAppColors colors) {
    Color c;
    switch(status){
      case 'open': c= Colors.orange; break;
      case 'in_progress': c= Colors.blue; break;
      case 'pending': c= Colors.orange; break;
      case 'completed':
      case 'closed': c= Colors.green; break;
      default: c = colors.primaryAccent;
    }
    return Container(width:12,height:12, decoration: BoxDecoration(color: c, shape: BoxShape.circle));
  }
}