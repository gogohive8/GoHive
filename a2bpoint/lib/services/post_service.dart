import 'dart:convert';
import 'dart:developer' as developer;
import 'package:http/http.dart' as http;
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/post.dart';
import 'exceptions.dart';
import 'dart:io';

class PostService {
  final http.Client _client = http.Client();
  final SupabaseClient _supabase = Supabase.instance.client;

  static const String _postsUrl =
      'https://gohive-post-service-9ac288c0fa11.herokuapp.com';

  SupabaseClient get supabase => _supabase;

  Future<dynamic> _handleResponse(http.Response response) async {
    developer.log('Response: ${response.statusCode}, body: ${response.body}',
        name: 'PostService');
    if (response.statusCode >= 200 && response.statusCode < 300) {
      if (response.statusCode == 204) return {};
      return response.body.isNotEmpty ? jsonDecode(response.body) : {};
    }
    if (response.statusCode == 400) {
      final errorBody = jsonDecode(response.body);
      final errorMessage = errorBody['error']?.toString() ?? 'Invalid input';
      developer.log('Validation error: $errorMessage', name: 'PostService');
      throw DataValidationException('Invalid input: $errorMessage');
    }
    if (response.statusCode == 401) {
      developer.log('Unauthorized: ${response.body}', name: 'PostService');
      throw AuthenticationException('Unauthorized: ${response.body}');
    }
    throw Exception('Request failed: ${response.statusCode} ${response.body}');
  }

  // НОВЫЕ МЕТОДЫ С ПАГИНАЦИЕЙ
  Future<List<Post>> getGoalsPaginated(
    String token, 
    String userId, {
    int offset = 0, 
    int limit = 20,
  }) async {
    try {
      developer.log('Fetching goals offset $offset with limit $limit', name: 'PostService');
      
      final response = await _client.get(
        Uri.parse('$_postsUrl/goals/all?offset=$offset&limit=$limit'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      ).timeout(const Duration(seconds: 10));

      final data = await _handleResponse(response);
      final posts = (data as List<dynamic>).map((json) {
        // Обработка image_urls
        List<String>? imageUrls;
        if (json['image_urls'] != null) {
          if (json['image_urls'] is String && json['image_urls'].isNotEmpty) {
            imageUrls = [json['image_urls']];
          } else if (json['image_urls'] is List) {
            imageUrls = (json['image_urls'] as List)
                .where((item) => item != null)
                .map((item) => item.toString())
                .toList();
          }
        }

        return Post.fromJson({
          ...json,
          'type': 'goal',
          'description': json['goalInfo']?.toString() ?? '',
          'created_at': json['created_at']?.toString() ??
              DateTime.now().toIso8601String(),
          'numOfLikes': json['numOfLikes'] ?? 0,
          'numOfComments': json['numOfComments'] ?? 0,
          'id': json['id']?.toString() ?? '',
          'userID': json['userID']?.toString() ?? 'unknown',
          'username': json['username']?.toString() ?? 'Unknown',
          'likedCurrentGoal': json['likedCurrentGoal'] ?? false,
          'image_urls': imageUrls,
        }, type: 'goal');
      }).toList();

      developer.log('Loaded ${posts.length} goals (offset $offset)', name: 'PostService');
      return posts;
    } catch (e, stackTrace) {
      developer.log('Get goals paginated error: $e',
          name: 'PostService', stackTrace: stackTrace);
      
      // Fallback на старый метод если пагинация не поддерживается
      if (offset == 0 && e.toString().contains('404')) {
        developer.log('Pagination not supported, falling back to getAllGoals', name: 'PostService');
        return await getAllGoals(token, userId);
      }
      rethrow;
    }
  }

  Future<List<Post>> getEventsPaginated(
    String token, 
    String userId, {
    int offset = 0, 
    int limit = 20,
  }) async {
    try {
      developer.log('Fetching events offset $offset with limit $limit', name: 'PostService');

      final response = await http.get(
        Uri.parse('$_postsUrl/events/all?offset=$offset&limit=$limit'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      developer.log('Events paginated fetch response: ${response.statusCode}',
          name: 'PostService');

      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        developer.log('Loaded ${data.length} events (offset $offset)', name: 'PostService');

        return data.map((json) {
          // Обработка image_urls для событий
          List<String>? imageUrls;
          if (json['image_urls'] != null) {
            if (json['image_urls'] is String && json['image_urls'].isNotEmpty) {
              imageUrls = [json['image_urls']];
            } else if (json['image_urls'] is List) {
              imageUrls = (json['image_urls'] as List)
                  .where((item) => item != null)
                  .map((item) => item.toString())
                  .toList();
            }
          }
          
          return Post.fromJson({
            'id': json['id'],
            'userID': json['userID'],
            'username': json['username'],
            'description': json['description'],
            'location': json['location'],
            'date_time': json['date_time'],
            'numOfLikes': json['numOfLikes'],
            'numOfComments': json['numOfComments'],
            'created_at': json['created_at'],
            'image_urls': imageUrls,
          }, type: 'event');
        }).toList();
      } else {
        final errorData = jsonDecode(response.body);
        throw Exception('Failed to fetch events: ${errorData['error']}');
      }
    } catch (e, stackTrace) {
      developer.log('Error fetching events paginated: $e',
          name: 'PostService', stackTrace: stackTrace);
      
      // Fallback на старый метод если пагинация не поддерживается
      if (offset == 0 && e.toString().contains('404')) {
        developer.log('Pagination not supported, falling back to getAllEvents', name: 'PostService');
        return await getAllEvents(token, userId);
      }
      rethrow;
    }
  }

  // СТАРЫЕ МЕТОДЫ (оставляем для обратной совместимости)
  Future<String> uploadMedia(File file, String token) async {
    try {
      developer.log('Uploading media file: ${file.path}', name: 'PostService');

      var request =
          http.MultipartRequest('POST', Uri.parse('$_postsUrl/upload'));
      request.headers['Authorization'] = 'Bearer $token';

      var multipartFile = await http.MultipartFile.fromPath('files', file.path);
      request.files.add(multipartFile);

      var streamedResponse = await request.send();
      var response = await http.Response.fromStream(streamedResponse);

      developer.log('Upload response: ${response.statusCode}',
          name: 'PostService');
      developer.log('Upload response body: ${response.body}',
          name: 'PostService');

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data is Map && data.containsKey('url')) {
          return data['url'];
        } else if (data is List && data.isNotEmpty) {
          return data[0];
        } else {
          throw Exception('Invalid upload response format');
        }
      } else {
        final errorData = jsonDecode(response.body);
        throw Exception('Failed to upload media: ${errorData['error']}');
      }
    } catch (e, stackTrace) {
      developer.log('Error uploading media: $e',
          name: 'PostService', stackTrace: stackTrace);
      throw Exception('Failed to upload media: $e');
    }
  }

