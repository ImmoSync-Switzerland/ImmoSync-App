import 'dart:math' as math;
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import 'package:immosync/core/widgets/glass_nav_bar.dart';
import 'package:immosync/features/payment/domain/models/payment.dart';
import 'package:immosync/features/payment/presentation/providers/payment_providers.dart';
import 'package:immosync/features/property/domain/models/property.dart';
import 'package:immosync/features/property/presentation/providers/properties_provider.dart';
import 'package:immosync/core/theme/app_typography.dart';

class ReportsPage extends StatelessWidget {
  const ReportsPage({super.key});

  @override
  Widget build(BuildContext context) => const ReportsScreen();
}

class ReportsScreen extends ConsumerWidget {
  const ReportsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final paymentsAsync = ref.watch(landlordPaymentsProvider);
    final propertiesAsync = ref.watch(landlordPropertiesProvider);

    return paymentsAsync.when(
      loading: () => const _ReportsScaffold(body: _CenteredLoader()),
      error: (e, st) => const _ReportsScaffold(
        body: _ErrorState(message: 'Failed to load payments'),
      ),
      data: (payments) {
        return propertiesAsync.when(
          loading: () => const _ReportsScaffold(body: _CenteredLoader()),
          error: (e, st) => const _ReportsScaffold(
            body: _ErrorState(message: 'Failed to load properties'),
          ),
          data: (properties) {
            final derived =
                _ReportData.from(payments: payments, properties: properties);
            return _ReportsScaffold(
              body: _ReportsBody(data: derived),
            );
          },
        );
      },
    );
  }
}

class _ReportsScaffold extends StatelessWidget {
  const _ReportsScaffold({required this.body});

  final Widget body;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBody: true,
      backgroundColor: Colors.transparent,
      bottomNavigationBar: const AppGlassNavBar(),
      body: Stack(
        children: [
          const _DeepNavyBackground(),
          SafeArea(child: body),
        ],
      ),
    );
  }
}

class _ReportsBody extends StatelessWidget {
  const _ReportsBody({required this.data});

  final _ReportData data;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(20, 22, 20, 100),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const _Header(),
          const SizedBox(height: 18),
          _RevenueCard(data: data.revenue),
          const SizedBox(height: 18),
          _MetricsGrid(data: data.metrics),
          const SizedBox(height: 18),
          _OccupancyCard(data: data.occupancy),
        ],
      ),
    );
  }
}

class _Header extends StatelessWidget {
  const _Header();

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Text(
          'Analytics',
          style: AppTypography.pageTitle.copyWith(color: Colors.white),
        ),
        const Spacer(),
        const _BentoCard(
          padding: EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.calendar_today, size: 16, color: Colors.white70),
              SizedBox(width: 8),
              Text(
                'This Month',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w700,
                  fontSize: 13,
                ),
              ),
              SizedBox(width: 6),
              Icon(Icons.keyboard_arrow_down, size: 18, color: Colors.white70),
            ],
          ),
        ),
      ],
    );
  }
}

class _RevenueCard extends StatelessWidget {
  const _RevenueCard({required this.data});

  final _RevenueData data;

  @override
  Widget build(BuildContext context) {
    final months = data.monthLabels;
    final revenue = data.values;
    final maxRevenue = revenue.isEmpty
        ? 1.0
        : revenue.reduce(math.max).clamp(1.0, double.infinity);

    return _BentoCard(
      padding: const EdgeInsets.all(18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Revenue Trends',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w800,
                  fontSize: 16,
                ),
              ),
              Icon(Icons.show_chart, color: Colors.white70),
            ],
          ),
          const SizedBox(height: 18),
          SizedBox(
            height: 230,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: List.generate(months.length, (index) {
                final value = revenue[index];
                final barHeight = (value / maxRevenue) * 180;

                return Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 4),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Expanded(
                          child: Align(
                            alignment: Alignment.bottomCenter,
                            child: Container(
                              height: barHeight,
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(10),
                                gradient: const LinearGradient(
                                  begin: Alignment.bottomCenter,
                                  end: Alignment.topCenter,
                                  colors: [
                                    Color(0xFF22C55E),
                                    Color(0xFF22D3EE)
                                  ],
                                ),
                                boxShadow: const [
                                  BoxShadow(
                                    color: Colors.black26,
                                    blurRadius: 12,
                                    offset: Offset(0, 6),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 10),
                        Text(
                          months[index],
                          style: const TextStyle(
                              color: Colors.white70,
                              fontSize: 11,
                              fontWeight: FontWeight.w600),
                        ),
                      ],
                    ),
                  ),
                );
              }),
            ),
          ),
        ],
      ),
    );
  }
}

class _MetricsGrid extends StatelessWidget {
  const _MetricsGrid({required this.data});

  final List<_MetricCardData> data;

