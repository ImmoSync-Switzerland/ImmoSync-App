import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';
import 'package:go_router/go_router.dart';
import 'package:immosync/l10n/app_localizations.dart';
import 'package:immosync/core/providers/dynamic_colors_provider.dart';
import 'package:immosync/features/payment/presentation/providers/payment_providers.dart';
import 'package:immosync/features/property/presentation/providers/property_providers.dart';
import 'package:immosync/core/providers/currency_provider.dart';

class RevenueDetailPage extends ConsumerStatefulWidget {
  const RevenueDetailPage({super.key});

  @override
  ConsumerState<RevenueDetailPage> createState() => _RevenueDetailPageState();
}

class _RevenueDetailPageState extends ConsumerState<RevenueDetailPage> {
  int _rangeMonths = 6; // default selection
  bool _showPerProperty = false;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final colors = ref.watch(dynamicColorsProvider);
    final payments = ref.watch(landlordPaymentsProvider);
    final properties = ref.watch(landlordPropertiesProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.revenueAnalytics),
        actions: [
          IconButton(
            tooltip: l10n.close,
            onPressed: () => context.pop(),
            icon: const Icon(Icons.close),
          )
        ],
      ),
      body: LayoutBuilder(
        builder: (context, constraints) {
          return SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildHeader(l10n, colors),
                const SizedBox(height: 28),
                _buildRangeSelector(l10n, colors),
                const SizedBox(height: 20),
                _buildModeToggle(l10n, colors),
                const SizedBox(height: 32),
                payments.when(
                  data: (paymentList) => properties.when(
                    data: (propertyList) {
                      final filtered = paymentList
                          .where((p) => p.status == 'completed')
                          .where((p) => p.date.isAfter(DateTime.now()
                              .subtract(Duration(days: 30 * _rangeMonths))))
                          .toList();
                      if (_showPerProperty) {
                        return _buildPerPropertyBreakdown(
                            filtered, propertyList, colors, l10n);
                      } else {
                        return _buildAggregateChart(filtered, colors, l10n);
                      }
                    },
                    loading: _loading,
                    error: (e, st) =>
                        _error(colors, l10n.errorLoadingProperties),
                  ),
                  loading: _loading,
                  error: (e, st) =>
                      _error(colors, l10n.errorLoadingPaymentHistory),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _loading() => const Center(
      child: Padding(
          padding: EdgeInsets.all(40), child: CircularProgressIndicator()));
  Widget _error(DynamicAppColors colors, String msg) => Padding(
        padding: const EdgeInsets.all(32),
        child: Row(children: [
          Icon(Icons.error_outline, color: colors.error),
          const SizedBox(width: 12),
          Expanded(child: Text(msg))
        ]),
      );

  Widget _buildHeader(AppLocalizations l10n, DynamicAppColors colors) {
    return Text(
      l10n.revenueAnalytics,
      style: Theme.of(context)
          .textTheme
          .headlineMedium
          ?.copyWith(fontWeight: FontWeight.bold),
    );
  }

  Widget _buildRangeSelector(AppLocalizations l10n, DynamicAppColors colors) {
    final options = [3, 6, 12];
    return Wrap(
      spacing: 12,
      children: options.map((m) {
        final selected = _rangeMonths == m;
        return GestureDetector(
          onTap: () => setState(() => _rangeMonths = m),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 250),
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(22),
              gradient: selected
                  ? LinearGradient(colors: [
                      colors.success.withValues(alpha: 0.85),
                      colors.success.withValues(alpha: 0.55)
                    ])
                  : null,
              border: Border.all(
                  color: selected ? Colors.transparent : colors.borderLight),
            ),
            child: Text('${m}M',
                style: TextStyle(
                    color: selected ? Colors.white : colors.textSecondary,
                    fontWeight: FontWeight.w600)),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildModeToggle(AppLocalizations l10n, DynamicAppColors colors) {
    return Row(
      children: [
        Switch(
          value: _showPerProperty,
          onChanged: (v) => setState(() => _showPerProperty = v),
        ),
        const SizedBox(width: 8),
        Text(_showPerProperty ? 'Property Breakdown' : 'Aggregate View'),
      ],
    );
  }

  Widget _buildAggregateChart(
      List payments, DynamicAppColors colors, AppLocalizations l10n) {
    if (payments.isEmpty) {
      return const Padding(
        padding: EdgeInsets.only(top: 40),
        child: Text('No data'),
      );
    }
    final now = DateTime.now();
    final months = List.generate(_rangeMonths,
        (i) => DateTime(now.year, now.month - (_rangeMonths - 1 - i), 1));
    final monthKeys = months
        .map((d) => '${d.year}-${d.month.toString().padLeft(2, '0')}')
        .toList();
    final totals = {for (final k in monthKeys) k: 0.0};
    for (final p in payments) {
      final k = '${p.date.year}-${p.date.month.toString().padLeft(2, '0')}';
      if (totals.containsKey(k)) totals[k] = (totals[k] ?? 0) + p.amount;
    }
    final maxY = totals.values
        .fold<double>(0, (m, v) => v > m ? v : m)
        .clamp(1, double.infinity);
    final spots = <FlSpot>[];
    for (var i = 0; i < monthKeys.length; i++) {
      spots.add(FlSpot(i.toDouble(), totals[monthKeys[i]]!));
    }

    String monthLabel(int index) => index >= 0 && index < months.length
        ? DateFormat('MMM').format(months[index])
        : '';

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(28),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            colors.info.withValues(alpha: 0.85),
            colors.info.withValues(alpha: 0.55),
            colors.info.withValues(alpha: 0.25)
          ],
        ),
        border:
            Border.all(color: Colors.white.withValues(alpha: 0.15), width: 1.2),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.white.withValues(alpha: 0.25)),
              child:
                  const Icon(Icons.show_chart, color: Colors.white, size: 20),
            ),
            const SizedBox(width: 16),
            const Text('Aggregate View',
                style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w700,
                    fontSize: 18)),
          ]),
          const SizedBox(height: 24),
          SizedBox(
            height: 210,
            child: LineChart(
              LineChartData(
                minY: 0,
                maxY: maxY * 1.2,
                gridData: FlGridData(
                    show: true,
                    horizontalInterval:
                        maxY == 0 ? 1 : (maxY / 4).ceilToDouble(),
                    getDrawingHorizontalLine: (v) => FlLine(
                        color: Colors.white.withValues(alpha: 0.25),
                        strokeWidth: 1),
                    drawVerticalLine: false),
                titlesData: FlTitlesData(
                  leftTitles: AxisTitles(
                      sideTitles: SideTitles(
                          showTitles: true,
                          reservedSize: 44,
                          interval: maxY == 0 ? 1 : (maxY / 4).ceilToDouble(),
                          getTitlesWidget: (v, meta) => Padding(
                              padding: const EdgeInsets.only(right: 4),
                              child: Text(_compactCurrency(v),
                                  style: const TextStyle(
                                      fontSize: 10, color: Colors.white70))))),
                  bottomTitles: AxisTitles(
                      sideTitles: SideTitles(
                          showTitles: true,
                          interval: 1,
                          getTitlesWidget: (v, meta) => Padding(
                              padding: const EdgeInsets.only(top: 6),
                              child: Text(monthLabel(v.toInt()),
                                  style: const TextStyle(
                                      fontSize: 10, color: Colors.white70))))),
                  rightTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false)),
                  topTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false)),
                ),
                borderData: FlBorderData(show: false),
                lineTouchData: LineTouchData(
                    touchTooltipData: LineTouchTooltipData(
                        tooltipRoundedRadius: 10,
                        getTooltipItems: (spots) => spots.map((s) {
                              final idx = s.x.toInt();
                              return LineTooltipItem(
                                  '${monthLabel(idx)}\n${_formatCurrency(s.y)}',
                                  const TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.w600));
                            }).toList())),
                lineBarsData: [
                  LineChartBarData(
                    spots: spots,
                    isCurved: true,
                    gradient: LinearGradient(colors: [
                      Colors.white,
                      Colors.white.withValues(alpha: 0.7)
                    ]),
                    barWidth: 3,
                    dotData: FlDotData(
                        show: true,
                        getDotPainter: (spot, percent, bar, index) =>
                            FlDotCirclePainter(
                                radius: 4,
                                color: Colors.white,
                                strokeColor:
                                    Colors.white.withValues(alpha: 0.2),
                                strokeWidth: 2)),
                    belowBarData: BarAreaData(
                        show: true,
                        gradient: LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            colors: [
                              Colors.white.withValues(alpha: 0.30),
                              Colors.white.withValues(alpha: 0.03)
                            ])),
                  )
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPerPropertyBreakdown(List payments, List properties,
      DynamicAppColors colors, AppLocalizations l10n) {
    final now = DateTime.now();
    final from = DateTime(now.year, now.month - (_rangeMonths - 1), 1);
    final Map<String, double> totalsByProperty = {};
    for (final p in payments) {
      if (p.date.isBefore(from)) continue;
      totalsByProperty[p.propertyId] =
          (totalsByProperty[p.propertyId] ?? 0) + p.amount;
    }
    final items = properties.map((prop) {
      final total = totalsByProperty[prop.id] ?? 0.0;
      return {'name': prop.title ?? prop.address ?? prop.id, 'total': total};
    }).toList()
      ..sort((a, b) => (b['total'] as double).compareTo(a['total'] as double));

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Property Breakdown',
            style: Theme.of(context)
                .textTheme
                .titleLarge
                ?.copyWith(fontWeight: FontWeight.bold)),
        const SizedBox(height: 16),
        ...items.map((e) {
          final pct = items.first['total'] == 0
              ? 0.0
              : (e['total'] as double) / (items.first['total'] as double);
          return Padding(
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: Row(
              children: [
                Expanded(
                    child: Text(e['name'] as String,
                        maxLines: 1, overflow: TextOverflow.ellipsis)),
                const SizedBox(width: 12),
                SizedBox(
                  width: 140,
                  child: Stack(children: [
                    Container(
                        height: 10,
                        decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(6),
                            color: colors.borderLight.withValues(alpha: 0.4))),
                    FractionallySizedBox(
                        widthFactor: pct,
                        child: Container(
                            height: 10,
                            decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(6),
                                gradient: LinearGradient(colors: [
                                  colors.success.withValues(alpha: 0.85),
                                  colors.success.withValues(alpha: 0.55)
                                ]))))
                  ]),
                ),
                const SizedBox(width: 12),
                Text(_formatCurrency(e['total'] as double),
                    style: const TextStyle(fontWeight: FontWeight.w600)),
              ],
            ),
          );
        })
      ],
    );
  }

  String _formatCurrency(double amount) {
    // Use same logic from reports page via currencyProvider
    final currency = ref.read(currencyProvider);
    String symbol;
    switch (currency.toUpperCase()) {
      case 'USD':
        symbol = '\$';
        break;
      case 'EUR':
        symbol = '€';
        break;
      case 'CHF':
        symbol = 'CHF ';
        break;
      default:
        symbol = '\$';
    }
    return NumberFormat.currency(symbol: symbol, decimalDigits: 2)
        .format(amount);
  }

  String _compactCurrency(double v) {
    if (v >= 1000000) return '${(v / 1000000).toStringAsFixed(1)}M';
    if (v >= 1000) return '${(v / 1000).toStringAsFixed(1)}k';
    if (v == v.roundToDouble()) return v.toStringAsFixed(0);
    return v.toStringAsFixed(1);
  }
}
