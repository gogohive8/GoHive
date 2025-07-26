import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'dart:developer' as developer;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:cached_network_image/cached_network_image.dart';
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
      developer.log('Loading profile for userId=$userId', name: 'ProfileScreen');

      final prefs = await SharedPreferences.getInstance();
      final savedBiography = prefs.getString('biography_$userId') ?? '';

      final profile = await _apiService.getProfile(userId, token);
      final goals = await _apiService.getGoals(userId, token);
      final events = await _apiService.getEvents(userId, token);

      if (mounted) {
        setState(() {
          _profile = profile;
          _goals = goals;
          _events = events;
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
        authProvider.handleAuthError(context, e);
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
    developer.log('Updating biography for userId=$userId', name: 'ProfileScreen');
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
          backgroundColor: Color(0xFFAFCBEA),
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
        backgroundColor: Color(0xFFF9F6F2),
        body: Center(child: CircularProgressIndicator()),
      );
    }

    final size = MediaQuery.of(context).size;

    return Scaffold(
      backgroundColor: const Color(0xFFF9F6F2),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(Color(0xFFAFCBEA)),
              ),
            )
          : _profile == null
              ? const Center(child: Text('Failed to load profile'))
              : CustomScrollView(
                  controller: _scrollController,
                  slivers: <Widget>[
                    SliverAppBar(
                      backgroundColor: const Color(0xFFF9F6F2),
                      expandedHeight: size.height * 0.35,
                      floating: false,
                      pinned: true,
                      flexibleSpace: FlexibleSpaceBar(
                        background: _buildProfileHeader(authProvider, size),
                      ),
                    ),
                    SliverPersistentHeader(
                      pinned: true,
                      delegate: _SliverTabBarDelegate(
                        TabBar(
                          controller: _tabController,
                          tabs: const [
                            Tab(text: 'Goals'),
                            Tab(text: 'Events'),
                          ],
                          indicatorColor: const Color(0xFFAFCBEA),
                          labelColor: const Color(0xFFAFCBEA),
                          unselectedLabelColor: const Color(0xFF333333),
                          labelStyle: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                      ),
                    ),
                    SliverFillRemaining(
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
      bottomNavigationBar: Navbar(
        selectedIndex: 3,
        onTap: (index) {
          final routes = ['/home', '/search', '/add', '/profile', '/ai-mentor'];
          Navigator.pushReplacementNamed(context, routes[index]);
        },
      ),
    );
  }

  Widget _buildProfileHeader(AuthProvider authProvider, Size size) {
    return Container(
      padding: EdgeInsets.all(size.width * 0.04),
      child: Column(
        children: [
          SizedBox(height: size.height * 0.06),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: const Color(0xFFAFCBEA),
                    width: 3,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.grey.withValues(alpha: 0.3),
                      blurRadius: 5,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: CircleAvatar(
                  radius: size.width * 0.12,
                  backgroundImage: _profile?['avatar'] != null &&
                          _profile!['avatar'].isNotEmpty
                      ? CachedNetworkImageProvider(_profile!['avatar'])
                      : const AssetImage('assets/images/default_avatar.png')
                          as ImageProvider,
                ),
              ),
              SizedBox(width: size.width * 0.04),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SizedBox(height: size.width * 0.02),
                    Text(
                      authProvider.username ?? 'User',
                      style: TextStyle(
                        fontSize: size.width * 0.06,
                        fontWeight: FontWeight.bold,
                        color: const Color(0xFF1A1A1A),
                      ),
                    ),
                    SizedBox(height: size.width * 0.01),
                    if (_profile?['country'] != null)
                      Text(
                        _profile!['country'],
                        style: TextStyle(
                          fontSize: size.width * 0.04,
                          color: const Color(0xFF333333),
                        ),
                      ),
                    SizedBox(height: size.width * 0.02),
                    Text(
                      authProvider.email ?? 'user@email.com',
                      style: TextStyle(
                        fontSize: size.width * 0.035,
                        color: const Color(0xFF666666),
                      ),
                    ),
                  ],
                ),
              ),
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
                  color: Color(0xFFAFCBEA),
                ),
              ),
            ],
          ),
          SizedBox(height: size.height * 0.02),
          _buildStatsRow(size),
          SizedBox(height: size.height * 0.02),
          TextFormField(
            controller: _biographyController,
            decoration: InputDecoration(
              filled: true,
              fillColor: const Color.fromRGBO(249, 246, 242, 0.9),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: const BorderSide(color: Color(0xFFAFCBEA)),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: const BorderSide(color: Color(0xFFAFCBEA)),
              ),
              suffixIcon: IconButton(
                icon: const Icon(Icons.edit, color: Color(0xFFAFCBEA)),
                onPressed: _updateBiography,
              ),
              hintText: 'Tell us about yourself...',
            ),
            maxLines: 3,
            style: const TextStyle(
              fontSize: 14,
              color: Color(0xFF1A1A1A),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatsRow(Size size) {
    return Container(
      padding: EdgeInsets.symmetric(vertical: size.height * 0.01),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          _buildStatItem('Posts', (_goals.length + _events.length).toString()),
          Container(
            height: 30,
            width: 1,
            color: const Color(0xFF333333),
          ),
          _buildStatItem('Followers', '${_profile?['numOfFollowers'] ?? 0}'),
          Container(
            height: 30,
            width: 1,
            color: const Color(0xFF333333),
          ),
          _buildStatItem('Following', '${_profile?['following'] ?? 0}'),
        ],
      ),
    );
  }

  Widget _buildStatItem(String label, String count) {
    return Column(
      children: [
        Text(
          count,
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Color(0xFF1A1A1A),
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: const TextStyle(
            fontSize: 12,
            color: Color(0xFF333333),
          ),
        ),
      ],
    );
  }

  Widget _buildPostsView({required List<Post> posts, required String type}) {
    if (posts.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              type == 'goal' ? Icons.flag_outlined : Icons.event_outlined,
              size: 64,
              color: const Color(0xFF333333),
            ),
            const SizedBox(height: 16),
            Text(
              'No ${type}s yet',
              style: const TextStyle(
                fontSize: 18,
                color: Color(0xFF333333),
              ),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadProfile,
      color: const Color(0xFFAFCBEA),
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: posts.length,
        itemBuilder: (context, index) {
          final post = posts[index];
          return Card(
            color: const Color(0xFFDDDDDD),
            elevation: 3,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            margin: const EdgeInsets.only(bottom: 16),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    post.text ?? 'No description available',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                      color: Color(0xFF1A1A1A),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        post.createdAt.toLocal().toString().split('.')[0],
                        style: const TextStyle(
                          fontSize: 12,
                          color: Color(0xFF666666),
                        ),
                      ),
                      Row(
                        children: [
                          const Icon(
                            Icons.favorite_border,
                            color: Color(0xFF333333),
                            size: 16,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            '${post.numOfLikes}',
                            style: const TextStyle(
                              color: Color(0xFF1A1A1A),
                              fontSize: 14,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                  if (type == 'goal' &&
                      post.tasks != null &&
                      post.tasks!.isNotEmpty) ...[
                    const SizedBox(height: 12),
                    const Text(
                      'Tasks:',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF1A1A1A),
                      ),
                    ),
                    const SizedBox(height: 8),
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
                            task['title']?.toString() ?? 'Untitled task',
                            style: const TextStyle(
                              color: Color(0xFF333333),
                              fontSize: 12,
                            ),
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

class _SliverTabBarDelegate extends SliverPersistentHeaderDelegate {
  final TabBar _tabBar;

  _SliverTabBarDelegate(this._tabBar);

  @override
  double get minExtent => _tabBar.preferredSize.height;
  @override
  double get maxExtent => _tabBar.preferredSize.height;

  @override
  Widget build(
      BuildContext context, double shrinkOffset, bool overlapsContent) {
    return Container(
      color: const Color(0xFFF9F6F2),
      child: _tabBar,
    );
  }

  @override
  bool shouldRebuild(_SliverTabBarDelegate oldDelegate) {
    return false;
  }
}