  @override
  Widget build(BuildContext context) {
    return GridView.count(
      padding: EdgeInsets.zero,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      primary: false,
      crossAxisCount: 2,
      childAspectRatio: 1.6,
      crossAxisSpacing: 16,
      mainAxisSpacing: 16,
      children: data.map((metric) => _MetricCard(data: metric)).toList(),
    );
  }
}

class _MetricCardData {
  const _MetricCardData({
    required this.icon,
    required this.iconColor,
    required this.label,
    required this.value,
    required this.valueColor,
  });

  final IconData icon;
  final Color iconColor;
  final String label;
  final String value;
  final Color valueColor;
}

class _MetricCard extends StatelessWidget {
  const _MetricCard({required this.data});

  final _MetricCardData data;

  @override
  Widget build(BuildContext context) {
    return _BentoCard(
      padding: const EdgeInsets.all(8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            decoration: BoxDecoration(
              color: data.iconColor.withAlpha(28),
              borderRadius: BorderRadius.circular(12),
            ),
            padding: const EdgeInsets.all(5),
            child: Icon(data.icon, color: data.iconColor, size: 14),
          ),
          const SizedBox(height: 6),
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Text(
              data.label,
              style: const TextStyle(
                  color: Colors.white70, fontWeight: FontWeight.w600),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          const SizedBox(height: 3),
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Text(
              data.value,
              style: TextStyle(
                color: data.valueColor,
                fontSize: 15,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _OccupancyCard extends StatelessWidget {
  const _OccupancyCard({required this.data});

  final _OccupancyData data;

  @override
  Widget build(BuildContext context) {
    final occupancy = data.percent;

    return _BentoCard(
      padding: const EdgeInsets.all(18),
      child: Row(
        children: [
          SizedBox(
            width: 100,
            height: 100,
            child: _DonutChart(percent: occupancy),
          ),
          const SizedBox(width: 18),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Occupancy Rate',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 8),
                _OccupancyLine(
                    label: 'Occupied',
                    value: data.occupied.toString(),
                    color: Colors.white),
                const SizedBox(height: 8),
                _OccupancyLine(
                    label: 'Vacant',
                    value: data.vacant.toString(),
                    color: Colors.white70),
                const SizedBox(height: 8),
                _OccupancyLine(
                    label: 'Total',
                    value: data.total.toString(),
                    color: Colors.white54),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _OccupancyLine extends StatelessWidget {
  const _OccupancyLine(
      {required this.label, required this.value, required this.color});

  final String label;
  final String value;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Text(
          '$label: ',
          style: const TextStyle(
              color: Colors.white70, fontWeight: FontWeight.w600),
        ),
        Flexible(
          child: FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Text(
              value,
              style: TextStyle(color: color, fontWeight: FontWeight.w700),
            ),
          ),
        ),
      ],
    );
  }
}

class _DonutChart extends StatelessWidget {
  const _DonutChart({required this.percent});

  final double percent;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 100,
      width: 100,
      child: CustomPaint(
        painter: _DonutPainter(percent: percent),
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                '${(percent * 100).toStringAsFixed(0)}%',
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w800,
                  fontSize: 22,
                ),
              ),
              const SizedBox(height: 4),
              const Text('Occupancy', style: TextStyle(color: Colors.white70)),
            ],
          ),
        ),
      ),
    );
  }
}

class _DonutPainter extends CustomPainter {
  _DonutPainter({required this.percent});

  final double percent;

  @override
  void paint(Canvas canvas, Size size) {
    const stroke = 12.0;
    final rect = Offset.zero & size;

    final background = Paint()
      ..color = Colors.white.withAlpha(20)
      ..style = PaintingStyle.stroke
      ..strokeWidth = stroke;

    const gradient = SweepGradient(
      startAngle: -math.pi / 2,
      endAngle: 3 * math.pi / 2,
      colors: [Color(0xFF38BDF8), Color(0xFF22C55E), Color(0xFF38BDF8)],
      stops: [0.0, 0.6, 1.0],
    );

    final foreground = Paint()
      ..shader = gradient.createShader(rect)
      ..style = PaintingStyle.stroke
      ..strokeWidth = stroke
      ..strokeCap = StrokeCap.round;

    final center = size.center(Offset.zero);
    final radius = (size.shortestSide - stroke) / 2;

    canvas.drawCircle(center, radius, background);
    final sweep = 2 * math.pi * percent;
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      -math.pi / 2,
      sweep,
      false,
      foreground,
    );
  }

  @override
  bool shouldRepaint(covariant _DonutPainter oldDelegate) =>
      oldDelegate.percent != percent;
}

class _ReportData {
  _ReportData(
      {required this.revenue, required this.metrics, required this.occupancy});

  final _RevenueData revenue;
  final List<_MetricCardData> metrics;
  final _OccupancyData occupancy;

  factory _ReportData.from(
      {required List<Payment> payments, required List<Property> properties}) {
    const monthNames = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec'
    ];
    final now = DateTime.now();
    final months = List<DateTime>.generate(
      7,
      (i) => DateTime(now.year, now.month - (6 - i), 1),
    );
    final monthKeys = <String, int>{
      for (var i = 0; i < months.length; i++)
        '${months[i].year}-${months[i].month}': i,
    };

