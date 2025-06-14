import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/post.dart';
import '../services/api_services.dart';
import '../data/dummy_data.dart';
import '../providers/auth_provider.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen>
    with SingleTickerProviderStateMixin {
  int _selectedIndex = 0;
  final ApiService _apiService = ApiService();
  late TabController _tabController;
  late Future<List<Post>> _postsFuture;
  final bool useDummyData = true;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _postsFuture =
        useDummyData ? Future.value(dummyPosts) : _apiService.getPosts();
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    if (!authProvider.isAuthenticated && !useDummyData) {
      _postsFuture = Future.value([]);
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  void _likePost(String postId, int currentLikes, int index) async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    if (!authProvider.isAuthenticated && !useDummyData) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Требуется авторизация')),
      );
      return;
    }
    try {
      if (!useDummyData) {
        await _apiService.likePost(postId);
      }
      setState(() {
        _postsFuture.then((posts) {
          if (index >= 0 && index < posts.length) {
            posts[index].likes = currentLikes + 1;
          }
        });
      });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Ошибка лайка: $e')),
      );
    }
  }

  void _logout() {
    Provider.of<AuthProvider>(context, listen: false).clearAuth();
    Navigator.pushReplacementNamed(context, '/sign-in');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('A2B Social'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () {},
          ),
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: _logout,
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'Goals'),
            Tab(text: 'Events'),
            Tab(text: 'Feed'),
          ],
          indicatorColor: Colors.white,
          labelColor: Colors.purple,
          unselectedLabelColor: Colors.grey,
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          // Goals Tab
          ListView.builder(
            padding: const EdgeInsets.all(8.0),
            itemCount: dummyGoals.length,
            itemBuilder: (context, index) {
              final goal = dummyGoals[index];
              return Card(
                margin: const EdgeInsets.symmetric(vertical: 8),
                child: ListTile(
                  leading: CircleAvatar(
                      backgroundImage: NetworkImage(goal['avatarUrl'])),
                  title: Text(goal['title']),
                  subtitle: Text(goal['description']),
                  trailing: IconButton(
                    icon: const Icon(Icons.favorite_border),
                    onPressed: () {
                      // Add goal like logic if needed
                    },
                  ),
                ),
              );
            },
          ),
          // Events Tab
          ListView.builder(
            padding: const EdgeInsets.all(8.0),
            itemCount: dummyEvents.length,
            itemBuilder: (context, index) {
              final event = dummyEvents[index];
              return Card(
                margin: const EdgeInsets.symmetric(vertical: 8),
                child: ListTile(
                  leading: CircleAvatar(
                      backgroundImage: NetworkImage(event['avatarUrl'])),
                  title: Text(event['title']),
                  subtitle: Text(event['description']),
                  trailing: ElevatedButton(
                    onPressed: () {
                      // Add event join logic if needed
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('Joined ${event['title']}')),
                      );
                    },
                    child: const Text('Join'),
                  ),
                ),
              );
            },
          ),
          // Feed Tab
          FutureBuilder<List<Post>>(
            future: _postsFuture,
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              } else if (snapshot.hasError) {
                return Center(child: Text('Ошибка: ${snapshot.error}'));
              } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
                return const Center(child: Text('Нет постов'));
              }
              final posts = snapshot.data!;
              return ListView.builder(
                itemCount: posts.length,
                itemBuilder: (context, index) {
                  final post = posts[index];
                  return Card(
                    margin:
                        const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        ListTile(
                          leading: CircleAvatar(
                            backgroundImage: NetworkImage(post.user.avatarUrl),
                          ),
                          title: Text(post.user.username),
                          subtitle: Text(post.createdAt.toString()),
                        ),
                        Image.network(
                          post.imageUrl,
                          height: 200,
                          width: double.infinity,
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) =>
                              const Center(child: Text('Ошибка изображения')),
                        ),
                        Padding(
                          padding: const EdgeInsets.all(8.0),
                          child: Text(post.text),
                        ),
                        Row(
                          children: [
                            IconButton(
                              icon: const Icon(Icons.favorite_border),
                              onPressed: () =>
                                  _likePost(post.id, post.likes, index),
                            ),
                            Text('${post.likes}'),
                            const SizedBox(width: 16),
                            IconButton(
                              icon: const Icon(Icons.comment),
                              onPressed: () {},
                            ),
                            Text('${post.comments}'),
                          ],
                        ),
                      ],
                    ),
                  );
                },
              );
            },
          ),
        ],
      ),
      bottomNavigationBar: BottomNavigationBar(
        items: [
          BottomNavigationBarItem(
            icon: Image.asset('assets/images/home.png', height: 24),
            label: 'Home',
          ),
          BottomNavigationBarItem(
            icon: Image.asset('assets/images/search.png', height: 24),
            label: 'Search',
          ),
          BottomNavigationBarItem(
            icon: Image.asset('assets/images/add.png', height: 24),
            label: 'Add',
          ),
          BottomNavigationBarItem(
            icon: Image.asset('assets/images/profile.png', height: 24),
            label: 'Profile',
          ),
          BottomNavigationBarItem(
            icon: Image.asset('assets/images/ai_mentor.png', height: 24),
            label: 'AI Mentor',
          ),
        ],
        currentIndex: _selectedIndex,
        selectedItemColor: Colors.purple,
        onTap: _onItemTapped,
        backgroundColor: Colors.white, // Базовый цвет фона
        elevation: 5,
      ),
    );
  }
}
