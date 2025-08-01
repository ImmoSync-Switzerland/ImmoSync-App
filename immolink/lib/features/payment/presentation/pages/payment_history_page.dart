import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:immolink/features/auth/presentation/providers/auth_provider.dart';
import 'package:immolink/features/payment/domain/models/payment.dart';
import 'package:immolink/features/payment/presentation/providers/payment_providers.dart';
import 'package:intl/intl.dart';

class PaymentHistoryPage extends ConsumerWidget {
  const PaymentHistoryPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentUser = ref.watch(currentUserProvider);
    final payments = currentUser?.role == 'landlord'
        ? ref.watch(landlordPaymentsProvider)
        : ref.watch(tenantPaymentsProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Payment History'),
        flexibleSpace: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [Colors.blue.shade700, Colors.blue.shade900],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
        ),
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Colors.blue.shade50, Colors.white],
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildFilterOptions(context),
              const SizedBox(height: 16),
              Expanded(
                child: payments.when(
                  data: (paymentsList) {
                    if (paymentsList.isEmpty) {
                      return const Center(
                        child: Text(
                          'No payment history found',
                          style: TextStyle(fontSize: 18),
                        ),
                      );
                    }

                    return ListView.builder(
                      itemCount: paymentsList.length,
                      itemBuilder: (context, index) {
                        return _buildPaymentCard(context, paymentsList[index]);
                      },
                    );
                  },
                  loading: () => const Center(child: CircularProgressIndicator()),
                  error: (error, stack) => Center(
                    child: Text('Error loading payment history: $error'),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFilterOptions(BuildContext context) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Filter Payments',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: DropdownButtonFormField<String>(
                    value: 'All',
                    decoration: InputDecoration(
                      labelText: 'Status',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 8,
                      ),
                    ),
                    items: const [
                      DropdownMenuItem(value: 'All', child: Text('All')),
                      DropdownMenuItem(value: 'pending', child: Text('Pending')),
                      DropdownMenuItem(value: 'completed', child: Text('Completed')),
                      DropdownMenuItem(value: 'failed', child: Text('Failed')),
                      DropdownMenuItem(value: 'refunded', child: Text('Refunded')),
                    ],
                    onChanged: (value) {
                      // TODO: Implement filtering
                    },
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: DropdownButtonFormField<String>(
                    value: 'All',
                    decoration: InputDecoration(
                      labelText: 'Type',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 8,
                      ),
                    ),
                    items: const [
                      DropdownMenuItem(value: 'All', child: Text('All')),
                      DropdownMenuItem(value: 'rent', child: Text('Rent')),
                      DropdownMenuItem(value: 'deposit', child: Text('Deposit')),
                      DropdownMenuItem(value: 'fee', child: Text('Fee')),
                    ],
                    onChanged: (value) {
                      // TODO: Implement filtering
                    },
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPaymentCard(BuildContext context, Payment payment) {
    Color statusColor;
    IconData statusIcon;

    switch (payment.status) {
      case 'pending':
        statusColor = Colors.orange;
        statusIcon = Icons.hourglass_empty;
        break;
      case 'completed':
        statusColor = Colors.green;
        statusIcon = Icons.check_circle;
        break;
      case 'failed':
        statusColor = Colors.red;
        statusIcon = Icons.cancel;
        break;
      case 'refunded':
        statusColor = Colors.blue;
        statusIcon = Icons.replay;
        break;
      default:
        statusColor = Colors.grey;
        statusIcon = Icons.help_outline;
    }

    final currencyFormat = NumberFormat.currency(symbol: 'CHF ');

    return Card(
      elevation: 4,
      margin: const EdgeInsets.only(bottom: 16),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: InkWell(
        onTap: () {
          _showPaymentDetails(context, payment);
        },
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text(
                      payment.type.toUpperCase(),
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
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
                          payment.status.toUpperCase(),
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: statusColor,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                currencyFormat.format(payment.amount),
                style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Property ID: ${payment.propertyId}',
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
                  'Method: ${payment.paymentMethod}',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey.shade700,
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  void _showPaymentDetails(BuildContext context, Payment payment) {
    final currencyFormat = NumberFormat.currency(symbol: 'CHF ');

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
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
                          'Payment Details',
                          style: const TextStyle(
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
                    _buildDetailItem('Amount', currencyFormat.format(payment.amount)),
                    _buildDetailItem('Status', payment.status.toUpperCase()),
                    _buildDetailItem('Type', payment.type.toUpperCase()),
                    _buildDetailItem('Date', DateFormat('MMM d, yyyy').format(payment.date)),
                    _buildDetailItem('Property ID', payment.propertyId),
                    _buildDetailItem('Tenant ID', payment.tenantId),
                    if (payment.transactionId != null)
                      _buildDetailItem('Transaction ID', payment.transactionId!),
                    if (payment.paymentMethod != null)
                      _buildDetailItem('Payment Method', payment.paymentMethod!),
                    if (payment.notes != null) ...[
                      const SizedBox(height: 16),
                      const Text(
                        'Notes',
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
                        onPressed: () {
                          // TODO: Implement payment cancellation
                          Navigator.pop(context);
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.red,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        child: const Text(
                          'Cancel Payment',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    if (payment.status == 'completed')
                      ElevatedButton(
                        onPressed: () {
                          // TODO: Implement receipt download
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.blue.shade700,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        child: const Text(
                          'Download Receipt',
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

  Widget _buildDetailItem(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              label,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Colors.grey.shade700,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(fontSize: 16),
            ),
          ),
        ],
      ),
    );
  }
}

