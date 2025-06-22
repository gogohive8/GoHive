import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:developer' as developer;
import '../services/exceptions.dart';

class AuthProvider with ChangeNotifier {
  String? _token;
  String? _userId;
  String? _username; // Добавляем поле username
  bool _isInitialized = false;

  String? get token => _token;
  String? get userId => _userId;
  String? get username => _username; // Геттер для username
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
      _username = prefs.getString('username'); // Загружаем username
      developer.log(
          'Loaded from cache: token=${_token != null ? "present" : "null"}, userId=${_userId != null ? _userId : "null"}, username=${_username != null ? _username : "null"}',
          name: 'AuthProvider');
      notifyListeners();
    } catch (e, stackTrace) {
      developer.log('Error loading from cache: $e',
          name: 'AuthProvider', stackTrace: stackTrace);
    }
  }

  Future<void> setAuthData(String token, String userId,
      {String? username}) async {
    try {
      _token = token;
      _userId = userId;
      _username = username; // Устанавливаем username
      final prefs = await SharedPreferences.getInstance();
      final tokenSaved = await prefs.setString('token', token);
      final userIdSaved = await prefs.setString('userId', userId);
      final usernameSaved =
          username != null ? await prefs.setString('username', username) : true;
      if (!tokenSaved || !userIdSaved || !usernameSaved) {
        developer.log('Failed to save auth data to SharedPreferences',
            name: 'AuthProvider');
        throw Exception('Failed to save auth data');
      }
      developer.log('Auth data set: userId=$userId, username=$username',
          name: 'AuthProvider');
      notifyListeners();
    } catch (e, stackTrace) {
      developer.log('Error setting auth data: $e',
          name: 'AuthProvider', stackTrace: stackTrace);
      throw Exception('Error setting auth data: $e');
    }
  }

  Future<void> clearAuth() async {
    try {
      developer.log('Clearing auth data, stack trace: ${StackTrace.current}',
          name: 'AuthProvider');
      _token = null;
      _userId = null;
      _username = null; // Очищаем username
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('token');
      await prefs.remove('userId');
      await prefs.remove('username'); // Удаляем username
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
      await Future.delayed(const Duration(seconds: 2));
      if (context.mounted) {
        Navigator.pushReplacementNamed(context, '/sign_in');
      }
    }
  }
}
