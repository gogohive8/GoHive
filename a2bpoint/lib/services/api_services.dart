import 'dart:convert';
import 'dart:developer' as developer;
import 'package:http/http.dart' as http;
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/post.dart';

class ApiService {
  final http.Client _client = http.Client();
  final SupabaseClient _supabase = Supabase.instance.client;
  static const String _baseUrl =
      'http://localhost:3001'; // For Android emulator
  static const String _postsUrl = 'http://localhost:3002';

  SupabaseClient get supabase => _supabase;

  Future<dynamic> _handleResponse(http.Response response) async {
    developer.log('Response: ${response.statusCode}, ${response.body}',
        name: 'ApiService');
    if (response.statusCode >= 200 && response.statusCode < 300) {
      return response.body.isNotEmpty ? jsonDecode(response.body) : {};
    }
    throw Exception('Request failed: ${response.statusCode} ${response.body}');
  }

  Future<Map<String, dynamic>> search(String query,
      {required String filter,
      required String token,
      required String userId}) async {
    final response = await http.post(
      Uri.parse('https://your-backend.com/search'),
      headers: {'Authorization': 'Bearer $token'},
      body: jsonEncode({'query': query, 'filter': filter, 'userId': userId}),
    );
    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception('Failed to search: ${response.statusCode}');
    }
  }

  Future<Map<String, String>?> login(String email, String password) async {
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

      // Initiate OAuth with Supabase
      await _supabase.auth.signInWithOAuth(
        OAuthProvider.google,
        redirectTo: 'https://osyajqltbkudsfcppqgh.supabase.co/auth/v1/callback',
      );

      // Wait for session (handled by deep link)
      final session = await _supabase.auth.onAuthStateChange
          .firstWhere((event) => event.event == AuthChangeEvent.signedIn)
          .then((event) => event.session);

      if (session == null) {
        throw Exception('No session received after OAuth');
      }

      final supabaseToken = session.accessToken;
      developer.log('Supabase token obtained', name: 'ApiService');

      // Send token to backend
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

  Future<Map<String, dynamic>?> getProfile(String userId, String token) async {
    try {
      developer.log('GetProfile request: userId=$userId', name: 'ApiService');
      final response = await _client.get(
        Uri.parse('$_baseUrl/profile/$userId'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      ).timeout(const Duration(seconds: 30));
      return await _handleResponse(response);
    } catch (e, stackTrace) {
      developer.log('GetProfile error: $e',
          name: 'ApiService', stackTrace: stackTrace);
      return null;
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

  Future<String?> uploadAvatar(
      String userId, String filePath, String token) async {
    try {
      developer.log('UploadAvatar request: userId=$userId', name: 'ApiService');
      var request = http.MultipartRequest(
        'POST',
        Uri.parse('$_baseUrl/upload/avatar/$userId'),
      );
      request.headers['Authorization'] = 'Bearer $token';
      request.files.add(await http.MultipartFile.fromPath('avatar', filePath));
      final response =
          await request.send().timeout(const Duration(seconds: 30));
      final responseBody = await response.stream.bytesToString();
      if (response.statusCode >= 200 && response.statusCode < 300) {
        final data = jsonDecode(responseBody);
        return data['url'] ?? null;
      }
      throw Exception('Upload failed: ${response.statusCode} $responseBody');
    } catch (e, stackTrace) {
      developer.log('UploadAvatar error: $e',
          name: 'ApiService', stackTrace: stackTrace);
      return null;
    }
  }

  Future<List<Post>> getGoals(String userId, String token) async {
    try {
      developer.log('GetGoals request: userId=$userId', name: 'ApiService');
      final response = await _client.get(
        Uri.parse('$_baseUrl/goals/$userId'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      ).timeout(const Duration(seconds: 30));
      final data = await _handleResponse(response);
      return (data['goals'] as List)
          .map((json) => Post.fromJson({...json, 'type': 'goal'}))
          .toList();
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
        Uri.parse('$_baseUrl/events/$userId'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      ).timeout(const Duration(seconds: 30));
      final data = await _handleResponse(response);
      return (data['events'] as List)
          .map((json) => Post.fromJson({...json, 'type': 'event'}))
          .toList();
    } catch (e, stackTrace) {
      developer.log('GetEvents error: $e',
          name: 'ApiService', stackTrace: stackTrace);
      return [];
    }
  }

  Future<List<Post>> getAllGoals(String token, String userId) async {
    try {
      developer.log('GetAllGoals request: userId= $userId', name: 'ApiService');
      final response = await _client.get(
        Uri.parse('$_postsUrl/goals/all'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      ).timeout(const Duration(seconds: 30));
      final data = await _handleResponse(response);
      return (data['goals'] as List)
          .map((json) => Post.fromJson({...json, 'type': 'goal'}))
          .toList();
    } catch (e, stackTrace) {
      developer.log('GetAllGoals error: $e',
          name: 'ApiService', stackTrace: stackTrace);
      return [];
    }
  }

  Future<List<Post>> getAllEvents() async {
    try {
      developer.log('GetAllEvents request', name: 'ApiService');
      final response = await _client.get(
        Uri.parse('$_baseUrl/events/all'),
        headers: {'Content-Type': 'application/json'},
      ).timeout(const Duration(seconds: 30));
      final data = await _handleResponse(response);
      return (data['events'] as List)
          .map((json) => Post.fromJson({...json, 'type': 'event'}))
          .toList();
    } catch (e, stackTrace) {
      developer.log('GetAllEvents error: $e',
          name: 'ApiService', stackTrace: stackTrace);
      return [];
    }
  }

  Future<void> likePost(String postId, String token) async {
    try {
      developer.log('LikePost request: postId=$postId', name: 'ApiService');
      final response = await _client
          .post(
            Uri.parse('$_baseUrl/like'),
            headers: {
              'Content-Type': 'application/json',
              'Authorization': 'Bearer $token',
            },
            body: jsonEncode({'post_id': postId}),
          )
          .timeout(const Duration(seconds: 30));
      await _handleResponse(response);
    } catch (e, stackTrace) {
      developer.log('LikePost error: $e',
          name: 'ApiService', stackTrace: stackTrace);
      rethrow;
    }
  }

  Future<void> joinEvent(String eventId, String token) async {
    try {
      developer.log('JoinEvent request: eventId=$eventId', name: 'ApiService');
      final response = await _client
          .post(
            Uri.parse('$_baseUrl/join'),
            headers: {
              'Content-Type': 'application/json',
              'Authorization': 'Bearer $token',
            },
            body: jsonEncode({'event_id': eventId}),
          )
          .timeout(const Duration(seconds: 30));
      await _handleResponse(response);
    } catch (e, stackTrace) {
      developer.log('JoinEvent error: $e',
          name: 'ApiService', stackTrace: stackTrace);
      rethrow;
    }
  }

  Future<void> createGoal(
    String userId,
    String description,
    String location,
    String interest, {
    String? pointA,
    String? pointB,
    List<String>? tasks,
    List<String>? imageUrls,
    required String token,
  }) async {
    try {
      developer.log('CreateGoal request: userId=$userId', name: 'ApiService');
      final response = await _client
          .post(
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
              'tasks': tasks
                      ?.map((task) => {'title': task, 'completed': false})
                      .toList() ??
                  [],
              'image_urls': imageUrls ?? [],
            }),
          )
          .timeout(const Duration(seconds: 30));
      await _handleResponse(response);
    } catch (e, stackTrace) {
      developer.log('CreateGoal error: $e',
          name: 'ApiService', stackTrace: stackTrace);
      rethrow;
    }
  }

  Future<void> createEvent(
    String userId,
    String description,
    String location,
    String interest,
    String dateTime, {
    List<String>? imageUrls,
    required String token,
  }) async {
    try {
      developer.log('CreateEvent request: userId=$userId', name: 'ApiService');
      final response = await _client
          .post(
            Uri.parse('$_postsUrl/events/create'),
            headers: {
              'Content-Type': 'application/json',
              'Authorization': 'Bearer $token',
            },
            body: jsonEncode({
              'user_id': userId,
              'description': description,
              'location': location,
              'date_time': dateTime,
              'image_urls': imageUrls ?? [],
            }),
          )
          .timeout(const Duration(seconds: 30));
      await _handleResponse(response);
    } catch (e, stackTrace) {
      developer.log('CreateEvent error: $e',
          name: 'ApiService', stackTrace: stackTrace);
      rethrow;
    }
  }

  void dispose() {
    developer.log('Disposing ApiService', name: 'ApiService');
    _client.close();
  }
}
