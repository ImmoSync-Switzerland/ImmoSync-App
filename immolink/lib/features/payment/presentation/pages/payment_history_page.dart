import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:immosync/l10n/app_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:immosync/features/auth/presentation/providers/auth_provider.dart';
import 'package:immosync/features/payment/domain/models/payment.dart';
import 'package:immosync/features/payment/presentation/providers/payment_providers.dart';
import 'package:intl/intl.dart';
import 'package:go_router/go_router.dart';

/// This file was corrupted by a bad paste/merge (widgets and methods ended up
/// inside other widgets/classes), causing a large cascade of syntax errors.
///
/// A clean, compiling implementation is provided below.
/// The old broken code is kept commented out for recovery.

const _backgroundStart = Color(0xFF0A1128);
const _backgroundEnd = Colors.black;
const _cardColor = Color(0xFF1C1C1E);
const _surfaceDark = Color(0xFF2C2C2E);

const _textPrimary = Colors.white;
const _textSecondary = Color(0xFFB0B0B0);

const _chipGradientDark = Color(0xFF2E7D32);
const _chipGradientLight = Color(0xFF66BB6A);

/// Backwards-compatible alias: app routes currently use `PaymentHistoryPage`.
/// New code should prefer `PaymentHistoryScreen`.
class PaymentHistoryScreen extends PaymentHistoryPage {
  const PaymentHistoryScreen({super.key});
}

class PaymentHistoryPage extends ConsumerStatefulWidget {
  const PaymentHistoryPage({super.key});

  @override
  ConsumerState<PaymentHistoryPage> createState() => _PaymentHistoryPageState();
}

class _PaymentHistoryPageState extends ConsumerState<PaymentHistoryPage> {
  String? _selectedStatus;
  String? _selectedType;

  String _localizePaymentStatus(AppLocalizations l10n, String status) {
    switch (status.toLowerCase()) {
      case 'pending':
        return l10n.pending;
      case 'completed':
        return l10n.completed;
      case 'failed':
        return l10n.failed;
      case 'refunded':
        return l10n.refunded;
      default:
        return status;
    }
  }

  String _localizePaymentType(AppLocalizations l10n, String type) {
    switch (type.toLowerCase()) {
      case 'rent':
        return l10n.rent;
      case 'maintenance':
        return l10n.maintenance;
      case 'deposit':
        return l10n.deposit;
      case 'fee':
        return l10n.fee;
      default:
        return l10n.other;
    }
  }

  List<Payment> _filterPayments(List<Payment> payments) {
    return payments.where((payment) {
      final normalizedStatus = payment.status.toLowerCase().trim();
      final normalizedType = payment.type.toLowerCase().trim();

      final statusMatch =
          _selectedStatus == null || normalizedStatus == _selectedStatus;
      final typeMatch =
          _selectedType == null || normalizedType == _selectedType;
      return statusMatch && typeMatch;
    }).toList();
  }

  Color _statusColor(String status) {
    switch (status.toLowerCase()) {
      case 'completed':
        return const Color(0xFF34C759);
      case 'failed':
        return const Color(0xFFFF3B30);
      case 'refunded':
        return const Color(0xFFFFD60A);
      case 'pending':
      default:
        return const Color(0xFF0A84FF);
    }
  }

  void _setStatus(String? value) {
    HapticFeedback.lightImpact();
    setState(() => _selectedStatus = value);
  }

  void _setType(String? value) {
    HapticFeedback.lightImpact();
    setState(() => _selectedType = value);
  }

