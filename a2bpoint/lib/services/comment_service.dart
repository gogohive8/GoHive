import 'dart:convert';
import 'dart:developer' as developer;
import 'package:http/http.dart' as http;
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/comment.dart';
import 'exceptions.dart';

class CommentService {
  final http.Client _client = http.Client();
  final SupabaseClient _supabase = Supabase.instance.client;
  static const String _postsUrl =
      'https://gohive-post-service-9ac288c0fa11.herokuapp.com';

  SupabaseClient get supabase => _supabase;

  Future<dynamic> _handleResponse(http.Response response) async {
    developer.log('Response: ${response.statusCode}, body: ${response.body}',
        name: 'ApiService');
    if (response.statusCode >= 200 && response.statusCode < 300) {
      if (response.statusCode == 204) return {};
      return response.body.isNotEmpty ? jsonDecode(response.body) : {};
    }
    if (response.statusCode == 400) {
      final errorBody = jsonDecode(response.body);
      final errorMessage = errorBody['error']?.toString() ?? 'Invalid input';
      developer.log('Validation error: $errorMessage', name: 'ApiService');
      throw DataValidationException('Invalid input: $errorMessage');
    }
    if (response.statusCode == 401) {
      developer.log('Unauthorized: ${response.body}', name: 'ApiService');
      throw AuthenticationException('Unauthorized: ${response.body}');
    }
    throw Exception('Request failed: ${response.statusCode} ${response.body}');
  }

  // Future<http.Response> _makeRequest(
  //     Future<http.Response> Function() request, int retries) async {
  //   for (int attempt = 1; attempt <= retries; attempt++) {
  //     try {
  //       final response = await request().timeout(const Duration(seconds: 30));
  //       return response;
  //     } catch (e) {
  //       if (attempt == retries) rethrow;
  //       developer.log('Request attempt $attempt failed: $e',
  //           name: 'ApiService');
  //       await Future.delayed(Duration(milliseconds: 500 * attempt));
  //     }
  //   }
  //   throw Exception('Request failed after $retries attempts');
  // }

  Future<Map<String, dynamic>> createComment(String post_id, String userId,
      String text, String post_type, String token) async {
    try {
      developer.log(
          'Creating comment for post_id: $post_id, userId: $userId, text: $text',
          name: 'ApiService');
      final response = await _client
          .post(
            Uri.parse('$_postsUrl/posts/$post_id/comments'),
            headers: {
              'Authorization': 'Bearer $token',
              'Content-Type': 'application/json',
            },
            body: jsonEncode({
              'text': text,
              'userId': userId,
              'postId': post_id,
              'post_type': post_type // ИСПРАВЛЕНО: правильное название поля
            }),
          )
          .timeout(const Duration(seconds: 10));

      final data = await _handleResponse(response);

      // Возвращаем данные в правильном формате
      final comment = {
        'post_id': post_id,
        'userId': userId,
        'text': text,
        'id': DateTime.now().millisecondsSinceEpoch.toString(), // Временный ID
        'username': 'Current User', // Можно получить из AuthProvider
        'created_at': DateTime.now().toIso8601String(),
      };

      developer.log('Comment created: $comment', name: 'ApiService');
      return comment;
    } catch (e, stackTrace) {
      developer.log('Create comment error: $e',
          name: 'ApiService', stackTrace: stackTrace);
      rethrow;
    }
  }

  Future<List<Comment>> getComments(
      String post_id, String token, String post_type,
      {int limit = 10, int offset = 0}) async {
    try {
      developer.log(
          'Fetching comments for post_id: $post_id, limit: $limit, offset: $offset',
          name: 'ApiService');
      final response = await _client.get(
        Uri.parse(
            '$_postsUrl/posts/$post_id/comments?limit=$limit&offset=$offset&post_type=$post_type'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      ).timeout(const Duration(seconds: 10));

      final data = await _handleResponse(response);

      // ИСПРАВЛЕНО: правильная обработка ответа сервера
      if (data.isEmpty || data['fetchComments'] == null) {
        developer.log('No comments found for post_id: $post_id',
            name: 'ApiService');
        return [];
      }

      // Берем массив комментариев из fetchComments
      final commentsData = data['fetchComments'] as List<dynamic>;

      final comments = commentsData
          .map((json) => Comment.fromJson({
                'id': json['id']?.toString() ?? '',
                'post_id': post_id,
                'userId': json['userID']?.toString() ?? 'unknown', // ИСПРАВЛЕНО
                'username': json['username']?.toString() ?? 'Unknown',
                'text': json['comment']?.toString() ??
                    json['comments']?.toString() ??
                    '', // ИСПРАВЛЕНО
                'created_at': json['created_at']?.toString() ??
                    DateTime.now().toIso8601String(),
              }))
          .toList();

      developer.log(
          'Parsed ${comments.length} comments: ${comments.map((c) => c.id)}',
          name: 'ApiService');
      return comments;
    } catch (e, stackTrace) {
      developer.log('Get comments error: $e',
          name: 'ApiService', stackTrace: stackTrace);
      rethrow;
    }
  }
}
