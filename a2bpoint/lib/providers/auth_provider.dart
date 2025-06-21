import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:developer' as developer;
import '../services/exceptions.dart'; // Import for AuthenticationException

class AuthProvider with ChangeNotifier {
  String? _token;
  String? _userId;
  bool _isInitialized = false;

  String? get token => _token;
  String? get userId => _userId;
  bool get isAuthenticated => _token != null && _userId != null;
  bool get isInitialized => _isInitialized;

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
      developer.log(
          'Loaded from cache: token=${_token != null ? "present" : "null"}, userId=$_userId',
          name: 'AuthProvider');
      notifyListeners();
    } catch (e, stackTrace) {
      developer.log('Error loading from cache: $e',
          name: 'AuthProvider', stackTrace: stackTrace);
    }
  }

  Future<void> setAuthData(String token, String userId) async {
    try {
      _token = token;
      _userId = userId;
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('token', token);
      await prefs.setString('userId', userId);
      developer.log('Auth data set: userId=$userId', name: 'AuthProvider');
      notifyListeners();
    } catch (e, stackTrace) {
      developer.log('Error setting auth data: $e',
          name: 'AuthProvider', stackTrace: stackTrace);
    }
  }

  Future<void> clearAuth() async {
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
      if (context.mounted) {
        Navigator.pushReplacementNamed(context, '/sign_in');
      }
    }
  }
}
