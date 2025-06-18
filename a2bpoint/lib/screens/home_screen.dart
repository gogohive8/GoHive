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
  late Future<List<String>> _categoriesFuture;
  late List<Future<List<Post>>> _postsFutures;
  List<String> _categories = [];

  @override
  void initState() {
    super.initState();
    _categoriesFuture = _apiService.getCategories();
    _categoriesFuture.then((categories) {
      setState(() {
        _categories = categories;
        _tabController = TabController(length: categories.length, vsync: this);
        _tabController.addListener(_handleTabSelection);
        _fetchPostsFutures();
      });
    });
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
        _fetchPostsFutures();
      });
    }
  }

  void _fetchPostsFutures() {
    setState(() {
      _postsFutures = _categories.map((category) {
        return _apiService.getAllGoals(interest: category);
      }).toList();
    });
  }

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
    final routes = ['/home', '/search', '/add', '/profile', '/ai'];
    Navigator.pushReplacementNamed(context, routes[index]);
  }

  void _likePost(
      String postId, int currentLikes, int index, int categoryIndex) async {
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
        _postsFutures[categoryIndex].then((posts) {
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
        SnackBar(content: Text('Joined event: $eventText')),
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
        elevation: 4,
        backgroundColor: Colors.white,
        title: FutureBuilder<List<String>>(
          future: _categoriesFuture,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }
            if (snapshot.hasError) {
              return Center(child: Text('Error: ${snapshot.error}'));
            }
            final categories = snapshot.data ?? [];
            return TabBar(
              controller: _tabController,
              isScrollable: true,
              indicatorColor: Colors.purple,
              tabs: categories.asMap().entries.map((entry) {
                final index = entry.key;
                final category = entry.value;
                return Tab(
                  child: Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: _tabController.index == index
                          ? Colors.purple.withValues(alpha: 0.2)
                          : Colors.transparent,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      category,
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: _tabController.index == index
                            ? Colors.purple
                            : Colors.grey,
                      ),
                    ),
                  ),
                );
              }).toList(),
            );
          },
        ),
        actions: [
          IconButton(
            icon: Image.asset('assets/images/messages_icon.png', height: 24),
            onPressed: () {},
          ),
        ],
      ),
      body: FutureBuilder<List<String>>(
        future: _categoriesFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }
          final categories = snapshot.data ?? [];
          return TabBarView(
            controller: _tabController,
            children: List.generate(categories.length, (categoryIndex) {
              return FutureBuilder<List<Post>>(
                future: _postsFutures[categoryIndex],
                builder: (context, postSnapshot) {
                  if (postSnapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  if (postSnapshot.hasError) {
                    return Center(child: Text('Error: ${postSnapshot.error}'));
                  }
                  final posts = postSnapshot.data ?? [];
                  return SingleChildScrollView(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          categories[categoryIndex],
                          style: const TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: Colors.purple,
                          ),
                        ),
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
                                  backgroundImage:
                                      post.user.avatarUrl.isNotEmpty
                                          ? NetworkImage(post.user.avatarUrl)
                                          : null,
                                  backgroundColor: Colors.grey,
                                ),
                                title: Text(post.text ?? 'No Text'),
                                subtitle: Text(
                                  'by ${post.user.username} • ${post.createdAt.toLocal().toString().split(' ')[0]}',
                                ),
                                trailing: post.type == 'event'
                                    ? ElevatedButton(
                                        onPressed: () => _joinEvent(
                                            post.id, post.text ?? ''),
                                        child: const Text('Join'),
                                      )
                                    : IconButton(
                                        icon: const Icon(Icons.favorite_border),
                                        onPressed: () => _likePost(post.id,
                                            post.likes, index, categoryIndex),
                                      ),
                              ),
                            );
                          },
                        ),
                      ],
                    ),
                  );
                },
              );
            }),
          );
        },
      ),
      bottomNavigationBar: Navbar(
        selectedIndex: _selectedIndex,
        onTap: _onItemTapped,
      ),
    );
  }
}
