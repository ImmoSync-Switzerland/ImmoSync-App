import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../../l10n/app_localizations.dart';
import 'package:immosync/features/auth/presentation/providers/user_role_provider.dart';
import 'package:immosync/features/payment/presentation/providers/payment_providers.dart';
import 'package:immosync/features/property/presentation/providers/property_providers.dart';
import 'package:immosync/features/maintenance/presentation/providers/maintenance_providers.dart';
import 'package:immosync/core/widgets/common_bottom_nav.dart';
import 'package:immosync/core/providers/currency_provider.dart';
import 'package:immosync/core/providers/dynamic_colors_provider.dart';
import 'package:intl/intl.dart';
import 'package:immosync/features/reports/services/pdf_exporter.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:visibility_detector/visibility_detector.dart';
import 'package:immosync/features/reports/presentation/utils/report_gradients.dart';
import 'dart:ui' as ui; // For BackdropFilter

class ReportsPage extends ConsumerStatefulWidget {
  const ReportsPage({super.key});

  @override
  ConsumerState<ReportsPage> createState() => _ReportsPageState();
}

// Animated numeric value widget (count-up) used for KPI cards (outside state class)
class _AnimatedValue extends StatefulWidget {
  final String
      displayValue; // Original formatted value (e.g., CHF 1,230.00 / 75%)
  final double? numericValue; // Parsed numeric portion if available
  const _AnimatedValue({required this.displayValue, this.numericValue});

  @override
  State<_AnimatedValue> createState() => _AnimatedValueState();
}

class _AnimatedValueState extends State<_AnimatedValue>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _anim;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 900));
    _anim = CurvedAnimation(parent: _controller, curve: Curves.easeOutCubic);
    // Stagger a bit for nicer cascade
    Future.delayed(
        const Duration(milliseconds: 60), () => _controller.forward());
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final target = widget.numericValue;
    return AnimatedBuilder(
      animation: _anim,
      builder: (context, _) {
        String text;
        if (target != null) {
          final current = target * _anim.value;
          // Preserve percent sign or currency prefix/suffix heuristically
          if (widget.displayValue.trim().endsWith('%')) {
            text = '${current.toStringAsFixed(0)}%';
          } else {
            // Try detect currency prefix (e.g., CHF, €, $)
            final match = RegExp(r'^[A-Z€$£]{1,4}')
                .firstMatch(widget.displayValue.replaceAll(',', ''));
            if (match != null) {
              text =
                  '${match.group(0)} ${current.toStringAsFixed(current >= 1000 ? 0 : 2)}';
            } else {
              text = current.toStringAsFixed(current >= 1000 ? 0 : 2);
            }
          }
        } else {
          text = widget.displayValue; // fallback (non-numeric)
        }
        return FittedBox(
          fit: BoxFit.scaleDown,
          child: Text(
            text,
            style: const TextStyle(
              fontSize: 26,
              fontWeight: FontWeight.w800,
              letterSpacing: -0.9,
              color: Colors.white,
            ),
          ),
        );
      },
    );
  }
}

