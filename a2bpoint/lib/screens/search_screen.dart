import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../services/api_services.dart';
import 'dart:developer' as developer;
import '../services/exceptions.dart';

class SearchScreen extends StatefulWidget {
  const SearchScreen({super.key});

  @override
  _SearchScreenState createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  final _searchController = TextEditingController();
  final ApiService _apiService = ApiService();
  List<Map<String, dynamic>> _searchResults = [];
  bool _isLoading = false;
  bool _hasSearched = false;

  @override
  void dispose() {
    _searchController.dispose();
    _apiService.dispose();
    super.dispose();
  }

  Future<void> _searchUsers() async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    if (!authProvider.isAuthenticated || authProvider.token == null) {
      authProvider.handleAuthError(
          context, AuthenticationException('Not authenticated'));
      return;
    }

    setState(() {
      _isLoading = true;
      _hasSearched = true;
    });
    try {
      final query = _searchController.text.trim();
      if (query.isEmpty) {
        setState(() {
          _searchResults = [];
          _isLoading = false;
        });
        return;
      }

      final results =
          await _apiService.search(query, token: authProvider.token!);
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
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Search error: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;

    return Scaffold(
      backgroundColor: const Color(0xFFF9F6F2),
      appBar: AppBar(
        backgroundColor: const Color(0xFFF9F6F2),
        title: const Text('Search', style: TextStyle(color: Color(0xFF1A1A1A))),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Search users...',
                filled: true,
                fillColor: const Color(0xFFDDDDDD),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: BorderSide.none,
                ),
                suffixIcon: IconButton(
                  icon: const Icon(Icons.search, color: Color(0xFF333333)),
                  onPressed: _searchUsers,
                ),
              ),
              onSubmitted: (_) => _searchUsers(),
            ),
            const SizedBox(height: 16),
            _isLoading
                ? const Center(child: CircularProgressIndicator())
                : !_hasSearched
                    ? const Center(child: Text('Enter a query to search users'))
                    : _searchResults.isEmpty
                        ? const Center(child: Text('No users found'))
                        : Expanded(
                            child: ListView.builder(
                              itemCount: _searchResults.length,
                              itemBuilder: (context, index) {
                                final user = _searchResults[index];
                                return Card(
                                  color: const Color(0xFFDDDDDD),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  margin: const EdgeInsets.only(bottom: 16),
                                  child: ListTile(
                                    leading: const CircleAvatar(
                                      backgroundColor: Color(0xFF333333),
                                      child: Icon(Icons.person,
                                          color: Color(0xFFF9F6F2)),
                                    ),
                                    title: Text(
                                      user['username'] ?? 'Unknown',
                                      style: const TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.bold,
                                        color: Color(0xFF1A1A1A),
                                      ),
                                    ),
                                    subtitle: Text(
                                      user['email'] ?? 'No email',
                                      style: const TextStyle(
                                          color: Color(0xFF333333)),
                                    ),
                                    onTap: () {
                                      // TODO: Navigate to user profile if needed
                                    },
                                  ),
                                );
                              },
                            ),
                          ),
          ],
        ),
      ),
    );
  }
}
