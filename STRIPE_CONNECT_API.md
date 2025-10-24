# Stripe Connect API Documentation

## Overview
The Stripe Connect integration enables landlords to receive payments directly from tenants through Stripe. This implementation uses **Stripe Connect Express** accounts with automatic payment method detection and multi-currency support.

## Architecture

### Payment Flow
```
Tenant → Create Payment Intent → Stripe Checkout → Confirm Payment → Landlord Account
```

### Account Setup Flow
```
Landlord → Create Connect Account → Complete Onboarding → Activate Account → Receive Payments
```

## API Endpoints

Base URL: `https://backend.immosync.ch/api/connect`

### Account Management

#### 1. Create Connect Account
Creates a Stripe Connect Express account for a landlord.

**Endpoint:** `POST /connect/create-account`

**Request Body:**
```json
{
  "landlordId": "string (required)",
  "email": "string (required)",
  "businessType": "individual | company (optional, default: individual)"
}
```

**Response (200):**
```json
{
  "accountId": "acct_xxx",
  "status": "pending",
  "message": "Connect account created successfully"
}
```

**Errors:**
- `400` - Missing required fields
- `404` - Landlord not found
- `500` - Server error

---

#### 2. Get Connect Account
Retrieves account details for a landlord.

**Endpoint:** `GET /connect/account/:landlordId`

**Response (200):**
```json
{
  "accountId": "acct_xxx",
  "country": "CH",
  "currency": "chf",
  "email": "landlord@example.com",
  "type": "express",
  "chargesEnabled": true,
  "payoutsEnabled": true,
  "detailsSubmitted": true,
  "capabilities": {
    "cardPayments": "active",
    "transfers": "active",
    "bankTransfers": "active"
  },
  "metadata": {}
}
```

---

#### 3. Create Onboarding Link
Generates a Stripe onboarding URL for account setup.

**Endpoint:** `POST /connect/create-onboarding-link`

**Request Body:**
```json
{
  "accountId": "acct_xxx (required)",
  "refreshUrl": "string (optional)",
  "returnUrl": "string (optional)"
}
```

**Response (200):**
```json
{
  "url": "https://connect.stripe.com/setup/...",
  "expires_at": 1234567890
}
```

---

#### 4. Check Onboarding Status
Checks if landlord has completed onboarding.

**Endpoint:** `GET /connect/onboarding-complete/:landlordId`

**Response (200):**
```json
{
  "isComplete": true,
  "accountId": "acct_xxx",
  "chargesEnabled": true,
  "payoutsEnabled": true,
  "detailsSubmitted": true
}
```

---

#### 5. Get Account Status
Gets comprehensive account status for a landlord.

**Endpoint:** `GET /connect/account-status/:landlordId`

**Response (200):**
```json
{
  "hasAccount": true,
  "accountId": "acct_xxx",
  "status": "complete | pending",
  "chargesEnabled": true,
  "detailsSubmitted": true,
  "payoutsEnabled": true
}
```

---

### Payment Operations

#### 6. Create Tenant Payment
Creates a payment intent for tenant to pay landlord.

**Endpoint:** `POST /connect/create-tenant-payment`

**Request Body:**
```json
{
  "tenantId": "string (required)",
  "propertyId": "string (required)",
  "amount": 1500.00 (required, in CHF),
  "currency": "chf (optional, default: chf)",
  "paymentType": "rent | deposit | maintenance (optional, default: rent)",
  "description": "string (optional)",
  "preferredPaymentMethod": "card | sofort | ideal | sepa_debit | bank_transfer (optional)"
}
```

**Response (200):**
```json
{
  "clientSecret": "pi_xxx_secret_xxx",
  "paymentIntentId": "pi_xxx",
  "applicationFee": 43.50
}
```

**Notes:**
- Application fee: 2.9% + CHF 0.30
- Automatic payment method detection with fallback
- Supports destination charges (funds go directly to landlord)

---

#### 7. Confirm Payment
Confirms payment after successful Stripe checkout.

**Endpoint:** `POST /connect/confirm-payment`

**Request Body:**
```json
{
  "paymentIntentId": "pi_xxx (required)",
  "status": "completed (optional)"
}
```

**Response (200):**
```json
{
  "success": true,
  "status": "completed",
  "paymentIntentId": "pi_xxx"
}
```

---