class _ReportsPageState extends ConsumerState<ReportsPage>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  // Period selector removed
  // Track visibility for staggered section animations
  // Expanded to 7 to allow unique indices across landlord & tenant variants
  final List<bool> _sectionVisible = List<bool>.filled(6, false);
  bool _visibilityInitialized = false;
  final revenueRangeProvider = StateProvider<int>((ref) => 6);

  // Helper method for responsive font sizes
  double _getResponsiveFontSize(BuildContext context, double baseFontSize) {
    final screenWidth = MediaQuery.of(context).size.width;
    if (screenWidth < 360) {
      return baseFontSize * 0.85; // Smaller phones
    } else if (screenWidth < 400) {
      return baseFontSize * 0.9; // Medium phones
    }
    return baseFontSize; // Tablets and larger
  }

  void _safeHaptic() {
    try {
      HapticFeedback.lightImpact();
    } catch (_) {}
  }

  // Reusable glass header icon (circular, blurred, subtle accent glow)
  Widget _glassHeaderIcon(IconData icon, Color accent) {
    return Container(
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color: accent.withValues(alpha: 0.55),
            blurRadius: 28,
            spreadRadius: 2,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: ClipOval(
        child: BackdropFilter(
          filter: ui.ImageFilter.blur(sigmaX: 18, sigmaY: 18),
          child: Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  accent.withValues(alpha: 1.0),
                  accent.withValues(alpha: 0.55),
                  accent.withValues(alpha: 0.22),
                ],
              ),
              border: Border.all(
                color: Colors.white.withValues(alpha: 0.55),
                width: 1.4,
              ),
            ),
            child: Icon(icon, color: Colors.white, size: 26),
          ),
        ),
      ),
    );
  }

  void _showCardDetail(String title) {
    // Fallback simple dialog
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: Text(title),
        content: const Text('No further data available.'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Close'))
        ],
      ),
    );
  }

  Future<void> _showFinancialDetailDialog(
      AppLocalizations l10n,
      AsyncValue properties,
      AsyncValue payments,
      DynamicAppColors colors) async {
    final props = await properties.whenData((value) => value).valueOrNull ?? [];
    final pays = await payments.whenData((value) => value).valueOrNull ?? [];
    final totalRevenue = props
        .where((p) => p.status == 'rented')
        .fold<double>(0, (s, p) => s + p.rentAmount);
    final collected = pays
        .where((p) => p.status == 'completed')
        .fold<double>(0, (s, p) => s + p.amount);
    final outstanding = pays
        .where((p) => p.status == 'pending')
        .fold<double>(0, (s, p) => s + p.amount);
    showDialog(
        context: context,
        builder: (_) => AlertDialog(
              title: Text(l10n.financialOverview),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _detailRow(
                      l10n.monthlyRevenue, _formatCurrency(totalRevenue)),
                  _detailRow(l10n.collected, _formatCurrency(collected)),
                  _detailRow(l10n.outstanding, _formatCurrency(outstanding)),
                  const Divider(),
                  Text(l10n.analyticsAndReports,
                      style: const TextStyle(fontWeight: FontWeight.w600)),
                ],
              ),
              actions: [
                TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: Text(l10n.close))
              ],
            ));
  }

  Future<void> _showTenantPaymentDetailDialog(AppLocalizations l10n,
      AsyncValue payments, DynamicAppColors colors) async {
    final list = await payments.whenData((v) => v).valueOrNull ?? [];
    final totalPaid = list
        .where((p) => p.status == 'completed')
        .fold<double>(0, (s, p) => s + p.amount);
    final pending = list
        .where((p) => p.status == 'pending')
        .fold<double>(0, (s, p) => s + p.amount);
    showDialog(
        context: context,
        builder: (_) => AlertDialog(
              title: Text(l10n.paymentSummary),
              content: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _detailRow(l10n.totalPaid, _formatCurrency(totalPaid)),
                    _detailRow(l10n.pending, _formatCurrency(pending)),
                    _detailRow(l10n.totalPayments, list.length.toString()),
                  ]),
              actions: [
                TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: Text(l10n.close))
              ],
            ));
  }

  Future<void> _showPropertyDetailDialog(AppLocalizations l10n,
      AsyncValue properties, DynamicAppColors colors) async {
    final list = await properties.whenData((v) => v).valueOrNull ?? [];
    final total = list.length;
    final rented = list.where((p) => p.status == 'rented').length;
    final available = list.where((p) => p.status == 'available').length;
    final occupancy = total == 0 ? 0 : (rented / total * 100).round();
    showDialog(
        context: context,
        builder: (_) => AlertDialog(
              title: Text(l10n.propertyOverview),
              content: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _detailRow(l10n.totalProperties, total.toString()),
                    _detailRow(l10n.occupied, rented.toString()),
                    _detailRow(l10n.available, available.toString()),
                    _detailRow(l10n.occupancyRate, '$occupancy%'),
                  ]),
              actions: [
                TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: Text(l10n.close))
              ],
            ));
  }

  Widget _detailRow(String label, String value) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: Row(children: [
          Expanded(child: Text(label)),
          Text(value, style: const TextStyle(fontWeight: FontWeight.w600))
        ]),
      );

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeOutCubic,
    ));
    _animationController.forward();
    // Visibility handled by VisibilityDetector per section
    // Initialize localized period labels after first frame to access context
    WidgetsBinding.instance.addPostFrameCallback((_) {
      // Period selector removed; hook retained for future re-introduction if needed
    });
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final userRole = ref.watch(userRoleProvider);
    final isLandlord = userRole == 'landlord';
    final colors = ref.watch(dynamicColorsProvider);

    return Scaffold(
      backgroundColor: colors.primaryBackground,
      appBar: AppBar(
        elevation: 0,
        backgroundColor: colors.surfaceCards,
        surfaceTintColor: Colors.transparent,
        systemOverlayStyle: SystemUiOverlayStyle.dark,
        leading: IconButton(
          onPressed: () {
            if (context.canPop()) {
              context.pop();
            } else {
              context.go('/home');
            }
          },
          icon: Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: colors.surfaceSecondary,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              Icons.arrow_back_ios_new,
              color: colors.textSecondary,
              size: 18,
            ),
          ),
        ),
        title: Text(
          l10n.analyticsAndReports,
          style: TextStyle(
            fontSize: _getResponsiveFontSize(context, 22),
            fontWeight: FontWeight.w800,
            color: colors.textPrimary,
            letterSpacing: -0.6,
          ),
        ),
        actions: const [],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(
            height: 1,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  Colors.transparent,
                  colors.borderLight.withValues(alpha: 0.5),
                  Colors.transparent,
                ],
              ),
            ),
          ),
        ),
      ),
      body: FadeTransition(
        opacity: _fadeAnimation,
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Modern hero header & period selector
              _buildHeroHeader(l10n, isLandlord, colors),
              const SizedBox(height: 28),
              _buildModernReport(isLandlord, l10n, colors),
              const SizedBox(height: 24), // Bottom padding for better scroll experience
            ],
          ),
        ),
      ),
      bottomNavigationBar: const CommonBottomNav(),
    );
  }

  Widget _buildHeroHeader(
      AppLocalizations l10n, bool isLandlord, DynamicAppColors colors) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            const Color(0xFF3B82F6).withValues(alpha: 0.95),
            const Color(0xFF8B5CF6).withValues(alpha: 0.85),
          ],
        ),
        borderRadius: BorderRadius.circular(32),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF3B82F6).withValues(alpha: 0.3),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        children: [
          // Header Icon
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Icon(
              isLandlord ? Icons.analytics_rounded : Icons.insights_rounded,
              color: Colors.white,
              size: 32,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            isLandlord ? l10n.analyticsAndReports : l10n.paymentSummary,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.w900,
              color: Colors.white,
              letterSpacing: -0.5,
              height: 1.2,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            isLandlord ? l10n.financialOverview : l10n.recentActivity,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: Colors.white.withValues(alpha: 0.85),
              height: 1.4,
            ),
          ),
          const SizedBox(height: 20),
          // Export Button
          GestureDetector(
            onTap: _showExportDialog,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.25),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: Colors.white.withValues(alpha: 0.4),
                  width: 1,
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.picture_as_pdf_rounded,
                    color: Colors.white,
                    size: 20,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    l10n.export.toUpperCase(),
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 0.5,
                      color: Colors.white,
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 24),
          _buildKpiStrip(isLandlord, l10n, colors),
        ],
      ),
    );
  }

  Widget _buildExportPill(AppLocalizations l10n, DynamicAppColors colors) {
    return GestureDetector(
      onTap: _showExportDialog,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(32),
          gradient: LinearGradient(
            colors: [colors.info, colors.primaryAccent],
          ),
          boxShadow: [
            BoxShadow(
              color: colors.info.withValues(alpha: 0.4),
              blurRadius: 20,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.picture_as_pdf_outlined, size: 18, color: Colors.white),
            const SizedBox(width: 8),
            Text(
              l10n.export,
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                letterSpacing: 0.3,
                color: Colors.white,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildKpiStrip(
      bool isLandlord, AppLocalizations l10n, DynamicAppColors colors) {
    final payments = ref
        .watch(isLandlord ? landlordPaymentsProvider : tenantPaymentsProvider);
    final maintenance = ref.watch(isLandlord
        ? landlordMaintenanceRequestsProvider
        : tenantMaintenanceRequestsProvider);
    final properties = isLandlord
        ? ref.watch(landlordPropertiesProvider)
        : ref.watch(tenantPropertiesProvider);

    return LayoutBuilder(builder: (context, constraints) {
      final width = constraints.maxWidth;
      int columns;
      if (width < 340) {
        columns = 1;
      } else if (width < 560) {
        columns = 2;
      } else if (width < 820) {
        columns = isLandlord ? 3 : 3;
      } else {
        columns = isLandlord ? 4 : 3; // tenant has fewer KPIs
      }
      final spacing = 14.0;
      final cardWidth = (width - spacing * (columns - 1)) / columns;

      List<Widget> cards = [
        _asyncKpiCard(
          label: l10n.collected,
          asyncValue: payments,
          icon: Icons.check_circle_outline,
          color: colors.success,
          valueBuilder: (list) => _formatCurrency(list
              .where((p) => p.status == 'completed')
              .fold<double>(0, (s, p) => s + p.amount)),
          minWidth: cardWidth,
        ),
        _asyncKpiCard(
          label: l10n.outstanding,
          asyncValue: payments,
          icon: Icons.hourglass_bottom,
          color: colors.warning,
          valueBuilder: (list) => _formatCurrency(list
              .where((p) => p.status == 'pending')
              .fold<double>(0, (s, p) => s + p.amount)),
          minWidth: cardWidth,
        ),
      ];
      if (isLandlord) {
        cards.add(
          _asyncKpiCard(
            label: l10n.occupancyRate,
            asyncValue: properties,
            icon: Icons.apartment_outlined,
            color: colors.info,
            valueBuilder: (list) {
              final total = list.length;
              final rented = list.where((p) => p.status == 'rented').length;
              final rate = total == 0 ? 0 : (rented / total * 100);
              return '${rate.toStringAsFixed(0)}%';
            },
            minWidth: cardWidth,
          ),
        );
      }
      cards.add(
        _asyncKpiCard(
          label: l10n.maintenance,
          asyncValue: maintenance,
          icon: Icons.build_circle_outlined,
          color: colors.error,
          valueBuilder: (list) => list
              .where((r) => r.status != 'completed' && r.status != 'closed')
              .length
              .toString(),
          minWidth: cardWidth,
        ),
      );

      return Wrap(
        spacing: spacing,
        runSpacing: spacing,
        children:
            cards.map((c) => SizedBox(width: cardWidth, child: c)).toList(),
      );
    });
  }

  Widget _asyncKpiCard<T>({
    required String label,
    required AsyncValue<List<T>> asyncValue,
    required String Function(List<T>) valueBuilder,
    required IconData icon,
    required Color color,
    required double minWidth,
  }) {
    return _HoverScale(
      onTap: () => _showCardDetail(label),
      child: FocusableActionDetector(
        mouseCursor: SystemMouseCursors.click,
        onShowFocusHighlight: (_) => setState(() {}),
        child: AnimatedSize(
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
          child: Container(
            constraints: BoxConstraints(minWidth: minWidth, maxWidth: 260),
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(24),
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  color.withValues(alpha: 0.65),
                  color.withValues(alpha: 0.35),
                ],
              ),
              border:
                  Border.all(color: color.withValues(alpha: 0.65), width: 1.5),
              boxShadow: [
                BoxShadow(
                    color: color.withValues(alpha: 0.4),
                    blurRadius: 12,
                    offset: const Offset(0, 5))
              ],
            ),
            child: asyncValue.when(
              data: (data) =>
                  _kpiContent(label, valueBuilder(data), icon, color),
              loading: () => _kpiShimmer(label, icon, color),
              error: (_, __) => _kpiError(label, icon, color),
            ),
          ),
        ),
      ),
    );
  }

  Widget _kpiContent(String label, String value, IconData icon, Color color) {
    // Detect numeric for animated count-up
    final numeric = double.tryParse(value.replaceAll(RegExp(r'[^0-9.,-]'), ''));
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: Colors.white.withValues(alpha: 0.22),
            border: Border.all(color: Colors.white.withValues(alpha: 0.35), width: 1.5),
          ),
          child: Icon(icon, size: 24, color: Colors.white),
        ),
        const SizedBox(height: 16),
        _AnimatedValue(
          displayValue: value,
          numericValue: numeric,
        ),
        const SizedBox(height: 8),
        Text(
          label.toUpperCase(),
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 10.5,
            fontWeight: FontWeight.w700,
            letterSpacing: 1.0,
            color: Colors.white.withValues(alpha: 0.9),
          ),
        ),
      ],
    );
  }

  Widget _kpiShimmer(String label, IconData icon, Color color) {
    return Row(
      children: [
        Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: color.withValues(alpha: 0.15),
          ),
          child: Icon(icon, color: color.withValues(alpha: 0.5), size: 20),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                  height: 16,
                  width: 80,
                  decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(6),
                      color: color.withValues(alpha: 0.25))),
              const SizedBox(height: 6),
              Container(
                  height: 10,
                  width: 60,
                  decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(4),
                      color: color.withValues(alpha: 0.18))),
              const SizedBox(height: 2),
              Text(label.toUpperCase(),
                  style: TextStyle(
                      fontSize: 9,
                      color: color.withValues(alpha: 0.4),
                      letterSpacing: 0.6)),
            ],
          ),
        ),
      ],
    );
  }

  Widget _kpiError(String label, IconData icon, Color color) {
    return Row(
      children: [
        Icon(icon, color: color, size: 20),
        const SizedBox(width: 8),
        Expanded(
            child: Text('—',
                style: TextStyle(
                    fontSize: 18, fontWeight: FontWeight.bold, color: color))),
        Text(label.toUpperCase(), style: TextStyle(fontSize: 10)),
      ],
    );
  }

  Widget _buildModernReport(
      bool isLandlord, AppLocalizations l10n, DynamicAppColors colors) {
    // Use existing detailed sections below but wrap them into a modern layered container set
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Range selector for revenue (syncs with detail view)
        _animatedSection(0, _buildRevenueRangeSelector(colors, l10n)),
        const SizedBox(height: 12),
        // Removed duplicate large header (already shown in hero header above) to avoid visual duplication
        if (isLandlord)
          _animatedSection(1, _buildLandlordReports(context, ref, l10n))
        else
          _animatedSection(1, _buildTenantReports(context, ref, l10n)),
      ],
    );
  }

  Widget _buildRevenueRangeSelector(
      DynamicAppColors colors, AppLocalizations l10n) {
    final range = ref.watch(revenueRangeProvider);
    final options = const [3, 6, 12];
    return Wrap(
      spacing: 12,
      children: options.map((m) {
        final selected = m == range;
        return _HoverScale(
          onTap: () => ref.read(revenueRangeProvider.notifier).state = m,
          child: FocusableActionDetector(
            mouseCursor: SystemMouseCursors.click,
            onShowFocusHighlight: (_) => setState(() {}),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 250),
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(22),
                gradient: selected
                    ? ReportGradients.glassAccent(colors.success,
                        isDark: colors.isDark)
                    : null,
                border: Border.all(
                    color: selected
                        ? Colors.white.withValues(alpha: 0.4)
                        : colors.borderLight),
                boxShadow: selected
                    ? [
                        BoxShadow(
                            color: colors.success.withValues(alpha: 0.35),
                            blurRadius: 12,
                            offset: const Offset(0, 4))
                      ]
                    : null,
              ),
              child: Text('${m}M',
                  style: TextStyle(
                      color: selected ? Colors.white : colors.textSecondary,
                      fontWeight: FontWeight.w600)),
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _animatedSection(int index, Widget child) {
    final visible =
        index < _sectionVisible.length ? _sectionVisible[index] : true;
    return VisibilityDetector(
      key: Key('report-sec-$index'),
      onVisibilityChanged: (info) {
        if (!_visibilityInitialized && info.visibleFraction > 0.1) {
          _visibilityInitialized = true;
        }
        if (info.visibleFraction > 0.35 && !_sectionVisible[index]) {
          setState(() => _sectionVisible[index] = true);
        }
      },
      child: AnimatedOpacity(
        duration: const Duration(milliseconds: 650),
        curve: Curves.easeOutCubic,
        opacity: visible ? 1 : 0,
        child: AnimatedSlide(
          duration: const Duration(milliseconds: 650),
          curve: Curves.easeOutCubic,
          offset: visible ? Offset.zero : const Offset(0, 0.12),
          child: child,
        ),
      ),
    );
  }

// (AnimatedValue moved to end of file)

  void _showExportDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(AppLocalizations.of(context)!.exportReportsTitle),
        content: Text(AppLocalizations.of(context)!.exportFormatPrompt),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(AppLocalizations.of(context)!.cancel),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              _exportToPDF();
            },
            child: Text(AppLocalizations.of(context)!.exportPdf),
          ),
        ],
      ),
    );
  }

  // Period selector widgets removed

  Widget _buildLandlordReports(
      BuildContext context, WidgetRef ref, AppLocalizations l10n) {
    final properties = ref.watch(landlordPropertiesProvider);
    final payments = ref.watch(landlordPaymentsProvider);
    final maintenanceRequests = ref.watch(landlordMaintenanceRequestsProvider);
    final colors = ref.watch(dynamicColorsProvider);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _animatedSection(2,
            _buildFinancialOverview(properties, payments, ref, l10n, colors)),
        const SizedBox(height: 24),
        _animatedSection(3, _buildPropertyMetrics(properties, l10n, colors)),
        const SizedBox(height: 24),
        _animatedSection(
            4, _buildMaintenanceOverview(maintenanceRequests, l10n, colors)),
        const SizedBox(height: 24),
        _animatedSection(
            5, _buildRevenueChart(properties, payments, ref, l10n, colors)),
      ],
    );
  }

  Widget _buildTenantReports(
      BuildContext context, WidgetRef ref, AppLocalizations l10n) {
    final payments = ref.watch(tenantPaymentsProvider);
    final maintenanceRequests = ref.watch(tenantMaintenanceRequestsProvider);
    final colors = ref.watch(dynamicColorsProvider);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _animatedSection(
            2, _buildTenantPaymentSummary(payments, ref, l10n, colors)),
        const SizedBox(height: 24),
        _animatedSection(3,
            _buildTenantMaintenanceHistory(maintenanceRequests, l10n, colors)),
        const SizedBox(height: 24),
        _animatedSection(4, _buildPaymentHistory(payments, ref, l10n, colors)),
      ],
    );
  }

  Widget _buildFinancialOverview(AsyncValue properties, AsyncValue payments,
      WidgetRef ref, AppLocalizations l10n, DynamicAppColors colors) {
    final accent = colors.success;
    return _HoverScale(
        onTap: () =>
            _showFinancialDetailDialog(l10n, properties, payments, colors),
        child: Container(
          padding: const EdgeInsets.all(26),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(28),
            gradient:
                ReportGradients.glassAccent(accent, isDark: colors.isDark),
            border: Border.all(
                color: Colors.white.withValues(alpha: 0.15), width: 1.2),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Title icon (left) with title underneath (stacked)
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: Colors.white.withValues(alpha: 0.25),
                    ),
                    child: const Icon(Icons.account_balance_wallet_outlined,
                        color: Colors.white, size: 22),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    l10n.financialOverview,
                    style: TextStyle(
                      fontSize: _getResponsiveFontSize(context, 20),
                      fontWeight: FontWeight.w800,
                      color: Colors.white,
                      letterSpacing: -0.5,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 28),
              properties.when(
                data: (propertyList) {
                  final totalRevenue = propertyList
                      .where((p) => p.status == 'rented')
                      .fold(0.0, (sum, p) => sum + p.rentAmount);

                  return payments.when(
                    data: (paymentsList) {
                      final completedPayments = paymentsList
                          .where((p) => p.status == 'completed')
                          .fold(0.0, (sum, p) => sum + p.amount);
                      final pendingPayments = paymentsList
                          .where((p) => p.status == 'pending')
                          .fold(0.0, (sum, p) => sum + p.amount);
                      return LayoutBuilder(builder: (context, c) {
                        final maxW = c.maxWidth;
                        // Each metric limited to 75% width of container (max 420) and centered horizontally
                        return Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _metricSizedBox(
                              child: _buildFinancialMetric(
                                  l10n.monthlyRevenue,
                                  _formatCurrency(totalRevenue),
                                  Icons.trending_up,
                                  Colors.white,
                                  colors),
                              parentWidth: maxW,
                            ),
                            const SizedBox(height: 22),
                            _metricSizedBox(
                              child: _buildFinancialMetric(
                                  l10n.collected,
                                  _formatCurrency(completedPayments),
                                  Icons.check_circle_outline,
                                  Colors.white,
                                  colors),
                              parentWidth: maxW,
                            ),
                            const SizedBox(height: 22),
                            _metricSizedBox(
                              child: _buildFinancialMetric(
                                  l10n.outstanding,
                                  _formatCurrency(pendingPayments),
                                  Icons.hourglass_empty,
                                  Colors.white,
                                  colors),
                              parentWidth: maxW,
                            ),
                          ],
                        );
                      });
                    },
                    loading: () =>
                        const Center(child: CircularProgressIndicator()),
                    error: (_, __) => Text(l10n.errorLoadingPaymentHistory,
                        style: const TextStyle(color: Colors.white70)),
                  );
                },
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (_, __) => Text(l10n.errorLoadingProperties,
                    style: const TextStyle(color: Colors.white70)),
              ),
            ],
          ),
        ));
  }

  String _formatCurrency(double amount) {
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

  Widget _buildFinancialMetric(String title, String value, IconData icon,
      Color color, DynamicAppColors colors) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 350),
      curve: Curves.easeOutCubic,
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 20),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Colors.white.withValues(alpha: 0.15),
            Colors.white.withValues(alpha: 0.05),
          ],
        ),
        border: Border.all(color: Colors.white.withValues(alpha: 0.25)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.white.withValues(alpha: 0.20),
            ),
            child: Icon(icon, size: 22, color: Colors.white),
          ),
          const SizedBox(height: 12),
          FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(
              value,
              style: TextStyle(
                fontSize: _getResponsiveFontSize(context, 18),
                fontWeight: FontWeight.w800,
                letterSpacing: -0.5,
                color: Colors.white,
              ),
            ),
          ),
          const SizedBox(height: 6),
          Text(
            title.toUpperCase(),
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: _getResponsiveFontSize(context, 10),
              fontWeight: FontWeight.w600,
              letterSpacing: 0.7,
              color: Colors.white.withValues(alpha: 0.85),
            ),
          ),
        ],
      ),
    );
  }

  Widget _metricSizedBox({required Widget child, required double parentWidth}) {
    final width = (parentWidth * 0.75).clamp(180.0, 420.0);
    return FractionallySizedBox(
      widthFactor: width / parentWidth,
      alignment: Alignment.centerLeft,
      child: child,
    );
  }

  Widget _buildPropertyMetrics(
      AsyncValue properties, AppLocalizations l10n, DynamicAppColors colors) {
    final accent = colors.info;
    return _HoverScale(
        onTap: () => _showPropertyDetailDialog(l10n, properties, colors),
        child: Container(
          padding: const EdgeInsets.all(26),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(28),
            gradient:
                ReportGradients.glassAccent(accent, isDark: colors.isDark),
            border: Border.all(
                color: Colors.white.withValues(alpha: 0.15), width: 1.2),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: Colors.white.withValues(alpha: 0.25),
                    ),
                    child: const Icon(Icons.home_work_outlined,
                        color: Colors.white, size: 22),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    l10n.propertyOverview,
                    style: TextStyle(
                      fontSize: _getResponsiveFontSize(context, 20),
                      fontWeight: FontWeight.w800,
                      color: Colors.white,
                      letterSpacing: -0.5,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 28),
              properties.when(
                data: (propertyList) {
                  final totalProperties = propertyList.length;
                  final rentedProperties =
                      propertyList.where((p) => p.status == 'rented').length;
                  final availableProperties =
                      propertyList.where((p) => p.status == 'available').length;
                  return LayoutBuilder(builder: (context, c) {
                    final maxW = c.maxWidth;
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _metricSizedBox(
                            child: _buildFinancialMetric(
                                l10n.totalProperties,
                                totalProperties.toString(),
                                Icons.home_outlined,
                                Colors.white,
                                colors),
                            parentWidth: maxW),
                        const SizedBox(height: 22),
                        _metricSizedBox(
                            child: _buildFinancialMetric(
                                l10n.occupied,
                                rentedProperties.toString(),
                                Icons.check_circle_outline,
                                Colors.white,
                                colors),
                            parentWidth: maxW),
                        const SizedBox(height: 22),
                        _metricSizedBox(
                            child: _buildFinancialMetric(
                                l10n.available,
                                availableProperties.toString(),
                                Icons.radio_button_unchecked,
                                Colors.white,
                                colors),
                            parentWidth: maxW),
                      ],
                    );
                  });
                },
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (_, __) => Text(l10n.errorLoadingProperties,
                    style: const TextStyle(color: Colors.white70)),
              ),
            ],
          ),
        ));
  }

  Widget _buildMaintenanceOverview(AsyncValue maintenanceRequests,
      AppLocalizations l10n, DynamicAppColors colors) {
    final accent = colors.warning;
    return Container(
      padding: const EdgeInsets.all(26),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(28),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            accent.withValues(alpha: 0.9),
            accent.withValues(alpha: 0.6),
            accent.withValues(alpha: 0.3)
          ],
        ),
        border:
            Border.all(color: Colors.white.withValues(alpha: 0.15), width: 1.2),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.white.withValues(alpha: 0.25),
                ),
                child: const Icon(Icons.build_circle_outlined,
                    color: Colors.white, size: 22),
              ),
              const SizedBox(height: 12),
              Text(
                l10n.maintenanceOverview,
                style: TextStyle(
                  fontSize: _getResponsiveFontSize(context, 20),
                  fontWeight: FontWeight.w800,
                  color: Colors.white,
                  letterSpacing: -0.5,
                ),
              ),
            ],
          ),
          const SizedBox(height: 28),
          maintenanceRequests.when(
            data: (requestList) {
              final totalRequests = requestList.length;
              final pendingRequests =
                  requestList.where((r) => r.status == 'pending').length;
              final completedRequests =
                  requestList.where((r) => r.status == 'completed').length;
              return LayoutBuilder(builder: (context, c) {
                final maxW = c.maxWidth;
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _metricSizedBox(
                        child: _buildFinancialMetric(
                            l10n.totalRequests,
                            totalRequests.toString(),
                            Icons.list_alt_outlined,
                            Colors.white,
                            colors),
                        parentWidth: maxW),
                    const SizedBox(height: 22),
                    _metricSizedBox(
                        child: _buildFinancialMetric(
                            l10n.pending,
                            pendingRequests.toString(),
                            Icons.hourglass_empty,
                            Colors.white,
                            colors),
                        parentWidth: maxW),
                    const SizedBox(height: 22),
                    _metricSizedBox(
                        child: _buildFinancialMetric(
                            l10n.completed,
                            completedRequests.toString(),
                            Icons.check_circle_outline,
                            Colors.white,
                            colors),
                        parentWidth: maxW),
                  ],
                );
              });
            },
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (_, __) => Text(l10n.errorLoadingMaintenanceData,
                style: const TextStyle(color: Colors.white70)),
          ),
        ],
      ),
    );
  }

  Widget _buildRevenueChart(AsyncValue properties, AsyncValue payments,
      WidgetRef ref, AppLocalizations l10n, DynamicAppColors colors) {
    return payments.when(
      data: (paymentsList) {
        // Aggregate last 6 months revenue from completed payments
        final rangeMonths = ref.watch(revenueRangeProvider);
        final now = DateTime.now();
        final months = List.generate(rangeMonths,
            (i) => DateTime(now.year, now.month - (rangeMonths - 1 - i), 1));
        final monthKeys = months
            .map((d) => '${d.year}-${d.month.toString().padLeft(2, '0')}')
            .toList();
        final totals = {for (final k in monthKeys) k: 0.0};
        for (final p in paymentsList.where((p) => p.status == 'completed')) {
          final k = '${p.date.year}-${p.date.month.toString().padLeft(2, '0')}';
          if (totals.containsKey(k)) totals[k] = (totals[k] ?? 0) + p.amount;
        }
        final maxY = (totals.values.fold<double>(0, (m, v) => v > m ? v : m))
            .clamp(1, double.infinity);
        final spots = <FlSpot>[];
        for (var i = 0; i < monthKeys.length; i++) {
          spots.add(FlSpot(i.toDouble(), totals[monthKeys[i]]!));
        }

        String monthLabel(int index) {
          if (index < 0 || index >= months.length) return '';
          return DateFormat('MMM').format(months[index]);
        }

        final accent = const Color(0xFF8B5CF6);
        final isDark = Theme.of(context).brightness == Brightness.dark;
        return _HoverScale(
          onTap: () {
            _safeHaptic();
            context.push('/reports/revenue-detail');
          },
          child: Container(
            padding: const EdgeInsets.all(28.0),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(28),
              gradient: ReportGradients.glassAccent(accent, isDark: isDark),
              border: Border.all(
                  color: Colors.white.withValues(alpha: 0.15), width: 1.2),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: Colors.white.withValues(alpha: 0.25),
                      ),
                      child: const Icon(Icons.trending_up,
                          color: Colors.white, size: 22),
                    ),
                    const SizedBox(width: 20),
                    Text(
                      l10n.revenueAnalytics,
                      style: TextStyle(
                        fontSize: _getResponsiveFontSize(context, 20),
                        fontWeight: FontWeight.w800,
                        color: Colors.white,
                        letterSpacing: -0.5,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                SizedBox(
                  height: 220,
                  child: LineChart(
                    LineChartData(
                      minY: 0,
                      maxY: maxY * 1.2,
                      gridData: FlGridData(
                        show: true,
                        horizontalInterval:
                            maxY == 0 ? 1 : (maxY / 4).ceilToDouble(),
                        getDrawingHorizontalLine: (value) => FlLine(
                          color: Colors.white.withValues(alpha: 0.25),
                          strokeWidth: 1,
                        ),
                        drawVerticalLine: false,
                      ),
                      titlesData: FlTitlesData(
                        leftTitles: AxisTitles(
                          sideTitles: SideTitles(
                            showTitles: true,
                            reservedSize: 44,
                            interval: maxY == 0 ? 1 : (maxY / 4).ceilToDouble(),
                            getTitlesWidget: (v, meta) => Padding(
                              padding: const EdgeInsets.only(right: 4),
                              child: Text(
                                _compactCurrency(v),
                                style: const TextStyle(
                                    fontSize: 10, color: Colors.white70),
                              ),
                            ),
                          ),
                        ),
                        bottomTitles: AxisTitles(
                          sideTitles: SideTitles(
                            showTitles: true,
                            interval: 1,
                            getTitlesWidget: (v, meta) => Padding(
                              padding: const EdgeInsets.only(top: 6),
                              child: Text(
                                monthLabel(v.toInt()),
                                style: const TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w600,
                                    color: Colors.white70),
                              ),
                            ),
                          ),
                        ),
                        rightTitles: const AxisTitles(
                            sideTitles: SideTitles(showTitles: false)),
                        topTitles: const AxisTitles(
                            sideTitles: SideTitles(showTitles: false)),
                      ),
                      borderData: FlBorderData(show: false),
                      lineTouchData: LineTouchData(
                        touchTooltipData: LineTouchTooltipData(
                          tooltipRoundedRadius: 10,
                          tooltipPadding: const EdgeInsets.symmetric(
                              horizontal: 12, vertical: 8),
                          tooltipMargin: 12,
                          fitInsideHorizontally: true,
                          fitInsideVertically: true,
                          getTooltipItems: (touched) => touched.map((barSpot) {
                            final idx = barSpot.x.toInt();
                            return LineTooltipItem(
                              '${monthLabel(idx)}\n${_formatCurrency(barSpot.y)}',
                              const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w700,
                                  fontSize: 12),
                            );
                          }).toList(),
                        ),
                      ),
                      lineBarsData: [
                        LineChartBarData(
                          spots: spots,
                          isCurved: true,
                          gradient: LinearGradient(
                            colors: [
                              Colors.white,
                              Colors.white.withValues(alpha: 0.75),
                            ],
                          ),
                          barWidth: 3,
                          dotData: FlDotData(
                            show: true,
                            getDotPainter: (spot, percent, bar, index) =>
                                FlDotCirclePainter(
                              radius: 4,
                              color: Colors.white,
                              strokeColor: Colors.white.withValues(alpha: 0.2),
                              strokeWidth: 2,
                            ),
                          ),
                          belowBarData: BarAreaData(
                            show: true,
                            gradient: LinearGradient(
                              begin: Alignment.topCenter,
                              end: Alignment.bottomCenter,
                              colors: [
                                Colors.white.withValues(alpha: 0.30),
                                Colors.white.withValues(alpha: 0.03),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
      loading: () => Container(
        padding: const EdgeInsets.all(32),
        decoration: BoxDecoration(
          color: colors.surfaceCards,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: colors.borderLight),
        ),
        child: const Center(child: CircularProgressIndicator()),
      ),
      error: (_, __) => Container(
        padding: const EdgeInsets.all(32),
        decoration: BoxDecoration(
          color: colors.surfaceCards,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: colors.error.withValues(alpha: 0.3)),
        ),
        child: Row(
          children: [
            Icon(Icons.error_outline, color: colors.error),
            const SizedBox(width: 12),
            Expanded(
                child: Text(l10n.errorLoadingPaymentHistory,
                    style: TextStyle(color: colors.textSecondary))),
          ],
        ),
      ),
    );
  }

  String _compactCurrency(double v) {
    if (v >= 1000000) return '${(v / 1000000).toStringAsFixed(1)}M';
    if (v >= 1000) return '${(v / 1000).toStringAsFixed(1)}k';
    if (v == v.roundToDouble()) return v.toStringAsFixed(0);
    return v.toStringAsFixed(1);
  }

  Widget _buildTenantMaintenanceHistory(AsyncValue maintenanceRequests,
      AppLocalizations l10n, DynamicAppColors colors) {
    return Container(
      padding: const EdgeInsets.all(24.0),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(32),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            const Color(0xFFEA580C).withValues(alpha: 0.95),
            const Color(0xFFDC2626).withValues(alpha: 0.85),
          ],
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFFEA580C).withValues(alpha: 0.3),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        children: [
          // Header
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Icon(
              Icons.build_rounded,
              color: Colors.white,
              size: 32,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            l10n.maintenanceRequests,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.w900,
              color: Colors.white,
              letterSpacing: -0.5,
              height: 1.2,
            ),
          ),
          const SizedBox(height: 24),
          maintenanceRequests.when(
            data: (requestList) {
              if (requestList.isEmpty) {
                return Container(
                  padding: const EdgeInsets.all(48),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(24),
                  ),
                  child: Column(
                    children: [
                      Icon(
                        Icons.check_circle_rounded,
                        size: 56,
                        color: Colors.white.withValues(alpha: 0.9),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        l10n.noMaintenanceRequests,
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: Colors.white.withValues(alpha: 0.9),
                        ),
                      ),
                    ],
                  ),
                );
              }

              return Column(
                children: requestList.take(5).map<Widget>((request) {
                  final statusColor = _getMaintenanceStatusColor(
                      request.status, colors);
                  final statusText = _formatStatusText(request.status);
                  
                  return Container(
                    margin: const EdgeInsets.only(bottom: 12),
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: Colors.white.withValues(alpha: 0.3),
                        width: 1,
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Container(
                              width: 48,
                              height: 48,
                              decoration: BoxDecoration(
                                color: Colors.white.withValues(alpha: 0.25),
                                borderRadius: BorderRadius.circular(16),
                              ),
                              child: Icon(
                                _getMaintenanceStatusIcon(request.status),
                                color: Colors.white,
                                size: 24,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    request.title,
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                    style: const TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w700,
                                      color: Colors.white,
                                      height: 1.3,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    DateFormat('MMM d, yyyy')
                                        .format(request.requestedDate),
                                    style: TextStyle(
                                      fontSize: 13,
                                      fontWeight: FontWeight.w500,
                                      color: Colors.white.withValues(alpha: 0.8),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 16, vertical: 8),
                          decoration: BoxDecoration(
                            color: statusColor.withValues(alpha: 0.9),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            statusText.toUpperCase(),
                            style: const TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w800,
                              letterSpacing: 0.5,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ],
                    ),
                  );
                }).toList(),
              );
            },
            loading: () => const Center(
              child: CircularProgressIndicator(color: Colors.white),
            ),
            error: (_, __) => Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(24),
              ),
              child: Text(
                l10n.errorLoadingMaintenanceRequests,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 14,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // Reintroduced payment history (simplified glass list similar to maintenance)
  Widget _buildPaymentHistory(AsyncValue payments, WidgetRef ref,
      AppLocalizations l10n, DynamicAppColors colors) {
    return Container(
      padding: const EdgeInsets.all(24.0),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(32),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            const Color(0xFF059669).withValues(alpha: 0.95),
            const Color(0xFF10B981).withValues(alpha: 0.85),
          ],
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF059669).withValues(alpha: 0.3),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        children: [
          // Header
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Icon(
              Icons.receipt_long_rounded,
              color: Colors.white,
              size: 32,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            l10n.paymentHistory,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.w900,
              color: Colors.white,
              letterSpacing: -0.5,
              height: 1.2,
            ),
          ),
          const SizedBox(height: 24),
          payments.when(
            data: (list) {
              if (list.isEmpty) {
                return Container(
                  padding: const EdgeInsets.all(48),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(24),
                  ),
                  child: Column(
                    children: [
                      Icon(
                        Icons.check_circle_rounded,
                        size: 56,
                        color: Colors.white.withValues(alpha: 0.9),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        l10n.noPaymentsFound,
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: Colors.white.withValues(alpha: 0.9),
                        ),
                      ),
                    ],
                  ),
                );
              }

              final limited = list.take(5).toList();
              return Column(
                children: limited.map<Widget>((p) {
                  final status = p.status?.toString() ?? '';
                  final amount =
                      (p.amount is num) ? (p.amount as num).toDouble() : 0.0;
                  Color statusColor;
                  IconData icon;
                  switch (status.toLowerCase()) {
                    case 'completed':
                      statusColor = const Color(0xFF10B981);
                      icon = Icons.check_circle_rounded;
                      break;
                    case 'pending':
                      statusColor = const Color(0xFFF59E0B);
                      icon = Icons.schedule_rounded;
                      break;
                    case 'failed':
                    case 'canceled':
                      statusColor = const Color(0xFFEF4444);
                      icon = Icons.cancel_rounded;
                      break;
                    default:
                      statusColor = const Color(0xFF3B82F6);
                      icon = Icons.payments_rounded;
                  }
                  
                  return Container(
                    margin: const EdgeInsets.only(bottom: 12),
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: Colors.white.withValues(alpha: 0.3),
                        width: 1,
                      ),
                    ),
                    child: Row(
                      children: [
                        Container(
                          width: 48,
                          height: 48,
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.25),
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: Icon(
                            icon,
                            color: Colors.white,
                            size: 24,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                _formatCurrency(amount),
                                style: const TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.w700,
                                  color: Colors.white,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 12, vertical: 4),
                                decoration: BoxDecoration(
                                  color: statusColor.withValues(alpha: 0.9),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Text(
                                  status.toUpperCase(),
                                  style: const TextStyle(
                                    fontSize: 10,
                                    fontWeight: FontWeight.w800,
                                    letterSpacing: 0.5,
                                    color: Colors.white,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  );
                }).toList(),
              );
            },
            loading: () => const Center(
              child: CircularProgressIndicator(color: Colors.white),
            ),
            error: (_, __) => Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(24),
              ),
              child: const Text(
                'Error loading payments',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 14,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTenantPaymentSummary(AsyncValue payments, WidgetRef ref,
      AppLocalizations l10n, DynamicAppColors colors) {
    return Container(
      padding: const EdgeInsets.all(24.0),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(32),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            const Color(0xFF059669).withValues(alpha: 0.95),
            const Color(0xFF10B981).withValues(alpha: 0.85),
          ],
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF059669).withValues(alpha: 0.3),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        children: [
          // Header
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Icon(
              Icons.account_balance_wallet_rounded,
              color: Colors.white,
              size: 32,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            l10n.paymentSummary,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.w900,
              color: Colors.white,
              letterSpacing: -0.5,
              height: 1.2,
            ),
          ),
          const SizedBox(height: 24),
          payments.when(
            data: (paymentsList) {
              final totalPaid = paymentsList
                  .where((p) => p.status == 'completed')
                  .fold(0.0, (sum, p) => sum + p.amount);
              final pendingAmount = paymentsList
                  .where((p) => p.status == 'pending')
                  .fold(0.0, (sum, p) => sum + p.amount);
              final totalPayments = paymentsList.length;

              return Column(
                children: [
                  // Total Paid Card
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: Colors.white.withValues(alpha: 0.3),
                        width: 1,
                      ),
                    ),
                    child: Column(
                      children: [
                        Icon(
                          Icons.check_circle_rounded,
                          color: Colors.white,
                          size: 40,
                        ),
                        const SizedBox(height: 12),
                        Text(
                          _formatCurrency(totalPaid),
                          style: const TextStyle(
                            fontSize: 32,
                            fontWeight: FontWeight.w900,
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          l10n.totalPaid.toUpperCase(),
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 1.0,
                            color: Colors.white.withValues(alpha: 0.9),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),
                  // Pending Card
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: Colors.white.withValues(alpha: 0.3),
                        width: 1,
                      ),
                    ),
                    child: Column(
                      children: [
                        Icon(
                          Icons.schedule_rounded,
                          color: Colors.white,
                          size: 40,
                        ),
                        const SizedBox(height: 12),
                        Text(
                          _formatCurrency(pendingAmount),
                          style: const TextStyle(
                            fontSize: 32,
                            fontWeight: FontWeight.w900,
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          l10n.pending.toUpperCase(),
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 1.0,
                            color: Colors.white.withValues(alpha: 0.9),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),
                  // Total Payments Card
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: Colors.white.withValues(alpha: 0.3),
                        width: 1,
                      ),
                    ),
                    child: Column(
                      children: [
                        Icon(
                          Icons.receipt_long_rounded,
                          color: Colors.white,
                          size: 40,
                        ),
                        const SizedBox(height: 12),
                        Text(
                          totalPayments.toString(),
                          style: const TextStyle(
                            fontSize: 32,
                            fontWeight: FontWeight.w900,
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          l10n.totalPayments.toUpperCase(),
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 1.0,
                            color: Colors.white.withValues(alpha: 0.9),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              );
            },
            loading: () => const Center(
              child: CircularProgressIndicator(color: Colors.white),
            ),
            error: (_, __) => Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(24),
              ),
              child: Text(
                l10n.errorLoadingPaymentSummary,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 14,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // Safely compute a target width based on a fraction while ensuring
  // we don't create non-normalized BoxConstraints (min > max).
  double _safeTargetWidth(double parentWidth,
      {required double minW,
      required double maxW,
      bool enforceMinOnlyIfFits = false}) {
    // Desired is 75% of parent.
    double desired = parentWidth * 0.75;
    // Cap by max first.
    double capped = desired.clamp(0, maxW);
    // If parent is smaller than minW we just use parent width (avoid > parent).
    if (parentWidth < minW) return parentWidth;
    // Optionally only enforce the min when result still <= parent.
    if (enforceMinOnlyIfFits) {
      if (capped < minW && minW <= parentWidth) return minW;
      return capped;
    }
    // Standard branch: clamp between minW and maxW but not exceeding parent.
    double withMin = capped < minW ? minW : capped;
    if (withMin > parentWidth) return parentWidth;
    return withMin;
  }

  Color _getMaintenanceStatusColor(String status, DynamicAppColors colors) {
    switch (status.toLowerCase()) {
      case 'completed':
        return colors.success;
      case 'in_progress':
        return colors.info;
      case 'pending':
        return colors.warning;
      case 'closed':
        return Colors.grey;
      default:
        return colors.textSecondary;
    }
  }

  IconData _getMaintenanceStatusIcon(String status) {
    switch (status.toLowerCase()) {
      case 'completed':
        return Icons.check_circle_outline;
      case 'in_progress':
        return Icons.engineering;
      case 'pending':
        return Icons.hourglass_empty;
      default:
        return Icons.help_outline;
    }
  }

  String _formatStatusText(String status) {
    // Convert underscores to spaces and capitalize properly
    return status
        .toLowerCase()
        .replaceAll('_', ' ')
        .split(' ')
        .map((word) =>
            word.isNotEmpty ? word[0].toUpperCase() + word.substring(1) : '')
        .join(' ');
  }

  Future<void> _exportToPDF() async {
    final colors = ref.read(dynamicColorsProvider);

    try {
      // Ask for export mode: Actual (Ist) vs Planned (Soll)
      final l10n = AppLocalizations.of(context)!;
      final isPlanned = await showDialog<bool>(
        context: context,
        barrierDismissible: true,
        builder: (ctx) {
          bool planned = false;
          return StatefulBuilder(
            builder: (context, setState) => AlertDialog(
              title: Text(l10n.analyticsAndReports),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  RadioListTile<bool>(
                    value: false,
                    groupValue: planned,
                    onChanged: (v) => setState(() => planned = v ?? false),
                    title: Text(l10n.actual),
                  ),
                  RadioListTile<bool>(
                    value: true,
                    groupValue: planned,
                    onChanged: (v) => setState(() => planned = v ?? false),
                    title: Text(l10n.planned),
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(null),
                  child: Text(l10n.cancel),
                ),
                ElevatedButton(
                  onPressed: () => Navigator.of(context).pop(planned),
                  child: Text(l10n.generateReport),
                ),
              ],
            ),
          );
        },
      );

      if (isPlanned == null) {
        // User cancelled
        return;
      }

      // Show loading dialog now
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => AlertDialog(
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const CircularProgressIndicator(),
              const SizedBox(height: 16),
              Text(AppLocalizations.of(context)!.generatingPdfReport),
            ],
          ),
        ),
      );
      // Determine role
      final userRole = ref.read(userRoleProvider);
      final isLandlord = userRole == 'landlord';

      // Build last 6 months list (oldest -> newest)
      final now = DateTime.now();
      final months = List<DateTime>.generate(
        6,
        (i) => DateTime(now.year, now.month - (5 - i), 1),
      );

      // Helpers to map dates to yyyy-MM keys
      String keyFor(DateTime d) =>
          '${d.year}-${d.month.toString().padLeft(2, '0')}';

      // Initialize maps for sums
      final revenueByMonth = <String, double>{
        for (final m in months) keyFor(m): 0.0,
      };
      final expensesByMonth = <String, double>{
        for (final m in months) keyFor(m): 0.0,
      };

      // Load payments (role-specific)
      final payments = await (isLandlord
          ? ref.read(landlordPaymentsProvider.future)
          : ref.read(tenantPaymentsProvider.future));

      int pendingCount = 0;
      int completedCount = 0;
      double collectedSum = 0.0;
      double outstandingSum = 0.0;
      for (final p in payments) {
        final status = (p.status).toLowerCase();
        if (status == 'completed') {
          completedCount++;
          collectedSum += p.amount;
          if (!isPlanned) {
            final k = keyFor(DateTime(p.date.year, p.date.month, 1));
            if (revenueByMonth.containsKey(k)) {
              revenueByMonth[k] = (revenueByMonth[k] ?? 0) + p.amount;
            }
          }
        } else if (status == 'pending') {
          pendingCount++;
          outstandingSum += p.amount;
        }
      }

      // Load maintenance to approximate expenses from actual/estimated cost
      final maintenance = await (isLandlord
          ? ref.read(landlordMaintenanceRequestsProvider.future)
          : ref.read(tenantMaintenanceRequestsProvider.future));

      for (final r in maintenance) {
        final when = r.completedDate ?? r.scheduledDate ?? r.requestedDate;
        final k = keyFor(DateTime(when.year, when.month, 1));
        final double cost;
        if (isPlanned) {
          // planned: take estimated only
          cost = r.cost?.estimated ?? 0.0;
        } else {
          // actual: take actual if present else estimated
          cost = r.cost?.actual ?? r.cost?.estimated ?? 0.0;
        }
        if (expensesByMonth.containsKey(k)) {
          expensesByMonth[k] = (expensesByMonth[k] ?? 0) + cost;
        }
      }

      // If planned: fill revenue per month with monthly rent sums instead of payments
      if (isPlanned) {
        double monthlyPlannedRevenue = 0.0;
        try {
          if (isLandlord) {
            final properties =
                await ref.read(landlordPropertiesProvider.future);
            monthlyPlannedRevenue = properties
                .where((p) => p.status.toLowerCase() == 'rented')
                .fold<double>(0.0, (sum, p) => sum + p.rentAmount);
          } else {
            final tenantProps = await ref.read(tenantPropertiesProvider.future);
            monthlyPlannedRevenue =
                tenantProps.fold<double>(0.0, (sum, p) => sum + p.rentAmount);
          }
        } catch (_) {}
        for (final m in months) {
          final k = keyFor(m);
          revenueByMonth[k] = monthlyPlannedRevenue;
        }
      }

      // Convert to aligned int lists for PDF
      final revenue =
          months.map((m) => revenueByMonth[keyFor(m)]?.round() ?? 0).toList();
      final expenses =
          months.map((m) => expensesByMonth[keyFor(m)]?.round() ?? 0).toList();

      // Compute occupancy (landlord only)
      double occupancyRate = 1.0;
      if (isLandlord) {
        try {
          final properties = await ref.read(landlordPropertiesProvider.future);
          if (properties.isNotEmpty) {
            final total = properties.length;
            final rented = properties
                .where((p) => p.status.toLowerCase() == 'rented')
                .length;
            occupancyRate = total == 0 ? 0.0 : rented / total;
          } else {
            occupancyRate = 0.0;
          }
        } catch (_) {
          occupancyRate = 1.0;
        }
      }

      // Currency formatting based on app currency setting
      final appCurrency = ref.read(currencyProvider);
      NumberFormat currencyFmt;
      switch (appCurrency) {
        case 'EUR':
          currencyFmt = NumberFormat.currency(locale: 'de_DE', symbol: '€');
          break;
        case 'USD':
          currencyFmt = NumberFormat.currency(locale: 'en_US', symbol: '\$');
          break;
        case 'GBP':
          currencyFmt = NumberFormat.currency(locale: 'en_GB', symbol: '£');
          break;
        case 'CHF':
        default:
          currencyFmt = NumberFormat.currency(locale: 'de_CH', symbol: 'CHF');
          break;
      }

      // Compute Month-specific KPIs
      // Monthly Revenue KPI (landlord): sum of rents of rented properties (align with dashboard)
      String? monthlyRevenueLabel;
      String? monthlyRevenueValue;
      if (isLandlord) {
        try {
          final properties = await ref.read(landlordPropertiesProvider.future);
          final totalMonthlyRent = properties
              .where((p) => p.status.toLowerCase() == 'rented')
              .fold<double>(0.0, (sum, p) => sum + p.rentAmount);
          monthlyRevenueLabel = AppLocalizations.of(context)!.monthlyRevenue;
          monthlyRevenueValue = currencyFmt.format(totalMonthlyRent);
        } catch (_) {
          // ignore – keep KPI hidden if failed
        }
      } else {
        // Tenant: show Monthly Rent Due (sum of tenant properties rent amounts if available)
        try {
          final tenantProps = await ref.read(tenantPropertiesProvider.future);
          final totalMonthlyRent =
              tenantProps.fold<double>(0.0, (sum, p) => sum + p.rentAmount);
          monthlyRevenueLabel = AppLocalizations.of(context)!.monthlyRent;
          monthlyRevenueValue = currencyFmt.format(totalMonthlyRent);
        } catch (_) {
          // ignore
        }
      }

      // Close loading dialog before invoking share sheet
      if (mounted) Navigator.of(context).pop();

      // Generate & share PDF
      await PdfExporter.exportFinancialReport(
        context: context,
        currency: currencyFmt,
        months: months,
        revenue: revenue,
        expenses: expenses,
        occupancyRate: occupancyRate,
        locale: Localizations.localeOf(context).toLanguageTag(),
        reportTitle: AppLocalizations.of(context)!.analyticsAndReports,
        revenueVsExpensesTitle: AppLocalizations.of(context)!.revenueVsExpenses,
        totalRevenueLabel: AppLocalizations.of(context)!.totalRevenue,
        totalExpensesLabel: AppLocalizations.of(context)!.totalExpenses,
        netIncomeLabel: AppLocalizations.of(context)!.netIncome,
        occupancyLabel: AppLocalizations.of(context)!.occupancyRate,
        monthlyRevenueLabel: monthlyRevenueLabel,
        monthlyRevenueValue: monthlyRevenueValue,
        collectedLabel: AppLocalizations.of(context)!.collected,
        collectedValue: currencyFmt.format(collectedSum),
        outstandingLabel: AppLocalizations.of(context)!.outstanding,
        outstandingValue: currencyFmt.format(outstandingSum),
        reportModeLabel: isPlanned ? l10n.planned : l10n.actual,
        monthHeader: AppLocalizations.of(context)!.month,
        revenueHeader: AppLocalizations.of(context)!.revenue,
        expensesHeader: AppLocalizations.of(context)!.expenses,
        netHeader: AppLocalizations.of(context)!.net,
        showOccupancy: isLandlord,
        altKpiLabel: isLandlord ? null : AppLocalizations.of(context)!.status,
        altKpiValue: isLandlord ? null : '✔ $completedCount • ⏳ $pendingCount',
      );

      // Optional confirmation
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(AppLocalizations.of(context)!.exportPdf),
            backgroundColor: colors.success,
          ),
        );
      }
    } catch (e) {
      // Close loading dialog if still open
      if (mounted) Navigator.of(context).pop();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to export PDF: $e'),
            backgroundColor: colors.error,
          ),
        );
      }
    }
  }
}

class _HoverScale extends StatefulWidget {
  final Widget child;
  final VoidCallback? onTap;
  const _HoverScale({required this.child, this.onTap});
  @override
  State<_HoverScale> createState() => _HoverScaleState();
}

class _HoverScaleState extends State<_HoverScale>
    with SingleTickerProviderStateMixin {
  double _scale = 1.0;
  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _scale = 1.02),
      onExit: (_) => setState(() => _scale = 1.0),
      child: GestureDetector(
        onTap: widget.onTap,
        child: AnimatedScale(
          scale: _scale,
          duration: const Duration(milliseconds: 160),
          curve: Curves.easeOut,
          child: widget.child,
        ),
      ),
    );
  }
}
