import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:immosync/core/providers/dynamic_colors_provider.dart';
import 'package:immosync/features/home/presentation/models/dashboard_design.dart';
import 'package:immosync/features/home/presentation/pages/glass_dashboard_shared.dart';
import 'package:immosync/features/maintenance/domain/models/maintenance_request.dart';
import 'package:immosync/features/maintenance/presentation/providers/maintenance_providers.dart';
import 'package:immosync/features/settings/providers/settings_provider.dart';
import 'package:immosync/l10n/app_localizations.dart';

class TenantMaintenanceRequestsPage extends ConsumerWidget {
  const TenantMaintenanceRequestsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = ref.watch(dynamicColorsProvider);
    final l10n = AppLocalizations.of(context)!;
    final design =
        dashboardDesignFromId(ref.watch(settingsProvider).dashboardDesign);
    final bool glassMode = design == DashboardDesign.glass;
    final maintenanceRequestsAsync =
        ref.watch(tenantMaintenanceRequestsProvider);

    if (glassMode) {
      return _buildGlassScaffold(
        context,
        ref,
        maintenanceRequestsAsync,
        colors,
        l10n,
      );
    }

    return _buildClassicScaffold(
      context,
      ref,
      maintenanceRequestsAsync,
      colors,
      l10n,
    );
  }

  Widget _buildGlassScaffold(
    BuildContext context,
    WidgetRef ref,
    AsyncValue<List<MaintenanceRequest>> requestsAsync,
    DynamicAppColors colors,
    AppLocalizations l10n,
  ) {
    return requestsAsync.when(
      data: (requests) => GlassPageScaffold(
        title: l10n.myMaintenanceRequests,
        showBottomNav: false,
        onBack: () => _handleBackNavigation(context),
        floatingActionButton:
            _buildFloatingActionButton(context, colors, glassMode: true),
        body: requests.isEmpty
            ? _buildEmptyState(
                context,
                glassMode: true,
                colors: colors,
                l10n: l10n,
              )
            : _buildRequestsList(
                context,
                ref,
                requests,
                glassMode: true,
                colors: colors,
                l10n: l10n,
              ),
      ),
      loading: () => GlassPageScaffold(
        title: l10n.myMaintenanceRequests,
        showBottomNav: false,
        onBack: () => _handleBackNavigation(context),
        floatingActionButton:
            _buildFloatingActionButton(context, colors, glassMode: true),
        body: const Center(
          child: CircularProgressIndicator(
            valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
          ),
        ),
      ),
      error: (error, stackTrace) => GlassPageScaffold(
        title: l10n.myMaintenanceRequests,
        showBottomNav: false,
        onBack: () => _handleBackNavigation(context),
        floatingActionButton:
            _buildFloatingActionButton(context, colors, glassMode: true),
        body: _buildErrorState(
          context,
          ref,
          error.toString(),
          glassMode: true,
          colors: colors,
          l10n: l10n,
        ),
      ),
    );
  }

  Widget _buildClassicScaffold(
    BuildContext context,
    WidgetRef ref,
    AsyncValue<List<MaintenanceRequest>> requestsAsync,
    DynamicAppColors colors,
    AppLocalizations l10n,
  ) {
    return Scaffold(
      backgroundColor: colors.primaryBackground,
      appBar: AppBar(
        backgroundColor: colors.primaryBackground,
        surfaceTintColor: colors.primaryBackground,
        elevation: 0,
        title: Text(
          l10n.myMaintenanceRequests,
          style: TextStyle(
            color: colors.textPrimary,
            fontWeight: FontWeight.w600,
            fontSize: 18,
          ),
        ),
        leading: IconButton(
          icon: Icon(
            Icons.chevron_left,
            color: colors.textPrimary,
            size: 32,
          ),
          onPressed: () => _handleBackNavigation(context),
        ),
      ),
      body: requestsAsync.when(
        data: (requests) => requests.isEmpty
            ? _buildEmptyState(
                context,
                glassMode: false,
                colors: colors,
                l10n: l10n,
              )
            : _buildRequestsList(
                context,
                ref,
                requests,
                glassMode: false,
                colors: colors,
                l10n: l10n,
              ),
        loading: () => Center(
          child: CircularProgressIndicator(
            valueColor: AlwaysStoppedAnimation<Color>(colors.primaryAccent),
          ),
        ),
        error: (error, stackTrace) => _buildErrorState(
          context,
          ref,
          error.toString(),
          glassMode: false,
          colors: colors,
          l10n: l10n,
        ),
      ),
      floatingActionButton:
          _buildFloatingActionButton(context, colors, glassMode: false),
    );
  }

  Widget _buildRequestsList(
    BuildContext context,
    WidgetRef ref,
    List<MaintenanceRequest> requests, {
    required bool glassMode,
    required DynamicAppColors colors,
    required AppLocalizations l10n,
  }) {
    final scrollPhysics = glassMode
        ? const BouncingScrollPhysics(
            parent: AlwaysScrollableScrollPhysics(),
          )
        : const AlwaysScrollableScrollPhysics();

    final listView = ListView.separated(
      physics: scrollPhysics,
      padding: glassMode
          ? const EdgeInsets.only(bottom: 140)
          : const EdgeInsets.fromLTRB(20, 12, 20, 120),
      itemCount: requests.length,
      separatorBuilder: (_, __) => SizedBox(height: glassMode ? 18 : 12),
      itemBuilder: (context, index) => _buildRequestCard(
        context,
        requests[index],
        glassMode: glassMode,
        colors: colors,
        l10n: l10n,
      ),
    );

    return RefreshIndicator(
      onRefresh: () async {
        ref.invalidate(tenantMaintenanceRequestsProvider);
      },
      color: glassMode ? Colors.white : colors.primaryAccent,
      backgroundColor: glassMode ? Colors.black.withValues(alpha: 0.32) : null,
      child: listView,
    );
  }

  Widget _buildRequestCard(
    BuildContext context,
    MaintenanceRequest request, {
    required bool glassMode,
    required DynamicAppColors colors,
    required AppLocalizations l10n,
  }) {
    final titleStyle = glassMode
        ? GoogleFonts.poppins(
            color: Colors.white,
            fontSize: 16,
            fontWeight: FontWeight.w600,
            letterSpacing: -0.2,
          )
        : TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w600,
            color: colors.textPrimary,
          );

    final descriptionStyle = glassMode
        ? GoogleFonts.poppins(
            color: Colors.white.withValues(alpha: 0.78),
            fontSize: 13,
            height: 1.4,
          )
        : TextStyle(
            fontSize: 13,
            color: colors.textSecondary,
            height: 1.4,
          );

    final metaStyle = glassMode
        ? GoogleFonts.poppins(
            color: Colors.white.withValues(alpha: 0.75),
            fontSize: 12,
          )
        : TextStyle(
            fontSize: 12,
            color: colors.textSecondary,
          );

    final categoryIconColor =
        glassMode ? colors.luxuryGold : colors.primaryAccent;

    final content = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            _buildStatusChip(
              context,
              request.status,
              glassMode: glassMode,
              colors: colors,
              l10n: l10n,
            ),
            _buildPriorityChip(
              context,
              request.priority,
              glassMode: glassMode,
              colors: colors,
              l10n: l10n,
            ),
          ],
        ),
        const SizedBox(height: 14),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(
              _getCategoryIcon(request.category),
              size: 20,
              color: categoryIconColor,
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                request.title,
                style: titleStyle,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
        if (request.description.isNotEmpty) ...[
          const SizedBox(height: 10),
          Text(
            request.description,
            style: descriptionStyle,
            maxLines: 3,
            overflow: TextOverflow.ellipsis,
          ),
        ],
        const SizedBox(height: 14),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              '${l10n.created}: ${_formatDate(request.requestedDate, l10n)}',
              style: metaStyle,
            ),
            if (request.completedDate != null &&
                request.completedDate != request.requestedDate)
              Text(
                '${l10n.updated}: ${_formatDate(request.completedDate!, l10n)}',
                style: metaStyle,
              ),
          ],
        ),
      ],
    );

    if (glassMode) {
      return GestureDetector(
        onTap: () => context.push('/maintenance/${request.id}'),
        child: GlassContainer(
          padding: EdgeInsets.zero,
          child: Container(
            decoration: BoxDecoration(
              color: Colors.black.withValues(alpha: 0.35),
              borderRadius: BorderRadius.circular(24),
              border: Border.all(
                color: Colors.white.withValues(alpha: 0.28),
              ),
            ),
            padding: const EdgeInsets.all(20),
            child: content,
          ),
        ),
      );
    }

    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () => context.push('/maintenance/${request.id}'),
        child: Container(
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            color: colors.surfaceCards,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: colors.borderLight),
            boxShadow: [
              BoxShadow(
                color: colors.shadowColor.withValues(alpha: 0.12),
                blurRadius: 18,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: content,
        ),
      ),
    );
  }

  Widget _buildErrorState(
    BuildContext context,
    WidgetRef ref,
    String error, {
    required bool glassMode,
    required DynamicAppColors colors,
    required AppLocalizations l10n,
  }) {
    final Widget content = Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(
          Icons.error_outline,
          size: 52,
          color: glassMode ? Colors.white : colors.error,
        ),
        const SizedBox(height: 16),
        Text(
          l10n.errorLoadingRequests,
          textAlign: TextAlign.center,
          style: glassMode
              ? GoogleFonts.poppins(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                )
              : TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: colors.textPrimary,
                ),
        ),
        const SizedBox(height: 8),
        Text(
          error,
          textAlign: TextAlign.center,
          style: glassMode
              ? GoogleFonts.poppins(
                  color: Colors.white.withValues(alpha: 0.8),
                  fontSize: 13,
                )
              : TextStyle(
                  fontSize: 13,
                  color: colors.textSecondary,
                ),
        ),
        const SizedBox(height: 20),
        ElevatedButton(
          onPressed: () => ref.invalidate(tenantMaintenanceRequestsProvider),
          style: glassMode
              ? ElevatedButton.styleFrom(
                  backgroundColor: Colors.white.withValues(alpha: 0.2),
                  foregroundColor: Colors.white,
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                    side: BorderSide(
                      color: Colors.white.withValues(alpha: 0.35),
                    ),
                  ),
                )
              : null,
          child: Text(l10n.retry),
        ),
      ],
    );

    if (glassMode) {
      return Center(
        child: GlassContainer(
          padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 24),
          child: content,
        ),
      );
    }

    return Center(
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 24),
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
        decoration: BoxDecoration(
          color: colors.surfaceCards,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: colors.shadowColor.withValues(alpha: 0.12),
              blurRadius: 20,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: content,
      ),
    );
  }

  Widget _buildEmptyState(
    BuildContext context, {
    required bool glassMode,
    required DynamicAppColors colors,
    required AppLocalizations l10n,
  }) {
    final Widget content = Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(
          Icons.build_circle_outlined,
          size: 60,
          color: glassMode
              ? Colors.white
              : colors.textSecondary.withValues(alpha: 0.8),
        ),
        const SizedBox(height: 18),
        Text(
          l10n.noMaintenanceRequests,
          textAlign: TextAlign.center,
          style: glassMode
              ? GoogleFonts.poppins(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                )
              : TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: colors.textPrimary,
                ),
        ),
        const SizedBox(height: 10),
        Text(
          l10n.noMaintenanceRequestsDescription,
          textAlign: TextAlign.center,
          style: glassMode
              ? GoogleFonts.poppins(
                  color: Colors.white.withValues(alpha: 0.82),
                  fontSize: 13,
                  height: 1.4,
                )
              : TextStyle(
                  fontSize: 14,
                  color: colors.textSecondary,
                  height: 1.4,
                ),
        ),
        const SizedBox(height: 26),
        ElevatedButton.icon(
          onPressed: () => context.push('/maintenance/request'),
          icon: const Icon(Icons.add),
          label: Text(l10n.createRequest),
          style: glassMode
              ? ElevatedButton.styleFrom(
                  backgroundColor: Colors.white.withValues(alpha: 0.22),
                  foregroundColor: Colors.white,
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                    side: BorderSide(
                      color: Colors.white.withValues(alpha: 0.35),
                    ),
                  ),
                )
              : ElevatedButton.styleFrom(
                  backgroundColor: colors.primaryAccent,
                  foregroundColor: colors.textOnAccent,
                ),
        ),
      ],
    );

    if (glassMode) {
      return Center(
        child: GlassContainer(
          padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 32),
          child: content,
        ),
      );
    }

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: content,
      ),
    );
  }

  Widget _buildStatusChip(
    BuildContext context,
    String status, {
    required bool glassMode,
    required DynamicAppColors colors,
    required AppLocalizations l10n,
  }) {
    final Color accent = _statusAccentColor(status, colors);
    final String label = _getStatusText(status, l10n);

    if (glassMode) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: accent.withValues(alpha: 0.18),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: accent.withValues(alpha: 0.45)),
        ),
        child: Text(
          label.toUpperCase(),
          style: GoogleFonts.poppins(
            color: Colors.white,
            fontSize: 11,
            fontWeight: FontWeight.w600,
            letterSpacing: 0.4,
          ),
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: accent.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w600,
          color: accent,
        ),
      ),
    );
  }

  Widget _buildPriorityChip(
    BuildContext context,
    String priority, {
    required bool glassMode,
    required DynamicAppColors colors,
    required AppLocalizations l10n,
  }) {
    final Color accent = _priorityAccentColor(priority, colors);
    final String label = _getPriorityText(priority, l10n);

    if (glassMode) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: accent.withValues(alpha: 0.2),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: accent.withValues(alpha: 0.45)),
        ),
        child: Text(
          label.toUpperCase(),
          style: GoogleFonts.poppins(
            color: Colors.white,
            fontSize: 11,
            fontWeight: FontWeight.w600,
            letterSpacing: 0.4,
          ),
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: accent.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w600,
          color: accent,
        ),
      ),
    );
  }

  Widget _buildFloatingActionButton(
    BuildContext context,
    DynamicAppColors colors, {
    required bool glassMode,
  }) {
    final Color background =
        glassMode ? Colors.white.withValues(alpha: 0.9) : colors.primaryAccent;
    final Color foreground = glassMode ? Colors.black87 : colors.textOnAccent;

    return FloatingActionButton(
      backgroundColor: background,
      foregroundColor: foreground,
      elevation: glassMode ? 4 : 2,
      onPressed: () => context.push('/maintenance/request'),
      child: const Icon(Icons.add),
    );
  }

  void _handleBackNavigation(BuildContext context) {
    final navigator = Navigator.of(context);
    if (navigator.canPop()) {
      navigator.pop();
    } else {
      context.go('/home');
    }
  }

  Color _statusAccentColor(String status, DynamicAppColors colors) {
    switch (status.toLowerCase()) {
      case 'pending':
        return colors.warning;
      case 'in_progress':
        return colors.info;
      case 'completed':
        return colors.success;
      case 'cancelled':
        return colors.error;
      default:
        return colors.textSecondary;
    }
  }

  Color _priorityAccentColor(String priority, DynamicAppColors colors) {
    switch (priority.toLowerCase()) {
      case 'high':
        return colors.error;
      case 'medium':
        return colors.warning;
      case 'low':
        return colors.success;
      default:
        return colors.textSecondary;
    }
  }

  IconData _getCategoryIcon(String category) {
    switch (category.toLowerCase()) {
      case 'plumbing':
        return Icons.plumbing;
      case 'electrical':
        return Icons.electrical_services;
      case 'heating':
        return Icons.thermostat;
      case 'appliance':
        return Icons.kitchen;
      case 'structural':
        return Icons.foundation;
      case 'cleaning':
        return Icons.cleaning_services;
      case 'pest':
        return Icons.bug_report;
      case 'security':
        return Icons.security;
      default:
        return Icons.build;
    }
  }

  String _formatDate(DateTime date, AppLocalizations l10n) {
    final now = DateTime.now();
    final difference = now.difference(date).inDays;

    if (difference == 0) {
      return l10n.today;
    } else if (difference == 1) {
      return l10n.yesterday;
    } else if (difference < 7) {
      return '${difference}d';
    } else {
      return '${date.day}/${date.month}/${date.year}';
    }
  }

  String _getStatusText(String status, AppLocalizations l10n) {
    switch (status.toLowerCase()) {
      case 'pending':
        return l10n.statusPending;
      case 'in_progress':
        return l10n.statusInProgress;
      case 'completed':
        return l10n.statusCompleted;
      case 'cancelled':
        return l10n.statusCancelled;
      default:
        return status;
    }
  }

  String _getPriorityText(String priority, AppLocalizations l10n) {
    switch (priority.toLowerCase()) {
      case 'high':
        return l10n.priorityHigh;
      case 'medium':
        return l10n.priorityMedium;
      case 'low':
        return l10n.priorityLow;
      default:
        return priority;
    }
  }
}
