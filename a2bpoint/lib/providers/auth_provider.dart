import 'dart:developer' as developer;
import 'dart:async';
import 'package:GoHive/services/exceptions.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:io';
import '../services/api_services.dart';
import '../services/post_service.dart';

class AuthProvider with ChangeNotifier {
  String? _token;
  String? _refreshToken;
  String? _userId;
  String? _email;
  String? _username;
  String? _bio;
  String? _avatarUrl;
  String? _phoneNumber;
  String? _country;
  String? _city;
  String? _sex;
  String? _dateOfBirthday;
  bool _isAuthenticated = false;
  bool _isInitialized = false;
  bool _isNewGoogleUser = false;
  
  // Для автоматического обновления токена
  Timer? _tokenRefreshTimer;
  DateTime? _tokenExpiry;
  bool _isRefreshingToken = false;

  // ДОБАВЛЕНА навигация
  final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

  // Getters
  String? get token => _token;
  String? get refreshToken => _refreshToken;
  String? get userId => _userId;
  String? get email => _email;
  String? get username => _username;
  String? get bio => _bio;
  String? get avatarUrl => _avatarUrl;
  String? get phoneNumber => _phoneNumber;
  String? get country => _country;
  String? get city => _city;
  String? get sex => _sex;
  String? get dateOfBirthday => _dateOfBirthday;
  bool get isAuthenticated => _isAuthenticated;
  bool get isInitialized => _isInitialized;
  bool get isNewGoogleUser => _isNewGoogleUser;

  // Setters
  set username(String? value) {
    _username = value;
    notifyListeners();
  }

  set bio(String? value) {
    _bio = value;
    notifyListeners();
  }

  set avatarUrl(String? value) {
    _avatarUrl = value;
    notifyListeners();
  }

  AuthProvider() {
    _loadAuthData();
  }

  @override
  void dispose() {
    _tokenRefreshTimer?.cancel();
    super.dispose();
  }

  Future<void> initialize() async {
    await _loadAuthData();
  }

  Future<void> _loadAuthData() async {
    try {
      developer.log('Loading auth data from SharedPreferences', name: 'AuthProvider');
      final prefs = await SharedPreferences.getInstance();
      _token = prefs.getString('token');
      _refreshToken = prefs.getString('refreshToken');
      _userId = prefs.getString('userId');
      _email = prefs.getString('email');
      _username = prefs.getString('username');
      _bio = prefs.getString('bio_${_userId ?? ''}') ?? '';
      _avatarUrl = prefs.getString('avatarUrl_${_userId ?? ''}') ?? '';
      _phoneNumber = prefs.getString('phoneNumber_${_userId ?? ''}');
      _country = prefs.getString('country_${_userId ?? ''}');
      _city = prefs.getString('city_${_userId ?? ''}');
      _sex = prefs.getString('sex_${_userId ?? ''}');
      _dateOfBirthday = prefs.getString('dateOfBirthday_${_userId ?? ''}');
      
      // Загружаем время истечения токена
      final tokenExpiryString = prefs.getString('tokenExpiry');
      if (tokenExpiryString != null) {
        _tokenExpiry = DateTime.parse(tokenExpiryString);
      }
      
      _isAuthenticated = _token != null &&
          _userId != null &&
          _token!.isNotEmpty &&
          _userId!.isNotEmpty;
      _isInitialized = true;
      _isNewGoogleUser = prefs.getBool('isNewGoogleUser') ?? false;
      
      developer.log(
          'Auth data loaded: token=${_token != null}, userId=${_userId != null}, email=${_email != null}, username=${_username != null}, bio=${_bio != null}, avatarUrl=${_avatarUrl != null}, isAuthenticated=$_isAuthenticated, isNewGoogleUser=$_isNewGoogleUser',
          name: 'AuthProvider');
      
      // Проверяем и обновляем токен если нужно
      if (_isAuthenticated) {
        await _checkAndRefreshToken();
        _setupTokenRefreshTimer();
      }
      
      notifyListeners();
    } catch (e, stackTrace) {
      developer.log('Error loading auth data: $e', name: 'AuthProvider', stackTrace: stackTrace);
      _isInitialized = true;
      notifyListeners();
    }
  }

  bool shouldRedirectTo() {
    return !isAuthenticated || _token == null || _userId == null;
  }

