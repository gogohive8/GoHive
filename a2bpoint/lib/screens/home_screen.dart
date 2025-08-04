import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:ionicons/ionicons.dart';
import 'package:like_button/like_button.dart';
import 'package:provider/provider.dart';
import 'package:video_player/video_player.dart';
import '../models/post.dart';
import '../services/api_services.dart';
import '../services/post_service.dart';
import '../services/exceptions.dart';
import '../providers/auth_provider.dart';
import '../screens/post_detail_screen.dart';
import 'navbar.dart';
import 'dart:developer' as developer;

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
  final PostService _postService = PostService();
  late TabController _tabController;
  final Map<String, VideoPlayerController> _videoControllers = {};
  List<Post> _goals = [];
  List<Post> _events = [];
  bool _isLoading = true;
  String? _error;

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

  void _checkAuthAndFetchPosts() async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);

    if (!authProvider.isInitialized) {
      developer.log('AuthProvider not initialized, waiting for initialization',
          name: 'HomeScreen');
      try {
        await authProvider.initialize();
        if (mounted) {
          _fetchPosts(authProvider);
        }
      } catch (e) {
        developer.log('Auth initialization error: $e', name: 'HomeScreen');
        if (mounted) {
          setState(() {
            _isLoading = false;
            _error = 'Authentication failed: $e';
          });
        }
      }
    } else {
      developer.log('AuthProvider initialized, fetching posts',
          name: 'HomeScreen');
      _fetchPosts(authProvider);
    }
  }

  void _fetchPosts(AuthProvider authProvider) async {
    if (!authProvider.isAuthenticated ||
        authProvider.userId == null ||
        authProvider.token == null) {
      developer.log('No token or userId, handling auth error',
          name: 'HomeScreen');
      if (mounted) {
        setState(() {
          _isLoading = false;
          _error = 'Not authenticated';
        });
      }
      return;
    }

    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      developer.log(
          'Fetching posts with token: ${authProvider.token!.substring(0, 20)}...',
          name: 'HomeScreen');

      final goals = await _postService.getAllGoals(
          authProvider.token!, authProvider.userId!);
      final events = await _postService.getAllEvents(
          authProvider.token!, authProvider.userId!);

      developer.log('Fetched ${goals.length} goals and ${events.length} events',
          name: 'HomeScreen');

      if (mounted) {
        setState(() {
          _goals = goals;
          _events = events;
          _isLoading = false;
        });
      }
    } catch (e) {
      developer.log('Fetch posts error: $e', name: 'HomeScreen');
      if (mounted) {
        setState(() {
          _isLoading = false;
          _error = e.toString();
        });
      }
    }
  }

  void _handleTabSelection() {
    if (_tabController.index != _selectedTabIndex) {
      setState(() {
        _selectedTabIndex = _tabController.index;
      });
    }
  }

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
    final routes = ['/home', '/search', '/add', '/profile', '/ai-mentor'];
    Navigator.pushReplacementNamed(context, routes[index]);
  }

  Widget _buildMediaWidget(Post post) {
    if (post.imageUrls == null || post.imageUrls!.isEmpty) {
      return const SizedBox.shrink();
    }

    // ИСПРАВЛЕНО: очистка URL от квадратных скобок и лишних символов
    String cleanUrl = post.imageUrls![0];

    // Убираем квадратные скобки если они есть
    if (cleanUrl.startsWith('[') && cleanUrl.endsWith(']')) {
      cleanUrl = cleanUrl.substring(1, cleanUrl.length - 1);
    }

    // Убираем лишние пробелы
    cleanUrl = cleanUrl.trim();

    // Дополнительная проверка на валидность URL
    if (!cleanUrl.startsWith('http://') && !cleanUrl.startsWith('https://')) {
      developer.log('Invalid URL format: $cleanUrl', name: 'HomeScreen');
      return Container(
        height: 200,
        color: Colors.grey[300],
        child: const Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.broken_image, size: 50, color: Colors.grey),
            SizedBox(height: 8),
            Text('Invalid image URL', style: TextStyle(color: Colors.grey)),
          ],
        ),
      );
    }

    developer.log('Loading cleaned media: $cleanUrl', name: 'HomeScreen');

    final isVideo = cleanUrl.toLowerCase().endsWith('.mp4') ||
        cleanUrl.toLowerCase().endsWith('.mov') ||
        cleanUrl.toLowerCase().endsWith('.avi');

    if (isVideo) {
      if (!_videoControllers.containsKey(post.id)) {
        _videoControllers[post.id] =
            VideoPlayerController.networkUrl(Uri.parse(cleanUrl))
              ..initialize().then((_) {
                if (mounted) setState(() {});
              });
      }
      final controller = _videoControllers[post.id]!;
      return controller.value.isInitialized
          ? Stack(
              alignment: Alignment.center,
              children: [
                AspectRatio(
                  aspectRatio: controller.value.aspectRatio,
                  child: VideoPlayer(controller),
                ),
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
          : Container(
              height: 200,
              child: const Center(child: CircularProgressIndicator()),
            );
    }

    return CachedNetworkImage(
      imageUrl: cleanUrl, // Используем очищенный URL
      height: 200,
      width: double.infinity,
      fit: BoxFit.cover,
      placeholder: (context, url) => Container(
        height: 200,
        child: const Center(child: CircularProgressIndicator()),
      ),
      errorWidget: (context, url, error) {
        developer.log('Image load error: $error for URL: $cleanUrl',
            name: 'HomeScreen');
        return Container(
          height: 200,
          color: Colors.grey[300],
          child: const Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.broken_image, size: 50, color: Colors.grey),
              SizedBox(height: 8),
              Text('Image not available', style: TextStyle(color: Colors.grey)),
            ],
          ),
        );
      },
      httpHeaders: const {
        'User-Agent': 'Flutter App',
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
                const SizedBox(height: 16),
                Expanded(
                  child: ListView(
                    children: [
                      _buildChallengeCard(
                        title: 'The "Tidy Up" Challenge',
                        description:
                            '7-day live challenge\nfor those who are tired',
                        imageAsset: 'assets/images/tidy_challenge.png',
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => ChallengeFullScreen(
                                title: 'The "Tidy Up" Challenge',
                                subtitle:
                                    'Start cleaning up and stay organized!',
                                tasks: [
                                  [
                                    TaskItem(
                                        title: 'Clean your desk',
                                        description: 'Make space to think.'),
                                    TaskItem(
                                        title: 'Organize the shelf',
                                        description:
                                            'Books, boxes, everything.'),
                                    TaskItem(
                                        title: 'Clean your desk',
                                        description: 'Make space to think.'),
                                    TaskItem(
                                        title: 'Organize the shelf',
                                        description:
                                            'Books, boxes, everything.'),
                                    TaskItem(
                                        title: 'Clean your desk',
                                        description: 'Make space to think.'),
                                    TaskItem(
                                        title: 'Organize the shelf',
                                        description:
                                            'Books, boxes, everything.'),
                                  ],
                                  [
                                    TaskItem(
                                        title: 'Fold your clothes',
                                        description: 'Sort and put them away.'),
                                  ],
                                  [
                                    TaskItem(
                                        title: 'Clean your desk',
                                        description: 'Make space to think.'),
                                    TaskItem(
                                        title: 'Organize the shelf',
                                        description:
                                            'Books, boxes, everything.'),
                                  ],
                                  [
                                    TaskItem(
                                        title: 'Fold your clothes',
                                        description: 'Sort and put them away.'),
                                  ],
                                  [
                                    TaskItem(
                                        title: 'Clean your desk',
                                        description: 'Make space to think.'),
                                    TaskItem(
                                        title: 'Organize the shelf',
                                        description:
                                            'Books, boxes, everything.'),
                                  ],
                                  [
                                    TaskItem(
                                        title: 'Fold your clothes',
                                        description: 'Sort and put them away.'),
                                  ],
                                  [
                                    TaskItem(
                                        title: 'Clean your desk',
                                        description: 'Make space to think.'),
                                    TaskItem(
                                        title: 'Organize the shelf',
                                        description:
                                            'Books, boxes, everything.'),
                                  ]
                                ],
                              ),
                            ),
                          );
                        },
                      ),
                      _buildChallengeCard(
                        title: 'The "Moon" Challenge',
                        description:
                            '7-day live challenge\nfor those who are tired',
                        imageAsset: 'assets/images/moon_challenge.png',
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => ChallengeFullScreen(
                                title: 'The "Moon" Challenge',
                                subtitle:
                                    'Start cleaning up and stay organized!',
                                tasks: [
                                  [
                                    TaskItem(
                                        title: 'Clean your desk',
                                        description: 'Make space to think.'),
                                    TaskItem(
                                        title: 'Organize the shelf',
                                        description:
                                            'Books, boxes, everything.'),
                                  ],
                                  [
                                    TaskItem(
                                        title: 'Fold your clothes',
                                        description: 'Sort and put them away.'),
                                  ],
                                  [
                                    TaskItem(
                                        title: 'Clean your desk',
                                        description: 'Make space to think.'),
                                    TaskItem(
                                        title: 'Organize the shelf',
                                        description:
                                            'Books, boxes, everything.'),
                                  ],
                                  [
                                    TaskItem(
                                        title: 'Fold your clothes',
                                        description: 'Sort and put them away.'),
                                  ],
                                  [
                                    TaskItem(
                                        title: 'Clean your desk',
                                        description: 'Make space to think.'),
                                    TaskItem(
                                        title: 'Organize the shelf',
                                        description:
                                            'Books, boxes, everything.'),
                                  ],
                                  [
                                    TaskItem(
                                        title: 'Fold your clothes',
                                        description: 'Sort and put them away.'),
                                  ],
                                  [
                                    TaskItem(
                                        title: 'Clean your desk',
                                        description: 'Make space to think.'),
                                    TaskItem(
                                        title: 'Organize the shelf',
                                        description:
                                            'Books, boxes, everything.'),
                                  ]
                                ],
                              ),
                            ),
                          );
                        },
                      ),
                      _buildChallengeCard(
                        title: 'The "Animal" Challenge',
                        description:
                            '7-day live challenge\nfor those who are tired',
                        imageAsset: 'assets/images/animal_challenge.png',
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => ChallengeFullScreen(
                                title: 'The "Animal" Challenge',
                                subtitle:
                                    'Start cleaning up and stay organized!',
                                tasks: [
                                  [
                                    TaskItem(
                                        title: 'Clean your desk',
                                        description: 'Make space to think.'),
                                    TaskItem(
                                        title: 'Organize the shelf',
                                        description:
                                            'Books, boxes, everything.'),
                                  ],
                                  [
                                    TaskItem(
                                        title: 'Fold your clothes',
                                        description: 'Sort and put them away.'),
                                  ],
                                  [
                                    TaskItem(
                                        title: 'Clean your desk',
                                        description: 'Make space to think.'),
                                    TaskItem(
                                        title: 'Organize the shelf',
                                        description:
                                            'Books, boxes, everything.'),
                                  ],
                                  [
                                    TaskItem(
                                        title: 'Fold your clothes',
                                        description: 'Sort and put them away.'),
                                  ],
                                  [
                                    TaskItem(
                                        title: 'Clean your desk',
                                        description: 'Make space to think.'),
                                    TaskItem(
                                        title: 'Organize the shelf',
                                        description:
                                            'Books, boxes, everything.'),
                                  ],
                                  [
                                    TaskItem(
                                        title: 'Fold your clothes',
                                        description: 'Sort and put them away.'),
                                  ],
                                  [
                                    TaskItem(
                                        title: 'Clean your desk',
                                        description: 'Make space to think.'),
                                    TaskItem(
                                        title: 'Organize the shelf',
                                        description:
                                            'Books, boxes, everything.'),
                                  ]
                                ],
                              ),
                            ),
                          );
                        },
                      ),
                      _buildChallengeCard(
                        title: 'The "Dance" Challenge',
                        description:
                            '7-day live challenge\nfor those who are tired',
                        imageAsset: 'assets/images/dance_challenge.png',
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => ChallengeFullScreen(
                                title: 'The "Dance" Challenge',
                                subtitle:
                                    'Start cleaning up and stay organized!',
                                tasks: [
                                  [
                                    TaskItem(
                                        title: 'Clean your desk',
                                        description: 'Make space to think.'),
                                    TaskItem(
                                        title: 'Organize the shelf',
                                        description:
                                            'Books, boxes, everything.'),
                                  ],
                                  [
                                    TaskItem(
                                        title: 'Fold your clothes',
                                        description: 'Sort and put them away.'),
                                  ],
                                  [
                                    TaskItem(
                                        title: 'Clean your desk',
                                        description: 'Make space to think.'),
                                    TaskItem(
                                        title: 'Organize the shelf',
                                        description:
                                            'Books, boxes, everything.'),
                                  ],
                                  [
                                    TaskItem(
                                        title: 'Fold your clothes',
                                        description: 'Sort and put them away.'),
                                  ],
                                  [
                                    TaskItem(
                                        title: 'Clean your desk',
                                        description: 'Make space to think.'),
                                    TaskItem(
                                        title: 'Organize the shelf',
                                        description:
                                            'Books, boxes, everything.'),
                                  ],
                                  [
                                    TaskItem(
                                        title: 'Fold your clothes',
                                        description: 'Sort and put them away.'),
                                  ],
                                  [
                                    TaskItem(
                                        title: 'Clean your desk',
                                        description: 'Make space to think.'),
                                    TaskItem(
                                        title: 'Organize the shelf',
                                        description:
                                            'Books, boxes, everything.'),
                                  ]
                                ],
                              ),
                            ),
                          );
                        },
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

  Widget _buildChallengeCard({
    required String title,
    required String description,
    required String imageAsset,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 8),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          children: [
            Expanded(
              flex: 2,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title,
                      style: const TextStyle(
                          fontSize: 18, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  Text(description,
                      style: const TextStyle(
                          fontSize: 14, color: Color(0xFF666666))),
                ],
              ),
            ),
            const SizedBox(width: 16),
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                image: DecorationImage(
                    image: AssetImage(imageAsset), fit: BoxFit.cover),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<bool> _onLikeButtonTapped(String postId, bool isLiked) async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final userId = authProvider.userId ?? '';
    final token = authProvider.token ?? '';

    if (userId.isEmpty || token.isEmpty) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Please login to like posts')),
        );
      }
      return isLiked;
    }

    try {
      if (!isLiked) {
        await _postService.likePost(postId, userId, token);
        setState(() {
          if (_selectedTabIndex == 0) {
            _goals = _goals.map((post) {
              if (post.id == postId) {
                return post.copyWith(numOfLikes: post.numOfLikes + 1);
              }
              return post;
            }).toList();
          } else if (_selectedTabIndex == 1) {
            _events = _events.map((post) {
              if (post.id == postId) {
                return post.copyWith(numOfLikes: post.numOfLikes + 1);
              }
              return post;
            }).toList();
          }
        });
      }
      return !isLiked;
    } catch (e) {
      developer.log('Like post error: $e', name: 'HomeScreen');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to like post: $e')),
        );
      }
      return isLiked;
    }
  }

  void _joinEvent(String eventId, String eventText) async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    if (!authProvider.isAuthenticated ||
        authProvider.token == null ||
        authProvider.userId == null) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Please login to join events')),
        );
      }
      return;
    }

    try {
      developer.log('Joining event: eventId=$eventId', name: 'HomeScreen');
      await _postService.joinEvent(
          eventId, authProvider.userId!, authProvider.token!);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Joined $eventText')),
        );
      }
    } catch (e) {
      developer.log('Join event error: $e', name: 'HomeScreen');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to join event: $e')),
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
                  'Challenge',
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
          _buildPostsView(type: 'goal', posts: _goals),
          _buildPostsView(type: 'event', posts: _events),
          _buildMissionsView(),
        ],
      ),
      bottomNavigationBar: Navbar(
        selectedIndex: _selectedIndex,
        onTap: _onItemTapped,
      ),
    );
  }

  Widget _buildPostsView({required String type, required List<Post> posts}) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_error != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline, size: 64, color: Colors.red[300]),
            const SizedBox(height: 16),
            Text(
              'Error loading $type',
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(
              _error!,
              textAlign: TextAlign.center,
              style: const TextStyle(color: Colors.grey),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () => _fetchPosts(
                  Provider.of<AuthProvider>(context, listen: false)),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFAFCBEA),
                foregroundColor: const Color(0xFF000000),
              ),
              child: const Text('Retry'),
            ),
          ],
        ),
      );
    }

    if (posts.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.inbox, size: 64, color: Colors.grey[400]),
            const SizedBox(height: 16),
            Text(
              'No $type to display',
              style: TextStyle(fontSize: 18, color: Colors.grey[600]),
            ),
            const SizedBox(height: 8),
            Text(
              'Be the first to create a ${type.toLowerCase()}!',
              style: TextStyle(color: Colors.grey[500]),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: () async =>
          _fetchPosts(Provider.of<AuthProvider>(context, listen: false)),
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: posts.length,
        itemBuilder: (context, index) {
          final post = posts[index];
          return Card(
            color: const Color(0xFFDDDDDD),
            elevation: 2,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            margin: const EdgeInsets.symmetric(vertical: 8),
            child: GestureDetector(
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) =>
                        PostDetailScreen(postId: post.id, postType: type),
                  ),
                );
              },
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        CircleAvatar(
                          backgroundImage: post.user.profileImage.isNotEmpty
                              ? NetworkImage(post.user.profileImage)
                              : null,
                          backgroundColor: const Color(0xFF333333),
                          radius: 20,
                          child: post.user.profileImage.isEmpty
                              ? Text(
                                  post.user.username.isNotEmpty
                                      ? post.user.username[0].toUpperCase()
                                      : 'U',
                                  style: const TextStyle(color: Colors.white),
                                )
                              : null,
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                post.user.username.isNotEmpty
                                    ? post.user.username
                                    : 'Unknown User',
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: Color(0xFF000000),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    _buildMediaWidget(post),
                    const SizedBox(height: 12),
                    Text(
                      post.text ?? 'No description',
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
                        'Tasks',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF000000),
                        ),
                      ),
                      ...post.tasks!.map((task) => Container(
                            margin: const EdgeInsets.only(bottom: 4),
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 6,
                            ),
                            decoration: BoxDecoration(
                              color: const Color(0xFFF9F6F2),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              task.title, // Changed from task['title']?.toString() ?? 'Untitled task'
                              style: const TextStyle(
                                color: Color(0xFF333333),
                                fontSize: 12,
                              ),
                            ),
                          )),
                    ],
                    const SizedBox(height: 12),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            Text(
                              '${post.numOfLikes} likes',
                              style: const TextStyle(color: Color(0xFF000000)),
                            ),
                            const SizedBox(width: 8),
                            Text(
                              '${post.numComments} comments',
                              style: const TextStyle(color: Color(0xFF000000)),
                            ),
                          ],
                        ),
                        if (type == 'goal')
                          LikeButton(
                            onTap: (isLiked) =>
                                _onLikeButtonTapped(post.id, isLiked),
                            size: 25,
                            circleColor: const CircleColor(
                                start: Color(0xffFFC0CB),
                                end: Color(0xffff0000)),
                            bubblesColor: const BubblesColor(
                              dotPrimaryColor: Color(0xffFFA500),
                              dotSecondaryColor: Color(0xffd8392b),
                              dotThirdColor: Color(0xffFF69B4),
                              dotLastColor: Color(0xffff8c00),
                            ),
                            likeBuilder: (isLiked) {
                              return Icon(
                                isLiked
                                    ? Ionicons.heart
                                    : Ionicons.heart_outline,
                                color: isLiked
                                    ? Colors.red
                                    : const Color(0xFF333333),
                                size: 25,
                              );
                            },
                          )
                        else
                          ElevatedButton(
                            onPressed: () =>
                                _joinEvent(post.id, post.text ?? ''),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFFAFCBEA),
                              foregroundColor: const Color(0xFF000000),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                            ),
                            child: const Text('Join'),
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
      ..arcToPoint(Offset(size.width, radius),
          radius: Radius.circular(radius), clockwise: false)
      ..lineTo(size.width, size.height - radius)
      ..arcToPoint(Offset(size.width - radius, size.height),
          radius: Radius.circular(radius), clockwise: false)
      ..lineTo(radius, size.height)
      ..arcToPoint(Offset(0, size.height - radius),
          radius: Radius.circular(radius), clockwise: false)
      ..lineTo(0, radius)
      ..arcToPoint(Offset(radius, 0),
          radius: Radius.circular(radius), clockwise: false)
      ..close();
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class ChallengeFullScreen extends StatelessWidget {
  final String title;
  final String subtitle;
  final List<List<TaskItem>> tasks;

  const ChallengeFullScreen({
    Key? key,
    required this.title,
    required this.subtitle,
    required this.tasks,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;

    final horizontalMargin = size.width * 0.04; // ~4% от ширины экрана
    final verticalMargin = size.height * 0.015;

    return DefaultTabController(
      length: tasks.length,
      child: Scaffold(
        backgroundColor: const Color(0xFFF2F1EC),
        body: SafeArea(
          child: Column(
            children: [
              // Верхняя панель
              Container(
                width: double.infinity,
                padding: EdgeInsets.only(
                  top: size.height * 0.015,
                  left: size.width * 0.04,
                  right: size.width * 0.04,
                  bottom: size.height * 0.014,
                ),
                decoration: BoxDecoration(
                  color: Color(0xFFFFFFFF),
                  borderRadius: BorderRadius.circular(60),
                ),
                child: Stack(
                  children: [
                    Positioned(
                      top: 0,
                      right: 20,
                      child: Image.asset(
                        'assets/challenge_title.png',
                        width: 160,
                        height: size.height * 0.21,
                        fit: BoxFit.contain,
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.only(top: 0.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const BackButton(color: Color(0xFF222220)),
                          const SizedBox(height: 8),
                          Padding(
                            padding: const EdgeInsets.only(right: 100.0),
                            child: Text(
                              title,
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontFamily: 'Inter',
                                color: const Color(0xFF222220),
                                fontSize: size.width * 0.075,
                              ),
                              softWrap: true,
                              overflow: TextOverflow.visible,
                            ),
                          ),
                          const SizedBox(height: 12),
                          Container(
                            margin: EdgeInsets.symmetric(
                              horizontal: horizontalMargin,
                              vertical: verticalMargin,
                            ),
                            decoration: BoxDecoration(
                              color: const Color(0xFFF0EFEA),
                              borderRadius: BorderRadius.circular(40),
                            ),
                            padding: EdgeInsets.symmetric(
                              horizontal: size.width * 0.03,
                              vertical: size.height * 0.0001,
                            ),
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(
                                  40), // обязательно такой же
                              child: TabBar(
                                dividerColor: Colors.transparent,
                                isScrollable: true,
                                indicator: BoxDecoration(
                                  color: const Color(0xFFFDFDFD),
                                  borderRadius: BorderRadius.circular(24),
                                ),
                                indicatorColor: Colors.transparent,
                                indicatorSize: TabBarIndicatorSize.tab,
                                physics: const ClampingScrollPhysics(),
                                labelPadding: const EdgeInsets.symmetric(
                                    horizontal: 12, vertical: 0),
                                labelColor: const Color(0xFF222220),
                                unselectedLabelColor: const Color(0xFF676767),
                                labelStyle: const TextStyle(
                                    fontWeight: FontWeight.bold),
                                tabs: List.generate(
                                  tasks.length,
                                  (index) => Tab(text: 'Day ${index + 1}'),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              Padding(
                padding: const EdgeInsets.only(
                    left: 26.0, top: 16.0, right: 55, bottom: 5),
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        'The challenge begins',
                        style: const TextStyle(
                          fontFamily: 'TT Norms Pro Trial',
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: const Color(0xFF222220),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Start completing tasks and checking them off. You\'ll do great!',
                        style: const TextStyle(
                          fontFamily: 'TT Norms Pro Trial',
                          fontSize: 19,
                          color: const Color(0xFF222220),
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              // 🔽 Контент задач
              Expanded(
                child: TabBarView(
                  children: List.generate(
                    tasks.length,
                    (dayIndex) => Padding(
                      padding: const EdgeInsets.all(16),
                      child: ListView.builder(
                        itemCount: tasks[dayIndex].length,
                        itemBuilder: (context, taskIndex) {
                          final task = tasks[dayIndex][taskIndex];
                          return _buildTaskCard(task, size);
                        },
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTaskCard(TaskItem task, Size size) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Column(
            children: [
              Container(
                width: 24,
                height: 20,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: const Color(0xFFBDBBB9), width: 6),
                  color: task.isCompleted ? Colors.blue : Colors.white,
                ),
                child: task.isCompleted
                    ? const Icon(Icons.check, color: Colors.black, size: 16)
                    : null,
              ),
              Container(
                width: 2,
                height: 70,
                color: const Color(0xFFBDBBB9),
              ),
            ],
          ),
          const SizedBox(width: 12),
          // Основной контейнер с задачей
          Expanded(
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: const [
                  BoxShadow(
                    color: Colors.black12,
                    blurRadius: 4,
                    offset: Offset(0, 2),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    task.title,
                    style: TextStyle(
                      fontSize: size.width * 0.045,
                      fontWeight: FontWeight.w600,
                      color: const Color(0xFF1D1B20),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    task.description,
                    style: TextStyle(
                      fontSize: size.width * 0.04,
                      color: const Color(0xFF222220),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class TaskItem {
  final String title;
  final String description;
  final bool isCompleted;

  TaskItem(
      {required this.title,
      required this.description,
      this.isCompleted = false});
}
