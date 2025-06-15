import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../providers/auth_provider.dart';
import '../services/api_services.dart';
import 'navbar.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  _ProfileScreenState createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final ApiService _apiService = ApiService();
  final ImagePicker _picker = ImagePicker();
  String? _avatarUrl;
  String? _username;
  int _followers = 0;
  int _following = 0;
  List<Map<String, dynamic>> _posts = [];

  @override
  void initState() {
    super.initState();
    _loadProfileData();
  }

  Future<void> _loadProfileData() async {
    try {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      if (authProvider.userId == null || !authProvider.isAuthenticated) {
        throw Exception('Пользователь не аутентифицирован');
      }
      final userResponse = await _apiService.supabase
          .from('users')
          .select('avatar_url, username, followers, following')
          .eq('id', authProvider.userId!) // Безопасно, так как проверено выше
          .single();
      final postsResponse = await _apiService.supabase
          .from('posts')
          .select('*, user(id, username)')
          .eq('user_id', authProvider.userId!);

      setState(() {
        _avatarUrl = userResponse['avatar_url'];
        _username = userResponse['username'];
        _followers = userResponse['followers'] ?? 0;
        _following = userResponse['following'] ?? 0;
        _posts = (postsResponse as List).cast<Map<String, dynamic>>();
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Ошибка загрузки профиля: $e')),
        );
      }
    }
  }

  Future<void> _pickAndUploadAvatar() async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    if (authProvider.userId == null || !authProvider.isAuthenticated) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Требуется авторизация')),
      );
      return;
    }
    final pickedFile = await _picker.pickImage(source: ImageSource.gallery);
    if (pickedFile != null) {
      final file = File(pickedFile.path);
      final fileName = DateTime.now().millisecondsSinceEpoch.toString();
      try {
        await _apiService.supabase.storage.from('avatars').uploadBinary(
              fileName,
              await file.readAsBytes(),
              fileOptions: FileOptions(
                contentType: 'image/jpeg',
                upsert: true,
              ),
            );
        final url =
            _apiService.supabase.storage.from('avatars').getPublicUrl(fileName);
        await _apiService.supabase
            .from('users')
            .update({'avatar_url': url}).eq('id', authProvider.userId!);
        setState(() {
          _avatarUrl = url;
        });
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Ошибка загрузки аватара: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final padding = size.width * 0.05;

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.purple),
          onPressed: () => Navigator.pop(context),
        ),
        elevation: 0,
        backgroundColor: Colors.white,
        toolbarHeight: 0,
      ),
      body: Column(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(vertical: 8),
            color: Colors.white,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                GestureDetector(
                  onTap: () {},
                  child: Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    decoration: BoxDecoration(
                      color: Colors.purple.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Text(
                      'Profile',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.purple,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: SingleChildScrollView(
              padding: EdgeInsets.all(padding),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Stack(
                    alignment: Alignment.center,
                    children: [
                      Container(
                        width: 64,
                        height: 64,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: Colors.grey[200],
                        ),
                        child: _avatarUrl != null
                            ? ClipOval(
                                child: Image.network(
                                  _avatarUrl!,
                                  fit: BoxFit.cover,
                                  errorBuilder: (context, error, stackTrace) =>
                                      Icon(Icons.person, size: 40),
                                ),
                              )
                            : const Icon(Icons.person, size: 40),
                      ),
                      Positioned(
                        bottom: 0,
                        right: 0,
                        child: IconButton(
                          icon: const Icon(Icons.camera_alt,
                              color: Colors.purple),
                          onPressed: _pickAndUploadAvatar,
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: size.height * 0.02),
                  Text(
                    _username ?? 'No username',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF1C0E31),
                    ),
                  ),
                  SizedBox(height: size.height * 0.01),
                  Text(
                    'I love soccer and boys playing soccer. I also eat fish every day',
                    style: TextStyle(
                      fontSize: 13,
                      color: Color(0xFF1C0E31),
                      height: 1.38,
                    ),
                  ),
                  SizedBox(height: size.height * 0.03),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('$_followers followers',
                          style: TextStyle(fontSize: 14)),
                      Text('$_following following',
                          style: TextStyle(fontSize: 14)),
                    ],
                  ),
                  SizedBox(height: size.height * 0.03),
                  Wrap(
                    spacing: 8,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(4),
                        decoration: BoxDecoration(
                          color: Colors.orange.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.emoji_events,
                                color: Colors.orange, size: 16),
                            Text(' Challenge winner'),
                          ],
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.all(4),
                        decoration: BoxDecoration(
                          color: Colors.green.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.check_circle,
                                color: Colors.green, size: 16),
                            Text(' Finished goals'),
                          ],
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.all(4),
                        decoration: BoxDecoration(
                          color: Colors.green.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.check_circle,
                                color: Colors.green, size: 16),
                            Text(' Attended'),
                          ],
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: size.height * 0.03),
                  Divider(color: Color(0x1A1C0E31), thickness: 1),
                  GridView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    gridDelegate:
                        const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 3,
                      crossAxisSpacing: 4,
                      mainAxisSpacing: 4,
                    ),
                    itemCount: _posts.length,
                    itemBuilder: (context, index) {
                      final post = _posts[index];
                      final isGoal = post['type'] == 'goal';
                      final imageUrl = post['image_urls']?.isNotEmpty == true
                          ? post['image_urls'][0]
                          : null;
                      return Stack(
                        children: [
                          Container(
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(8),
                              image: imageUrl != null
                                  ? DecorationImage(
                                      image: NetworkImage(imageUrl),
                                      fit: BoxFit.cover,
                                    )
                                  : null,
                            ),
                            child: imageUrl == null
                                ? const Center(
                                    child: Icon(Icons.image, size: 40))
                                : null,
                          ),
                          if (isGoal && post['tasks'] != null)
                            Positioned(
                              bottom: 4,
                              left: 4,
                              child: Container(
                                padding: const EdgeInsets.all(4),
                                color: Colors.black54,
                                child: Text(
                                  '${post['tasks'].where((task) => task['completed'] ?? false).length}/${post['tasks'].length} tasks',
                                  style: const TextStyle(
                                      color: Colors.white, fontSize: 12),
                                ),
                              ),
                            ),
                          if (!isGoal)
                            Positioned(
                              bottom: 4,
                              left: 4,
                              child: Container(
                                padding: const EdgeInsets.all(4),
                                color: Colors.black54,
                                child: Text(
                                  post['created_at'] != null
                                      ? DateTime.parse(post['created_at'])
                                          .toLocal()
                                          .toString()
                                          .split(' ')[0]
                                      : 'No date',
                                  style: const TextStyle(
                                      color: Colors.white, fontSize: 12),
                                ),
                              ),
                            ),
                        ],
                      );
                    },
                  ),
                ],
              ),
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
}