  Future<void> setAuthData(
    String token,
    String refreshToken,
    String userId,
    String email,
    String? username, {
    String? bio,
    String? avatarUrl,
    bool isGoogleLogin = false,
    bool isNewUser = false,
    int? expiresInSeconds,
  }) async {
    try {
      developer.log(
          'Setting auth data: token=$token, refreshToken=$refreshToken, userId=$userId, email=$email, username=$username, bio=$bio, avatarUrl=$avatarUrl, isGoogleLogin=$isGoogleLogin, isNewUser=$isNewUser',
          name: 'AuthProvider');
      
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('token', token);
      await prefs.setString('refreshToken', refreshToken);
      await prefs.setString('userId', userId);
      await prefs.setString('email', email);
      
      // Устанавливаем время истечения токена (по умолчанию 1 час)
      final expiryTime = DateTime.now().add(Duration(seconds: expiresInSeconds ?? 3600));
      _tokenExpiry = expiryTime;
      await prefs.setString('tokenExpiry', expiryTime.toIso8601String());
      
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
      if (avatarUrl != null) {
        await prefs.setString('avatarUrl_$userId', avatarUrl);
      } else {
        await prefs.remove('avatarUrl_$userId');
      }
      await prefs.setBool('isNewGoogleUser', isGoogleLogin && isNewUser);
      
      _token = token;
      _refreshToken = refreshToken;
      _userId = userId;
      _email = email;
      _username = username;
      _bio = bio;
      _avatarUrl = avatarUrl;
      _isAuthenticated = true;
      _isNewGoogleUser = isGoogleLogin && isNewUser;
      
      _setupTokenRefreshTimer();
      
      developer.log('Auth data set: isAuthenticated=true', name: 'AuthProvider');
      notifyListeners();
    } catch (e, stackTrace) {
      developer.log('Error setting auth data: $e', name: 'AuthProvider', stackTrace: stackTrace);
      await clearAuthData();
    }
  }

  void _setupTokenRefreshTimer() {
    _tokenRefreshTimer?.cancel();
    
    if (_tokenExpiry == null) return;
    
    final refreshTime = _tokenExpiry!.subtract(Duration(minutes: 5));
    final now = DateTime.now();
    
    if (refreshTime.isAfter(now)) {
      final duration = refreshTime.difference(now);
      developer.log('Setting up token refresh timer for ${duration.inMinutes} minutes', name: 'AuthProvider');
      
      _tokenRefreshTimer = Timer(duration, () {
        _refreshTokenAutomatically();
      });
    } else {
      _refreshTokenAutomatically();
    }
  }

  Future<void> _checkAndRefreshToken() async {
    if (_tokenExpiry == null || _refreshToken == null) return;
    
    final now = DateTime.now();
    if (_tokenExpiry!.difference(now).inMinutes < 10) {
      developer.log('Token expires soon, refreshing...', name: 'AuthProvider');
      await _refreshTokenAutomatically();
    }
  }

  // ИСПРАВЛЕННЫЙ метод обновления токена
  Future<void> _refreshTokenAutomatically() async {
    if (_isRefreshingToken || _refreshToken == null) return;
    
    _isRefreshingToken = true;
    
    try {
      developer.log('Refreshing token automatically...', name: 'AuthProvider');
      
      final apiService = ApiService();
      final result = await apiService.refreshToken(_refreshToken!, _userId ?? '');
      
      if (result != null && result['access_token'] != null) {
        final newToken = result['access_token'];
        final newRefreshToken = result['refresh_token'] ?? _refreshToken;
        final expiresIn = result['expires_in'] ?? 3600;
        
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('token', newToken);
        await prefs.setString('refreshToken', newRefreshToken);
        
        final expiryTime = DateTime.now().add(Duration(seconds: expiresIn));
        _tokenExpiry = expiryTime;
        await prefs.setString('tokenExpiry', expiryTime.toIso8601String());
        
        _token = newToken;
        _refreshToken = newRefreshToken;
        
        _setupTokenRefreshTimer();
        
        developer.log('Token refreshed successfully', name: 'AuthProvider');
        notifyListeners();
      } else {
        throw Exception('Invalid refresh token response');
      }
    } catch (e) {
      developer.log('Failed to refresh token: $e', name: 'AuthProvider');
      await handleAuthError(e, AuthenticationException('Failed to refresh token: $e'));
    } finally {
      _isRefreshingToken = false;
    }
  }

  Future<bool> refreshTokenManually() async {
    if (_refreshToken == null) return false;
    
    try {
      await _refreshTokenAutomatically();
      return _token != null;
    } catch (e) {
      developer.log('Manual token refresh failed: $e', name: 'AuthProvider');
      return false;
    }
  }

  bool isTokenValid() {
    if (_tokenExpiry == null) return _token != null;
    return _token != null && DateTime.now().isBefore(_tokenExpiry!);
  }

  Future<String?> getValidToken() async {
    if (!isTokenValid()) {
      final refreshed = await refreshTokenManually();
      if (!refreshed) return null;
    }
    return _token;
  }

