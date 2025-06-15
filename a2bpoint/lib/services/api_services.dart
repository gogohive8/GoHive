// api_services.dart
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/post.dart';

class ApiService {
  final SupabaseClient _supabase = Supabase.instance.client;

  Future<Map<String, String>?> login(String email, String password) async {
    try {
      final response = await _supabase.auth.signInWithPassword(
        email: email,
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
      String email, String password) async {
    return await login(email, password);
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

  Future<Map<String, String>?> signInWithFacebook() async {
    try {
      await _supabase.auth.signInWithOAuth(
        OAuthProvider.facebook,
        redirectTo: 'io.supabase.flutterquickstart://callback',
      );
      final session = _supabase.auth.currentSession;
      return {
        'token': session?.accessToken ?? '',
        'userId': session?.user.id ?? ''
      };
    } catch (e) {
      print('Facebook sign in error: $e');
      return null;
    }
  }

  Future<Map<String, String>?> signInWithApple() async {
    try {
      await _supabase.auth.signInWithOAuth(
        OAuthProvider.apple,
        redirectTo: 'io.supabase.flutterquickstart://callback',
      );
      final session = _supabase.auth.currentSession;
      return {
        'token': session?.accessToken ?? '',
        'userId': session?.user.id ?? ''
      };
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

  Future<void> createGoal(
      String userId, String description, String location, String interest,
      {String? pointA, String? pointB, List<String>? tasks}) async {
    try {
      // Второму разработчику: Перед сохранением данных в таблицу goals,
      // загрузите изображения из _images в Supabase Storage (например, в папку 'goals_images')
      // и сохраните URL изображений в отдельном поле (например, 'image_urls' типа JSONB).
      // Пример: await _supabase.storage.from('goals_images').upload('image_name.jpg', file);
      await _supabase.from('goals').insert({
        'user_id': userId,
        'description': description,
        'location': location,
        'interest': interest,
        'point_a': pointA,
        'point_b': pointB,
        'tasks': tasks ?? [],
        'created_at': DateTime.now().toIso8601String(),
      });
    } catch (e) {
      print('Create goal error: $e');
      throw Exception('Failed to create goal: $e');
    }
  }
}
