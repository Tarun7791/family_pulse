# Setup Guide

This guide will help you set up Family Pulse from scratch.

## Prerequisites

### Required Software
- **Flutter SDK**: Version 3.10.3 or higher
  - Download from: https://flutter.dev/docs/get-started/install
  - Verify: `flutter --version`
  
- **Android Studio** or **VS Code**
  - Android Studio: https://developer.android.com/studio
  - VS Code: https://code.visualstudio.com/ (with Flutter extension)

- **Git**: For cloning the repository
  - Download from: https://git-scm.com/downloads

### Firebase Account
- Create a free account at https://firebase.google.com

## Step-by-Step Setup

### 1. Clone the Repository
```bash
git clone https://github.com/yourusername/family_pulse.git
cd family_pulse
```

### 2. Install Flutter Dependencies
```bash
flutter pub get
```

### 3. Firebase Configuration

#### 3.1 Create Firebase Project
1. Go to [Firebase Console](https://console.firebase.google.com)
2. Click "Add Project"
3. Enter project name: "Family Pulse"
4. Disable Google Analytics (optional)
5. Click "Create Project"

#### 3.2 Add Android App
1. In Firebase Console, click "Add app" → Android icon
2. Enter package name: `com.family.screentime.family_screen_time`
3. Download `google-services.json`
4. Place it in: `android/app/google-services.json`

#### 3.3 Enable Authentication
1. In Firebase Console → Authentication
2. Click "Get Started"
3. Enable "Email/Password" sign-in method
4. Click "Save"

#### 3.4 Enable Firestore
1. In Firebase Console → Firestore Database
2. Click "Create Database"
3. Start in **Test Mode** (we'll secure it later)
4. Choose a location (e.g., us-central)
5. Click "Enable"

#### 3.5 Deploy Security Rules
1. Open `firestore.rules` in your project
2. Copy all contents
3. In Firebase Console → Firestore → Rules tab
4. Paste the rules
5. Click "Publish"

### 4. Build the App

#### Debug Build (for testing)
```bash
flutter run
```

#### Release Build (for distribution)
```bash
flutter build apk --release
```

The APK will be at: `build/app/outputs/flutter-apk/app-release.apk`

### 5. Install on Device

#### Via USB
1. Enable Developer Options on your Android device
2. Enable USB Debugging
3. Connect device via USB
4. Run: `flutter install`

#### Via APK Transfer
1. Copy `app-release.apk` to your device
2. Open the file on your device
3. Allow installation from unknown sources if prompted
4. Install the app

## First-Time Usage

### Parent Setup
1. Open the app
2. Click "SIGN UP"
3. Enter name, email, password
4. Select "Parent" role
5. Click "CREATE ACCOUNT"
6. Click "CREATE NEW FAMILY"
7. Enter family name (e.g., "Smith Family")
8. Note the 6-digit join code

### Child Setup
1. Open the app on child's device
2. Click "SIGN UP"
3. Enter name, email, password
4. Select "Child" role
5. Click "CREATE ACCOUNT"
6. Click "JOIN EXISTING FAMILY"
7. Enter the 6-digit code from parent
8. Grant "Usage Access" permission when prompted

## Troubleshooting

### Build Errors

**Error: "google-services.json not found"**
- Solution: Download from Firebase Console and place in `android/app/`

**Error: "Execution failed for task ':app:processDebugGoogleServices'"**
- Solution: Ensure package name in `google-services.json` matches `android/app/build.gradle`

**Error: "Gradle build daemon disappeared"**
- Solution: Run `flutter clean` then rebuild

### Runtime Errors

**Error: "Usage Access permission denied"**
- Solution: Go to Settings → Apps → Special Access → Usage Access → Enable for Family Pulse

**Error: "No family found"**
- Solution: Ensure join code is correct and family exists in Firestore

**Error: "Screen time shows 0 minutes"**
- Solution: Use some apps, wait 10 minutes for sync, or manually refresh

### Firebase Errors

**Error: "Firestore permission denied"**
- Solution: Ensure security rules are deployed correctly

**Error: "Authentication failed"**
- Solution: Check if Email/Password is enabled in Firebase Console

## Development Tips

### Hot Reload
While developing, use hot reload for instant updates:
- Press `r` in terminal
- Or click ⚡ in VS Code/Android Studio

### Debugging
View logs in real-time:
```bash
flutter logs
```

### Code Formatting
Format code before committing:
```bash
flutter format .
```

### Analyze Code
Check for issues:
```bash
flutter analyze
```

## Production Deployment

### Generate Signed APK
1. Create keystore:
```bash
keytool -genkey -v -keystore family-pulse-key.jks -keyalg RSA -keysize 2048 -validity 10000 -alias family-pulse
```

2. Create `android/key.properties`:
```properties
storePassword=your_store_password
keyPassword=your_key_password
keyAlias=family-pulse
storeFile=../family-pulse-key.jks
```

3. Build signed APK:
```bash
flutter build apk --release
```

### Upgrade Firestore Plan
For production use with many families:
1. Go to Firebase Console → Upgrade
2. Choose "Blaze" (pay-as-you-go)
3. Set budget alerts

## Environment Variables

For different environments (dev/prod), create:

**lib/config/dev_config.dart**
```dart
class Config {
  static const String apiUrl = 'https://dev-api.example.com';
  static const bool enableLogging = true;
}
```

**lib/config/prod_config.dart**
```dart
class Config {
  static const String apiUrl = 'https://api.example.com';
  static const bool enableLogging = false;
}
```

## Support

For issues or questions:
- Open an issue on GitHub
- Email: [your-email@example.com]
- Documentation: See `ARCHITECTURE.md` for technical details

---

**Ready to go!** 🚀 Your Family Pulse app should now be fully functional.