  Future<void> updateProfile(
      String username, String bio, String email, File? newAvatar) async {
    try {
      developer.log(
          'Updating profile: username=$username, bio=$bio, email=$email, newAvatar=${newAvatar?.path}',
          name: 'AuthProvider');
      
      final validToken = await getValidToken();
      if (validToken == null) {
        throw Exception('Invalid token');
      }
      
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('username', username);
      await prefs.setString('bio_${_userId ?? ''}', bio);
      await prefs.setString('email', email);
      String? photoURL;
      if (newAvatar != null) {
        photoURL = await PostService().uploadMedia(newAvatar, validToken);
        await prefs.setString('avatarUrl_${_userId ?? ''}', photoURL);
        _avatarUrl = photoURL;
      }
      _username = username;
      _bio = bio;
      _email = email;
      developer.log('Profile updated locally', name: 'AuthProvider');
      notifyListeners();

      await ApiService().updateProfile(
        _userId ?? '',
        validToken,
        {
          'username': username,
          'bio': bio,
          'email': email,
          if (photoURL != null) 'avatarUrl': photoURL,
        },
        photoURL ?? '',
      );
    } catch (e, stackTrace) {
      developer.log('Error updating profile: $e', name: 'AuthProvider', stackTrace: stackTrace);
      rethrow;
    }
  }

  Future<void> updatePersonalData({
    required String username,
    required String email,
    String? phoneNumber,
    String? country,
    String? city,
    String? sex,
    String? dateOfBirthday,
  }) async {
    try {
      developer.log(
          'Updating personal data: username=$username, email=$email, phoneNumber=$phoneNumber, country=$country, city=$city, sex=$sex, dateOfBirthday=$dateOfBirthday',
          name: 'AuthProvider');

      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('username', username);
      await prefs.setString('email', email);

      if (phoneNumber != null) {
        await prefs.setString('phoneNumber_${_userId ?? ''}', phoneNumber);
      }
      if (country != null) {
        await prefs.setString('country_${_userId ?? ''}', country);
      }
      if (city != null) {
        await prefs.setString('city_${_userId ?? ''}', city);
      }
      if (sex != null) {
        await prefs.setString('sex_${_userId ?? ''}', sex);
      }
      if (dateOfBirthday != null) {
        await prefs.setString('dateOfBirthday_${_userId ?? ''}', dateOfBirthday);
      }

      _username = username;
      _email = email;
      _phoneNumber = phoneNumber;
      _country = country;
      _city = city;
      _sex = sex;
      _dateOfBirthday = dateOfBirthday;

      developer.log('Personal data updated locally', name: 'AuthProvider');
      notifyListeners();
    } catch (e, stackTrace) {
      developer.log('Error updating personal data: $e', name: 'AuthProvider', stackTrace: stackTrace);
      rethrow;
    }
  }

  Future<void> clearAuthData() async {
    try {
      developer.log('Clearing auth data', name: 'AuthProvider');
      
      _tokenRefreshTimer?.cancel();
      
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('token');
      await prefs.remove('refreshToken');
      await prefs.remove('tokenExpiry');
      await prefs.remove('userId');
      await prefs.remove('email');
      await prefs.remove('username');
      await prefs.remove('bio_${_userId ?? ''}');
      await prefs.remove('avatarUrl_${_userId ?? ''}');
      await prefs.remove('phoneNumber_${_userId ?? ''}');
      await prefs.remove('country_${_userId ?? ''}');
      await prefs.remove('city_${_userId ?? ''}');
      await prefs.remove('sex_${_userId ?? ''}');
      await prefs.remove('dateOfBirthday_${_userId ?? ''}');
      await prefs.remove('isNewGoogleUser');
      
      _token = null;
      _refreshToken = null;
      _tokenExpiry = null;
      _userId = null;
      _email = null;
      _username = null;
      _bio = null;
      _avatarUrl = null;
      _phoneNumber = null;
      _country = null;
      _city = null;
      _sex = null;
      _dateOfBirthday = null;
      _isAuthenticated = false;
      _isNewGoogleUser = false;
      _isRefreshingToken = false;
      
      developer.log('Auth data cleared', name: 'AuthProvider');
      notifyListeners();
    } catch (e, stackTrace) {
      developer.log('Error clearing auth data: $e', name: 'AuthProvider', stackTrace: stackTrace);
    }
  }

  // ИСПРАВЛЕННАЯ обработка ошибок аутентификации
  Future<void> handleAuthError(dynamic error, AuthenticationException authenticationException) async {
    developer.log('Handling auth error: $error', name: 'AuthProvider');
    
    await clearAuthData();
    
    // Безопасная навигация без использования BuildContext
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final context = navigatorKey.currentContext;
      if (context != null && context.mounted) {
        Navigator.of(context).pushNamedAndRemoveUntil(
          '/sign_in', 
          (route) => false,
        );
      }
    });
  }

  // ДОПОЛНИТЕЛЬНЫЙ метод для использования с контекстом (обратная совместимость)
  void handleAuthErrorWithContext(BuildContext context, dynamic error) {
    developer.log('Handling auth error with context: $error', name: 'AuthProvider');
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