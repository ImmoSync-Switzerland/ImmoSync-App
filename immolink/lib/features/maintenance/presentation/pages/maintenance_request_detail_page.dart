import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../../l10n/app_localizations.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:immosync/features/maintenance/domain/models/maintenance_request.dart';
import 'package:immosync/features/maintenance/presentation/providers/maintenance_providers.dart';
import 'package:immosync/features/maintenance/presentation/pages/maintenance_detail_screen.dart';
import 'package:immosync/features/auth/presentation/providers/auth_provider.dart';
import 'package:immosync/features/auth/presentation/providers/user_role_provider.dart';
import 'package:immosync/features/auth/presentation/providers/user_service_provider.dart';
import '../../../../core/providers/dynamic_colors_provider.dart';
import '../../../../core/utils/category_utils.dart';

class MaintenanceRequestDetailPage extends ConsumerWidget {
  final String requestId;
  final MaintenanceRequest? initialRequest;

  const MaintenanceRequestDetailPage({
    super.key,
    required this.requestId,
    this.initialRequest,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final requestAsync = ref.watch(maintenanceRequestProvider(requestId));

    final colors = ref.watch(dynamicColorsProvider);
    final l10n = AppLocalizations.of(context)!;

    void handleBack() {
      if (context.canPop()) {
        context.pop();
        return;
      }
      context.go('/home');
    }

    Widget buildForRequest(MaintenanceRequest request) {
      final userRole = ref.watch(userRoleProvider);
      final canUpdateStatus = userRole == 'landlord';

      final tenantId = request.tenantId.trim();
      final tenantUserAsync = tenantId.isEmpty
          ? const AsyncValue.data(null)
          : ref.watch(userByIdProvider(tenantId));
      final tenantUser = tenantUserAsync.maybeWhen(
        data: (u) => u,
        orElse: () => null,
      );

      final noteAuthorNameById = <String, String>{};
      final authorIds = request.notes
          .map((n) => n.author.trim())
          .where((id) => id.isNotEmpty)
          .toSet();

      for (final authorId in authorIds) {
        // If it's already an email/name-like string, don't treat it as an id.
        if (authorId.contains('@')) continue;
        final userAsync = ref.watch(userByIdProvider(authorId));
        final user = userAsync.maybeWhen(
          data: (u) => u,
          orElse: () => null,
        );
        final name = user?.fullName.trim();
        if (name != null && name.isNotEmpty) {
          noteAuthorNameById[authorId] = name;
        }
      }

      final effectiveRequestId = request.id.isNotEmpty ? request.id : requestId;

      String? primaryLabel;
      String? nextStatus;
      if (canUpdateStatus && request.status == 'pending') {
        primaryLabel = l10n.markAsInProgress;
        nextStatus = 'in_progress';
      } else if (canUpdateStatus && request.status == 'in_progress') {
        primaryLabel = l10n.markAsCompleted;
        nextStatus = 'completed';
      }

      return MaintenanceDetailScreen(
        onBack: handleBack,
        data: _toDetailData(
          request,
          resolvedTenantName: tenantUser?.fullName,
          resolvedNoteAuthorNames: noteAuthorNameById,
        ),
        primaryActionLabel: primaryLabel,
        onPrimaryActionTap: nextStatus == null
            ? null
            : () => _updateStatus(
                context, ref, effectiveRequestId, nextStatus!, colors),
        secondaryActionLabel: l10n.addNote,
        onSecondaryActionTap: () =>
            _showAddNoteDialog(context, ref, effectiveRequestId, colors),
      );
    }

    return requestAsync.when(
      data: buildForRequest,
      loading: () {
        if (initialRequest != null) {
          return buildForRequest(initialRequest!);
        }
        return MaintenanceDetailLoadingScreen(onBack: handleBack);
      },
      error: (error, stack) => MaintenanceDetailErrorScreen(
        onBack: handleBack,
        message: error.toString(),
      ),
    );
  }

  static MaintenanceDetailData _toDetailData(
    MaintenanceRequest request, {
    String? resolvedTenantName,
    Map<String, String> resolvedNoteAuthorNames = const {},
  }) {
    final statusLabel = request.statusDisplayText;
    final priorityLabel = switch (request.priority) {
      'urgent' => 'Urgent',
      'high' => 'High',
      'medium' => 'Medium',
      'low' => 'Low',
      _ => request.priorityDisplayText,
    };

    final notes = [...request.notes]
      ..sort((a, b) => b.timestamp.compareTo(a.timestamp));

    return MaintenanceDetailData(
      title: request.title.isNotEmpty ? request.title : 'Maintenance Request',
      statusLabel: statusLabel,
      priorityLabel: priorityLabel,
      category: request.categoryDisplayText,
      location: request.location.isNotEmpty ? request.location : '—',
      reportedLabel: DateFormat('MMM d, yyyy').format(request.requestedDate),
      tenant: _firstNonEmpty([
        resolvedTenantName,
        request.tenantName,
        request.tenantEmail,
        request.tenantId,
      ]),
      description: request.description.isNotEmpty
          ? request.description
          : 'No description provided.',
      notes: notes
          .map(
            (note) => MaintenanceNoteData(
              authorLabel: _firstNonEmpty([
                note.authorName,
                resolvedNoteAuthorNames[note.author.trim()],
                note.author,
              ]),
              timestampLabel:
                  DateFormat('MMM d, yyyy · HH:mm').format(note.timestamp),
              content: note.content,
            ),
          )
          .toList(growable: false),
    );
  }

  static String _firstNonEmpty(List<String?> values) {
    for (final value in values) {
      final v = value?.trim();
      if (v != null && v.isNotEmpty) return v;
    }
    return '—';
  }

  // Kept as legacy/reference UI. The active detail UI is [MaintenanceDetailScreen].
  // ignore: unused_element
  Widget _buildRequestDetails(BuildContext context, MaintenanceRequest request,
      AppLocalizations l10n, WidgetRef ref, DynamicAppColors colors) {
    final IconData statusIcon = _getStatusIcon(request.status);

    return CustomScrollView(
      slivers: [
        // Hero Header
        SliverToBoxAdapter(
          child: Container(
            margin: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Color(0xF2EA580C), // Orange #EA580C @ 95%
                  Color(0xD9DC2626), // Red #DC2626 @ 85%
                ],
              ),
              borderRadius: BorderRadius.circular(32),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.3),
                  blurRadius: 20,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Icon(
                          CategoryUtils.getCategoryIcon(request.category),
                          color: Colors.white,
                          size: 32,
                        ),
                      ),
                      const SizedBox(width: 20),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              request.title,
                              style: const TextStyle(
                                fontSize: 24,
                                fontWeight: FontWeight.w900,
                                color: Colors.white,
                                height: 1.2,
                              ),
                            ),
                            const SizedBox(height: 12),
                            Wrap(
                              spacing: 12,
                              runSpacing: 8,
                              children: [
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 16,
                                    vertical: 8,
                                  ),
                                  decoration: BoxDecoration(
                                    color: Colors.white.withValues(alpha: 0.2),
                                    borderRadius: BorderRadius.circular(20),
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Icon(
                                        statusIcon,
                                        size: 16,
                                        color: Colors.white,
                                      ),
                                      const SizedBox(width: 6),
                                      Text(
                                        request.statusDisplayText.toUpperCase(),
                                        style: const TextStyle(
                                          fontSize: 12,
                                          fontWeight: FontWeight.w700,
                                          color: Colors.white,
                                          letterSpacing: 0.5,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 16,
                                    vertical: 8,
                                  ),
                                  decoration: BoxDecoration(
                                    color: Colors.white.withValues(alpha: 0.2),
                                    borderRadius: BorderRadius.circular(20),
                                  ),
                                  child: Text(
                                    '${request.priorityDisplayText.toUpperCase()} PRIORITY',
                                    style: const TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w700,
                                      color: Colors.white,
                                      letterSpacing: 0.5,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),

        // Description Section
        SliverToBoxAdapter(
          child: Container(
            margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.95),
              borderRadius: BorderRadius.circular(32),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.15),
                  blurRadius: 20,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: colors.primaryAccent.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Icon(
                          Icons.description_outlined,
                          color: colors.primaryAccent,
                          size: 20,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Text(
                        l10n.description,
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w800,
                          color: colors.textPrimary,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Text(
                    request.description,
                    style: TextStyle(
                      fontSize: 16,
                      color: colors.textSecondary,
                      height: 1.6,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),

        // Details Grid Section
        SliverToBoxAdapter(
          child: Container(
            margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.95),
              borderRadius: BorderRadius.circular(32),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.15),
                  blurRadius: 20,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: colors.primaryAccent.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Icon(
                          Icons.info_outline,
                          color: colors.primaryAccent,
                          size: 20,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Text(
                        l10n.details,
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w800,
                          color: colors.textPrimary,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  _buildModernDetailGrid(request, colors, l10n),
                ],
              ),
            ),
          ),
        ),

        // Contractor Information (if available)
        if (request.contractorInfo != null)
          SliverToBoxAdapter(
            child: Container(
              margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.95),
                borderRadius: BorderRadius.circular(32),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.15),
                    blurRadius: 20,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: colors.primaryAccent.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Icon(
                            Icons.person_outline,
                            color: colors.primaryAccent,
                            size: 20,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Text(
                          l10n.contractorInformation,
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w800,
                            color: colors.textPrimary,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),
                    if (request.contractorInfo!.name != null)
                      _buildModernDetailRow(Icons.person, l10n.name,
                          request.contractorInfo!.name!, colors),
                    if (request.contractorInfo!.contact != null)
                      _buildModernDetailRow(Icons.phone, l10n.contact,
                          request.contractorInfo!.contact!, colors),
                    if (request.contractorInfo!.company != null)
                      _buildModernDetailRow(Icons.business, l10n.company,
                          request.contractorInfo!.company!, colors),
                  ],
                ),
              ),
            ),
          ),

