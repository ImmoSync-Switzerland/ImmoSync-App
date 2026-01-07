import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:immosync/features/auth/presentation/providers/auth_provider.dart';
import 'package:immosync/features/payment/domain/models/payment.dart';
import 'package:immosync/features/payment/presentation/providers/payment_providers.dart';
import 'package:immosync/features/property/presentation/providers/property_providers.dart';
import 'package:immosync/features/property/domain/models/property.dart';
import 'package:immosync/l10n/app_localizations.dart';

/// This file previously contained a corrupted widget tree (likely from a bad
/// paste/merge) that caused a large cascade of syntax errors.
///
/// The page is reimplemented below to compile and behave correctly.
/// The old broken code is kept commented out at the bottom for recovery.

const _backgroundStart = Color(0xFF0A1128);
const _backgroundEnd = Colors.black;
const _cardColor = Color(0xFF1C1C1E);
const _fieldColor = Color(0xFF2C2C2E);

const _textPrimary = Colors.white;
const _textSecondary = Color(0xFFB0B0B0);

const _moneyGreen = Color(0xFF34C759);

const _fieldBorderRadius = BorderRadius.all(Radius.circular(12));

/// Backwards-compatible alias: app routes currently use `MakePaymentPage`.
/// New code should prefer `MakePaymentScreen`.
class MakePaymentScreen extends MakePaymentPage {
  const MakePaymentScreen({super.key, super.propertyId});
}

class MakePaymentPage extends ConsumerStatefulWidget {
  final String? propertyId;

  const MakePaymentPage({super.key, this.propertyId});

  @override
  ConsumerState<MakePaymentPage> createState() => _MakePaymentPageState();
}

class _MakePaymentPageState extends ConsumerState<MakePaymentPage> {
  final _formKey = GlobalKey<FormState>();
  final _amountController = TextEditingController();
  final _notesController = TextEditingController();

  String? _selectedPropertyId;
  String? _selectedPaymentMethod;
  String? _selectedPaymentType;

  final List<String> _paymentMethods = const [
    'Credit Card',
    'Bank Transfer',
    'PayPal',
    'Other',
  ];

  final List<String> _paymentTypes = const [
    'Rent',
    'Deposit',
    'Fee',
    'Other',
  ];

  @override
  void initState() {
    super.initState();
    _selectedPropertyId = widget.propertyId;
    _selectedPaymentMethod = _paymentMethods.first;
    _selectedPaymentType = _paymentTypes.first;
  }

