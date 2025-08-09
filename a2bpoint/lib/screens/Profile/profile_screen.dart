import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'dart:developer' as developer;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../providers/auth_provider.dart';
import '../../services/api_services.dart';
import '../../services/post_service.dart';
import '../../models/post.dart';
import '../../services/exceptions.dart';
import '../navbar.dart';
import 'profile_edit_screen.dart';
import '../Home/post_detail_screen.dart';
import '../../models/tasks.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  _ProfileScreenState createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen>
    with SingleTickerProviderStateMixin {
  final ApiService _apiService = ApiService();
  final PostService _postService = PostService();
  Map<String, dynamic>? _profile;
  List<Post> _goals = [];
  List<Post> _events = [];
  bool _isLoading = true;
  final TextEditingController _biographyController = TextEditingController();
  late TabController _tabController;
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _tabController.addListener(_handleTabChange);
    _loadProfile();
  }

  @override
  void dispose() {
    _tabController.removeListener(_handleTabChange);
    _tabController.dispose();
    _biographyController.dispose();
    _scrollController.dispose();
    _apiService.dispose();
    super.dispose();
  }

  void _handleTabChange() {
    if (!_tabController.indexIsChanging) {
      setState(() {});
    }
  }

  // Функция для фильтрации постов с изображениями
  List<Post> _filterPostsWithImages(List<Post> posts) {
    return posts.where((post) {
      if (post.imageUrls == null || post.imageUrls!.isEmpty) return false;
      
      // Проверяем, есть ли хотя бы один валидный URL
      for (String url in post.imageUrls!) {
        String cleanUrl = _extractImageUrl(url);
        if (cleanUrl.isNotEmpty && cleanUrl.startsWith('http')) {
          return true;
        }
      }
      return false;
    }).toList();
  }

  // Функция для извлечения правильного URL из массива
  String _extractImageUrl(String? imageUrl) {
    if (imageUrl == null || imageUrl.isEmpty) return '';
    
    // Убираем все лишние символы
    String cleanUrl = imageUrl
        .replaceAll('[', '')
        .replaceAll(']', '')
        .replaceAll('"', '')
        .replaceAll("'", '')
        .trim();
    
    // Берем первый URL если есть несколько (разделенных запятой)
    if (cleanUrl.contains(',')) {
      cleanUrl = cleanUrl.split(',').first.trim();
    }
    
    return cleanUrl;
  }

  Future<void> _loadProfile() async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final userId = authProvider.userId ?? '';
    final token = authProvider.token ?? '';

    if (userId.isEmpty || token.isEmpty) {
      developer.log('No userId or token, skipping profile load',
          name: 'ProfileScreen');
      authProvider.handleAuthError(
          context, AuthenticationException('Not authenticated'));
      setState(() => _isLoading = false);
      return;
    }

    try {
      developer.log('Loading profile for userId=$userId',
          name: 'ProfileScreen');

      final prefs = await SharedPreferences.getInstance();
      final savedBiography = prefs.getString('biography_$userId') ?? '';

      final profile = await _apiService.getProfile(userId, token);
      final goals = await _postService.getGoals(userId, token);
      final events = await _postService.getEvents(userId, token);

      if (mounted) {
        setState(() {
          _profile = profile;
          // Фильтруем посты с изображениями
          _goals = _filterPostsWithImages(goals);
          _events = _filterPostsWithImages(events);
          _biographyController.text =
              profile['biography']?.toString() ?? savedBiography;
          _isLoading = false;
        });
        await prefs.setString('biography_$userId', _biographyController.text);
      }
    } catch (e, stackTrace) {
      developer.log('Load profile error: $e',
          name: 'ProfileScreen', stackTrace: stackTrace);
      if (mounted) {
        authProvider.handleAuthError(
          context,
          e is AuthenticationException ? e : AuthenticationException(e.toString()),
        );
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error loading profile: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _updateBiography() async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final userId = authProvider.userId ?? '';
    final token = authProvider.token ?? '';

    if (_biographyController.text.isEmpty || userId.isEmpty || token.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Biography or authentication details missing'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    try {
      developer.log('Updating biography for userId=$userId',
          name: 'ProfileScreen');
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('biography_$userId', _biographyController.text);

      await _apiService.updateProfile(
        userId,
        token,
        {'bio': _biographyController.text},
        '', // photoURL
      );

      if (mounted) {
        setState(() {
          _profile = {...?_profile, 'biography': _biographyController.text};
        });
        await authProvider.updateProfile(
          authProvider.username ?? '',
          _biographyController.text,
          authProvider.email ?? '',
          null, // newAvatar
        );
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Biography updated successfully'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error updating biography: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);
    if (!authProvider.isInitialized) {
      return const Scaffold(
        backgroundColor: Color(0xFFF4F3EE),
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      backgroundColor: const Color(0xFFF4F3EE),
      appBar: AppBar(
        backgroundColor: const Color(0xFFF4F3EE),
        elevation: 0,
        automaticallyImplyLeading: false,
        // Перенесли вкладки в AppBar
        title: Row(
          mainAxisAlignment: MainAxisAlignment.start,
          children: [
            GestureDetector(
              onTap: () => _tabController.animateTo(0),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  color: _tabController.index == 0 
                      ? const Color(0x1F5F93E6) // #5F93E6 с 12% прозрачностью
                      : Colors.transparent,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  'Goals',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: _tabController.index == 0 
                        ? const Color(0xFF5F93E6) // Синий цвет текста для активной вкладки
                        : Colors.black,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 20),
            GestureDetector(
              onTap: () => _tabController.animateTo(1),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  color: _tabController.index == 1 
                      ? const Color(0x1F5F93E6) // #5F93E6 с 12% прозрачностью
                      : Colors.transparent,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  'Events',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: _tabController.index == 1 
                        ? const Color(0xFF5F93E6) // Синий цвет текста для активной вкладки
                        : Colors.black,
                  ),
                ),
              ),
            ),
          ],
        ),
        actions: [
          // Иконка чата (используем такую же как в HomeScreen)
          IconButton(
            icon: Image.asset('assets/images/messages_icon.png', height: 24),
            onPressed: () {
              // Функционал чата
            },
          ),
          // Иконка редактирования
          IconButton(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const ProfileEditScreen(),
                ),
              );
            },
            icon: const Icon(
              Icons.edit,
              size: 24,
              color: Colors.black,
            ),
          ),
        ],
      ),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(Colors.blue),
              ),
            )
          : _profile == null
              ? const Center(child: Text('Failed to load profile'))
              : Column(
                  children: [
                    // Фиксированный заголовок профиля
                    _buildProfileHeader(authProvider),
                    // Контент табов
                    Expanded(
                      child: TabBarView(
                        controller: _tabController,
                        children: [
                          _buildGridView(posts: _goals, postType: 'goal'),
                          _buildGridView(posts: _events, postType: 'event'),
                        ],
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

  Widget _buildProfileHeader(AuthProvider authProvider) {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 20),
      child: Column(
        children: [
          Row(
            children: [
              // Аватар
              Container(
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: Colors.grey.shade300,
                    width: 2,
                  ),
                ),
                child: CircleAvatar(
                  radius: 45,
                  backgroundImage: _profile?['avatar'] != null &&
                          _profile!['avatar'].isNotEmpty
                      ? CachedNetworkImageProvider(_profile!['avatar'])
                      : const AssetImage('assets/images/default_avatar.png')
                          as ImageProvider,
                ),
              ),
              const SizedBox(width: 20),
              // Статистика в горизонтальном ряду
              Expanded(
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    _buildStatColumn(
                        '${_goals.length + _events.length}', 'Posts'),
                    _buildStatColumn(
                        '${_profile?['numOfFollowers'] ?? 0}', 'Followers'),
                    _buildStatColumn(
                        '${_profile?['following'] ?? 0}', 'Following'),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 15),
          // Имя пользователя и биография
          Align(
            alignment: Alignment.centerLeft,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  authProvider.username ?? 'User',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Colors.black,
                  ),
                ),
                const SizedBox(height: 5),
                Container(
                  width: double.infinity,
                  child: Text(
                    _biographyController.text.isNotEmpty 
                        ? _biographyController.text
                        : 'Tell us about yourself...',
                    style: TextStyle(
                      fontSize: 14,
                      color: _biographyController.text.isNotEmpty 
                          ? Colors.black
                          : Colors.grey.shade600,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatColumn(String count, String label) {
    return Column(
      children: [
        Text(
          count,
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Colors.black,
          ),
        ),
        Text(
          label,
          style: const TextStyle(
            fontSize: 14,
            color: Colors.black,
          ),
        ),
      ],
    );
  }

  Widget _buildGridView({required List<Post> posts, required String postType}) {
    if (posts.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.photo_outlined,
              size: 64,
              color: Colors.grey.shade400,
            ),
            const SizedBox(height: 16),
            Text(
              'No posts with photos yet',
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey.shade600,
              ),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadProfile,
      color: Colors.blue,
      child: Padding(
        padding: const EdgeInsets.all(2),
        child: GridView.builder(
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 3,
            crossAxisSpacing: 2,
            mainAxisSpacing: 2,
          ),
          itemCount: posts.length,
          itemBuilder: (context, index) {
            final post = posts[index];
            return _buildGridItem(post, postType);
          },
        ),
      ),
    );
  }

  Widget _buildGridItem(Post post, String postType) {
    String imageUrl = '';
    
    // Обрабатываем URL изображения правильно
    if (post.imageUrls != null && post.imageUrls!.isNotEmpty) {
      imageUrl = _extractImageUrl(post.imageUrls!.first);
    }
    
    final hasMultipleImages = (post.imageUrls?.length ?? 0) > 1;

    return GestureDetector(
      onTap: () {
        // Добавляем навигацию к детальному экрану поста
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => PostDetailScreen(
              postId: post.id, 
              postType: postType,
            ),
          ),
        );
      },
      child: Container(
        child: Stack(
          fit: StackFit.expand,
          children: [
            CachedNetworkImage(
              imageUrl: imageUrl,
              fit: BoxFit.cover,
              placeholder: (context, url) => Container(
                color: Colors.grey.shade300,
                child: const Center(
                  child: CircularProgressIndicator(),
                ),
              ),
              errorWidget: (context, url, error) => Container(
                color: Colors.grey.shade300,
                child: const Icon(
                  Icons.error,
                  color: Colors.red,
                ),
              ),
            ),
            // Индикатор множественных изображений
            if (hasMultipleImages)
              Positioned(
                top: 8,
                right: 8,
                child: Container(
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.7),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(
                    Icons.copy,
                    color: Colors.white,
                    size: 16,
                  ),
                ),
              ),
            // Показать лайки, если есть
            if (post.numOfLikes > 0)
              Positioned(
                bottom: 8,
                left: 8,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.7),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(
                        Icons.favorite,
                        color: Colors.red,
                        size: 12,
                      ),
                      const SizedBox(width: 2),
                      Text(
                        '${post.numOfLikes}',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 10,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}