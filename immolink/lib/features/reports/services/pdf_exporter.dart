import 'dart:typed_data';

import 'package:flutter/material.dart' show BuildContext;
import 'package:intl/intl.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

class PdfExporter {
  static Future<void> exportFinancialReport({
    required BuildContext context,
    required NumberFormat currency,
    required List<DateTime> months,
    required List<int> revenue,
    required List<int> expenses,
    required double occupancyRate,
    String? locale,
    String reportTitle = 'Reports & Analytics',
    String revenueVsExpensesTitle = 'Revenue vs Expenses',
    String totalRevenueLabel = 'Total Revenue',
    String totalExpensesLabel = 'Total Expenses',
    String netIncomeLabel = 'Net Income',
    String occupancyLabel = 'Occupancy',
    String? reportModeLabel,
  String? logoAssetPath,
    String? monthlyRevenueLabel,
    String? monthlyRevenueValue,
    String? collectedLabel,
    String? collectedValue,
    String? outstandingLabel,
    String? outstandingValue,
    String monthHeader = 'Month',
    String revenueHeader = 'Revenue',
    String expensesHeader = 'Expenses',
    String netHeader = 'Net',
    bool showOccupancy = true,
    String? altKpiLabel,
    String? altKpiValue,
  }) async {
    final bytes = await buildFinancialReport(
      currency: currency,
      months: months,
      revenue: revenue,
      expenses: expenses,
      occupancyRate: occupancyRate,
      locale: locale,
      reportTitle: reportTitle,
      revenueVsExpensesTitle: revenueVsExpensesTitle,
      totalRevenueLabel: totalRevenueLabel,
      totalExpensesLabel: totalExpensesLabel,
      netIncomeLabel: netIncomeLabel,
      occupancyLabel: occupancyLabel,
  reportModeLabel: reportModeLabel,
  logoAssetPath: logoAssetPath,
      monthlyRevenueLabel: monthlyRevenueLabel,
      monthlyRevenueValue: monthlyRevenueValue,
      collectedLabel: collectedLabel,
      collectedValue: collectedValue,
      outstandingLabel: outstandingLabel,
      outstandingValue: outstandingValue,
      monthHeader: monthHeader,
      revenueHeader: revenueHeader,
      expensesHeader: expensesHeader,
      netHeader: netHeader,
      showOccupancy: showOccupancy,
      altKpiLabel: altKpiLabel,
      altKpiValue: altKpiValue,
    );
    await Printing.sharePdf(bytes: bytes, filename: 'financial_report.pdf');
  }

