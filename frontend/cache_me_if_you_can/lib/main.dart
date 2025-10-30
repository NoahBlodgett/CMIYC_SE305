import 'dart:io' show Platform;
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'pages/settings_page.dart';
import 'styles/styles.dart';
import 'pages/workout_page.dart';
import 'widgets/homePageWidgets/progress_waves.dart';
import 'firebase_options.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Try to initialize Firebase. If platform hasn't been configured yet
  // (for example Windows desktop before you run `flutterfire configure`),
  // catch the exception and show a helpful error UI instead of crashing.
  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );

    // For development, sign in anonymously so currentUser is available.
    if (kDebugMode) {
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
  final host = Platform.isAndroid ? '10.0.2.2' : 'localhost';
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
                const SizedBox(height: 12),
                ElevatedButton(
                  onPressed: () async {
                    // Try a simple retry (useful after adding config files)
                    try {
                      await Firebase.initializeApp();
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
      home: const HomePage(),
      debugShowCheckedModeBanner: false,
    );
  }
}

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
  final String user = "Nathan";
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
              "Hello, ${widget.user}",
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
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                ProgressWidget(
                  progress: 0.72,
                  goalLabel: "Steps",
                  value: "5,200",
                  color: Colors.greenAccent,
                  size: circleSize,
                ),
                const SizedBox(width: 16),
                ProgressWidget(
                  progress: 0.45,
                  goalLabel: "Calories",
                  value: "450",
                  color: Colors.orangeAccent,
                  size: circleSize,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
