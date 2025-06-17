import 'dart:developer' as developer;
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../services/api_services.dart';
import '../models/post.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  _ProfileScreenState createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final ApiService _apiService = ApiService();
  Map<String, dynamic>? _profile;
  List<Post> _goals = [];
  List<Post> _events = [];
  bool _isLoading = true;
  final _bioController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadProfile();
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
          _bioController.text = profile?['bio'] ?? '';
          _isLoading = false;
        });
      }
    } catch (e, stackTrace) {
      developer.log('Load profile error: $e',
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

    if (_bioController.text.isEmpty || userId.isEmpty || token.isEmpty) return;

    try {
      developer.log('Updating bio for userId=$userId', name: 'ProfileScreen');
      final success =
          await _apiService.updateBio(userId, _bioController.text, token);
      if (success && mounted) {
        setState(() {
          _profile?['bio'] = _bioController.text;
        });
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

  Future<void> _uploadAvatar() async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: ImageSource.gallery);

    if (pickedFile == null) return;

    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final userId = authProvider.userId ?? '';
    final token = authProvider.token ?? '';

    if (userId.isEmpty || token.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please log in to upload an avatar')),
      );
      return;
    }

    try {
      developer.log('Uploading avatar for userId=$userId',
          name: 'ProfileScreen');
      final url =
          await _apiService.uploadAvatar(userId, pickedFile.path, token);
      if (url != null && mounted) {
        setState(() {
          _profile?['avatar_url'] = url;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Avatar updated successfully')),
        );
      }
    } catch (e, stackTrace) {
      developer.log('Upload avatar error: $e',
          name: 'ProfileScreen', stackTrace: stackTrace);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error uploading avatar: $e')),
        );
      }
    }
  }

  Future<void> _likePost(String postId) async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    if (authProvider.token?.isNotEmpty ?? false) {
      try {
        developer.log('Liking post: postId=$postId', name: 'ProfileScreen');
        await _apiService.likePost(postId, authProvider.token!);
      } catch (e, stackTrace) {
        developer.log('Like post error: $e',
            name: 'ProfileScreen', stackTrace: stackTrace);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error liking post: $e')),
          );
        }
      }
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please log in to like posts')),
      );
    }
  }

  Future<void> _joinEvent(String eventId) async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    if (authProvider.token?.isNotEmpty ?? false) {
      try {
        developer.log('Joining event: eventId=$eventId', name: 'ProfileScreen');
        await _apiService.joinEvent(eventId, authProvider.token!);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Joined event successfully')),
        );
      } catch (e, stackTrace) {
        developer.log('Join event error: $e',
            name: 'ProfileScreen', stackTrace: stackTrace);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error joining event: $e')),
          );
        }
      }
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please log in to join events')),
      );
    }
  }

  @override
  void dispose() {
    _bioController.dispose();
    _apiService.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Profile'),
        backgroundColor: const Color(0xFF7964FF),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _profile == null
              ? const Center(child: Text('Failed to load profile'))
              : SingleChildScrollView(
                  padding: EdgeInsets.all(size.width * 0.05),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Center(
                        child: Stack(
                          children: [
                            CircleAvatar(
                              radius: size.width * 0.15,
                              backgroundImage:
                                  _profile?['avatar_url'] != null &&
                                          _profile?['avatar_url'].isNotEmpty
                                      ? NetworkImage(_profile?['avatar_url'])
                                      : null,
                              child: _profile?['avatar_url'] == null ||
                                      _profile?['avatar_url'].isEmpty
                                  ? Icon(Icons.person, size: size.width * 0.1)
                                  : null,
                            ),
                            Positioned(
                              bottom: 0,
                              right: 0,
                              child: IconButton(
                                icon: const Icon(Icons.camera_alt,
                                    color: Colors.white),
                                onPressed: _uploadAvatar,
                              ),
                            ),
                          ],
                        ),
                      ),
                      SizedBox(height: size.height * 0.02),
                      Center(
                        child: Text(
                          _profile?['username'] ?? 'Unknown',
                          style: TextStyle(
                            fontSize: size.width * 0.06,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      SizedBox(height: size.height * 0.01),
                      TextFormField(
                        controller: _bioController,
                        decoration: InputDecoration(
                          labelText: 'Bio',
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                          suffixIcon: IconButton(
                            icon: const Icon(Icons.save),
                            onPressed: _updateBio,
                          ),
                        ),
                        maxLines: 3,
                      ),
                      SizedBox(height: size.height * 0.02),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Column(
                            children: [
                              Text(
                                '${_profile?['followers'] ?? 0}',
                                style: TextStyle(
                                  fontSize: size.width * 0.05,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const Text('Followers'),
                            ],
                          ),
                          SizedBox(width: size.width * 0.1),
                          Column(
                            children: [
                              Text(
                                '${_profile?['following'] ?? 0}',
                                style: TextStyle(
                                  fontSize: size.width * 0.05,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const Text('Following'),
                            ],
                          ),
                        ],
                      ),
                      SizedBox(height: size.height * 0.03),
                      const Text(
                        'Goals',
                        style: TextStyle(
                            fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                      _goals.isEmpty
                          ? const Padding(
                              padding: EdgeInsets.all(8.0),
                              child: Text('No goals found'),
                            )
                          : ListView.builder(
                              shrinkWrap: true,
                              physics: const NeverScrollableScrollPhysics(),
                              itemCount: _goals.length,
                              itemBuilder: (context, index) {
                                final goal = _goals[index];
                                return ListTile(
                                  title: Text(goal.text ?? 'No description'),
                                  subtitle: Text('By ${goal.user.username}'),
                                  trailing: IconButton(
                                    icon: const Icon(Icons.favorite_border),
                                    onPressed: () => _likePost(goal.id),
                                  ),
                                );
                              },
                            ),
                      SizedBox(height: size.height * 0.03),
                      const Text(
                        'Events',
                        style: TextStyle(
                            fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                      _events.isEmpty
                          ? const Padding(
                              padding: EdgeInsets.all(8.0),
                              child: Text('No events found'),
                            )
                          : ListView.builder(
                              shrinkWrap: true,
                              physics: const NeverScrollableScrollPhysics(),
                              itemCount: _events.length,
                              itemBuilder: (context, index) {
                                final event = _events[index];
                                return ListTile(
                                  title: Text(event.text ?? 'No description'),
                                  subtitle: Text('By ${event.user.username}'),
                                  trailing: IconButton(
                                    icon: const Icon(Icons.event),
                                    onPressed: () => _joinEvent(event.id),
                                  ),
                                );
                              },
                            ),
                    ],
                  ),
                ),
    );
  }
}