  static Future<Uint8List> buildFinancialReport({
    required NumberFormat currency,
    required List<DateTime> months,
    required List<int> revenue,
    required List<int> expenses,
    required double occupancyRate,
    String? locale,
    String reportTitle = 'Reports & Analytics',
    String revenueVsExpensesTitle = 'Revenue vs Expenses',
    String totalRevenueLabel = 'Total Revenue',
    String totalExpensesLabel = 'Total Expenses',
    String netIncomeLabel = 'Net Income',
    String occupancyLabel = 'Occupancy',
    String? reportModeLabel,
  String? logoAssetPath,
    String? monthlyRevenueLabel,
    String? monthlyRevenueValue,
    String? collectedLabel,
    String? collectedValue,
    String? outstandingLabel,
    String? outstandingValue,
    String monthHeader = 'Month',
    String revenueHeader = 'Revenue',
    String expensesHeader = 'Expenses',
    String netHeader = 'Net',
    bool showOccupancy = true,
    String? altKpiLabel,
    String? altKpiValue,
    PdfPageFormat? format,
  }) async {
    // Try to use embedded fonts from assets if available, else fallback.
    pw.Document doc;
    try {
      final regularData = await rootBundle.load('assets/fonts/NotoSans-Regular.ttf');
      final boldData = await rootBundle.load('assets/fonts/NotoSans-Bold.ttf');
      final base = pw.Font.ttf(regularData);
      final bold = pw.Font.ttf(boldData);
      doc = pw.Document(theme: pw.ThemeData.withFont(base: base, bold: bold));
    } catch (_) {
      doc = pw.Document();
    }
    final df = DateFormat.yMMMM(locale);

    final totalRevenue = revenue.fold<int>(0, (s, v) => s + v);
    final totalExpenses = expenses.fold<int>(0, (s, v) => s + v);
    final net = totalRevenue - totalExpenses;

    final headerStyle = pw.TextStyle(fontSize: 20, fontWeight: pw.FontWeight.bold);
    final labelStyle = pw.TextStyle(fontSize: 10, color: PdfColors.grey700);
    final valueStyle = pw.TextStyle(fontSize: 12, fontWeight: pw.FontWeight.bold);

    // Preload logo if provided
    pw.MemoryImage? logoImage;
    if (logoAssetPath != null) {
      try {
        final data = await rootBundle.load(logoAssetPath);
        logoImage = pw.MemoryImage(
          data.buffer.asUint8List(),
        );
      } catch (_) {}
    }

    doc.addPage(
      pw.MultiPage(
        pageFormat: format ?? PdfPageFormat.a4,
        build: (ctx) => [
          pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
            crossAxisAlignment: pw.CrossAxisAlignment.center,
            children: [
              pw.Row(children: [
                if (logoImage != null) ...[
                  pw.Container(
                    width: 24,
                    height: 24,
                    margin: const pw.EdgeInsets.only(right: 8),
                    child: pw.Image(logoImage),
                  ),
                ],
                pw.Text(reportTitle, style: headerStyle),
                if (reportModeLabel != null) ...[
                  pw.SizedBox(width: 8),
                  pw.Container(
                    padding: const pw.EdgeInsets.symmetric(vertical: 2, horizontal: 8),
                    decoration: pw.BoxDecoration(
                      color: PdfColors.grey200,
                      borderRadius: pw.BorderRadius.circular(999),
                      border: pw.Border.all(color: PdfColors.grey400, width: 0.5),
                    ),
                    child: pw.Text(reportModeLabel, style: pw.TextStyle(fontSize: 10, color: PdfColors.grey700)),
                  ),
                ],
              ]),
              pw.Text(DateFormat.yMMMd().format(DateTime.now())),
            ],
          ),
          pw.SizedBox(height: 12),
          pw.Container(height: 1, color: PdfColors.grey300),
          pw.SizedBox(height: 12),

          // KPIs
          pw.Wrap(
            spacing: 12,
            runSpacing: 12,
            children: [
              if (monthlyRevenueLabel != null && monthlyRevenueValue != null)
                _kpi(monthlyRevenueLabel, _sanitizeText(monthlyRevenueValue), labelStyle, valueStyle),
              if (collectedLabel != null && collectedValue != null)
                _kpi(collectedLabel, _sanitizeText(collectedValue), labelStyle, valueStyle),
              if (outstandingLabel != null && outstandingValue != null)
                _kpi(outstandingLabel, _sanitizeText(outstandingValue), labelStyle, valueStyle),
              _kpi(totalRevenueLabel, _fmtCurrency(currency, totalRevenue.toDouble()), labelStyle, valueStyle),
              _kpi(totalExpensesLabel, _fmtCurrency(currency, totalExpenses.toDouble()), labelStyle, valueStyle),
              _kpi(netIncomeLabel, _fmtCurrency(currency, net.toDouble()), labelStyle, valueStyle),
              if (showOccupancy)
                _kpi(occupancyLabel, NumberFormat.percentPattern().format(occupancyRate), labelStyle, valueStyle)
              else if (altKpiLabel != null && altKpiValue != null)
                _kpi(altKpiLabel, altKpiValue, labelStyle, valueStyle),
            ],
          ),
          pw.SizedBox(height: 18),

          pw.Text(revenueVsExpensesTitle, style: pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold)),
          pw.SizedBox(height: 8),
          _barChart(months: months, revenue: revenue, expenses: expenses, locale: locale),
          pw.SizedBox(height: 8),
          _revenueTable(months, revenue, expenses, df, currency, labelStyle, monthHeader, revenueHeader, expensesHeader, netHeader),
        ],
      ),
    );

    return doc.save();
  }

  static pw.Widget _kpi(String label, String value, pw.TextStyle labelStyle, pw.TextStyle valueStyle) {
    return pw.Container(
      width: 180,
      padding: const pw.EdgeInsets.all(10),
      decoration: pw.BoxDecoration(
        border: pw.Border.all(color: PdfColors.grey300),
        borderRadius: pw.BorderRadius.circular(8),
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text(label, style: labelStyle),
          pw.SizedBox(height: 4),
          pw.Text(value, style: valueStyle),
        ],
      ),
    );
  }

  static pw.Widget _revenueTable(
    List<DateTime> months,
    List<int> revenue,
    List<int> expenses,
    DateFormat df,
    NumberFormat currency,
    pw.TextStyle labelStyle,
    String monthHeader,
    String revenueHeader,
    String expensesHeader,
    String netHeader,
  ) {
    final headers = [monthHeader, revenueHeader, expensesHeader, netHeader];
    final data = List.generate(months.length, (i) {
      final net = revenue[i] - expenses[i];
      return [
        df.format(months[i]),
        _fmtCurrency(currency, revenue[i].toDouble()),
        _fmtCurrency(currency, expenses[i].toDouble()),
        _fmtCurrency(currency, net.toDouble()),
      ];
    });

    return pw.TableHelper.fromTextArray(
      headers: headers,
      data: data,
      headerStyle: pw.TextStyle(fontWeight: pw.FontWeight.bold),
      headerDecoration: const pw.BoxDecoration(color: PdfColor.fromInt(0xFFEFEFEF)),
      cellStyle: const pw.TextStyle(fontSize: 10),
      border: pw.TableBorder.all(color: PdfColors.grey300, width: 0.5),
      cellAlignment: pw.Alignment.centerLeft,
      headerAlignment: pw.Alignment.centerLeft,
      columnWidths: {
        0: const pw.FixedColumnWidth(140),
        1: const pw.FlexColumnWidth(1),
        2: const pw.FlexColumnWidth(1),
        3: const pw.FlexColumnWidth(1),
      },
    );
  }

  static pw.Widget _barChart({
    required List<DateTime> months,
    required List<int> revenue,
    required List<int> expenses,
    String? locale,
  }) {
    final labels = months
        .map((m) => DateFormat.MMM(locale).format(m))
        .toList();
    final maxVal = [
      ...revenue.map((e) => e.abs()),
      ...expenses.map((e) => e.abs()),
    ].fold<int>(0, (a, b) => a > b ? a : b);
    final safeMax = maxVal == 0 ? 1 : maxVal;
    const chartHeight = 80.0;
    const barWidth = 6.0;
    const gap = 10.0;

    return pw.Container(
      padding: const pw.EdgeInsets.symmetric(vertical: 6),
      child: pw.Row(
        crossAxisAlignment: pw.CrossAxisAlignment.end,
        children: List.generate(months.length, (i) {
          final revH = (revenue[i] / safeMax) * chartHeight;
          final expH = (expenses[i] / safeMax) * chartHeight;
          return pw.Container(
            margin: const pw.EdgeInsets.symmetric(horizontal: 4),
            child: pw.Column(
              mainAxisAlignment: pw.MainAxisAlignment.end,
              children: [
                pw.Row(
                  crossAxisAlignment: pw.CrossAxisAlignment.end,
                  children: [
                    pw.Container(width: barWidth, height: revH, color: PdfColors.green600),
                    pw.SizedBox(width: 2),
                    pw.Container(width: barWidth, height: expH, color: PdfColors.red600),
                  ],
                ),
                pw.SizedBox(height: 4),
                pw.Text(labels[i], style: const pw.TextStyle(fontSize: 8, color: PdfColors.grey700)),
              ],
            ),
          );
        }),
      ),
    );
  }

  // Replace characters that are not embedded in the default PDF font
  // e.g., U+2019 (right single quotation mark) used in de_CH as thousands separator
  static String _sanitizeText(String s) {
    return s
        .replaceAll('\u2019', "'")
        .replaceAll('\u00A0', ' ')
        .replaceAll('\u202F', ' ');
  }

  static String _fmtCurrency(NumberFormat currency, num value) {
    final formatted = currency.format(value);
    return _sanitizeText(formatted);
  }
}
