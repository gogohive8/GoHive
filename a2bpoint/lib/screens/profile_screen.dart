import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'dart:developer' as developer;
import '../providers/auth_provider.dart';
import '../services/api_services.dart';
import '../models/post.dart';
import 'navbar.dart';
import '../services/exceptions.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  _ProfileScreenState createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final ApiService _apiService = ApiService();
  List<Post> _goals = [];
  List<Post> _events = [];
  bool _isLoading = true;
  int _selectedTab = 0;
  String? _bio;
  bool _isEditingBio = false;
  final TextEditingController _bioController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _checkAuth();
    _loadProfile();
  }

  @override
  void dispose() {
    _apiService.dispose();
    _bioController.dispose();
    super.dispose();
  }

  Future<void> _checkAuth() async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    await authProvider.initialize();
    if (authProvider.shouldRedirectTo()) {
      Navigator.pushReplacementNamed(context, '/sign-in');
    }
  }

  Future<void> _loadProfile() async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final userId = authProvider.userId ?? '';
    final token = authProvider.token ?? '';

    if (userId.isEmpty || token.isEmpty) {
      authProvider.handleAuthError(
          context, AuthenticationException('Not authenticated'));
      setState(() => _isLoading = false);
      return;
    }

    try {
      developer.log('Loading profile for userId=${authProvider.userId}',
          name: 'ProfileScreen');
      final profileData = await _apiService.getProfile(
          authProvider.userId!, authProvider.token!);
      final goals =
          await _apiService.getGoals(authProvider.userId!, authProvider.token!);
      final events = await _apiService.getEvents(
          authProvider.userId!, authProvider.token!);
      if (mounted) {
        setState(() {
          _bio = profileData?['bio']?.toString() ?? authProvider.bio;
          _bioController.text = _bio ?? '';
          _goals = goals;
          _events = events;
          _isLoading = false;
        });
      }
    } catch (e, stackTrace) {
      developer.log('Load profile error: $e',
          name: 'ProfileScreen', stackTrace: stackTrace);
      if (mounted) {
        authProvider.handleAuthError(context, e);
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Ошибка загрузки профиля: $e')),
        );
      }
    }
  }

  Future<void> _updateBio() async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    if (!authProvider.isAuthenticated ||
        authProvider.token == null ||
        authProvider.userId == null) {
      authProvider.handleAuthError(
          context, AuthenticationException('Not authenticated'));
      return;
    }

    try {
      final success = await _apiService.updateBio(
          authProvider.userId!, _bioController.text, authProvider.token!);
      if (success && mounted) {
        authProvider.setBio(_bioController.text);
        setState(() {
          _bio = _bioController.text;
          _isEditingBio = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Bio updated successfully')),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to update bio')),
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

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);
    if (!authProvider.isInitialized) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }
    return Scaffold(
      backgroundColor: const Color(0xFFF9F6F2),
      appBar: AppBar(
        backgroundColor: const Color(0xFFF9F6F2),
        elevation: 0,
        title: Text(
          authProvider.username ?? 'Profile',
          style: const TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: Color(0xFF1A1A1A),
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout, color: Color(0xFF333333)),
            onPressed: () async {
              await authProvider.logout();
              Navigator.pushReplacementNamed(context, '/sign-in');
            },
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const CircleAvatar(
                          backgroundColor: Color(0xFF333333),
                          child: Icon(
                            Icons.person,
                            color: Color(0xFFF9F6F2),
                            size: 40,
                          ),
                          radius: 40,
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                authProvider.username ?? 'Unknown',
                                style: const TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                  color: Color(0xFF1A1A1A),
                                ),
                              ),
                              const SizedBox(height: 8),
                              _isEditingBio
                                  ? TextField(
                                      controller: _bioController,
                                      maxLines: 3,
                                      decoration: InputDecoration(
                                        hintText: 'Enter your bio',
                                        filled: true,
                                        fillColor: const Color(0xFFDDDDDD),
                                        border: OutlineInputBorder(
                                          borderRadius:
                                              BorderRadius.circular(10),
                                          borderSide: BorderSide.none,
                                        ),
                                      ),
                                      style: const TextStyle(
                                          color: Color(0xFF1A1A1A)),
                                    )
                                  : Text(
                                      _bio ?? 'No bio available',
                                      style: const TextStyle(
                                        fontSize: 16,
                                        color: Color(0xFF333333),
                                      ),
                                    ),
                              const SizedBox(height: 8),
                              TextButton(
                                onPressed: () {
                                  if (_isEditingBio) {
                                    _updateBio();
                                  } else {
                                    setState(() => _isEditingBio = true);
                                  }
                                },
                                child: Text(
                                  _isEditingBio ? 'Save Bio' : 'Edit Bio',
                                  style:
                                      const TextStyle(color: Color(0xFFAFCBEA)),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        GestureDetector(
                          onTap: () => setState(() => _selectedTab = 0),
                          child: Text(
                            'Goals',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: _selectedTab == 0
                                  ? const Color(0xFFAFCBEA)
                                  : const Color(0xFF333333),
                            ),
                          ),
                        ),
                        GestureDetector(
                          onTap: () => setState(() => _selectedTab = 1),
                          child: Text(
                            'Events',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: _selectedTab == 1
                                  ? const Color(0xFFAFCBEA)
                                  : const Color(0xFF333333),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    _selectedTab == 0
                        ? _buildPostList(_goals)
                        : _buildPostList(_events),
                  ],
                ),
              ),
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

  Widget _buildPostList(List<Post> posts) {
    if (posts.isEmpty) {
      return const Center(child: Text('No posts available'));
    }
    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: posts.length,
      itemBuilder: (context, index) {
        final post = posts[index];
        return Card(
          color: const Color(0xFFDDDDDD),
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          margin: const EdgeInsets.only(bottom: 16),
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  post.title ?? 'No title',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF1A1A1A),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  post.text ?? 'No description',
                  style: const TextStyle(
                    fontSize: 14,
                    color: Color(0xFF1A1A1A),
                  ),
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    const Icon(Icons.favorite_border,
                        color: Color(0xFF333333), size: 20),
                    const SizedBox(width: 4),
                    Text(
                      '${post.numOfLikes ?? 0}',
                      style: const TextStyle(color: Color(0xFF1A1A1A)),
                    ),
                    const SizedBox(width: 16),
                    Text(
                      post.createdAt?.toString().split(' ')[0] ?? '',
                      style: const TextStyle(
                        fontSize: 12,
                        color: Color(0xFF333333),
                      ),
                    ),
                  ],
                ),
                if (post.type == 'event' && post.dateTime != null)
                  Padding(
                    padding: const EdgeInsets.only(top: 8.0),
                    child: Text(
                      'Date: ${post.dateTime.toString().split('.')[0]}',
                      style: const TextStyle(
                        fontSize: 12,
                        color: Color(0xFF333333),
                      ),
                    ),
                  ),
                if (post.type == 'goal' && post.tasks != null)
                  Padding(
                    padding: const EdgeInsets.only(top: 8.0),
                    child: Text(
                      'Tasks: ${post.tasks!.where((task) => task['completed'] ?? false).length}/${post.tasks!.length}',
                      style: const TextStyle(
                        fontSize: 12,
                        color: Color(0xFF333333),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        );
      },
    );
  }
}
