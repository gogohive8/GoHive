import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:supabase_flutter/supabase_flutter.dart';

class ApiService {
  static const String baseUrl = 'http://localhost:3000/api';
  String? _token;
  final SupabaseClient _supabase = Supabase.instance.client;

  void setToken(String token) {
    _token = token;
  }

  Future<void> signUpEmail(String name, String surname, String? username,
      int? age, String mail, String? phone, String password) async {
    final response = await http.post(
      Uri.parse('$baseUrl/register/email'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'name': name,
        'surname': surname,
        'username': username,
        'age': age,
        'mail': mail,
        'phone': phone,
        'password': password,
      }),
    );
    if (response.statusCode != 201) {
      throw Exception('Failed to sign up: ${response.body}');
    }
    final data = jsonDecode(response.body);
    setToken(data['token']);
  }

  Future<String> signUpOAuth(String provider) async {
    await _supabase.auth.signInWithOAuth(
      provider == 'google' ? OAuthProvider.google : OAuthProvider.apple,
      redirectTo: 'https://osyajqltbkudsfcppqgh.supabase.co/auth/v1/callback',
    );

    final session = _supabase.auth.currentSession;
    if (session == null) {
      throw Exception('OAuth sign-in failed');
    }

    final response = await http.post(
      Uri.parse('$baseUrl/register/oauth'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'provider': provider,
        'access_token': session.accessToken,
      }),
    );
    if (response.statusCode != 200) {
      throw Exception('Failed to complete OAuth sign-in: ${response.body}');
    }
    final data = jsonDecode(response.body);
    return data['token'];
  }

  Future<String> login(String mail, String password) async {
    final response = await http.post(
      Uri.parse('$baseUrl/login'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'mail': mail, 'password': password}),
    );
    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      setToken(data['token']);
      return data['token'];
    } else {
      throw Exception('Failed to login: ${response.body}');
    }
  }

  Future<void> logout() async {
    final response = await http.post(
      Uri.parse('$baseUrl/logout'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $_token',
      },
    );
    if (response.statusCode != 200) {
      throw Exception('Failed to logout: ${response.body}');
    }
    setToken('');
  }
}
