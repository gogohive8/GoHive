import 'package:flutter/foundation.dart';

class AuthProvider with ChangeNotifier {
  String? _token;
  String? _userId;

  String? get token => _token;
  String? get userId => _userId;
  bool get isAuthenticated => _token != null;

  void setAuthData(String token, String userId) {
    _token = token;
    _userId = userId;
    notifyListeners();
  }

  void clearAuth() {
    _token = null;
    _userId = null;
    notifyListeners();
  }
}
