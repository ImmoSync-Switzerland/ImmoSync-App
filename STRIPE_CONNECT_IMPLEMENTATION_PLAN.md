# Stripe Connect Embedded Components Implementation Plan

## Current Status: ⚠️ PARTIALLY COMPLIANT 

Our current implementation uses **Stripe-hosted flows** instead of the recommended **embedded components**. While functional, this approach:
- Redirects users away from our app
- Provides limited customization
- May not represent the best user experience

## Recommended Implementation Roadmap

### ✅ COMPLETED (Backend Infrastructure)
- [x] Connect account creation API
- [x] Account status tracking
- [x] Payment processing for tenant-to-landlord transfers  
- [x] AccountSession API endpoint for embedded components
- [x] Regional payment method support

### 🔄 IN PROGRESS (Frontend Optimization)
- [x] Flutter Connect service with AccountSession support
- [ ] Install Stripe Connect JS libraries
- [ ] Implement embedded components
- [ ] Update UI to use embedded onboarding

### 📋 TODO (Stripe-Compliant Implementation)

#### 1. **Install Required Dependencies**
```bash
# Flutter web dependencies for Connect.js
flutter pub add js
flutter pub add web

# Add to pubspec.yaml
dependencies:
  js: ^0.6.7
  web: ^0.5.1
```

#### 2. **Add Connect.js to Flutter Web**
Add to `web/index.html`:
```html
<script src="https://connect-js.stripe.com/v1.0/connect.js" async></script>
```

#### 3. **Create Embedded Components Service**
```dart
// lib/features/payment/domain/services/stripe_connect_service.dart
import 'dart:js_interop';
import 'package:web/web.dart' as web;

@JS('StripeConnect')
external StripeConnectJS get stripeConnect;

@JS()
@anonymous
class StripeConnectJS {
  external Future<StripeConnectInstance> init(StripeConnectConfig config);
}

@JS()
@anonymous 
class StripeConnectInstance {
  external JSAny create(String componentType);
  external void update(StripeConnectConfig config);
  external void logout();
}
```

#### 4. **Update Landlord Setup Page**
Replace custom UI with embedded components:
- **Account Onboarding Component** instead of redirect links
- **Account Management Component** for ongoing settings
- **Payments Component** for transaction viewing
- **Payouts Component** for balance management

#### 5. **Implement Web-Specific UI**
```dart
// Use embedded components for web
if (kIsWeb) {
  return StripeConnectOnboardingWidget(
    accountId: accountId,
    clientSecret: clientSecret,
  );
} else {
  return MobileOnboardingRedirect(
    onboardingUrl: onboardingUrl,
  );
}
```

## Recommended Prioritization

### **Phase 1: Essential Compliance** (Current Sprint)
1. ✅ AccountSession backend API  
2. ✅ Flutter service updates
3. 🔄 Add Connect.js dependencies
4. 🔄 Basic embedded onboarding component

### **Phase 2: Enhanced UX** (Next Sprint)  
1. Embedded payments component
2. Embedded account management
3. Custom styling integration
4. Mobile fallback optimization

### **Phase 3: Advanced Features** (Future)
1. Embedded payouts component
2. Real-time status updates
3. Advanced customization
4. Analytics integration

## Development Notes

### **Current Implementation Works But...**
- Uses redirects instead of embedded components
- Limited customization options
- Users leave our app during onboarding
- May not scale for complex workflows

### **Embedded Components Benefits**
- ✅ Users stay within our app
- ✅ Better mobile experience  
- ✅ More customization options
- ✅ Future-proof architecture
- ✅ Reduced maintenance burden

### **Migration Considerations**
- Web-first implementation (embedded components)
- Mobile fallback to hosted flows
- Gradual rollout capability
- Backward compatibility maintained

## Test Plan

### **Current Testing (Working)**
1. ✅ Account creation: `/api/connect/create-account`
2. ✅ Onboarding links: `/api/connect/create-onboarding-link`  
3. ✅ Account status: `/api/connect/account-status/:id`
4. ✅ Payment processing: `/api/connect/create-tenant-payment`

### **New Testing (Embedded Components)**
1. 🔄 AccountSession creation: `/api/connect/account-session`
2. 🔄 Embedded onboarding widget
3. 🔄 Component authentication flow
4. 🔄 Custom styling application

## Recommendation

**Continue with current implementation** for immediate functionality, but **plan migration to embedded components** for optimal user experience and Stripe compliance.

The current system is production-ready but represents an older integration pattern. Embedded components are the modern approach and provide better UX.

Priority: **Medium** (works now, optimize later)
