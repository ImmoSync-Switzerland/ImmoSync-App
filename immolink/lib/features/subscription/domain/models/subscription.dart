import 'dart:convert';

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
    // Helper to safely parse prices
    double parsePrice(dynamic value) {
      if (value == null) return 0.0;
      if (value is int) return value.toDouble() / 100; // Stripe uses cents
      if (value is double) return value;
      if (value is String) {
        try {
          return double.parse(value);
        } catch (e) {
          return 0.0;
        }
      }
      return 0.0;
    }

    // Parse features list
    List<String> parseFeatures(dynamic featuresValue) {
      if (featuresValue == null) return <String>[];
      if (featuresValue is List) {
        return featuresValue.map((e) => e.toString()).toList();
      }
      if (featuresValue is String) {
        // Try to parse as JSON array string
        try {
          final decoded = json.decode(featuresValue);
          if (decoded is List) {
            return decoded.map((e) => e.toString()).toList();
          }
        } catch (e) {
          // Not JSON, treat as single feature
          return [featuresValue];
        }
      }
      return <String>[];
    }

    return SubscriptionPlan(
      id: map['id']?.toString() ?? map['_id']?.toString() ?? '',
      name: map['name']?.toString() ?? map['nickname']?.toString() ?? '',
      description: map['description']?.toString() ?? 
                  map['product']?['description']?.toString() ?? '',
      monthlyPrice: parsePrice(
        map['monthlyPrice'] ?? 
        map['monthly_price'] ?? 
        map['prices']?['monthly'] ??
        map['unit_amount']
      ),
      yearlyPrice: parsePrice(
        map['yearlyPrice'] ?? 
        map['yearly_price'] ?? 
        map['prices']?['yearly'] ??
        map['unit_amount']
      ),
      features: parseFeatures(
        map['features'] ?? 
        map['product']?['features'] ??
        map['metadata']?['features']
      ),
      isPopular: map['isPopular'] == true || 
                map['is_popular'] == true ||
                map['metadata']?['popular'] == 'true',
      stripePriceIdMonthly: map['monthlyPriceId']?.toString() ?? 
                           map['monthly_price_id']?.toString() ??
                           map['stripePriceIdMonthly']?.toString() ?? 
                           (map['interval'] == 'month' ? map['id']?.toString() : '') ?? '',
      stripePriceIdYearly: map['yearlyPriceId']?.toString() ?? 
                          map['yearly_price_id']?.toString() ??
                          map['stripePriceIdYearly']?.toString() ?? 
                          (map['interval'] == 'year' ? map['id']?.toString() : '') ?? '',
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
    // Helper function to parse dates with multiple fallbacks
    DateTime? parseDateOptional(List<String> keys) {
      for (var key in keys) {
        final value = map[key];
        if (value != null) {
          try {
            // Handle both string and int (Unix timestamp)
            if (value is int) {
              // Only parse if not 0 (Unix epoch)
              if (value == 0) continue;
              return DateTime.fromMillisecondsSinceEpoch(value * 1000);
            }
            final parsed = DateTime.parse(value.toString());
            // Check if parsed date is Unix epoch (1970-01-01) which indicates invalid data
            if (parsed.year == 1970 && parsed.month == 1 && parsed.day == 1) {
              print('[UserSubscription] Skipping Unix epoch date from $key ($value)');
              continue;
            }
            return parsed;
          } catch (e) {
            print('[UserSubscription] Error parsing date from $key ($value): $e');
          }
        }
      }
      return null;
    }

    DateTime parseDate(List<String> keys, DateTime fallback) {
      return parseDateOptional(keys) ?? fallback;
    }

    // Parse status - normalize Stripe statuses
    String parseStatus(dynamic statusValue) {
      final status = statusValue?.toString().toLowerCase() ?? 'unknown';
      // Map Stripe statuses to our internal statuses
      switch (status) {
        case 'active':
        case 'trialing':
          return 'active';
        case 'canceled':
        case 'cancelled':
          return 'canceled';
        case 'past_due':
          return 'past_due';
        case 'incomplete':
        case 'incomplete_expired':
          return 'incomplete';
        case 'unpaid':
          return 'past_due';
        default:
          return status;
      }
    }

    print('[UserSubscription.fromMap] Parsing subscription data: $map');

    // Parse dates first to use in fallback calculation
    final startDate = parseDate(
      ['createdAt', 'created_at', 'startDate', 'start_date', 'created'],
      DateTime.now(),
    );
    
    final billingInterval = map['billingInterval']?.toString() ?? 
                           map['billing_interval']?.toString() ??
                           map['interval']?.toString() ?? 
                           'month';
    
    // Calculate fallback next billing date based on start date and interval
    final fallbackNextBilling = billingInterval == 'year' 
        ? DateTime(startDate.year + 1, startDate.month, startDate.day)
        : DateTime(startDate.year, startDate.month + 1, startDate.day);

    final subscription = UserSubscription(
      id: map['_id']?.toString() ?? map['id']?.toString() ?? '',
      userId: map['userId']?.toString() ?? map['user_id']?.toString() ?? '',
      planId: map['planId']?.toString() ?? 
              map['plan_id']?.toString() ?? 
              map['plan']?.toString() ?? '',
      status: parseStatus(map['status']),
      startDate: startDate,
      endDate: parseDateOptional(
        ['cancelAt', 'cancel_at', 'endDate', 'end_date', 'ended_at'],
      ),
      billingInterval: billingInterval,
      stripeSubscriptionId: map['stripeSubscriptionId']?.toString() ?? 
                          map['stripe_subscription_id']?.toString() ??
                          map['subscriptionId']?.toString() ??
                          map['subscription_id']?.toString() ?? '',
      stripeCustomerId: map['stripeCustomerId']?.toString() ??
                       map['stripe_customer_id']?.toString() ??
                       map['customerId']?.toString() ??
                       map['customer']?.toString(),
      amount: (map['amount'] ?? map['plan']?['amount'] ?? 0).toDouble(),
      nextBillingDate: parseDate(
        ['currentPeriodEnd', 'current_period_end', 'nextBillingDate', 
         'next_billing_date', 'billing_cycle_anchor'],
        fallbackNextBilling,
      ),
    );

    print('[UserSubscription.fromMap] Parsed nextBillingDate: ${subscription.nextBillingDate}');
    print('[UserSubscription.fromMap] Parsed endDate: ${subscription.endDate}');

    return subscription;
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
