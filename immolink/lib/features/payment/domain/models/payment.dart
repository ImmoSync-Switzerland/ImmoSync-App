class Payment {
  final String id;
  final String propertyId;
  final String tenantId;
  final double amount;
  final DateTime date;
  final String status; // 'pending', 'completed', 'failed', 'refunded'
  final String type; // 'rent', 'deposit', 'fee', etc.
  final String? transactionId;
  final String? paymentMethod; // 'credit_card', 'bank_transfer', etc.
  final String? notes;

  Payment({
    required this.id,
    required this.propertyId,
    required this.tenantId,
    required this.amount,
    required this.date,
    required this.status,
    required this.type,
    this.transactionId,
    this.paymentMethod,
    this.notes,
  });

  factory Payment.fromMap(Map<String, dynamic> map) {
    return Payment(
      id: map['_id'].toString(),
      propertyId: map['propertyId'],
      tenantId: map['tenantId'],
      amount: map['amount'].toDouble(),
      date: DateTime.parse(map['date']),
      status: map['status'],
      type: map['type'],
      transactionId: map['transactionId'],
      paymentMethod: map['paymentMethod'],
      notes: map['notes'],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'propertyId': propertyId,
      'tenantId': tenantId,
      'amount': amount,
      'date': date.toIso8601String(),
      'status': status,
      'type': type,
      'transactionId': transactionId,
      'paymentMethod': paymentMethod,
      'notes': notes,
    };
  }

  Payment copyWith({
    String? id,
    String? propertyId,
    String? tenantId,
    double? amount,
    DateTime? date,
    String? status,
    String? type,
    String? transactionId,
    String? paymentMethod,
    String? notes,
  }) {
    return Payment(
      id: id ?? this.id,
      propertyId: propertyId ?? this.propertyId,
      tenantId: tenantId ?? this.tenantId,
      amount: amount ?? this.amount,
      date: date ?? this.date,
      status: status ?? this.status,
      type: type ?? this.type,
      transactionId: transactionId ?? this.transactionId,
      paymentMethod: paymentMethod ?? this.paymentMethod,
      notes: notes ?? this.notes,
    );
  }
}
