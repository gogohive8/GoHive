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
      developer.log('No token found, handling auth error', name: 'HomeScreen');
      authProvider.handleAuthError(
          context, AuthenticationException('Not authenticated'));
    }
  }

  void _handleTabSelection() {
    if (_tabController.index != _selectedTabIndex) {
      setState(() {
        _selectedTabIndex = _tabController.index;
      });
      _fetchPosts();
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

  Future<void> _likePost(String? postId) async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    if (!authProvider.isAuthenticated || authProvider.token == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please log in to like posts')),
      );
      return;
    }
    if (postId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Invalid post ID')),
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
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildPostsView(),
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

  Widget _buildPostsView() {
    return FutureBuilder<Map<String, List<Post>>>(
      future: _postsFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snapshot.hasError) {
          developer.log('Snapshot error: ${snapshot.error}',
              name: 'HomeScreen', stackTrace: snapshot.stackTrace);
          final authProvider =
              Provider.of<AuthProvider>(context, listen: false);
          authProvider.handleAuthError(context, snapshot.error);
          return Center(child: Text('Ошибка загрузки: ${snapshot.error}'));
        }
        final groupedPosts = snapshot.data ?? {};
        if (groupedPosts.isEmpty) {
          developer.log('No posts to display', name: 'HomeScreen');
          return const Center(child: Text('Нет доступных постов'));
        }
        developer.log('Posts data: $groupedPosts', name: 'HomeScreen');
        return SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: groupedPosts.entries.map((entry) {
              final userId = entry.key;
              final posts = entry.value;
              final username =
                  posts.isNotEmpty ? posts[0].user.username : 'Unknown';
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    child: Text(
                      username,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF000000),
                      ),
                    ),
                  ),
                  ListView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: posts.length,
                    itemBuilder: (context, index) {
                      final post = posts[index];
                      developer.log(
                          'Post[$index]: text=${post.text}, id=${post.id}',
                          name: 'HomeScreen');
                      final isLiked = _likedPosts.contains(post.id);
                      return Card(
                        color: const Color(0xFFDDDDDD),
                        elevation: 2,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        margin: const EdgeInsets.symmetric(vertical: 8),
                        child: Padding(
                          padding: const EdgeInsets.all(12),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  CircleAvatar(
                                    backgroundImage:
                                        post.user.avatarUrl.isNotEmpty
                                            ? NetworkImage(post.user.avatarUrl)
                                            : null,
                                    backgroundColor: const Color(0xFF333333),
                                    radius: 20,
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          post.user.username,
                                          style: const TextStyle(
                                            fontWeight: FontWeight.bold,
                                            color: Color(0xFF000000),
                                          ),
                                        ),
                                        Text(
                                          post.createdAt
                                              .toLocal()
                                              .toString()
                                              .split(' ')[0],
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
                                post.text ?? 'No description',
                                style: const TextStyle(
                                  fontSize: 16,
                                  color: Color(0xFF1A1A1A),
                                ),
                              ),
                              const SizedBox(height: 8),
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  _selectedTabIndex == 0
                                      ? Row(
                                          children: [
                                            IconButton(
                                              icon: Icon(
                                                isLiked
                                                    ? Icons.favorite
                                                    : Icons.favorite_border,
                                                color: isLiked
                                                    ? Colors.red
                                                    : const Color(0xFF333333),
                                              ),
                                              onPressed: () => _likePost(
                                                  post.id,
                                                  post.likes,
                                                  userId,
                                                  index),
                                            ),
                                            Text(
                                              '${post.likes}',
                                              style: const TextStyle(
                                                color: Color(0xFF1A1A1A),
                                              ),
                                            ),
                                          ],
                                        )
                                      : ElevatedButton(
                                          onPressed: () => _joinEvent(
                                              post.id, post.text ?? ''),
                                          style: ElevatedButton.styleFrom(
                                            backgroundColor:
                                                const Color(0xFFAFCBEA),
                                            foregroundColor:
                                                const Color(0xFF000000),
                                            shape: RoundedRectangleBorder(
                                              borderRadius:
                                                  BorderRadius.circular(8),
                                            ),
                                          ),
                                          child: const Text('Join'),
                                        ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ],
              );
            }).toList(),
          ),
        );
      },
    );
  }
}
