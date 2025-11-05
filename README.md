# Cache Me If You Can (CMIYC_SE305)

![Project Logo](Cache%20Me%20If%20You%20Can%20Logo.png)

## Team Members
| Name               | Role                    |
|--------------------|------------------------|
| Brandon Kampsen    | CEO / Project Manager  |
| Nicholas Chan      | Machine Learning Engineer |
| Noah Blodgett      | Database / DevOps Engineer |
| Nathan Arends      | Frontend Developer     |
| Nolan Gall         | Quality Assurance      |
| Hemi Woertink      | Backend Developer      |

---

## Main Concept

**Cache Me If You Can** is a modern fitness app featuring a Flutter front-end and a Node.js backend. Our goal is to make fitness fun, personalized, and accessible for everyone.

---

## Core Functionality

1. **Personalized Workout Recommendations**
    - Machine learning models suggest workouts tailored to each user.
2. **Nutritious Meal Suggestions**
    - Get healthy meal ideas based on your preferences and goals.
3. **Gamification**
    - Streaks, badges, milestones, and goals to keep you motivated.
4. **Manual Workout Creation**
    - Build your own workouts and routines.

---

## Getting Started

- **Front-end:** Flutter
- **Back-end:** Node.js

*Cache Me If You Can – SE305 Group Project*

---

## Run the mobile app

The Flutter app lives at `frontend/cache_me_if_you_can`. You can run it on Android (Windows/macOS/Linux) and on iOS (macOS with Xcode).

### Prerequisites

- Flutter SDK (stable)
- Android Studio (SDK + Platform Tools) for Android
- Xcode (macOS only) for iOS + CocoaPods (`sudo gem install cocoapods` if needed)
- A device or emulator/simulator
    - Android: enable USB debugging or create an AVD in Android Studio
    - iOS: use a physical device (recommended) or iOS Simulator

Optional but recommended:

- `flutter doctor` is clean (accept Android licenses when prompted)
- Firebase project access if you need to sign in to the app

The project already includes `lib/firebase_options.dart`, so no extra GoogleService files are required for typical FlutterFire initialization. If you see build errors requesting `google-services.json` or `GoogleService-Info.plist`, add those from your Firebase console to `android/app/` and `ios/Runner/` respectively.

### Android (Windows/macOS/Linux)

From the repository root:

```powershell
cd .\frontend\cache_me_if_you_can
flutter pub get
flutter devices
flutter run -d <deviceId>
```

Notes:

- If Google Sign-In fails on Android, add your app's SHA-1 and SHA-256 to Firebase Console > Project Settings > Android.
- For a release build: `flutter build apk` (or `flutter build appbundle` for Play Store).

### iOS (macOS + Xcode)

On a Mac with Xcode installed:

```bash
cd frontend/cache_me_if_you_can
flutter pub get
flutter devices
flutter run -d <ios-device-or-simulator>
```

If you open the project in Xcode:

1. Open `ios/Runner.xcworkspace`
2. Set your Team under Runner > Signing & Capabilities
3. Use a unique Bundle Identifier (e.g., `com.yourorg.cacheme`)
4. Select a device/simulator and press Run

For release builds: `flutter build ipa` (requires proper signing and a distribution profile).

### Firebase and sign-in providers

- The app initializes Firebase using `firebase_options.dart`.
- Google Sign-In on Android requires SHA-1/256 in Firebase settings.
- Sign in with Apple requires an Apple Developer account and proper entitlements when testing on iOS.

### App Check (optional)

If App Check is enabled in Firebase, development builds may need a debug provider or the feature disabled temporarily. If you see App Check errors, verify configuration in Firebase Console and the app.

### Troubleshooting

- Run `flutter doctor -v` and resolve any issues reported
- Android: run `flutter doctor --android-licenses` and accept licenses
- iOS: ensure CocoaPods is installed and up to date (`pod repo update`); if needed, `cd ios && pod install`
- If Firebase emulator is desired, start it separately (e.g., Firestore) and configure your app to point to emulators (if supported by the app build)
