import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/post.dart';
import '../services/exceptions.dart';
import 'dart:developer' as developer;

class ApiService {
  static const _baseUrl =
      'https://gohive-user-service-efb5dea164ed.herokuapp.com';
  final http.Client _client = http.Client();
  final SupabaseClient _supabase = Supabase.instance.client;

  SupabaseClient get supabase => _supabase;

  void dispose() {
    _client.close();
  }

  Future<dynamic> _handleResponse(http.Response response) async {
    developer.log(
        'Handling response: status=${response.statusCode}, body=${response.body}',
        name: 'ApiService');
    if (response.statusCode >= 200 && response.statusCode < 300) {
      return response.body.isNotEmpty ? jsonDecode(response.body) : null;
    }
    if (response.statusCode == 400 &&
        jsonDecode(response.body).containsKey('id')) {
      return jsonDecode(response.body);
    }
    throw AuthenticationException(
        'Request failed with status: ${response.statusCode}');
  }

  Future<Map<String, dynamic>?> login(String email, String password) async {
    try {
      developer.log('Login request: email=$email', name: 'ApiService');
      final response = await _client
          .post(
            Uri.parse('$_baseUrl/login'),
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode({'mail': email, 'password': password}),
          )
          .timeout(const Duration(seconds: 30));
      final data = await _handleResponse(response);
      if (data == null || data['token'] == null || data['userID'] == null) {
        developer.log('Invalid response data: $data', name: 'ApiService');
        return null;
      }
      return {
        'token': data['token'] as String,
        'userId': data['userID'] as String,
        'username': data['username'] as String? ?? 'Unknown',
      };
    } catch (e, stackTrace) {
      developer.log('Login error: $e',
          name: 'ApiService', stackTrace: stackTrace);
      throw AuthenticationException('Failed to login: $e');
    }
  }

  Future<bool> signInWithGoogle() async {
    try {
      developer.log('Starting Google OAuth', name: 'ApiService');
      final success = await _supabase.auth.signInWithOAuth(
        OAuthProvider.google,
        redirectTo: 'https://gohive-d4359.firebaseapp.com',
      );
      developer.log('OAuth initiated: success=$success', name: 'ApiService');
      return success;
    } catch (e, stackTrace) {
      developer.log('Google OAuth error: $e',
          name: 'ApiService', stackTrace: stackTrace);
      throw AuthenticationException('Failed to initiate Google OAuth: $e');
    }
  }

  Future<Map<String, dynamic>?> exchangeSupabaseTokenForAuthData(
      String supabaseToken) async {
    for (int attempt = 1; attempt <= 3; attempt++) {
      try {
        developer.log('Exchanging Supabase token, attempt $attempt',
            name: 'ApiService');
        final response = await _client.post(
          Uri.parse('$_baseUrl/register/oauth/google'),
          headers: {
            'Content-Type': 'application/json',
            'Authorization': 'Bearer $supabaseToken',
          },
        ).timeout(const Duration(seconds: 30));
        final data = await _handleResponse(response);
        if (data == null || data['token'] == null || data['userID'] == null) {
          developer.log('Invalid response data: $data', name: 'ApiService');
          return null;
        }
        return {
          'token': data['token'] as String,
          'userId': data['userID'] as String,
          'username': data['username'] as String? ?? 'Unknown',
        };
      } catch (e, stackTrace) {
        developer.log('Token exchange error (attempt $attempt): $e',
            name: 'ApiService', stackTrace: stackTrace);
        if (attempt == 3) return null;
        await Future.delayed(Duration(seconds: attempt * 2));
      }
    }
    return null;
  }

  Future<Map<String, dynamic>?> signUp(
    String username,
    String email,
    String password,
    String firstName,
    String lastName,
    int age,
    String phone,
  ) async {
    try {
      final response = await _client
          .post(
            Uri.parse('$_baseUrl/register'),
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode({
              'username': username,
              'mail': email,
              'password': password,
              'first_name': firstName,
              'last_name': lastName,
              'age': age,
              'phone': phone,
            }),
          )
          .timeout(const Duration(seconds: 30));
      final data = await _handleResponse(response);
      if (data == null || data['token'] == null || data['userID'] == null) {
        developer.log('Invalid response data: $data', name: 'ApiService');
        return null;
      }
      return {
        'token': data['token'] as String,
        'userId': data['userID'] as String,
        'username': data['username'] as String? ?? 'Unknown',
      };
    } catch (e, stackTrace) {
      developer.log('SignUp error: $e',
          name: 'ApiService', stackTrace: stackTrace);
      throw AuthenticationException('Failed to sign up: $e');
    }
  }

