import 'dart:developer' as developer;
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/post.dart';
import '../services/api_services.dart';
import '../providers/auth_provider.dart';
import 'navbar.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen>
    with SingleTickerProviderStateMixin {
  int _selectedIndex = 0;
  int _selectedTabIndex = 0;
  final ApiService _apiService = ApiService();
  late TabController _tabController;
  late Future<List<Post>> _postsFuture;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _tabController.addListener(_handleTabSelection);
    _fetchPosts();
  }

  @override
  void dispose() {
    _tabController.removeListener(_handleTabSelection);
    _tabController.dispose();
    _apiService.dispose();
    super.dispose();
  }

  void _handleTabSelection() {
    if (_tabController.index != _selectedTabIndex) {
      setState(() {
        _selectedTabIndex = _tabController.index;
      });
      _fetchPosts();
    }
  }

  void _fetchPosts() {
    developer.log('Fetching posts: tabIndex=$_selectedTabIndex',
        name: 'HomeScreen');
    _postsFuture = _selectedTabIndex == 0
        ? _apiService.getAllGoals()
        : _apiService.getAllEvents();
  }

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
    final routes = ['/home', '/search', '/add', '/profile', '/ai-mentor'];
    Navigator.pushReplacementNamed(context, routes[index]);
  }

  void _likePost(String postId, int currentLikes, int index) async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    if (!authProvider.isAuthenticated || authProvider.token == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Authorization required')),
      );
      return;
    }
    try {
      developer.log('Liking post: postId=$postId', name: 'HomeScreen');
      await _apiService.likePost(postId, authProvider.token!);
      setState(() {
        _postsFuture.then((posts) {
          if (index >= 0 && index < posts.length) {
            posts[index].likes = currentLikes + 1;
          }
        });
      });
    } catch (e, stackTrace) {
      developer.log('Like post error: $e',
          name: 'HomeScreen', stackTrace: stackTrace);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error liking post: $e')),
      );
    }
  }

  void _joinEvent(String eventId, String eventText) async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    if (!authProvider.isAuthenticated || authProvider.token == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Authorization required')),
      );
      return;
    }
    try {
      developer.log('Joining event: eventId=$eventId', name: 'HomeScreen');
      await _apiService.joinEvent(eventId, authProvider.token!);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Joined $eventText')),
      );
    } catch (e, stackTrace) {
      developer.log('Join event error: $e',
          name: 'HomeScreen', stackTrace: stackTrace);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error joining event: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.white,
        title: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            GestureDetector(
              onTap: () => _tabController.animateTo(0),
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: _selectedTabIndex == 0
                      ? Colors.purple.withValues(alpha: 0.1)
                      : Colors.transparent,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  'Goals',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: _selectedTabIndex == 0 ? Colors.purple : Colors.grey,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 8),
            GestureDetector(
              onTap: () => _tabController.animateTo(1),
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: _selectedTabIndex == 1
                      ? Colors.purple.withValues(alpha: 0.1)
                      : Colors.transparent,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  'Events',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: _selectedTabIndex == 1 ? Colors.purple : Colors.grey,
                  ),
                ),
              ),
            ),
          ],
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
          FutureBuilder<List<Post>>(
            future: _postsFuture,
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }
              if (snapshot.hasError) {
                return Center(child: Text('Error: ${snapshot.error}'));
              }
              final posts = snapshot.data ?? [];
              return SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 16),
                    ListView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: posts.length,
                      itemBuilder: (context, index) {
                        final post = posts[index];
                        return Card(
                          color: Colors.purple.withValues(alpha: 0.1),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          margin: const EdgeInsets.symmetric(vertical: 8),
                          child: ListTile(
                            leading: CircleAvatar(
                              backgroundImage: post.user.avatarUrl.isNotEmpty
                                  ? NetworkImage(post.user.avatarUrl)
                                  : null,
                              backgroundColor: Colors.grey,
                            ),
                            title: Text(post.text ?? 'No Text'),
                            subtitle: Text(
                              'by ${post.user.username} • ${post.createdAt.toLocal().toString().split(' ')[0]}',
                            ),
                            trailing: IconButton(
                              icon: const Icon(Icons.favorite_border),
                              onPressed: () =>
                                  _likePost(post.id, post.likes, index),
                            ),
                          ),
                        );
                      },
                    ),
                  ],
                ),
              );
            },
          ),
          FutureBuilder<List<Post>>(
            future: _postsFuture,
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }
              if (snapshot.hasError) {
                return Center(child: Text('Error: ${snapshot.error}'));
              }
              final posts = snapshot.data ?? [];
              return SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 16),
                    ListView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: posts.length,
                      itemBuilder: (context, index) {
                        final post = posts[index];
                        return Card(
                          color: Colors.purple.withValues(alpha: 0.1),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          margin: const EdgeInsets.symmetric(vertical: 8),
                          child: ListTile(
                            leading: CircleAvatar(
                              backgroundImage: post.user.avatarUrl.isNotEmpty
                                  ? NetworkImage(post.user.avatarUrl)
                                  : null,
                              backgroundColor: Colors.grey,
                            ),
                            title: Text(post.text ?? 'No Text'),
                            subtitle: Text(
                              'by ${post.user.username} • ${post.createdAt.toLocal().toString().split(' ')[0]}',
                            ),
                            trailing: ElevatedButton(
                              onPressed: () =>
                                  _joinEvent(post.id, post.text ?? ''),
                              child: const Text('Join'),
                            ),
                          ),
                        );
                      },
                    ),
                  ],
                ),
              );
            },
          ),
        ],
      ),
      bottomNavigationBar: Navbar(
        selectedIndex: _selectedIndex,
        onTap: _onItemTapped,
      ),
    );
  }
}
