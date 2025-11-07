# Stripe Customer Portal Integration

## Backend Endpoint Required

### POST /api/subscriptions/create-portal-session

Creates a Stripe Customer Portal session for subscription management.

**Request Body:**
```json
{
  "customerId": "cus_xxxxxxxxxxxxx",
  "returnUrl": "immosync://subscription/management"
}
```

**Response:**
```json
{
  "url": "https://billing.stripe.com/session/xxxxxxxxxxxxx"
}
```

**Backend Implementation Example (Node.js):**

```javascript
// routes/subscriptions.js
router.post('/create-portal-session', authenticateToken, async (req, res) => {
  try {
    const { customerId, returnUrl } = req.body;

    if (!customerId) {
      return res.status(400).json({ error: 'customerId is required' });
    }

    // Create Stripe billing portal session
    const session = await stripe.billingPortal.sessions.create({
      customer: customerId,
      return_url: returnUrl || 'https://your-app.com/subscription',
    });

    res.json({ url: session.url });
  } catch (error) {
    console.error('Error creating portal session:', error);
    res.status(500).json({ error: error.message });
  }
});
```

**Required Stripe Setup:**

1. Enable Stripe Customer Portal in Dashboard:
   - Go to https://dashboard.stripe.com/settings/billing/portal
   - Configure features you want to allow customers to manage
   - Set up allowed actions (update payment method, cancel subscription, etc.)

2. Required Stripe Package:
```bash
npm install stripe
```

3. Environment Variables:
```
STRIPE_SECRET_KEY=sk_test_xxxxxxxxxxxxx
```

## Flutter Implementation

The Flutter app calls this endpoint when the user clicks "Manage Subscription":

```dart
final portalUrl = await subscriptionService.createCustomerPortalSession(
  customerId: subscription.stripeCustomerId,
  returnUrl: 'immosync://subscription/management',
);

// Opens portal in external browser
await launchUrl(Uri.parse(portalUrl), mode: LaunchMode.externalApplication);
```

## Features Available in Customer Portal

- Update payment method
- View billing history
- Download invoices
- Cancel subscription
- Update subscription (upgrade/downgrade)

## Deep Linking

When the user completes their action in the portal, they're redirected back to the app via the `returnUrl`. 

**Android Setup (android/app/src/main/AndroidManifest.xml):**
```xml
<intent-filter>
    <action android:name="android.intent.action.VIEW" />
    <category android:name="android.intent.category.DEFAULT" />
    <category android:name="android.intent.category.BROWSABLE" />
    <data android:scheme="immosync" android:host="subscription" />
</intent-filter>
```

**iOS Setup (ios/Runner/Info.plist):**
```xml
<key>CFBundleURLTypes</key>
<array>
    <dict>
        <key>CFBundleURLSchemes</key>
        <array>
            <string>immosync</string>
        </array>
    </dict>
</array>
```

## Testing

1. Create a test subscription in Stripe Dashboard
2. Note the customer ID (cus_xxx)
3. Test the portal creation endpoint:
```bash
curl -X POST https://backend.immosync.ch/api/subscriptions/create-portal-session \
  -H "Authorization: Bearer YOUR_TOKEN" \
  -H "Content-Type: application/json" \
  -d '{"customerId": "cus_xxx", "returnUrl": "https://example.com"}'
```

4. Open the returned URL in browser to test the portal

## Security Notes

- Portal sessions expire after a few minutes
- Always validate the customer belongs to the authenticated user
- Use HTTPS for return URLs
- Implement rate limiting on the endpoint
