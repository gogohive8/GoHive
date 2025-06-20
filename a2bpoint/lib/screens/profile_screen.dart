import 'dart:convert';
import 'dart:developer' as developer;
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import 'dart:io';
import '../providers/auth_provider.dart';
import '../services/api_services.dart';
import '../models/post.dart';
import 'navbar.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  _ProfileScreenState createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final ApiService _apiService = ApiService();
  Map<String, dynamic>? _profile;
  List<Post> _goals = [];
  List<Post> _events = [];
  bool _isLoading = true;
  final _bioController = TextEditingController();
  int _selectedTab = 0;

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  @override
  void dispose() {
    _bioController.dispose();
    _apiService.dispose();
    super.dispose();
  }

  Future<void> _loadProfile() async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final userId = authProvider.userId ?? '';
    final token = authProvider.token ?? '';

    if (userId.isEmpty || token.isEmpty) {
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please log in to view your profile')),
      );
      return;
    }

    try {
      developer.log('Loading profile for userId=$userId',
          name: 'ProfileScreen');
      final profile = await _apiService.getProfile(userId, token);
      final goals = await _apiService.getGoals(userId, token);
      final events = await _apiService.getEvents(userId, token);

      if (mounted) {
        setState(() {
          _profile = profile;
          _goals = goals;
          _events = events;
          _bioController.text = profile?['bio'] ?? '';
          _isLoading = false;
        });
      }
    } catch (e, stackTrace) {
      developer.log('Load profile error: $e',
          name: 'ProfileScreen', stackTrace: stackTrace);
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading profile: $e')),
        );
      }
    }
  }

  Future<void> _updateBio() async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final userId = authProvider.userId ?? '';
    final token = authProvider.token ?? '';

    if (_bioController.text.isEmpty || userId.isEmpty || token.isEmpty) return;

    try {
      developer.log('Updating bio for userId=$userId', name: 'ProfileScreen');
      final success =
          await _apiService.updateBio(userId, _bioController.text, token);
      if (success && mounted) {
        setState(() {
          _profile?['bio'] = _bioController.text;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Bio updated successfully')),
        );
      }
    } catch (e, stackTrace) {
      developer.log('Update bio error: $e',
          name: 'ProfileScreen', stackTrace: stackTrace);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error updating bio: $e')),
        );
      }
    }
  }

  Future<void> _uploadAvatar() async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: ImageSource.gallery);

    if (pickedFile == null) return;

    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final userId = authProvider.userId ?? '';
    final token = authProvider.token ?? '';

    if (userId.isEmpty || token.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please log in to upload an avatar')),
      );
      return;
    }

    try {
      developer.log('Uploading avatar for userId=$userId',
          name: 'ProfileScreen');
      final urls =
          await _apiService.uploadImages(userId, [pickedFile.path], token);
      if (urls.isNotEmpty && mounted) {
        setState(() {
          _profile?['avatar_url'] = urls.first;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Avatar updated successfully')),
        );
      }
    } catch (e, stackTrace) {
      developer.log('Upload avatar error: $e',
          name: 'ProfileScreen', stackTrace: stackTrace);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error uploading avatar: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF9F6F2), // Светло-бежевый фон
      appBar: AppBar(
        backgroundColor: const Color(0xFFF9F6F2),
        elevation: 0,
        title: Text(
          _profile?['username'] ?? 'Unknown',
          style: const TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: Color(0xFF1A1A1A), // Тёмно-серый
          ),
        ),
        actions: [
          IconButton(
            icon: Image.asset('assets/images/messages_icon.png', height: 24),
            onPressed: () {}, // Заглушка для сообщений
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _profile == null
              ? const Center(child: Text('Failed to load profile'))
              : LayoutBuilder(
                  builder: (context, constraints) {
                    final screenWidth = constraints.maxWidth;
                    final avatarRadius =
                        screenWidth * 0.15 > 50 ? 50.0 : screenWidth * 0.15;
                    final gridCrossAxisCount =
                        screenWidth > 600 ? 3 : (screenWidth > 400 ? 2 : 1);

                    return ConstrainedBox(
                      constraints: BoxConstraints(
                          maxHeight: MediaQuery.of(context).size.height -
                              kToolbarHeight -
                              kBottomNavigationBarHeight),
                      child: SingleChildScrollView(
                        padding: EdgeInsets.all(screenWidth * 0.03),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.start,
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Stack(
                                  alignment: Alignment.center,
                                  children: [
                                    CircleAvatar(
                                      radius: avatarRadius,
                                      backgroundImage: _profile?[
                                                      'avatar_url'] !=
                                                  null &&
                                              _profile?['avatar_url'].isNotEmpty
                                          ? NetworkImage(
                                              _profile!['avatar_url'])
                                          : const AssetImage(
                                              'assets/images/default_avatar.png'),
                                      backgroundColor:
                                          const Color(0xFF333333), // Серый
                                    ),
                                    Positioned(
                                      bottom: -avatarRadius * 0.2,
                                      right: -avatarRadius * 0.2,
                                      child: IconButton(
                                        icon: const Icon(Icons.camera_alt,
                                            color:
                                                Color(0xFFAFCBEA)), // Голубой
                                        onPressed: _uploadAvatar,
                                        padding:
                                            EdgeInsets.all(avatarRadius * 0.1),
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(width: 16),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        _profile?['username'] ?? 'Unknown',
                                        style: TextStyle(
                                          fontSize: screenWidth * 0.05 > 20
                                              ? 20.0
                                              : screenWidth * 0.05,
                                          fontWeight: FontWeight.bold,
                                          color: const Color(
                                              0xFF1A1A1A), // Тёмно-серый
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        '${_profile?['followers'] ?? 0} followers  ${_profile?['following'] ?? 0} following',
                                        style: const TextStyle(
                                          fontSize: 12,
                                          color: Color(0xFF333333), // Серый
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 16),
                            TextFormField(
                              controller: _bioController,
                              decoration: InputDecoration(
                                filled: true,
                                fillColor: const Color.fromRGBO(249, 246, 242,
                                    0.9), // Схожий с фоном с прозрачностью
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(8),
                                  borderSide: const BorderSide(
                                      color: Color(0xFFAFCBEA)), // Голубой
                                ),
                                focusedBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(8),
                                  borderSide: const BorderSide(
                                      color: Color(0xFFAFCBEA)),
                                ),
                                suffixIcon: IconButton(
                                  icon: const Icon(Icons.edit,
                                      color: Color(0xFFAFCBEA)), // Голубой
                                  onPressed: _updateBio,
                                ),
                              ),
                              maxLines: 1,
                              style: const TextStyle(
                                fontSize: 14,
                                color: Color(0xFF1A1A1A), // Тёмно-серый
                              ),
                            ),
                            const SizedBox(height: 20),
                            GridView.builder(
                              shrinkWrap: true,
                              physics: const NeverScrollableScrollPhysics(),
                              gridDelegate:
                                  SliverGridDelegateWithFixedCrossAxisCount(
                                crossAxisCount: gridCrossAxisCount,
                                crossAxisSpacing: screenWidth * 0.02,
                                mainAxisSpacing: screenWidth * 0.02,
                                childAspectRatio: 0.9,
                              ),
                              itemCount: _selectedTab == 0
                                  ? _goals.length
                                  : _events.length,
                              clipBehavior: Clip.hardEdge,
                              itemBuilder: (context, index) {
                                final post = _selectedTab == 0
                                    ? _goals[index]
                                    : _events[index];
                                final createdAt = post.createdAt
                                    .toLocal()
                                    .toString()
                                    .split(' ')[0];
                                return Container(
                                  decoration: BoxDecoration(
                                    color:
                                        const Color(0xFFDDDDDD), // Светло-серый
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Stack(
                                    children: [
                                      Padding(
                                        padding: const EdgeInsets.all(8.0),
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          mainAxisAlignment:
                                              MainAxisAlignment.spaceBetween,
                                          children: [
                                            Text(
                                              createdAt,
                                              style: const TextStyle(
                                                fontSize: 12,
                                                color:
                                                    Color(0xFF333333), // Серый
                                              ),
                                            ),
                                            Text(
                                              post.text ?? 'No description',
                                              style: const TextStyle(
                                                fontSize: 12,
                                                color: Color(
                                                    0xFF1A1A1A), // Тёмно-серый
                                              ),
                                              maxLines: 2,
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                          ],
                                        ),
                                      ),
                                      if (_selectedTab == 0 &&
                                          post.tasks != null)
                                        Positioned(
                                          bottom: 4,
                                          right: 4,
                                          child: Container(
                                            padding: const EdgeInsets.all(4),
                                            color: const Color(
                                                0xFF333333), // Серый
                                            child: Text(
                                              '${post.tasks!.where((task) => task['completed'] ?? false).length}/${post.tasks!.length}',
                                              style: const TextStyle(
                                                fontSize: 10,
                                                color: Color(
                                                    0xFFF9F6F2), // Светло-бежевый
                                              ),
                                            ),
                                          ),
                                        ),
                                    ],
                                  ),
                                );
                              },
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
      bottomNavigationBar: Navbar(
        selectedIndex: 3,
        onTap: (index) {
          final routes = ['/home', '/search', '/add', '/profile', '/ai-mentor'];
          Navigator.pushReplacementNamed(context, routes[index]);
        },
      ),
    );
  }
}