  Future<List<Post>> getAllGoals(String token, String userId) async {
    try {
      final response = await _client.get(
        Uri.parse('$_baseUrl/goals?user_id=$userId'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      ).timeout(const Duration(seconds: 30));
      final data = await _handleResponse(response);
      return (data['goals'] as List<dynamic>)
          .map((e) => Post.fromJson(e as Map<String, dynamic>, type: 'goal'))
          .toList();
    } catch (e, stackTrace) {
      developer.log('Get goals error: $e',
          name: 'ApiService', stackTrace: stackTrace);
      throw AuthenticationException('Failed to fetch goals: $e');
    }
  }

  Future<List<Post>> getAllEvents(String token, String userId) async {
    try {
      final response = await _client.get(
        Uri.parse('$_baseUrl/events?user_id=$userId'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      ).timeout(const Duration(seconds: 30));
      final data = await _handleResponse(response);
      return (data['events'] as List<dynamic>)
          .map((e) => Post.fromJson(e as Map<String, dynamic>, type: 'event'))
          .toList();
    } catch (e, stackTrace) {
      developer.log('Get events error: $e',
          name: 'ApiService', stackTrace: stackTrace);
      throw AuthenticationException('Failed to fetch events: $e');
    }
  }

  Future<void> likePost(String postId, String token) async {
    try {
      final response = await _client.post(
        Uri.parse('$_baseUrl/likes/$postId'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      ).timeout(const Duration(seconds: 30));
      await _handleResponse(response);
    } catch (e, stackTrace) {
      developer.log('Like post error: $e',
          name: 'ApiService', stackTrace: stackTrace);
      throw AuthenticationException('Failed to like post: $e');
    }
  }

  Future<void> joinEvent(String eventId, String token) async {
    try {
      final response = await _client.post(
        Uri.parse('$_baseUrl/events/$eventId/join'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      ).timeout(const Duration(seconds: 30));
      await _handleResponse(response);
    } catch (e, stackTrace) {
      developer.log('Join event error: $e',
          name: 'ApiService', stackTrace: stackTrace);
      throw AuthenticationException('Failed to join event: $e');
    }
  }

  Future<void> createGoal({
    required String token,
    required String userId,
    required String title,
    required String description,
    required String category,
    List<Map<String, dynamic>>? tasks,
  }) async {
    try {
      final response = await _client
          .post(
            Uri.parse('$_baseUrl/goals'),
            headers: {
              'Content-Type': 'application/json',
              'Authorization': 'Bearer $token',
            },
            body: jsonEncode({
              'user_id': userId,
              'title': title,
              'description': description,
              'category': category,
              if (tasks != null && tasks.isNotEmpty) 'tasks': tasks,
            }),
          )
          .timeout(const Duration(seconds: 30));
      developer.log(
          'Create goal response: status=${response.statusCode}, body=${response.body}',
          name: 'ApiService');
      await _handleResponse(response);
    } catch (e, stackTrace) {
      developer.log('Create goal error: $e',
          name: 'ApiService', stackTrace: stackTrace);
      throw DataValidationException('Failed to create goal: $e');
    }
  }

  Future<void> createEvent({
    required String token,
    required String userId,
    required String title,
    required String description,
    required String category,
    required String dateTime,
  }) async {
    try {
      final response = await _client
          .post(
            Uri.parse('$_baseUrl/events'),
            headers: {
              'Content-Type': 'application/json',
              'Authorization': 'Bearer $token',
            },
            body: jsonEncode({
              'user_id': userId,
              'title': title,
              'description': description,
              'category': category,
              'date_time': dateTime,
            }),
          )
          .timeout(const Duration(seconds: 30));
      developer.log(
          'Create event response: status=${response.statusCode}, body=${response.body}',
          name: 'ApiService');
      await _handleResponse(response);
    } catch (e, stackTrace) {
      developer.log('Create event error: $e',
          name: 'ApiService', stackTrace: stackTrace);
      throw DataValidationException('Failed to create event: $e');
    }
  }

  Future<void> updateBio({
    required String token,
    required String userId,
    required String bio,
  }) async {
    try {
      final response = await _client
          .patch(
            Uri.parse('$_baseUrl/users/$userId'),
            headers: {
              'Content-Type': 'application/json',
              'Authorization': 'Bearer $token',
            },
            body: jsonEncode({'bio': bio}),
          )
          .timeout(const Duration(seconds: 30));
      developer.log(
          'Update bio response: status=${response.statusCode}, body=${response.body}',
          name: 'ApiService');
      final data = await _handleResponse(response);
      if (data == null || data['bio'] != bio) {
        throw DataValidationException('Bio not updated on server');
      }
    } catch (e, stackTrace) {
      developer.log('Update bio error: $e',
          name: 'ApiService', stackTrace: stackTrace);
      throw DataValidationException('Failed to update bio: $e');
    }
  }

  Future<List<Post>> search(String token, String query, String filter) async {
    try {
      final response = await _client.get(
        Uri.parse(
            '$_baseUrl/search?query=$query&filter=${filter.toLowerCase()}'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      ).timeout(const Duration(seconds: 30));
      final data = await _handleResponse(response);
      return (data['results'] as List<dynamic>)
          .map((e) => Post.fromJson(e as Map<String, dynamic>,
              type: filter.toLowerCase()))
          .toList();
    } catch (e, stackTrace) {
      developer.log('Search error: $e',
          name: 'ApiService', stackTrace: stackTrace);
      throw DataValidationException('Failed to search: $e');
    }
  }
}
