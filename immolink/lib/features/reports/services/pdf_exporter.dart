import 'dart:typed_data';

import 'package:flutter/material.dart' show BuildContext;
import 'package:intl/intl.dart';
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
    String reportTitle = 'Reports & Analytics',
    String revenueVsExpensesTitle = 'Revenue vs Expenses',
    String totalRevenueLabel = 'Total Revenue',
    String totalExpensesLabel = 'Total Expenses',
    String netIncomeLabel = 'Net Income',
    String occupancyLabel = 'Occupancy',
    String? monthlyRevenueLabel,
    String? monthlyRevenueValue,
    String? collectedLabel,
    String? collectedValue,
    String? outstandingLabel,
    String? outstandingValue,
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
      reportTitle: reportTitle,
      revenueVsExpensesTitle: revenueVsExpensesTitle,
      totalRevenueLabel: totalRevenueLabel,
      totalExpensesLabel: totalExpensesLabel,
      netIncomeLabel: netIncomeLabel,
      occupancyLabel: occupancyLabel,
      monthlyRevenueLabel: monthlyRevenueLabel,
      monthlyRevenueValue: monthlyRevenueValue,
      collectedLabel: collectedLabel,
      collectedValue: collectedValue,
      outstandingLabel: outstandingLabel,
      outstandingValue: outstandingValue,
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
    String reportTitle = 'Reports & Analytics',
    String revenueVsExpensesTitle = 'Revenue vs Expenses',
    String totalRevenueLabel = 'Total Revenue',
    String totalExpensesLabel = 'Total Expenses',
    String netIncomeLabel = 'Net Income',
    String occupancyLabel = 'Occupancy',
    String? monthlyRevenueLabel,
    String? monthlyRevenueValue,
    String? collectedLabel,
    String? collectedValue,
    String? outstandingLabel,
    String? outstandingValue,
    bool showOccupancy = true,
    String? altKpiLabel,
    String? altKpiValue,
    PdfPageFormat? format,
  }) async {
    final doc = pw.Document();
    final df = DateFormat.yMMMM();

    final totalRevenue = revenue.fold<int>(0, (s, v) => s + v);
    final totalExpenses = expenses.fold<int>(0, (s, v) => s + v);
    final net = totalRevenue - totalExpenses;

    final headerStyle = pw.TextStyle(fontSize: 20, fontWeight: pw.FontWeight.bold);
    final labelStyle = pw.TextStyle(fontSize: 10, color: PdfColors.grey700);
    final valueStyle = pw.TextStyle(fontSize: 12, fontWeight: pw.FontWeight.bold);

    doc.addPage(
      pw.MultiPage(
        pageFormat: format ?? PdfPageFormat.a4,
        build: (ctx) => [
          pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
            children: [
              pw.Text(reportTitle, style: headerStyle),
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
          _revenueTable(months, revenue, expenses, df, currency, labelStyle),
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
  ) {
    final headers = ['Month', 'Revenue', 'Expenses', 'Net'];
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
