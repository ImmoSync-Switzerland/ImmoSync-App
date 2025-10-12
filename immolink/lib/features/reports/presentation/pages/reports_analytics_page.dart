import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:printing/printing.dart';

import '../../services/pdf_exporter.dart';

class ReportsAnalyticsPage extends StatelessWidget {
  const ReportsAnalyticsPage({super.key});

  @override
  Widget build(BuildContext context) {
    final colors = _Palette.fromTheme(Theme.of(context));
    // l10n available if needed later
    final locale = Localizations.localeOf(context).toString();
    final currency = NumberFormat.simpleCurrency(locale: locale);

    // Demo data – in real app, replace with repository/provider values
    final now = DateTime.now();
    final months =
        List.generate(6, (i) => DateTime(now.year, now.month - (5 - i)));
    final revenue = List.generate(6, (i) => 3000 + (i * 450));
    final expenses = List.generate(6, (i) => 1200 + (i * 220));
    final occupancyRate = 0.92;

    final totalRevenue = revenue.fold<int>(0, (sum, v) => sum + v);
    final totalExpenses = expenses.fold<int>(0, (sum, v) => sum + v);
    final net = totalRevenue - totalExpenses;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Reports & Analytics'),
        actions: [
          IconButton(
            tooltip: 'Export PDF',
            icon: const Icon(Icons.picture_as_pdf),
            onPressed: () async {
              await PdfExporter.exportFinancialReport(
                context: context,
                currency: currency,
                months: months,
                revenue: revenue,
                expenses: expenses,
                occupancyRate: occupancyRate,
                reportTitle: 'Reports & Analytics',
                revenueVsExpensesTitle: 'Revenue vs Expenses',
                totalRevenueLabel: 'Total Revenue',
                totalExpensesLabel: 'Total Expenses',
                netIncomeLabel: 'Net Income',
                occupancyLabel: 'Occupancy',
              );
            },
          ),
          IconButton(
            tooltip: 'Print',
            icon: const Icon(Icons.print),
            onPressed: () async {
              await Printing.layoutPdf(
                onLayout: (format) => PdfExporter.buildFinancialReport(
                  currency: currency,
                  months: months,
                  revenue: revenue,
                  expenses: expenses,
                  occupancyRate: occupancyRate,
                  format: format,
                  reportTitle: 'Reports & Analytics',
                  revenueVsExpensesTitle: 'Revenue vs Expenses',
                  totalRevenueLabel: 'Total Revenue',
                  totalExpensesLabel: 'Total Expenses',
                  netIncomeLabel: 'Net Income',
                  occupancyLabel: 'Occupancy',
                ),
              );
            },
          ),
        ],
      ),
      body: Container(
        color: colors.surfaceBackground,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            _KpiRow(
              colors: colors,
              items: [
                _Kpi(
                  label: 'Total Revenue',
                  value: currency.format(totalRevenue.toDouble()),
                  icon: Icons.trending_up,
                  color: colors.success,
                ),
                _Kpi(
                  label: 'Total Expenses',
                  value: currency.format(totalExpenses.toDouble()),
                  icon: Icons.trending_down,
                  color: colors.danger,
                ),
                _Kpi(
                  label: 'Net Income',
                  value: currency.format(net.toDouble()),
                  icon: Icons.account_balance_wallet,
                  color: net >= 0 ? colors.success : colors.danger,
                ),
                _Kpi(
                  label: 'Occupancy',
                  value: NumberFormat.percentPattern().format(occupancyRate),
                  icon: Icons.home_work,
                  color: colors.info,
                ),
              ],
            ),
            const SizedBox(height: 16),
            _SectionCard(
              title: 'Revenue vs Expenses',
              colors: colors,
              child: _BarChart(
                months: months,
                revenue: revenue,
                expenses: expenses,
                colors: colors,
              ),
            ),
            const SizedBox(height: 16),
            _SectionCard(
              title: 'Recent Activity',
              colors: colors,
              child: Column(
                children: List.generate(5, (i) {
                  return ListTile(
                    leading:
                        CircleAvatar(backgroundColor: colors.surfaceSecondary),
                    title: Text('Payment received - Unit ${101 + i}',
                        style: TextStyle(color: colors.textPrimary)),
                    subtitle: Text(
                        DateFormat.yMMMd()
                            .format(now.subtract(Duration(days: i * 3))),
                        style: TextStyle(color: colors.textSecondary)),
                    trailing: Text(
                      currency.format(1000 + i * 50),
                      style: TextStyle(
                          color: colors.textPrimary,
                          fontWeight: FontWeight.w600),
                    ),
                  );
                }),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _KpiRow extends StatelessWidget {
  const _KpiRow({required this.items, required this.colors});

  final List<_Kpi> items;
  final _Palette colors;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isWide = constraints.maxWidth > 800;
        final crossAxisCount = isWide ? 4 : 2;
        return GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: crossAxisCount,
            mainAxisSpacing: 12,
            crossAxisSpacing: 12,
            childAspectRatio: isWide ? 3.2 : 2.8,
          ),
          itemCount: items.length,
          itemBuilder: (context, index) =>
              _KpiCard(item: items[index], colors: colors),
        );
      },
    );
  }
}

class _Kpi {
  final String label;
  final String value;
  final IconData icon;
  final Color color;
  const _Kpi(
      {required this.label,
      required this.value,
      required this.icon,
      required this.color});
}

