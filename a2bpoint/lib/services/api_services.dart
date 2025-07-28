import 'dart:convert';
import 'dart:developer' as developer;
import 'package:http/http.dart' as http;
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/post.dart';
import '../models/comment.dart';
import 'exceptions.dart';
import 'dart:io';
import 'package:dio/dio.dart' as dio;

class ApiService {
  final http.Client _client = http.Client();
  final SupabaseClient _supabase = Supabase.instance.client;
  static const String _baseUrl =
      'https://gohive-user-service-efb5dea164ed.herokuapp.com';
  static const String _postsUrl =
      'https://gohive-post-service-9ac288c0fa11.herokuapp.com';
  static const String _aiUrl =
      'https://gohive-ai-service-38f2e813d406.herokuapp.com';

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

  Future<http.Response> _makeRequest(
      Future<http.Response> Function() request, int retries) async {
    for (int attempt = 1; attempt <= retries; attempt++) {
      try {
        final response = await request().timeout(const Duration(seconds: 30));
        return response;
      } catch (e) {
        if (attempt == retries) rethrow;
        developer.log('Request attempt $attempt failed: $e',
            name: 'ApiService');
        await Future.delayed(Duration(milliseconds: 500 * attempt));
      }
    }
    throw Exception('Request failed after $retries attempts');
  }

  Future<String> generateGoal(String prompt, String token) async {
    try {
      developer.log('Sending goal generation request: prompt: $prompt',
          name: 'ApiService');
      final response = await _client
          .post(
            Uri.parse('$_aiUrl/api/generate-goal'),
            headers: {
              'Authorization': 'Bearer $token',
              'Content-Type': 'application/json',
            },
            body: jsonEncode({'prompt': prompt}),
          )
          .timeout(const Duration(seconds: 30));
      final data = await _handleResponse(response);
      final aiResponse = data.toString();
      developer.log('Goal generation response: $aiResponse}',
          name: 'ApiService');
      return aiResponse;
    } catch (e, stackTrace) {
      developer.log('Goal generation error: $e',
          name: 'ApiService', stackTrace: stackTrace);
      throw Exception('Failed to generate goal: $e');
    }
  }

  Future<String> generateEvent(String prompt, String token) async {
    try {
      developer.log('Sending event generation request: prompt: $prompt',
          name: 'ApiService');
      final response = await _client
          .post(
            Uri.parse('$_aiUrl/api/generate-event'),
            headers: {
              'Authorization': 'Bearer $token',
              'Content-Type': 'application/json',
            },
            body: jsonEncode({'prompt': prompt}),
          )
          .timeout(const Duration(seconds: 30));
      final data = await _handleResponse(response);
      final aiResponse = data.toString();
      developer.log('Event generation response: $aiResponse}',
          name: 'ApiService');
      return aiResponse;
    } catch (e, stackTrace) {
      developer.log('Event generation error: $e',
          name: 'ApiService', stackTrace: stackTrace);
      throw Exception('Failed to generate event: $e');
    }
  }

  Future<String> uploadMedia(File file, String token) async {
    try {
      developer.log('Uploading media file: ${file.path}', name: 'ApiService');
      
      var request = http.MultipartRequest('POST', Uri.parse('$_baseUrl/upload'));
      request.headers['Authorization'] = 'Bearer $token';
      
      var multipartFile = await http.MultipartFile.fromPath('files', file.path);
      request.files.add(multipartFile);

      var streamedResponse = await request.send();
      var response = await http.Response.fromStream(streamedResponse);

      developer.log('Upload response: ${response.statusCode}', name: 'ApiService');
      developer.log('Upload response body: ${response.body}', name: 'ApiService');

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        // Сервер может вернуть либо объект с url, либо массив URL
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
      developer.log('Error uploading media: $e', name: 'ApiService', stackTrace: stackTrace);
      throw Exception('Failed to upload media: $e');
    }
  }

