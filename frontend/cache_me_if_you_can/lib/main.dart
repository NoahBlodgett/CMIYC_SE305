import 'dart:io' show Platform;
import 'dart:ui' as ui;
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:firebase_app_check/firebase_app_check.dart';
import 'styles/styles.dart';
import 'package:cache_me_if_you_can/core/navigation/app_router.dart';
import 'firebase_options.dart';

import 'features/auth/presentation/pages/pages.dart';
import 'features/home/presentation/pages/pages.dart';
import 'features/onboarding/presentation/pages/pages.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  // Global error handlers to capture uncaught exceptions early in startup
  FlutterError.onError = (FlutterErrorDetails details) {
    FlutterError.dumpErrorToConsole(details);
  };
  ui.PlatformDispatcher.instance.onError = (error, stack) {
    debugPrint('UNCAUGHT (platformDispatcher): $error');
    debugPrintStack(stackTrace: stack);
    return true; // handled -> prevents silent engine kill
  };
  assert(() {
    // Simple timestamp markers to diagnose startup latency in debug builds.
    final start = DateTime.now();
    debugPrint('[StartupTrace] main() started at $start');
    return true;
  }());

  // Try to initialize Firebase. If platform hasn't been configured yet
  // (for example Windows desktop before you run `flutterfire configure`),
  // catch the exception and show a helpful error UI instead of crashing.
  try {
    // Resolve Firebase options; if the generated options are missing, use a
    // dev fallback suitable for emulators.
    FirebaseOptions? options;
    try {
      options = DefaultFirebaseOptions.currentPlatform;
    } catch (_) {
      options = null;
    }

    await Firebase.initializeApp(options: options);

    // Optionally enable Firebase App Check. You can disable it during local
    // development with: --dart-define=APP_CHECK_ENABLED=false
    const appCheckEnabled = bool.fromEnvironment(
      'APP_CHECK_ENABLED',
      defaultValue: true,
    );
    if (appCheckEnabled) {
      try {
        // Enable Firebase App Check to remove warnings and harden API calls.
        // Use debug providers in debug builds; use real providers in release.
        await FirebaseAppCheck.instance.activate(
          // ignore: deprecated_member_use
          androidProvider: kDebugMode
              ? AndroidProvider.debug
              : AndroidProvider.playIntegrity,
          // ignore: deprecated_member_use
          appleProvider: kDebugMode
              ? AppleProvider.debug
              : AppleProvider.appAttest,
        );
      } catch (e) {
        if (kDebugMode) {
          debugPrint('App Check activation skipped due to error: $e');
        }
      }
    } else {
      if (kDebugMode) {
        debugPrint('App Check disabled via APP_CHECK_ENABLED=false');
      }
    }

    // For development, sign in anonymously so currentUser is available.
    // Default to NOT using emulators unless explicitly enabled.
    // On physical devices, emulator hosts like 10.0.2.2/localhost are unreachable
    // and can cause long startup delays waiting on network timeouts.
    const useEmulators = bool.fromEnvironment(
      'USE_EMULATORS',
      defaultValue: false,
    );
    if (kDebugMode && useEmulators) {
      try {
        // Point to local emulators in debug/dev to avoid hitting prod
        await _useFirebaseEmulators();
        // Don't block app startup on debug sign-in; fire-and-forget to avoid delays
        // if the emulator host isn't reachable from a physical device.
        // ignore: discarded_futures
        FirebaseAuth.instance.signInAnonymously();
      } catch (_) {
        // ignore errors in debug sign-in
      }
    }

    runApp(const MyApp());
    assert(() {
      debugPrint('[StartupTrace] runApp(MyApp) invoked at ${DateTime.now()}');
      return true;
    }());
  } catch (e) {
    // In development, continue without Firebase and let widgets use mock fallbacks.
    if (kDebugMode) {
      runApp(const MyApp());
      assert(() {
        debugPrint(
          '[StartupTrace] runApp(MyApp) (Firebase init failed) at ${DateTime.now()}',
        );
        return true;
      }());
    } else {
      runApp(ErrorApp(e.toString()));
    }
  }
}

