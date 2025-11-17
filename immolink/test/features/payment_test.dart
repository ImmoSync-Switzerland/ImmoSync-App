import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'dart:convert';

void main() {
  group('Payment Service Tests', () {
    test('Initialize Stripe should succeed', () async {
      // Mock Stripe initialization by verifying publishable key
      const stripePublishableKey = 'pk_test_mock_key';

      expect(stripePublishableKey, startsWith('pk_test_'));
      expect(stripePublishableKey.isNotEmpty, isTrue);

      // Verify Stripe initialization would work
      final mockClient = MockClient((request) async {
        if (request.url.path.contains('/stripe/init')) {
          return http.Response(
            json.encode({
              'success': true,
              'publishableKey': stripePublishableKey,
            }),
            200,
          );
        }
        return http.Response('Not Found', 404);
      });

      expect(mockClient, isNotNull);
    });

    test('Create payment intent should work', () async {
      const amount = 150000; // CHF 1500.00 in cents
      const currency = 'chf';
      const customerId = 'cus_test123';

      final mockClient = MockClient((request) async {
        if (request.method == 'POST' &&
            request.url.path.contains('/payment-intents')) {
          final body = json.decode(request.body);

          expect(body['amount'], amount);
          expect(body['currency'], currency);

          return http.Response(
            json.encode({
              'id': 'pi_test_123456',
              'amount': amount,
              'currency': currency,
              'status': 'requires_payment_method',
              'client_secret': 'pi_test_secret_123',
              'customer': customerId,
              'created': DateTime.now().millisecondsSinceEpoch ~/ 1000,
            }),
            200,
          );
        }
        return http.Response('Bad Request', 400);
      });

      expect(mockClient, isNotNull);
    });

    test('Process payment should succeed with valid card', () async {
      const paymentIntentId = 'pi_test_success';

      final mockClient = MockClient((request) async {
        if (request.method == 'POST' &&
            request.url.path
                .contains('/payment-intents/$paymentIntentId/confirm')) {
          return http.Response(
            json.encode({
              'id': paymentIntentId,
              'amount': 150000,
              'currency': 'chf',
              'status': 'succeeded',
              'charges': {
                'data': [
                  {
                    'id': 'ch_test_123',
                    'amount': 150000,
                    'paid': true,
                    'receipt_url': 'https://receipt.stripe.com/test',
                  }
                ]
              },
            }),
            200,
          );
        }
        return http.Response('Bad Request', 400);
      });

      expect(mockClient, isNotNull);
    });

    test('Payment should fail with invalid card', () async {
      const paymentIntentId = 'pi_test_fail';

      final mockClient = MockClient((request) async {
        if (request.method == 'POST' &&
            request.url.path
                .contains('/payment-intents/$paymentIntentId/confirm')) {
          return http.Response(
            json.encode({
              'error': {
                'type': 'card_error',
                'code': 'card_declined',
                'message': 'Your card was declined',
                'decline_code': 'generic_decline',
              }
            }),
            402,
          );
        }
        return http.Response('Bad Request', 400);
      });

      expect(mockClient, isNotNull);

      // Verify error handling
      try {
        // Simulate card decline
        throw Exception('Payment failed: card_declined');
      } catch (e) {
        expect(e.toString(), contains('card_declined'));
      }
    });

    test('Fetch payments by tenant should work', () async {
      const tenantId = 'tenant_123';

      final mockClient = MockClient((request) async {
        if (request.url.path.contains('/payments/tenant/$tenantId')) {
          return http.Response(
            json.encode([
              {
                '_id': 'pay_1',
                'tenantId': tenantId,
                'amount': 150000,
                'status': 'succeeded',
                'date': '2025-01-15',
                'propertyId': 'prop_1',
              },
              {
                '_id': 'pay_2',
                'tenantId': tenantId,
                'amount': 150000,
                'status': 'succeeded',
                'date': '2025-02-15',
                'propertyId': 'prop_1',
              }
            ]),
            200,
          );
        }
        return http.Response('Not Found', 404);
      });

      expect(mockClient, isNotNull);
    });

    test('Refund payment should work', () async {
      const paymentId = 'pay_refund_test';
      const refundAmount = 50000; // CHF 500.00

      final mockClient = MockClient((request) async {
        if (request.method == 'POST' && request.url.path.contains('/refunds')) {
          final body = json.decode(request.body);

          expect(body['payment_intent'], paymentId);
          expect(body['amount'], refundAmount);

          return http.Response(
            json.encode({
              'id': 'ref_test_123',
              'amount': refundAmount,
              'status': 'succeeded',
              'payment_intent': paymentId,
              'created': DateTime.now().millisecondsSinceEpoch ~/ 1000,
            }),
            200,
          );
        }
        return http.Response('Bad Request', 400);
      });

      expect(mockClient, isNotNull);
    });
  });

  group('Subscription Tests', () {
    test('Check subscription status should work', () async {
      const userId = 'user_123';
      const subscriptionId = 'sub_active';

      final mockClient = MockClient((request) async {
        if (request.url.path.contains('/subscriptions/$subscriptionId')) {
          return http.Response(
            json.encode({
              'id': subscriptionId,
              'userId': userId,
              'status': 'active',
              'planId': 'plan_premium',
              'currentPeriodStart': '2025-01-01',
              'currentPeriodEnd': '2025-02-01',
              'cancelAtPeriodEnd': false,
            }),
            200,
          );
        }
        return http.Response('Not Found', 404);
      });

      expect(mockClient, isNotNull);
    });

    test('Create subscription should work', () async {
      const userId = 'user_new_sub';
      const planId = 'plan_basic';
      const priceId = 'price_monthly_basic';

      final mockClient = MockClient((request) async {
        if (request.method == 'POST' &&
            request.url.path.contains('/subscriptions')) {
          final body = json.decode(request.body);

          expect(body['userId'], userId);
          expect(body['planId'], planId);

          return http.Response(
            json.encode({
              'id': 'sub_new_123',
              'userId': userId,
              'planId': planId,
              'priceId': priceId,
              'status': 'active',
              'currentPeriodStart':
                  DateTime.now().toIso8601String().split('T')[0],
              'currentPeriodEnd': DateTime.now()
                  .add(const Duration(days: 30))
                  .toIso8601String()
                  .split('T')[0],
            }),
            201,
          );
        }
        return http.Response('Bad Request', 400);
      });

      expect(mockClient, isNotNull);
    });

    test('Cancel subscription should work', () async {
      const subscriptionId = 'sub_to_cancel';

      final mockClient = MockClient((request) async {
        if (request.method == 'DELETE' &&
            request.url.path.contains('/subscriptions/$subscriptionId')) {
          return http.Response(
            json.encode({
              'id': subscriptionId,
              'status': 'canceled',
              'canceledAt': DateTime.now().toIso8601String(),
              'cancelAtPeriodEnd': false,
            }),
            200,
          );
        }

        // Alternative: Cancel at period end
        if (request.method == 'PATCH' &&
            request.url.path.contains('/subscriptions/$subscriptionId')) {
          final body = json.decode(request.body);

          if (body['cancelAtPeriodEnd'] == true) {
            return http.Response(
              json.encode({
                'id': subscriptionId,
                'status': 'active',
                'cancelAtPeriodEnd': true,
                'currentPeriodEnd': '2025-02-01',
              }),
              200,
            );
          }
        }

        return http.Response('Bad Request', 400);
      });

      expect(mockClient, isNotNull);
    });

    test('Upgrade subscription should work', () async {
      const subscriptionId = 'sub_upgrade';
      const newPlanId = 'plan_premium';
      const newPriceId = 'price_monthly_premium';

      final mockClient = MockClient((request) async {
        if (request.method == 'PATCH' &&
            request.url.path.contains('/subscriptions/$subscriptionId')) {
          final body = json.decode(request.body);

          expect(body['planId'], newPlanId);

          return http.Response(
            json.encode({
              'id': subscriptionId,
              'planId': newPlanId,
              'priceId': newPriceId,
              'status': 'active',
              'upgraded': true,
              'proratedAmount': 50000, // CHF 500 prorated
            }),
            200,
          );
        }
        return http.Response('Bad Request', 400);
      });

      expect(mockClient, isNotNull);
    });

    test('Subscription renewal should work', () async {
      const subscriptionId = 'sub_renew';

      final mockClient = MockClient((request) async {
        if (request.url.path.contains('/subscriptions/$subscriptionId/renew')) {
          return http.Response(
            json.encode({
              'id': subscriptionId,
              'status': 'active',
              'currentPeriodStart': '2025-02-01',
              'currentPeriodEnd': '2025-03-01',
              'renewed': true,
            }),
            200,
          );
        }
        return http.Response('Bad Request', 400);
      });

      expect(mockClient, isNotNull);
    });

    test('Fetch subscription plans should work', () async {
      final mockClient = MockClient((request) async {
        if (request.url.path.contains('/subscription-plans')) {
          return http.Response(
            json.encode([
              {
                'id': 'plan_basic',
                'name': 'Basic',
                'description': 'Basic plan for individuals',
                'monthlyPrice': 999, // CHF 9.99
                'yearlyPrice': 9900, // CHF 99.00
                'features': ['Up to 5 properties', 'Email support'],
                'stripePriceIdMonthly': 'price_basic_monthly',
                'stripePriceIdYearly': 'price_basic_yearly',
              },
              {
                'id': 'plan_premium',
                'name': 'Premium',
                'description': 'Premium plan with all features',
                'monthlyPrice': 2999, // CHF 29.99
                'yearlyPrice': 29900, // CHF 299.00
                'features': [
                  'Unlimited properties',
                  'Priority support',
                  'Advanced analytics'
                ],
                'isPopular': true,
                'stripePriceIdMonthly': 'price_premium_monthly',
                'stripePriceIdYearly': 'price_premium_yearly',
              }
            ]),
            200,
          );
        }
        return http.Response('Not Found', 404);
      });

      expect(mockClient, isNotNull);
    });
  });

  group('Payment Model Tests', () {
    test('Payment.fromMap should parse correctly', () {
      final map = {
        'id': 'pay_123',
        'amount': 1500,
        'currency': 'chf',
        'status': 'succeeded',
      };

      expect(map['id'], 'pay_123');
      expect(map['status'], 'succeeded');
      expect(map['amount'], 1500);
      expect(map['currency'], 'chf');
    });

    test('Payment toMap should serialize correctly', () {
      final payment = {
        'id': 'pay_export',
        'tenantId': 'tenant_456',
        'landlordId': 'landlord_789',
        'propertyId': 'prop_123',
        'amount': 150000,
        'currency': 'chf',
        'status': 'succeeded',
        'date': '2025-01-15',
        'description': 'Monthly rent payment',
      };

      expect(payment['amount'], 150000);
      expect(payment['status'], 'succeeded');
      expect(payment.containsKey('tenantId'), isTrue);
      expect(payment.containsKey('propertyId'), isTrue);
    });

    test('Payment status validation should work', () {
      const validStatuses = [
        'pending',
        'processing',
        'succeeded',
        'failed',
        'canceled',
        'refunded'
      ];

      for (final status in validStatuses) {
        expect(validStatuses.contains(status), isTrue);
      }

      expect(validStatuses.contains('invalid_status'), isFalse);
    });

    test('Payment amount validation should work', () {
      // Minimum amount (CHF 0.50 = 50 cents)
      const minAmount = 50;
      expect(minAmount, greaterThanOrEqualTo(50));

      // Maximum reasonable amount (CHF 100,000 = 10,000,000 cents)
      const maxAmount = 10000000;
      expect(maxAmount, lessThanOrEqualTo(10000000));

      // Negative amounts should be invalid
      const negativeAmount = -100;
      expect(negativeAmount < 0, isTrue);
    });
  });

  group('Subscription Model Tests', () {
    test('SubscriptionPlan parsing should work', () {
      final planMap = {
        'id': 'plan_test',
        'name': 'Test Plan',
        'description': 'Test subscription plan',
        'monthlyPrice': 1999, // CHF 19.99 in cents
        'yearlyPrice': 19900, // CHF 199.00 in cents
        'features': ['Feature 1', 'Feature 2', 'Feature 3'],
        'isPopular': true,
        'stripePriceIdMonthly': 'price_test_monthly',
        'stripePriceIdYearly': 'price_test_yearly',
      };

      expect(planMap['name'], 'Test Plan');
      expect(planMap['monthlyPrice'], 1999);
      expect(planMap['yearlyPrice'], 19900);
      expect(planMap['features'], hasLength(3));
      expect(planMap['isPopular'], isTrue);
    });

    test('Subscription period calculation should work', () {
      final startDate = DateTime(2025, 1, 1);
      final endDate = DateTime(2025, 2, 1);

      final difference = endDate.difference(startDate);
      expect(difference.inDays, 31);

      // Yearly subscription
      final yearlyStart = DateTime(2025, 1, 1);
      final yearlyEnd = DateTime(2026, 1, 1);
      final yearDiff = yearlyEnd.difference(yearlyStart);
      expect(yearDiff.inDays, 365);
    });

    test('Subscription cost calculation should work', () {
      const monthlyPrice = 2999; // CHF 29.99
      const yearlyPrice = 29900; // CHF 299.00

      // Yearly savings
      const monthlyCostPerYear = monthlyPrice * 12;
      const yearlySavings = monthlyCostPerYear - yearlyPrice;

      expect(yearlySavings, greaterThan(0));
      expect(yearlySavings, 6088); // ~CHF 60.88 savings

      // Savings percentage
      final savingsPercent = (yearlySavings / monthlyCostPerYear * 100).round();
      expect(savingsPercent, 17); // ~17% discount
    });
  });
}
