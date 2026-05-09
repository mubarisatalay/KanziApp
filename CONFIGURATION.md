# Configuration Guide

This guide explains how to configure the Kanzi App for development and production.

---

## 1. Supabase Configuration

### 1.1 Get Your Supabase Credentials

1. Go to [Supabase Dashboard](https://app.supabase.com)
2. Select your project (or create a new one)
3. Navigate to **Settings** → **API**
4. Copy the following values:
   - **Project URL** (e.g., `https://xxxxxxxxxxxxx.supabase.co`)
   - **anon public key** (safe to use in Flutter)

⚠️ **Important:** Never use the `service_role` key in your Flutter app! It bypasses all security rules.

### 1.2 Configure Flutter App

Create or edit the file: `lib/core/constants/supabase_constants.dart`

```dart
class SupabaseConstants {
  // Replace with your actual Supabase URL
  static const String supabaseUrl = 'https://xxxxxxxxxxxxx.supabase.co';
  
  // Replace with your actual anon key
  static const String supabaseAnonKey = 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...';
  
  // Storage bucket name
  static const String imagesBucket = 'challenge-images';
  
  // Edge Function URLs (optional)
  static const String generateChallengesUrl = '$supabaseUrl/functions/v1/generate-daily-challenges';
}
```

### 1.3 Alternative: Environment Variables (Optional)

For better security, you can use environment variables instead of hardcoding values.

#### Option A: Using --dart-define
```bash
flutter run \
  --dart-define=SUPABASE_URL=https://xxxxx.supabase.co \
  --dart-define=SUPABASE_ANON_KEY=your_anon_key
```

Then access in code:
```dart
class SupabaseConstants {
  static const String supabaseUrl = String.fromEnvironment(
    'SUPABASE_URL',
    defaultValue: 'https://xxxxx.supabase.co', // fallback for development
  );
  
  static const String supabaseAnonKey = String.fromEnvironment(
    'SUPABASE_ANON_KEY',
    defaultValue: 'your_anon_key',
  );
}
```

#### Option B: Using flutter_dotenv package
1. Add to `pubspec.yaml`:
```yaml
dependencies:
  flutter_dotenv: ^5.1.0
```

2. Create `.env` file (add to .gitignore!):
```env
SUPABASE_URL=https://xxxxx.supabase.co
SUPABASE_ANON_KEY=your_anon_key
```

3. Load in `main.dart`:
```dart
import 'package:flutter_dotenv/flutter_dotenv.dart';

void main() async {
  await dotenv.load(fileName: ".env");
  
  await Supabase.initialize(
    url: dotenv.env['SUPABASE_URL']!,
    anonKey: dotenv.env['SUPABASE_ANON_KEY']!,
  );
  
  runApp(MyApp());
}
```

---

## 2. Android Configuration

### 2.1 Update Package Name

Edit `android/app/build.gradle`:
```gradle
android {
    defaultConfig {
        applicationId "com.yourcompany.kanziapp"  // Change this
        minSdkVersion 21  // Minimum for Flutter
        targetSdkVersion 33
        versionCode 1
        versionName "1.0.0"
    }
}
```

### 2.2 Configure App Name

Edit `android/app/src/main/AndroidManifest.xml`:
```xml
<application
    android:label="Kanzi"
    android:icon="@mipmap/ic_launcher">
```

### 2.3 Internet Permission

Ensure this is in `AndroidManifest.xml` (should be there by default):
```xml
<uses-permission android:name="android.permission.INTERNET" />
<uses-permission android:name="android.permission.CAMERA" />
<uses-permission android:name="android.permission.READ_EXTERNAL_STORAGE" />
<uses-permission android:name="android.permission.WRITE_EXTERNAL_STORAGE" />
```

### 2.4 ProGuard Rules (for Release Builds)

Create `android/app/proguard-rules.pro`:
```proguard
# Supabase
-keep class io.supabase.** { *; }
-keep class com.google.gson.** { *; }
```

---

## 3. iOS Configuration

### 3.1 Update Bundle Identifier

Edit `ios/Runner.xcodeproj/project.pbxproj` or use Xcode:
1. Open `ios/Runner.xcworkspace` in Xcode
2. Select Runner project → General
3. Change **Bundle Identifier** to `com.yourcompany.kanziapp`

### 3.2 Configure App Name

Edit `ios/Runner/Info.plist`:
```xml
<key>CFBundleName</key>
<string>Kanzi</string>
<key>CFBundleDisplayName</key>
<string>Kanzi</string>
```

### 3.3 Camera & Photo Library Permissions

Edit `ios/Runner/Info.plist`:
```xml
<key>NSCameraUsageDescription</key>
<string>We need camera access to take challenge photos</string>
<key>NSPhotoLibraryUsageDescription</key>
<string>We need photo library access to select challenge photos</string>
<key>NSPhotoLibraryAddUsageDescription</key>
<string>We need permission to save photos to your library</string>
```

### 3.4 Minimum iOS Version

Edit `ios/Podfile`:
```ruby
platform :ios, '12.0'  # Minimum for Flutter
```

---

## 4. Firebase Configuration (Optional for Push Notifications)

### 4.1 Create Firebase Project

1. Go to [Firebase Console](https://console.firebase.google.com)
2. Create new project or add Firebase to existing project
3. Add Android app:
   - Package name: `com.yourcompany.kanziapp`
   - Download `google-services.json`
   - Place in `android/app/`
4. Add iOS app:
   - Bundle ID: `com.yourcompany.kanziapp`
   - Download `GoogleService-Info.plist`
   - Place in `ios/Runner/`

### 4.2 Install FlutterFire

```bash
dart pub global activate flutterfire_cli
flutterfire configure
```

### 4.3 Add to pubspec.yaml

```yaml
dependencies:
  firebase_core: ^2.15.0
  firebase_messaging: ^14.6.5
```

### 4.4 Initialize in main.dart

```dart
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Initialize Firebase
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  
  // Initialize Supabase
  await Supabase.initialize(...);
  
  runApp(MyApp());
}
```

---

## 5. App Icons & Splash Screen

### 5.1 Generate App Icons

1. Create 1024x1024 icon image
2. Add to `pubspec.yaml`:
```yaml
dev_dependencies:
  flutter_launcher_icons: ^0.13.1

flutter_launcher_icons:
  android: true
  ios: true
  image_path: "assets/icon/app_icon.png"
  adaptive_icon_background: "#FFFFFF"
  adaptive_icon_foreground: "assets/icon/app_icon.png"
```

3. Run:
```bash
flutter pub get
flutter pub run flutter_launcher_icons
```

### 5.2 Generate Splash Screen

1. Add to `pubspec.yaml`:
```yaml
dev_dependencies:
  flutter_native_splash: ^2.3.2

flutter_native_splash:
  color: "#FFFFFF"
  image: assets/splash/splash_logo.png
  android: true
  ios: true
```

2. Run:
```bash
flutter pub get
flutter pub run flutter_native_splash:create
```

---

## 6. Build Configuration

### 6.1 Development Build

```bash
# Debug mode (hot reload enabled)
flutter run

# Specify device
flutter run -d android
flutter run -d ios
```

### 6.2 Release Build

#### Android APK
```bash
flutter build apk --release
```

#### Android App Bundle (for Play Store)
```bash
flutter build appbundle --release
```

#### iOS (requires Xcode)
```bash
flutter build ios --release
```

Then open in Xcode:
```bash
open ios/Runner.xcworkspace
```
And archive for distribution.

### 6.3 Build with Custom Configuration

```bash
flutter build apk \
  --release \
  --dart-define=SUPABASE_URL=https://prod.supabase.co \
  --dart-define=SUPABASE_ANON_KEY=prod_key \
  --target-platform android-arm,android-arm64
```

---

## 7. Code Signing

### 7.1 Android

1. Create keystore:
```bash
keytool -genkey -v -keystore ~/kanzi-release-key.jks \
  -keyalg RSA -keysize 2048 -validity 10000 \
  -alias kanzi
```

2. Create `android/key.properties`:
```properties
storePassword=your_store_password
keyPassword=your_key_password
keyAlias=kanzi
storeFile=/Users/you/kanzi-release-key.jks
```

3. Edit `android/app/build.gradle`:
```gradle
def keystoreProperties = new Properties()
def keystorePropertiesFile = rootProject.file('key.properties')
if (keystorePropertiesFile.exists()) {
    keystoreProperties.load(new FileInputStream(keystorePropertiesFile))
}

android {
    signingConfigs {
        release {
            keyAlias keystoreProperties['keyAlias']
            keyPassword keystoreProperties['keyPassword']
            storeFile keystoreProperties['storeFile'] ? file(keystoreProperties['storeFile']) : null
            storePassword keystoreProperties['storePassword']
        }
    }
    buildTypes {
        release {
            signingConfig signingConfigs.release
        }
    }
}
```

### 7.2 iOS

1. Open `ios/Runner.xcworkspace` in Xcode
2. Select Runner → Signing & Capabilities
3. Select your Team
4. Xcode will automatically manage provisioning profiles

---

## 8. Environment-Specific Configuration

### 8.1 Create Multiple Flavors

For dev, staging, and production environments:

**Option 1: Using Flavors**

1. Update `android/app/build.gradle`:
```gradle
android {
    flavorDimensions "default"
    productFlavors {
        dev {
            dimension "default"
            applicationIdSuffix ".dev"
            versionNameSuffix "-dev"
        }
        prod {
            dimension "default"
        }
    }
}
```

2. Run with flavor:
```bash
flutter run --flavor dev
flutter build apk --flavor prod
```

**Option 2: Separate Config Files**

Create multiple config files:
- `lib/core/constants/supabase_constants_dev.dart`
- `lib/core/constants/supabase_constants_prod.dart`

Import based on environment:
```dart
import 'supabase_constants_dev.dart' if (dart.library.js) 'supabase_constants_prod.dart';
```

---

## 9. Testing Configuration

### 9.1 Mock Supabase for Tests

Create `test/mocks/mock_supabase_client.dart`:
```dart
import 'package:mockito/mockito.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class MockSupabaseClient extends Mock implements SupabaseClient {}
class MockGoTrueClient extends Mock implements GoTrueClient {}
class MockPostgrestClient extends Mock implements PostgrestClient {}
```

Generate mocks:
```bash
flutter pub run build_runner build
```

### 9.2 Test Configuration

```dart
void main() {
  setUpAll(() async {
    // Initialize Supabase for testing
    await Supabase.initialize(
      url: 'https://test.supabase.co',
      anonKey: 'test-key',
    );
  });
}
```

---

## 10. Security Checklist

- [ ] ✅ Supabase `anon` key is used (not `service_role`)
- [ ] ✅ `.env` file is added to `.gitignore`
- [ ] ✅ Keystore file is NOT committed to git
- [ ] ✅ `key.properties` is added to `.gitignore`
- [ ] ✅ Row Level Security (RLS) is enabled on all tables
- [ ] ✅ Storage policies are configured correctly
- [ ] ✅ API keys are not hardcoded in public repositories
- [ ] ✅ HTTPS is used for all network requests
- [ ] ✅ User input is validated on client and server

---

## 11. Common Issues & Solutions

### Issue: "Supabase not initialized"
**Solution:** Ensure `Supabase.initialize()` is called before `runApp()` in `main.dart`

### Issue: Build fails with "Execution failed for task ':app:processDebugGoogleServices'"
**Solution:** Ensure `google-services.json` is in `android/app/` directory

### Issue: iOS build fails with "No such module 'Supabase'"
**Solution:** Run `pod install` in `ios/` directory

### Issue: Image picker not working on iOS
**Solution:** Add camera/photo library permissions to `Info.plist`

### Issue: "RLS policy violation" errors
**Solution:** Check RLS policies in Supabase Dashboard and ensure user is authenticated

---

## Next Steps

After configuration:
1. Test authentication flow
2. Test room creation/joining
3. Test image upload
4. Test voting system
5. Deploy to TestFlight/Play Store Beta

For more help, see:
- [QUICKSTART.md](QUICKSTART.md) - Setup guide
- [ARCHITECTURE.md](ARCHITECTURE.md) - Code structure
- [MVP_DESIGN.md](MVP_DESIGN.md) - Product specification
