import 'dart:async';
import 'dart:developer' as developer;
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../services/api_services.dart';
import '../models/post.dart';
import 'navbar.dart';

class SearchScreen extends StatefulWidget {
  const SearchScreen({super.key});

  @override
  _SearchScreenState createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _selectedFilter = 'Goals';
  List<Post> _searchResults = [];
  bool _isLoading = false;
  Timer? _debounce;

  @override
  void initState() {
    super.initState();
    _searchController.addListener(_onSearchChanged);
  }

  @override
  void dispose() {
    _searchController.removeListener(_onSearchChanged);
    _searchController.dispose();
    _debounce?.cancel();
    super.dispose();
  }

  void _onSearchChanged() {
    if (_debounce?.isActive ?? false) _debounce!.cancel();
    _debounce = Timer(const Duration(milliseconds: 500), () {
      if (_searchController.text.isNotEmpty) {
        _performSearch();
      } else {
        setState(() {
          _searchResults = [];
        });
      }
    });
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
        setState(() {
          _isLoading = false;
        });
        return;
      }
      final token = authProvider.token!;
      final apiService = ApiService();
      final results = await apiService.search(
        token,
        _searchController.text,
        _selectedFilter,
      );
      if (mounted) {
        setState(() {
          _searchResults = results;
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

  void _showFilterDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Select Filter'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              title: const Text('Goals'),
              onTap: () {
                setState(() {
                  _selectedFilter = 'Goals';
                });
                if (_searchController.text.isNotEmpty) _performSearch();
                Navigator.pop(context);
              },
            ),
            ListTile(
              title: const Text('Events'),
              onTap: () {
                setState(() {
                  _selectedFilter = 'Events';
                });
                if (_searchController.text.isNotEmpty) _performSearch();
                Navigator.pop(context);
              },
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF9F6F2),
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _searchController,
                      decoration: InputDecoration(
                        hintText: 'Search $_selectedFilter...',
                        hintStyle: const TextStyle(color: Color(0xFF333333)),
                        filled: true,
                        fillColor: const Color(0xFFDDDDDD),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                          borderSide: BorderSide.none,
                        ),
                        prefixIcon:
                            const Icon(Icons.search, color: Color(0xFF333333)),
                        suffixIcon: _searchController.text.isNotEmpty
                            ? IconButton(
                                icon: const Icon(Icons.clear,
                                    color: Color(0xFF333333)),
                                onPressed: () {
                                  _searchController.clear();
                                  setState(() {
                                    _searchResults = [];
                                  });
                                },
                              )
                            : null,
                      ),
                      style: const TextStyle(color: Color(0xFF1A1A1A)),
                    ),
                  ),
                  const SizedBox(width: 8),
                  IconButton(
                    icon:
                        const Icon(Icons.filter_list, color: Color(0xFF333333)),
                    onPressed: _showFilterDialog,
                  ),
                  IconButton(
                    icon: Image.asset('assets/images/messages_icon.png',
                        height: 24),
                    onPressed: () {},
                  ),
                ],
              ),
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0),
                child: _isLoading
                    ? const Center(child: CircularProgressIndicator())
                    : _searchResults.isEmpty
                        ? const Center(child: Text('No results found'))
                        : ListView.builder(
                            itemCount: _searchResults.length,
                            itemBuilder: (context, index) {
                              final post = _searchResults[index];
                              return _buildCard(
                                title: post.title ?? 'No title',
                                username: post.username,
                                likes: post.numOfLikes,
                                createdAt: post.createdAt,
                              );
                            },
                          ),
              ),
            ),
          ],
        ),
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
    required String title,
    required String username,
    required int likes,
    required DateTime createdAt,
  }) {
    return Card(
      color: const Color(0xFFDDDDDD),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      margin: const EdgeInsets.only(bottom: 16.0),
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const CircleAvatar(
                  backgroundColor: Color(0xFF333333),
                  child: Icon(
                    Icons.person,
                    color: Color(0xFFF9F6F2),
                    size: 20,
                  ),
                  radius: 20,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        username,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF000000),
                        ),
                      ),
                      Text(
                        createdAt.toString().split(' ')[0],
                        style: const TextStyle(
                          fontSize: 12,
                          color: Color(0xFF333333),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              title,
              style: const TextStyle(
                fontSize: 16,
                color: Color(0xFF1A1A1A),
              ),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                const Icon(Icons.favorite_border,
                    color: Color(0xFF333333), size: 20),
                const SizedBox(width: 4),
                Text(
                  '$likes',
                  style: const TextStyle(color: Color(0xFF1A1A1A)),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
