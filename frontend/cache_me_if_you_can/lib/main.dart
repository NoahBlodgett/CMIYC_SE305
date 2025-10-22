import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'pages/settings_page.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Try to initialize Firebase. If platform hasn't been configured yet
  // (for example Windows desktop before you run `flutterfire configure`),
  // catch the exception and show a helpful error UI instead of crashing.
  try {
    await Firebase.initializeApp();

    // For development, sign in anonymously so currentUser is available.
    if (kDebugMode) {
      try {
        await FirebaseAuth.instance.signInAnonymously();
      } catch (_) {
        // ignore errors in debug sign-in
      }
    }

    runApp(const MyApp());
  } catch (e) {
    runApp(ErrorApp(e.toString()));
  }
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
                      // Restart the app by rebuilding the widget tree with MyApp
                      Navigator.of(context).pushReplacement(
                        MaterialPageRoute(builder: (_) => const MyApp()),
                      );
                    } catch (e) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('Still failing: $e')),
                      );
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
      title: 'Cache Me If You Can',
      theme: ThemeData(primarySwatch: Colors.pink),
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
    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              "Hello, ${widget.user}",
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 20),
            ),
            SizedBox(height: 4),
            Text(
              "Ready to crush your goals today?",
              style: TextStyle(fontSize: 14, color: Colors.white70),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.notifications),
            onPressed: () {
              // nothing so far
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
        toolbarHeight: 60,
        backgroundColor: Colors.blueAccent,
      ),
      body: Text("Hello World!"),
    );
  }
}
