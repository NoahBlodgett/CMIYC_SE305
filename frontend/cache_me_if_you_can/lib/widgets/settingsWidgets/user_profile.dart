import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

class UserProfile extends StatefulWidget {
  const UserProfile({super.key});

  @override
  State<UserProfile> createState() => _UserProfileState();
}

class _UserProfileState extends State<UserProfile> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseStorage _storage = FirebaseStorage.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final ImagePicker _picker = ImagePicker();

  User? _user;
  late TextEditingController _nameController;
  String? _photoUrl;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _user = _auth.currentUser;
    _photoUrl = _user?.photoURL;
    _nameController = TextEditingController(text: _user?.displayName ?? '');
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  Future<void> _pickAndUploadImage() async {
    try {
      final XFile? picked = await _picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 800,
        imageQuality: 80,
      );
      if (picked == null) return;

      setState(() => _isLoading = true);

      final file = File(picked.path);
      final uid = _user?.uid;
      if (uid == null) throw Exception('No authenticated user');

      final ref = _storage.ref().child('profile_pics').child('$uid.jpg');
      await ref.putFile(file);
      final downloadUrl = await ref.getDownloadURL();

      // Update Firebase Auth profile
      await _user!.updatePhotoURL(downloadUrl);

      // Update Firestore user doc (optional, but useful for other services)
      await _firestore.collection('users').doc(uid).set({
        'photoURL': downloadUrl,
      }, SetOptions(merge: true));

      if (mounted) {
        setState(() {
          _photoUrl = downloadUrl;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        // show snackbar synchronously while mounted
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Failed to upload image: $e')));
      }
    }
  }

  Future<void> _saveDisplayName() async {
    try {
      final newName = _nameController.text.trim();
      if (newName.isEmpty) return;
      setState(() => _isLoading = true);

      await _user!.updateDisplayName(newName);
      await _firestore.collection('users').doc(_user!.uid).set({
        'displayName': newName,
      }, SetOptions(merge: true));

      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Profile updated')));
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Failed to update name: $e')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.all(16),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Stack(
              alignment: Alignment.bottomRight,
              children: [
                CircleAvatar(
                  radius: 48,
                  backgroundImage: _photoUrl != null
                      ? NetworkImage(_photoUrl!)
                      : null,
                  child: _photoUrl == null
                      ? const Icon(Icons.person, size: 48)
                      : null,
                ),
                Positioned(
                  right: 0,
                  bottom: 0,
                  child: InkWell(
                    onTap: _isLoading ? null : _pickAndUploadImage,
                    child: Container(
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        color: Theme.of(context).colorScheme.primary,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.edit,
                        size: 18,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _nameController,
              decoration: const InputDecoration(
                labelText: 'Display name',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: _isLoading ? null : _saveDisplayName,
                icon: const Icon(Icons.save),
                label: _isLoading
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Text('Save'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
