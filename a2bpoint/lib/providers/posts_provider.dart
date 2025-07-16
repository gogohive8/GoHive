import 'package:flutter/material.dart';
import '../models/post.dart';
import '../services/api_services.dart';
import 'dart:developer' as developer;

class PostsProvider with ChangeNotifier {
  final ApiService _apiService = ApiService();
  List<Post> _posts = [];
  bool _isLoading = false;
  String? _error;

  List<Post> get posts => _posts;
  bool get isLoading => _isLoading;
  String? get error => _error;

  void setPosts(List<Post> posts) {
    _posts = posts;
    _isLoading = false;
    _error = null;
    developer.log('Posts updated: ${posts.length}', name: 'PostsProvider');
    notifyListeners();
  }

  Future<void> fetchPosts(String token, {bool isEvent = false}) async {
    try {
      _isLoading = true;
      _error = null;
      notifyListeners();

      developer.log('Fetching posts with token, isEvent=$isEvent',
          name: 'PostsProvider');
      final posts = isEvent
          ? await _apiService.getAllEvents(token, '')
          : await _apiService.getAllGoals(token, '');
      _posts = posts;
      developer.log('Fetched ${posts.length} posts', name: 'PostsProvider');
    } catch (e, stackTrace) {
      developer.log('Error fetching posts: $e',
          name: 'PostsProvider', stackTrace: stackTrace);
      _error = 'Failed to load posts. Please try again.';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> likePost(String post_id, String userId, String token,
      bool isLiked, int currentnumOfLikes) async {
    try {
      developer.log(
          'Updating numOfLikes for post_id: $post_id, isLiked: $isLiked',
          name: 'PostsProvider');
      final index = _posts.indexWhere((post) => post.id == post_id);
      if (index != -1) {
        final result = await _apiService.likePost(post_id, userId, token);
        _posts[index] = _posts[index].copyWith(
          numOfLikes: result['numOfnumOfLikes'],
        );
        developer.log(
            'numOfLikes updated: post_id=$post_id, numOfLikes=${result['numOfnumOfLikes']}',
            name: 'PostsProvider');
        notifyListeners();
      }
    } catch (e, stackTrace) {
      developer.log('Error updating post numOfLikes: $e',
          name: 'PostsProvider', stackTrace: stackTrace);
      _error = 'Failed to update like.';
      notifyListeners();
      rethrow;
    }
  }

  Future<void> addComment(
      String post_id, String userId, String text, String token) async {
    try {
      developer.log('Adding comment to post_id: $post_id',
          name: 'PostsProvider');
      await _apiService.createComment(post_id, userId, text, token);
      final index = _posts.indexWhere((post) => post.id == post_id);
      if (index != -1) {
        _posts[index] = _posts[index].copyWith(
          numComments: _posts[index].numComments + 1,
        );
        developer.log('Comment added: post_id=$post_id', name: 'PostsProvider');
        notifyListeners();
      }
    } catch (e, stackTrace) {
      developer.log('Error adding comment: $e',
          name: 'PostsProvider', stackTrace: stackTrace);
      _error = 'Failed to add comment.';
      notifyListeners();
      rethrow;
    }
  }

  void clearError() {
    _error = null;
    notifyListeners();
  }
}
