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

  Future<void> likePost(String postId, bool isLiked, int currentLikes) async {
    try {
      developer.log('Updating likes for postId: $postId, isLiked: $isLiked',
          name: 'PostsProvider');
      final index = _posts.indexWhere((post) => post.id == postId);
      if (index != -1) {
        _posts[index] = Post(
          id: _posts[index].id,
          user: _posts[index].user,
          text: _posts[index].text,
          type: _posts[index].type,
          createdAt: _posts[index].createdAt,
          likes: isLiked ? currentLikes + 1 : currentLikes - 1,
          numComments: _posts[index].numComments,
          imageUrls: _posts[index].imageUrls,
          tasks: _posts[index].tasks,
        );
        notifyListeners();
      }
    } catch (e, stackTrace) {
      developer.log('Error updating post likes: $e',
          name: 'PostsProvider', stackTrace: stackTrace);
      rethrow;
    }
  }

  Future<void> addComment(String postId) async {
    try {
      developer.log('Adding comment to postId: $postId', name: 'PostsProvider');
      final index = _posts.indexWhere((post) => post.id == postId);
      if (index != -1) {
        _posts[index] = Post(
          id: _posts[index].id,
          user: _posts[index].user,
          text: _posts[index].text,
          type: _posts[index].type,
          createdAt: _posts[index].createdAt,
          likes: _posts[index].likes,
          numComments: _posts[index].numComments + 1,
          imageUrls: _posts[index].imageUrls,
          tasks: _posts[index].tasks,
        );
        notifyListeners();
      }
    } catch (e, stackTrace) {
      developer.log('Error adding comment: $e',
          name: 'PostsProvider', stackTrace: stackTrace);
      rethrow;
    }
  }

  void clearError() {
    _error = null;
    notifyListeners();
  }
}
