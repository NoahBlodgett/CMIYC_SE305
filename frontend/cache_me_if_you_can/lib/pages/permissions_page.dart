import 'dart:io' show Platform;
import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../main.dart';

class PermissionsPage extends StatefulWidget {
  const PermissionsPage({super.key});

  @override
  State<PermissionsPage> createState() => _PermissionsPageState();
}

class _PermissionsPageState extends State<PermissionsPage> {
  bool _requesting = true;

  @override
  void initState() {
    super.initState();
    _requestAll();
  }

  Future<void> _requestAll() async {
    try {
      // Notifications (Android 13+/iOS)
      await Permission.notification.request();
      // Optional camera/photo access if you plan to allow profile photos later
      if (Platform.isAndroid) {
        // Camera
        await Permission.camera.request();
        // Storage (older Android) - permission_handler maps accordingly
        await Permission.storage.request();
      } else if (Platform.isIOS) {
        // Camera and Photos on iOS
        await Permission.camera.request();
        await Permission.photos.request();
      }

      // Mark completed so we don't show this page again unnecessarily
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('permissionsCompleted', true);
    } finally {
      if (!mounted) return;
      setState(() => _requesting = false);
      // Go to home (auth gate will route properly)
      Navigator.of(
        context,
      ).pushReplacement(MaterialPageRoute(builder: (_) => const HomePage()));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Permissions')),
      body: Center(
        child: _requesting
            ? Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: const [
                  CircularProgressIndicator(),
                  SizedBox(height: 12),
                  Text('Requesting permissions...'),
                ],
              )
            : const Text('Done'),
      ),
    );
  }
}
