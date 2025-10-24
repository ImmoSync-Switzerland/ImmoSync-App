# Stripe Connect Integration Guide

## ✅ Completed Implementation

### Backend (Node.js/Express)
- ✅ **15 API Endpoints** in `routes/connect.js`
  - Account management (create, get, onboarding)
  - Payment operations (create, confirm, history)
  - Financial operations (balance, payouts, refunds)
  - Payment methods by country
  - Webhook handling

### Flutter Frontend
- ✅ **Service Layer** (`stripe_connect_payment_service.dart`)
  - 15 methods matching backend API
  - 9 data models with JSON serialization
  - Comprehensive error handling
  
- ✅ **State Management** (`payment_providers.dart`)
  - 7 FutureProviders for reactive data
  - StripeConnectNotifier for mutations
  - Auto-dispose pattern
  
- ✅ **Example UI** (`landlord_stripe_dashboard.dart`)
  - Account status card
  - Balance display
  - Payment history
  - Onboarding flow

## 🚀 Quick Start

### 1. Backend Setup

#### Environment Variables
Add to `ImmoSync-Backend/.env`:
```env
STRIPE_SECRET_KEY=sk_test_51xxx
STRIPE_WEBHOOK_SECRET=whsec_xxx
APP_URL=https://backend.immosync.ch
```

#### Test the API
```bash
cd ImmoSync-Backend
npm install stripe  # if not already installed
node server.js

# Test endpoint
curl http://localhost:3000/api/connect/payment-methods/CH
```

### 2. Flutter Setup

#### Dependencies
Already included in `pubspec.yaml`:
- `http: ^1.1.0`
- `flutter_riverpod: ^2.4.9`

#### Configuration
Set API URL in `.env` or dart-define:
```env
API_URL=https://backend.immosync.ch/api
```

#### Test Service
```dart
import 'package:immosync/features/payment/domain/services/stripe_connect_payment_service.dart';

final service = StripeConnectPaymentService();

// Test getting payment methods
final methods = await service.getAvailablePaymentMethods('CH');
print(methods); // [card, bank_transfer, sofort]
```

## 📋 Implementation Checklist

### Phase 1: Account Setup ⏳
- [ ] Add "Setup Payments" button in Landlord Dashboard
- [ ] Implement onboarding flow:
  1. Check if account exists
  2. Create account if needed
  3. Generate onboarding link
  4. Open in browser/WebView
  5. Handle return URL
- [ ] Show account status badge (Active/Pending/Not Setup)
- [ ] Display capabilities (charges, payouts)

**Example Code:**
```dart
// In landlord_dashboard.dart
final accountAsync = ref.watch(stripeConnectAccountProvider);

accountAsync.when(
  data: (account) {
    if (!account.chargesEnabled) {
      return _buildSetupPaymentsButton();
    }
    return _buildPaymentDashboardCard();
  },
  loading: () => CircularProgressIndicator(),
  error: (_, __) => _buildSetupPaymentsButton(), // No account yet
);
```

### Phase 2: Tenant Payment UI ⏳
- [ ] Create payment page (`tenant_payment_page.dart`)
- [ ] Add Stripe Elements integration:
  ```yaml
  # pubspec.yaml
  dependencies:
    flutter_stripe: ^10.0.0
  ```
- [ ] Payment form with:
  - Amount input (auto-filled from rent)
  - Payment method selector
  - Terms & conditions
  - Submit button
- [ ] Handle payment flow:
  1. Create payment intent
  2. Show Stripe checkout
  3. Confirm payment
  4. Show success/failure

**Example Flow:**
```dart
// Create payment
final intent = await ref.read(stripeConnectNotifierProvider.notifier)
    .createTenantPayment(
      tenantId: user.id,
      propertyId: property.id,
      amount: property.monthlyRent,
    );

// Initialize Stripe
await Stripe.instance.initPaymentSheet(
  paymentSheetParameters: SetupPaymentSheetParameters(
    merchantDisplayName: 'ImmoLink',
    paymentIntentClientSecret: intent.clientSecret,
  ),
);

// Present payment sheet
await Stripe.instance.presentPaymentSheet();

// Confirm in backend
await ref.read(stripeConnectNotifierProvider.notifier)
    .confirmPayment(paymentIntentId: intent.paymentIntentId);
```

