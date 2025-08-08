import 'dart:convert';
import 'dart:developer' as developer;
import 'package:http/http.dart' as http;
import '../models/comment.dart';

class CommentService {
  final http.Client _client = http.Client();
  
  static const String _commentsUrl = 
      'https://gohive-post-service-9ac288c0fa11.herokuapp.com';

  Future<List<Comment>> getComments(String postId, String token, String postType) async {
    try {
      developer.log('Fetching comments for post $postId of type $postType', 
          name: 'CommentService');

      final response = await _client.get(
        Uri.parse('$_commentsUrl/comments/$postId?post_type=$postType'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      ).timeout(const Duration(seconds: 10));

      developer.log('Comments response: ${response.statusCode}, Content-Type: ${response.headers['content-type']}', 
          name: 'CommentService');

      // ИСПРАВЛЕНИЕ: Проверяем статус код и Content-Type
      if (response.statusCode == 404) {
        developer.log('No comments found for post $postId (404)', name: 'CommentService');
        return []; // Возвращаем пустой список вместо ошибки
      }

      if (response.statusCode == 200) {
        // ИСПРАВЛЕНИЕ: Проверяем Content-Type перед парсингом
        final contentType = response.headers['content-type'] ?? '';
        if (!contentType.contains('application/json')) {
          developer.log('Server returned non-JSON response: $contentType', name: 'CommentService');
          developer.log('Response body: ${response.body}', name: 'CommentService');
          throw Exception('Server returned HTML instead of JSON - API endpoint may not exist');
        }

        // ИСПРАВЛЕНИЕ: Проверяем, что body не пустой
        if (response.body.isEmpty) {
          developer.log('Empty response body', name: 'CommentService');
          return [];
        }

        try {
          final dynamic jsonData = jsonDecode(response.body);
          
          // ИСПРАВЛЕНИЕ: Обрабатываем разные форматы ответа
          List<dynamic> data;
          if (jsonData is List) {
            data = jsonData;
          } else if (jsonData is Map && jsonData['fetchComments'] != null) {
            data = jsonData['fetchComments'] as List<dynamic>;
          } else if (jsonData is Map && jsonData['comments'] != null) {
            data = jsonData['comments'] as List<dynamic>;
          } else {
            developer.log('Unexpected JSON structure: $jsonData', name: 'CommentService');
            return [];
          }

          final comments = data.map((json) => Comment.fromJson(json)).toList();
          developer.log('Parsed ${comments.length} comments', name: 'CommentService');
          return comments;
          
        } catch (jsonError) {
          developer.log('JSON parsing error: $jsonError', name: 'CommentService');
          developer.log('Response body that failed to parse: ${response.body}', name: 'CommentService');
          throw Exception('Failed to parse JSON response: $jsonError');
        }
      } else {
        // ИСПРАВЛЕНИЕ: Безопасная обработка ошибок
        try {
          final errorData = jsonDecode(response.body);
          throw Exception('Failed to fetch comments: ${errorData['error']}');
        } catch (e) {
          // Если не удается распарсить JSON ошибки
          throw Exception('Failed to fetch comments: HTTP ${response.statusCode}');
        }
      }
    } catch (e, stackTrace) {
      developer.log('Error fetching comments: $e', 
          name: 'CommentService', stackTrace: stackTrace);
      
      // ИСПРАВЛЕНИЕ: Более информативные сообщения об ошибках
      if (e.toString().contains('FormatException')) {
        throw Exception('Server returned invalid response format (possibly HTML instead of JSON)');
      }
      throw Exception('Failed to fetch comments: $e');
    }
  }

  Future<Map<String, dynamic>> createComment(
    String postId,
    String userId,
    String text,
    String postType,
    String token, {
    String? taskId,
    String? imageUrl,
  }) async {
    try {
      final body = {
        'post_id': postId,
        'user_id': userId,
        'text': text,
        'post_type': postType,
        if (taskId != null) 'task_id': taskId,
        if (imageUrl != null) 'image_url': imageUrl,
      };

      developer.log(
          'Creating comment for post $postId, taskId: $taskId, hasImage: ${imageUrl != null}', 
          name: 'CommentService');

      final response = await _client.post(
        Uri.parse('$_commentsUrl/comments/create'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode(body),
      ).timeout(const Duration(seconds: 30));

      developer.log('Create comment response: ${response.statusCode}', 
          name: 'CommentService');

      if (response.statusCode == 200 || response.statusCode == 201) {
        final data = jsonDecode(response.body);
        developer.log('Comment created successfully', name: 'CommentService');
        return data;
      } else {
        // ИСПРАВЛЕНИЕ: Безопасная обработка ошибок создания
        try {
          final errorData = jsonDecode(response.body);
          throw Exception('Failed to create comment: ${errorData['error']}');
        } catch (e) {
          throw Exception('Failed to create comment: HTTP ${response.statusCode}');
        }
      }
    } catch (e, stackTrace) {
      developer.log('Error creating comment: $e', 
          name: 'CommentService', stackTrace: stackTrace);
      throw Exception('Failed to create comment: $e');
    }
  }

  Future<void> deleteComment(String commentId, String token) async {
    try {
      developer.log('Deleting comment $commentId', name: 'CommentService');

      final response = await _client.delete(
        Uri.parse('$_commentsUrl/comments/$commentId'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      ).timeout(const Duration(seconds: 10));

      developer.log('Delete comment response: ${response.statusCode}', 
          name: 'CommentService');

      if (response.statusCode != 200 && response.statusCode != 204) {
        try {
          final errorData = jsonDecode(response.body);
          throw Exception('Failed to delete comment: ${errorData['error']}');
        } catch (e) {
          throw Exception('Failed to delete comment: HTTP ${response.statusCode}');
        }
      }
    } catch (e, stackTrace) {
      developer.log('Error deleting comment: $e', 
          name: 'CommentService', stackTrace: stackTrace);
      throw Exception('Failed to delete comment: $e');
    }
  }

  Future<Map<String, dynamic>> updateComment(
    String commentId,
    String text,
    String token,
  ) async {
    try {
      developer.log('Updating comment $commentId', name: 'CommentService');

      final response = await _client.put(
        Uri.parse('$_commentsUrl/comments/$commentId'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode({
          'text': text,
        }),
      ).timeout(const Duration(seconds: 10));

      developer.log('Update comment response: ${response.statusCode}', 
          name: 'CommentService');

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data;
      } else {
        try {
          final errorData = jsonDecode(response.body);
          throw Exception('Failed to update comment: ${errorData['error']}');
        } catch (e) {
          throw Exception('Failed to update comment: HTTP ${response.statusCode}');
        }
      }
    } catch (e, stackTrace) {
      developer.log('Error updating comment: $e', 
          name: 'CommentService', stackTrace: stackTrace);
      throw Exception('Failed to update comment: $e');
    }
  }

  void dispose() {
    _client.close();
  }
}