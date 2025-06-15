import 'package:supabase_flutter/supabase_flutter.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter/material.dart';
import '../models/post.dart';
import '../providers/auth_provider.dart';

class ApiService {
  final SupabaseClient _supabase = Supabase.instance.client;

  SupabaseClient get supabase => _supabase;
  static const String _baseUrl = 'http://localhost:3000'; // API Gateway URL
  final http.Client _client = http.Client();

  Future<Map<String, String>?> login(String email, String password) async {
    try {
      final response = await _client.post(
        Uri.parse('$_baseUrl/api/login'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'email': email, 'password': password}),
      );
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return {'token': data['token'] ?? '', 'userId': data['userId'] ?? ''};
      } else {
        print('Login error: ${response.body}');
        return null;
      }
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
      final response = await _client
          .post(
            Uri.parse('$_baseUrl/api/register/email'),
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode({
              'firstName': firstName,
              'lastName': lastName,
              'username': username,
              'age': age,
              'email': email,
              'phoneNumber': phoneNumber,
              'password': password,
            }),
          )
          .timeout(Duration(seconds: 30));
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return {'token': data['token'] ?? '', 'userId': data['userId'] ?? ''};
      } else {
        print('Sign up error: ${response.body}');
        return null;
      }
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
      return {
        'token': session?.accessToken ?? '',
        'userId': session?.user.id ?? ''
      };
    } catch (e) {
      print('Google sign in error: $e');
      return null;
    }
  }

  Future<List<Post>> getGoals() async {
    try {
      final response = await _supabase
          .from('goals')
          .select('*, user(id, username, avatar_url)');
      return (response as List)
          .map((json) => Post.fromJson({...json, 'type': 'goal'}))
          .toList();
    } catch (e) {
      print('Get goals error: $e');
      return [];
    }
  }

  Future<List<Post>> getEvents() async {
    try {
      final response = await _supabase
          .from('events')
          .select('*, user(id, username, avatar_url)');
      return (response as List)
          .map((json) => Post.fromJson({...json, 'type': 'event'}))
          .toList();
    } catch (e) {
      print('Get events error: $e');
      return [];
    }
  }

  Future<void> likePost(String postId, String type) async {
    try {
      await _supabase
          .from(type == 'goal' ? 'goals' : 'events')
          .update({'likes': 'likes + 1'}).eq('id', postId);
    } catch (e) {
      print('Like post error: $e');
      throw Exception('Failed to like post: $e');
    }
  }

  Future<void> joinEvent(String eventId, String userId) async {
    try {
      await _supabase.from('event_participants').insert({
        'event_id': eventId,
        'user_id': userId,
      });
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
      List<String>? imageUrls}) async {
    try {
      await _supabase.from('goals').insert({
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
      });
    } catch (e) {
      print('Create goal error: $e');
      throw Exception('Failed to create goal: $e');
    }
  }

  Future<void> createEvent(String userId, String description, String location,
      {String? pointA,
      String? pointB,
      List<String>? tasks,
      List<String>? imageUrls}) async {
    try {
      await _supabase.from('events').insert({
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
      });
    } catch (e) {
      print('Create event error: $e');
      throw Exception('Failed to create event: $e');
    }
  }
}
