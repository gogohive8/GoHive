import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/post.dart';
import '../providers/auth_provider.dart';

class ApiService {
  final http.Client _client = http.Client();
  final SupabaseClient _supabase = Supabase.instance.client;
  static const String _baseUrl = 'http://localhost:3001';

  // Helper method for handling HTTP responses
  Future<Map<String, dynamic>?> _handleResponse(http.Response response) async {
    if (response.statusCode == 200 || response.statusCode == 201) {
      return jsonDecode(response.body);
    }
    print('Error: ${response.statusCode}, ${response.body}');
    return null;
  }

  Future<Map<String, String>?> login(String email, String password) async {
    try {
      final response = await _client
          .post(
            Uri.parse('$_baseUrl/login'),
            headers: {
              'Content-Type': 'application/json',
              'Accept': 'application/json',
            },
            body: jsonEncode({'mail': email, 'password': password}),
          )
          .timeout(const Duration(seconds: 30));
      final data = await _handleResponse(response);
      return data != null
          ? {'token': data['token'] ?? '', 'userId': data['userId'] ?? ''}
          : null;
    } catch (e) {
      print('Login error: $e');
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
      String phoneNumber) async {
    try {
      final body = jsonEncode({
        'name': firstName,
        'surname': lastName,
        'username': username,
        'age': age,
        'mail': email,
        'phone': phoneNumber,
        'password': password,
      });
      final response = await _client
          .post(
            Uri.parse('$_baseUrl/register/email'),
            headers: {
              'Content-Type': 'application/json',
              'Accept': 'application/json',
            },
            body: body,
          )
          .timeout(const Duration(seconds: 30));
      final data = await _handleResponse(response);
      return data != null
          ? {
              'token': data['token'] ?? '',
              'userId': data['user']?['id']?.toString() ?? ''
            }
          : null;
    } catch (e) {
      print('Sign up error: $e');
      return null;
    }
  }

  Future<Map<String, String>?> signInWithGoogle() async {
    try {
      await _supabase.auth.signInWithOAuth(
        OAuthProvider.google,
        redirectTo: 'io.supabase.flutterquickstart://callback',
      );
      final session = _supabase.auth.currentSession;
      if (session == null) return null;

      final response = await _client
          .post(
            Uri.parse('$_baseUrl/auth/google'),
            headers: {
              'Content-Type': 'application/json',
              'Accept': 'application/json',
            },
            body: jsonEncode({
              'access_token': session.accessToken,
              'user_id': session.user.id,
            }),
          )
          .timeout(const Duration(seconds: 30));
      final data = await _handleResponse(response);
      return data != null
          ? {'token': data['token'] ?? '', 'userId': data['userId'] ?? ''}
          : null;
    } catch (e) {
      print('Google sign-in error: $e');
      return null;
    }
  }

  Future<Map<String, dynamic>?> getProfile(String userId, String token) async {
    try {
      final response = await _client
          .post(
            Uri.parse('$_baseUrl/profile/$userId'),
            headers: {
              'Content-Type': 'application/json',
              'Accept': 'application/json',
              'Authorization': 'Bearer $token',
            },
            body: jsonEncode({'user_id': userId}),
          )
          .timeout(const Duration(seconds: 30));
      final data = await _handleResponse(response);
      return data != null
          ? {
              'avatar_url': data['avatar_url'] ?? '',
              'username': data['username'] ?? '',
              'bio': data['bio'] ?? '',
              'followers': data['followers'] ?? 0,
              'following': data['following'] ?? 0,
            }
          : null;
    } catch (e) {
      print('Get profile error: $e');
      return null;
    }
  }

  Future<bool> updateBio(String userId, String bio, String token) async {
    try {
      final response = await _client
          .post(
            Uri.parse('$_baseUrl/profile/$userId/bio'),
            headers: {
              'Content-Type': 'application/json',
              'Accept': 'application/json',
              'Authorization': 'Bearer $token',
            },
            body: jsonEncode({'bio': bio}),
          )
          .timeout(const Duration(seconds: 30));
      return response.statusCode == 200;
    } catch (e) {
      print('Update bio error: $e');
      return false;
    }
  }

  Future<String?> uploadAvatar(
      String userId, List<int> fileBytes, String token) async {
    try {
      final response = await _client
          .post(
            Uri.parse('$_baseUrl/upload/avatar/$userId'),
            headers: {
              'Content-Type': 'application/octet-stream',
              'Accept': 'application/json',
              'Authorization': 'Bearer $token',
            },
            body: fileBytes,
          )
          .timeout(const Duration(seconds: 30));
      final data = await _handleResponse(response);
      return data?['url']?.toString();
    } catch (e) {
      print('Upload avatar error: $e');
      return null;
    }
  }

  Future<List<Post>> getGoals(String userId, String token) async {
    try {
      final response = await _client
          .post(
            Uri.parse('$_baseUrl/goals'),
            headers: {
              'Content-Type': 'application/json',
              'Accept': 'application/json',
              'Authorization': 'Bearer $token',
            },
            body: jsonEncode({'user_id': userId}),
          )
          .timeout(const Duration(seconds: 30));
      final data = await _handleResponse(response);
      return data != null
          ? (data['goals'] as List)
              .map((json) => Post.fromJson({...json, 'type': 'goal'}))
              .toList()
          : [];
    } catch (e) {
      print('Get goals error: $e');
      return [];
    }
  }

  Future<List<Post>> getEvents(String userId, String token) async {
    try {
      final response = await _client
          .post(
            Uri.parse('$_baseUrl/events'),
            headers: {
              'Content-Type': 'application/json',
              'Accept': 'application/json',
              'Authorization': 'Bearer $token',
            },
            body: jsonEncode({'user_id': userId}),
          )
          .timeout(const Duration(seconds: 30));
      final data = await _handleResponse(response);
      return data != null
          ? (data['events'] as List)
              .map((json) => Post.fromJson({...json, 'type': 'event'}))
              .toList()
          : [];
    } catch (e) {
      print('Get events error: $e');
      return [];
    }
  }

  Future<List<Post>> getAllGoals() async {
    try {
      final response = await _client
          .post(
            Uri.parse('$_baseUrl/goals/all'),
            headers: {
              'Content-Type': 'application/json',
              'Accept': 'application/json',
            },
            body: jsonEncode({}),
          )
          .timeout(const Duration(seconds: 30));
      final data = await _handleResponse(response);
      return data != null
          ? (data['goals'] as List)
              .map((json) => Post.fromJson({...json, 'type': 'goal'}))
              .toList()
          : [];
    } catch (e) {
      print('Get all goals error: $e');
      return [];
    }
  }

  Future<List<Post>> getAllEvents() async {
    try {
      final response = await _client
          .post(
            Uri.parse('$_baseUrl/events/all'),
            headers: {
              'Content-Type': 'application/json',
              'Accept': 'application/json',
            },
            body: jsonEncode({}),
          )
          .timeout(const Duration(seconds: 30));
      final data = await _handleResponse(response);
      return data != null
          ? (data['events'] as List)
              .map((json) => Post.fromJson({...json, 'type': 'event'}))
              .toList()
          : [];
    } catch (e) {
      print('Get all events error: $e');
      return [];
    }
  }

  Future<void> likePost(String postId, String type, String token) async {
    try {
      final response = await _client
          .post(
            Uri.parse('$_baseUrl/like'),
            headers: {
              'Content-Type': 'application/json',
              'Accept': 'application/json',
              'Authorization': 'Bearer $token',
            },
            body: jsonEncode({
              'post_id': postId,
              'type': type,
            }),
          )
          .timeout(const Duration(seconds: 30));
      if (response.statusCode != 200) {
        throw Exception('Failed to like post: ${response.body}');
      }
    } catch (e) {
      print('Like post error: $e');
      throw Exception('Failed to like post: $e');
    }
  }

  Future<void> joinEvent(String eventId, String userId, String token) async {
    try {
      final response = await _client
          .post(
            Uri.parse('$_baseUrl/join'),
            headers: {
              'Content-Type': 'application/json',
              'Accept': 'application/json',
              'Authorization': 'Bearer $token',
            },
            body: jsonEncode({
              'event_id': eventId,
              'user_id': userId,
            }),
          )
          .timeout(const Duration(seconds: 30));
      if (response.statusCode != 200) {
        throw Exception('Failed to join event: ${response.body}');
      }
    } catch (e) {
      print('Join event error: $e');
      throw Exception('Failed to join event: $e');
    }
  }

  Future<void> createGoal(
      String userId, String description, String location, String interest,
      {String? pointA,
      String? pointB,
      List<String>? tasks,
      List<String>? imageUrls,
      required String token}) async {
    try {
      final response = await _client
          .post(
            Uri.parse('$_baseUrl/goals/create'),
            headers: {
              'Content-Type': 'application/json',
              'Accept': 'application/json',
              'Authorization': 'Bearer $token',
            },
            body: jsonEncode({
              'user_id': userId,
              'description': description,
              'location': location,
              'interest': interest,
              'point_a': pointA,
              'point_b': pointB,
              'tasks': tasks
                      ?.map((task) => {'title': task, 'completed': false})
                      .toList() ??
                  [],
              'image_urls': imageUrls ?? [],
              'created_at': DateTime.now().toIso8601String(),
              'likes': 0,
              'comments': 0,
            }),
          )
          .timeout(const Duration(seconds: 30));
      if (response.statusCode != 200) {
        throw Exception('Failed to create goal: ${response.body}');
      }
    } catch (e) {
      print('Create goal error: $e');
      throw Exception('Failed to create goal: $e');
    }
  }

  Future<void> createEvent(String userId, String description, String location,
      {String? pointA,
      String? pointB,
      List<String>? tasks,
      List<String>? imageUrls,
      required String token}) async {
    try {
      final response = await _client
          .post(
            Uri.parse('$_baseUrl/events/create'),
            headers: {
              'Content-Type': 'application/json',
              'Accept': 'application/json',
              'Authorization': 'Bearer $token',
            },
            body: jsonEncode({
              'user_id': userId,
              'description': description,
              'location': location,
              'point_a': pointA,
              'point_b': pointB,
              'tasks': tasks
                      ?.map((task) => {'title': task, 'completed': false})
                      .toList() ??
                  [],
              'image_urls': imageUrls ?? [],
              'created_at': DateTime.now().toIso8601String(),
              'likes': 0,
              'comments': 0,
            }),
          )
          .timeout(const Duration(seconds: 30));
      if (response.statusCode != 200) {
        throw Exception('Failed to create event: ${response.body}');
      }
    } catch (e) {
      print('Create event error: $e');
      throw Exception('Failed to create event: $e');
    }
  }

  void dispose() {
    _client.close();
  }
}
