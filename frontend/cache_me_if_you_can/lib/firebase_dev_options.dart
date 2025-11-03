import 'package:firebase_core/firebase_core.dart';

/// Development fallback Firebase options used when the generated
/// firebase_options.dart is not present. Suitable for local emulator usage.
/// Do NOT ship to production.
class DevFirebaseOptions {
  static FirebaseOptions get currentPlatform {
    // Minimal options for Android. These values are acceptable for emulator
    // usage because emulators ignore credentials and project secrets.
    return const FirebaseOptions(
      apiKey: 'fake-api-key',
      appId: '1:1234567890:android:devapp',
      messagingSenderId: '1234567890',
      projectId: 'se-305-db',
    );
  }
}
