import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'dart:developer' as developer;

import '../../providers/auth_provider.dart';
import '../../providers/chat_provider.dart';
import '../../services/api_services.dart';
import '../../services/post_service.dart';
import '../../services/exceptions.dart';
import '../../models/post.dart';
import '../../models/user.dart';
import '../../models/chat.dart';
import '../Home/post_detail_screen.dart';
import '../Chats/chat_screen.dart';

class OtherUserProfileScreen extends StatefulWidget {
  final String userId;
  final String? username;

  const OtherUserProfileScreen({
    Key? key,
    required this.userId,
    this.username,
  }) : super(key: key);

  @override
  _OtherUserProfileScreenState createState() => _OtherUserProfileScreenState();
}

class _OtherUserProfileScreenState extends State<OtherUserProfileScreen>
    with SingleTickerProviderStateMixin {
  final ApiService _apiService = ApiService();
  final PostService _postService = PostService();
  
  Map<String, dynamic>? _profile;
  List<Post> _goals = [];
  List<Post> _events = [];
  bool _isLoading = true;
  bool _isFollowing = false;
  bool _isFollowLoading = false;
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _tabController.addListener(_handleTabChange);
    _loadUserProfile();
  }

  @override
  void dispose() {
    _tabController.removeListener(_handleTabChange);
    _tabController.dispose();
    _apiService.dispose();
    super.dispose();
  }

  void _handleTabChange() {
    if (!_tabController.indexIsChanging) {
      setState(() {});
    }
  }

  List<Post> _filterPostsWithImages(List<Post> posts) {
    return posts.where((post) {
      if (post.imageUrls == null || post.imageUrls!.isEmpty) return false;
      
      for (String url in post.imageUrls!) {
        String cleanUrl = _extractImageUrl(url);
        if (cleanUrl.isNotEmpty && cleanUrl.startsWith('http')) {
          return true;
        }
      }
      return false;
    }).toList();
  }

  String _extractImageUrl(String? imageUrl) {
    if (imageUrl == null || imageUrl.isEmpty) return '';
    
    String cleanUrl = imageUrl
        .replaceAll('[', '')
        .replaceAll(']', '')
        .replaceAll('"', '')
        .replaceAll("'", '')
        .trim();
    
    if (cleanUrl.contains(',')) {
      cleanUrl = cleanUrl.split(',').first.trim();
    }
    
    return cleanUrl;
  }

  Future<void> _loadUserProfile() async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final token = authProvider.token ?? '';

    if (token.isEmpty) {
      developer.log('No token available', name: 'OtherUserProfileScreen');
      setState(() => _isLoading = false);
      return;
    }

    try {
      developer.log('Loading profile for userId=${widget.userId}', 
          name: 'OtherUserProfileScreen');

      // Загружаем профиль, посты и статус подписки параллельно
      final futures = await Future.wait([
        _apiService.getProfile(widget.userId, token),
        _postService.getGoals(widget.userId, token),
        _postService.getEvents(widget.userId, token),
        _apiService.getFollowStatus(widget.userId, token),
      ]);

      final profile = futures[0] as Map<String, dynamic>;
      final goals = futures[1] as List<Post>;
      final events = futures[2] as List<Post>;
      final isFollowing = futures[3] as bool;

      if (mounted) {
        setState(() {
          _profile = profile;
          _goals = _filterPostsWithImages(goals);
          _events = _filterPostsWithImages(events);
          _isFollowing = isFollowing;
          _isLoading = false;
        });
      }
    } catch (e, stackTrace) {
      developer.log('Load user profile error: $e',
          name: 'OtherUserProfileScreen', stackTrace: stackTrace);
      if (mounted) {
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

  Future<void> _toggleFollow() async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final token = authProvider.token ?? '';

    if (token.isEmpty || _isFollowLoading) return;

    setState(() => _isFollowLoading = true);

    try {
      developer.log('${_isFollowing ? 'Unfollowing' : 'Following'} user: ${widget.userId}',
          name: 'OtherUserProfileScreen');

      // Вызываем соответствующий API метод
      if (_isFollowing) {
        await _apiService.unfollowUser(widget.userId, token);
      } else {
        await _apiService.followUser(widget.userId, token);
      }
      
      if (mounted) {
        setState(() {
          _isFollowing = !_isFollowing;
          // Обновляем количество подписчиков
          if (_profile != null) {
            int currentFollowers = _profile!['numOfFollowers'] ?? 0;
            _profile!['numOfFollowers'] = _isFollowing 
                ? currentFollowers + 1 
                : currentFollowers - 1;
          }
        });

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(_isFollowing ? 'Following!' : 'Unfollowed'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } on DataValidationException catch (e) {
      developer.log('Follow/Unfollow validation error: $e', name: 'OtherUserProfileScreen');
      
      // Обрабатываем специфические ошибки
      if (e.toString().contains('already follow') || 
          e.toString().contains('duplicate key') ||
          e.toString().contains('23505')) {
        // Пользователь уже подписан
        if (mounted) {
          setState(() {
            _isFollowing = true;
          });
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Already following this user'),
              backgroundColor: Colors.orange,
            ),
          );
        }
      } else if (e.toString().contains('not following') || 
                 e.toString().contains('does not exist')) {
        // Пользователь не подписан (при попытке отписаться)
        if (mounted) {
          setState(() {
            _isFollowing = false;
          });
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Not following this user'),
              backgroundColor: Colors.orange,
            ),
          );
        }
      } else {
        // Другие ошибки валидации
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Error: ${e.message ?? e.toString()}'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    } catch (e, stackTrace) {
      developer.log('Follow/Unfollow error: $e',
          name: 'OtherUserProfileScreen', stackTrace: stackTrace);
      
      if (mounted) {
        String errorMessage = 'Unable to update follow status';
        
        // Определяем тип ошибки для пользователя
        if (e.toString().contains('timeout')) {
          errorMessage = 'Connection timeout. Please try again.';
        } else if (e.toString().contains('401')) {
          errorMessage = 'Please log in again';
        } else if (e.toString().contains('403')) {
          errorMessage = 'You don\'t have permission for this action';
        } else if (e.toString().contains('404')) {
          errorMessage = 'User not found';
        }
        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(errorMessage),
            backgroundColor: Colors.red,
            action: SnackBarAction(
              label: 'Retry',
              textColor: Colors.white,
              onPressed: () => _toggleFollow(),
            ),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isFollowLoading = false);
      }
    }
  }

  Future<void> _openChat() async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final chatProvider = Provider.of<ChatProvider>(context, listen: false);
    final token = authProvider.token ?? '';
    final currentUserId = authProvider.userId ?? '';

    if (token.isEmpty || currentUserId.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Authentication required'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    try {
      developer.log('Opening chat with user: ${widget.userId}',
          name: 'OtherUserProfileScreen');

      // Показываем индикатор загрузки
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const Center(
          child: CircularProgressIndicator(),
        ),
      );

      // Ищем существующий чат с этим пользователем
      Chat? existingChat;
      final chats = chatProvider.chats;
      
      for (final chat in chats) {
        if (chat.type == ChatType.direct && 
            chat.participants.contains(widget.userId) &&
            chat.participants.contains(currentUserId)) {
          existingChat = chat;
          break;
        }
      }

      String chatId;
      
      if (existingChat != null) {
        // Используем существующий чат
        chatId = existingChat.id;
        developer.log('Found existing chat: $chatId', name: 'OtherUserProfileScreen');
      } else {
        // Создаем новый чат
        try {
          final newChat = await chatProvider.createDirectChat(
            widget.userId,
            token,
          );
          chatId = newChat.id;
          developer.log('Created new chat: $chatId', name: 'OtherUserProfileScreen');
        } catch (e) {
          developer.log('Failed to create chat, error details: $e', name: 'OtherUserProfileScreen');
          
          // Если ошибка содержит HTML, значит проблема с API endpoint
          if (e.toString().contains('DOCTYPE html') || e.toString().contains('FormatException')) {
            throw Exception('Chat service temporarily unavailable. Please try again later.');
          }
          rethrow;
        }
      }

      // Закрываем диалог загрузки
      if (mounted) {
        Navigator.pop(context);
        
        // Переходим к чату
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => ChatScreen(chatId: chatId),
          ),
        );
      }
      
    } catch (e, stackTrace) {
      developer.log('Open chat error: $e',
          name: 'OtherUserProfileScreen', stackTrace: stackTrace);
          
      // Закрываем диалог загрузки если он открыт
      if (mounted && Navigator.canPop(context)) {
        Navigator.pop(context);
      }
      
      if (mounted) {
        String errorMessage = 'Error opening chat';
        
        // Более понятные сообщения об ошибках
        if (e.toString().contains('temporarily unavailable')) {
          errorMessage = 'Chat service is temporarily unavailable';
        } else if (e.toString().contains('FormatException') || e.toString().contains('DOCTYPE html')) {
          errorMessage = 'Chat service error. Please try again later.';
        } else if (e.toString().contains('timeout')) {
          errorMessage = 'Connection timeout. Please check your internet.';
        }
        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(errorMessage),
            backgroundColor: Colors.red,
            action: SnackBarAction(
              label: 'Retry',
              textColor: Colors.white,
              onPressed: () => _openChat(),
            ),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF4F3EE),
      appBar: AppBar(
        backgroundColor: const Color(0xFFF4F3EE),
        elevation: 0,
        leading: Container(
          margin: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.1),
                blurRadius: 4,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: IconButton(
            icon: const Icon(Icons.arrow_back_ios, color: Colors.black87, size: 18),
            onPressed: () => Navigator.pop(context),
            padding: EdgeInsets.zero,
          ),
        ),
        title: Row(
          mainAxisAlignment: MainAxisAlignment.start,
          children: [
            GestureDetector(
              onTap: () => _tabController.animateTo(0),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  color: _tabController.index == 0 
                      ? const Color(0x1F5F93E6)
                      : Colors.transparent,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  'Goals',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: _tabController.index == 0 
                        ? const Color(0xFF5F93E6)
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
                      ? const Color(0x1F5F93E6)
                      : Colors.transparent,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  'Events',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: _tabController.index == 1 
                        ? const Color(0xFF5F93E6)
                        : Colors.black,
                  ),
                ),
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: Image.asset('assets/images/messages_icon.png', height: 24),
            onPressed: _openChat,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF5F93E6)),
              ),
            )
          : _profile == null
              ? const Center(child: Text('Failed to load profile'))
              : Column(
                  children: [
                    _buildProfileHeader(),
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
    );
  }

  Widget _buildProfileHeader() {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 20),
      child: Column(
        children: [
          Row(
            children: [
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
          Align(
            alignment: Alignment.centerLeft,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _profile?['username'] ?? 'User',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Colors.black,
                  ),
                ),
                const SizedBox(height: 5),
                if (_profile?['biography'] != null && _profile!['biography'].isNotEmpty)
                  Container(
                    width: double.infinity,
                    child: Text(
                      _profile!['biography'],
                      style: const TextStyle(
                        fontSize: 14,
                        color: Colors.black,
                      ),
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              Expanded(
                flex: 2,
                child: _isFollowLoading
                    ? Container(
                        height: 36,
                        decoration: BoxDecoration(
                          color: Colors.grey.shade300,
                          borderRadius: BorderRadius.circular(18),
                        ),
                        child: const Center(
                          child: SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor: AlwaysStoppedAnimation<Color>(Colors.grey),
                            ),
                          ),
                        ),
                      )
                    : ElevatedButton(
                        onPressed: _toggleFollow,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: _isFollowing 
                              ? Colors.grey.shade300 
                              : const Color(0xFF5F93E6),
                          foregroundColor: _isFollowing 
                              ? Colors.black87 
                              : Colors.white,
                          elevation: 0,
                          padding: const EdgeInsets.symmetric(vertical: 10),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(18),
                          ),
                        ),
                        child: Text(
                          _isFollowing ? 'Following' : 'Follow',
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: ElevatedButton(
                  onPressed: _openChat,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.white,
                    foregroundColor: Colors.black87,
                    elevation: 0,
                    side: BorderSide(color: Colors.grey.shade300),
                    padding: const EdgeInsets.symmetric(vertical: 10),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(18),
                    ),
                  ),
                  child: const Text(
                    'Message',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
            ],
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
      onRefresh: _loadUserProfile,
      color: const Color(0xFF5F93E6),
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
    
    if (post.imageUrls != null && post.imageUrls!.isNotEmpty) {
      imageUrl = _extractImageUrl(post.imageUrls!.first);
    }
    
    final hasMultipleImages = (post.imageUrls?.length ?? 0) > 1;

    return GestureDetector(
      onTap: () {
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