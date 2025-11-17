import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:immosync/core/providers/dynamic_colors_provider.dart';
import 'package:immosync/core/widgets/app_top_bar.dart';
import 'package:immosync/features/property/presentation/providers/property_providers.dart';
import 'package:immosync/core/providers/currency_provider.dart';
import 'package:immosync/l10n/app_localizations.dart';

class RevenueDetailsPage extends ConsumerWidget {
  const RevenueDetailsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = ref.watch(dynamicColorsProvider);
    final propertiesAsync = ref.watch(landlordPropertiesProvider);

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppTopBar(
        title: '',
        showNotification: false,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios, color: colors.textPrimary),
          onPressed: () => context.pop(),
        ),
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              colors.primaryAccent,
              colors.primaryAccent.withValues(alpha: 0.8),
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
                    data: (properties) =>
                        _buildContent(context, ref, colors, properties),
                    loading: () =>
                        const Center(child: CircularProgressIndicator()),
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

  Widget _buildHeader(BuildContext context, WidgetRef ref,
      DynamicAppColors colors, AsyncValue propertiesAsync) {
    final totalRevenue = propertiesAsync.maybeWhen(
      data: (properties) {
        final propertyList = properties as List;
        return propertyList.fold<double>(
          0.0,
          (sum, property) => sum + (property.rentAmount ?? 0.0),
        );
      },
      orElse: () => 0.0,
    );

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
                  Icons.trending_up,
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
                      AppLocalizations.of(context)!.monthlyRevenue,
                      style: TextStyle(
                        fontSize: 16,
                        color: Colors.white.withValues(alpha: 0.9),
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      ref
                          .read(currencyProvider.notifier)
                          .formatAmount(totalRevenue),
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

  Widget _buildContent(BuildContext context, WidgetRef ref,
      DynamicAppColors colors, List properties) {
    return ListView(
      padding: const EdgeInsets.all(24.0),
      children: [
        _buildRevenueOverview(context, ref, colors, properties),
        const SizedBox(height: 24),
        _buildRevenueByProperty(context, ref, colors, properties),
        const SizedBox(height: 24),
        _buildRevenueBreakdown(context, ref, colors, properties),
      ],
    );
  }

  Widget _buildRevenueOverview(BuildContext context, WidgetRef ref,
      DynamicAppColors colors, List properties) {
    final totalRevenue = properties.fold<double>(
      0.0,
      (sum, property) => sum + (property.rentAmount ?? 0.0),
    );
    final avgRevenuePerProperty =
        properties.isEmpty ? 0.0 : totalRevenue / properties.length;

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
            AppLocalizations.of(context)!.overview,
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
            AppLocalizations.of(context)!.totalRevenuePerMonth,
            ref.read(currencyProvider.notifier).formatAmount(totalRevenue),
            Icons.account_balance_wallet_outlined,
            colors.success,
          ),
          const SizedBox(height: 16),
          _buildOverviewItem(
            ref,
            colors,
            AppLocalizations.of(context)!.averagePerProperty,
            ref
                .read(currencyProvider.notifier)
                .formatAmount(avgRevenuePerProperty),
            Icons.home_outlined,
            colors.info,
          ),
          const SizedBox(height: 16),
          _buildOverviewItem(
            ref,
            colors,
            AppLocalizations.of(context)!.numberOfProperties,
            '${properties.length}',
            Icons.apartment_outlined,
            colors.primaryAccent,
          ),
        ],
      ),
    );
  }

  Widget _buildOverviewItem(WidgetRef ref, DynamicAppColors colors,
      String label, String value, IconData icon, Color color) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                color.withValues(alpha: 0.2),
                color.withValues(alpha: 0.1)
              ],
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

  Widget _buildRevenueByProperty(BuildContext context, WidgetRef ref,
      DynamicAppColors colors, List properties) {
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
            AppLocalizations.of(context)!.revenueByProperty,
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w700,
              color: colors.textPrimary,
            ),
          ),
          const SizedBox(height: 20),
          ...properties.map((property) => Padding(
                padding: const EdgeInsets.only(bottom: 16.0),
                child:
                    _buildPropertyRevenueItem(context, ref, colors, property),
              )),
        ],
      ),
    );
  }

  Widget _buildPropertyRevenueItem(BuildContext context, WidgetRef ref,
      DynamicAppColors colors, dynamic property) {
    final rent = property.rentAmount ?? 0.0;

    return Container(
      padding: const EdgeInsets.all(16.0),
      decoration: BoxDecoration(
        color: colors.surfaceCards,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: colors.borderLight,
          width: 1,
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 4,
            height: 48,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [colors.success, colors.successLight],
              ),
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  property.address?.street ??
                      AppLocalizations.of(context)!.unknownAddress,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: colors.textPrimary,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                Text(
                  '${property.address?.city ?? ''} ${property.address?.postalCode ?? ''}'
                      .trim(),
                  style: TextStyle(
                    fontSize: 14,
                    color: colors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          Text(
            ref.read(currencyProvider.notifier).formatAmount(rent),
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w700,
              color: colors.success,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRevenueBreakdown(BuildContext context, WidgetRef ref,
      DynamicAppColors colors, List properties) {
    final totalRevenue = properties.fold<double>(
      0.0,
      (sum, property) => sum + (property.rentAmount ?? 0.0),
    );

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
            AppLocalizations.of(context)!.revenueDistribution,
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w700,
              color: colors.textPrimary,
            ),
          ),
          const SizedBox(height: 20),
          _buildBreakdownItem(
            ref,
            colors,
            AppLocalizations.of(context)!.rentIncome,
            ref.read(currencyProvider.notifier).formatAmount(totalRevenue),
            totalRevenue > 0 ? 100.0 : 0.0,
            colors.success,
          ),
          const SizedBox(height: 12),
          _buildBreakdownItem(
            ref,
            colors,
            AppLocalizations.of(context)!.utilityCosts,
            ref.read(currencyProvider.notifier).formatAmount(0.0),
            0.0,
            colors.info,
          ),
          const SizedBox(height: 12),
          _buildBreakdownItem(
            ref,
            colors,
            AppLocalizations.of(context)!.otherIncome,
            ref.read(currencyProvider.notifier).formatAmount(0.0),
            0.0,
            colors.warning,
          ),
        ],
      ),
    );
  }

  Widget _buildBreakdownItem(WidgetRef ref, DynamicAppColors colors,
      String label, String amount, double percentage, Color color) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              label,
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w600,
                color: colors.textPrimary,
              ),
            ),
            Text(
              amount,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: color,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Stack(
          children: [
            Container(
              height: 8,
              decoration: BoxDecoration(
                color: colors.surfaceCards,
                borderRadius: BorderRadius.circular(4),
              ),
            ),
            FractionallySizedBox(
              widthFactor: percentage / 100,
              child: Container(
                height: 8,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [color, color.withValues(alpha: 0.7)],
                  ),
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }
}