  @override
  void dispose() {
    _amountController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  String _formatAddress(Property property, AppLocalizations l10n) {
    final street = property.address.street.trim();
    final city = property.address.city.trim();
    final postal = property.address.postalCode.trim();

    final parts = <String>[
      if (street.isNotEmpty) street,
      if (postal.isNotEmpty || city.isNotEmpty)
        [postal, city].where((e) => e.isNotEmpty).join(' '),
    ].where((e) => e.isNotEmpty).toList();

    return parts.isNotEmpty ? parts.join(', ') : l10n.property;
  }

  String _paymentTypeDisplay(AppLocalizations l10n, String type) {
    switch (type.toLowerCase()) {
      case 'rent':
        return l10n.rent;
      case 'deposit':
        return l10n.deposit;
      case 'fee':
        return l10n.fee;
      default:
        return l10n.other;
    }
  }

  String _paymentMethodDisplay(AppLocalizations l10n, String method) {
    switch (method.toLowerCase()) {
      case 'credit card':
        return l10n.creditDebitCard;
      case 'bank transfer':
        return l10n.bankTransfer;
      case 'paypal':
        return l10n.paypal;
      default:
        return l10n.other;
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final userProperties = ref.watch(tenantPropertiesProvider);

    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        title: Text(
          l10n.makePayment,
          style: const TextStyle(
            color: _textPrimary,
            fontWeight: FontWeight.w600,
          ),
        ),
        backgroundColor: Colors.transparent,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        iconTheme: const IconThemeData(color: _textPrimary),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_rounded),
          onPressed: () => context.pop(),
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
        child: SafeArea(
          child: userProperties.when(
            data: (properties) {
              if (properties.isEmpty) {
                return Center(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(
                          Icons.home_outlined,
                          size: 64,
                          color: _textSecondary,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          l10n.noPropertiesFound,
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w600,
                            color: _textPrimary,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          l10n.noPropertiesToMakePaymentsFor,
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            fontSize: 14,
                            color: _textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }

              if (_selectedPropertyId == null ||
                  !properties.any((p) => p.id == _selectedPropertyId)) {
                _selectedPropertyId = properties.first.id;
              }

              final selectedProperty = properties.firstWhere(
                (p) => p.id == _selectedPropertyId,
                orElse: () => properties.first,
              );

              if (_amountController.text.isEmpty &&
                  selectedProperty.outstandingPayments > 0) {
                _amountController.text =
                    selectedProperty.outstandingPayments.toString();
              }

              return SingleChildScrollView(
                padding: const EdgeInsets.all(20),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      _buildPropertySection(l10n, properties, selectedProperty),
                      const SizedBox(height: 20),
                      _buildPaymentDetailsSection(l10n),
                      const SizedBox(height: 20),
                      _buildNotesSection(l10n),
                      const SizedBox(height: 28),
                      _buildSubmitButton(l10n),
                    ],
                  ),
                ),
              );
            },
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (error, _) => Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.error_outline,
                        size: 48, color: Colors.redAccent),
                    const SizedBox(height: 12),
                    Text(
                      l10n.errorLoadingProperties,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: _textPrimary,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      error.toString(),
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        fontSize: 13,
                        color: _textSecondary,
                      ),
                    ),
                    const SizedBox(height: 16),
                    SizedBox(
                      width: double.infinity,
                      child: OutlinedButton(
                        onPressed: () =>
                            ref.invalidate(tenantPropertiesProvider),
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
          ),
        ),
      ),
    );
  }

  InputDecoration _darkFieldDecoration({required String label}) {
    return InputDecoration(
      labelText: label,
      labelStyle: const TextStyle(color: _textSecondary),
      filled: true,
      fillColor: _fieldColor,
      border: const OutlineInputBorder(
        borderRadius: _fieldBorderRadius,
        borderSide: BorderSide.none,
      ),
      enabledBorder: const OutlineInputBorder(
        borderRadius: _fieldBorderRadius,
        borderSide: BorderSide.none,
      ),
      focusedBorder: const OutlineInputBorder(
        borderRadius: _fieldBorderRadius,
        borderSide: BorderSide(color: Colors.cyanAccent, width: 1),
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
    );
  }

  Widget _buildPropertySection(
    AppLocalizations l10n,
    List<Property> properties,
    Property selectedProperty,
  ) {
    return BentoCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            l10n.property,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: _textPrimary,
            ),
          ),
          const SizedBox(height: 12),
          DropdownButtonFormField<String>(
            isExpanded: true,
            // ignore: deprecated_member_use
            value: _selectedPropertyId,
            dropdownColor: _fieldColor,
            decoration: _darkFieldDecoration(label: l10n.property),
            items: properties.map((property) {
              final label = _formatAddress(property, l10n);
              return DropdownMenuItem<String>(
                value: property.id,
                child: Text(
                  label,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(color: _textPrimary),
                ),
              );
            }).toList(),
            onChanged: (value) {
              setState(() {
                _selectedPropertyId = value;
              });
            },
            iconEnabledColor: _textPrimary,
          ),
          const SizedBox(height: 14),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.blue.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                const Icon(Icons.info_outline, size: 18, color: Colors.blue),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'Outstanding payments: CHF '
                    '${selectedProperty.outstandingPayments.toStringAsFixed(1)}',
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: Colors.blue,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPaymentDetailsSection(AppLocalizations l10n) {
    if (_selectedPaymentType == null ||
        !_paymentTypes.contains(_selectedPaymentType)) {
      _selectedPaymentType = _paymentTypes.first;
    }
    if (_selectedPaymentMethod == null ||
        !_paymentMethods.contains(_selectedPaymentMethod)) {
      _selectedPaymentMethod = _paymentMethods.first;
    }

    return BentoCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            l10n.paymentDetailsTitle,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: _textPrimary,
            ),
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: DropdownButtonFormField<String>(
                  isExpanded: true,
                  // ignore: deprecated_member_use
                  value: _selectedPaymentType,
                  dropdownColor: _fieldColor,
                  iconEnabledColor: _textPrimary,
                  decoration: _darkFieldDecoration(label: l10n.paymentType),
                  items: _paymentTypes
                      .map(
                        (type) => DropdownMenuItem<String>(
                          value: type,
                          child: Text(
                            _paymentTypeDisplay(l10n, type),
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(color: _textPrimary),
                          ),
                        ),
                      )
                      .toList(),
                  onChanged: (value) {
                    setState(() {
                      _selectedPaymentType = value;
                    });
                  },
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: DropdownButtonFormField<String>(
                  isExpanded: true,
                  // ignore: deprecated_member_use
                  value: _selectedPaymentMethod,
                  dropdownColor: _fieldColor,
                  iconEnabledColor: _textPrimary,
                  decoration: _darkFieldDecoration(label: l10n.paymentMethod),
                  items: _paymentMethods
                      .map(
                        (method) => DropdownMenuItem<String>(
                          value: method,
                          child: Text(
                            _paymentMethodDisplay(l10n, method),
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(color: _textPrimary),
                          ),
                        ),
                      )
                      .toList(),
                  onChanged: (value) {
                    setState(() {
                      _selectedPaymentMethod = value;
                    });
                  },
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          TextFormField(
            controller: _amountController,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            style: const TextStyle(
              color: _moneyGreen,
              fontWeight: FontWeight.w700,
            ),
            decoration: _darkFieldDecoration(label: l10n.amount).copyWith(
              prefixText: 'CHF ',
              prefixStyle: const TextStyle(color: _textSecondary),
            ),
            validator: (value) {
              if (value == null || value.trim().isEmpty) {
                return l10n.pleaseEnterAmount;
              }
              final parsed = double.tryParse(value.replaceAll(',', '.'));
              if (parsed == null) {
                return l10n.pleaseEnterValidNumber;
              }
              if (parsed <= 0) {
                return l10n.amountMustBeGreaterThanZero;
              }
              return null;
            },
          ),
        ],
      ),
    );
  }

  Widget _buildNotesSection(AppLocalizations l10n) {
    return BentoCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            l10n.notesOptional,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: _textPrimary,
            ),
          ),
          const SizedBox(height: 12),
          TextFormField(
            controller: _notesController,
            maxLines: 3,
            style: const TextStyle(color: _textPrimary),
            decoration:
                _darkFieldDecoration(label: l10n.notesOptional).copyWith(
              hintText: l10n.addAdditionalNotes,
              hintStyle: const TextStyle(color: _textSecondary),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSubmitButton(AppLocalizations l10n) {
    return SizedBox(
      width: double.infinity,
      height: 54,
      child: DecoratedBox(
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [Colors.blue, Colors.cyan],
            begin: Alignment.centerLeft,
            end: Alignment.centerRight,
          ),
          borderRadius: BorderRadius.circular(14),
        ),
        child: ElevatedButton.icon(
          onPressed: _submitPayment,
          icon: const Icon(Icons.credit_card_rounded),
          label: const Text(
            'Submit Payment',
            style: TextStyle(fontWeight: FontWeight.w700),
          ),
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.transparent,
            foregroundColor: Colors.white,
            shadowColor: Colors.transparent,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(14),
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _submitPayment() async {
    final l10n = AppLocalizations.of(context)!;

    if (!_formKey.currentState!.validate()) {
      return;
    }
    if (_selectedPropertyId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(l10n.pleaseSelectProperty),
          backgroundColor: Colors.redAccent,
        ),
      );
      return;
    }

    final currentUser = ref.read(currentUserProvider);
    if (currentUser == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(l10n.userNotAuthenticated),
          backgroundColor: Colors.redAccent,
        ),
      );
      return;
    }

    try {
      showDialog<void>(
        context: context,
        barrierDismissible: false,
        builder: (_) => const Center(child: CircularProgressIndicator()),
      );

      final amount = double.parse(
        _amountController.text.trim().replaceAll(',', '.'),
      );

      final payment = Payment(
        id: '',
        tenantId: currentUser.id,
        propertyId: _selectedPropertyId!,
        amount: amount,
        type: (_selectedPaymentType ?? _paymentTypes.first).toLowerCase(),
        paymentMethod:
            (_selectedPaymentMethod ?? _paymentMethods.first).toLowerCase(),
        status: 'pending',
        date: DateTime.now(),
        notes: _notesController.text.trim().isEmpty
            ? null
            : _notesController.text.trim(),
      );

      await ref.read(paymentNotifierProvider.notifier).createPayment(payment);

      if (!mounted) return;
      Navigator.of(context).pop();

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(l10n.paymentSubmittedSuccessfully),
          backgroundColor: Colors.green,
        ),
      );

      context.pop();
    } catch (e) {
      if (!mounted) return;
      Navigator.of(context).maybePop();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(l10n.failedToSubmitPayment(e)),
          backgroundColor: Colors.redAccent,
        ),
      );
    }
  }
}