class _KpiCard extends StatelessWidget {
  const _KpiCard({required this.item, required this.colors});
  final _Kpi item;
  final _Palette colors;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: colors.surfaceCards,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
              color: colors.shadowColor.withValues(alpha: 0.06),
              blurRadius: 12,
              offset: const Offset(0, 6)),
        ],
      ),
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          CircleAvatar(
            backgroundColor: item.color.withValues(alpha: 0.15),
            child: Icon(item.icon, color: item.color),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(item.label, style: TextStyle(color: colors.textSecondary)),
                const SizedBox(height: 4),
                Text(item.value,
                    style: TextStyle(
                        color: colors.textPrimary,
                        fontSize: 18,
                        fontWeight: FontWeight.bold)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _SectionCard extends StatelessWidget {
  const _SectionCard(
      {required this.title, required this.colors, required this.child});
  final String title;
  final Widget child;
  final _Palette colors;
  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: colors.surfaceCards,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
              color: colors.shadowColor.withValues(alpha: 0.06),
              blurRadius: 12,
              offset: const Offset(0, 6)),
        ],
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title,
              style: TextStyle(
                  color: colors.textPrimary,
                  fontSize: 16,
                  fontWeight: FontWeight.w600)),
          const SizedBox(height: 12),
          child,
        ],
      ),
    );
  }
}

class _BarChart extends StatelessWidget {
  const _BarChart(
      {required this.months,
      required this.revenue,
      required this.expenses,
      required this.colors});
  final List<DateTime> months;
  final List<int> revenue;
  final List<int> expenses;
  final _Palette colors;

  @override
  Widget build(BuildContext context) {
    final maxValue = math
        .max(
          revenue.fold<int>(0, (s, v) => math.max(s, v)),
          expenses.fold<int>(0, (s, v) => math.max(s, v)),
        )
        .toDouble();
    return LayoutBuilder(
      builder: (context, constraints) {
        final barWidth = 14.0;
        final groupSpacing = 28.0;
        final chartHeight = 180.0;
        return SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: SizedBox(
            width: months.length * (barWidth * 2 + groupSpacing) + 24,
            height: chartHeight + 28,
            child: CustomPaint(
              painter: _BarChartPainter(
                months: months,
                revenue: revenue,
                expenses: expenses,
                colors: colors,
                maxValue: maxValue,
                barWidth: barWidth,
                chartHeight: chartHeight,
                groupSpacing: groupSpacing,
              ),
            ),
          ),
        );
      },
    );
  }
}

class _BarChartPainter extends CustomPainter {
  _BarChartPainter({
    required this.months,
    required this.revenue,
    required this.expenses,
    required this.colors,
    required this.maxValue,
    required this.barWidth,
    required this.chartHeight,
    required this.groupSpacing,
  });
  final List<DateTime> months;
  final List<int> revenue;
  final List<int> expenses;
  final _Palette colors;
  final double maxValue;
  final double barWidth;
  final double chartHeight;
  final double groupSpacing;

  @override
  void paint(Canvas canvas, Size size) {
    final paintRevenue = Paint()..color = colors.success;
    final paintExpenses = Paint()..color = colors.danger;
    final labelStyle = TextStyle(color: colors.textSecondary, fontSize: 11);
    final monthFormat = DateFormat.MMM();

    for (var i = 0; i < months.length; i++) {
      final x = 12 + i * (barWidth * 2 + groupSpacing);
      final revH = (revenue[i] / maxValue) * chartHeight;
      final expH = (expenses[i] / maxValue) * chartHeight;

      final revRect =
          Rect.fromLTWH(x.toDouble(), chartHeight - revH, barWidth, revH);
      final expRect =
          Rect.fromLTWH(x + barWidth + 6, chartHeight - expH, barWidth, expH);
      canvas.drawRRect(
          RRect.fromRectAndRadius(revRect, const Radius.circular(4)),
          paintRevenue);
      canvas.drawRRect(
          RRect.fromRectAndRadius(expRect, const Radius.circular(4)),
          paintExpenses);

      final tp = TextPainter(
        text: TextSpan(text: monthFormat.format(months[i]), style: labelStyle),
        textDirection: ui.TextDirection.ltr,
      )..layout();
      tp.paint(canvas, Offset(x + 2, chartHeight + 6));
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _Palette {
  final Color surfaceBackground;
  final Color surfaceCards;
  final Color surfaceSecondary;
  final Color textPrimary;
  final Color textSecondary;
  final Color shadowColor;
  final Color success;
  final Color danger;
  final Color info;

  _Palette({
    required this.surfaceBackground,
    required this.surfaceCards,
    required this.surfaceSecondary,
    required this.textPrimary,
    required this.textSecondary,
    required this.shadowColor,
    required this.success,
    required this.danger,
    required this.info,
  });

  factory _Palette.fromTheme(ThemeData theme) {
    final scheme = theme.colorScheme;
    final onSurface = scheme.onSurface;
    final secondaryText =
        theme.textTheme.bodyMedium?.color?.withValues(alpha: 0.7) ??
            onSurface.withValues(alpha: 0.7);
    return _Palette(
      surfaceBackground: theme.scaffoldBackgroundColor,
      surfaceCards: scheme.surface,
      surfaceSecondary: theme.cardColor.withValues(alpha: 0.5),
      textPrimary: onSurface,
      textSecondary: secondaryText,
      shadowColor: Colors.black,
      success: Colors.teal,
      danger: Colors.redAccent,
      info: Colors.blueAccent,
    );
  }
}
