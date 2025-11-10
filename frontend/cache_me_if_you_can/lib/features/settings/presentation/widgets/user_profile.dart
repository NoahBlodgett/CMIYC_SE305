import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:cache_me_if_you_can/mock/mock_data.dart';

class UserProfile extends StatefulWidget {
  const UserProfile({super.key});

  @override
  State<UserProfile> createState() => _UserProfileState();
}

class _UserProfileState extends State<UserProfile> {
  final ImagePicker _picker = ImagePicker();
  final String apiBase = 'http://localhost:3000';
  late TextEditingController _nameController;
  String? _photoUrl;
  bool _isLoading = false;
  bool _mockMode = false;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController();
    _loadProfileFromApi();
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

      if (!_mockMode) {
        final uri = Uri.parse('$apiBase/profile/upload-proxy');
        final request = http.MultipartRequest('POST', uri);
        request.files.add(
          http.MultipartFile(
            'file',
            file.openRead(),
            await file.length(),
            filename: picked.name,
          ),
        );
        final streamed = await request.send().timeout(
          const Duration(seconds: 3),
        );
        final resp = await http.Response.fromStream(streamed);
        if (resp.statusCode != 200) {
          throw Exception('Upload failed: ${resp.statusCode} ${resp.body}');
        }
        final body = json.decode(resp.body);
        final downloadUrl = body['publicUrl'] as String?;
        if (downloadUrl == null) throw Exception('No publicUrl in response');
        if (mounted) {
          setState(() {
            _photoUrl = downloadUrl;
            _isLoading = false;
          });
        }
      } else {
        if (mounted) {
          setState(() {
            _photoUrl = 'https://via.placeholder.com/150';
            _isLoading = false;
          });
        }
      }
    } catch (e) {
      if (kDebugMode && !_mockMode) {
        if (mounted) setState(() => _mockMode = true);
        if (mounted) {
          setState(() {
            _photoUrl = 'https://via.placeholder.com/150';
            _isLoading = false;
          });
        }
      } else {
        if (mounted) {
          setState(() => _isLoading = false);
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text('Failed to upload image: $e')));
        }
      }
    }
  }

  Future<void> _saveDisplayName() async {
    try {
      final newName = _nameController.text.trim();
      if (newName.isEmpty) return;
      setState(() => _isLoading = true);
      if (!_mockMode) {
        final uri = Uri.parse('$apiBase/profile/name');
        final resp = await http
            .post(
              uri,
              headers: {'Content-Type': 'application/json'},
              body: json.encode({'displayName': newName}),
            )
            .timeout(const Duration(seconds: 3));
        if (resp.statusCode != 200) {
          throw Exception('Failed to save name ${resp.body}');
        }
      } else {
        await saveUserProfile({'name': newName});
      }
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Profile updated')));
      }
    } catch (e) {
      if (kDebugMode && !_mockMode) {
        if (mounted) setState(() => _mockMode = true);
        await saveUserProfile({'name': _nameController.text.trim()});
        if (mounted) {
          setState(() => _isLoading = false);
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Profile updated (mock)')),
          );
        }
      } else {
        if (mounted) {
          setState(() => _isLoading = false);
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text('Failed to update name: $e')));
        }
      }
    }
  }

  Future<void> _loadProfileFromApi() async {
    try {
      final uri = Uri.parse('$apiBase/profile');
      final resp = await http.get(uri).timeout(const Duration(seconds: 3));
      if (resp.statusCode != 200) throw Exception('Failed to load profile');
      final body = json.decode(resp.body);
      if (mounted) {
        setState(() {
          _nameController.text = body['displayName'] ?? '';
          _photoUrl = body['photoURL'];
        });
      }
    } catch (e) {
      if (kDebugMode) {
        final mock = await fetchUserProfile();
        if (mounted) {
          setState(() {
            _mockMode = true;
            _nameController.text = mock['name'] ?? '';
            _photoUrl = mock['photoURL'] ?? 'https://via.placeholder.com/150';
          });
        }
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
            if (_mockMode)
              Align(
                alignment: Alignment.centerLeft,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: Theme.of(
                      context,
                    ).colorScheme.secondary.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: Theme.of(context).colorScheme.secondary,
                    ),
                  ),
                  child: Text(
                    'Mock mode',
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.secondary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
            const SizedBox(height: 8),
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
