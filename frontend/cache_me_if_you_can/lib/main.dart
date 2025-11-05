import 'dart:io' show Platform;
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:firebase_app_check/firebase_app_check.dart';
import 'pages/settings_page.dart';
import 'styles/styles.dart';
import 'pages/workout_page.dart';
import 'widgets/homePageWidgets/progress_waves.dart';
import 'pages/login_page.dart';
import 'pages/create_user_page.dart';
import 'firebase_options.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

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
    const useEmulators = bool.fromEnvironment(
      'USE_EMULATORS',
      defaultValue: true,
    );
    if (kDebugMode && useEmulators) {
      try {
        // Point to local emulators in debug/dev to avoid hitting prod
        await _useFirebaseEmulators();
        await FirebaseAuth.instance.signInAnonymously();
      } catch (_) {
        // ignore errors in debug sign-in
      }
    }

    runApp(const MyApp());
  } catch (e) {
    // In development, continue without Firebase and let widgets use mock fallbacks.
    if (kDebugMode) {
      runApp(const MyApp());
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

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Momentum',
      // Apply centralized theme from styles.dart
      theme: AppTheme.lightTheme,
      home: const _AuthGate(),
      routes: {
        '/login': (_) => const LoginPage(),
        '/signup': (_) => const CreateUserPage(),
      },
      debugShowCheckedModeBanner: false,
    );
  }
}

class _AuthGate extends StatelessWidget {
  const _AuthGate();

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, snap) {
        if (snap.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }
        final user = snap.data;
        if (user == null) {
          // First screen: Login when not signed in
          return const LoginPage();
        }
        return const HomePage();
      },
    );
  }
}

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  @override
  Widget build(BuildContext context) {
    // Compute responsive size for the circular progress widgets to avoid overflow.
    final screenWidth = MediaQuery.of(context).size.width;
    // Body has 16px horizontal padding on both sides, Row has a 16px spacer between items.
    final availableRow =
        (screenWidth - 32.0) -
        1.0; // subtract 1px as safety to avoid rounding overflow
    final perItem = (availableRow - 16.0) / 2.0;
    // Clamp each circle between 120 and 160; they will shrink on narrow screens.
    final double circleSize = perItem.clamp(120.0, 160.0);
    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              _greetingName(),
              // Use themed headline style from AppTheme
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: 4),
            Text(
              "Ready to crush your goals today?",
              // Subtle secondary text color from AppTheme
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.notifications),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const WorkoutPage()),
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const SettingsPage()),
              );
            },
          ),
        ],
        // AppBar theming (colors, elevation, bottom border) comes from AppTheme
        toolbarHeight: 60,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Center(
              child: Wrap(
                spacing: 16,
                runSpacing: 16,
                alignment: WrapAlignment.center,
                children: [
                  Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      ProgressWidget(
                        progress: 0.72,
                        goalLabel: '', // hide center text for clarity
                        value: '',
                        color: Colors.greenAccent,
                        size: circleSize,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        '5,200 steps',
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                      Text(
                        'Goal: 7,200',
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                    ],
                  ),
                  Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // If you want live calories from mock/DB, swap to CaloriesProgressLoader
                      ProgressWidget(
                        progress: 0.18,
                        goalLabel: '',
                        value: '',
                        color: Colors.orangeAccent,
                        size: circleSize,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        '320 / 2500 kcal',
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                      Text(
                        "Today's calories",
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

extension on _HomePageState {
  String _greetingName() {
    final user = FirebaseAuth.instance.currentUser;
    final base = user?.displayName?.trim();
    final name = (base != null && base.isNotEmpty)
        ? base
        : (user?.email != null ? user!.email!.split('@').first : 'Friend');
    return 'Hello, $name';
  }
}
