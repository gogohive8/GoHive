import 'dart:developer' as developer;
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../services/api_services.dart';
import '../models/post.dart';
import 'navbar.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  _ProfileScreenState createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final ApiService _apiService = ApiService();
  List<Post> _goals = [];
  List<Post> _events = [];
  bool _isLoading = true;
  final _bioController = TextEditingController();
  int _selectedTab = 0;

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  @override
  void dispose() {
    _bioController.dispose();
    _apiService.dispose();
    super.dispose();
  }

  Future<void> _loadProfile() async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final userId = authProvider.userId ?? '';
    final token = authProvider.token ?? '';

    if (userId.isEmpty || token.isEmpty) {
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please log in to view your profile')),
      );
      return;
    }

    try {
      developer.log('Loading profile data for userId=$userId',
          name: 'ProfileScreen');
      final goals = await _apiService.getAllGoals(token, userId);
      final events = await _apiService.getAllEvents(token, userId);

      if (mounted) {
        setState(() {
          _goals = goals;
          _events = events;
          _bioController.text = authProvider.bio ?? '';
          _isLoading = false;
        });
      }
    } catch (e, stackTrace) {
      developer.log('Load profile data error: $e',
          name: 'ProfileScreen', stackTrace: stackTrace);
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading profile: $e')),
        );
      }
    }
  }

  Future<void> _updateBio() async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final userId = authProvider.userId ?? '';
    final token = authProvider.token ?? '';

    if (_bioController.text.isEmpty || userId.isEmpty || token.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a bio')),
      );
      return;
    }

    try {
      developer.log('Updating bio for userId=$userId', name: 'ProfileScreen');
      await _apiService.updateBio(
        token: token,
        userId: userId,
        bio: _bioController.text,
      );
      await authProvider.setBio(_bioController.text);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Bio updated successfully')),
        );
      }
    } catch (e, stackTrace) {
      developer.log('Update bio error: $e',
          name: 'ProfileScreen', stackTrace: stackTrace);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error updating bio: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);
    return Scaffold(
      backgroundColor: const Color(0xFFF9F6F2),
      appBar: AppBar(
        backgroundColor: const Color(0xFFF9F6F2),
        elevation: 0,
        title: Text(
          authProvider.username ?? 'Unknown',
          style: const TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: Color(0xFF1A1A1A),
          ),
        ),
        actions: [
          IconButton(
            icon: Image.asset('assets/images/messages_icon.png', height: 24),
            onPressed: () {},
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : LayoutBuilder(
              builder: (context, constraints) {
                final screenWidth = constraints.maxWidth;
                final avatarRadius =
                    screenWidth * 0.15 > 50 ? 50.0 : screenWidth * 0.15;
                final gridCrossAxisCount =
                    screenWidth > 600 ? 3 : (screenWidth > 400 ? 2 : 1);

                return ConstrainedBox(
                  constraints: BoxConstraints(
                      maxHeight: MediaQuery.of(context).size.height -
                          kToolbarHeight -
                          kBottomNavigationBarHeight),
                  child: SingleChildScrollView(
                    padding: EdgeInsets.all(screenWidth * 0.03),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.start,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            CircleAvatar(
                              radius: avatarRadius,
                              backgroundColor: const Color(0xFF333333),
                              child: const Icon(
                                Icons.person,
                                color: Color(0xFFF9F6F2),
                                size: 40,
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    authProvider.username ?? 'Unknown',
                                    style: TextStyle(
                                      fontSize: screenWidth * 0.05 > 20
                                          ? 20.0
                                          : screenWidth * 0.05,
                                      fontWeight: FontWeight.bold,
                                      color: const Color(0xFF1A1A1A),
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  const Text(
                                    '0 followers  0 following',
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: Color(0xFF333333),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        TextFormField(
                          controller: _bioController,
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
                              onPressed: _updateBio,
                            ),
                          ),
                          maxLines: 1,
                          style: const TextStyle(
                            fontSize: 14,
                            color: Color(0xFF1A1A1A),
                          ),
                        ),
                        const SizedBox(height: 20),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceAround,
                          children: [
                            GestureDetector(
                              onTap: () => setState(() => _selectedTab = 0),
                              child: Text(
                                'Goals',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  color: _selectedTab == 0
                                      ? const Color(0xFFAFCBEA)
                                      : const Color(0xFF333333),
                                ),
                              ),
                            ),
                            GestureDetector(
                              onTap: () => setState(() => _selectedTab = 1),
                              child: Text(
                                'Events',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  color: _selectedTab == 1
                                      ? const Color(0xFFAFCBEA)
                                      : const Color(0xFF333333),
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 10),
                        GridView.builder(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          gridDelegate:
                              SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: gridCrossAxisCount,
                            crossAxisSpacing: screenWidth * 0.02,
                            mainAxisSpacing: screenWidth * 0.02,
                            childAspectRatio: 0.9,
                          ),
                          itemCount: _selectedTab == 0
                              ? _goals.length
                              : _events.length,
                          clipBehavior: Clip.hardEdge,
                          itemBuilder: (context, index) {
                            final post = _selectedTab == 0
                                ? _goals[index]
                                : _events[index];
                            final createdAt = post.createdAt
                                .toLocal()
                                .toString()
                                .split(' ')[0];
                            return Container(
                              decoration: BoxDecoration(
                                color: const Color(0xFFDDDDDD),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Stack(
                                children: [
                                  Padding(
                                    padding: const EdgeInsets.all(8.0),
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      mainAxisAlignment:
                                          MainAxisAlignment.spaceBetween,
                                      children: [
                                        Text(
                                          createdAt,
                                          style: const TextStyle(
                                            fontSize: 12,
                                            color: Color(0xFF333333),
                                          ),
                                        ),
                                        Text(
                                          post.title ?? 'No title',
                                          style: const TextStyle(
                                            fontSize: 14,
                                            fontWeight: FontWeight.bold,
                                            color: Color(0xFF1A1A1A),
                                          ),
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                        Text(
                                          post.text ?? 'No description',
                                          style: const TextStyle(
                                            fontSize: 12,
                                            color: Color(0xFF1A1A1A),
                                          ),
                                          maxLines: 2,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ],
                                    ),
                                  ),
                                  if (_selectedTab == 0 && post.tasks != null)
                                    Positioned(
                                      bottom: 4,
                                      right: 4,
                                      child: Container(
                                        padding: const EdgeInsets.all(4),
                                        color: const Color(0xFF333333),
                                        child: Text(
                                          '${post.tasks!.where((task) => task['completed'] ?? false).length}/${post.tasks!.length}',
                                          style: const TextStyle(
                                            fontSize: 10,
                                            color: Color(0xFFF9F6F2),
                                          ),
                                        ),
                                      ),
                                    ),
                                ],
                              ),
                            );
                          },
                        ),
                      ],
                    ),
                  ),
                );
              },
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
}
