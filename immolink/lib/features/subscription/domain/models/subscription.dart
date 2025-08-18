class SubscriptionPlan {
  final String id;
  final String name;
  final String description;
  final double monthlyPrice;
  final double yearlyPrice;
  final List<String> features;
  final bool isPopular;
  final String stripePriceIdMonthly;
  final String stripePriceIdYearly;

  SubscriptionPlan({
    required this.id,
    required this.name,
    required this.description,
    required this.monthlyPrice,
    required this.yearlyPrice,
    required this.features,
    this.isPopular = false,
    required this.stripePriceIdMonthly,
    required this.stripePriceIdYearly,
  });

  factory SubscriptionPlan.fromMap(Map<String, dynamic> map) {
    return SubscriptionPlan(
      id: map['id'],
      name: map['name'],
      description: map['description'] ?? '',
      monthlyPrice: (map['monthlyPrice'] ?? 0).toDouble(),
      yearlyPrice: (map['yearlyPrice'] ?? 0).toDouble(),
      features: map['features'] != null 
          ? List<String>.from(map['features'])
          : <String>[],
      isPopular: map['isPopular'] ?? false,
      stripePriceIdMonthly: map['monthlyPriceId'] ?? map['stripePriceIdMonthly'] ?? '',
      stripePriceIdYearly: map['yearlyPriceId'] ?? map['stripePriceIdYearly'] ?? '',
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'monthlyPrice': monthlyPrice,
      'yearlyPrice': yearlyPrice,
      'features': features,
      'isPopular': isPopular,
      'stripePriceIdMonthly': stripePriceIdMonthly,
      'stripePriceIdYearly': stripePriceIdYearly,
    };
  }
}

class UserSubscription {
  final String id;
  final String userId;
  final String planId;
  final String status; // 'active', 'canceled', 'past_due', 'incomplete'
  final DateTime startDate;
  final DateTime? endDate;
  final String billingInterval; // 'monthly', 'yearly'
  final String stripeSubscriptionId;
  final String? stripeCustomerId;
  final double amount;
  final DateTime nextBillingDate;

  UserSubscription({
    required this.id,
    required this.userId,
    required this.planId,
    required this.status,
    required this.startDate,
    this.endDate,
    required this.billingInterval,
    required this.stripeSubscriptionId,
    this.stripeCustomerId,
    required this.amount,
    required this.nextBillingDate,
  });

  factory UserSubscription.fromMap(Map<String, dynamic> map) {
    return UserSubscription(
      id: map['_id']?.toString() ?? map['id']?.toString() ?? '',
      userId: map['userId']?.toString() ?? '',
      planId: map['planId']?.toString() ?? '',
      status: map['status']?.toString() ?? 'unknown',
      startDate: map['createdAt'] != null 
        ? DateTime.parse(map['createdAt']) 
        : (map['startDate'] != null ? DateTime.parse(map['startDate']) : DateTime.now()),
      endDate: map['currentPeriodEnd'] != null 
        ? DateTime.parse(map['currentPeriodEnd']) 
        : (map['endDate'] != null ? DateTime.parse(map['endDate']) : null),
      billingInterval: map['billingInterval']?.toString() ?? 'month',
      stripeSubscriptionId: map['stripeSubscriptionId']?.toString() ?? '',
      stripeCustomerId: map['stripeCustomerId']?.toString(),
      amount: (map['amount'] ?? 0).toDouble(),
      nextBillingDate: map['currentPeriodEnd'] != null 
        ? DateTime.parse(map['currentPeriodEnd']) 
        : (map['nextBillingDate'] != null ? DateTime.parse(map['nextBillingDate']) : DateTime.now()),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'userId': userId,
      'planId': planId,
      'status': status,
      'startDate': startDate.toIso8601String(),
      'endDate': endDate?.toIso8601String(),
      'billingInterval': billingInterval,
      'stripeSubscriptionId': stripeSubscriptionId,
      'stripeCustomerId': stripeCustomerId,
      'amount': amount,
      'nextBillingDate': nextBillingDate.toIso8601String(),
    };
  }

  bool get isActive => status == 'active';
  bool get isCanceled => status == 'canceled';
  bool get isPastDue => status == 'past_due';
}