### Phase 3: Balance Dashboard ⏳
- [ ] Extend `landlord_stripe_dashboard.dart`
- [ ] Add balance card (already in example)
- [ ] Add transaction history list
- [ ] Add "Request Payout" button
- [ ] Implement payout dialog:
  - Amount input
  - Estimated arrival date
  - Confirm button

**UI Components:**
```dart
// Already implemented in example:
- _buildAccountStatusCard()
- _buildBalanceCard()
- _buildPaymentCard()

// To add:
- _buildPayoutRequestDialog()
- _buildTransactionList()
```

### Phase 4: Notifications ⏳
- [ ] Add webhook event handlers in backend
- [ ] Send push notifications on:
  - Payment received
  - Payout completed
  - Account updated
- [ ] Create notification models
- [ ] Update notification service

### Phase 5: Testing ⏳
- [ ] Unit tests for service methods
- [ ] Widget tests for UI components
- [ ] Integration tests for payment flow
- [ ] Test with Stripe test cards
- [ ] Test webhook events

### Phase 6: Production ⏳
- [ ] Create production Stripe account
- [ ] Update environment variables
- [ ] Configure production webhook endpoint
- [ ] Test with real bank account
- [ ] Submit for app review if needed

## 🔧 Code Examples

### Open Onboarding Link
```dart
import 'package:url_launcher/url_launcher.dart';

Future<void> openOnboardingLink(BuildContext context, WidgetRef ref) async {
  final user = ref.read(currentUserProvider)!;
  final notifier = ref.read(stripeConnectNotifierProvider.notifier);
  
  // Create account if doesn't exist
  var account = await notifier.createConnectAccount(
    landlordId: user.id,
    email: user.email,
  );
  
  if (account == null) return;
  
  // Get onboarding link
  final url = await notifier.createOnboardingLink(
    accountId: account.accountId,
    refreshUrl: 'immosync://stripe-refresh',
    returnUrl: 'immosync://stripe-return',
  );
  
  if (url != null) {
    await launchUrl(Uri.parse(url));
  }
}
```

### Handle Deep Links
Add to `AndroidManifest.xml`:
```xml
<intent-filter>
    <action android:name="android.intent.action.VIEW" />
    <category android:name="android.intent.category.DEFAULT" />
    <category android:name="android.intent.category.BROWSABLE" />
    <data android:scheme="immosync" />
</intent-filter>
```

Handle in `main.dart`:
```dart
// Listen for deep links
final sub = linkStream.listen((String? link) {
  if (link?.startsWith('immosync://stripe-return') == true) {
    // Refresh account status
    ref.invalidate(stripeConnectAccountProvider);
    // Navigate to dashboard
    GoRouter.of(context).go('/landlord/payments');
  }
});
```

### Display Payment History
```dart
final paymentsAsync = ref.watch(landlordConnectPaymentsProvider);

paymentsAsync.when(
  data: (payments) {
    if (payments.isEmpty) {
      return Center(child: Text('No payments yet'));
    }
    
    return ListView.builder(
      itemCount: payments.length,
      itemBuilder: (context, index) {
        final payment = payments[index];
        return ListTile(
          leading: Icon(_getPaymentIcon(payment.paymentType)),
          title: Text('${payment.currency.toUpperCase()} ${payment.amount.toStringAsFixed(2)}'),
          subtitle: Text(_formatDate(payment.createdAt)),
          trailing: _buildStatusChip(payment.status),
        );
      },
    );
  },
  loading: () => CircularProgressIndicator(),
  error: (e, _) => Text('Error: $e'),
);
```

### Request Payout
```dart
Future<void> requestPayout(WidgetRef ref, double amount) async {
  final user = ref.read(currentUserProvider)!;
  final notifier = ref.read(stripeConnectNotifierProvider.notifier);
  
  try {
    final payout = await notifier.createPayout(
      landlordId: user.id,
      amount: amount,
      currency: 'chf',
      description: 'Payout request',
    );
    
    if (payout != null) {
      // Show success message
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Payout requested: CHF ${payout.amount}'),
          backgroundColor: Colors.green,
        ),
      );
      
      // Refresh balance
      ref.invalidate(landlordBalanceProvider);
      ref.invalidate(landlordPayoutsProvider);
    }
  } catch (e) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Error: $e'),
        backgroundColor: Colors.red,
      ),
    );
  }
}
```

