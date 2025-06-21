import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:developer' as developer;

class AuthProvider with ChangeNotifier {
  String? _token;
  String? _userId;
  bool _isInitialized = false;

  String? get token => _token;
  String? get userId => _userId;
  bool get isAuthenticated => _token != null && _userId != null;
  bool get isInitialized => _isInitialized;

  // Инициализация провайдера с автоматической загрузкой из кэша
  Future<void> initialize() async {
    if (!_isInitialized) {
      developer.log('Initializing AuthProvider', name: 'AuthProvider');
      await loadFromCache();
      _isInitialized = true;
      notifyListeners();
    }
  }

  // Загрузка данных из кэша
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

  // Сохранение данных в кэш
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

  // Очистка данных авторизации
  Future<void> clearAuth() async {
    try {
      _token = null;
      _userId = null;
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('token');
      await prefs.remove('userId');
      developer.log('Auth data cleared', name: 'AuthProvider');
      notifyListeners();
    } catch (e, stackTrace) {
      developer.log('Error clearing auth data: $e',
          name: 'AuthProvider', stackTrace: stackTrace);
    }
  }

  // Проверка необходимости редиректа на страницу авторизации
  bool shouldRedirectToSignIn() {
    final shouldRedirect = !isAuthenticated && _isInitialized;
    if (shouldRedirect) {
      developer.log('Redirecting to sign-in: not authenticated',
          name: 'AuthProvider');
    }
    return shouldRedirect;
  }
}
