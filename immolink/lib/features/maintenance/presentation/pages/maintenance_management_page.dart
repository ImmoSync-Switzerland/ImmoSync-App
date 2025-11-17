import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../../l10n/app_localizations.dart';
import 'package:go_router/go_router.dart';
import 'package:immosync/features/maintenance/domain/models/maintenance_request.dart';
import 'package:immosync/features/maintenance/presentation/providers/maintenance_providers.dart';
import 'package:immosync/features/property/presentation/providers/property_providers.dart';
import 'package:intl/intl.dart';
import '../../../../core/providers/dynamic_colors_provider.dart';
import '../../../../core/utils/category_utils.dart';

class MaintenanceManagementPage extends ConsumerStatefulWidget {
  const MaintenanceManagementPage({super.key});

  @override
  ConsumerState<MaintenanceManagementPage> createState() =>
      _MaintenanceManagementPageState();
}

class _MaintenanceManagementPageState
    extends ConsumerState<MaintenanceManagementPage> {
  String _selectedStatus = 'All';
  String _selectedPriority = 'All';

  List<MaintenanceRequest> _filterRequests(List<MaintenanceRequest> requests) {
    return requests.where((request) {
      final bool statusMatch =
          _selectedStatus == 'All' || request.status == _selectedStatus;
      final bool priorityMatch =
          _selectedPriority == 'All' || request.priority == _selectedPriority;
      return statusMatch && priorityMatch;
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final colors = ref.watch(dynamicColorsProvider);
    final maintenanceRequestsAsync =
        ref.watch(landlordMaintenanceRequestsProvider);

    return Scaffold(
      backgroundColor: colors.primaryBackground,
      appBar: AppBar(
        title: Text(l10n.maintenanceRequests),
        backgroundColor: colors.surfaceCards,
        foregroundColor: colors.textPrimary,
        elevation: 0,
      ),
      body: Column(
        children: [
          _buildFilterOptions(context, l10n, colors),
          Expanded(
            child: maintenanceRequestsAsync.when(
              data: (requests) {
                final filteredRequests = _filterRequests(requests);
                if (filteredRequests.isEmpty) {
                  return _buildEmptyState(l10n, colors);
                }

                return ListView.builder(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  itemCount: filteredRequests.length,
                  itemBuilder: (context, index) {
                    return _buildMaintenanceRequestCard(
                        context, filteredRequests[index], l10n, colors, ref);
                  },
                );
              },
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (error, stack) => Consumer(
                builder: (context, ref, child) {
                  final colors = ref.watch(dynamicColorsProvider);
                  return Center(
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
                          l10n.errorLoadingMaintenanceRequests,
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w600,
                            color: colors.textPrimary,
                            inherit: true,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          error.toString(),
                          style: TextStyle(
                            color: colors.textSecondary,
                            inherit: true,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterOptions(
      BuildContext context, AppLocalizations l10n, DynamicAppColors colors) {
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(20),
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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.filter_list,
                  color: Colors.white,
                  size: 24,
                ),
              ),
              const SizedBox(width: 12),
              Text(
                l10n.filterRequests,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                  color: Colors.white,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _buildDropdown(
                  label: l10n.status,
                  value: _selectedStatus,
                  items: [
                    DropdownMenuItem(value: 'All', child: Text(l10n.all)),
                    DropdownMenuItem(
                        value: 'pending', child: Text(l10n.pending)),
                    DropdownMenuItem(
                        value: 'in_progress', child: Text(l10n.inProgress)),
                    DropdownMenuItem(
                        value: 'completed', child: Text(l10n.completed)),
                    DropdownMenuItem(
                        value: 'cancelled', child: Text(l10n.cancelled)),
                  ],
                  onChanged: (value) {
                    if (value != null) {
                      setState(() {
                        _selectedStatus = value;
                      });
                    }
                  },
                  colors: colors,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildDropdown(
                  label: l10n.priority,
                  value: _selectedPriority,
                  items: [
                    DropdownMenuItem(value: 'All', child: Text(l10n.all)),
                    DropdownMenuItem(value: 'low', child: Text(l10n.low)),
                    DropdownMenuItem(value: 'medium', child: Text(l10n.medium)),
                    DropdownMenuItem(value: 'high', child: Text(l10n.high)),
                    DropdownMenuItem(
                        value: 'emergency', child: Text(l10n.emergency)),
                  ],
                  onChanged: (value) {
                    if (value != null) {
                      setState(() {
                        _selectedPriority = value;
                      });
                    }
                  },
                  colors: colors,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildDropdown({
    required String label,
    required String value,
    required List<DropdownMenuItem<String>> items,
    required Function(String?) onChanged,
    required DynamicAppColors colors,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.95),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      child: DropdownButtonFormField<String>(
        initialValue: value,
        decoration: InputDecoration(
          labelText: label,
          border: InputBorder.none,
          contentPadding: EdgeInsets.zero,
          isDense: true,
          labelStyle: TextStyle(
            color: colors.textSecondary,
            fontSize: 12,
            fontWeight: FontWeight.w600,
            inherit: true,
          ),
        ),
        items: items,
        onChanged: onChanged,
        dropdownColor: Colors.white,
        isDense: true,
        style: TextStyle(
          color: colors.textPrimary,
          fontSize: 14,
          fontWeight: FontWeight.w600,
          inherit: true,
        ),
      ),
    );
  }

  Widget _buildEmptyState(AppLocalizations l10n, DynamicAppColors colors) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.build_outlined,
            size: 56,
            color: colors.textTertiary,
          ),
          const SizedBox(height: 14),
          Text(
            l10n.noMaintenanceRequests,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: colors.textSecondary,
              inherit: true,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            l10n.noMaintenanceRequestsDescription,
            style: TextStyle(
              fontSize: 13,
              color: colors.textTertiary,
              inherit: true,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildMaintenanceRequestCard(
      BuildContext context,
      MaintenanceRequest request,
      AppLocalizations l10n,
      DynamicAppColors colors,
      WidgetRef ref) {
    Color statusColor;
    IconData statusIcon;
    String statusText;

    switch (request.status) {
      case 'pending':
        statusColor = colors.warning;
        statusIcon = Icons.hourglass_empty;
        statusText = l10n.pending;
        break;
      case 'in_progress':
        statusColor = colors.info;
        statusIcon = Icons.engineering;
        statusText = l10n.inProgress;
        break;
      case 'completed':
        statusColor = colors.success;
        statusIcon = Icons.check_circle;
        statusText = l10n.completed;
        break;
      case 'cancelled':
        statusColor = colors.error;
        statusIcon = Icons.cancel;
        statusText = l10n.cancelled;
        break;
      default:
        statusColor = colors.textTertiary;
        statusIcon = Icons.help_outline;
        statusText = request.status;
    }

    Color priorityColor;
    String priorityText;
    switch (request.priority) {
      case 'low':
        priorityColor = colors.success;
        priorityText = l10n.low;
        break;
      case 'medium':
        priorityColor = colors.warning;
        priorityText = l10n.medium;
        break;
      case 'high':
        priorityColor = colors.error;
        priorityText = l10n.high;
        break;
      case 'emergency':
        priorityColor = colors.error;
        priorityText = l10n.emergency;
        break;
      default:
        priorityColor = colors.textTertiary;
        priorityText = request.priority;
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.95),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.15),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () {
            context.push('/maintenance/${request.id}');
          },
          borderRadius: BorderRadius.circular(24),
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(6),
                            decoration: BoxDecoration(
                              color: CategoryUtils.getCategoryColor(
                                      request.category)
                                  .withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Icon(
                              CategoryUtils.getCategoryIcon(request.category),
                              size: 14,
                              color: CategoryUtils.getCategoryColor(
                                  request.category),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  request.title,
                                  style: TextStyle(
                                    fontSize: 15,
                                    fontWeight: FontWeight.bold,
                                    color: colors.textPrimary,
                                    inherit: true,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                Text(
                                  request.category,
                                  style: TextStyle(
                                    fontSize: 11,
                                    color: CategoryUtils.getCategoryColor(
                                        request.category),
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: statusColor.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: statusColor.withValues(alpha: 0.3),
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            statusIcon,
                            size: 12,
                            color: statusColor,
                          ),
                          const SizedBox(width: 3),
                          Text(
                            statusText.toUpperCase(),
                            style: TextStyle(
                              fontSize: 9,
                              fontWeight: FontWeight.w600,
                              color: statusColor,
                              letterSpacing: 0.5,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                Text(
                  request.description,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 13,
                    color: colors.textSecondary,
                    height: 1.3,
                    inherit: true,
                  ),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Icon(
                      Icons.home_work_outlined,
                      size: 14,
                      color: colors.textTertiary,
                    ),
                    const SizedBox(width: 5),
                    Expanded(
                      child: Consumer(
                        builder: (context, ref, child) {
                          final propertyAsync =
                              ref.watch(propertyProvider(request.propertyId));
                          return propertyAsync.when(
                            data: (property) => Text(
                              '${property.address.street}, ${property.address.city}',
                              style: TextStyle(
                                fontSize: 12,
                                color: colors.textTertiary,
                                inherit: true,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            loading: () => Text(
                              l10n.loadingAddress,
                              style: TextStyle(
                                fontSize: 12,
                                color: colors.textTertiary,
                                inherit: true,
                              ),
                            ),
                            error: (error, stack) => Text(
                              '${l10n.propertyIdLabel}: ${request.propertyId}',
                              style: TextStyle(
                                fontSize: 12,
                                color: colors.textTertiary,
                                inherit: true,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          );
                        },
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 6,
                        vertical: 3,
                      ),
                      decoration: BoxDecoration(
                        color: priorityColor.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        '${priorityText.toUpperCase()} ${l10n.priority}',
                        style: TextStyle(
                          fontSize: 9,
                          fontWeight: FontWeight.w600,
                          color: priorityColor,
                          letterSpacing: 0.3,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Row(
                  children: [
                    Icon(
                      Icons.access_time,
                      size: 14,
                      color: colors.textTertiary,
                    ),
                    const SizedBox(width: 5),
                    Text(
                      '${l10n.reported}: ${DateFormat('MMM d, yyyy').format(request.requestedDate)}',
                      style: TextStyle(
                        fontSize: 12,
                        color: colors.textTertiary,
                        inherit: true,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