    final revenueBuckets = List<double>.filled(months.length, 0);
    double incomeTotal = 0;
    double pendingTotal = 0;
    for (final payment in payments) {
      if (payment.status == 'completed') {
        incomeTotal += payment.amount;
        final key = '${payment.date.year}-${payment.date.month}';
        final bucketIndex = monthKeys[key];
        if (bucketIndex != null) {
          revenueBuckets[bucketIndex] += payment.amount;
        }
      } else if (payment.status == 'pending') {
        pendingTotal += payment.amount;
      }
    }

    final totalUnits = properties.length;
    final occupiedUnits =
        properties.where((p) => p.tenantIds.isNotEmpty).length;
    final vacantUnits = math.max(0, totalUnits - occupiedUnits);
    final occupancyPercent = totalUnits == 0 ? 0.0 : occupiedUnits / totalUnits;
    final expensesTotal =
        properties.fold<double>(0, (sum, p) => sum + p.outstandingPayments);

    final revenueData = _RevenueData(
      monthLabels: months.map((m) => monthNames[m.month - 1]).toList(),
      values: revenueBuckets,
    );

    final metrics = <_MetricCardData>[
      _MetricCardData(
        icon: Icons.arrow_upward_rounded,
        iconColor: const Color(0xFF22C55E),
        label: 'Income',
        value: _formatCurrency(incomeTotal),
        valueColor: Colors.white,
      ),
      _MetricCardData(
        icon: Icons.access_time_filled_rounded,
        iconColor: const Color(0xFFF97316),
        label: 'Pending',
        value: _formatCurrency(pendingTotal),
        valueColor: const Color(0xFFF97316),
      ),
      _MetricCardData(
        icon: Icons.home_work_rounded,
        iconColor: const Color(0xFF38BDF8),
        label: 'Occupancy',
        value: '${(occupancyPercent * 100).toStringAsFixed(0)}%',
        valueColor: Colors.white,
      ),
      _MetricCardData(
        icon: Icons.trending_down_rounded,
        iconColor: const Color(0xFFEF4444),
        label: 'Expenses',
        value: _formatCurrency(expensesTotal),
        valueColor: Colors.white,
      ),
    ];

    final occupancy = _OccupancyData(
      percent: occupancyPercent,
      occupied: occupiedUnits,
      vacant: vacantUnits,
      total: totalUnits,
    );

    return _ReportData(
        revenue: revenueData, metrics: metrics, occupancy: occupancy);
  }
}

class _RevenueData {
  _RevenueData({required this.monthLabels, required this.values});

  final List<String> monthLabels;
  final List<double> values;
}

class _OccupancyData {
  _OccupancyData(
      {required this.percent,
      required this.occupied,
      required this.vacant,
      required this.total});

  final double percent;
  final int occupied;
  final int vacant;
  final int total;
}

class _CenteredLoader extends StatelessWidget {
  const _CenteredLoader();

  @override
  Widget build(BuildContext context) {
    return const Center(child: CircularProgressIndicator());
  }
}

class _ErrorState extends StatelessWidget {
  const _ErrorState({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Text(
        message,
        style:
            const TextStyle(color: Colors.white70, fontWeight: FontWeight.w600),
      ),
    );
  }
}

String _formatCurrency(double value) {
  return NumberFormat.currency(
          locale: 'de_CH', symbol: 'CHF ', decimalDigits: 0)
      .format(value);
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
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          width: 1,
          color: Colors.white.withAlpha(25),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(80),
            blurRadius: 22,
            offset: const Offset(0, 12),
          ),
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
      fit: StackFit.expand,
      children: [
        const DecoratedBox(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [Color(0xFF0A1128), Colors.black],
            ),
          ),
        ),
        const _Glow(
            color: Color(0xFF4F46E5),
            size: 420,
            alignment: Alignment(-0.75, -0.6),
            opacity: 0.22),
        const _Glow(
            color: Color(0xFF0EA5E9),
            size: 360,
            alignment: Alignment(0.85, -0.1),
            opacity: 0.16),
        const _Glow(
            color: Color(0xFFF97316),
            size: 500,
            alignment: Alignment(-0.5, 0.9),
            opacity: 0.12),
        Positioned.fill(
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 26, sigmaY: 26),
            child: const SizedBox.shrink(),
          ),
        ),
      ],
    );
  }
}

class _Glow extends StatelessWidget {
  const _Glow({
    required this.color,
    required this.size,
    required this.alignment,
    this.opacity = 0.16,
  });

  final Color color;
  final double size;
  final Alignment alignment;
  final double opacity;

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: alignment,
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: RadialGradient(
            colors: [
              color.withValues(alpha: opacity),
              color.withValues(alpha: 0.02),
              Colors.transparent,
            ],
            stops: const [0, 0.45, 1],
          ),
        ),
      ),
    );
  }
}
