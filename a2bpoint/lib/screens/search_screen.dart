import 'dart:developer' as developer;
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../services/api_services.dart';
import 'navbar.dart';

class SearchScreen extends StatefulWidget {
  const SearchScreen({super.key});

  @override
  _SearchScreenState createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _selectedFilter = 'Goals';
  List<dynamic> _searchResults = [];
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _searchController.addListener(_onSearchChanged);
  }

  @override
  void dispose() {
    _searchController.removeListener(_onSearchChanged);
    _searchController.dispose();
    super.dispose();
  }

  void _onSearchChanged() {
    if (_searchController.text.isNotEmpty) {
      _performSearch();
    } else {
      setState(() {
        _searchResults = [];
      });
    }
  }

  Future<void> _performSearch() async {
    setState(() {
      _isLoading = true;
    });
    try {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      if (!authProvider.isAuthenticated ||
          authProvider.token == null ||
          authProvider.userId == null) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Authorization required')),
          );
        }
        return;
      }
      final token = authProvider.token!;
      final userId = authProvider.userId!;
      final apiService = ApiService();
      final response = await apiService.search(
        _searchController.text,
        filter: _selectedFilter,
        token: token,
        userId: userId,
      );
      if (mounted) {
        setState(() {
          _searchResults = response['data'] ?? [];
          _isLoading = false;
        });
      }
    } catch (e, stackTrace) {
      developer.log('Search error: $e',
          name: 'SearchScreen', stackTrace: stackTrace);
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error searching: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    return Scaffold(
      body: Stack(
        children: [
          ClipPath(
            clipper: CustomShapeClipper(),
            child: Container(
              width: double.infinity,
              height: double.infinity,
              color: const Color(0xFFE9ECF4),
            ),
          ),
          SafeArea(
            child: Column(
              children: [
                // System Top (44dp)
                Container(
                  width: size.width,
                  height: 44,
                  color: Colors.transparent,
                ),
                // Light Tab and Icons
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: Container(
                          width: 263,
                          height: 34,
                          color: Colors.white,
                          child: const Center(
                              child: Text('Search Tab',
                                  style: TextStyle(color: Colors.black))),
                        ),
                      ),
                      Row(
                        children: [
                          Container(
                              width: 24,
                              height: 24,
                              color:
                                  Colors.grey), // Placeholder for linear_esse
                          const SizedBox(width: 40),
                          Container(
                              width: 24,
                              height: 24,
                              color:
                                  Colors.grey), // Placeholder for linear_mess
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 8),
                // Frame 3 (317dp x 20dp)
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0),
                  child: Container(
                    width: 317,
                    height: 20,
                    color: Colors.white.withOpacity(0.5),
                  ),
                ),
                const SizedBox(height: 16),
                // Vector 12 and 13
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0),
                  child: Row(
                    children: [
                      Container(
                          width: 343,
                          height: 1,
                          color: const Color(0x1A1C0E31)),
                      const SizedBox(width: 16),
                      Container(
                          width: 38, height: 1, color: const Color(0x1C0E31)),
                    ],
                  ),
                ),
                const SizedBox(height: 24),
                // Search Results
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16.0),
                    child: _isLoading
                        ? const Center(child: CircularProgressIndicator())
                        : ListView.builder(
                            itemCount: _searchResults.length,
                            itemBuilder: (context, index) {
                              final item = _searchResults[index];
                              return _buildCard(
                                imageUrl: item['imageUrl'] ??
                                    'https://via.placeholder.com/150',
                                title: item['title'] ?? 'No title',
                                username: item['username'] ?? 'Unknown',
                                likes: item['likes'] ?? 0,
                                comments: item['comments'] ?? 0,
                              );
                            },
                          ),
                  ),
                ),
              ],
            ),
          ),
          // Navigation Bar
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: ClipPath(
              clipper: NavBarClipper(),
              child: Container(
                height: 100,
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Color(0x00E9ECF4), Color(0xFFE9ECF4)],
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
      bottomNavigationBar: Navbar(
        selectedIndex: 1,
        onTap: (index) {
          final routes = ['/home', '/search', '/add', '/profile', '/ai-mentor'];
          Navigator.pushReplacementNamed(context, routes[index]);
        },
      ),
    );
  }

  Widget _buildCard({
    required String imageUrl,
    required String title,
    required String username,
    required int likes,
    required int comments,
  }) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Image.network(imageUrl,
              fit: BoxFit.cover, height: 200, width: double.infinity),
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Text(
              title,
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8.0),
            child: Text(
              username,
              style: const TextStyle(fontStyle: FontStyle.italic),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('$likes likes'),
                Text('$comments comments'),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class CustomShapeClipper extends CustomClipper<Path> {
  @override
  Path getClip(Size size) {
    final path = Path();
    path.moveTo(0, 0);
    path.lineTo(size.width, 0);
    path.lineTo(size.width, size.height - 100); // Leave space for nav bar
    path.lineTo(0, size.height - 100);
    path.close();
    return path;
  }

  @override
  bool shouldReclip(covariant CustomClipper<Path> oldClipper) => false;
}

class NavBarClipper extends CustomClipper<Path> {
  @override
  Path getClip(Size size) {
    final path = Path();
    path.moveTo(0, 0);
    path.lineTo(size.width, 0);
    path.lineTo(size.width, size.height);
    path.lineTo(0, size.height);
    path.close();
    return path;
  }

  @override
  bool shouldReclip(covariant CustomClipper<Path> oldClipper) => false;
}
