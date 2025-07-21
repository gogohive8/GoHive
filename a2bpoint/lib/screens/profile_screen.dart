import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'dart:developer' as developer;
import 'package:shared_preferences/shared_preferences.dart';
import '../providers/auth_provider.dart';
import '../services/api_services.dart';
import '../models/post.dart';
import '../services/exceptions.dart';
import 'navbar.dart';
import 'profile_edit_screen.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  _ProfileScreenState createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen>
    with SingleTickerProviderStateMixin {
  final ApiService _apiService = ApiService();
  Map<String, dynamic>? _profile;
  List<Post> _goals = [];
  List<Post> _events = [];
  bool _isLoading = true;
  late TabController _tabController;

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
    _apiService.dispose();
    super.dispose();
  }

  void _handleTabChange() {
    if (!_tabController.indexIsChanging) {
      setState(() {});
    }
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

      final profile = await _apiService.getProfile(userId, token);
      final goals = await _apiService.getGoals(userId, token);
      final events = await _apiService.getEvents(userId, token);

      if (mounted) {
        setState(() {
          _profile = profile;
          _goals = goals;
          _events = events;
          _isLoading = false;
        });
        developer.log(
            'Profile loaded: username=${_profile?['username'] ?? 'User'}, bio=${_profile?['bio'] ?? 'none'}, avatar=${_profile?['avatar'] ?? 'none'}',
            name: 'ProfileScreen');
      }
    } catch (e, stackTrace) {
      developer.log('Load profile error: $e',
          name: 'ProfileScreen', stackTrace: stackTrace);
      if (mounted) {
        authProvider.handleAuthError(context, e);
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Ошибка загрузки профиля: $e')),
        );
      }
    }
  }

  void _editProfile() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const ProfileEditScreen()),
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

    final size = MediaQuery.of(context).size;
    final padding = size.width * 0.03;

    return Scaffold(
      backgroundColor: const Color(0xFFF9F6F2),
      appBar: AppBar(
        backgroundColor: const Color(0xFFF9F6F2),
        elevation: 0,
        automaticallyImplyLeading: false,
        title: Text(
          authProvider.username ?? 'User',
          style: const TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: Color(0xFF1A1A1A),
          ),
        ),
        centerTitle: true,
        actions: [
          IconButton(
            icon: Image.asset('assets/images/messages_icon.png', height: 24),
            onPressed: () {},
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'Goals'),
            Tab(text: 'Events'),
          ],
          indicatorColor: const Color(0xFFAFCBEA),
          labelColor: const Color(0xFFAFCBEA),
          unselectedLabelColor: const Color(0xFF333333),
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _profile == null
              ? const Center(child: Text('Failed to load profile'))
              : SingleChildScrollView(
                  padding: EdgeInsets.all(padding),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Center(
                        child: CircleAvatar(
                          radius: 40,
                          backgroundImage: _profile?['avatar'] != null &&
                                  _profile!['avatar'].isNotEmpty
                              ? NetworkImage(_profile!['avatar'])
                              : const AssetImage(
                                      'assets/images/default_avatar.png')
                                  as ImageProvider,
                        ),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        authProvider.username ?? 'User',
                        style: const TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF1A1A1A),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        '${_profile?['followers'] ?? 0} followers  ${_profile?['following'] ?? 0} following',
                        style: const TextStyle(
                          fontSize: 12,
                          color: Color(0xFF333333),
                        ),
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        initialValue: authProvider.bio ?? '',
                        readOnly: true,
                        decoration: InputDecoration(
                          filled: true,
                          fillColor: const Color.fromRGBO(249, 246, 242, 0.9),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                            borderSide:
                                const BorderSide(color: Color(0xFFAFCBEA)),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                            borderSide:
                                const BorderSide(color: Color(0xFFAFCBEA)),
                          ),
                          suffixIcon: IconButton(
                            icon: const Icon(Icons.edit,
                                color: Color(0xFFAFCBEA)),
                            onPressed: _editProfile,
                          ),
                        ),
                        maxLines: 3,
                        style: const TextStyle(
                          fontSize: 14,
                          color: Color(0xFF1A1A1A),
                        ),
                      ),
                      const SizedBox(height: 20),
                      SizedBox(
                        height: size.height * 0.5,
                        child: TabBarView(
                          controller: _tabController,
                          children: [
                            _buildPostsView(posts: _goals, type: 'goal'),
                            _buildPostsView(posts: _events, type: 'event'),
                          ],
                        ),
                      ),
                    ],
                  ),
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

  Widget _buildPostsView({required List<Post> posts, required String type}) {
    if (posts.isEmpty) {
      return Center(child: Text('No $type available'));
    }
    return RefreshIndicator(
      onRefresh: _loadProfile,
      child: ListView.builder(
        itemCount: posts.length,
        itemBuilder: (context, index) {
          final post = posts[index];
          developer.log(
              'Rendering $type[$index]: id=${post.id}, text=${post.text}, likes=${post.likes}',
              name: 'ProfileScreen');
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
                  Text(
                    post.text ?? 'No description available',
                    style: const TextStyle(
                      fontSize: 16,
                      color: Color(0xFF1A1A1A),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    post.createdAt.toLocal().toString().split('.')[0],
                    style: const TextStyle(
                      fontSize: 12,
                      color: Color(0xFF333333),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          const Icon(Icons.favorite_border,
                              color: Color(0xFF333333)),
                          const SizedBox(width: 4),
                          Text(
                            '${post.likes}',
                            style: const TextStyle(color: Color(0xFF1A1A1A)),
                          ),
                        ],
                      ),
                    ],
                  ),
                  if (type == 'goal' &&
                      post.tasks != null &&
                      post.tasks!.isNotEmpty) ...[
                    const SizedBox(height: 8),
                    const Text(
                      'Tasks:',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF1A1A1A),
                      ),
                    ),
                    ...post.tasks!.map((task) => Padding(
                          padding: const EdgeInsets.symmetric(vertical: 4),
                          child: Text(
                            task['title']?.toString() ?? 'Untitled task',
                            style: const TextStyle(color: Color(0xFF333333)),
                          ),
                        )),
                  ],
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}