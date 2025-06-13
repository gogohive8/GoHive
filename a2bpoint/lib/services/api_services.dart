import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/post.dart';

class ApiService {
  final SupabaseClient _supabase = Supabase.instance.client;

  Future<Map<String, String>?> login(String phone, String password) async {
    try {
      final response = await _supabase.auth.signInWithPassword(
        email: '$phone@example.com',
        password: password,
      );
      return {
        'token': response.session?.accessToken ?? '',
        'userId': response.user?.id ?? ''
      };
    } catch (e) {
      print('Login error: $e');
      return null;
    }
  }

  Future<Map<String, String>?> signUp(
      String username, String email, String password) async {
    try {
      final response = await _supabase.auth.signUp(
        email: email,
        password: password,
        data: {'username': username},
      );
      return {
        'token': response.session?.accessToken ?? '',
        'userId': response.user?.id ?? ''
      };
    } catch (e) {
      print('Sign up error: $e');
      return null;
    }
  }

  Future<Map<String, String>?> signInWithEmail(
      String phone, String password) async {
    return await login(phone, password);
  }

  Future<Map<String, String>?> signInWithFacebook() async {
    try {
      await _supabase.auth.signInWithOAuth(
        OAuthProvider.facebook,
        redirectTo: 'io.supabase.flutter://callback',
      );
      return {'token': 'facebook_dummy_token', 'userId': 'facebook_dummy_user'};
    } catch (e) {
      print('Facebook sign in error: $e');
      return null;
    }
  }

  Future<Map<String, String>?> signInWithGoogle() async {
    try {
      await _supabase.auth.signInWithOAuth(
        OAuthProvider.google,
        redirectTo: 'io.supabase.flutter://callback',
      );
      return {'token': 'google_dummy_token', 'userId': 'google_dummy_user'};
    } catch (e) {
      print('Google sign in error: $e');
      return null;
    }
  }

  Future<Map<String, String>?> signInWithApple() async {
    try {
      await Future.delayed(const Duration(seconds: 1));
      return {'token': 'apple_dummy_token', 'userId': 'apple_dummy_user'};
    } catch (e) {
      print('Apple sign in error: $e');
      return null;
    }
  }

  void setToken(String token) {
    print('Token set: $token');
  }

  Future<List<Post>> getPosts() async {
    try {
      final response = await _supabase.from('posts').select();
      return (response as List).map((json) => Post.fromJson(json)).toList();
    } catch (e) {
      print('Get posts error: $e');
      return [];
    }
  }

  Future<void> likePost(String postId) async {
    try {
      await _supabase
          .from('posts')
          .update({'likes': 'likes + 1'}).eq('id', postId);
    } catch (e) {
      print('Like post error: $e');
    }
  }
}
