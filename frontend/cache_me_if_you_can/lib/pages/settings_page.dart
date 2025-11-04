import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:firebase_app_check/firebase_app_check.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:settings_ui/settings_ui.dart';
import '../widgets/settingsWidgets/user_profile.dart';
import 'security_page.dart';

class SettingsPage extends StatelessWidget {
  const SettingsPage({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(
        title: Text('Settings', style: theme.textTheme.titleLarge),
        centerTitle: true,
        elevation: 0,
        backgroundColor: theme.colorScheme.surface,
      ),
      body: SafeArea(
        child: SettingsList(
          lightTheme: SettingsThemeData(
            settingsListBackground: theme.colorScheme.surface,
            settingsSectionBackground: theme.colorScheme.surface,
            trailingTextColor: theme.colorScheme.primary,
          ),
          sections: [
            SettingsSection(
              title: const Text('Profile'),
              tiles: [
                SettingsTile.navigation(
                  leading: CircleAvatar(
                    backgroundColor: theme.colorScheme.secondaryContainer,
                    child: Icon(
                      Icons.person,
                      color: theme.colorScheme.onSecondaryContainer,
                    ),
                  ),
                  title: const Text('Account'),
                  value: const Text('Edit profile'),
                  onPressed: (context) {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => Scaffold(
                          appBar: AppBar(title: const Text('Account')),
                          body: const Padding(
                            padding: EdgeInsets.all(16.0),
                            child: UserProfile(),
                          ),
                        ),
                      ),
                    );
                  },
                ),
                SettingsTile.navigation(
                  leading: const Icon(Icons.lock_outline),
                  title: const Text('Password & Security'),
                  onPressed: (context) {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const SecurityPage()),
                    );
                  },
                ),
              ],
            ),
            SettingsSection(
              title: const Text('Preferences'),
              tiles: [
                SettingsTile.switchTile(
                  title: const Text('Dark Mode'),
                  leading: const Icon(Icons.dark_mode),
                  initialValue: false,
                  onToggle: (value) {},
                ),
                SettingsTile.navigation(
                  leading: const Icon(Icons.palette_outlined),
                  title: const Text('Theme Color'),
                  value: const Text('System Default'),
                  onPressed: (context) {},
                ),
                SettingsTile.navigation(
                  leading: const Icon(Icons.language),
                  title: const Text('Language'),
                  value: const Text('English'),
                  onPressed: (context) {},
                ),
              ],
            ),
            SettingsSection(
              title: const Text('Notifications'),
              tiles: [
                SettingsTile.switchTile(
                  initialValue: true,
                  onToggle: (value) {},
                  leading: const Icon(Icons.notifications_active_outlined),
                  title: const Text('App Notifications'),
                ),
                SettingsTile.switchTile(
                  initialValue: false,
                  onToggle: (value) {},
                  title: const Text('Email Updates'),
                  leading: const Icon(Icons.mail_outline),
                ),
              ],
            ),
            SettingsSection(
              title: const Text('About'),
              tiles: [
                SettingsTile.navigation(
                  leading: const Icon(Icons.info_outline),
                  title: const Text('About App'),
                  onPressed: (context) {
                    showAboutDialog(
                      context: context,
                      applicationName: 'Cache Me If You Can',
                      applicationVersion: 'v1.0.0',
                      applicationLegalese: '© 2025 Cache Me If You Can Inc.',
                    );
                  },
                ),
              ],
            ),
            SettingsSection(
              title: const Text('Developer'),
              tiles: [
                SettingsTile.navigation(
                  leading: const Icon(Icons.verified_user_outlined),
                  title: const Text('Verify App Check'),
                  value: const Text('Debug token check'),
                  onPressed: (context) async {
                    final messenger = ScaffoldMessenger.of(context);
                    try {
                      final token = await FirebaseAppCheck.instance.getToken(
                        true,
                      );
                      if (token != null && token.isNotEmpty) {
                        messenger.showSnackBar(
                          SnackBar(
                            content: Text(
                              'App Check token acquired (${token.substring(0, 8)}...)',
                            ),
                          ),
                        );
                      } else {
                        messenger.showSnackBar(
                          const SnackBar(
                            content: Text('No App Check token returned'),
                          ),
                        );
                      }
                    } catch (e) {
                      if (kDebugMode) {
                        debugPrint('App Check token error: $e');
                      }
                      messenger.showSnackBar(
                        SnackBar(content: Text('App Check error: $e')),
                      );
                    }
                  },
                ),
              ],
            ),
            // Logout section at the bottom
            SettingsSection(
              tiles: [
                SettingsTile.navigation(
                  leading: Icon(Icons.logout, color: theme.colorScheme.error),
                  title: Text(
                    'Log out',
                    style: TextStyle(color: theme.colorScheme.error),
                  ),
                  onPressed: (context) async {
                    // Capture navigator before async gap to satisfy lints
                    final nav = Navigator.of(context);
                    try {
                      await FirebaseAuth.instance.signOut();
                    } finally {
                      // Pop to root; _AuthGate will route to LoginPage
                      nav.popUntil((route) => route.isFirst);
                    }
                  },
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
