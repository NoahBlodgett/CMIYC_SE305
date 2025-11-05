import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:settings_ui/settings_ui.dart';
import 'package:permission_handler/permission_handler.dart' as ph;
import 'package:url_launcher/url_launcher.dart';

class SecurityPage extends StatefulWidget {
  const SecurityPage({super.key});

  @override
  State<SecurityPage> createState() => _SecurityPageState();
}

class _SecurityPageState extends State<SecurityPage> {
  bool _busy = false;
  User? get _user => FirebaseAuth.instance.currentUser;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(title: const Text('Password & Security')),
      body: SafeArea(
        child: SettingsList(
          lightTheme: SettingsThemeData(
            settingsListBackground: theme.colorScheme.surface,
            settingsSectionBackground: theme.colorScheme.surface,
            trailingTextColor: theme.colorScheme.primary,
          ),
          sections: [
            SettingsSection(
              title: const Text('Password & Sign-in'),
              tiles: [
                SettingsTile.navigation(
                  leading: const Icon(Icons.password_outlined),
                  title: const Text('Change password'),
                  description: const Text('Use a strong, unique password'),
                  onPressed: (_) => _changePasswordDialog(),
                ),
                SettingsTile.switchTile(
                  title: const Text('Two-factor authentication (2FA)'),
                  leading: const Icon(Icons.phonelink_lock_outlined),
                  initialValue: false,
                  onToggle: (v) {
                    _showComingSoon('Two-factor authentication');
                  },
                  description: const Text('Add an extra layer of security'),
                ),
                SettingsTile.switchTile(
                  title: const Text('Biometric login'),
                  leading: const Icon(Icons.fingerprint),
                  initialValue: false,
                  onToggle: (v) {
                    _showComingSoon('Biometric login');
                  },
                  description: const Text(
                    'Use Face ID / fingerprint to sign in (coming soon)',
                  ),
                ),
              ],
            ),
            SettingsSection(
              title: const Text('Sessions & Devices'),
              tiles: [
                SettingsTile.navigation(
                  leading: const Icon(Icons.devices_other_outlined),
                  title: const Text('Active sessions'),
                  value: FutureBuilder<String>(
                    future: _sessionSummary(),
                    builder: (context, snap) =>
                        Text(snap.data ?? 'Current device'),
                  ),
                  onPressed: (context) => _showSessionsSheet(),
                ),
                SettingsTile.navigation(
                  leading: const Icon(Icons.logout),
                  title: const Text('Sign out of all devices'),
                  description: const Text(
                    'Requires backend support to revoke sessions',
                  ),
                  onPressed: (context) {
                    _showComingSoon('Sign out of all devices');
                  },
                ),
              ],
            ),
            SettingsSection(
              title: const Text('Permissions & Privacy'),
              tiles: [
                SettingsTile.navigation(
                  leading: const Icon(Icons.privacy_tip_outlined),
                  title: const Text('Privacy policy'),
                  onPressed: (context) =>
                      _openUrl(Uri.parse('https://example.com/privacy')),
                ),
                SettingsTile.navigation(
                  leading: const Icon(Icons.app_settings_alt_outlined),
                  title: const Text('Review app permissions'),
                  onPressed: (context) async {
                    await ph.openAppSettings();
                  },
                ),
                SettingsTile.navigation(
                  leading: const Icon(Icons.security_outlined),
                  title: const Text('Recent security activity'),
                  onPressed: (context) => _showRecentSecurity(),
                ),
              ],
            ),
            SettingsSection(
              title: const Text('Account recovery'),
              tiles: [
                SettingsTile.navigation(
                  leading: const Icon(Icons.contact_mail_outlined),
                  title: const Text('Recovery options'),
                  value: const Text('Email, phone, and questions'),
                  onPressed: (context) => _openRecoverySheet(),
                ),
              ],
            ),
            SettingsSection(
              title: const Text('Help & Support'),
              tiles: [
                SettingsTile.navigation(
                  leading: const Icon(Icons.menu_book_outlined),
                  title: const Text('Security tips'),
                  onPressed: (context) => _showSecurityTips(),
                ),
                SettingsTile.navigation(
                  leading: const Icon(Icons.report_gmailerrorred_outlined),
                  title: const Text('Report a security issue'),
                  onPressed: (context) => _reportIssue(),
                ),
              ],
            ),
            SettingsSection(
              tiles: [
                SettingsTile.navigation(
                  leading: Icon(
                    Icons.delete_forever_outlined,
                    color: theme.colorScheme.error,
                  ),
                  title: Text(
                    'Delete account & data',
                    style: TextStyle(color: theme.colorScheme.error),
                  ),
                  onPressed: (context) => _confirmDelete(),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Future<String> _sessionSummary() async {
    final u = _user;
    if (u == null) return 'Not signed in';
    final last = u.metadata.lastSignInTime;
    if (last == null) return 'Current device';
    return 'Last sign-in: ${last.toLocal()}';
  }

  void _showComingSoon(String feature) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text('$feature setup is coming soon')));
  }

  Future<void> _changePasswordDialog() async {
    final email = _user?.email;
    if (email == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Password change not available for this account'),
        ),
      );
      return;
    }
    final currentCtrl = TextEditingController();
    final newCtrl = TextEditingController();
    final confirmCtrl = TextEditingController();
    await showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Change password'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: currentCtrl,
              obscureText: true,
              decoration: const InputDecoration(labelText: 'Current password'),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: newCtrl,
              obscureText: true,
              decoration: const InputDecoration(labelText: 'New password'),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: confirmCtrl,
              obscureText: true,
              decoration: const InputDecoration(
                labelText: 'Confirm new password',
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: _busy
                ? null
                : () async {
                    final current = currentCtrl.text;
                    final next = newCtrl.text;
                    final confirm = confirmCtrl.text;
                    if (next.length < 6 || next != confirm) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text(
                            'Passwords must match and be at least 6 characters',
                          ),
                        ),
                      );
                      return;
                    }
                    Navigator.pop(ctx);
                    await _changePassword(email, current, next);
                  },
            child: const Text('Update'),
          ),
        ],
      ),
    );
  }

  Future<void> _changePassword(
    String email,
    String current,
    String next,
  ) async {
    setState(() => _busy = true);
    final messenger = ScaffoldMessenger.of(context);
    try {
      final user = _user;
      if (user == null) throw Exception('Not signed in');
      // Reauthenticate with email/password
      final cred = EmailAuthProvider.credential(
        email: email,
        password: current,
      );
      await user.reauthenticateWithCredential(cred);
      await user.updatePassword(next);
      messenger.showSnackBar(const SnackBar(content: Text('Password updated')));
    } on FirebaseAuthException catch (e) {
      messenger.showSnackBar(
        SnackBar(content: Text(e.message ?? 'Update failed')),
      );
    } catch (e) {
      messenger.showSnackBar(SnackBar(content: Text('Failed: $e')));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  void _showRecentSecurity() {
    final u = _user;
    final created = u?.metadata.creationTime;
    final last = u?.metadata.lastSignInTime;
    showModalBottomSheet(
      context: context,
      showDragHandle: true,
      builder: (ctx) => Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Recent security activity',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text('Account created: ${created?.toLocal()}'),
            Text('Last sign-in: ${last?.toLocal()}'),
            const SizedBox(height: 8),
            const Text(
              'More detailed activity will appear here when available.',
            ),
          ],
        ),
      ),
    );
  }

  void _openRecoverySheet() {
    final emailCtrl = TextEditingController();
    final phoneCtrl = TextEditingController();
    final q1Ctrl = TextEditingController();
    final a1Ctrl = TextEditingController();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (ctx) => Padding(
        padding: EdgeInsets.only(
          left: 16,
          right: 16,
          bottom: MediaQuery.of(ctx).viewInsets.bottom + 16,
          top: 8,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'Account recovery',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: emailCtrl,
              keyboardType: TextInputType.emailAddress,
              decoration: const InputDecoration(
                labelText: 'Recovery email (optional)',
              ),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: phoneCtrl,
              keyboardType: TextInputType.phone,
              decoration: const InputDecoration(
                labelText: 'Recovery phone (optional)',
              ),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: q1Ctrl,
              decoration: const InputDecoration(
                labelText: 'Security question (optional)',
              ),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: a1Ctrl,
              decoration: const InputDecoration(labelText: 'Answer (optional)'),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                const Spacer(),
                TextButton(
                  onPressed: () => Navigator.pop(ctx),
                  child: const Text('Cancel'),
                ),
                const SizedBox(width: 8),
                FilledButton(
                  onPressed: _busy
                      ? null
                      : () async {
                          Navigator.pop(ctx);
                          await _saveRecovery(
                            emailCtrl.text.trim(),
                            phoneCtrl.text.trim(),
                            q1Ctrl.text.trim(),
                            a1Ctrl.text.trim(),
                          );
                        },
                  child: const Text('Save'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _saveRecovery(
    String email,
    String phone,
    String q,
    String a,
  ) async {
    setState(() => _busy = true);
    final u = _user;
    final messenger = ScaffoldMessenger.of(context);
    try {
      if (u == null) throw Exception('Not signed in');
      final data = <String, dynamic>{};
      if (email.isNotEmpty) data['recovery_email'] = email;
      if (phone.isNotEmpty) data['recovery_phone'] = phone;
      if (q.isNotEmpty && a.isNotEmpty) {
        data['recovery_question'] = q;
        data['recovery_answer_hint'] = a.isNotEmpty ? a[0] : '';
      }
      if (data.isNotEmpty) {
        await FirebaseFirestore.instance
            .collection('users')
            .doc(u.uid)
            .set(data, SetOptions(merge: true));
      }
      messenger.showSnackBar(
        const SnackBar(content: Text('Recovery options saved')),
      );
    } catch (e) {
      messenger.showSnackBar(SnackBar(content: Text('Failed to save: $e')));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _showSessionsSheet() async {
    final u = _user;
    showModalBottomSheet(
      context: context,
      showDragHandle: true,
      builder: (ctx) => Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Active sessions',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            if (u != null) ...[
              Text('Signed in as: ${u.email ?? u.displayName ?? u.uid}'),
              const SizedBox(height: 4),
              Text(
                'Providers: ${u.providerData.map((p) => p.providerId).join(', ')}',
              ),
              const SizedBox(height: 4),
              Text('Last sign-in: ${u.metadata.lastSignInTime?.toLocal()}'),
            ],
            const SizedBox(height: 12),
            const Text(
              'More devices will appear here when backend tracking is enabled.',
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _openUrl(Uri uri) async {
    final ok = await launchUrl(uri, mode: LaunchMode.externalApplication);
    if (!mounted) return;
    if (!ok) {
      final messenger = ScaffoldMessenger.of(context);
      messenger.showSnackBar(
        SnackBar(content: Text('Could not open ${uri.toString()}')),
      );
    }
  }

  Future<void> _reportIssue() async {
    final uri = Uri.parse('mailto:support@example.com');
    await _openUrl(uri);
  }

  void _showSecurityTips() {
    showModalBottomSheet(
      context: context,
      showDragHandle: true,
      builder: (ctx) => Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Security tips',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            const Text(
              '• Use a unique, strong password and don\'t reuse it across apps.',
            ),
            const Text('• Enable 2FA when available.'),
            const Text('• Review app permissions regularly.'),
            const Text('• Be cautious of phishing emails and links.'),
          ],
        ),
      ),
    );
  }

  Future<void> _confirmDelete() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete account?'),
        content: const Text(
          'This will permanently delete your account and associated data. This action cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.error,
            ),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (confirmed == true) {
      await _deleteAccount();
    }
  }

  Future<void> _deleteAccount() async {
    setState(() => _busy = true);
    final messenger = ScaffoldMessenger.of(context);
    final nav = Navigator.of(context);
    try {
      final u = _user;
      if (u == null) throw Exception('Not signed in');
      // Delete user doc first
      await FirebaseFirestore.instance
          .collection('users')
          .doc(u.uid)
          .delete()
          .catchError((_) {});
      // Delete auth account
      await u.delete();
      if (!mounted) return;
      messenger.showSnackBar(const SnackBar(content: Text('Account deleted')));
      nav.pop();
    } on FirebaseAuthException catch (e) {
      messenger.showSnackBar(
        SnackBar(
          content: Text(e.message ?? 'Delete failed (re-auth may be required)'),
        ),
      );
    } catch (e) {
      messenger.showSnackBar(SnackBar(content: Text('Delete failed: $e')));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }
}