class BentoCard extends StatelessWidget {
  const BentoCard({super.key, required this.child, this.padding});

  final Widget child;
  final EdgeInsets? padding;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: padding ?? const EdgeInsets.all(20),
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
const _fieldColor = Color(0xFF2C2C2E);
const _textPrimary = Colors.white;
const _textSecondary = Colors.white70;

const _fieldBorderRadius = BorderRadius.all(Radius.circular(12));

class MakePaymentPage extends ConsumerStatefulWidget {
  final String? propertyId;

  const MakePaymentPage({super.key, this.propertyId});

  @override
  ConsumerState<MakePaymentPage> createState() => _MakePaymentPageState();
}

class _MakePaymentPageState extends ConsumerState<MakePaymentPage> {
  final _formKey = GlobalKey<FormState>();
  final _amountController = TextEditingController();
  final _notesController = TextEditingController();
  String? _selectedPropertyId;
  String? _selectedPaymentMethod;
  String? _selectedPaymentType;

  final List<String> _paymentMethods = [
    'Credit Card',
    'Bank Transfer',
    'PayPal',
    'Other'
  ];

  final List<String> _paymentTypes = ['Rent', 'Deposit', 'Fee', 'Other'];

  @override
  void initState() {
    super.initState();
    _selectedPropertyId = widget.propertyId;
    _selectedPaymentMethod = _paymentMethods.first;
    _selectedPaymentType = _paymentTypes.first;
  }