  Future<List<Comment>> getComments(String postId, String token, String postType) async {
    try {
      developer.log('Fetching comments for post: $postId', name: 'ApiService');
      
      final response = await http.get(
        Uri.parse('$_baseUrl/posts/$postId/comments?post_type=$postType'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      developer.log('Get comments response: ${response.statusCode}', name: 'ApiService');

      if (response.statusCode == 200) {
        final dynamic data = jsonDecode(response.body);
        List<dynamic> comments;
        
        // Обрабатываем разные форматы ответа от сервера
        if (data is Map && data.containsKey('fetchComments')) {
          comments = data['fetchComments'];
        } else if (data is List) {
          comments = data;
        } else {
          comments = [];
        }
        
        return comments.map((json) => Comment.fromJson(json)).toList();
      } else {
        final errorData = jsonDecode(response.body);
        throw Exception('Failed to get comments: ${errorData['error']}');
      }
    } catch (e, stackTrace) {
      developer.log('Error getting comments: $e', name: 'ApiService', stackTrace: stackTrace);
      throw Exception('Failed to get comments: $e');
    }
  }

  // Replace the createComment method in your ApiService with this:
Future<Map<String, dynamic>> createComment(String postId, String userId, String text, String postType, String token) async {
  try {
    developer.log('Creating comment for post: $postId', name: 'ApiService');
    
    final response = await http.post(
      Uri.parse('$_baseUrl/posts/$postId/comments'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
      body: jsonEncode({
        'text': text,
        'userId': userId,
        'postId': postId,
        'post_type': postType,
      }),
    );

    developer.log('Create comment response: ${response.statusCode}', name: 'ApiService');

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      return data; // Return the comment data
    } else {
      final errorData = jsonDecode(response.body);
      throw Exception('Failed to create comment: ${errorData['error']}');
    }
  } catch (e, stackTrace) {
    developer.log('Error creating comment: $e', name: 'ApiService', stackTrace: stackTrace);
    throw Exception('Failed to create comment: $e');
  }
}

  Future<Map<String, dynamic>> likePost(String postId, String userId, String token) async {
    try {
      developer.log('Liking post: $postId', name: 'ApiService');
      
      final response = await http.post(
        Uri.parse('$_baseUrl/like'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode({
          'post_id': postId,
          'user_id': userId,
        }),
      );

      developer.log('Like response: ${response.statusCode}', name: 'ApiService');

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
      developer.log('Error liking post: $e', name: 'ApiService', stackTrace: stackTrace);
      throw Exception('Failed to like post: $e');
    }
  }

  Future<void> joinEvent(String eventId, String userId, String token) async {
    try {
      developer.log('Joining event: $eventId', name: 'ApiService');
      
      final response = await http.post(
        Uri.parse('$_baseUrl/joinEvent'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode({
          'post_id': eventId,
          'user_id': userId,
        }),
      );

      developer.log('Join event response: ${response.statusCode}', name: 'ApiService');

      if (response.statusCode != 200) {
        final errorData = jsonDecode(response.body);
        throw Exception('Failed to join event: ${errorData['error']}');
      }
    } catch (e, stackTrace) {
      developer.log('Error joining event: $e', name: 'ApiService', stackTrace: stackTrace);
      throw Exception('Failed to join event: $e');
    }
  }

  Future<List<Post>> getPosts(String token) async {
    try {
      developer.log('Attempting to fetch posts with token', name: 'ApiService');
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
      developer.log('Parsed ${posts.length} posts', name: 'ApiService');
      return posts;
    } catch (e, stackTrace) {
      developer.log('Get posts error: $e',
          name: 'ApiService', stackTrace: stackTrace);
      rethrow;
    }
  }

  Future<List<Post>> getAllGoals(String token, String userId) async {
    try {
      developer.log('Fetching all goals', name: 'ApiService');
      
      final response = await http.get(
        Uri.parse('$_baseUrl/goals/all'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      developer.log('Goals fetch response: ${response.statusCode}', name: 'ApiService');

      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        developer.log('Received ${data.length} goals', name: 'ApiService');
        
        return data.map((json) {
          // Убеждаемся, что все необходимые поля присутствуют
          return Post.fromJson({
            'id': json['id'],
            'userID': json['userID'],
            'username': json['username'],
            'description': json['description'] ?? json['goalInfo'],
            'category': json['category'],
            'pointA': json['pointA'],
            'pointB': json['pointB'],
            'location': json['location'],
            'numOfLikes': json['numOfLikes'],
            'numOfComments': json['numOfComments'],
            'created_at': json['created_at'],
            'image_urls': json['image_urls'],
            'tasks': json['tasks'],
          }, type: 'goal');
        }).toList();
      } else {
        final errorData = jsonDecode(response.body);
        throw Exception('Failed to fetch goals: ${errorData['error']}');
      }
    } catch (e, stackTrace) {
      developer.log('Error fetching goals: $e', name: 'ApiService', stackTrace: stackTrace);
      throw Exception('Failed to fetch goals: $e');
    }
  }

  Future<List<Post>> getAllEvents(String token, String userId) async {
    try {
      developer.log('Fetching all events', name: 'ApiService');
      
      final response = await http.get(
        Uri.parse('$_baseUrl/events/all'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      developer.log('Events fetch response: ${response.statusCode}', name: 'ApiService');

      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        developer.log('Received ${data.length} events', name: 'ApiService');
        
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
      developer.log('Error fetching events: $e', name: 'ApiService', stackTrace: stackTrace);
      throw Exception('Failed to fetch events: $e');
    }
  }

  Future<List<Post>> getGoals(String userId, String token) async {
    try {
      developer.log('GetGoals request: userId: $userId', name: 'ApiService');
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
      developer.log('Parsed ${posts.length} user goals', name: 'ApiService');
      return posts;
    } catch (e, stackTrace) {
      developer.log('GetGoals error: $e',
          name: 'ApiService', stackTrace: stackTrace);
      return [];
    }
  }

  Future<List<Post>> getEvents(String userId, String token) async {
    try {
      developer.log('GetEvents request: userId: $userId', name: 'ApiService');
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
      developer.log('Parsed ${posts.length} user events', name: 'ApiService');
      return posts;
    } catch (e, stackTrace) {
      developer.log('GetEvents error: $e',
          name: 'ApiService', stackTrace: stackTrace);
      return [];
    }
  }

  Future<Post> getPostById(String post_id, String token) async {
    try {
      developer.log('Fetching post by id: $post_id', name: 'ApiService');
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
          name: 'ApiService', stackTrace: stackTrace);
      rethrow;
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
      developer.log('Creating goal with userId: $userId', name: 'ApiService');
      
      final response = await http.post(
        Uri.parse('$_baseUrl/goals/create'),
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

      developer.log('Goal creation response: ${response.statusCode}', name: 'ApiService');
      developer.log('Goal creation response body: ${response.body}', name: 'ApiService');

      if (response.statusCode != 200) {
        final errorData = jsonDecode(response.body);
        throw Exception('Failed to create goal: ${errorData['error']}');
      }
    } catch (e, stackTrace) {
      developer.log('Error creating goal: $e', name: 'ApiService', stackTrace: stackTrace);
      throw Exception('Failed to create goal: $e');
    }
  }

  Future<void> createEvent({
    required String userId,
    required String description,
    required String location,
    required String interest,
    required String dateTime,
    List<String>? imageUrls,
    required String token,
  }) async {
    try {
      developer.log('Creating event with userId: $userId', name: 'ApiService');
      
      final response = await http.post(
        Uri.parse('$_baseUrl/events/create'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode({
          'user_id': userId,
          'description': description,
          'location': location,
          'date_time': dateTime,
          'image_urls': imageUrls,
        }),
      );

      developer.log('Event creation response: ${response.statusCode}', name: 'ApiService');
      developer.log('Event creation response body: ${response.body}', name: 'ApiService');

      if (response.statusCode != 200) {
        final errorData = jsonDecode(response.body);
        throw Exception('Failed to create event: ${errorData['error']}');
      }
    } catch (e, stackTrace) {
      developer.log('Error creating event: $e', name: 'ApiService', stackTrace: stackTrace);
      throw Exception('Failed to create event: $e');
    }
  }

  Future<Map<String, String>> login(String email, String password) async {
    try {
      developer.log('Attempting login request: email: $email',
          name: 'ApiService');
      final response = await _makeRequest(
        () => _client.post(
          Uri.parse('$_baseUrl/login'),
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode({'mail': email, 'password': password}),
        ),
        3,
      );
      final data = await _handleResponse(response);
      return {
        'token': data['token']?.toString() ?? '',
        'userId': data['userID']?.toString() ?? '',
        'username': data['username']?.toString() ?? 'Unknown',
        'email': email,
      };
    } catch (e, stackTrace) {
      developer.log('Login error: $e',
          name: 'ApiService', stackTrace: stackTrace);
      throw Exception('Login failed: $e');
    }
  }

  Future<Map<String, String>> signUp(
    String username,
    String email,
    String password,
    String firstName,
    String lastName,
    int age,
    String phoneNumber,
  ) async {
    try {
      developer.log(
          'Attempting signUp request: email: $email, username: $username',
          name: 'ApiService');
      final response = await _client
          .post(
            Uri.parse('$_baseUrl/register/email'),
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode({
              'name': firstName,
              'surname': lastName,
              'username': username,
              'age': age,
              'mail': email,
              'phone': phoneNumber,
              'password': password,
            }),
          )
          .timeout(const Duration(seconds: 30));
      final data = await _handleResponse(response);
      return {
        'token': data['token']?.toString() ?? '',
        'userId': data['userID']?.toString() ?? '',
        'username': data['username']?.toString() ?? '',
        'email': email,
      };
    } catch (e, stackTrace) {
      developer.log('SignUp error: $e',
          name: 'ApiService', stackTrace: stackTrace);
      throw Exception('SignUp failed: $e');
    }
  }

  Future<Map<String, String>> signInWithGoogle() async {
    try {
      developer.log('Initiating Google Sign-In OAuth', name: 'ApiService');
      final authResponse = await _supabase.auth.signInWithOAuth(
        OAuthProvider.google,
        redirectTo: 'https://gohive-d4359.firebaseapp.com/',
      );

      if (!authResponse) {
        throw Exception('Google Sign-In OAuth initiation failed');
      }

      final session = await _supabase.auth.onAuthStateChange.firstWhere(
        (event) => event.event == AuthChangeEvent.signedIn,
        orElse: () => throw Exception('Authentication timed out'),
      );

      final supabaseToken = session.session?.accessToken;
      if (supabaseToken == null) {
        throw Exception('No Supabase token available');
      }
      developer.log('Supabase OAuth token obtained', name: 'ApiService');

      final response = await _client
          .post(
            Uri.parse('$_baseUrl/register/oauth/google'),
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode({'supabase_token': supabaseToken}),
          )
          .timeout(const Duration(seconds: 30));

      developer.log(
          'Google OAuth response: ${response.statusCode}, body: ${response.body}',
          name: 'ApiService');
      final data = await _handleResponse(response);
      if (data['token'] == null || data['userID'] == null) {
        throw Exception('Invalid server response: missing token or userID');
      }
      final email = _supabase.auth.currentUser?.email ?? 'unknown';
      return {
        'token': data['token'].toString(),
        'userId': data['userID'].toString(),
        'username': data['username']?.toString() ?? '',
        'email': email,
        'isNewUser': data['isNewUser']?.toString() ?? 'false',
      };
    } catch (e, stackTrace) {
      developer.log('Google Sign-In error: $e',
          name: 'ApiService', stackTrace: stackTrace);
      throw Exception('Google Sign-In failed: $e');
    }
  }

  Future<Map<String, String>> signInWithFacebook() async {
    try {
      developer.log('Initiating Facebook Sign-In OAuth', name: 'ApiService');
      final authResponse = await _supabase.auth.signInWithOAuth(
        OAuthProvider.facebook,
        redirectTo: 'https://gohive-d4359.firebaseapp.com/',
      );

      if (!authResponse) {
        throw Exception('Facebook Sign-In OAuth initiation failed');
      }

      final session = await _supabase.auth.onAuthStateChange.firstWhere(
        (event) => event.event == AuthChangeEvent.signedIn,
        orElse: () => throw Exception('Authentication timed out'),
      );

      final supabaseToken = session.session?.accessToken;
      if (supabaseToken == null) {
        throw Exception('No Supabase token available');
      }
      developer.log('Supabase OAuth token obtained', name: 'ApiService');

      final response = await _client
          .post(
            Uri.parse('$_baseUrl/register/oauth/facebook'),
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode({'supabase_token': supabaseToken}),
          )
          .timeout(const Duration(seconds: 30));

      developer.log(
          'Facebook OAuth response: ${response.statusCode}, body: ${response.body}',
          name: 'ApiService');
      final data = await _handleResponse(response);
      if (data['token'] == null || data['userID'] == null) {
        throw Exception('Invalid server response: missing token or userID');
      }
      final email = _supabase.auth.currentUser?.email ?? 'unknown';
      return {
        'token': data['token'].toString(),
        'userId': data['userID'].toString(),
        'username': data['username']?.toString() ?? '',
        'email': email,
        'isNewUser': data['isNewUser']?.toString() ?? 'false',
      };
    } catch (e, stackTrace) {
      developer.log('Facebook Sign-In error: $e',
          name: 'ApiService', stackTrace: stackTrace);
      throw Exception('Facebook Sign-In failed: $e');
    }
  }

  Future<Map<String, String>> signInWithApple() async {
    try {
      developer.log('Initiating Apple Sign-In OAuth', name: 'ApiService');
      final authResponse = await _supabase.auth.signInWithOAuth(
        OAuthProvider.apple,
        redirectTo: 'https://gohive-d4359.firebaseapp.com/',
      );

      if (!authResponse) {
        throw Exception('Apple Sign-In OAuth initiation failed');
      }

      final session = await _supabase.auth.onAuthStateChange.firstWhere(
        (event) => event.event == AuthChangeEvent.signedIn,
        orElse: () => throw Exception('Authentication timed out'),
      );

      final supabaseToken = session.session?.accessToken;
      if (supabaseToken == null) {
        throw Exception('No Supabase token available');
      }
      developer.log('Supabase OAuth token obtained', name: 'ApiService');

      final response = await _client
          .post(
            Uri.parse('$_baseUrl/register/oauth/apple'),
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode({'supabase_token': supabaseToken}),
          )
          .timeout(const Duration(seconds: 30));

      developer.log(
          'Apple OAuth response: ${response.statusCode}, body: ${response.body}',
          name: 'ApiService');
      final data = await _handleResponse(response);
      if (data['token'] == null || data['userID'] == null) {
        throw Exception('Invalid server response: missing token or userID');
      }
      final email = _supabase.auth.currentUser?.email ?? 'unknown';
      return {
        'token': data['token'].toString(),
        'userId': data['userID'].toString(),
        'username': data['username']?.toString() ?? '',
        'email': email,
        'isNewUser': data['isNewUser']?.toString() ?? 'false',
      };
    } catch (e, stackTrace) {
      developer.log('Apple Sign-In error: $e',
          name: 'ApiService', stackTrace: stackTrace);
      throw Exception('Apple Sign-In failed: $e');
    }
  }

  Future<Map<String, dynamic>> getProfile(String userId, String token) async {
    try {
      developer.log('Fetching profile for userId: $userId', name: 'ApiService');
      final response = await _client.get(
        Uri.parse('$_baseUrl/profile/$userId'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      ).timeout(const Duration(seconds: 10));
      final data = await _handleResponse(response);
      return {
        'userId': data['userID']?.toString() ?? userId,
        'username': data['username']?.toString() ?? '',
        'biography': data['biography']?.toString() ?? '',
        'numOfFollowers': (data['numOfFollowers'] as num?)?.toInt() ?? 0,
        'following': (data['following'] as num?)?.toInt() ?? 0,
        'avatar': data['avatar']?.toString() ?? '',
        'age': (data['age'] as num?)?.toInt(),
      };
    } catch (e, stackTrace) {
      developer.log('Get profile error: $e',
          name: 'ApiService', stackTrace: stackTrace);
      rethrow;
    }
  }

 Future<void> updateProfile(String userId, String token,
    Map<String, dynamic> data, String photoURL) async {
  try {
    developer.log('Updating profile for userId: $userId, data: $data',
        name: 'ApiService');
    
    // ИСПРАВЛЕНО: правильное формирование тела запроса
    final requestBody = {
      'userId': userId,
      'photoURL': photoURL,
      ...data, // Распаковываем данные из data в основной объект
    };

    final response = await _client
        .post(
          Uri.parse('$_baseUrl/profile/$userId'),
          headers: {
            'Authorization': 'Bearer $token',
            'Content-Type': 'application/json',
          },
          body: jsonEncode(requestBody), // Используем правильно сформированный объект
        )
        .timeout(const Duration(seconds: 10));
    await _handleResponse(response);
  } catch (e, stackTrace) {
    developer.log('Update profile error: $e',
        name: 'ApiService', stackTrace: stackTrace);
    rethrow;
  }
}

  Future<List<Map<String, dynamic>>> searchUsers(
    String query, {
    required String token,
    required String userId,
  }) async {
    try {
      developer.log('Searching users: query: $query, userId: $userId',
          name: 'ApiService');
      final response = await _client
          .post(
            Uri.parse('$_baseUrl/search/users'),
            headers: {
              'Content-Type': 'application/json',
              'Authorization': 'Bearer $token',
            },
            body: jsonEncode({'query': query, 'userId': userId}),
          )
          .timeout(const Duration(seconds: 30));

      final data = await _handleResponse(response);
      developer.log('Search results: $data', name: 'ApiService');
      return (data['users'] as List<dynamic>).cast<Map<String, dynamic>>();
    } catch (e, stackTrace) {
      developer.log('Search users error: $e',
          name: 'ApiService', stackTrace: stackTrace);
      throw Exception('Failed to search users: $e');
    }
  }

  Future<void> createPreOrder(String userId, String token) async {
    try {
      developer.log('Creating pre-order for userId: $userId',
          name: 'ApiService');
      final response = await _client.post(
        Uri.parse('$_baseUrl/preorder'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
        body: {'user_id': userId},
      ).timeout(const Duration(seconds: 10));
      developer.log(
          'Create pre-order response: ${response.statusCode}, ${response.body}',
          name: 'ApiService');
      await _handleResponse(response);
    } catch (e, stackTrace) {
      developer.log('Create pre-order error: $e',
          name: 'ApiService', stackTrace: stackTrace);
      rethrow;
    }
  }

  void dispose() {
    developer.log('Disposing ApiService', name: 'ApiService');
    _client.close();
  }
  Future<List<Post>> getUserGoals(String userId, String token) async {
    try {
      developer.log('Fetching user goals for: $userId', name: 'ApiService');
      
      final response = await http.get(
        Uri.parse('$_baseUrl/goals/$userId'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      developer.log('User goals response: ${response.statusCode}', name: 'ApiService');

      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        return data.map((json) => Post.fromJson(json, type: 'goal')).toList();
      } else {
        final errorData = jsonDecode(response.body);
        throw Exception('Failed to fetch user goals: ${errorData['error']}');
      }
    } catch (e, stackTrace) {
      developer.log('Error fetching user goals: $e', name: 'ApiService', stackTrace: stackTrace);
      throw Exception('Failed to fetch user goals: $e');
    }
  }
Future<List<Post>> getUserEvents(String userId, String token) async {
    try {
      developer.log('Fetching user events for: $userId', name: 'ApiService');
      
      final response = await http.get(
        Uri.parse('$_baseUrl/events/$userId'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      developer.log('User events response: ${response.statusCode}', name: 'ApiService');

      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        return data.map((json) => Post.fromJson(json, type: 'event')).toList();
      } else {
        final errorData = jsonDecode(response.body);
        throw Exception('Failed to fetch user events: ${errorData['error']}');
      }
    } catch (e, stackTrace) {
      developer.log('Error fetching user events: $e', name: 'ApiService', stackTrace: stackTrace);
      throw Exception('Failed to fetch user events: $e');
    }
  }
}
