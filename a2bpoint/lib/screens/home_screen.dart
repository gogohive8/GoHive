import 'dart:developer' as developer;
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/post.dart';
import '../services/api_services.dart';
import '../services/exceptions.dart';
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
  late Future<Map<String, List<Post>>> _postsFuture;
  final Set<String> _likedPosts = {};

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _tabController.addListener(_handleTabSelection);
    _checkAuthAndFetchPosts();
  }

  @override
  void dispose() {
    _tabController.removeListener(_handleTabSelection);
    _tabController.dispose();
    _apiService.dispose();
    super.dispose();
  }

  void _checkAuthAndFetchPosts() {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    if (!authProvider.isInitialized) {
      developer.log('AuthProvider not initialized, waiting for initialization',
          name: 'HomeScreen');
      authProvider.initialize().then((_) {
        if (mounted) {
          _redirectIfNotAuthenticated(authProvider);
          _fetchPosts();
        }
      });
    } else {
      developer.log('AuthProvider initialized, checking authentication',
          name: 'HomeScreen');
      _redirectIfNotAuthenticated(authProvider);
      _fetchPosts();
    }
  }

  void _redirectIfNotAuthenticated(AuthProvider authProvider) {
    if (!authProvider.isInitialized) {
      developer.log('AuthProvider not initialized, skipping redirect',
          name: 'HomeScreen');
      return;
    }
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

  void _fetchPosts() {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final token = authProvider.token ?? '';
    final userId = authProvider.userId ?? '';

    if (token.isEmpty || userId.isEmpty) {
      developer.log('No token or userId, skipping fetch', name: 'HomeScreen');
      setState(() {
        _postsFuture = Future.value({});
      });
      return;
    }
    developer.log('Fetching posts: tabIndex=$_selectedTabIndex',
        name: 'HomeScreen');
    _postsFuture = (_selectedTabIndex == 0
            ? _apiService.getAllGoals(token, userId)
            : _apiService.getAllEvents(token, userId))
        .then(_groupPostsByUser)
        .catchError((e) {
      authProvider.handleAuthError(context, e);
      return <String, List<Post>>{};
    });
  }

  Future<Map<String, List<Post>>> _groupPostsByUser(List<Post> posts) async {
    final Map<String, List<Post>> groupedPosts = {};
    for (var post in posts) {
      final userId = post.user.id;
      if (!groupedPosts.containsKey(userId)) {
        groupedPosts[userId] = [];
      }
      groupedPosts[userId]!.add(post);
    }
    return groupedPosts;
  }

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
    final routes = ['/home', '/search', '/add', '/profile', '/ai-mentor'];
    Navigator.pushReplacementNamed(context, routes[index]);
  }

  void _likePost(
      String postId, int currentLikes, String userId, int index) async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    if (!authProvider.isAuthenticated || authProvider.token == null) {
      authProvider.handleAuthError(
          context, AuthenticationException('Not authenticated'));
      return;
    }
    try {
      developer.log('Liking post: postId=$postId', name: 'HomeScreen');
      await _apiService.likePost(postId, authProvider.token!);
      setState(() {
        if (_likedPosts.contains(postId)) {
          _likedPosts.remove(postId);
          _postsFuture.then((groupedPosts) {
            if (groupedPosts.containsKey(userId)) {
              final posts = groupedPosts[userId]!;
              if (index >= 0 && index < posts.length) {
                posts[index].likes = currentLikes - 1;
              }
            }
          });
        } else {
          _likedPosts.add(postId);
          _postsFuture.then((groupedPosts) {
            if (groupedPosts.containsKey(userId)) {
              final posts = groupedPosts[userId]!;
              if (index >= 0 && index < posts.length) {
                posts[index].likes = currentLikes + 1;
              }
            }
          });
        }
      });
    } catch (e, stackTrace) {
      developer.log('Like post error: $e',
          name: 'HomeScreen', stackTrace: stackTrace);
      authProvider.handleAuthError(context, e);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error liking post: $e')),
      );
    }
  }

  void _joinEvent(String eventId, String eventText) async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    if (!authProvider.isAuthenticated || authProvider.token == null) {
      authProvider.handleAuthError(
          context, AuthenticationException('Not authenticated'));
      return;
    }
    try {
      developer.log('Joining event: eventId=$eventId', name: 'HomeScreen');
      await _apiService.joinEvent(eventId, authProvider.token!);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('You have joined $eventText')),
      );
    } catch (e, stackTrace) {
      developer.log('Join event error: $e',
          name: 'HomeScreen', stackTrace: stackTrace);
      authProvider.handleAuthError(context, e);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error joining event: $e')),
      );
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
        elevation: 0,
        backgroundColor: const Color(0xFFF9F6F2),
        automaticallyImplyLeading: false,
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
                      ? const Color.fromRGBO(175, 203, 234, 0.1)
                      : Colors.transparent,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  'Goals',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: _selectedTabIndex == 0
                        ? const Color(0xFFAFCBEA)
                        : const Color(0xFF1A1A1A),
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
                      ? const Color.fromRGBO(175, 203, 234, 0.1)
                      : Colors.transparent,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  'Events',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: _selectedTabIndex == 1
                        ? const Color(0xFFAFCBEA)
                        : const Color(0xFF1A1A1A),
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
          _buildPostsView(),
        ],
      ),
      bottomNavigationBar: Navbar(
        selectedIndex: _selectedIndex,
        onTap: _onItemTapped,
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