#### 8. Get Landlord Payments
Retrieves payment history for a landlord.

**Endpoint:** `GET /connect/landlord-payments/:landlordId?limit=50`

**Query Parameters:**
- `limit` - Number of records (default: 50)

**Response (200):**
```json
[
  {
    "_id": "xxx",
    "stripePaymentIntentId": "pi_xxx",
    "tenantId": "xxx",
    "propertyId": "xxx",
    "landlordId": "xxx",
    "amount": 1500.00,
    "currency": "chf",
    "type": "rent",
    "status": "completed",
    "applicationFee": 43.50,
    "description": "Rent payment",
    "createdAt": "2025-01-15T10:30:00Z",
    "completedAt": "2025-01-15T10:32:00Z",
    "updatedAt": "2025-01-15T10:32:00Z"
  }
]
```

---

#### 9. Get Tenant Payments
Retrieves payment history for a tenant.

**Endpoint:** `GET /connect/tenant-payments/:tenantId?limit=50`

**Response:** Same as landlord payments

---

### Financial Operations

#### 10. Get Account Balance
Retrieves available and pending balance for landlord.

**Endpoint:** `GET /connect/balance/:landlordId`

**Response (200):**
```json
{
  "available": 2450.50,
  "pending": 1500.00,
  "currency": "chf",
  "lastUpdated": "2025-01-15T12:00:00Z"
}
```

---

#### 11. Get Balance Transactions
Retrieves balance transaction history.

**Endpoint:** `GET /connect/balance-transactions/:landlordId?limit=20`

**Response (200):**
```json
[
  {
    "id": "txn_xxx",
    "amount": 1500.00,
    "currency": "chf",
    "type": "payment",
    "description": "Rent payment",
    "fee": 43.50,
    "net": 1456.50,
    "status": "available",
    "availableOn": "2025-01-17T00:00:00Z",
    "created": "2025-01-15T10:32:00Z"
  }
]
```

---

#### 12. Get Payouts
Retrieves payout history for landlord.

**Endpoint:** `GET /connect/payouts/:landlordId?limit=20`

**Response (200):**
```json
[
  {
    "id": "po_xxx",
    "amount": 2450.50,
    "currency": "chf",
    "status": "paid",
    "description": "Payout to bank account",
    "arrivalDate": "2025-01-20T00:00:00Z",
    "created": "2025-01-18T08:00:00Z",
    "method": "standard",
    "type": "bank_account"
  }
]
```

---

#### 13. Create Payout
Creates a payout to landlord's bank account.

**Endpoint:** `POST /connect/create-payout`

**Request Body:**
```json
{
  "landlordId": "string (required)",
  "amount": 2450.50 (required),
  "currency": "chf (optional, default: chf)",
  "description": "string (optional)"
}
```

**Response (200):**
```json
{
  "payoutId": "po_xxx",
  "amount": 2450.50,
  "currency": "chf",
  "status": "pending",
  "arrivalDate": "2025-01-20T00:00:00Z",
  "created": "2025-01-18T08:00:00Z"
}
```

**Errors:**
- `400` - Insufficient balance or invalid amount
- `404` - Connect account not found

---

#### 14. Create Refund
Issues a refund for a payment.

**Endpoint:** `POST /connect/create-refund`

**Request Body:**
```json
{
  "paymentIntentId": "pi_xxx (required)",
  "amount": 1500.00 (optional, full refund if omitted),
  "reason": "requested_by_customer | duplicate | fraudulent (optional)"
}
```

**Response (200):**
```json
{
  "refundId": "re_xxx",
  "amount": 1500.00,
  "currency": "chf",
  "status": "succeeded",
  "reason": "requested_by_customer",
  "created": "2025-01-16T09:15:00Z"
}
```

---

### Payment Methods

#### 15. Get Available Payment Methods
Retrieves available payment methods for a country.

**Endpoint:** `GET /connect/payment-methods/:countryCode`

**Example:** `GET /connect/payment-methods/CH`

**Response (200):**
```json
[
  {
    "type": "card",
    "name": "Credit/Debit Card",
    "icon": "credit_card",
    "instant": true
  },
  {
    "type": "bank_transfer",
    "name": "Bank Transfer",
    "icon": "account_balance",
    "instant": false,
    "description": "Takes 1-3 business days"
  },
  {
    "type": "sofort",
    "name": "Sofort",
    "icon": "flash_on",
    "instant": true,
    "description": "Instant bank payment"
  }
]
```

