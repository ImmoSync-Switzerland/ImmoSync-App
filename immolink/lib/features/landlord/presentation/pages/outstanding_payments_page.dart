import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:immosync/core/providers/dynamic_colors_provider.dart';
import 'package:immosync/core/widgets/app_top_bar.dart';
import 'package:immosync/features/property/presentation/providers/property_providers.dart';
import 'package:immosync/core/providers/currency_provider.dart';

class OutstandingPaymentsPage extends ConsumerWidget {
  const OutstandingPaymentsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = ref.watch(dynamicColorsProvider);
    final propertiesAsync = ref.watch(landlordPropertiesProvider);

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: const AppTopBar(
        title: '',
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              colors.warning,
              colors.warning.withValues(alpha: 0.8),
            ],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              // Header
              _buildHeader(context, ref, colors, propertiesAsync),
              const SizedBox(height: 24),
              // Content
              Expanded(
                child: Container(
                  decoration: BoxDecoration(
                    color: colors.primaryBackground,
                    borderRadius: const BorderRadius.only(
                      topLeft: Radius.circular(32),
                      topRight: Radius.circular(32),
                    ),
                  ),
                  child: propertiesAsync.when(
                    data: (properties) => _buildContent(context, ref, colors, properties),
                    loading: () => const Center(child: CircularProgressIndicator()),
                    error: (error, stack) => Center(
                      child: Text('Fehler: $error'),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context, WidgetRef ref, DynamicAppColors colors, AsyncValue propertiesAsync) {
    // For demo purposes, using 0 outstanding - will be replaced with actual data
    final totalOutstanding = 0.0;

    return Padding(
      padding: const EdgeInsets.all(24.0),
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
                  Icons.warning,
                  size: 32,
                  color: Colors.white,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Ausstehende Zahlungen',
                      style: TextStyle(
                        fontSize: 16,
                        color: Colors.white.withValues(alpha: 0.9),
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      ref.read(currencyProvider.notifier).formatAmount(totalOutstanding),
                      style: const TextStyle(
                        fontSize: 36,
                        fontWeight: FontWeight.w900,
                        color: Colors.white,
                        letterSpacing: -1.2,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildContent(BuildContext context, WidgetRef ref, DynamicAppColors colors, List properties) {
    // For demo purposes, showing message when no outstanding payments
    // In production, this would show actual outstanding payment data
    return ListView(
      padding: const EdgeInsets.all(24.0),
      children: [
        _buildOverview(ref, colors),
        const SizedBox(height: 24),
        _buildEmptyState(ref, colors),
      ],
    );
  }

  Widget _buildOverview(WidgetRef ref, DynamicAppColors colors) {
    return Container(
      padding: const EdgeInsets.all(20.0),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.06),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Übersicht',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w700,
              color: colors.textPrimary,
            ),
          ),
          const SizedBox(height: 20),
          _buildOverviewItem(
            ref,
            colors,
            'Offene Zahlungen',
            '0',
            Icons.receipt_long_outlined,
            colors.warning,
          ),
          const SizedBox(height: 16),
          _buildOverviewItem(
            ref,
            colors,
            'Überfällige Zahlungen',
            '0',
            Icons.error_outline,
            colors.error,
          ),
          const SizedBox(height: 16),
          _buildOverviewItem(
            ref,
            colors,
            'Gesamtbetrag',
            ref.read(currencyProvider.notifier).formatAmount(0.0),
            Icons.account_balance_wallet_outlined,
            colors.info,
          ),
        ],
      ),
    );
  }

  Widget _buildOverviewItem(WidgetRef ref, DynamicAppColors colors, String label, String value, IconData icon, Color color) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [color.withValues(alpha: 0.2), color.withValues(alpha: 0.1)],
            ),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(icon, color: color, size: 24),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(
                  fontSize: 14,
                  color: colors.textSecondary,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                value,
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: colors.textPrimary,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildEmptyState(WidgetRef ref, DynamicAppColors colors) {
    return Container(
      padding: const EdgeInsets.all(40.0),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.06),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  colors.success.withValues(alpha: 0.2),
                  colors.success.withValues(alpha: 0.1),
                ],
              ),
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.check_circle_outline,
              size: 64,
              color: colors.success,
            ),
          ),
          const SizedBox(height: 24),
          Text(
            'Keine ausstehenden Zahlungen',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w700,
              color: colors.textPrimary,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 12),
          Text(
            'Alle Mietzahlungen sind aktuell.',
            style: TextStyle(
              fontSize: 15,
              color: colors.textSecondary,
              height: 1.5,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}
