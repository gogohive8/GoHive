import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:loading_overlay/loading_overlay.dart';
import 'package:image_picker/image_picker.dart';
import '../providers/auth_provider.dart';
import '../services/api_services.dart';
import '../screens/navbar.dart';

class ProfileEditScreen extends StatefulWidget {
  const ProfileEditScreen({super.key});

  @override
  _ProfileEditScreenState createState() => _ProfileEditScreenState();
}

class _ProfileEditScreenState extends State<ProfileEditScreen> {
  final _formKey = GlobalKey<FormState>();
  final _usernameController = TextEditingController();
  final _bioController = TextEditingController();
  bool _isLoading = false;
  File? _newAvatar;
  final ApiService _apiService = ApiService();

  @override
  void initState() {
    super.initState();
    final auth = Provider.of<AuthProvider>(context, listen: false);
    _usernameController.text = auth.username ?? '';
    _bioController.text = auth.bio ?? '';
  }

  @override
  void dispose() {
    _usernameController.dispose();
    _bioController.dispose();
    _apiService.dispose();
    super.dispose();
  }

  String? _validateUsername(String? val) {
    if (val == null || val.trim().isEmpty) return 'Username is required';
    if (val.trim().length < 3) return 'Minimum 3 characters';
    return null;
  }

  Future<void> _pickImage() async {
    final img = await ImagePicker().pickImage(source: ImageSource.gallery);
    if (img != null) {
      setState(() => _newAvatar = File(img.path));
    }
  }

  Future<void> _save() async {
  if (!_formKey.currentState!.validate()) return;

  final auth = Provider.of<AuthProvider>(context, listen: false);
  if (auth.userId == null || auth.token == null) {
    auth.handleAuthError(context, 'Authentication required');
    return;
  }

  setState(() => _isLoading = true);
  try {
    String? photoURL;
    if (_newAvatar != null) {
      photoURL = await _apiService.uploadMedia(_newAvatar!, auth.token!);
    }

    final data = {
      'username': _usernameController.text.trim(),
      'bio': _bioController.text.trim(),
      if (photoURL != null) 'avatarUrl': photoURL,
    };

    await _apiService.updateProfile(
      auth.userId!,
      auth.token!,
      data,
      photoURL ?? '',
    );

    await auth.updateProfile(
      _usernameController.text.trim(),
      _bioController.text.trim(),
      auth.email ?? '',
      _newAvatar,
    );

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Profile updated successfully'),
          backgroundColor: Color(0xFFAFCBEA),
        ),
      );
      Navigator.pop(context);
    }
  } catch (e) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error updating profile: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  } finally {
    if (mounted) setState(() => _isLoading = false);
  }
}

  @override
  Widget build(BuildContext context) {
    final sw = MediaQuery.of(context).size.width;
    final sh = MediaQuery.of(context).size.height;
    final auth = Provider.of<AuthProvider>(context);

    if (!auth.isInitialized) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return LoadingOverlay(
      isLoading: _isLoading,
      progressIndicator: const CircularProgressIndicator(
        valueColor: AlwaysStoppedAnimation(Color(0xFFAFCBEA)),
      ),
      child: Scaffold(
        backgroundColor: const Color(0xFFF9F6F2),
        appBar: AppBar(
          backgroundColor: const Color(0xFFF9F6F2),
          elevation: 0,
          title: Text(
            'Edit Profile',
            style: TextStyle(
              color: const Color(0xFF1A1A1A),
              fontSize: sw * 0.05,
            ),
          ),
          centerTitle: true,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back, color: Color(0xFF1A1A1A)),
            onPressed: () => Navigator.pop(context),
          ),
          actions: [
            TextButton(
              onPressed: _isLoading ? null : _save,
              child: Text(
                'SAVE',
                style: TextStyle(color: const Color(0xFFAFCBEA)),
              ),
            ),
          ],
        ),
        body: SingleChildScrollView(
          padding: EdgeInsets.symmetric(horizontal: sw * 0.04),
          child: Form(
            key: _formKey,
            autovalidateMode: AutovalidateMode.onUserInteraction,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SizedBox(height: sh * 0.04),
                Center(
                  child: GestureDetector(
                    onTap: _pickImage,
                    child: Stack(
                      alignment: Alignment.bottomRight,
                      children: [
                        CircleAvatar(
                          radius: sw * 0.15,
                          backgroundImage: _newAvatar != null
                              ? FileImage(_newAvatar!)
                              : (auth.avatarUrl != null &&
                                          auth.avatarUrl!.isNotEmpty
                                      ? NetworkImage(auth.avatarUrl!)
                                      : const AssetImage(
                                          'assets/images/default_avatar.png'))
                                  as ImageProvider,
                        ),
                        Container(
                          padding: EdgeInsets.all(6),
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: const Color(0xFFAFCBEA),
                          ),
                          child: const Icon(Icons.camera_alt,
                              size: 20, color: Colors.white),
                        ),
                      ],
                    ),
                  ),
                ),
                SizedBox(height: sh * 0.03),
                Text(
                  'Username',
                  style: TextStyle(
                      fontSize: sw * 0.04, fontWeight: FontWeight.bold),
                ),
                SizedBox(height: sh * 0.01),
                TextFormField(
                  controller: _usernameController,
                  decoration: InputDecoration(
                    prefixIcon: const Icon(Icons.person_outline,
                        color: Color(0xFFAFCBEA)),
                    filled: true,
                    fillColor: const Color(0xFFDDDDDD),
                    border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8)),
                  ),
                  validator: _validateUsername,
                  enabled: !_isLoading,
                ),
                SizedBox(height: sh * 0.03),
                Text(
                  'Bio',
                  style: TextStyle(
                      fontSize: sw * 0.04, fontWeight: FontWeight.bold),
                ),
                SizedBox(height: sh * 0.01),
                TextFormField(
                  controller: _bioController,
                  decoration: InputDecoration(
                    filled: true,
                    fillColor: const Color(0xFFDDDDDD),
                    border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8)),
                  ),
                  maxLines: 4,
                  enabled: !_isLoading,
                ),
                SizedBox(height: sh * 0.05),
              ],
            ),
          ),
        ),
        bottomNavigationBar: Navbar(selectedIndex: 3, onTap: (_) {}),
      ),
    );
  }
}