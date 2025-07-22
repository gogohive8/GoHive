import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../services/exceptions.dart';
import 'dart:developer' as developer;

class AuthProvider with ChangeNotifier {
  final SupabaseClient _supabaseClient = Supabase.instance.client;
  String? _token;
  String? _userId;
  String? _username;
  String? _profileImage;
  String? _email;
  bool _isInitialized = false;

  String? get token => _token;
  String? get userId => _userId;
  String? get username => _username;
  String? get profileImage => _profileImage;
  String? get email => _email;
  bool get isInitialized => _isInitialized;
  bool get isAuthenticated => _token != null && _userId != null;

  AuthProvider() {
    developer.log('AuthProvider created', name: 'AuthProvider');
  }

  Future<void> initialize() async {
    if (_isInitialized) {
      developer.log('AuthProvider already initialized', name: 'AuthProvider');
      return;
    }
    try {
      developer.log('Initializing AuthProvider', name: 'AuthProvider');
      final prefs = await SharedPreferences.getInstance();
      _token = prefs.getString('auth_token');
      _userId = prefs.getString('user_id');
      _username = prefs.getString('username');
      _profileImage = prefs.getString('avatar_url');
      _email = prefs.getString('email');
      _isInitialized = true;
      developer.log(
          'AuthProvider initialized: token=${_token != null}, userId=$_userId',
          name: 'AuthProvider');
      notifyListeners();
    } catch (e, stackTrace) {
      developer.log('Initialization error: $e',
          name: 'AuthProvider', stackTrace: stackTrace);
      _isInitialized =
          true; // Mark as initialized even on error to avoid repeated attempts
      notifyListeners();
    }
  }

  bool shouldRedirectTo() {
    final shouldRedirect =
        _isInitialized && (_token == null || _userId == null);
    developer.log('shouldRedirectTo: $shouldRedirect', name: 'AuthProvider');
    return shouldRedirect;
  }

  Future<void> setAuthData(
      String token, String userId, String email, String username,
      {bool isGoogleLogin = false, bool isNewUser = false}) async {
    try {
      developer.log(
          'Setting auth data: userId=$userId, username=$username, email=$email',
          name: 'AuthProvider');
      _token = token;
      _userId = userId;
      _username = username;
      _email = email;
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('auth_token', token);
      await prefs.setString('user_id', userId);
      await prefs.setString('username', username);
      await prefs.setString('email', email);
      if (_profileImage != null) {
        await prefs.setString('avatar_url', _profileImage!);
      } else {
        await prefs.remove('avatar_url');
      }
      notifyListeners();
    } catch (e, stackTrace) {
      developer.log('Error setting auth data: $e',
          name: 'AuthProvider', stackTrace: stackTrace);
      rethrow;
    }
  }

  Future<void> signIn(String email, String password) async {
    try {
      developer.log('Attempting sign in for email: $email',
          name: 'AuthProvider');
      final response = await _supabaseClient.auth.signInWithPassword(
        email: email,
        password: password,
      );
      final user = response.user;
      if (user == null) {
        throw AuthenticationException('Sign-in failed: No user returned');
      }
      final token = response.session?.accessToken;
      if (token == null) {
        throw AuthenticationException('Sign-in failed: No token returned');
      }
      final username = user.userMetadata?['username']?.toString() ?? 'Unknown';
      final profileImage = user.userMetadata?['avatar_url']?.toString();
      await setAuthData(token, user.id, email, username);
      developer.log('Sign-in successful: userId=${user.id}',
          name: 'AuthProvider');
    } catch (e, stackTrace) {
      developer.log('Sign-in error: $e',
          name: 'AuthProvider', stackTrace: stackTrace);
      rethrow;
    }
  }

  Future<void> signUp(String email, String password, String username) async {
    try {
      developer.log('Attempting sign up for email: $email',
          name: 'AuthProvider');
      final response = await _supabaseClient.auth.signUp(
        email: email,
        password: password,
        data: {'username': username},
      );
      final user = response.user;
      if (user == null) {
        throw AuthenticationException('Sign-up failed: No user returned');
      }
      final token = response.session?.accessToken;
      if (token == null) {
        throw AuthenticationException('Sign-up failed: No token returned');
      }
      await setAuthData(token, user.id, email, username);
      developer.log('Sign-up successful: userId=${user.id}',
          name: 'AuthProvider');
    } catch (e, stackTrace) {
      developer.log('Sign-up error: $e',
          name: 'AuthProvider', stackTrace: stackTrace);
      rethrow;
    }
  }

  Future<void> signOut() async {
    try {
      developer.log('Signing out', name: 'AuthProvider');
      await _supabaseClient.auth.signOut();
      _token = null;
      _userId = null;
      _username = null;
      _profileImage = null;
      _email = null;
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('auth_token');
      await prefs.remove('user_id');
      await prefs.remove('username');
      await prefs.remove('avatar_url');
      await prefs.remove('email');
      notifyListeners();
      developer.log('Sign-out successful', name: 'AuthProvider');
    } catch (e, stackTrace) {
      developer.log('Sign-out error: $e',
          name: 'AuthProvider', stackTrace: stackTrace);
      rethrow;
    }
  }

  void handleAuthError(BuildContext context, Object error) {
    developer.log('Handling auth error: $error', name: 'AuthProvider');
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Ошибка авторизации: $error')),
    );
    if (_token == null || _userId == null) {
      Navigator.pushReplacementNamed(context, '/sign_in');
    }
  }
}
