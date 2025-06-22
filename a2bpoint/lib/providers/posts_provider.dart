import 'package:flutter/material.dart';
import 'dart:developer' as developer;
import '../models/post.dart';
import '../services/api_services.dart';

class PostsProvider with ChangeNotifier {
  final ApiService _apiService = ApiService();
  List<Post> _posts = [];
  bool _isLoading = false;
  String? _error;

  List<Post> get posts => _posts;
  bool get isLoading => _isLoading;
  String? get error => _error;

  Future<void> fetchPosts(String token) async {
    try {
      _isLoading = true;
      _error = null;
      notifyListeners();

      developer.log('Fetching posts with token', name: 'PostsProvider');
      final posts = await _apiService.getPosts(token);
      _posts = posts;
      developer.log('Fetched ${posts.length} posts', name: 'PostsProvider');
      for (var post in posts) {
        developer.log(
            'Post: id=${post.id}, type=${post.type}, text=${post.text}, userId=${post.user.id}',
            name: 'PostsProvider');
      }
    } catch (e, stackTrace) {
      developer.log('Error fetching posts: $e',
          name: 'PostsProvider', stackTrace: stackTrace);
      _error = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  void clearError() {
    _error = null;
    notifyListeners();
  }
}