**Supported Countries:**
- `CH` - Switzerland (card, bank_transfer, sofort)
- `DE` - Germany (card, sepa_debit, sofort)
- `NL` - Netherlands (card, ideal, sepa_debit)
- Default - (card, bank_transfer)

---

## Webhooks

### Webhook Endpoint
Stripe sends events to: `POST /connect/webhook`

**Supported Events:**
- `payment_intent.succeeded` - Payment completed successfully
- `payment_intent.payment_failed` - Payment failed
- `account.updated` - Connect account status changed

**Webhook Signature:** Verified using `STRIPE_WEBHOOK_SECRET`

**Event Handling:**
- Updates payment status in database
- Updates landlord account status
- Triggers notifications (future)

---

## Environment Variables

Required in backend `.env`:

```env
STRIPE_SECRET_KEY=sk_test_xxx
STRIPE_WEBHOOK_SECRET=whsec_xxx
APP_URL=https://immosync.ch
```

---

## Database Schema

### `payments` Collection
```javascript
{
  _id: ObjectId,
  stripePaymentIntentId: String,
  tenantId: String,
  propertyId: String,
  landlordId: String,
  amount: Number,
  currency: String,
  type: String, // 'rent', 'deposit', 'maintenance'
  status: String, // 'pending', 'completed', 'failed', 'refunded'
  applicationFee: Number,
  description: String,
  paymentMethod: String,
  refundId: String, // if refunded
  refundAmount: Number,
  refundReason: String,
  createdAt: Date,
  completedAt: Date,
  refundedAt: Date,
  updatedAt: Date
}
```

### `users` Collection (Landlord Fields)
```javascript
{
  _id: ObjectId,
  stripeConnectAccountId: String,
  connectAccountStatus: String, // 'pending', 'active'
  connectAccountDetails: {
    chargesEnabled: Boolean,
    payoutsEnabled: Boolean,
    country: String,
    updatedAt: Date
  },
  currency: String, // default 'chf'
  // ... other user fields
}
```

---

## Testing

### Test Cards
- **Success:** `4242 4242 4242 4242`
- **Declined:** `4000 0000 0000 0002`
- **3D Secure:** `4000 0027 6000 3184`

### Test Mode
All endpoints work with Stripe test keys (`sk_test_*`). Use test cards for payments.

### Webhooks
Test webhooks using Stripe CLI:
```bash
stripe listen --forward-to localhost:3000/api/connect/webhook
stripe trigger payment_intent.succeeded
```

---

## Error Handling

All endpoints return consistent error responses:

```json
{
  "message": "Error description",
  "code": "error_code (optional)",
  "details": {} // optional additional info
}
```

**Common HTTP Codes:**
- `200` - Success
- `201` - Created
- `400` - Bad request / validation error
- `404` - Resource not found
- `500` - Server error

---

## Security

1. **API Authentication:** All endpoints should use JWT authentication (implement via middleware)
2. **Webhook Verification:** Stripe signature validation prevents unauthorized events
3. **Account Isolation:** Landlords can only access their own accounts/payments
4. **PCI Compliance:** Payment card data never touches the server (handled by Stripe.js)

---

## Rate Limits

Stripe API limits:
- Test mode: 25 requests/second
- Live mode: 100 requests/second

Implement rate limiting on backend endpoints as needed.

---

## Next Steps

1. ✅ Backend API implemented
2. ✅ Flutter service layer implemented
3. ✅ Riverpod providers implemented
4. ✅ Example UI widget created
5. ⏳ Add JWT authentication middleware
6. ⏳ Implement tenant payment UI with Stripe Elements
7. ⏳ Add webhook notifications (push notifications)
8. ⏳ Create landlord balance dashboard
9. ⏳ Add payout request UI
10. ⏳ Implement proper error handling in UI
11. ⏳ Add payment receipt generation
12. ⏳ Setup production Stripe account
13. ⏳ Configure production webhook endpoint

---

## Support

For Stripe-specific issues, consult:
- [Stripe Connect Docs](https://stripe.com/docs/connect)
- [Stripe API Reference](https://stripe.com/docs/api)
- [Stripe Testing Guide](https://stripe.com/docs/testing)
