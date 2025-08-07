import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:loading_overlay/loading_overlay.dart';
import 'package:image_picker/image_picker.dart';
import '../../providers/auth_provider.dart';
import '../../services/api_services.dart';
import '../../services/post_service.dart';
import '../navbar.dart';
import 'personaldatascreen.dart'; // Исправлено на правильное имя файла

class ProfileEditScreen extends StatefulWidget {
  const ProfileEditScreen({super.key});

  @override
  _ProfileEditScreenState createState() => _ProfileEditScreenState();
}

class _ProfileEditScreenState extends State<ProfileEditScreen> {
  bool _isLoading = false;
  File? _newAvatar;
  final ApiService _apiService = ApiService();
  final PostService _postService = PostService();
  
  // Настройки уведомлений (локальное состояние)
  bool _notificationsEnabled = true;

  @override
  void dispose() {
    _apiService.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    final img = await ImagePicker().pickImage(source: ImageSource.gallery);
    if (img != null) {
      setState(() => _newAvatar = File(img.path));
      await _updateAvatar();
    }
  }

  Future<void> _updateAvatar() async {
    final auth = Provider.of<AuthProvider>(context, listen: false);
    if (auth.userId == null || auth.token == null || _newAvatar == null) return;

    setState(() => _isLoading = true);
    try {
      String photoURL = await _postService.uploadMedia(_newAvatar!, auth.token!);
      
      await _apiService.updateProfile(
        auth.userId!,
        auth.token!,
        {},
        photoURL,
      );

      await auth.updateProfile(
        auth.username ?? '',
        auth.bio ?? '',
        auth.email ?? '',
        _newAvatar,
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Profile photo updated successfully'),
            backgroundColor: Color(0xFF5F93E6),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error updating photo: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _showComingSoon(String feature) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('$feature - Coming Soon!'),
        backgroundColor: const Color(0xFF5F93E6),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final auth = Provider.of<AuthProvider>(context);

    if (!auth.isInitialized) {
      return const Scaffold(
        backgroundColor: Color(0xFFF4F3EE),
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return LoadingOverlay(
      isLoading: _isLoading,
      progressIndicator: const CircularProgressIndicator(
        valueColor: AlwaysStoppedAnimation(Color(0xFF5F93E6)),
      ),
      child: Scaffold(
        backgroundColor: const Color(0xFFF4F3EE),
        appBar: AppBar(
          backgroundColor: const Color(0xFFF4F3EE),
          elevation: 0,
          title: const Text(
            'Profile',
            style: TextStyle(
              color: Colors.black,
              fontSize: 18,
              fontWeight: FontWeight.w600,
            ),
          ),
          centerTitle: true,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back, color: Colors.black),
            onPressed: () => Navigator.pop(context),
          ),
          actions: [
            IconButton(
              icon: const Icon(Icons.message, color: Colors.black), // Заменено на стандартную иконку
              onPressed: () => _showComingSoon('Messages'),
            ),
          ],
        ),
        body: SingleChildScrollView(
          child: Column(
            children: [
              const SizedBox(height: 20),
              
              // Профильное фото
              Center(
                child: GestureDetector(
                  onTap: _pickImage,
                  child: Stack(
                    alignment: Alignment.bottomRight,
                    children: [
                      CircleAvatar(
                        radius: 50,
                        backgroundImage: _newAvatar != null
                            ? FileImage(_newAvatar!)
                            : (auth.avatarUrl != null && auth.avatarUrl!.isNotEmpty
                                ? NetworkImage(auth.avatarUrl!)
                                : const AssetImage('assets/images/default_avatar.png'))
                            as ImageProvider,
                      ),
                      Container(
                        padding: const EdgeInsets.all(6),
                        decoration: const BoxDecoration(
                          shape: BoxShape.circle,
                          color: Color(0xFF5F93E6),
                        ),
                        child: const Icon(
                          Icons.camera_alt,
                          size: 16,
                          color: Colors.white,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              
              const SizedBox(height: 40),
              
              // Секция "Personal data"
              Container(
                margin: const EdgeInsets.symmetric(horizontal: 20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Personal data',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: Colors.grey,
                      ),
                    ),
                    const SizedBox(height: 15),
                    
                    _buildMenuItem(
                      title: 'My data',
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const PersonalDataScreen(),
                          ),
                        );
                      },
                    ),
                    
                    _buildMenuItem(
                      title: 'Restore Purchases',
                      onTap: () => _showComingSoon('Restore Purchases'),
                    ),
                    
                    _buildMenuItem(
                      title: 'Interests',
                      onTap: () => _showComingSoon('Interests'),
                    ),
                    
                    const SizedBox(height: 30),
                    
                    // Секция "Additional settings"
                    const Text(
                      'Additional settings',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: Colors.grey,
                      ),
                    ),
                    const SizedBox(height: 15),
                    
                    _buildToggleItem(
                      title: 'Notification',
                      value: _notificationsEnabled,
                      onChanged: (value) {
                        setState(() {
                          _notificationsEnabled = value;
                        });
                        // Здесь можно добавить логику сохранения настройки
                      },
                    ),
                    
                    const SizedBox(height: 30),
                    
                    // Секция "Basic principles"
                    const Text(
                      'Basic principles',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: Colors.grey,
                      ),
                    ),
                    const SizedBox(height: 15),
                    
                    _buildMenuItem(
                      title: 'Terms and conditions of use',
                      onTap: () => _showComingSoon('Terms and conditions'),
                    ),
                    
                    _buildMenuItem(
                      title: 'Privacy policy',
                      onTap: () => _showComingSoon('Privacy policy'),
                    ),
                    
                    _buildMenuItem(
                      title: 'Cookie policy',
                      onTap: () => _showComingSoon('Cookie policy'),
                    ),
                    
                    const SizedBox(height: 40),
                  ],
                ),
              ),
            ],
          ),
        ),
        bottomNavigationBar: Navbar(
          selectedIndex: 3,
          onTap: (index) {
            final routes = ['/home', '/search', '/add', '/profile', '/ai-mentor'];
            Navigator.pushReplacementNamed(context, routes[index]);
          },
        ),
      ),
    );
  }

  Widget _buildMenuItem({
    required String title,
    required VoidCallback onTap,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 5),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(8),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w400,
                    color: Colors.black,
                  ),
                ),
                const Icon(
                  Icons.chevron_right,
                  color: Colors.grey,
                  size: 24,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildToggleItem({
    required String title,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 5),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 0),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              title,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w400,
                color: Colors.black,
              ),
            ),
            Switch(
              value: value,
              onChanged: onChanged,
              activeColor: const Color(0xFF5F93E6),
              inactiveThumbColor: Colors.grey,
              inactiveTrackColor: Colors.grey.shade300,
            ),
          ],
        ),
      ),
    );
  }
}