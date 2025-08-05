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
    String date_of_birthday,
    String sex,
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
              'date_of_birthday': date_of_birthday,
              'sex': sex
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
        'avatar': data['profileImage']?.toString() ?? '',
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
      // Convert any Set in data to List to ensure JSON encodability
      final encodableData = data.map((key, value) {
        if (value is Set) {
          return MapEntry(key, value.toList());
        }
        return MapEntry(key, value);
      });

      // ИСПРАВЛЕНО: правильное формирование тела запроса
      final requestBody = {
        'userId': userId,
        'photoURL': photoURL,
        'data': encodableData, // Распаковываем данные из data в основной объект
      };

      final response = await _client
          .post(
            Uri.parse('$_baseUrl/profile/$userId'),
            headers: {
              'Authorization': 'Bearer $token',
              'Content-Type': 'application/json',
            },
            body: jsonEncode(
                requestBody), // Используем правильно сформированный объект
          )
          .timeout(const Duration(seconds: 30));
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

      developer.log('User goals response: ${response.statusCode}',
          name: 'ApiService');

      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        return data.map((json) => Post.fromJson(json, type: 'goal')).toList();
      } else {
        final errorData = jsonDecode(response.body);
        throw Exception('Failed to fetch user goals: ${errorData['error']}');
      }
    } catch (e, stackTrace) {
      developer.log('Error fetching user goals: $e',
          name: 'ApiService', stackTrace: stackTrace);
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

      developer.log('User events response: ${response.statusCode}',
          name: 'ApiService');

      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        return data.map((json) => Post.fromJson(json, type: 'event')).toList();
      } else {
        final errorData = jsonDecode(response.body);
        throw Exception('Failed to fetch user events: ${errorData['error']}');
      }
    } catch (e, stackTrace) {
      developer.log('Error fetching user events: $e',
          name: 'ApiService', stackTrace: stackTrace);
      throw Exception('Failed to fetch user events: $e');
    }
  }
}
