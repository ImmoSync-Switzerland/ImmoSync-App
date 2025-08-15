import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:immolink/features/maintenance/domain/models/maintenance_request.dart';
import 'package:immolink/features/maintenance/presentation/providers/maintenance_providers.dart';
import 'package:immolink/features/auth/presentation/providers/auth_provider.dart';
import 'package:immolink/features/auth/presentation/providers/user_role_provider.dart';
import '../../../../core/providers/dynamic_colors_provider.dart';
import '../../../../core/utils/category_utils.dart';

class MaintenanceRequestDetailPage extends ConsumerWidget {
  final String requestId;

  const MaintenanceRequestDetailPage({
    super.key,
    required this.requestId,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final colors = ref.watch(dynamicColorsProvider);
    final requestAsync = ref.watch(maintenanceRequestProvider(requestId));

    return Scaffold(
      backgroundColor: colors.primaryBackground,
      appBar: AppBar(
        title: Text(l10n.maintenanceRequestDetails),
        backgroundColor: colors.surfaceCards,
        foregroundColor: colors.textPrimary,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.pop(),
        ),
      ),
      body: requestAsync.when(
        data: (request) => _buildRequestDetails(context, request, l10n, ref, colors),
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stack) => Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.error_outline,
                size: 64,
                color: colors.error,
              ),
              const SizedBox(height: 16),
              Text(
                'Error loading maintenance request',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: colors.textPrimary,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                error.toString(),
                style: TextStyle(
                  fontSize: 14,
                  color: colors.textSecondary,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () => context.pop(),
                child: const Text('Go Back'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildRequestDetails(BuildContext context, MaintenanceRequest request, AppLocalizations l10n, WidgetRef ref, DynamicAppColors colors) {
    Color statusColor = _getStatusColor(request.status, colors);
    IconData statusIcon = _getStatusIcon(request.status);
    Color priorityColor = _getPriorityColor(request.priority, colors);

    return CustomScrollView(
      slivers: [
        // Hero Header
        SliverToBoxAdapter(
          child: Container(
            margin: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  CategoryUtils.getCategoryColor(request.category).withValues(alpha: 0.1),
                  CategoryUtils.getCategoryColor(request.category).withValues(alpha: 0.05),
                ],
              ),
              borderRadius: BorderRadius.circular(24),
              border: Border.all(
                color: CategoryUtils.getCategoryColor(request.category).withValues(alpha: 0.2),
                width: 1,
              ),
              boxShadow: [
                BoxShadow(
                  color: CategoryUtils.getCategoryColor(request.category).withValues(alpha: 0.1),
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
                          color: CategoryUtils.getCategoryColor(request.category).withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: CategoryUtils.getCategoryColor(request.category).withValues(alpha: 0.3),
                            width: 2,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: CategoryUtils.getCategoryColor(request.category).withValues(alpha: 0.2),
                              blurRadius: 8,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: Icon(
                          CategoryUtils.getCategoryIcon(request.category),
                          color: CategoryUtils.getCategoryColor(request.category),
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
                              style: TextStyle(
                                fontSize: 24,
                                fontWeight: FontWeight.bold,
                                color: colors.textPrimary,
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
                                    color: statusColor.withValues(alpha: 0.15),
                                    borderRadius: BorderRadius.circular(25),
                                    border: Border.all(
                                      color: statusColor.withValues(alpha: 0.3),
                                    ),
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Icon(
                                        statusIcon,
                                        size: 16,
                                        color: statusColor,
                                      ),
                                      const SizedBox(width: 6),
                                      Text(
                                        request.statusDisplayText.toUpperCase(),
                                        style: TextStyle(
                                          fontSize: 12,
                                          fontWeight: FontWeight.w700,
                                          color: statusColor,
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
                                    color: priorityColor.withValues(alpha: 0.15),
                                    borderRadius: BorderRadius.circular(25),
                                    border: Border.all(
                                      color: priorityColor.withValues(alpha: 0.3),
                                    ),
                                  ),
                                  child: Text(
                                    '${request.priorityDisplayText.toUpperCase()} PRIORITY',
                                    style: TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w700,
                                      color: priorityColor,
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
                        Icons.description_outlined,
                        color: colors.textSecondary,
                        size: 20,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'Description',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
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
                        Icons.info_outline,
                        color: colors.textSecondary,
                        size: 20,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'Details',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: colors.textPrimary,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  _buildModernDetailGrid(request, colors),
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
                          Icons.person_outline,
                          color: colors.textSecondary,
                          size: 20,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'Contractor Information',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: colors.textPrimary,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),
                    if (request.contractorInfo!.name != null)
                      _buildModernDetailRow(Icons.person, 'Name', request.contractorInfo!.name!, colors),
                    if (request.contractorInfo!.contact != null)
                      _buildModernDetailRow(Icons.phone, 'Contact', request.contractorInfo!.contact!, colors),
                    if (request.contractorInfo!.company != null)
                      _buildModernDetailRow(Icons.business, 'Company', request.contractorInfo!.company!, colors),
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
                          'Notes',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: colors.textPrimary,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),
                    ...request.notes.map((note) => Container(
                      margin: const EdgeInsets.only(bottom: 16),
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: colors.primaryBackground,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: colors.textTertiary.withValues(alpha: 0.1),
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
                            DateFormat('MMM d, yyyy \'at\' h:mm a').format(note.timestamp),
                            style: TextStyle(
                              fontSize: 12,
                              color: colors.textTertiary,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    )).toList(),
                  ],
                ),
              ),
            ),
          ),

        // Add Note Section (for tenants)
        SliverToBoxAdapter(
          child: Container(
            margin: const EdgeInsets.symmetric(horizontal: 20),
            child: _buildAddNoteSection(context, ref, request, colors),
          ),
        ),

        // Action Buttons Section
        SliverToBoxAdapter(
          child: Container(
            margin: const EdgeInsets.all(20),
            child: _buildModernActionButtons(context, ref, request, colors),
          ),
        ),

        // Add some bottom padding
        const SliverToBoxAdapter(
          child: SizedBox(height: 20),
        ),
      ],
    );
  }

  Widget _buildModernDetailGrid(MaintenanceRequest request, DynamicAppColors colors) {
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: _buildModernDetailCard(
                Icons.category_outlined,
                'Category',
                request.categoryDisplayText,
                CategoryUtils.getCategoryColor(request.category),
                colors,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildModernDetailCard(
                Icons.location_on_outlined,
                'Location',
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
                'Reported',
                DateFormat('MMM d').format(request.requestedDate),
                colors.textSecondary,
                colors,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildModernDetailCard(
                Icons.priority_high,
                'Urgency',
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
                    'Scheduled',
                    DateFormat('MMM d').format(request.scheduledDate!),
                    colors.warning,
                    colors,
                  ),
                ),
              if (request.scheduledDate != null && request.completedDate != null)
                const SizedBox(width: 12),
              if (request.completedDate != null)
                Expanded(
                  child: _buildModernDetailCard(
                    Icons.check_circle_outline,
                    'Completed',
                    DateFormat('MMM d').format(request.completedDate!),
                    colors.success,
                    colors,
                  ),
                ),
            ],
          ),
        ],
        if (request.cost?.estimated != null || request.cost?.actual != null) ...[
          const SizedBox(height: 12),
          Row(
            children: [
              if (request.cost?.estimated != null)
                Expanded(
                  child: _buildModernDetailCard(
                    Icons.attach_money,
                    'Estimated',
                    '\$${request.cost!.estimated!.toStringAsFixed(2)}',
                    colors.warning,
                    colors,
                  ),
                ),
              if (request.cost?.estimated != null && request.cost?.actual != null)
                const SizedBox(width: 12),
              if (request.cost?.actual != null)
                Expanded(
                  child: _buildModernDetailCard(
                    Icons.money,
                    'Actual Cost',
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

  Widget _buildModernDetailCard(IconData icon, String label, String value, Color color, DynamicAppColors colors) {
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

  Widget _buildModernDetailRow(IconData icon, String label, String value, DynamicAppColors colors) {
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

  Widget _buildModernActionButtons(BuildContext context, WidgetRef ref, MaintenanceRequest request, DynamicAppColors colors) {
    // Only landlords and property managers can update maintenance request status
    final userRole = ref.watch(userRoleProvider);
    if (userRole == 'tenant') {
      return const SizedBox.shrink();
    }
    
    if (request.status == 'completed' || request.status == 'cancelled') {
      return const SizedBox.shrink();
    }

    return Column(
      children: [
        if (request.status == 'pending') ...[
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
              onPressed: () => _updateStatus(context, ref, request.id, 'in_progress', colors),
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
                  const Text(
                    'Mark as In Progress',
                    style: TextStyle(
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
        if (request.status == 'in_progress') ...[
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
              onPressed: () => _updateStatus(context, ref, request.id, 'completed', colors),
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
                  const Text(
                    'Mark as Completed',
                    style: TextStyle(
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
        // Add secondary action button for adding notes or scheduling
        const SizedBox(height: 12),
        Container(
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
                  'Add Note',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: colors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Color _getStatusColor(String status, DynamicAppColors colors) {
    switch (status) {
      case 'pending':
        return colors.warning;
      case 'in_progress':
        return colors.info;
      case 'completed':
        return colors.success;
      case 'cancelled':
        return colors.error;
      default:
        return colors.textTertiary;
    }
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

  void _updateStatus(BuildContext context, WidgetRef ref, String requestId, String newStatus, DynamicAppColors colors) async {
    final l10n = AppLocalizations.of(context)!;
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
            content: Text('${l10n.statusUpdatedTo} ${newStatus.replaceAll('_', ' ')}'),
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

  void _showAddNoteDialog(BuildContext context, WidgetRef ref, String requestId, DynamicAppColors colors) {
    final TextEditingController noteController = TextEditingController();
    final l10n = AppLocalizations.of(context)!;
    
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: colors.surfaceCards,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: Text(
            l10n.addNote,
            style: TextStyle(
              color: colors.textPrimary,
              fontSize: 20,
              fontWeight: FontWeight.w600,
            ),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                decoration: BoxDecoration(
                  color: colors.primaryBackground,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: colors.textSecondary.withValues(alpha: 0.2),
                  ),
                ),
                child: TextField(
                  controller: noteController,
                  maxLines: 4,
                  decoration: InputDecoration(
                    hintText: 'Enter your note here...',
                    hintStyle: TextStyle(
                      color: colors.textSecondary.withValues(alpha: 0.6),
                    ),
                    border: InputBorder.none,
                    contentPadding: const EdgeInsets.all(16),
                  ),
                  style: TextStyle(
                    color: colors.textPrimary,
                    fontSize: 14,
                  ),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: Text(
                'Cancel',
                style: TextStyle(
                  color: colors.textSecondary,
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
            ElevatedButton(
              onPressed: () async {
                if (noteController.text.trim().isNotEmpty) {
                  await _addNote(context, ref, requestId, noteController.text.trim(), colors);
                  if (context.mounted) {
                    Navigator.of(context).pop();
                  }
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: colors.primaryAccent,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
              ),
              child: const Text(
                'Add Note',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  Future<void> _addNote(BuildContext context, WidgetRef ref, String requestId, String noteContent, DynamicAppColors colors) async {
    try {
      // Show loading indicator
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => Center(
          child: Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: colors.surfaceCards,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                CircularProgressIndicator(
                  valueColor: AlwaysStoppedAnimation<Color>(colors.primaryAccent),
                ),
                const SizedBox(height: 16),
                Text(
                  'Adding note...',
                  style: TextStyle(
                    color: colors.textPrimary,
                    fontSize: 16,
                  ),
                ),
              ],
            ),
          ),
        ),
      );

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

      // Close loading dialog
      if (context.mounted) {
        Navigator.of(context).pop();
        
        // Show success message
        ScaffoldMessenger.of(context).showSnackBar(
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
      // Close loading dialog
      if (context.mounted) {
        Navigator.of(context).pop();
        
        // Show error message
        ScaffoldMessenger.of(context).showSnackBar(
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

  Widget _buildAddNoteSection(BuildContext context, WidgetRef ref, MaintenanceRequest request, DynamicAppColors colors) {
    final l10n = AppLocalizations.of(context)!;
    
    // Only show add note section if the request is not completed/cancelled
    if (request.status == 'completed' || request.status == 'cancelled') {
      return const SizedBox.shrink();
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: colors.surfaceCards,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.note_add,
                color: colors.primaryAccent,
                size: 20,
              ),
              const SizedBox(width: 8),
              Text(
                l10n.addNote,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: colors.textPrimary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: () => _showAddNoteDialog(context, ref, request.id, colors),
              icon: const Icon(Icons.add_comment, size: 18),
              label: Text(l10n.addNote),
              style: ElevatedButton.styleFrom(
                backgroundColor: colors.primaryAccent,
                foregroundColor: colors.textOnAccent,
                padding: const EdgeInsets.symmetric(vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
