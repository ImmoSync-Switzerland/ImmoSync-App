# GitHub Actions Secrets Setup

This document lists all required GitHub Secrets for the CI/CD pipeline.

## Required Secrets

Go to: `Settings` → `Secrets and variables` → `Actions` → `New repository secret`

### 1. API Configuration

- **`CLIENT_API_URL`**
  - Description: Backend API URL
  - Example: `https://backend.immosync.ch/api`

### 2. Firebase/Google Services

- **`GOOGLE_SERVICES_JSON_B64`** (Recommended) OR **`GOOGLE_SERVICES_JSON`**
  - Description: Android google-services.json file for Firebase
  - How to get:
    1. Go to [Firebase Console](https://console.firebase.google.com/)
    2. Select your project
    3. Go to Project Settings → General
    4. Under "Your apps", find your Android app
    5. Download `google-services.json`
    6. For B64 version: `base64 -w 0 google-services.json` (Linux/Mac) or `[Convert]::ToBase64String([IO.File]::ReadAllBytes("google-services.json"))` (PowerShell)
  - ⚠️ **Important**: Must be the Android `google-services.json`, NOT `firebase.json`!

### 3. Payment Integration

- **`STRIPE_PUBLISHABLE_KEY`**
  - Description: Stripe publishable API key
  - Format: `pk_live_...` or `pk_test_...`
  - Get from: [Stripe Dashboard](https://dashboard.stripe.com/apikeys)

### 4. Google OAuth

- **`GOOGLE_CLIENT_ID`**
  - Description: Google OAuth 2.0 Client ID
  - Format: `xxxxx.apps.googleusercontent.com`
  - Get from: [Google Cloud Console](https://console.cloud.google.com/apis/credentials)

### 5. Database (Optional - for mobile/desktop direct access)

- **`MONGODB_URI`** (Optional)
  - Description: MongoDB connection string
  - Example: `mongodb+srv://user:pass@cluster.mongodb.net`

- **`MONGODB_DB_NAME`** (Optional)
  - Description: MongoDB database name
  - Example: `immolink_db`

### 6. WebSocket (Optional)

- **`WS_URL`** (Optional)
  - Description: WebSocket server URL
  - Example: `wss://backend.immosync.ch`
  - Note: Auto-derived from API_URL if not provided

### 7. Site Repository Publishing (Optional)

- **`SITE_REPO_PAT`** (Optional)
  - Description: Personal Access Token for publishing to immosync.ch repository
  - Required permissions: `repo` (full control)
  - Get from: GitHub Settings → Developer settings → Personal access tokens → Fine-grained tokens

## Verification

After adding all secrets, trigger a workflow run:
1. Go to `Actions` tab
2. Select "Android APK CI"
3. Click "Run workflow"
4. Select branch: `main`
5. Click "Run workflow"

## Troubleshooting

### Missing Secret Errors
If you see `Missing required secret: X`, add that secret to your repository.

### Invalid google-services.json
Error: `google-services.json missing expected JSON key "project_number"`

**Solution**: Make sure you downloaded the **Android** `google-services.json` file (not `firebase.json` or iOS `GoogleService-Info.plist`).

The file should look like:
```json
{
  "project_info": {
    "project_number": "123456789",
    ...
  },
  "client": [
    {
      "client_info": {
        "mobilesdk_app_id": "1:123456789:android:...",
        ...
      }
    }
  ]
}
```

### .env Asset Missing
The `.env` file is automatically created during CI from the secrets above. No action needed.
