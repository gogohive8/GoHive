import 'dart:convert';
import 'dart:developer' as developer;
import 'package:http/http.dart' as http;
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/post.dart';
import 'exceptions.dart';

class ApiService {
  final http.Client _client = http.Client();
  final SupabaseClient _supabase = Supabase.instance.client;
  static const String _baseUrl =
      'https://gohive-user-service-efb5dea164ed.herokuapp.com';
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
      final errorMessage = errorBody['error']?.toString() ?? 'Invalid data';
      developer.log('Validation error: $errorMessage', name: 'ApiService');
      throw DataValidationException('Invalid data: $errorMessage');
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
    throw Exception('All retry attempts failed');
  }

  Future<List<Post>> getPosts(String token) async {
    try {
      developer.log('Fetching posts with token', name: 'ApiService');
      final response = await _client.get(
        Uri.parse('$_postsUrl/posts'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      ).timeout(const Duration(seconds: 10));

      developer.log(
          'Get posts response: ${response.statusCode}, body: ${response.body}',
          name: 'ApiService');
      final data = await _handleResponse(response);
      final posts = (data as List<dynamic>)
          .map((json) => Post.fromJson(json, type: json['type'] ?? 'goal'))
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
      developer.log('Fetching all goals for userId: $userId',
          name: 'ApiService');
      final response = await _client.get(
        Uri.parse('$_postsUrl/goals'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      ).timeout(const Duration(seconds: 10));
      developer.log(
          'Get goals response: ${response.statusCode}, body: ${response.body}',
          name: 'ApiService');
      final data = await _handleResponse(response);
      final posts = (data as List<dynamic>)
          .map((json) => Post.fromJson(json, type: 'goal'))
          .toList();
      developer.log('Parsed ${posts.length} goals', name: 'ApiService');
      return posts;
    } catch (e, stackTrace) {
      developer.log('Get all goals error: $e',
          name: 'ApiService', stackTrace: stackTrace);
      rethrow;
    }
  }

  Future<List<Post>> getAllEvents(String token, String userId) async {
    try {
      developer.log('Fetching all events for userId: $userId',
          name: 'ApiService');
      final response = await _client.get(
        Uri.parse('$_postsUrl/events'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      ).timeout(const Duration(seconds: 10));
      developer.log(
          'Get events response: ${response.statusCode}, body: ${response.body}',
          name: 'ApiService');
      final data = await _handleResponse(response);
      final posts = (data as List<dynamic>)
          .map((json) => Post.fromJson(json, type: 'event'))
          .toList();
      developer.log('Parsed ${posts.length} events', name: 'ApiService');
      return posts;
    } catch (e, stackTrace) {
      developer.log('Get all events error: $e',
          name: 'ApiService', stackTrace: stackTrace);
      rethrow;
    }
  }

  Future<List<Post>> getGoals(String userId, String token) async {
    try {
      developer.log('GetGoals request: userId=$userId', name: 'ApiService');
      final response = await _client.get(
        Uri.parse('$_postsUrl/goals/$userId'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      ).timeout(const Duration(seconds: 30));
      developer.log(
          'Get goals response: ${response.statusCode}, body: ${response.body}',
          name: 'ApiService');
      final data = await _handleResponse(response);
      final posts = (data['goals'] as List)
          .map((json) => Post.fromJson({...json, 'type': 'goal'}, type: ''))
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
      developer.log('GetEvents request: userId=$userId', name: 'ApiService');
      final response = await _client.get(
        Uri.parse('$_postsUrl/events/$userId'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      ).timeout(const Duration(seconds: 30));
      developer.log(
          'Get events response: ${response.statusCode}, body: ${response.body}',
          name: 'ApiService');
      final data = await _handleResponse(response);
      final posts = (data['events'] as List)
          .map((json) => Post.fromJson({...json, 'type': 'event'}, type: ''))
          .toList();
      developer.log('Parsed ${posts.length} user events', name: 'ApiService');
      return posts;
    } catch (e, stackTrace) {
      developer.log('GetEvents error: $e', stackTrace: stackTrace);
      return [];
    }
  }

  Future<void> likePost(String postId, String token) async {
    try {
      developer.log('Liking post: postId=$postId', name: 'ApiService');
      final response = await _client.post(
        Uri.parse('$_postsUrl/posts/$postId/like'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      ).timeout(const Duration(seconds: 10));
      developer.log('Like post response: ${response.statusCode}',
          name: 'ApiService');
      await _handleResponse(response);
    } catch (e, stackTrace) {
      developer.log('Like post error: $e',
          name: 'ApiService', stackTrace: stackTrace);
      rethrow;
    }
  }

  Future<void> joinEvent(String eventId, String token) async {
    try {
      developer.log('Joining event: eventId=$eventId', name: 'ApiService');
      final response = await _client.post(
        Uri.parse('$_postsUrl/events/$eventId/join'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      ).timeout(const Duration(seconds: 10));
      developer.log('Join event response: ${response.statusCode}',
          name: 'ApiService');
      await _handleResponse(response);
    } catch (e, stackTrace) {
      developer.log('Join event error: $e',
          name: 'ApiService', stackTrace: stackTrace);
      rethrow;
    }
  }

  Future<void> createGoal({
    required String userId,
    required String description,
    required String location,
    required String interest,
    String? pointA,
    String? pointB,
    List<Map<String, dynamic>>? tasks,
    required String token,
  }) async {
    try {
      final body = {
        'user_id': userId,
        'description': description,
        'location': location,
        'interest': interest,
        if (pointA != null && pointA.isNotEmpty) 'point_a': pointA,
        if (pointB != null && pointB.isNotEmpty) 'point_b': pointB,
        if (tasks != null && tasks.isNotEmpty)
          'tasks': tasks
              .map((task) => {'title': task['title'], 'completed': false})
              .toList(),
      };

      developer.log(
          'Creating goal for user: $userId, body: ${jsonEncode(body)}',
          name: 'ApiService');

      final response = await _client
          .post(
            Uri.parse('$_postsUrl/goals/create'),
            headers: {
              'Content-Type': 'application/json',
              'Authorization': 'Bearer $token',
            },
            body: jsonEncode(body),
          )
          .timeout(const Duration(seconds: 30));

      developer.log(
          'CreateGoal response: ${response.statusCode}, ${response.body}',
          name: 'ApiService');

      await _handleResponse(response);
    } catch (e, stackTrace) {
      developer.log('CreateGoal error: $e',
          name: 'ApiService', stackTrace: stackTrace);
      rethrow;
    }
  }

  Future<void> createEvent({
    required String userId,
    required String description,
    required String location,
    required String interest,
    required String dateTime,
    required String token,
  }) async {
    try {
      final body = {
        'user_id': userId,
        'description': description,
        'location': location,
        'interest': interest,
        'date_time': dateTime,
      };

      developer.log(
          'Creating event for user: $userId, body: ${jsonEncode(body)}',
          name: 'ApiService');

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
          name: 'ApiService');

      await _handleResponse(response);
    } catch (e, stackTrace) {
      developer.log('CreateEvent error: $e',
          name: 'ApiService', stackTrace: stackTrace);
      rethrow;
    }
  }

  Future<Map<String, String>?> login(String email, String password) async {
    try {
      developer.log('Login request: email=$email', name: 'ApiService');
      final response = await _makeRequest(
        () => _client.post(
          Uri.parse('$_baseUrl/login'),
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode({'mail': email, 'password': password}),
        ),
        3,
      );
      final data = await _handleResponse(response);
      return {'token': data['token'] ?? '', 'userId': data['userID'] ?? ''};
    } catch (e, stackTrace) {
      developer.log('Login error: $e',
          name: 'ApiService', stackTrace: stackTrace);
      return null;
    }
  }

  Future<Map<String, String>?> signUp(
    String username,
    String email,
    String password,
    String firstName,
    String lastName,
    int age,
    String phoneNumber,
  ) async {
    try {
      developer.log('SignUp request: username=$username, email=$email',
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
      return {'token': data['token'] ?? '', 'userId': data['userID'] ?? ''};
    } catch (e, stackTrace) {
      developer.log('SignUp error: $e',
          name: 'ApiService', stackTrace: stackTrace);
      return null;
    }
  }

  Future<Map<String, String>?> signInWithGoogle() async {
    try {
      developer.log('Google OAuth request', name: 'ApiService');
      await _supabase.auth.signInWithOAuth(
        OAuthProvider.google,
        redirectTo: 'https://gohive-d4359.firebaseapp.com',
      );
      final session = await _supabase.auth.onAuthStateChange
          .firstWhere((event) => event.event == AuthChangeEvent.signedIn)
          .then((event) => event.session);
      if (session == null) {
        throw Exception('No session received after OAuth');
      }
      final supabaseToken = await session.accessToken;
      developer.log('Supabase token obtained', name: 'ApiService');
      final response = await _client
          .post(
            Uri.parse('$_baseUrl/register/oauth/google'),
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode({'supabase_token': supabaseToken}),
          )
          .timeout(const Duration(seconds: 30));
      final data = await _handleResponse(response);
      return {'token': data['token'] ?? '', 'userId': data['userID'] ?? ''};
    } catch (e, stackTrace) {
      developer.log('Google sign-in error: $e',
          name: 'ApiService', stackTrace: stackTrace);
      return null;
    }
  }

  Future<Map<String, dynamic>> getProfile(String userId, String token) async {
    try {
      developer.log('Fetching profile: userId=$userId', name: 'ApiService');
      final response = await _client.get(
        Uri.parse('$_baseUrl/profile/$userId'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      ).timeout(const Duration(seconds: 10));
      final data = await _handleResponse(response);
      return data as Map<String, dynamic>;
    } catch (e, stackTrace) {
      developer.log('Get profile error: $e',
          name: 'ApiService', stackTrace: stackTrace);
      rethrow;
    }
  }

  Future<void> updateProfile(
      String userId, String token, Map<String, dynamic> data) async {
    try {
      developer.log('Updating profile: userId=$userId', name: 'ApiService');
      final response = await _client
          .post(
            Uri.parse('$_baseUrl/profile/$userId'),
            headers: {
              'Authorization': 'Bearer $token',
              'Content-Type': 'application/json',
            },
            body: jsonEncode(data),
          )
          .timeout(const Duration(seconds: 10));
      await _handleResponse(response);
    } catch (e, stackTrace) {
      developer.log('Update profile error: $e',
          name: 'ApiService', stackTrace: stackTrace);
      rethrow;
    }
  }

  Future<bool> updateBio(String userId, String bio, String token) async {
    try {
      developer.log('UpdateBio request: userId=$userId', name: 'ApiService');
      final response = await _client
          .put(
            Uri.parse('$_baseUrl/profile/$userId/bio'),
            headers: {
              'Content-Type': 'application/json',
              'Authorization': 'Bearer $token',
            },
            body: jsonEncode({'bio': bio}),
          )
          .timeout(const Duration(seconds: 30));
      await _handleResponse(response);
      return true;
    } catch (e, stackTrace) {
      developer.log('UpdateBio error: $e',
          name: 'ApiService', stackTrace: stackTrace);
      return false;
    }
  }

  Future<List<Map<String, dynamic>>> searchUsers(
    String query, {
    required String token,
    required String userId,
  }) async {
    try {
      developer.log('Searching users: query=$query, userId=$userId',
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
      developer.log('Search users response: $data', name: 'ApiService');
      return (data['users'] as List<dynamic>?)?.cast<Map<String, dynamic>>() ??
          [];
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
      // Заглушка, так как сервер недоступен
      developer.log(
          'Pre-order request: POST $_baseUrl/preorder, userId: $userId',
          name: 'ApiService');
      // Раскомментировать, когда сервер будет доступен
      /*
      final response = await _client.post(
        Uri.parse('$_baseUrl/preorder'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
        body: jsonEncode({'user_id': userId}),
      ).timeout(const Duration(seconds: 10));
      developer.log('Create pre-order response: ${response.statusCode}, ${response.body}',
          name: 'ApiService');
      await _handleResponse(response);
      */
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
}