        // Notes Section (if available)
        if (request.notes.isNotEmpty)
          SliverToBoxAdapter(
            child: Container(
              margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
              decoration: BoxDecoration(
                color: colors.surfaceCards,
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: colors.shadowColor.withValues(alpha: 0.08),
                    blurRadius: 20,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(
                          Icons.note_outlined,
                          color: colors.textSecondary,
                          size: 20,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          l10n.notes,
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: colors.textPrimary,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),
                    ...request.notes
                        .map((note) => Container(
                              margin: const EdgeInsets.only(bottom: 16),
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                color: colors.primaryBackground,
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                  color: colors.textTertiary
                                      .withValues(alpha: 0.1),
                                ),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    note.content,
                                    style: TextStyle(
                                      fontSize: 15,
                                      color: colors.textSecondary,
                                      height: 1.5,
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    DateFormat('MMM d, yyyy \'at\' h:mm a')
                                        .format(note.timestamp),
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: colors.textTertiary,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ],
                              ),
                            ))
                        .toList(),
                  ],
                ),
              ),
            ),
          ),

        // Action Buttons Section
        SliverToBoxAdapter(
          child: Container(
            margin: const EdgeInsets.all(20),
            child:
                _buildModernActionButtons(context, ref, request, colors, l10n),
          ),
        ),

        // Add some bottom padding
        const SliverToBoxAdapter(
          child: SizedBox(height: 20),
        ),
      ],
    );
  }

  Widget _buildModernDetailGrid(MaintenanceRequest request,
      DynamicAppColors colors, AppLocalizations l10n) {
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: _buildModernDetailCard(
                Icons.category_outlined,
                l10n.category,
                request.categoryDisplayText,
                CategoryUtils.getCategoryColor(request.category),
                colors,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildModernDetailCard(
                Icons.location_on_outlined,
                l10n.location,
                request.location,
                colors.info,
                colors,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _buildModernDetailCard(
                Icons.access_time,
                l10n.reported,
                DateFormat('MMM d').format(request.requestedDate),
                colors.textSecondary,
                colors,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildModernDetailCard(
                Icons.priority_high,
                l10n.urgency,
                '${request.urgencyLevel}/5',
                _getPriorityColor(request.priority, colors),
                colors,
              ),
            ),
          ],
        ),
        if (request.scheduledDate != null || request.completedDate != null) ...[
          const SizedBox(height: 12),
          Row(
            children: [
              if (request.scheduledDate != null)
                Expanded(
                  child: _buildModernDetailCard(
                    Icons.schedule,
                    l10n.scheduled,
                    DateFormat('MMM d').format(request.scheduledDate!),
                    colors.warning,
                    colors,
                  ),
                ),
              if (request.scheduledDate != null &&
                  request.completedDate != null)
                const SizedBox(width: 12),
              if (request.completedDate != null)
                Expanded(
                  child: _buildModernDetailCard(
                    Icons.check_circle_outline,
                    l10n.completed,
                    DateFormat('MMM d').format(request.completedDate!),
                    colors.success,
                    colors,
                  ),
                ),
            ],
          ),
        ],
        if (request.cost?.estimated != null ||
            request.cost?.actual != null) ...[
          const SizedBox(height: 12),
          Row(
            children: [
              if (request.cost?.estimated != null)
                Expanded(
                  child: _buildModernDetailCard(
                    Icons.attach_money,
                    l10n.estimated,
                    '\$${request.cost!.estimated!.toStringAsFixed(2)}',
                    colors.warning,
                    colors,
                  ),
                ),
              if (request.cost?.estimated != null &&
                  request.cost?.actual != null)
                const SizedBox(width: 12),
              if (request.cost?.actual != null)
                Expanded(
                  child: _buildModernDetailCard(
                    Icons.money,
                    l10n.actualCost,
                    '\$${request.cost!.actual!.toStringAsFixed(2)}',
                    colors.success,
                    colors,
                  ),
                ),
            ],
          ),
        ],
      ],
    );
  }

  Widget _buildModernDetailCard(IconData icon, String label, String value,
      Color color, DynamicAppColors colors) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: color.withValues(alpha: 0.2),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                icon,
                size: 16,
                color: color,
              ),
              const SizedBox(width: 6),
              Text(
                label,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: color,
                  letterSpacing: 0.5,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: colors.textPrimary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildModernDetailRow(
      IconData icon, String label, String value, DynamicAppColors colors) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: colors.textSecondary.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              icon,
              size: 16,
              color: colors.textSecondary,
            ),
          ),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: colors.textTertiary,
                  letterSpacing: 0.5,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                value,
                style: TextStyle(
                  fontSize: 14,
                  color: colors.textSecondary,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildModernActionButtons(
      BuildContext context,
      WidgetRef ref,
      MaintenanceRequest request,
      DynamicAppColors colors,
      AppLocalizations l10n) {
    // Tenants may add notes, but must not change status.
    final userRole = ref.watch(userRoleProvider);
    final canUpdateStatus = userRole == 'landlord';

    if (request.status == 'completed' || request.status == 'cancelled') {
      // Still allow notes even when completed/cancelled.
      return _buildAddNoteButton(context, ref, request.id, colors, l10n);
    }

    return Column(
      children: [
        if (canUpdateStatus && request.status == 'pending') ...[
          Container(
            width: double.infinity,
            height: 56,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [colors.info, colors.info.withValues(alpha: 0.8)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: colors.info.withValues(alpha: 0.3),
                  blurRadius: 12,
                  offset: const Offset(0, 6),
                ),
              ],
            ),
            child: ElevatedButton(
              onPressed: () => _updateStatus(
                  context, ref, request.id, 'in_progress', colors),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.transparent,
                shadowColor: Colors.transparent,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(
                    Icons.engineering,
                    color: Colors.white,
                    size: 20,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    l10n.markAsInProgress,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
        if (canUpdateStatus && request.status == 'in_progress') ...[
          Container(
            width: double.infinity,
            height: 56,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [colors.success, colors.success.withValues(alpha: 0.8)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: colors.success.withValues(alpha: 0.3),
                  blurRadius: 12,
                  offset: const Offset(0, 6),
                ),
              ],
            ),
            child: ElevatedButton(
              onPressed: () =>
                  _updateStatus(context, ref, request.id, 'completed', colors),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.transparent,
                shadowColor: Colors.transparent,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(
                    Icons.check_circle,
                    color: Colors.white,
                    size: 20,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    l10n.markAsCompleted,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
        const SizedBox(height: 12),
        _buildAddNoteButton(context, ref, request.id, colors, l10n),
      ],
    );
  }

  Widget _buildAddNoteButton(
    BuildContext context,
    WidgetRef ref,
    String requestId,
    DynamicAppColors colors,
    AppLocalizations l10n,
  ) {
    return SizedBox(
      width: double.infinity,
      height: 48,
      child: OutlinedButton(
        onPressed: () {
          _showAddNoteDialog(context, ref, requestId, colors);
        },
        style: OutlinedButton.styleFrom(
          side: BorderSide(
            color: colors.textSecondary.withValues(alpha: 0.3),
            width: 1.5,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.note_add,
              color: colors.textSecondary,
              size: 18,
            ),
            const SizedBox(width: 8),
            Text(
              l10n.addNote,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: colors.textSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }

  IconData _getStatusIcon(String status) {
    switch (status) {
      case 'pending':
        return Icons.hourglass_empty;
      case 'in_progress':
        return Icons.engineering;
      case 'completed':
        return Icons.check_circle;
      case 'cancelled':
        return Icons.cancel;
      default:
        return Icons.help_outline;
    }
  }

  Color _getPriorityColor(String priority, DynamicAppColors colors) {
    switch (priority) {
      case 'low':
        return colors.success;
      case 'medium':
        return colors.warning;
      case 'high':
        return colors.error;
      case 'urgent':
        return colors.error;
      default:
        return colors.textTertiary;
    }
  }

  void _updateStatus(BuildContext context, WidgetRef ref, String requestId,
      String newStatus, DynamicAppColors colors) async {
    final l10n = AppLocalizations.of(context)!;

    final userRole = ref.read(userRoleProvider);
    if (userRole != 'landlord') {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Only landlords can update request status.'),
          backgroundColor: colors.error,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
        ),
      );
      return;
    }

    try {
      // Show loading indicator
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const Center(
          child: CircularProgressIndicator(),
        ),
      );

      final maintenanceService = ref.read(maintenanceServiceProvider);
      await maintenanceService.updateMaintenanceRequestStatus(
        requestId,
        newStatus,
        notes: 'Status updated to ${newStatus.replaceAll('_', ' ')}',
        authorId: ref.read(currentUserProvider)?.id,
      );

      // Refresh the request data
      ref.invalidate(maintenanceRequestProvider(requestId));

      // Close loading dialog
      if (context.mounted) {
        Navigator.of(context).pop();

        // Show success message
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
                '${l10n.statusUpdatedTo} ${newStatus.replaceAll('_', ' ')}'),
            backgroundColor: colors.success,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
          ),
        );
      }
    } catch (e) {
      // Close loading dialog
      if (context.mounted) {
        Navigator.of(context).pop();

        // Show error message
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${l10n.failedToUpdateStatus}: $e'),
            backgroundColor: colors.error,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
          ),
        );
      }
    }
  }

  void _showAddNoteDialog(
    BuildContext pageContext,
    WidgetRef ref,
    String requestId,
    DynamicAppColors colors,
  ) {
    showModalBottomSheet<void>(
      context: pageContext,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      barrierColor: Colors.black.withValues(alpha: 0.55),
      builder: (sheetContext) {
        return _AddNoteDialog(
          colors: colors,
          onSubmit: (value) =>
              _addNote(pageContext, ref, requestId, value, colors),
        );
      },
    );
  }
}

