import 'dart:developer' as developer;
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AuthProvider with ChangeNotifier {
  String? _token;
  String? _userId;
  String? _email;
  String? _username;
  String? _bio;
  bool _isAuthenticated = false;
  bool _isInitialized = false;
  bool _isNewGoogleUser = false;

  String? get token => _token;
  String? get userId => _userId;
  String? get email => _email;
  String? get username => _username;
  String? get bio => _bio;
  bool get isAuthenticated => _isAuthenticated;
  bool get isInitialized => _isInitialized;
  bool get isNewGoogleUser => _isNewGoogleUser;

  AuthProvider() {
    _loadAuthData();
  }

  Future<void> initialize() async {
    await _loadAuthData();
  }

  Future<void> _loadAuthData() async {
    try {
      developer.log('Loading auth data from SharedPreferences',
          name: 'AuthProvider');
      final prefs = await SharedPreferences.getInstance();
      _token = prefs.getString('token');
      _userId = prefs.getString('userId');
      _email = prefs.getString('email');
      _username = prefs.getString('username');
      _bio = prefs.getString('bio_${_userId ?? ''}') ?? '';
      _isAuthenticated = _token != null &&
          _userId != null &&
          _token!.isNotEmpty &&
          _userId!.isNotEmpty;
      _isInitialized = true;
      _isNewGoogleUser = prefs.getBool('isNewGoogleUser') ?? false;
      developer.log(
          'Auth data loaded: token=${_token != null}, userId=${_userId != null}, email=${_email != null}, username=${_username != null}, bio=${_bio != null}, isAuthenticated=$_isAuthenticated, isNewGoogleUser=$_isNewGoogleUser',
          name: 'AuthProvider');
      notifyListeners();
    } catch (e, stackTrace) {
      developer.log('Error loading auth data: $e',
          name: 'AuthProvider', stackTrace: stackTrace);
      _isInitialized = true;
      notifyListeners();
    }
  }

  bool shouldRedirectTo() {
    return !isAuthenticated || _token == null || _userId == null;
  }

  Future<void> setAuthData(
    String token,
    String userId,
    String email,
    String? username, {
    String? bio,
    bool isGoogleLogin = false,
    bool isNewUser = false,
  }) async {
    try {
      developer.log(
          'Setting auth data: token=$token, userId=$userId, email=$email, username=$username, bio=$bio, isGoogleLogin=$isGoogleLogin, isNewUser=$isNewUser',
          name: 'AuthProvider');
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('token', token);
      await prefs.setString('userId', userId);
      await prefs.setString('email', email);
      if (username != null) {
        await prefs.setString('username', username);
      } else {
        await prefs.remove('username');
      }
      if (bio != null) {
        await prefs.setString('bio_$userId', bio);
      } else {
        await prefs.remove('bio_$userId');
      }
      await prefs.setBool('isNewGoogleUser', isGoogleLogin && isNewUser);
      _token = token;
      _userId = userId;
      _email = email;
      _username = username;
      _bio = bio;
      _isAuthenticated = true;
      _isNewGoogleUser = isGoogleLogin && isNewUser;
      developer.log('Auth data set: isAuthenticated=true',
          name: 'AuthProvider');
      notifyListeners();
    } catch (e, stackTrace) {
      developer.log('Error setting auth data: $e',
          name: 'AuthProvider', stackTrace: stackTrace);
      await clearAuthData();
    }
  }

  Future<void> updateProfile(String username, String bio) async {
    try {
      developer.log('Updating profile: username=$username, bio=$bio',
          name: 'AuthProvider');
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('username', username);
      await prefs.setString('bio_${_userId ?? ''}', bio);
      _username = username;
      _bio = bio;
      developer.log('Profile updated locally', name: 'AuthProvider');
      notifyListeners();
    } catch (e, stackTrace) {
      developer.log('Error updating profile: $e',
          name: 'AuthProvider', stackTrace: stackTrace);
    }
  }

  Future<void> clearAuthData() async {
    try {
      developer.log('Clearing auth data', name: 'AuthProvider');
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('token');
      await prefs.remove('userId');
      await prefs.remove('email');
      await prefs.remove('username');
      await prefs.remove('bio_${_userId ?? ''}');
      await prefs.remove('isNewGoogleUser');
      _token = null;
      _userId = null;
      _email = null;
      _username = null;
      _bio = null;
      _isAuthenticated = false;
      _isNewGoogleUser = false;
      developer.log('Auth data cleared', name: 'AuthProvider');
      notifyListeners();
    } catch (e, stackTrace) {
      developer.log('Error clearing auth data: $e',
          name: 'AuthProvider', stackTrace: stackTrace);
    }
  }

  void handleAuthError(BuildContext context, dynamic error) {
    developer.log('Handling auth error: $error', name: 'AuthProvider');
    clearAuthData();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (context.mounted) {
        Navigator.pushReplacementNamed(context, '/sign_in');
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Authentication error: ${error.toString()}')),
        );
      }
    });
  }
}