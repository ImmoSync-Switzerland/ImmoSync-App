# Social Login Setup Guide

This document explains how to configure Google and Apple login for the ImmoLink application.

## Backend Setup

1. **Create Backend Configuration**
   ```bash
   cd backend
   cp config.example.js config.js
   ```

2. **Install Dependencies**
   ```bash
   npm install
   ```

3. **Firebase Admin Setup**
   - The backend requires Firebase Admin SDK for token verification
   - In development, it uses default project settings
   - In production, configure Firebase Admin with service account credentials

## Frontend Setup

1. **Install Flutter Dependencies**
   ```bash
   cd immolink
   flutter pub get
   ```

2. **Dependencies Added**
   - `google_sign_in: ^6.2.1` - Google Sign-In functionality
   - `sign_in_with_apple: ^6.1.3` - Apple Sign-In functionality
   - `firebase_auth: ^5.4.2` - Firebase authentication (already present)

## Firebase Project Configuration

For production use, you'll need to:

1. **Create a Firebase Project**
   - Go to [Firebase Console](https://console.firebase.google.com/)
   - Create a new project or use existing one

2. **Configure Authentication Providers**
   - Enable Google Sign-In in Firebase Auth
   - Enable Apple Sign-In in Firebase Auth
   - Configure OAuth redirect URIs

3. **Download Configuration Files**
   - `google-services.json` for Android (place in `android/app/`)
   - `GoogleService-Info.plist` for iOS (place in `ios/Runner/`)

4. **Backend Firebase Admin**
   - Generate service account key from Firebase Console
   - Set `GOOGLE_APPLICATION_CREDENTIALS` environment variable
   - Or configure programmatically in production

## Platform-Specific Setup

### iOS (Sign in with Apple)
- Enable "Sign In with Apple" capability in Xcode
- Configure App ID in Apple Developer Portal
- Add Apple as authentication provider in Firebase

### Android (Google Sign-In)
- Add `google-services.json` to `android/app/`
- Configure OAuth2 client in Google Cloud Console
- Ensure SHA certificates are configured

## Testing

The implementation includes:
- ✅ UI buttons connected to authentication methods
- ✅ Firebase Auth integration for social login
- ✅ Backend endpoint for token verification
- ✅ Error handling and user feedback
- ✅ Consistent user data structure

## API Endpoints

- `POST /api/auth/social-login` - Verify Firebase token and create/login user

## Error Handling

The application handles:
- Cancelled login attempts
- Firebase authentication failures
- Backend token verification errors
- Network connectivity issues