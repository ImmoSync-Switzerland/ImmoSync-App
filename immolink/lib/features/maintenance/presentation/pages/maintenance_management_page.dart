import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:immosync/features/maintenance/domain/models/maintenance_request.dart';
import 'package:immosync/features/maintenance/presentation/pages/maintenance_request_detail_page.dart';
import 'package:immosync/l10n/app_localizations.dart';

/// Back-compat wrapper for the existing `/maintenance/manage` route.
/// The redesigned UI lives in [MaintenanceScreen].
class MaintenanceManagementPage extends StatelessWidget {
  const MaintenanceManagementPage({super.key});

  @override
  Widget build(BuildContext context) {
    return const MaintenanceScreen();
  }
}

class MaintenanceScreen extends StatefulWidget {
  const MaintenanceScreen({super.key});

  @override
  State<MaintenanceScreen> createState() => _MaintenanceScreenState();
}

class _MaintenanceScreenState extends State<MaintenanceScreen> {
  static const _localDetailsPlaceholderId = '000000000000000000000000';

  _MaintenanceStatusFilter _activeFilter = _MaintenanceStatusFilter.all;

  final _requests = <_MaintenanceRequestViewModel>[
    const _MaintenanceRequestViewModel(
      id: 'req-1',
      title: 'Heating Failure',
      address: 'Hinterkirchweg 12, Zürich',
      status: _MaintenanceStatusFilter.pending,
      priority: _MaintenancePriority.urgent,
      dateLabel: 'Nov 30',
      icon: Icons.thermostat,
      iconColor: Color(0xFF38BDF8),
    ),
    const _MaintenanceRequestViewModel(
      id: 'req-2',
      title: 'Leaking Faucet',
      address: 'Bahnhofstrasse 5, Zürich',
      status: _MaintenanceStatusFilter.inProgress,
      priority: _MaintenancePriority.low,
      dateLabel: 'Dec 02',
      icon: Icons.water_drop,
      iconColor: Color(0xFF22C55E),
    ),
    const _MaintenanceRequestViewModel(
      id: 'req-3',
      title: 'Broken Window',
      address: 'Seestrasse 88, Zürich',
      status: _MaintenanceStatusFilter.pending,
      priority: _MaintenancePriority.urgent,
      dateLabel: 'Dec 03',
      icon: Icons.window,
      iconColor: Color(0xFFF97316),
    ),
    const _MaintenanceRequestViewModel(
      id: 'req-4',
      title: 'Light Fixture Replacement',
      address: 'Langstrasse 44, Zürich',
      status: _MaintenanceStatusFilter.completed,
      priority: _MaintenancePriority.low,
      dateLabel: 'Dec 05',
      icon: Icons.lightbulb,
      iconColor: Color(0xFFEAB308),
    ),
  ];