## 🔒 Security Considerations

### Backend
1. **Add Authentication Middleware**
   ```javascript
   // middleware/auth.js
   const verifyToken = (req, res, next) => {
     const token = req.headers.authorization?.split(' ')[1];
     if (!token) return res.status(401).json({ message: 'Unauthorized' });
     
     try {
       const decoded = jwt.verify(token, process.env.JWT_SECRET);
       req.userId = decoded.userId;
       next();
     } catch (err) {
       res.status(401).json({ message: 'Invalid token' });
     }
   };
   
   // Apply to routes
   router.use('/connect', verifyToken);
   ```

2. **Validate User Permissions**
   ```javascript
   // Check if user owns the resource
   const landlord = await db.collection('users').findOne({ 
     _id: new ObjectId(landlordId) 
   });
   
   if (landlord._id.toString() !== req.userId) {
     return res.status(403).json({ message: 'Forbidden' });
   }
   ```

### Flutter
1. **Store Secrets Securely**
   - Never commit API keys to git
   - Use dart-define or .env files
   - Use flutter_secure_storage for tokens

2. **Validate User Input**
   ```dart
   if (amount <= 0 || amount > 100000) {
     throw Exception('Invalid amount');
   }
   ```

3. **Handle Errors Gracefully**
   ```dart
   try {
     await service.createPayment(...);
   } catch (e) {
     // Show user-friendly error
     ScaffoldMessenger.of(context).showSnackBar(
       SnackBar(content: Text('Payment failed. Please try again.')),
     );
   }
   ```

## 📊 Monitoring

### Backend Logs
```javascript
// Log all payment operations
console.log(`[Payment] Creating payment for tenant ${tenantId}, amount ${amount}`);
console.log(`[Payout] Requesting payout for landlord ${landlordId}, amount ${amount}`);
```

### Error Tracking
Consider adding Sentry or similar:
```javascript
const Sentry = require("@sentry/node");
Sentry.init({ dsn: process.env.SENTRY_DSN });

// Capture errors
app.use(Sentry.Handlers.errorHandler());
```

### Stripe Dashboard
- Monitor payments in real-time
- Set up email alerts for disputes
- Review payout schedule

## 🆘 Troubleshooting

### "Connect account not found"
- Check if `stripeConnectAccountId` exists in user document
- Verify landlord has completed account creation

### "Payment failed"
- Check Stripe dashboard for decline reason
- Verify account has charges enabled
- Test with different payment method

### "Insufficient balance for payout"
- Check available balance in Stripe
- Ensure pending balance has cleared
- Wait 2-3 days for balance availability

### Webhook not firing
- Verify webhook secret in .env
- Check Stripe webhook logs
- Ensure endpoint is publicly accessible
- Test with Stripe CLI

## 📚 Resources

- [Stripe Connect Express Docs](https://stripe.com/docs/connect/express-accounts)
- [Stripe API Reference](https://stripe.com/docs/api)
- [Flutter Stripe Plugin](https://pub.dev/packages/flutter_stripe)
- [Riverpod Documentation](https://riverpod.dev)
- **Full API Documentation:** `STRIPE_CONNECT_API.md`

## ✅ Summary

**What's Done:**
- ✅ Complete backend API (15 endpoints)
- ✅ Flutter service layer (15 methods)
- ✅ Riverpod state management (7 providers + notifier)
- ✅ Example dashboard UI
- ✅ Full documentation

**What's Next:**
- ⏳ Integrate Stripe Elements for checkout UI
- ⏳ Add URL launcher for onboarding
- ⏳ Implement deep linking
- ⏳ Add authentication middleware
- ⏳ Create payment receipt UI
- ⏳ Setup production Stripe account

**Estimated Time to MVP:** 2-3 days
