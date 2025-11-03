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
  bool _requesting = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    // Show explanation first; user taps Continue to trigger system popups
  }

  Future<void> _requestAll() async {
    setState(() {
      _requesting = true;
      _error = null;
    });
    try {
      // Request notifications (Android 13+/iOS)
      final notif = await Permission.notification.request();

      // Camera + media/photos by platform
      PermissionStatus cam;
      PermissionStatus mediaOrPhotos;
      if (Platform.isAndroid) {
        cam = await Permission.camera.request();
        // Storage covers legacy; package maps to READ_MEDIA_* on newer Android
        mediaOrPhotos = await Permission.storage.request();
      } else {
        cam = await Permission.camera.request();
        mediaOrPhotos = await Permission.photos.request();
      }

      // Collect any permanently denied permissions
      final deniedPermanently = <String>[];
      if (notif.isPermanentlyDenied) deniedPermanently.add('Notifications');
      if (cam.isPermanentlyDenied) deniedPermanently.add('Camera');
      if (mediaOrPhotos.isPermanentlyDenied) {
        deniedPermanently.add(Platform.isAndroid ? 'Storage' : 'Photos');
      }

      // If some are permanently denied, guide user to Settings
      if (deniedPermanently.isNotEmpty) {
        if (!mounted) return;
        await showDialog(
          context: context,
          builder: (ctx) => AlertDialog(
            title: const Text('Allow permissions in Settings'),
            content: Text(
              'To continue, enable: ${deniedPermanently.join(', ')} in App Settings.',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(ctx).pop(),
                child: const Text('Cancel'),
              ),
              TextButton(
                onPressed: () async {
                  Navigator.of(ctx).pop();
                  await openAppSettings();
                },
                child: const Text('Open Settings'),
              ),
            ],
          ),
        );
      }

      // Mark completed so we don't show this page again unnecessarily
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('permissionsCompleted', true);

      if (!mounted) return;
      Navigator.of(
        context,
      ).pushReplacement(MaterialPageRoute(builder: (_) => const HomePage()));
    } catch (e) {
      setState(() => _error = e.toString());
    } finally {
      if (mounted) setState(() => _requesting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Permissions')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'We need a few permissions',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 8),
            const Text(
              '• Notifications: Remind you about goals and updates\n'
              '• Camera: Add or update your profile photo\n'
              '• Photos/Storage: Save and select images',
            ),
            if (_error != null) ...[
              const SizedBox(height: 12),
              Text(_error!, style: const TextStyle(color: Colors.redAccent)),
            ],
            const Spacer(),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _requesting ? null : _requestAll,
                child: _requesting
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Text('Continue'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
