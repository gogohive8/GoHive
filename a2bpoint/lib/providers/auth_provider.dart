import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:developer' as developer;
import '../services/exceptions.dart';

class AuthProvider with ChangeNotifier {
  String? _token;
  String? _userId;
  String? _username;
  String? _bio;
  bool _isInitialized = false;
  bool _isFirstLogin = false;

  String? get token => _token;
  String? get userId => _userId;
  String? get username => _username;
  String? get bio => _bio;
  bool get isAuthenticated => _token != null && _userId != null;
  bool get isInitialized => _isInitialized;
  bool get isFirstLogin => _isFirstLogin;

  Future<void> initialize() async {
    if (!_isInitialized) {
      developer.log('Initializing AuthProvider', name: 'AuthProvider');
      await loadFromCache();
      _isInitialized = true;
      notifyListeners();
    }
  }

  Future<void> loadFromCache() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      _token = prefs.getString('token');
      _userId = prefs.getString('userId');
      _username = prefs.getString('username');
      _bio = prefs.getString('bio');
      _isFirstLogin = prefs.getBool('isFirstLogin') ?? true;
      developer.log(
          'Loaded from cache: token=${_token != null ? "present" : "null"}, userId=${_userId != null ? _userId : "null"}',
          name: 'AuthProvider');
      notifyListeners();
    } catch (e, stackTrace) {
      developer.log('Error loading from cache: $e',
          name: 'AuthProvider', stackTrace: stackTrace);
    }
  }

  Future<void> setAuthData(
      String token, String userId, String? username, bool isGoogleLogin) async {
    try {
      _token = token;
      _userId = userId;
      _username = username ?? 'Unknown';
      _isFirstLogin = isGoogleLogin;
      final prefs = await SharedPreferences.getInstance();
      final tokenSaved = await prefs.setString('token', token);
      final userIdSaved = await prefs.setString('userId', userId);
      if (!tokenSaved || !userIdSaved) {
        developer.log('Failed to save auth data to SharedPreferences',
            name: 'AuthProvider');
        throw Exception('Failed to save auth data');
      }
      developer.log('Auth data set: userId=$userId', name: 'AuthProvider');
      notifyListeners();
    } catch (e, stackTrace) {
      developer.log('Error setting auth data: $e',
          name: 'AuthProvider', stackTrace: stackTrace);
      throw Exception('Error setting auth data: $e');
    }
  }

  Future<void> setBio(String bio) async {
    try {
      developer.log('Clearing auth data, stack trace: ${StackTrace.current}',
          name: 'AuthProvider');
      _token = null;
      _userId = null;
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('token');
      await prefs.remove('userId');
      notifyListeners();
    } catch (e, stackTrace) {
      developer.log('Error clearing auth data: $e',
          name: 'AuthProvider', stackTrace: stackTrace);
    }
  }

  bool shouldRedirectTo() {
    final shouldRedirect = !isAuthenticated && _isInitialized;
    if (shouldRedirect) {
      developer.log('Should redirect to sign-in: not authenticated',
          name: 'AuthProvider');
    }
    return shouldRedirect;
  }

  Future<void> handleAuthError(BuildContext context, dynamic error) async {
    if (error is AuthenticationException) {
      developer.log('Authentication error detected: ${error.message}',
          name: 'AuthProvider');
      await clearAuth();
      // Добавляем задержку перед редиректом
      await Future.delayed(const Duration(seconds: 2));
      if (context.mounted) {
        Navigator.pushReplacementNamed(context, '/sign_in');
      }
    }
  }

  void handleAuthError(BuildContext context, dynamic error) {
    developer.log('Handling auth error: $error', name: 'AuthProvider');
    if (error is AuthenticationException) {
      logout();
      Navigator.pushReplacementNamed(context, '/sign-in');
    }
  }

  bool shouldRedirectTo() {
    return !isAuthenticated && _isInitialized;
  }
}
