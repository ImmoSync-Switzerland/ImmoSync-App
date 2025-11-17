import 'package:flutter_test/flutter_test.dart';
import 'package:intl/intl.dart';

import 'package:immosync/features/reports/services/pdf_exporter.dart';

void main() {
  test('buildFinancialReport returns non-empty pdf bytes', () async {
    final now = DateTime(2025, 9, 1);
    final months =
        List.generate(6, (i) => DateTime(now.year, now.month - (5 - i)));
    final revenue = [3000, 3450, 3900, 4350, 4800, 5250];
    final expenses = [1200, 1420, 1640, 1860, 2080, 2300];
    final occupancy = 0.92;
    final currency = NumberFormat.simpleCurrency(locale: 'en_US');

    final bytes = await PdfExporter.buildFinancialReport(
      currency: currency,
      months: months,
      revenue: revenue,
      expenses: expenses,
      occupancyRate: occupancy,
    );

    expect(bytes, isNotEmpty);
  });
}
