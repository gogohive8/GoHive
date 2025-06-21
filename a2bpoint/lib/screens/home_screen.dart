import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'dart:developer' as developer;
import '../providers/auth_provider.dart';
import '../services/api_services.dart';
import '../models/post.dart';
import 'navbar.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final ApiService _apiService = ApiService();
  List<Post> _goals = [];
  List<Post> _events = [];
  bool _isLoading = true;
  int _selectedTab = 0;

  @override
  void initState() {
    super.initState();
    _checkAuth();
    _loadPosts();
  }

  @override
  void dispose() {
    _apiService.dispose();
    super.dispose();
  }

  Future<void> _checkAuth() async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    await authProvider.initialize();
    if (authProvider.shouldRedirectTo()) {
      Navigator.pushReplacementNamed(context, '/sign_in');
    } else if (authProvider.isFirstLogin) {
      Navigator.pushReplacementNamed(context, '/welcome');
    }
  }

  Future<void> _loadPosts() async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    if (!authProvider.isAuthenticated ||
        authProvider.token == null ||
        authProvider.userId == null) {
      setState(() => _isLoading = false);
      return;
    }

    try {
      developer.log('Loading posts for userId=${authProvider.userId}',
          name: 'HomeScreen');
      final goals = await _apiService.getAllGoals(
          authProvider.token!, authProvider.userId!);
      final events = await _apiService.getAllEvents(
          authProvider.token!, authProvider.userId!);
      if (mounted) {
        setState(() {
          _goals = goals;
          _events = events;
          _isLoading = false;
        });
      }
    } catch (e, stackTrace) {
      developer.log('Load posts error: $e',
          name: 'HomeScreen', stackTrace: stackTrace);
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading posts: $e')),
        );
      }
    }
  }

  Future<void> _likePost(String postId) async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    if (!authProvider.isAuthenticated || authProvider.token == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please log in to like posts')),
      );
      return;
    }

    try {
      await _apiService.likePost(postId, authProvider.token!);
      _loadPosts();
    } catch (e, stackTrace) {
      developer.log('Like post error: $e',
          name: 'HomeScreen', stackTrace: stackTrace);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error liking post: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    return Scaffold(
      backgroundColor: const Color(0xFFF9F6F2),
      appBar: AppBar(
        backgroundColor: const Color(0xFFF9F6F2),
        elevation: 0,
        title: const Text(
          'GoHive',
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: Color(0xFF1A1A1A),
          ),
        ),
        actions: [
          IconButton(
            icon: Image.asset('assets/images/messages_icon.png', height: 24),
            onPressed: () {},
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                Padding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  child: Row(
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
                ),
                Expanded(
                  child: _selectedTab == 0
                      ? _buildPostList(_goals)
                      : _buildPostList(_events),
                ),
              ],
            ),
      bottomNavigationBar: Navbar(
        selectedIndex: 0,
        onTap: (index) {
          final routes = ['/home', '/search', '/add', '/profile', '/ai-mentor'];
          Navigator.pushReplacementNamed(context, routes[index]);
        },
      ),
    );
  }

  Widget _buildPostList(List<Post> posts) {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
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
                Row(
                  children: [
                    const CircleAvatar(
                      backgroundColor: Color(0xFF333333),
                      child: Icon(
                        Icons.person,
                        color: Color(0xFFF9F6F2),
                        size: 20,
                      ),
                      radius: 20,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            post.username,
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF000000),
                            ),
                          ),
                          Text(
                            post.createdAt.toString().split(' ')[0],
                            style: const TextStyle(
                              fontSize: 12,
                              color: Color(0xFF333333),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
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
                    IconButton(
                      icon: const Icon(Icons.favorite_border,
                          color: Color(0xFF333333)),
                      onPressed: () => _likePost(post.id),
                    ),
                    Text(
                      '${post.numOfLikes}',
                      style: const TextStyle(color: Color(0xFF1A1A1A)),
                    ),
                    const SizedBox(width: 16),
                    if (post.type == 'event' && post.dateTime != null)
                      Text(
                        post.dateTime!,
                        style: const TextStyle(
                          fontSize: 12,
                          color: Color(0xFF333333),
                        ),
                      ),
                  ],
                ),
                if (post.type == 'goal' && post.tasks != null)
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: 8),
                      Text(
                        'Tasks: ${post.tasks!.where((task) => task['completed'] ?? false).length}/${post.tasks!.length}',
                        style: const TextStyle(
                          fontSize: 12,
                          color: Color(0xFF333333),
                        ),
                      ),
                    ],
                  ),
              ],
            ),
          ),
        );
      },
    );
  }
}