  Future<void> _cancelPayment(Payment payment) async {
    final l10n = AppLocalizations.of(context)!;
    final shouldCancel = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l10n.cancelPayment),
        content: Text(l10n.confirmCancelPaymentMessage),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text(l10n.no),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: Text(l10n.yesCancel),
          ),
        ],
      ),
    );
    if (shouldCancel != true) return;

    try {
      showDialog<void>(
        context: context,
        barrierDismissible: false,
        builder: (_) => const Center(child: CircularProgressIndicator()),
      );

      final paymentService = ref.read(paymentServiceProvider);
      await paymentService.cancelPayment(payment.id);

      if (!mounted) return;
      Navigator.of(context).pop();
      Navigator.of(context).maybePop();

      ref.invalidate(landlordPaymentsProvider);
      ref.invalidate(tenantPaymentsProvider);

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(l10n.paymentCancelledSuccessfully),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      Navigator.of(context).maybePop();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(l10n.failedToCancelPayment(e.toString())),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _copyReceiptLink(Payment payment) async {
    final l10n = AppLocalizations.of(context)!;
    try {
      final paymentService = ref.read(paymentServiceProvider);
      final receiptUrl = await paymentService.downloadReceipt(payment.id);
      await Clipboard.setData(ClipboardData(text: receiptUrl));
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.receiptDownloadStarted)),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(l10n.failedToDownloadReceipt(e.toString())),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void _showPaymentDetails(Payment payment) {
    final l10n = AppLocalizations.of(context)!;
    final currency = NumberFormat.currency(symbol: 'CHF ');

    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: BentoCard(
              padding: const EdgeInsets.all(18),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        l10n.paymentDetailsTitle,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w800,
                          color: _textPrimary,
                        ),
                      ),
                      IconButton(
                        onPressed: () => Navigator.of(context).pop(),
                        icon: const Icon(Icons.close_rounded,
                            color: _textPrimary),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  _detailRow(l10n.amount, currency.format(payment.amount)),
                  _detailRow(l10n.status,
                      _localizePaymentStatus(l10n, payment.status)),
                  _detailRow(
                      l10n.type, _localizePaymentType(l10n, payment.type)),
                  _detailRow(l10n.date,
                      DateFormat('MMM d, yyyy').format(payment.date)),
                  _detailRow(l10n.propertyId, payment.propertyId),
                  _detailRow(l10n.tenantId, payment.tenantId),
                  if (payment.paymentMethod != null)
                    _detailRow(l10n.paymentMethod, payment.paymentMethod!),
                  if (payment.notes != null && payment.notes!.trim().isNotEmpty)
                    _detailRow(l10n.notes, payment.notes!),
                  const SizedBox(height: 16),
                  if (payment.status.toLowerCase() == 'pending')
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: () => _cancelPayment(payment),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.redAccent,
                          foregroundColor: _textPrimary,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                          elevation: 0,
                        ),
                        child: Text(l10n.cancelPayment),
                      ),
                    ),
                  if (payment.status.toLowerCase() == 'completed')
                    SizedBox(
                      width: double.infinity,
                      child: OutlinedButton(
                        onPressed: () => _copyReceiptLink(payment),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: _textPrimary,
                          side: const BorderSide(color: Colors.white24),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                        ),
                        child: Text(l10n.downloadReceipt),
                      ),
                    ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _detailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              label,
              style: const TextStyle(
                color: _textSecondary,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                color: _textPrimary,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _filterChip({
    required String label,
    required bool selected,
    required VoidCallback onTap,
  }) {
    return InkWell(
      borderRadius: BorderRadius.circular(999),
      onTap: () {
        HapticFeedback.lightImpact();
        onTap();
      },
      child: DecoratedBox(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(999),
          color: selected ? null : _surfaceDark,
          gradient: selected
              ? const LinearGradient(
                  colors: [_chipGradientDark, _chipGradientLight],
                  begin: Alignment.centerLeft,
                  end: Alignment.centerRight,
                )
              : null,
          border: Border.all(color: Colors.white10),
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          child: Text(
            label,
            style: TextStyle(
              color: selected ? _textPrimary : _textSecondary,
              fontWeight: selected ? FontWeight.w700 : FontWeight.w600,
            ),
          ),
        ),
      ),
    );
  }

  Widget _headerCard() {
    final l10n = AppLocalizations.of(context)!;
    return DecoratedBox(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(18),
        gradient: LinearGradient(
          colors: [
            _chipGradientLight.withValues(alpha: 0.55),
            _chipGradientDark.withValues(alpha: 0.25),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        boxShadow: [
          BoxShadow(
            color: _chipGradientLight.withValues(alpha: 0.18),
            blurRadius: 24,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(1.2),
        child: BentoCard(
          padding: const EdgeInsets.all(18),
          child: Row(
            children: [
              DecoratedBox(
                decoration: BoxDecoration(
                  color: _chipGradientLight.withValues(alpha: 0.18),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: _chipGradientLight.withValues(alpha: 0.30),
                  ),
                ),
                child: const SizedBox(
                  width: 46,
                  height: 46,
                  child: Icon(
                    Icons.history_rounded,
                    color: _chipGradientLight,
                  ),
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      l10n.paymentHistory,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                        color: _textPrimary,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      l10n.trackAllTransactions,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: _textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _filtersCard(AppLocalizations l10n) {
    return BentoCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Icon(
                    Icons.filter_alt_rounded,
                    color: _textSecondary,
                    size: 18,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      l10n.filterPayments,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: _textPrimary,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 14),
          Wrap(
            spacing: 8.0,
            runSpacing: 12.0,
            alignment: WrapAlignment.start,
            children: [
              _filterChip(
                label: l10n.all,
                selected: _selectedStatus == null,
                onTap: () => _setStatus(null),
              ),
              _filterChip(
                label: l10n.completed,
                selected: _selectedStatus == 'completed',
                onTap: () => _setStatus('completed'),
              ),
              _filterChip(
                label: l10n.pending,
                selected: _selectedStatus == 'pending',
                onTap: () => _setStatus('pending'),
              ),
              _filterChip(
                label: l10n.failed,
                selected: _selectedStatus == 'failed',
                onTap: () => _setStatus('failed'),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Wrap(
            spacing: 8.0,
            runSpacing: 12.0,
            alignment: WrapAlignment.start,
            children: [
              _filterChip(
                label: l10n.allTypes,
                selected: _selectedType == null,
                onTap: () => _setType(null),
              ),
              _filterChip(
                label: l10n.rent,
                selected: _selectedType == 'rent',
                onTap: () => _setType('rent'),
              ),
              _filterChip(
                label: l10n.maintenance,
                selected: _selectedType == 'maintenance',
                onTap: () => _setType('maintenance'),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _emptyState() {
    final l10n = AppLocalizations.of(context)!;
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 28),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.credit_card_rounded,
              size: 64,
              color: _textPrimary.withValues(alpha: 0.30),
            ),
            const SizedBox(height: 14),
            Text(
              l10n.noPaymentHistoryFound,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w800,
                color: _textPrimary,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              l10n.paymentHistoryWillAppearAfterFirstPayment,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: _textSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _transactionCard({
    required AppLocalizations l10n,
    required Payment payment,
    required bool incoming,
  }) {
    final currency = NumberFormat.currency(symbol: 'CHF ');
    final statusColor = _statusColor(payment.status);
    final arrowColor =
        incoming ? const Color(0xFF34C759) : const Color(0xFFFF3B30);

    return BentoCard(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          DecoratedBox(
            decoration: BoxDecoration(
              color: arrowColor.withValues(alpha: 0.14),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: Colors.white10),
            ),
            child: SizedBox(
              width: 42,
              height: 42,
              child: Icon(
                incoming ? Icons.south_west_rounded : Icons.north_east_rounded,
                color: arrowColor,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _localizePaymentType(l10n, payment.type),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontWeight: FontWeight.w800,
                    color: _textPrimary,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  DateFormat('MMM d, yyyy').format(payment.date),
                  style: const TextStyle(
                    color: _textSecondary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                currency.format(payment.amount),
                style: const TextStyle(
                  fontWeight: FontWeight.w900,
                  color: Color(0xFF34C759),
                ),
              ),
              const SizedBox(height: 4),
              Text(
                _localizePaymentStatus(l10n, payment.status),
                style: TextStyle(
                  color: statusColor,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final currentUser = ref.watch(currentUserProvider);

    final paymentsAsync = currentUser?.role == 'landlord'
        ? ref.watch(landlordPaymentsProvider)
        : ref.watch(tenantPaymentsProvider);

    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        title: Text(
          l10n.paymentHistory,
          style: const TextStyle(
            color: _textPrimary,
            fontWeight: FontWeight.w900,
            fontSize: 18,
            letterSpacing: -0.2,
          ),
        ),
        leading: IconButton(
          icon: const Icon(Icons.chevron_left, color: _textPrimary, size: 32),
          onPressed: () {
            if (Navigator.of(context).canPop()) {
              context.pop();
            } else {
              context.go('/home');
            }
          },
        ),
      ),
      body: DecoratedBox(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [_backgroundStart, _backgroundEnd],
          ),
        ),
        child: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _headerCard(),
                const SizedBox(height: 16),
                _filtersCard(l10n),
                const SizedBox(height: 16),
                paymentsAsync.when(
                  data: (payments) {
                    final filtered = _filterPayments(payments);
                    if (filtered.isEmpty) {
                      return _emptyState();
                    }

                    final incoming = (currentUser?.role == 'landlord');

                    return ListView.separated(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: filtered.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 12),
                      itemBuilder: (context, index) {
                        final payment = filtered[index];
                        return InkWell(
                          borderRadius: BorderRadius.circular(16),
                          onTap: () {
                            _showPaymentDetails(payment);
                          },
                          child: _transactionCard(
                            l10n: l10n,
                            payment: payment,
                            incoming: incoming,
                          ),
                        );
                      },
                    );
                  },
                  loading: () => Padding(
                    padding: const EdgeInsets.symmetric(vertical: 36),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Center(
                          child: CircularProgressIndicator(color: Colors.white),
                        ),
                        const SizedBox(height: 14),
                        Text(
                          l10n.loadingPaymentHistory,
                          style: const TextStyle(
                            color: _textSecondary,
                            fontWeight: FontWeight.w600,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  ),
                  error: (error, _) => BentoCard(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.error_outline,
                            size: 48, color: Colors.redAccent),
                        const SizedBox(height: 12),
                        Text(
                          error.toString(),
                          textAlign: TextAlign.center,
                          style: const TextStyle(color: _textSecondary),
                        ),
                        const SizedBox(height: 12),
                        SizedBox(
                          width: double.infinity,
                          child: OutlinedButton(
                            onPressed: () {
                              ref.invalidate(currentUser?.role == 'landlord'
                                  ? landlordPaymentsProvider
                                  : tenantPaymentsProvider);
                            },
                            style: OutlinedButton.styleFrom(
                              foregroundColor: _textPrimary,
                              side: const BorderSide(color: Colors.white24),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            child: Text(l10n.retry),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class BentoCard extends StatelessWidget {
  const BentoCard({super.key, required this.child, this.padding});

  final Widget child;
  final EdgeInsets? padding;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: padding ?? const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: _cardColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white10),
      ),
      child: child,
    );
  }
}

/*

const _backgroundStart = Color(0xFF0A1128);
const _backgroundEnd = Colors.black;
const _cardColor = Color(0xFF1C1C1E);
const _surfaceDark = Color(0xFF2C2C2E);
const _textPrimary = Colors.white;
const _textSecondary = Colors.white70;
const _textTertiary = Colors.white54;
const _chipGradientDark = Color(0xFF2E7D32);
const _chipGradientLight = Color(0xFF66BB6A);

class PaymentHistoryPage extends ConsumerStatefulWidget {
  const PaymentHistoryPage({super.key});

  @override
  ConsumerState<PaymentHistoryPage> createState() => _PaymentHistoryPageState();
}

class _PaymentHistoryPageState extends ConsumerState<PaymentHistoryPage> {
  String? _selectedStatus;
  String? _selectedType;

  String _localizePaymentStatus(AppLocalizations l10n, String status) {
    switch (status.toLowerCase()) {
      case 'pending':
        return l10n.pending;
      case 'completed':
        return l10n.completed;
      case 'failed':
        return l10n.failed;
      case 'refunded':
        return l10n.refunded;
      default:
        return status;
    }
  }

  String _localizePaymentType(AppLocalizations l10n, String type) {
    switch (type.toLowerCase()) {
      case 'rent':
        return l10n.rent;
      case 'maintenance':
        return l10n.maintenance;
      case 'deposit':
        return l10n.deposit;
      case 'fee':
        return l10n.fee;
      case 'other':
        return l10n.other;
      default:
        return type;
    }
  }

  List<Payment> _filterPayments(List<Payment> payments) {
    return payments.where((payment) {
      final bool statusMatch =
          _selectedStatus == null || payment.status == _selectedStatus;
      final bool typeMatch =
          _selectedType == null || payment.type == _selectedType;
      return statusMatch && typeMatch;
    }).toList();
  }

  Future<void> _cancelPayment(Payment payment) async {
    final l10n = AppLocalizations.of(context)!;
    try {
      // Show confirmation dialog
      final shouldCancel = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: Text(l10n.cancelPayment),
          content: Text(l10n.confirmCancelPaymentMessage),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: Text(l10n.no),
            ),
            TextButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: Text(l10n.yesCancel),
            ),
          ],
        ),
      );

      if (shouldCancel == true) {
        // Show loading indicator
        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (context) => const Center(
            child: CircularProgressIndicator(),
          ),
        );

        await _paymentService.cancelPayment(payment.id);

        // Close loading dialog
        Navigator.of(context).pop();

        // Close payment details dialog
        Navigator.of(context).pop();

        // Refresh the payments list
        ref.invalidate(landlordPaymentsProvider);
        ref.invalidate(tenantPaymentsProvider);

        // Show success message
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(l10n.paymentCancelledSuccessfully),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      // Close loading dialog if open
      Navigator.of(context).pop();

      // Show error message
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(l10n.failedToCancelPayment(e.toString())),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _downloadReceipt(Payment payment) async {
    final l10n = AppLocalizations.of(context)!;
    try {
      // Show loading indicator
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const Center(
          child: CircularProgressIndicator(),
        ),
      );

      final receiptUrl = await _paymentService.downloadReceipt(payment.id);

      // Close loading dialog
      Navigator.of(context).pop();

      // Launch the receipt URL
      if (await canLaunchUrl(Uri.parse(receiptUrl))) {
        await launchUrl(Uri.parse(receiptUrl));
      } else {
        throw Exception(l10n.couldNotOpenReceipt);
      }

      // Show success message
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(l10n.receiptDownloadStarted),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      // Close loading dialog if open
      Navigator.of(context).pop();

      // Show error message
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(l10n.failedToDownloadReceipt(e.toString())),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final currentUser = ref.watch(currentUserProvider);
    final l10n = AppLocalizations.of(context)!;
    final paymentsAsync = currentUser?.role == 'landlord'
        ? ref.watch(landlordPaymentsProvider)
        : ref.watch(tenantPaymentsProvider);

    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        title: Text(
          l10n.paymentHistory,
          style: TextStyle(
            color: colors.textPrimary,
            fontSize: 20,
            fontWeight: FontWeight.w600,
          ),
        ),
        backgroundColor: Colors.transparent,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(
            Icons.chevron_left,
            color: _textPrimary,
            size: 20,
          ),
          onPressed: () {
            HapticFeedback.lightImpact();
            if (Navigator.of(context).canPop()) {
              context.pop();
            } else {
              context.go('/home');
            }
          },
        ),
      ),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [_backgroundStart, _backgroundEnd],
          ),
        ),
        child: Column(
          children: [
            SizedBox(
                height:
                    MediaQuery.of(context).padding.top + kToolbarHeight + 8),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildHeader(colors, l10n),
                    const SizedBox(height: 20),
                    _buildFilterOptions(context, colors, l10n),
                    const SizedBox(height: 24),
                    Expanded(
                      child: paymentsAsync.when(
                        data: (paymentsList) {
                          final filteredPayments =
                              _filterPayments(paymentsList);
                          if (filteredPayments.isEmpty) {
                            return Center(
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(
                                    Icons.payment_outlined,
                                    size: 64,
                                    color: colors.textTertiary,
                                  ),
                                  const SizedBox(height: 16),
                                  Text(
                                    l10n.noPaymentHistoryFound,
                                    style: TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.w600,
                                      color: colors.textPrimary,
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    l10n.paymentHistoryWillAppearAfterFirstPayment,
                                    style: TextStyle(
                                      fontSize: 14,
                                      color: colors.textSecondary,
                                    ),
                                    textAlign: TextAlign.center,
                                  ),
                                ],
                              ),
                            );
                          }

                          return ListView.builder(
                            itemCount: filteredPayments.length,
                            itemBuilder: (context, index) {
                              return _buildPaymentCard(
                                  context, filteredPayments[index], colors);
                            },
                          );
                        },
                        loading: () => Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              SizedBox(
                                width: 32,
                                height: 32,
                                child: CircularProgressIndicator(
                                  valueColor: AlwaysStoppedAnimation<Color>(
                                      colors.primaryAccent),
                                  strokeWidth: 2.5,
                                ),
                              ),
                              const SizedBox(height: 16),
                              Text(
                                l10n.loadingPaymentHistory,
                                style: TextStyle(
                                  color: colors.textSecondary,
                                  fontSize: 14,
                                ),
                              ),
                            ],
                          ),
                        ),
                        error: (error, stack) => Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.error_outline,
                                  size: 48, color: colors.error),
                              const SizedBox(height: 16),
                              Text(
                                l10n.errorLoadingPaymentHistory,
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.w600,
                                  color: colors.textPrimary,
                                ),
                              ),
                              padding: const EdgeInsets.symmetric(
                                vertical: 12,
                                horizontal: 16,
                              ),
                              const SizedBox(height: 16),
                              ElevatedButton(
                                onPressed: () {
                                  ref.invalidate(currentUser?.role == 'landlord'
                                      ? landlordPaymentsProvider
                                      : tenantPaymentsProvider);
                                },
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: colors.primaryAccent,
                                  foregroundColor: colors.textOnAccent,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                ),
                                child: Text(l10n.retry),
                              ),
                            ),
                            child: Text(l10n.retry),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(DynamicAppColors colors, AppLocalizations l10n) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color(0xFF2E7D32), // Dunkleres Grün
            Color(0xFF66BB6A), // Helleres Grün
          ],
        ),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF2E7D32).withValues(alpha: 0.4),
            blurRadius: 24,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: const Color(0xFF2E7D32).withValues(alpha: 0.18),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: const Color(0xFF66BB6A).withValues(alpha: 0.35),
                width: 1,
              ),
            ),
            child: const Icon(
              Icons.history_rounded,
              color: Color(0xFF66BB6A),
              size: 22,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  l10n.paymentHistory,
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  l10n.trackAllTransactions,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                    color: _textSecondary,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterOptions(
      BuildContext context, DynamicAppColors colors, AppLocalizations l10n) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            colors.surfaceCards,
            colors.surfaceCards.withValues(alpha: 0.7),
          ],
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: colors.borderLight.withValues(alpha: 0.5),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: colors.shadowColor.withValues(alpha: 0.1),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(
                Icons.filter_list_rounded,
                color: _textPrimary,
                size: 18,
              ),
              const SizedBox(width: 10),
              Text(
                l10n.filterPayments,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: colors.textPrimary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            l10n.status,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: _textSecondary,
            ),
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: [
              _buildFilterChip(l10n.all, null, colors),
              _buildFilterChip(l10n.completed, 'completed', colors),
              _buildFilterChip(l10n.pending, 'pending', colors),
              _buildFilterChip(l10n.failed, 'failed', colors),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            l10n.type,
              _buildFilterPill(
                  label: 'All',
                  selected: _selectedStatus == null,
                  onTap: () => _setStatus(null)),
              _buildFilterPill(
                  label: 'Completed',
                  selected: _selectedStatus == 'completed',
                  onTap: () => _setStatus('completed')),
              _buildFilterPill(
                  label: 'Pending',
                  selected: _selectedStatus == 'pending',
                  onTap: () => _setStatus('pending')),
              _buildFilterPill(
                  label: 'Failed',
                  selected: _selectedStatus == 'failed',
                  onTap: () => _setStatus('failed')),
            ],
          ),
          const SizedBox(height: 16),
          const Text(
            'Type',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: _textSecondary,
            ),
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: [
              _buildFilterChip(l10n.allTypes, null, colors, isTypeFilter: true),
              _buildFilterChip(l10n.rent, 'rent', colors, isTypeFilter: true),
              _buildFilterChip(l10n.maintenance, 'maintenance', colors,
                  isTypeFilter: true),
              _buildFilterChip(l10n.other, 'other', colors, isTypeFilter: true),
              _buildFilterPill(
                label: l10n.allTypes,
                selected: _selectedType == null,
                onTap: () => _setType(null),
              ),
              _buildFilterPill(
                label: 'Rent',
                selected: _selectedType == 'rent',
                onTap: () => _setType('rent'),
              ),
              _buildFilterPill(
                label: 'Maintenance',
                selected: _selectedType == 'maintenance',
                onTap: () => _setType('maintenance'),
              ),
            ],
          ),
        ],
      ),
    );
  }

  void _setStatus(String? value) {
    HapticFeedback.lightImpact();
    setState(() {
      _selectedStatus = value;
    });
  }

  void _setType(String? value) {
    HapticFeedback.lightImpact();
    setState(() {
      _selectedType = value;
    });
  }

  Widget _buildFilterPill({
    required String label,
    required bool selected,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: selected ? null : _surfaceDark,
          gradient: selected
              ? const LinearGradient(
                  begin: Alignment.centerLeft,
                  end: Alignment.centerRight,
                  colors: [_chipGradientDark, _chipGradientLight],
                )
              : null,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: selected
                ? const Color(0xFF2E7D32).withValues(alpha: 0.9)
                : Colors.white.withValues(alpha: 0.10),
            width: selected ? 1.5 : 1,
          ),
          boxShadow: selected
              ? [
                  BoxShadow(
                    color: const Color(0xFF2E7D32).withValues(alpha: 0.35),
                    blurRadius: 14,
                    offset: const Offset(0, 6),
                  ),
                ]
              : null,
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 13,
            fontWeight: selected ? FontWeight.w700 : FontWeight.w600,
            color: selected ? _textPrimary : _textTertiary,
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyStateCard(AppLocalizations l10n) {
    return BentoCard(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 22),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.credit_card_rounded,
              size: 64,
              color: Colors.white.withValues(alpha: 0.22),
            ),
            const SizedBox(height: 14),
            Text(
              l10n.noPaymentHistoryFound,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w800,
                color: _textPrimary,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Your transactions will appear here.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 13,
                color: _textSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPaymentCard(
      BuildContext context, Payment payment, DynamicAppColors colors) {
    final l10n = AppLocalizations.of(context)!;
    Color statusColor;
    IconData statusIcon;
  Widget _buildTransactionCard(Payment payment, bool isIncoming) {
    final amountText =
        NumberFormat.currency(symbol: 'CHF ').format(payment.amount);
    final dateText = DateFormat('MMM d, yyyy').format(payment.date);

    final arrowColor = isIncoming ? const Color(0xFF66BB6A) : Colors.redAccent;
    final arrowIcon =
        isIncoming ? Icons.arrow_downward_rounded : Icons.arrow_upward_rounded;

    return BentoCard(
      padding: const EdgeInsets.all(16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: arrowColor.withValues(alpha: 0.16),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: arrowColor.withValues(alpha: 0.28),
                width: 1,
              ),
            ),
            child: Icon(
              arrowIcon,
              color: arrowColor,
              size: 22,
            ),
          ),
        ],
      ),
      child: InkWell(
        onTap: () {
          HapticFeedback.lightImpact();
          _showPaymentDetails(context, payment);
        },
        borderRadius: BorderRadius.circular(20),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [
                                statusColor.withValues(alpha: 0.2),
                                statusColor.withValues(alpha: 0.1),
                              ],
                            ),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Icon(
                            _getPaymentTypeIcon(payment.type),
                            color: statusColor,
                            size: 22,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            _localizePaymentType(l10n, payment.type),
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w700,
                              color: colors.textPrimary,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: statusColor.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          statusIcon,
                          size: 16,
                          color: statusColor,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          _localizePaymentStatus(l10n, payment.status),
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: statusColor,
                          ),
                        ),
                      ],
                    ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  payment.type.toUpperCase(),
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w800,
                    color: _textPrimary,
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    l10n.propertyIdWithValue(payment.propertyId),
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey.shade700,
                    ),
                  ),
                  Text(
                    DateFormat('MMM d, yyyy').format(payment.date),
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey.shade700,
                    ),
                  ),
                ],
              ),
              if (payment.paymentMethod != null) ...[
                const SizedBox(height: 8),
                Text(
                  l10n.methodWithValue(payment.paymentMethod!),
                  style: TextStyle(
                const SizedBox(height: 4),
                Text(
                  dateText,
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: _textSecondary,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 10),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                amountText,
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w800,
                  color: Color(0xFF66BB6A),
                ),
              ),
              const SizedBox(height: 4),
              Text(
                payment.status.toUpperCase(),
                style: const TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  color: _textTertiary,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class BentoCard extends StatelessWidget {
  const BentoCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(20),
    this.glowColor,
  });

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        final l10n = AppLocalizations.of(context)!;
        return DraggableScrollableSheet(
          initialChildSize: 0.6,
          maxChildSize: 0.9,
          minChildSize: 0.5,
          expand: false,
          builder: (context, scrollController) {
            return SingleChildScrollView(
              controller: scrollController,
              child: Padding(
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          l10n.paymentDetailsTitle,
                          style: TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.close),
                          onPressed: () => Navigator.pop(context),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    _buildDetailItem(
                        l10n.amount, currencyFormat.format(payment.amount)),
                    _buildDetailItem(l10n.status,
                        _localizePaymentStatus(l10n, payment.status)),
                    _buildDetailItem(
                        l10n.type, _localizePaymentType(l10n, payment.type)),
                    _buildDetailItem(l10n.date,
                        DateFormat('MMM d, yyyy').format(payment.date)),
                    _buildDetailItem(l10n.propertyId, payment.propertyId),
                    _buildDetailItem(l10n.tenantId, payment.tenantId),
                    if (payment.transactionId != null)
                      _buildDetailItem(
                          l10n.transactionId, payment.transactionId!),
                    if (payment.paymentMethod != null)
                      _buildDetailItem(
                          l10n.paymentMethod, payment.paymentMethod!),
                    if (payment.notes != null) ...[
                      const SizedBox(height: 16),
                      Text(
                        l10n.notes,
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        payment.notes!,
                        style: const TextStyle(fontSize: 16),
                      ),
                    ],
                    const SizedBox(height: 24),
                    if (payment.status == 'pending')
                      ElevatedButton(
                        onPressed: () => _cancelPayment(payment),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.red,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        child: Text(
                          l10n.cancelPayment,
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    if (payment.status == 'completed')
                      ElevatedButton(
                        onPressed: () => _downloadReceipt(payment),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.blue.shade700,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        child: Text(
                          l10n.downloadReceipt,
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }
  final Widget child;
  final EdgeInsets padding;
  final Color? glowColor;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: padding,
      decoration: BoxDecoration(
        color: _cardColor,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.06),
          width: 1,
        ),
        boxShadow: glowColor == null
            ? null
            : [
                BoxShadow(
                  color: glowColor!.withValues(alpha: 0.22),
                  blurRadius: 20,
                  offset: const Offset(0, 10),
                ),
              ],
      ),
      child: child,
    );
  }
}

*/