  Future<void> createGoal({
    required String userId,
    required String description,
    required String location,
    required String interest,
    required String pointA,
    required String pointB,
    required List<Map<String, dynamic>> tasks,
    List<String>? imageUrls,
    required String token,
  }) async {
    try {
      developer.log('Creating goal with userId: $userId', name: 'PostService');

      final response = await http.post(
        Uri.parse('$_postsUrl/goals/create'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode({
          'user_id': userId,
          'description': description,
          'location': location,
          'interest': interest,
          'point_a': pointA,
          'point_b': pointB,
          'tasks': tasks,
          'image_urls': imageUrls,
        }),
      );

      developer.log('Goal creation response: ${response.statusCode}',
          name: 'PostService');
      developer.log('Goal creation response body: ${response.body}',
          name: 'PostService');

      if (response.statusCode != 200) {
        final errorData = jsonDecode(response.body);
        throw Exception('Failed to create goal: ${errorData['error']}');
      }
    } catch (e, stackTrace) {
      developer.log('Error creating goal: $e',
          name: 'PostService', stackTrace: stackTrace);
      throw Exception('Failed to create goal: $e');
    }
  }

  Future<void> createEvent({
    required String userId,
    required String description,
    required String location,
    required String interest,
    required String dateTime,
    required String token,
    List<String>? imageUrls,
  }) async {
    try {
      final body = {
        'user_id': userId,
        'description': description,
        'location': location,
        'interest': interest,
        'date_time': dateTime,
        if (imageUrls != null && imageUrls.isNotEmpty) 'image_urls': imageUrls,
      };

      developer.log(
          'Creating event for userId: $userId, body: ${jsonEncode(body)}',
          name: 'PostService');

      final response = await _client
          .post(
            Uri.parse('$_postsUrl/events/create'),
            headers: {
              'Content-Type': 'application/json',
              'Authorization': 'Bearer $token',
            },
            body: jsonEncode(body),
          )
          .timeout(const Duration(seconds: 30));

      developer.log(
          'CreateEvent response: ${response.statusCode}, ${response.body}',
          name: 'PostService');

      await _handleResponse(response);
    } catch (e, stackTrace) {
      developer.log('CreateEvent error: $e',
          name: 'PostService', stackTrace: stackTrace);
      rethrow;
    }
  }

  Future<List<Post>> getAllGoals(String token, String userId) async {
    try {
      developer.log('Fetching all goals for userId: $userId',
          name: 'PostService');
      final response = await _client.get(
        Uri.parse('$_postsUrl/goals/all'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      ).timeout(const Duration(seconds: 10));

      final data = await _handleResponse(response);
      final posts = (data as List<dynamic>).map((json) {
        List<String>? imageUrls;
        if (json['image_urls'] != null) {
          if (json['image_urls'] is String && json['image_urls'].isNotEmpty) {
            imageUrls = [json['image_urls']];
          } else if (json['image_urls'] is List) {
            imageUrls = (json['image_urls'] as List)
                .where((item) => item != null)
                .map((item) => item.toString())
                .toList();
          }
        }

        return Post.fromJson({
          ...json,
          'type': 'goal',
          'description': json['goalInfo']?.toString() ?? '',
          'created_at': json['created_at']?.toString() ??
              DateTime.now().toIso8601String(),
          'numOfLikes': json['numOfLikes'] ?? 0,
          'numOfComments': json['numOfComments'] ?? 0,
          'id': json['id']?.toString() ?? '',
          'userID': json['userID']?.toString() ?? 'unknown',
          'username': json['username']?.toString() ?? 'Unknown',
          'likedCurrentGoal': json['likedCurrentGoal'] ?? false,
          'image_urls': imageUrls,
        }, type: 'goal');
      }).toList();

      developer.log('Parsed ${posts.length} goals', name: 'PostService');
      return posts;
    } catch (e, stackTrace) {
      developer.log('Get all goals error: $e',
          name: 'PostService', stackTrace: stackTrace);
      rethrow;
    }
  }

  Future<List<Post>> getAllEvents(String token, String userId) async {
    try {
      developer.log('Fetching all events', name: 'PostService');

      final response = await http.get(
        Uri.parse('$_postsUrl/events/all'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      developer.log('Events fetch response: ${response.statusCode}',
          name: 'PostService');

      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        developer.log('Received ${data.length} events', name: 'PostService');

        return data.map((json) {
          return Post.fromJson({
            'id': json['id'],
            'userID': json['userID'],
            'username': json['username'],
            'description': json['description'],
            'location': json['location'],
            'date_time': json['date_time'],
            'numOfLikes': json['numOfLikes'],
            'numOfComments': json['numOfComments'],
            'created_at': json['created_at'],
            'image_urls': json['image_urls'],
          }, type: 'event');
        }).toList();
      } else {
        final errorData = jsonDecode(response.body);
        throw Exception('Failed to fetch events: ${errorData['error']}');
      }
    } catch (e, stackTrace) {
      developer.log('Error fetching events: $e',
          name: 'PostService', stackTrace: stackTrace);
      throw Exception('Failed to fetch events: $e');
    }
  }

  Future<List<Post>> getPosts(String token) async {
    try {
      developer.log('Attempting to fetch posts with token', name: 'PostService');
      final response = await _client.get(
        Uri.parse('$_postsUrl/goals/all'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      ).timeout(const Duration(seconds: 10));
      final data = await _handleResponse(response);
      final posts = (data as List<dynamic>)
          .map((json) => Post.fromJson({
                ...json,
                'type': 'goal',
                'userID': json['userID']?.toString() ??
                    json['user_id']?.toString() ??
                    'unknown',
                'username': json['username']?.toString() ?? 'Unknown',
                'numOfComments': json['numOfComments'] ?? 0,
                'description': json['description']?.toString() ??
                    json['goalInfo']?.toString() ??
                    '',
                'created_at': json['created_at']?.toString() ??
                    DateTime.now().toIso8601String(),
                'tasks': json['tasks'] ?? [],
                'numOfLikes': json['numOfLikes'] ?? 0,
                'id': json['id']?.toString() ?? '',
                'likes': json['likes'] ?? [],
              }, type: 'goal'))
          .toList();
      developer.log('Parsed ${posts.length} posts', name: 'PostService');
      return posts;
    } catch (e, stackTrace) {
      developer.log('Get posts error: $e',
          name: 'PostService', stackTrace: stackTrace);
      rethrow;
    }
  }

  Future<List<Post>> getGoals(String userId, String token) async {
    try {
      developer.log('GetGoals request: userId: $userId', name: 'PostService');
      final response = await _client.get(
        Uri.parse('$_postsUrl/goals/$userId'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      ).timeout(const Duration(seconds: 30));
      final data = await _handleResponse(response);
      final posts = (data as List<dynamic>)
          .map((json) => Post.fromJson({
                ...json,
                'type': 'goal',
                'userID': json['user_id']?.toString() ??
                    json['ID']?.toString() ??
                    'unknown',
                'username': json['username']?.toString() ?? 'Unknown',
                'description': json['description']?.toString() ??
                    json['goalInfo']?.toString() ??
                    '',
                'created_at': json['created_at']?.toString() ??
                    DateTime.now().toIso8601String(),
                'tasks': json['tasks'] ?? [],
                'numOfLikes': json['numOfLikes'] ?? 0,
                'numOfComments': json['numOfComments'] ?? 0,
                'id': json['id']?.toString() ?? '',
                'likes': json['likes'] ?? [],
                'photo_urls': json['photoURL'] ?? [],
              }, type: 'goal'))
          .toList();
      developer.log('Parsed ${posts.length} user goals', name: 'PostService');
      return posts;
    } catch (e, stackTrace) {
      developer.log('GetGoals error: $e',
          name: 'PostService', stackTrace: stackTrace);
      return [];
    }
  }

  Future<List<Post>> getEvents(String userId, String token) async {
    try {
      developer.log('GetEvents request: userId: $userId', name: 'PostService');
      final response = await _client.get(
        Uri.parse('$_postsUrl/events/$userId'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      ).timeout(const Duration(seconds: 30));
      final data = await _handleResponse(response);
      final posts = (data as List<dynamic>)
          .map((json) => Post.fromJson({
                ...json,
                'type': 'event',
                'userID': json['user_id']?.toString() ?? 'unknown',
                'username': json['username']?.toString() ?? 'Unknown',
                'description': json['description']?.toString() ?? '',
                'created_at': json['createdAt']?.toString() ??
                    DateTime.now().toIso8601String(),
                'numOfLikes': json['numOfLikes'] ?? 0,
                'numOfComments': json['numOfComments'] ?? 0,
                'id': json['id']?.toString() ?? '',
                'likes': json['likes'] ?? [],
                'date_time': json['date_time'] ?? [],
                'image_urls': json['photoURL'] ?? [],
              }, type: 'event'))
          .toList();
      developer.log('Parsed ${posts.length} user events', name: 'PostService');
      return posts;
    } catch (e, stackTrace) {
      developer.log('GetEvents error: $e',
          name: 'PostService', stackTrace: stackTrace);
      return [];
    }
  }

  Future<Post> getPostById(String post_id, String token) async {
    try {
      developer.log('Fetching post by id: $post_id', name: 'PostService');
      final response = await _client.get(
        Uri.parse('$_postsUrl/posts/$post_id'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      ).timeout(const Duration(seconds: 10));
      final data = await _handleResponse(response);
      return Post.fromJson({
        ...data,
        'type': data['type']?.toString() ?? 'goal',
        'userID': data['userID']?.toString() ??
            data['user_id']?.toString() ??
            'unknown',
        'username': data['username']?.toString() ?? 'Unknown',
        'description': data['description']?.toString() ??
            data['goalInfo']?.toString() ??
            '',
        'created_at':
            data['created_at']?.toString() ?? DateTime.now().toIso8601String(),
        'tasks': data['tasks'] ?? [],
        'numOfLikes': data['numOfLikes'] ?? 0,
        'numOfComments': data['numOfComments'] ?? 0,
        'id': data['id']?.toString() ?? '',
        'likes': data['likes'] ?? [],
      }, type: data['type']?.toString() ?? 'goal');
    } catch (e, stackTrace) {
      developer.log('Get post by id error: $e',
          name: 'PostService', stackTrace: stackTrace);
      rethrow;
    }
  }

  Future<Map<String, dynamic>> likePost(
      String postId, String userId, String token) async {
    try {
      developer.log('Liking post: $postId', name: 'PostService');

      final response = await http.post(
        Uri.parse('$_postsUrl/like'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode({
          'post_id': postId,
          'user_id': userId,
        }),
      );

      developer.log('Like response: ${response.statusCode}',
          name: 'PostService');

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return {
          'message': data['message'],
          'numOfLikes': data['numOfLikes'],
        };
      } else {
        final errorData = jsonDecode(response.body);
        throw Exception('Failed to like post: ${errorData['error']}');
      }
    } catch (e, stackTrace) {
      developer.log('Error liking post: $e',
          name: 'PostService', stackTrace: stackTrace);
      throw Exception('Failed to like post: $e');
    }
  }

  Future<void> joinEvent(String eventId, String userId, String token) async {
    try {
      developer.log('Joining event: $eventId', name: 'PostService');

      final response = await http.post(
        Uri.parse('$_postsUrl/joinEvent'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode({
          'post_id': eventId,
          'user_id': userId,
        }),
      );

      developer.log('Join event response: ${response.statusCode}',
          name: 'PostService');

      if (response.statusCode != 200) {
        final errorData = jsonDecode(response.body);
        throw Exception('Failed to join event: ${errorData['error']}');
      }
    } catch (e, stackTrace) {
      developer.log('Error joining event: $e',
          name: 'PostService', stackTrace: stackTrace);
      throw Exception('Failed to join event: $e');
    }
  }
}