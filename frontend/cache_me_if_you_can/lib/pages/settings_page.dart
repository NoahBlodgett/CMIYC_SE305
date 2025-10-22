import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../widgets/settingsWidgets/user_profile.dart';

class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key});

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  bool _darkMode = false;
  bool _notifications = true;
  bool _autoSync = true;

  final _auth = FirebaseAuth.instance;

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    final user = _auth.currentUser;
    if (user == null) return;
    final snapshot = await FirebaseFirestore.instance
        .collection('users')
        .doc(user.uid)
        .get();
    if (!snapshot.exists) return;
    final data = snapshot.data()!;
    setState(() {
      _darkMode = data['settings']?['darkMode'] ?? _darkMode;
      _notifications = data['settings']?['notifications'] ?? _notifications;
      _autoSync = data['settings']?['autoSync'] ?? _autoSync;
    });
  }

  Future<void> _saveSetting(String key, bool value) async {
    final user = _auth.currentUser;
    if (user == null) return;
    await FirebaseFirestore.instance.collection('users').doc(user.uid).set({
      'settings': {key: value},
    }, SetOptions(merge: true));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            Navigator.pop(context);
          },
        ),
        title: const Text('User Settings'),
      ),
      body: ListView(
        children: [
          const Padding(
            padding: EdgeInsets.all(16.0),
            child: Text(
              "Account",
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
          ),
          ListTile(
            leading: const Icon(Icons.person),
            title: const Text("Profile"),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => Scaffold(
                    appBar: AppBar(title: const Text('Profile')),
                    body: const Center(child: UserProfile()),
                  ),
                ),
              );
            },
          ),
          SwitchListTile(
            value: _darkMode,
            title: const Text('Dark mode'),
            secondary: const Icon(Icons.dark_mode),
            onChanged: (v) {
              setState(() => _darkMode = v);
              _saveSetting('darkMode', v);
            },
          ),
          SwitchListTile(
            value: _notifications,
            title: const Text('Notifications'),
            secondary: const Icon(Icons.notifications),
            onChanged: (v) {
              setState(() => _notifications = v);
              _saveSetting('notifications', v);
            },
          ),
          SwitchListTile(
            value: _autoSync,
            title: const Text('Auto-sync'),
            secondary: const Icon(Icons.sync),
            onChanged: (v) {
              setState(() => _autoSync = v);
              _saveSetting('autoSync', v);
            },
          ),
          ListTile(
            leading: const Icon(Icons.lock_reset),
            title: const Text("Reset Password"),
            onTap: () => FirebaseAuth.instance.sendPasswordResetEmail(
              email: FirebaseAuth.instance.currentUser?.email ?? '',
            ),
          ),
        ],
      ),
    );
  }
}
