import 'dart:developer' as developer;
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:video_player/video_player.dart';
import '../models/post.dart';
import '../services/api_services.dart';
import '../services/exceptions.dart';
import '../providers/auth_provider.dart';
import '../providers/posts_provider.dart';
import 'navbar.dart';
import 'post_detail_screen.dart';

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
  final Map<String, VideoPlayerController> _videoControllers = {};
  final Set<String> _likedPosts = {};

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _tabController.addListener(_handleTabSelection);
    _checkAuthAndFetchPosts();
  }

  @override
  void dispose() {
    _tabController.removeListener(_handleTabSelection);
    _videoControllers.forEach((_, controller) => controller.dispose());
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
    developer.log('Token: $token, UserId: $userId', name: 'HomeScreen');
    if (token.isEmpty || userId.isEmpty) {
      developer.log('No token or userId, skipping fetch', name: 'HomeScreen');
      setState(() {
        _postsFuture = Future.value(<String, List<Post>>{});
      });
      return;
    }
    developer.log('Fetching posts: tabIndex=$_selectedTabIndex, userId=$userId',
        name: 'HomeScreen');
    _postsFuture = (_selectedTabIndex == 0
            ? _apiService.getAllGoals(token, userId)
            : _selectedTabIndex == 1
                ? _apiService.getAllEvents(token, userId)
                : Future<List<Post>>.value([])) // Заглушка для миссий
        .then((value) => _groupPostsByUser(value as List<Post>))
        .catchError((e, stackTrace) {
      developer.log('Fetch posts error: $e',
          name: 'HomeScreen', stackTrace: stackTrace);
      authProvider.handleAuthError(context, e);
      return <String, List<Post>>{};
    }) as Future<Map<String, List<Post>>>;
  }

  Future<Map<String, List<Post>>> _groupPostsByUser(List<Post> posts) async {
    final Map<String, List<Post>> groupedPosts = {};
    for (var post in posts) {
      final userId = post.user.id.isEmpty ? 'unknown' : post.user.id;
      developer.log(
          'Processing post: id=${post.id}, userId=$userId, username=${post.user.username}',
          name: 'HomeScreen');
      if (!groupedPosts.containsKey(userId)) {
        groupedPosts[userId] = [];
      }
      groupedPosts[userId]!.add(post);
    }
    developer.log(
        'Grouped posts: ${groupedPosts.length} users, total posts: ${posts.length}',
        name: 'HomeScreen');
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
    final postsProvider = Provider.of<PostsProvider>(context, listen: false);
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
          postsProvider.likePost(postId, false, currentLikes);
        } else {
          _likedPosts.add(postId);
          postsProvider.likePost(postId, true, currentLikes);
        }
      });
    } catch (e, stackTrace) {
      developer.log('Like post error: $e',
          name: 'HomeScreen', stackTrace: stackTrace);
      authProvider.handleAuthError(context, e);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Ошибка лайка: $e')),
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
        SnackBar(content: Text('Вы присоединились к $eventText')),
      );
    } catch (e, stackTrace) {
      developer.log('Join event error: $e',
          name: 'HomeScreen', stackTrace: stackTrace);
      authProvider.handleAuthError(context, e);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Ошибка присоединения: $e')),
      );
    }
  }

  Widget _buildMediaWidget(Post post) {
    if (post.imageUrls == null || post.imageUrls!.isEmpty) {
      return const SizedBox.shrink();
    }
    final url = post.imageUrls![0];
    final isVideo = url.endsWith('.mp4') || url.endsWith('.mov');
    if (isVideo) {
      if (!_videoControllers.containsKey(post.id)) {
        _videoControllers[post.id] =
            VideoPlayerController.networkUrl(Uri.parse(url))
              ..initialize().then((_) => setState(() {}));
      }
      final controller = _videoControllers[post.id]!;
      return controller.value.isInitialized
          ? Stack(
              alignment: Alignment.center,
              children: [
                VideoPlayer(controller),
                IconButton(
                  icon: Icon(
                    controller.value.isPlaying ? Icons.pause : Icons.play_arrow,
                    color: Colors.white,
                    size: 50,
                  ),
                  onPressed: () {
                    setState(() {
                      controller.value.isPlaying
                          ? controller.pause()
                          : controller.play();
                    });
                  },
                ),
              ],
            )
          : const Center(child: CircularProgressIndicator());
    }
    return ListView.builder(
      scrollDirection: Axis.horizontal,
      itemCount: post.imageUrls!.length,
      itemBuilder: (context, imgIndex) {
        return Padding(
          padding: const EdgeInsets.only(right: 8),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: Image.network(
              post.imageUrls![imgIndex],
              width: 200,
              height: 200,
              fit: BoxFit.cover,
              errorBuilder: (context, error, stackTrace) {
                developer.log('Image load error: $error', name: 'HomeScreen');
                return const Icon(Icons.broken_image, size: 100);
              },
            ),
          ),
        );
      },
    );
  }

  Widget _buildMissionsView() {
    final size = MediaQuery.of(context).size;
    final padding = size.width * 0.05;
    final aspectRatio = 375 / 790;
    final containerHeight = size.width / aspectRatio;

    return Center(
      child: SizedBox(
        width: size.width * 0.9,
        height: containerHeight * 0.9,
        child: CustomPaint(
          painter: MissionsBackgroundPainter(),
          child: Padding(
            padding: EdgeInsets.all(padding),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Миссии',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF000000),
                  ),
                ),
                const SizedBox(height: 16),
                Expanded(
                  child: ListView(
                    children: [
                      Card(
                        color: const Color(0xFFDDDDDD),
                        elevation: 2,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        margin: const EdgeInsets.symmetric(vertical: 8),
                        child: ListTile(
                          title: const Text('Миссия 1: Пройти 10 км'),
                          subtitle: const Text('Награда: 50 баллов'),
                        ),
                      ),
                      Card(
                        color: const Color(0xFFDDDDDD),
                        elevation: 2,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        margin: const EdgeInsets.symmetric(vertical: 8),
                        child: ListTile(
                          title: const Text('Миссия 2: Прочитать книгу'),
                          subtitle: const Text('Награда: 30 баллов'),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
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
                  'Цели',
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
                  'События',
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
            const SizedBox(width: 8),
            GestureDetector(
              onTap: () => _tabController.animateTo(2),
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: _selectedTabIndex == 2
                      ? const Color.fromRGBO(175, 203, 234, 0.1)
                      : Colors.transparent,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  'Миссии',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: _selectedTabIndex == 2
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
          _buildPostsView(type: 'goal'),
          _buildPostsView(type: 'event'),
          _buildMissionsView(),
        ],
      ),
      bottomNavigationBar: Navbar(
        selectedIndex: _selectedIndex,
        onTap: _onItemTapped,
      ),
    );
  }

  Widget _buildPostsView({required String type}) {
    return FutureBuilder<Map<String, List<Post>>>(
      future: _postsFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snapshot.hasError) {
          developer.log('Snapshot error: ${snapshot.error}',
              name: 'HomeScreen', stackTrace: snapshot.stackTrace);
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text('Ошибка загрузки $type: ${snapshot.error}'),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: _fetchPosts,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFAFCBEA),
                    foregroundColor: const Color(0xFF000000),
                  ),
                  child: const Text('Повторить'),
                ),
              ],
            ),
          );
        }
        final groupedPosts = snapshot.data ?? {};
        final totalPosts = groupedPosts.values
            .fold<int>(0, (sum, posts) => sum + posts.length);
        _postsFuture.then((posts) {
          developer.log(
              'Raw posts before grouping: ${posts.values.expand((p) => p).length}',
              name: 'HomeScreen');
        });
        developer.log(
            'Displaying $type posts: ${groupedPosts.length} users, $totalPosts posts',
            name: 'HomeScreen');
        return RefreshIndicator(
          onRefresh: () async {
            _fetchPosts();
            await _postsFuture;
          },
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (groupedPosts.isEmpty)
                  Center(child: Text('Нет $type для отображения'))
                else
                  ...groupedPosts.entries.map((entry) {
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
                                'Rendering $type[$index]: id=${post.id}, text=${post.text}, tasks=${post.tasks?.length ?? 0}',
                                name: 'HomeScreen');
                            final isLiked = _likedPosts.contains(post.id);
                            return GestureDetector(
                              onTap: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) =>
                                        PostDetailScreen(post: post),
                                  ),
                                );
                              },
                              child: Card(
                                color: const Color(0xFFDDDDDD),
                                elevation: 2,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                margin: const EdgeInsets.symmetric(vertical: 8),
                                child: Padding(
                                  padding: const EdgeInsets.all(12),
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        children: [
                                          CircleAvatar(
                                            backgroundImage:
                                                post.user.avatarUrl.isNotEmpty
                                                    ? NetworkImage(
                                                        post.user.avatarUrl)
                                                    : null,
                                            backgroundColor:
                                                const Color(0xFF333333),
                                            radius: 20,
                                            child: post.user.avatarUrl.isEmpty
                                                ? Text(
                                                    post.user.username[0]
                                                        .toUpperCase(),
                                                    style: const TextStyle(
                                                        color: Colors.white),
                                                  )
                                                : null,
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
                                                      .split('.')[0],
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
                                      const SizedBox(height: 12),
                                      if (post.imageUrls != null &&
                                          post.imageUrls!.isNotEmpty)
                                        SizedBox(
                                          height: 200,
                                          child: _buildMediaWidget(post),
                                        ),
                                      const SizedBox(height: 12),
                                      Text(
                                        post.text ?? 'Описание отсутствует',
                                        style: const TextStyle(
                                          fontSize: 16,
                                          color: Color(0xFF1A1A1A),
                                        ),
                                      ),
                                      if (type == 'goal' &&
                                          post.tasks != null &&
                                          post.tasks!.isNotEmpty) ...[
                                        const SizedBox(height: 12),
                                        const Text(
                                          'Задачи',
                                          style: TextStyle(
                                            fontSize: 14,
                                            fontWeight: FontWeight.bold,
                                            color: Color(0xFF000000),
                                          ),
                                        ),
                                        ...post.tasks!.map((task) => Padding(
                                              padding:
                                                  const EdgeInsets.symmetric(
                                                      vertical: 4),
                                              child: Text(
                                                task['title']?.toString() ??
                                                    'Без названия',
                                                style: const TextStyle(
                                                    color: Color(0xFF333333)),
                                              ),
                                            )),
                                      ],
                                      const SizedBox(height: 12),
                                      Row(
                                        mainAxisAlignment:
                                            MainAxisAlignment.spaceBetween,
                                        children: [
                                          Row(
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
                                                    color: Color(0xFF000000)),
                                              ),
                                              const SizedBox(width: 16),
                                              IconButton(
                                                icon: const Icon(
                                                  Icons.comment,
                                                  color: Color(0xFF333333),
                                                ),
                                                onPressed: () {
                                                  Navigator.push(
                                                    context,
                                                    MaterialPageRoute(
                                                      builder: (context) =>
                                                          PostDetailScreen(
                                                              post: post),
                                                    ),
                                                  );
                                                },
                                              ),
                                              Text(
                                                '${post.numComments}',
                                                style: const TextStyle(
                                                    color: Color(0xFF000000)),
                                              ),
                                            ],
                                          ),
                                          if (type == 'event')
                                            ElevatedButton(
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
                                              child:
                                                  const Text('Присоединиться'),
                                            ),
                                        ],
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            );
                          },
                        ),
                      ],
                    );
                  }).toList(),
              ],
            ),
          ),
        );
      },
    );
  }
}

class MissionsBackgroundPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = const Color(0xFFF4F3EE);
    final radius = 32.0;
    final path = Path()
      ..moveTo(radius, 0)
      ..lineTo(size.width - radius, 0)
      ..arcToPoint(Offset(size.width, radius), radius: Radius.circular(radius), clockwise: false)
      ..lineTo(size.width, size.height - radius)
      ..arcToPoint(Offset(size.width - radius, size.height), radius: Radius.circular(radius), clockwise: false)
      ..lineTo(radius, size.height)
      ..arcToPoint(Offset(0, size.height - radius), radius: Radius.circular(radius), clockwise: false)
      ..lineTo(0, radius)
      ..arcToPoint(Offset(radius, 0), radius: Radius.circular(radius), clockwise: false)
      ..close();
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}