import 'dart:convert';
import 'dart:developer' as developer;
import 'package:flutter/foundation.dart';
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
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        toolbarHeight: 0,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _profile == null
              ? const Center(child: Text('Failed to load profile'))
              : Column(
                  children: [
                    Container(
                      height: 80,
                      padding: const EdgeInsets.symmetric(
                          vertical: 10, horizontal: 16),
                      color: Colors.white,
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          GestureDetector(
                            onTap: () => setState(() => _selectedTab = 0),
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 16, vertical: 8),
                              decoration: BoxDecoration(
                                color: _selectedTab == 0
                                    ? Color.fromRGBO(121, 100, 255, 0.1)
                                    : Colors.transparent,
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(
                                'Goals',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: _selectedTab == 0
                                      ? FontWeight.bold
                                      : FontWeight.normal,
                                  color: _selectedTab == 0
                                      ? Colors.purple
                                      : Colors.black,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 16),
                          GestureDetector(
                            onTap: () => setState(() => _selectedTab = 1),
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 16, vertical: 8),
                              decoration: BoxDecoration(
                                color: _selectedTab == 1
                                    ? Color.fromRGBO(121, 100, 255, 0.1)
                                    : Colors.transparent,
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(
                                'Events',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: _selectedTab == 1
                                      ? FontWeight.bold
                                      : FontWeight.normal,
                                  color: _selectedTab == 1
                                      ? Colors.purple
                                      : Colors.black,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    Expanded(
                      child: SingleChildScrollView(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Stack(
                                  alignment: Alignment.center,
                                  children: [
                                    CircleAvatar(
                                      radius: 60,
                                      backgroundImage:
                                          _profile?['avatar_url'] != null &&
                                                  _profile?['avatar_url']
                                                      .isNotEmpty
                                              ? NetworkImage(
                                                  _profile?['avatar_url'])
                                              : null,
                                      child: _profile?['avatar_url'] == null ||
                                              _profile?['avatar_url'].isEmpty
                                          ? const Icon(Icons.person, size: 40)
                                          : null,
                                    ),
                                    Positioned(
                                      bottom: 0,
                                      right: 0,
                                      child: IconButton(
                                        icon: const Icon(Icons.camera_alt,
                                            color: Colors.purple),
                                        onPressed: _uploadAvatar,
                                      ),
                                    ),
                                  ],
                                ),
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.end,
                                  children: [
                                    Text(
                                      _profile?['username'] ?? 'Unknown',
                                      style: const TextStyle(
                                        fontSize: 24,
                                        fontWeight: FontWeight.bold,
                                        color: Color(0xFF1C0E31),
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      '${_profile?['followers'] ?? 0} followers  ${_profile?['following'] ?? 0} following',
                                      style: const TextStyle(
                                        fontSize: 14,
                                        color: Color(0xFF1C0E31),
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                            const SizedBox(height: 16),
                            TextFormField(
                              controller: _bioController,
                              decoration: InputDecoration(
                                labelText: 'Bio',
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                focusedBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(10),
                                  borderSide:
                                      const BorderSide(color: Colors.purple),
                                ),
                                suffixIcon: IconButton(
                                  icon: const Icon(Icons.edit,
                                      color: Colors.purple),
                                  onPressed: _updateBio,
                                ),
                              ),
                              maxLines: 3,
                            ),
                            const SizedBox(height: 20),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.start,
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(8),
                                  decoration: BoxDecoration(
                                    color: Color.fromRGBO(121, 100, 255, 0.1),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: const Row(
                                    children: [
                                      Icon(Icons.emoji_events,
                                          color: Colors.purple),
                                      SizedBox(width: 4),
                                      Text('Challenge winner'),
                                    ],
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Container(
                                  padding: const EdgeInsets.all(8),
                                  decoration: BoxDecoration(
                                    color: Color.fromRGBO(255, 165, 0, 0.1),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: const Row(
                                    children: [
                                      Icon(Icons.check_circle,
                                          color: Colors.orange),
                                      SizedBox(width: 4),
                                      Text('Finished goals'),
                                    ],
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Container(
                                  padding: const EdgeInsets.all(8),
                                  decoration: BoxDecoration(
                                    color: Color.fromRGBO(0, 128, 0, 0.1),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: const Row(
                                    children: [
                                      Icon(Icons.event, color: Colors.green),
                                      SizedBox(width: 4),
                                      Text('Attended'),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 20),
                            GridView.builder(
                              shrinkWrap: true,
                              physics: const NeverScrollableScrollPhysics(),
                              gridDelegate:
                                  const SliverGridDelegateWithFixedCrossAxisCount(
                                crossAxisCount: 3,
                                crossAxisSpacing: 8,
                                mainAxisSpacing: 8,
                                childAspectRatio: 0.9,
                              ),
                              itemCount: _selectedTab == 0
                                  ? _goals.length
                                  : _events.length,
                              itemBuilder: (context, index) {
                                final post = _selectedTab == 0
                                    ? _goals[index]
                                    : _events[index];
                                final createdAt = post.createdAt
                                    .toLocal()
                                    .toString()
                                    .split(' ')[0];
                                return Stack(
                                  children: [
                                    Container(
                                      decoration: BoxDecoration(
                                        borderRadius: BorderRadius.circular(8),
                                        image:
                                            post.imageUrls?.isNotEmpty == true
                                                ? DecorationImage(
                                                    image: NetworkImage(
                                                        post.imageUrls![0]),
                                                    fit: BoxFit.cover,
                                                  )
                                                : null,
                                      ),
                                      child: post.imageUrls?.isNotEmpty != true
                                          ? const Center(
                                              child:
                                                  Icon(Icons.image, size: 40))
                                          : null,
                                    ),
                                    Positioned(
                                      top: 4,
                                      left: 4,
                                      child: Text(
                                        createdAt,
                                        style: const TextStyle(
                                          fontSize: 12,
                                          color: Colors.white,
                                          backgroundColor: Colors.black54,
                                        ),
                                      ),
                                    ),
                                    Positioned(
                                      bottom: 4,
                                      left: 4,
                                      child: Text(
                                        post.text ?? 'No description',
                                        style: const TextStyle(
                                          fontSize: 12,
                                          color: Colors.white,
                                          backgroundColor: Colors.black54,
                                        ),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                    if (_selectedTab == 0 && post.tasks != null)
                                      Positioned(
                                        bottom: 4,
                                        right: 4,
                                        child: Container(
                                          padding: const EdgeInsets.all(4),
                                          color: Colors.black54,
                                          child: Text(
                                            '${post.tasks!.where((task) => task['completed'] ?? false).length}/${post.tasks!.length} tasks',
                                            style: const TextStyle(
                                              fontSize: 10,
                                              color: Colors.white,
                                            ),
                                          ),
                                        ),
                                      ),
                                  ],
                                );
                              },
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
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