  String _formatAddress(Property property) {
    final street = property.address.street.trim();
    final city = property.address.city.trim();
    final postal = property.address.postalCode.trim();
    final parts = [
      if (street.isNotEmpty) street,
      if (postal.isNotEmpty || city.isNotEmpty)
        [postal, city].where((e) => e.isNotEmpty).join(' '),
    ].where((e) => e.isNotEmpty).toList();
    final l10n = AppLocalizations.of(context)!;
    return parts.isNotEmpty ? parts.join(', ') : l10n.property;
  }

  String _paymentTypeDisplay(AppLocalizations l10n, String type) {
    switch (type.toLowerCase()) {
      case 'rent':
        return l10n.rent;
      case 'deposit':
        return l10n.deposit;
      case 'fee':
        return l10n.fee;
      default:
        return l10n.other;
    }
  }

  String _paymentMethodDisplay(AppLocalizations l10n, String method) {
    switch (method.toLowerCase()) {
      case 'credit card':
        return l10n.creditDebitCard;
      case 'bank transfer':
        return l10n.bankTransfer;
      case 'paypal':
        return l10n.paypal;
      default:
        return l10n.other;
    }
  }

  @override
  void dispose() {
    _amountController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final userProperties = ref.watch(tenantPropertiesProvider);
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        title: Text(
          l10n.makePayment,
          style: const TextStyle(
            color: AppColors.textPrimary,
            fontSize: 20,
            fontWeight: FontWeight.w600,
          ),
        ),
        backgroundColor: Colors.transparent,
        surfaceTintColor: Colors.transparent,
        foregroundColor: _textPrimary,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: _textPrimary),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: userProperties.when(
          data: (properties) {
            if (properties.isEmpty) {
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(
                      Icons.home_outlined,
                      size: 64,
                      color: AppColors.textTertiary,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      l10n.noPropertiesFound,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      l10n.noPropertiesToMakePaymentsFor,
                      style: const TextStyle(
                        fontSize: 14,
                        color: AppColors.textSecondary,
                      ),
                      SizedBox(height: 8),
                      Text(
                        'You have no properties to make payments for.',
                        style: TextStyle(
                          fontSize: 14,
                          color: _textSecondary,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                );
              }

              if (_selectedPropertyId == null ||
                  !properties.any((p) => p.id == _selectedPropertyId)) {
                _selectedPropertyId = properties.first.id;
              }

              final selectedProperty = properties.firstWhere(
                (p) => p.id == _selectedPropertyId,
                orElse: () => properties.first,
              );

              if (_amountController.text.isEmpty) {
                _amountController.text =
                    selectedProperty.outstandingPayments.toString();
              }

              return SingleChildScrollView(
                padding: const EdgeInsets.all(20.0),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      _buildPropertySection(properties, selectedProperty),
                      const SizedBox(height: 24),
                      _buildPaymentDetailsSection(),
                      const SizedBox(height: 24),
                      _buildNotesSection(),
                      const SizedBox(height: 32),
                      _buildSubmitButton(),
                    ],
                  ),
                ),
              );
            },
            loading: () => const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  _buildPropertySection(properties, selectedProperty),
                  const SizedBox(height: 24),
                  _buildPaymentDetailsSection(),
                  const SizedBox(height: 24),
                  _buildNotesSection(),
                  const SizedBox(height: 32),
                  _buildSubmitButton(),
                ],
              ),
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
                    valueColor:
                        AlwaysStoppedAnimation<Color>(AppColors.primaryAccent),
                    strokeWidth: 2.5,
                  ),
                ),
                SizedBox(height: 16),
                Text(
                  l10n.loadingProperties,
                  style: TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 14,
                  ),
                ],
              ),
            ),
          ),
          error: (error, stack) => Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.error_outline,
                    size: 48, color: AppColors.error),
                const SizedBox(height: 16),
                Text(
                  l10n.errorLoadingProperties,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    error.toString(),
                    style: const TextStyle(
                      fontSize: 14,
                      color: _textSecondary,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildPropertySection(
      List<Property> properties, Property selectedProperty) {
    final l10n = AppLocalizations.of(context)!;
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surfaceCards,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: AppColors.borderLight,
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: AppColors.shadowColor.withValues(alpha: 0.08),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              l10n.property,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: AppColors.textPrimary,
              ),
            ),
            style: const TextStyle(
              color: _textPrimary,
              fontSize: 14,
            ),
            decoration: const InputDecoration(
              filled: true,
              fillColor: _fieldColor,
              border: OutlineInputBorder(
                borderRadius: _fieldBorderRadius,
                borderSide: BorderSide.none,
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: _fieldBorderRadius,
                borderSide: BorderSide.none,
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: _fieldBorderRadius,
                borderSide: BorderSide.none,
              ),
              contentPadding: EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 12,
              ),
            ),
            items: properties.map((property) {
              final addressLabel = _formatAddress(property);
              return DropdownMenuItem<String>(
                value: property.id,
                child: Text(
                  addressLabel,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(color: _textPrimary),
                ),
              ),
              child: Row(
                children: [
                  const Icon(
                    Icons.info_outline,
                    color: AppColors.primaryAccent,
                    size: 20,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      l10n.outstandingPaymentsWithAmount(
                        'CHF ${selectedProperty.outstandingPayments}',
                      ),
                      style: const TextStyle(
                        fontSize: 14,
                        color: AppColors.primaryAccent,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPaymentDetailsSection() {
    final l10n = AppLocalizations.of(context)!;
    // Ensure selections remain valid & unique
    if (_selectedPaymentType != null &&
        !_paymentTypes.contains(_selectedPaymentType)) {
      _selectedPaymentType = _paymentTypes.first;
    }
    if (_selectedPaymentMethod != null &&
        !_paymentMethods.contains(_selectedPaymentMethod)) {
      _selectedPaymentMethod = _paymentMethods.first;
    }
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surfaceCards,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: AppColors.borderLight,
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: AppColors.shadowColor.withValues(alpha: 0.08),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              l10n.paymentDetailsTitle,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        l10n.paymentType,
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    DropdownButtonFormField<String>(
                      isExpanded: true,
                      initialValue: _selectedPaymentType,
                      dropdownColor: _fieldColor,
                      icon: const Icon(
                        Icons.keyboard_arrow_down_rounded,
                        color: _textSecondary,
                      ),
                      style: const TextStyle(
                        color: _textPrimary,
                        fontSize: 14,
                      ),
                      decoration: const InputDecoration(
                        filled: true,
                        fillColor: _fieldColor,
                        border: OutlineInputBorder(
                          borderRadius: _fieldBorderRadius,
                          borderSide: BorderSide.none,
                        ),
                        child: DropdownButtonFormField<String>(
                          initialValue: _selectedPaymentType,
                          decoration: const InputDecoration(
                            border: InputBorder.none,
                            contentPadding: EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 12,
                            ),
                          ),
                          style: const TextStyle(
                            color: AppColors.textPrimary,
                            fontSize: 14,
                          ),
                          dropdownColor: AppColors.surfaceCards,
                          items: _paymentTypes.map((type) {
                            return DropdownMenuItem<String>(
                              value: type,
                              child: Text(_paymentTypeDisplay(l10n, type)),
                            );
                          }).toList(),
                          onChanged: (String? newValue) {
                            setState(() {
                              _selectedPaymentType = newValue;
                            });
                          },
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        l10n.paymentMethod,
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                          color: AppColors.textSecondary,
                        ),
                      ),
                      items: _paymentTypes.map((type) {
                        return DropdownMenuItem<String>(
                          value: type,
                          child: Text(
                            type,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(color: _textPrimary),
                          ),
                        );
                      }).toList(),
                      onChanged: (String? newValue) {
                        setState(() {
                          _selectedPaymentType = newValue;
                        });
                      },
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Payment Method',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        color: _textSecondary,
                      ),
                    ),
                    const SizedBox(height: 8),
                    DropdownButtonFormField<String>(
                      isExpanded: true,
                      initialValue: _selectedPaymentMethod,
                      dropdownColor: _fieldColor,
                      icon: const Icon(
                        Icons.keyboard_arrow_down_rounded,
                        color: _textSecondary,
                      ),
                      style: const TextStyle(
                        color: _textPrimary,
                        fontSize: 14,
                      ),
                      decoration: const InputDecoration(
                        filled: true,
                        fillColor: _fieldColor,
                        border: OutlineInputBorder(
                          borderRadius: _fieldBorderRadius,
                          borderSide: BorderSide.none,
                        ),
                        child: DropdownButtonFormField<String>(
                          initialValue: _selectedPaymentMethod,
                          decoration: const InputDecoration(
                            border: InputBorder.none,
                            contentPadding: EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 12,
                            ),
                          ),
                          style: const TextStyle(
                            color: AppColors.textPrimary,
                            fontSize: 14,
                          ),
                          dropdownColor: AppColors.surfaceCards,
                          items: _paymentMethods.map((method) {
                            return DropdownMenuItem<String>(
                              value: method,
                              child: Text(_paymentMethodDisplay(l10n, method)),
                            );
                          }).toList(),
                          onChanged: (String? newValue) {
                            setState(() {
                              _selectedPaymentMethod = newValue;
                            });
                          },
                        ),
                      ),
                      items: _paymentMethods.map((method) {
                        return DropdownMenuItem<String>(
                          value: method,
                          child: Text(
                            method,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(color: _textPrimary),
                          ),
                        );
                      }).toList(),
                      onChanged: (String? newValue) {
                        setState(() {
                          _selectedPaymentMethod = newValue;
                        });
                      },
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 16),
            Text(
              '${l10n.amount} (CHF)',
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: AppColors.textSecondary,
              ),
            ],
          ),
          const SizedBox(height: 16),
          const Text(
            'Amount (CHF)',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: _textSecondary,
            ),
          ),
          const SizedBox(height: 8),
          TextFormField(
            controller: _amountController,
            keyboardType: TextInputType.number,
            cursorColor: Colors.greenAccent,
            decoration: const InputDecoration(
              filled: true,
              fillColor: _fieldColor,
              hintText: 'Enter amount',
              hintStyle: TextStyle(
                color: Colors.white54,
              ),
              child: TextFormField(
                controller: _amountController,
                keyboardType: TextInputType.number,
                decoration: InputDecoration(
                  hintText: l10n.enterAmount,
                  hintStyle: const TextStyle(
                    color: AppColors.textTertiary,
                  ),
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 12,
                  ),
                  prefixText: 'CHF ',
                  prefixStyle: const TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                style: const TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 14,
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return l10n.pleaseEnterAmount;
                  }
                  if (double.tryParse(value) == null) {
                    return l10n.pleaseEnterValidNumber;
                  }
                  if (double.parse(value) <= 0) {
                    return l10n.amountMustBeGreaterThanZero;
                  }
                  return null;
                },
              ),
            ),
            style: const TextStyle(
              color: Colors.greenAccent,
              fontSize: 16,
              fontWeight: FontWeight.w700,
            ),
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Please enter an amount';
              }
              if (double.tryParse(value) == null) {
                return 'Please enter a valid number';
              }
              if (double.parse(value) <= 0) {
                return 'Amount must be greater than 0';
              }
              return null;
            },
          ),
        ],
      ),
    );
  }

  Widget _buildNotesSection() {
    final l10n = AppLocalizations.of(context)!;
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surfaceCards,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: AppColors.borderLight,
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: AppColors.shadowColor.withValues(alpha: 0.08),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              l10n.notesOptional,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: AppColors.textPrimary,
              ),
              border: OutlineInputBorder(
                borderRadius: _fieldBorderRadius,
                borderSide: BorderSide.none,
              ),
              child: TextFormField(
                controller: _notesController,
                maxLines: 3,
                decoration: InputDecoration(
                  hintText: l10n.addAdditionalNotes,
                  hintStyle: const TextStyle(
                    color: AppColors.textTertiary,
                  ),
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.all(16),
                ),
                style: const TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 14,
                ),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: _fieldBorderRadius,
                borderSide: BorderSide.none,
              ),
              contentPadding: EdgeInsets.all(16),
            ),
            style: const TextStyle(
              color: _textPrimary,
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSubmitButton() {
    final l10n = AppLocalizations.of(context)!;
    return SizedBox(
      width: double.infinity,
      height: 48,
      child: ElevatedButton(
        onPressed: _submitPayment,
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primaryAccent,
          foregroundColor: AppColors.textOnAccent,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          elevation: 0,
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.payment,
              size: 18,
            ),
            const SizedBox(width: 8),
            Text(
              l10n.submitPayment,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
      child: GestureDetector(
        onTap: _submitPayment,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 16),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Color(0xFF2563EB), Color(0xFF22D3EE)],
              begin: Alignment.centerLeft,
              end: Alignment.centerRight,
            ),
            borderRadius: BorderRadius.circular(14),
            boxShadow: [
              BoxShadow(
                color: Colors.blueAccent.withValues(alpha: 0.4),
                blurRadius: 16,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: const Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.credit_card,
                color: Colors.white,
                size: 20,
              ),
              SizedBox(width: 10),
              Text(
                'Submit Payment',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _submitPayment() async {
    final l10n = AppLocalizations.of(context)!;

    if (!_formKey.currentState!.validate()) {
      return;
    }

    if (_selectedPropertyId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(l10n.pleaseSelectProperty),
          backgroundColor: AppColors.error,
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    final currentUser = ref.read(currentUserProvider);
    if (currentUser == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(l10n.userNotAuthenticated),
          backgroundColor: AppColors.error,
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    try {
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => Center(
          child: Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: _cardColor,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const CircularProgressIndicator(
                  valueColor:
                      AlwaysStoppedAnimation<Color>(AppColors.primaryAccent),
                ),
                const SizedBox(height: 16),
                Text(
                  l10n.processingPayment,
                  style: const TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 16,
                  ),
                ),
              ],
            ),
          ),
        ),
      );

      final payment = Payment(
        id: '',
        tenantId: currentUser.id,
        propertyId: _selectedPropertyId!,
        amount: double.parse(_amountController.text),
        type: _selectedPaymentType!.toLowerCase(),
        paymentMethod: _selectedPaymentMethod!.toLowerCase(),
        status: 'pending',
        date: DateTime.now(),
        notes: _notesController.text.isNotEmpty ? _notesController.text : null,
      );

      await ref.read(paymentNotifierProvider.notifier).createPayment(payment);

      if (mounted) {
        Navigator.of(context).pop(); // Close loading dialog

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(l10n.paymentSubmittedSuccessfully),
            backgroundColor: AppColors.success,
            behavior: SnackBarBehavior.floating,
          ),
        );

        context.pop(); // Return to previous page
      }
    } catch (e) {
      if (mounted) {
        Navigator.of(context).pop(); // Close loading dialog

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(l10n.failedToSubmitPayment(e)),
            backgroundColor: AppColors.error,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }
}

class BentoCard extends StatelessWidget {
  const BentoCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(20),
    this.backgroundColor = _cardColor,
  });

  final Widget child;
  final EdgeInsets padding;
  final Color backgroundColor;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: padding,
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.06),
          width: 1,
        ),
      ),
      child: child,
    );
  }
}

*/
