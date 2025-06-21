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
          'Loaded from cache: token=${_token != null ? "present" : "null"}, userId=$_userId, username=$_username, bio=$_bio, isFirstLogin=$_isFirstLogin',
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
      await prefs.setString('token', token);
      await prefs.setString('userId', userId);
      await prefs.setString('username', _username!);
      await prefs.setBool('isFirstLogin', _isFirstLogin);
      developer.log(
          'Auth data set: userId=$userId, username=$username, isFirstLogin=$_isFirstLogin',
          name: 'AuthProvider');
      notifyListeners();
    } catch (e, stackTrace) {
      developer.log('Error setting auth data: $e',
          name: 'AuthProvider', stackTrace: stackTrace);
      if (e is AuthenticationException) {
        _token = null;
        _userId = null;
        _username = null;
        _isFirstLogin = true;
        notifyListeners();
      }
    }
  }

  Future<void> setBio(String bio) async {
    try {
      _bio = bio;
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('bio', bio);
      developer.log('Bio updated: $bio', name: 'AuthProvider');
      notifyListeners();
    } catch (e, stackTrace) {
      developer.log('Error setting bio: $e',
          name: 'AuthProvider', stackTrace: stackTrace);
    }
  }

  Future<void> markWelcomeShown() async {
    try {
      _isFirstLogin = false;
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('isFirstLogin', false);
      developer.log('Welcome screen marked as shown', name: 'AuthProvider');
      notifyListeners();
    } catch (e, stackTrace) {
      developer.log('Error marking welcome shown: $e',
          name: 'AuthProvider', stackTrace: stackTrace);
    }
  }

  Future<void> logout() async {
    try {
      _token = null;
      _userId = null;
      _username = null;
      _bio = null;
      _isFirstLogin = true;
      final prefs = await SharedPreferences.getInstance();
      await prefs.clear();
      developer.log('Logged out and cleared cache', name: 'AuthProvider');
      notifyListeners();
    } catch (e, stackTrace) {
      developer.log('Error during logout: $e',
          name: 'AuthProvider', stackTrace: stackTrace);
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