// In debug, route Firebase services to local emulators when available.
Future<void> _useFirebaseEmulators() async {
  // Allow overriding the host via --dart-define=EMULATOR_HOST=192.168.x.x when testing on a phone.
  const hostOverride = String.fromEnvironment(
    'EMULATOR_HOST',
    defaultValue: '',
  );
  final host = hostOverride.isNotEmpty
      ? hostOverride
      : (Platform.isAndroid ? '10.0.2.2' : 'localhost');
  // Firestore
  FirebaseFirestore.instance.useFirestoreEmulator(host, 8080);
  FirebaseFirestore.instance.settings = const Settings(
    persistenceEnabled: false,
    sslEnabled: false,
  );
  // Auth
  await FirebaseAuth.instance.useAuthEmulator(host, 9099);
  // Functions
  FirebaseFunctions.instance.useFunctionsEmulator(host, 5001);
}

class ErrorApp extends StatelessWidget {
  final String error;
  const ErrorApp(this.error, {super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        appBar: AppBar(title: const Text('Firebase not configured')),
        body: Padding(
          padding: const EdgeInsets.all(16.0),
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Firebase failed to initialize. This usually means the native platform files are not configured yet.',
                ),
                const SizedBox(height: 12),
                Text('Error: $error'),
                const SizedBox(height: 12),
                const Text('Quick fixes:'),
                const SizedBox(height: 8),
                const Text(
                  '1) Run the FlutterFire CLI: `flutterfire configure`',
                ),
                const SizedBox(height: 6),
                const Text(
                  '2) For Windows, ensure desktop Firebase setup is completed or use the FlutterFire CLI to generate configuration.',
                ),
                ElevatedButton(
                  onPressed: () async {
                    // Try a simple retry (useful after adding config files)
                    try {
                      FirebaseOptions? options;
                      try {
                        options = DefaultFirebaseOptions.currentPlatform;
                      } catch (_) {
                        options = null;
                      }
                      await Firebase.initializeApp(options: options);
                      // Restart the app by calling runApp again
                      runApp(const MyApp());
                    } catch (e) {
                      // Can't use ScaffoldMessenger safely across async gap; print instead
                      // Developer can see console logs
                      // Optionally you could show a dialog using a new context
                      // but runApp restart is simplest here.
                      if (kDebugMode) debugPrint('Still failing: $e');
                    }
                  },
                  child: const Text('Retry initialize'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _AuthGate extends StatelessWidget {
  const _AuthGate();

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const _GateSplash();
        }
        final user = snapshot.data;
        if (user == null) {
          return const LoginPage();
        }
        return FutureBuilder<DocumentSnapshot<Map<String, dynamic>>>(
          future: FirebaseFirestore.instance
              .collection('users')
              .doc(user.uid)
              .get(),
          builder: (context, docSnap) {
            if (docSnap.connectionState == ConnectionState.waiting) {
              return const _GateSplash();
            }
            if (docSnap.hasError) {
              return _GateError(
                message: 'Could not load your profile. Tap to try again.',
                onRetry: () => FirebaseAuth.instance.signOut(),
              );
            }
            final data = docSnap.data?.data();
            final onboardingComplete = data?['onboarding_completed'] == true;
            if (!onboardingComplete) {
              return const OnboardingPage();
            }
            return const HomePage();
          },
        );
      },
    );
  }
}

class _GateSplash extends StatelessWidget {
  const _GateSplash();

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Center(child: CircularProgressIndicator()),
    );
  }
}

class _GateError extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;
  const _GateError({required this.message, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(message, textAlign: TextAlign.center),
            const SizedBox(height: 12),
            ElevatedButton(
              onPressed: onRetry,
              child: const Text('Retry'),
            ),
          ],
        ),
      ),
    );
  }
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    // router already declared below, removed duplicate
    // Always start at the login page as the base route
    final router = AppRouter();
    return MaterialApp(
      title: 'Momentum',
      theme: AppTheme.lightTheme,
      debugShowCheckedModeBanner: false,
      home: const _AuthGate(),
      onGenerateRoute: router.onGenerateRoute,
      builder: (context, child) {
        ErrorWidget.builder = (FlutterErrorDetails details) {
          // Log the full error details for debugging (secure logs)
          debugPrint('[MyApp] Global error: ${details.exceptionAsString()}');
          // Show generic message to users to avoid exposing internal details
          return const Scaffold(
            body: Center(child: Text('An unexpected error occurred.')),
          );
        };
        try {
          return child!;
        } catch (e) {
          debugPrint('[MyApp] Exception in builder: $e');
          WidgetsBinding.instance.addPostFrameCallback((_) {
            Navigator.of(context).pushNamedAndRemoveUntil(Routes.login, (route) => false);
          });
          return const SizedBox.shrink();
        }
      },
    );
  }
}
// HomePage lives in features/home; routing handled by AppRouter.

// _SplashScreen removed as it is no longer used
