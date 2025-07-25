import 'package:flutter/material.dart';
import '../models/post.dart';
import '../models/comment.dart';
import '../services/api_services.dart';
import 'dart:developer' as developer;

class PostsProvider with ChangeNotifier {
  final ApiService _apiService = ApiService();
  List<Post> _posts = [];
  List<Comment> _comments = [];
  bool _isLoading = false;
  String? _error;

  List<Post> get posts => _posts;
  List<Comment> get comments => _comments;
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

  Future<void> fetchComments(String postId, String token, String postType) async {
    try {
      _isLoading = true;
      _error = null;
      notifyListeners();

      developer.log('Fetching comments for post_id: $postId, post_type: $postType',
          name: 'PostsProvider');
      _comments = await _apiService.getComments(postId, token, postType);
      developer.log('Fetched ${_comments.length} comments', name: 'PostsProvider');
    } catch (e, stackTrace) {
      developer.log('Error fetching comments: $e',
          name: 'PostsProvider', stackTrace: stackTrace);
      _error = 'Failed to load comments. Please try again.';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> likePost(String postId, String userId, String token,
      bool isLiked, int currentNumOfLikes) async {
    try {
      developer.log(
          'Updating numOfLikes for post_id: $postId, isLiked: $isLiked',
          name: 'PostsProvider');
      final index = _posts.indexWhere((post) => post.id == postId);
      if (index != -1) {
        final result = await _apiService.likePost(postId, userId, token);
        _posts[index] = _posts[index].copyWith(
          numOfLikes: result['numOfLikes'] ?? currentNumOfLikes,
        );
        developer.log(
            'numOfLikes updated: post_id=$postId, numOfLikes=${result['numOfLikes']}',
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
      String postId, String userId, String text, String postType, String token) async {
    try {
      developer.log('Adding comment to post_id: $postId',
          name: 'PostsProvider');
      await _apiService.createComment(postId, userId, text, postType, token);
      final index = _posts.indexWhere((post) => post.id == postId);
      if (index != -1) {
        _posts[index] = _posts[index].copyWith(
          numComments: _posts[index].numComments + 1,
        );
        developer.log('Comment added: post_id=$postId', name: 'PostsProvider');
        notifyListeners();
      }
      // Обновляем комментарии
      await fetchComments(postId, token, postType);
    } catch (e, stackTrace) {
      developer.log('Error adding comment: $e',
          name: 'PostsProvider', stackTrace: stackTrace);
      _error = 'Failed to add comment.';
      notifyListeners();
      rethrow;
    }
  }

  Future<void> joinEvent(String eventId, String userId, String token) async {
    try {
      developer.log('Joining event: eventId=$eventId', name: 'PostsProvider');
      await _apiService.joinEvent(eventId, userId, token);
      developer.log('Joined event: eventId=$eventId', name: 'PostsProvider');
      notifyListeners();
    } catch (e, stackTrace) {
      developer.log('Error joining event: $e',
          name: 'PostsProvider', stackTrace: stackTrace);
      _error = 'Failed to join event.';
      notifyListeners();
      rethrow;
    }
  }

  void clearError() {
    _error = null;
    notifyListeners();
  }
}