class _AddNoteDialog extends StatefulWidget {
  final DynamicAppColors colors;
  final Future<void> Function(String value) onSubmit;

  const _AddNoteDialog({
    required this.colors,
    required this.onSubmit,
  });

  @override
  State<_AddNoteDialog> createState() => _AddNoteDialogState();
}

class _AddNoteDialogState extends State<_AddNoteDialog> {
  late final TextEditingController _noteController;
  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    _noteController = TextEditingController();
  }

  @override
  void dispose() {
    _noteController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final value = _noteController.text.trim();
    if (value.isEmpty || _isSubmitting) return;

    setState(() => _isSubmitting = true);
    try {
      await widget.onSubmit(value);
      if (!mounted) return;
      Navigator.of(context).pop();
    } finally {
      if (!mounted) return;
      setState(() => _isSubmitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final viewInsets = MediaQuery.viewInsetsOf(context);
    final fullHeight = MediaQuery.sizeOf(context).height;
    // Keep the sheet height stable while typing. We avoid tying height to
    // viewInsets so keyboard/suggestion-bar changes don't collapse the input.
    final sheetHeight = (fullHeight * 0.56).clamp(320.0, 520.0);

    final canSubmit = _noteController.text.trim().isNotEmpty && !_isSubmitting;

    return SafeArea(
      top: false,
      child: AnimatedPadding(
        duration: const Duration(milliseconds: 180),
        curve: Curves.easeOut,
        padding: EdgeInsets.only(bottom: viewInsets.bottom),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
          child: SizedBox(
            height: sheetHeight,
            child: Container(
              decoration: BoxDecoration(
                color: const Color(0xFF1C1C1E),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: Colors.white.withValues(alpha: 0.12),
                  width: 1,
                ),
                boxShadow: const [
                  BoxShadow(
                    color: Colors.black45,
                    blurRadius: 18,
                    offset: Offset(0, 12),
                  ),
                ],
              ),
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      l10n.addNote,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Expanded(
                      child: Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.black.withValues(alpha: 0.14),
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(
                            color: Colors.white.withValues(alpha: 0.08),
                          ),
                        ),
                        child: TextField(
                          controller: _noteController,
                          autofocus: true,
                          expands: true,
                          maxLines: null,
                          minLines: null,
                          keyboardAppearance: Brightness.dark,
                          cursorColor: Colors.white,
                          textInputAction: TextInputAction.send,
                          onChanged: (_) {
                            if (!mounted) return;
                            setState(() {});
                          },
                          onSubmitted: (_) => _submit(),
                          decoration: InputDecoration(
                            hintText: l10n.enterNoteHint,
                            hintStyle: const TextStyle(
                              color: Colors.white54,
                              fontWeight: FontWeight.w700,
                            ),
                            filled: true,
                            fillColor: Colors.transparent,
                            border: InputBorder.none,
                            enabledBorder: InputBorder.none,
                            focusedBorder: InputBorder.none,
                            disabledBorder: InputBorder.none,
                            errorBorder: InputBorder.none,
                            focusedErrorBorder: InputBorder.none,
                            isCollapsed: true,
                          ),
                          style: const TextStyle(
                            color: Colors.white70,
                            fontSize: 13,
                            height: 1.4,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: Opacity(
                            opacity: _isSubmitting ? 0.6 : 1.0,
                            child: GestureDetector(
                              onTap: _isSubmitting
                                  ? null
                                  : () => Navigator.of(context).pop(),
                              child: Container(
                                height: 48,
                                decoration: BoxDecoration(
                                  color: const Color(0xFF1C1C1E),
                                  borderRadius: BorderRadius.circular(14),
                                  border: Border.all(
                                    color: Colors.white.withValues(alpha: 0.16),
                                  ),
                                ),
                                child: Center(
                                  child: Text(
                                    l10n.cancel,
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.w800,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Opacity(
                            opacity: canSubmit ? 1.0 : 0.55,
                            child: GestureDetector(
                              onTap: canSubmit ? _submit : null,
                              child: Container(
                                height: 48,
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(14),
                                  gradient: const LinearGradient(
                                    colors: [
                                      Color(0xFF38BDF8),
                                      Color(0xFF06B6D4)
                                    ],
                                    begin: Alignment.topLeft,
                                    end: Alignment.bottomRight,
                                  ),
                                ),
                                child: Center(
                                  child: _isSubmitting
                                      ? const SizedBox(
                                          width: 18,
                                          height: 18,
                                          child: CircularProgressIndicator(
                                            strokeWidth: 2.2,
                                            valueColor:
                                                AlwaysStoppedAnimation<Color>(
                                              Colors.white,
                                            ),
                                          ),
                                        )
                                      : Text(
                                          l10n.addNote,
                                          style: const TextStyle(
                                            color: Colors.white,
                                            fontWeight: FontWeight.w800,
                                          ),
                                        ),
                                ),
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
          ),
        ),
      ),
    );
  }
}

Future<void> _addNote(
  BuildContext context,
  WidgetRef ref,
  String requestId,
  String noteContent,
  DynamicAppColors colors,
) async {
  try {
    final maintenanceService = ref.read(maintenanceServiceProvider);
    final currentUser = ref.read(currentUserProvider);

    if (currentUser?.id == null) {
      throw Exception('User not authenticated');
    }

    await maintenanceService.addNoteToMaintenanceRequest(
      requestId,
      noteContent,
      currentUser!.id,
    );

    // Refresh the maintenance request data
    ref.invalidate(maintenanceRequestProvider(requestId));

    if (context.mounted) {
      final messenger = ScaffoldMessenger.maybeOf(context);
      if (messenger == null) return;
      messenger.showSnackBar(
        SnackBar(
          content: Text(AppLocalizations.of(context)!.noteAddedSuccessfully),
          backgroundColor: colors.success,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
        ),
      );
    }
  } catch (e) {
    if (context.mounted) {
      final messenger = ScaffoldMessenger.maybeOf(context);
      if (messenger == null) return;
      messenger.showSnackBar(
        SnackBar(
          content: Text('${AppLocalizations.of(context)!.failedToAddNote}: $e'),
          backgroundColor: colors.error,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
        ),
      );
    }
  }
}