  @override
  Widget build(BuildContext context) {
    final filtered = _activeFilter == _MaintenanceStatusFilter.all
        ? _requests
        : _requests.where((r) => r.status == _activeFilter).toList();

    return Scaffold(
      extendBody: true,
      backgroundColor: Colors.transparent,
      body: Stack(
        children: [
          const _DeepNavyBackground(),
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 22, 20, 0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      IconButton(
                        onPressed: () {
                          if (context.canPop()) {
                            context.pop();
                            return;
                          }
                          context.go('/home');
                        },
                        icon: const Icon(
                          Icons.arrow_back,
                          color: Colors.white,
                        ),
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(),
                        tooltip: AppLocalizations.of(context)!.back,
                      ),
                      const SizedBox(width: 12),
                      const Text(
                        'Maintenance',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 24,
                          fontWeight: FontWeight.w800,
                          letterSpacing: -0.2,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),
                  _FilterChips(
                    active: _activeFilter,
                    onChanged: (value) => setState(() => _activeFilter = value),
                  ),
                  const SizedBox(height: 14),
                  Expanded(
                    child: filtered.isEmpty
                        ? const Center(
                            child: Text(
                              'No requests found',
                              style: TextStyle(
                                color: Colors.white70,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          )
                        : ListView.builder(
                            padding: const EdgeInsets.only(bottom: 100),
                            itemCount: filtered.length,
                            itemBuilder: (context, index) {
                              final request = filtered[index];
                              final rawId = request.id?.trim();
                              final hasValidBackendId =
                                  rawId != null && _looksLikeObjectId(rawId);
                              final requestId = hasValidBackendId
                                  ? rawId
                                  : _localDetailsPlaceholderId;
                              return Padding(
                                padding: EdgeInsets.only(
                                  bottom: index == filtered.length - 1 ? 0 : 12,
                                ),
                                child: _RequestCard(
                                  request: request,
                                  onTap: () {
                                    if (hasValidBackendId) {
                                      context.push('/maintenance/$requestId');
                                      return;
                                    }

                                    Navigator.of(context).push(
                                      MaterialPageRoute(
                                        builder: (_) =>
                                            MaintenanceRequestDetailPage(
                                          requestId: _localDetailsPlaceholderId,
                                          initialRequest:
                                              _toLocalMaintenanceRequest(
                                            requestId,
                                            request,
                                          ),
                                        ),
                                      ),
                                    );
                                  },
                                ),
                              );
                            },
                          ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  static bool _looksLikeObjectId(String id) {
    return RegExp(r'^[a-fA-F0-9]{24}$').hasMatch(id);
  }

  static MaintenanceRequest _toLocalMaintenanceRequest(
    String id,
    _MaintenanceRequestViewModel request,
  ) {
    return MaintenanceRequest(
      id: id,
      propertyId: '',
      tenantId: '',
      landlordId: '',
      title: request.title,
      description: '',
      category: 'other',
      priority: switch (request.priority) {
        _MaintenancePriority.urgent => 'urgent',
        _MaintenancePriority.low => 'low',
      },
      status: switch (request.status) {
        _MaintenanceStatusFilter.pending => 'pending',
        _MaintenanceStatusFilter.inProgress => 'in_progress',
        _MaintenanceStatusFilter.completed => 'completed',
        _MaintenanceStatusFilter.all => 'pending',
      },
      location: request.address,
      requestedDate: DateTime.now(),
    );
  }
}

enum _MaintenanceStatusFilter {
  all,
  pending,
  inProgress,
  completed,
}

enum _MaintenancePriority {
  urgent,
  low,
}

class _MaintenanceRequestViewModel {
  const _MaintenanceRequestViewModel({
    this.id,
    required this.title,
    required this.address,
    required this.status,
    required this.priority,
    required this.dateLabel,
    required this.icon,
    required this.iconColor,
  });

  final String? id;
  final String title;
  final String address;
  final _MaintenanceStatusFilter status;
  final _MaintenancePriority priority;
  final String dateLabel;
  final IconData icon;
  final Color iconColor;
}

class _FilterChips extends StatelessWidget {
  const _FilterChips({required this.active, required this.onChanged});

  final _MaintenanceStatusFilter active;
  final ValueChanged<_MaintenanceStatusFilter> onChanged;

  @override
  Widget build(BuildContext context) {
    const filters = <_MaintenanceStatusFilter>[
      _MaintenanceStatusFilter.all,
      _MaintenanceStatusFilter.pending,
      _MaintenanceStatusFilter.inProgress,
      _MaintenanceStatusFilter.completed,
    ];
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: filters.map((filter) {
          final selected = filter == active;
          return Padding(
            padding: const EdgeInsets.only(right: 10),
            child: FilterChip(
              selected: selected,
              onSelected: (_) => onChanged(filter),
              label: Text(
                _labelForFilter(filter),
                style:
                    TextStyle(color: selected ? Colors.white : Colors.white70),
              ),
              backgroundColor: const Color(0xFF1C1C1E),
              selectedColor: const Color(0xFF38BDF8),
              checkmarkColor: Colors.white,
              side: BorderSide(
                color: Colors.white.withValues(alpha: selected ? 0.0 : 0.08),
              ),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  static String _labelForFilter(_MaintenanceStatusFilter filter) {
    return switch (filter) {
      _MaintenanceStatusFilter.all => 'All',
      _MaintenanceStatusFilter.pending => 'Pending',
      _MaintenanceStatusFilter.inProgress => 'In Progress',
      _MaintenanceStatusFilter.completed => 'Completed',
    };
  }
}

class _RequestCard extends StatelessWidget {
  const _RequestCard({required this.request, required this.onTap});

  final _MaintenanceRequestViewModel request;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final status = _statusBadge(request.status);
    final priority = _priorityBadge(request.priority);

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: _BentoCard(
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Text(
                      request.title,
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w800,
                        fontSize: 15,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: request.iconColor.withValues(alpha: 0.16),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child:
                        Icon(request.icon, color: request.iconColor, size: 20),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  const Icon(Icons.location_on,
                      color: Colors.white54, size: 14),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      request.address,
                      style: const TextStyle(
                        color: Colors.white70,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  priority,
                  const SizedBox(width: 8),
                  status,
                  const Spacer(),
                  Text(
                    request.dateLabel,
                    style: const TextStyle(
                      color: Colors.white54,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  static Widget _priorityBadge(_MaintenancePriority priority) {
    final (label, color) = switch (priority) {
      _MaintenancePriority.urgent => ('Urgent', const Color(0xFFF97316)),
      _MaintenancePriority.low => ('Low', const Color(0xFF38BDF8)),
    };

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.14),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: color,
          fontWeight: FontWeight.w800,
          fontSize: 12,
        ),
      ),
    );
  }

  static Widget _statusBadge(_MaintenanceStatusFilter status) {
    final (label, color) = switch (status) {
      _MaintenanceStatusFilter.pending => ('Pending', const Color(0xFFF97316)),
      _MaintenanceStatusFilter.inProgress => (
          'In Progress',
          const Color(0xFFF97316)
        ),
      _MaintenanceStatusFilter.completed => (
          'Completed',
          const Color(0xFF22C55E)
        ),
      _MaintenanceStatusFilter.all => ('All', const Color(0xFF38BDF8)),
    };

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: color.withValues(alpha: 0.55)),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: color,
          fontWeight: FontWeight.w800,
          fontSize: 12,
        ),
      ),
    );
  }
}

class _BentoCard extends StatelessWidget {
  const _BentoCard({required this.child, this.padding});

  final Widget child;
  final EdgeInsets? padding;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: padding ?? const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFF1C1C1E),
        borderRadius: BorderRadius.circular(16),
        border:
            Border.all(color: Colors.white.withValues(alpha: 0.12), width: 1),
        boxShadow: const [
          BoxShadow(
              color: Colors.black45, blurRadius: 18, offset: Offset(0, 12)),
        ],
      ),
      child: child,
    );
  }
}

class _DeepNavyBackground extends StatelessWidget {
  const _DeepNavyBackground();

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [Color(0xFF0A1128), Colors.black],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
        ),
        Positioned(
          top: -90,
          left: -50,
          child: _GlowCircle(
              color: const Color(0xFF38BDF8).withValues(alpha: 0.28)),
        ),
        Positioned(
          bottom: -70,
          right: -30,
          child: _GlowCircle(
              color: const Color(0xFF4F46E5).withValues(alpha: 0.22)),
        ),
      ],
    );
  }
}

class _GlowCircle extends StatelessWidget {
  const _GlowCircle({required this.color});

  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 240,
      height: 240,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: RadialGradient(
          colors: [color, color.withValues(alpha: 0.0)],
          stops: const [0.0, 1.0],
        ),
      ),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 120, sigmaY: 120),
        child: const SizedBox.expand(),
      ),
    );
  }
}
