// screens/home_screen.dart (рефакторенная версия)
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:video_player/video_player.dart';
import '../models/post.dart';
import '../services/api_services.dart';
import '../services/post_service.dart';
import '../providers/auth_provider.dart';
import '../services/notification_service.dart';
import '../screens/navbar.dart';
import '../widgets/home/home_app_bar.dart';
import '../widgets/home/posts_view.dart';
import '../widgets/home/challenge_view.dart';
import 'dart:developer' as developer;
import 'package:jwt_decoder/jwt_decoder.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen>
    with SingleTickerProviderStateMixin {
  // UI состояние
  int _selectedIndex = 0;
  int _selectedTabIndex = 0;
  late TabController _tabController;

  // Сервисы
  final ApiService _apiService = ApiService();
  final PostService _postService = PostService();
  final Map<String, VideoPlayerController> _videoControllers = {};

  // Данные постов
  List<Post> _goals = [];
  List<Post> _events = [];
  bool _isLoading = true;
  String? _error;

  // Пагинация
  static const int _postsPerPage = 20;
  int _goalsOffset = 0;
  int _eventsOffset = 0;
  bool _goalsHasMore = true;
  bool _eventsHasMore = true;
  bool _isLoadingMoreGoals = false;
  bool _isLoadingMoreEvents = false;

  // Состояние вкладок
  bool _goalsLoaded = false;
  bool _eventsLoaded = false;

  // Контроллеры скролла
  final ScrollController _goalsScrollController = ScrollController();
  final ScrollController _eventsScrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _initializeScreen();
    _refreshTokenIfNeeded();
  }

  void _initializeScreen() {
    _tabController = TabController(length: 3, vsync: this);
    _tabController.addListener(_handleTabSelection);

    _goalsScrollController.addListener(_onGoalsScroll);
    _eventsScrollController.addListener(_onEventsScroll);

    _checkAuthAndLoadInitialTab();
    _setupNotifications();
  }

  void _setupNotifications() async {
    _sendFcmToken();
    NotificationService().onTokenRefresh.listen((newToken) async {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final userId = authProvider.userId;
      if (userId != null) {
        await NotificationService().updateToken(userId, newToken);
      }
    });
  }

  Future<void> _sendFcmToken() async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final userId = authProvider.userId;
    if (userId != null) {
      final token = await NotificationService().setupNotifications();
      if (token != null) {
        await NotificationService().updateToken(userId, token);
      }
    }
  }

  Future<void> _refreshTokenIfNeeded() async {
    setState(() => _isLoading = true);
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final accessToken = authProvider.token;
    final refreshToken = authProvider.refreshToken;
    final userId = authProvider.userId; // Assuming user_id is stored

    if (accessToken == null ||
        JwtDecoder.isExpired(accessToken) ||
        userId == null ||
        refreshToken == null) {
      final newToken =
          await _apiService.refreshToken(userId ?? '', refreshToken ?? '');
      if (newToken == null) {
        // Redirect to login screen
        if (mounted) {
          Navigator.pushReplacementNamed(context, '/login');
        }
      }
    }
    setState(() => _isLoading = false);
  }

  @override
  void dispose() {
    _tabController.removeListener(_handleTabSelection);
    _goalsScrollController.dispose();
    _eventsScrollController.dispose();
    _videoControllers.forEach((_, controller) => controller.dispose());
    _tabController.dispose();
    _apiService.dispose();
    super.dispose();
  }

  void _checkAuthAndLoadInitialTab() async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);

    if (!authProvider.isInitialized) {
      developer.log('AuthProvider not initialized, waiting for initialization',
          name: 'HomeScreen');
      try {
        await authProvider.initialize();
        if (mounted) {
          _loadTabData(0);
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
      developer.log('AuthProvider initialized, loading initial tab',
          name: 'HomeScreen');
      _loadTabData(0);
    }
  }

  void _handleTabSelection() {
    if (_tabController.index != _selectedTabIndex) {
      setState(() {
        _selectedTabIndex = _tabController.index;
      });
      _loadTabData(_selectedTabIndex);
    }
  }

  void _loadTabData(int tabIndex) async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);

    if (!authProvider.isAuthenticated ||
        authProvider.userId == null ||
        authProvider.token == null) {
      setState(() {
        _isLoading = false;
        _error = 'Not authenticated';
      });
      return;
    }

    switch (tabIndex) {
      case 0:
        if (!_goalsLoaded) {
          _fetchGoals(authProvider, isInitial: true);
        }
        break;
      case 1:
        if (!_eventsLoaded) {
          _fetchEvents(authProvider, isInitial: true);
        }
        break;
      case 2:
        // Challenge tab - статический контент
        break;
    }
  }

  void _fetchGoals(AuthProvider authProvider, {bool isInitial = false}) async {
    if (_isLoadingMoreGoals || (!_goalsHasMore && !isInitial)) return;

    setState(() {
      if (isInitial) {
        _isLoading = true;
        _error = null;
        _goalsOffset = 0;
        _goalsHasMore = true;
        _goals.clear();
      } else {
        _isLoadingMoreGoals = true;
      }
    });

    try {
      developer.log('Fetching goals offset ${_goalsOffset}',
          name: 'HomeScreen');

      final goals = await _postService.getGoalsPaginated(
        authProvider.token!,
        authProvider.userId!,
        offset: _goalsOffset,
        limit: _postsPerPage,
      );

      if (mounted) {
        setState(() {
          if (isInitial) {
            _goals = goals;
            _goalsLoaded = true;
            _isLoading = false;
          } else {
            _goals.addAll(goals);
            _isLoadingMoreGoals = false;
          }

          _goalsHasMore = goals.length == _postsPerPage;
          _goalsOffset += goals.length;
        });
      }
    } catch (e) {
      developer.log('Fetch goals error: $e', name: 'HomeScreen');
      if (mounted) {
        setState(() {
          if (isInitial) {
            _isLoading = false;
          } else {
            _isLoadingMoreGoals = false;
          }
          _error = e.toString();
        });
      }
    }
  }

  void _fetchEvents(AuthProvider authProvider, {bool isInitial = false}) async {
    if (_isLoadingMoreEvents || (!_eventsHasMore && !isInitial)) return;

    setState(() {
      if (isInitial) {
        _isLoading = true;
        _error = null;
        _eventsOffset = 0;
        _eventsHasMore = true;
        _events.clear();
      } else {
        _isLoadingMoreEvents = true;
      }
    });

    try {
      developer.log('Fetching events offset ${_eventsOffset}',
          name: 'HomeScreen');

      final events = await _postService.getEventsPaginated(
        authProvider.token!,
        authProvider.userId!,
        offset: _eventsOffset,
        limit: _postsPerPage,
      );

      if (mounted) {
        setState(() {
          if (isInitial) {
            _events = events;
            _eventsLoaded = true;
            _isLoading = false;
          } else {
            _events.addAll(events);
            _isLoadingMoreEvents = false;
          }

          _eventsHasMore = events.length == _postsPerPage;
          _eventsOffset += events.length;
        });
      }
    } catch (e) {
      developer.log('Fetch events error: $e', name: 'HomeScreen');
      if (mounted) {
        setState(() {
          if (isInitial) {
            _isLoading = false;
          } else {
            _isLoadingMoreEvents = false;
          }
          _error = e.toString();
        });
      }
    }
  }

  void _onGoalsScroll() {
    if (_goalsScrollController.position.pixels >=
        _goalsScrollController.position.maxScrollExtent - 200) {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      _fetchGoals(authProvider);
    }
  }

  void _onEventsScroll() {
    if (_eventsScrollController.position.pixels >=
        _eventsScrollController.position.maxScrollExtent - 200) {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      _fetchEvents(authProvider);
    }
  }

  Future<void> _refreshCurrentTab() async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);

    switch (_selectedTabIndex) {
      case 0:
        _goalsLoaded = false;
        _fetchGoals(authProvider, isInitial: true);
        break;
      case 1:
        _eventsLoaded = false;
        _fetchEvents(authProvider, isInitial: true);
        break;
    }
  }

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
    final routes = ['/home', '/search', '/add', '/profile', '/ai-mentor'];
    Navigator.pushReplacementNamed(context, routes[index]);
  }

  void _onVideoControllerUpdate() {
    if (mounted) setState(() {});
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
      appBar: HomeAppBar(
        selectedTabIndex: _selectedTabIndex,
        tabController: _tabController,
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          PostsView(
            postType: 'goal',
            posts: _goals,
            scrollController: _goalsScrollController,
            isLoading: _isLoading,
            isLoadingMore: _isLoadingMoreGoals,
            hasMore: _goalsHasMore,
            isTabLoaded: _goalsLoaded,
            error: _error,
            videoControllers: _videoControllers,
            onRefresh: _refreshCurrentTab,
            onRetry: _refreshCurrentTab,
            onVideoControllerUpdate: _onVideoControllerUpdate,
            onLikePressed: _onLikeButtonTapped,
            onJoinEvent: _joinEvent,
          ),
          PostsView(
            postType: 'event',
            posts: _events,
            scrollController: _eventsScrollController,
            isLoading: _isLoading,
            isLoadingMore: _isLoadingMoreEvents,
            hasMore: _eventsHasMore,
            isTabLoaded: _eventsLoaded,
            error: _error,
            videoControllers: _videoControllers,
            onRefresh: _refreshCurrentTab,
            onRetry: _refreshCurrentTab,
            onVideoControllerUpdate: _onVideoControllerUpdate,
            onLikePressed: _onLikeButtonTapped,
            onJoinEvent: _joinEvent,
          ),
          const ChallengeView(),
        ],
      ),
      bottomNavigationBar: Navbar(
        selectedIndex: _selectedIndex,
        onTap: _onItemTapped,
      ),
    );
  }
}
