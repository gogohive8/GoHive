import 'dart:convert';
import 'dart:developer' as developer;
import 'package:http/http.dart' as http;
import 'package:supabase_flutter/supabase_flutter.dart';
import 'exceptions.dart';

class AIService {
  final http.Client _client = http.Client();
  final SupabaseClient _supabase = Supabase.instance.client;
  static const String _aiUrl =
      'https://gohive-ai-service-38f2e813d406.herokuapp.com';

  SupabaseClient get supabase => _supabase;

  Future<dynamic> _handleResponse(http.Response response) async {
    developer.log('Response: ${response.statusCode}, body: ${response.body}',
        name: 'ApiService');
    if (response.statusCode >= 200 && response.statusCode < 300) {
      if (response.statusCode == 204) return {};
      return response.body.isNotEmpty ? jsonDecode(response.body) : {};
    }
    if (response.statusCode == 400) {
      final errorBody = jsonDecode(response.body);
      final errorMessage = errorBody['error']?.toString() ?? 'Invalid input';
      developer.log('Validation error: $errorMessage', name: 'ApiService');
      throw DataValidationException('Invalid input: $errorMessage');
    }
    if (response.statusCode == 401) {
      developer.log('Unauthorized: ${response.body}', name: 'ApiService');
      throw AuthenticationException('Unauthorized: ${response.body}');
    }
    throw Exception('Request failed: ${response.statusCode} ${response.body}');
  }

  // Future<http.Response> _makeRequest(
  //     Future<http.Response> Function() request, int retries) async {
  //   for (int attempt = 1; attempt <= retries; attempt++) {
  //     try {
  //       final response = await request().timeout(const Duration(seconds: 30));
  //       return response;
  //     } catch (e) {
  //       if (attempt == retries) rethrow;
  //       developer.log('Request attempt $attempt failed: $e',
  //           name: 'ApiService');
  //       await Future.delayed(Duration(milliseconds: 500 * attempt));
  //     }
  //   }
  //   throw Exception('Request failed after $retries attempts');
  // }

  Future<String> generateGoal(String prompt, String token) async {
    try {
      developer.log('Sending goal generation request: prompt: $prompt',
          name: 'ApiService');
      final response = await _client
          .post(
            Uri.parse('$_aiUrl/api/generate-goal'),
            headers: {
              'Authorization': 'Bearer $token',
              'Content-Type': 'application/json',
            },
            body: jsonEncode({'prompt': prompt}),
          )
          .timeout(const Duration(seconds: 30));
      final data = await _handleResponse(response);
      final aiResponse = data.toString();
      developer.log('Goal generation response: $aiResponse}',
          name: 'ApiService');
      return aiResponse;
    } catch (e, stackTrace) {
      developer.log('Goal generation error: $e',
          name: 'ApiService', stackTrace: stackTrace);
      throw Exception('Failed to generate goal: $e');
    }
  }

  Future<String> generateEvent(String prompt, String token) async {
    try {
      developer.log('Sending event generation request: prompt: $prompt',
          name: 'ApiService');
      final response = await _client
          .post(
            Uri.parse('$_aiUrl/api/generate-event'),
            headers: {
              'Authorization': 'Bearer $token',
              'Content-Type': 'application/json',
            },
            body: jsonEncode({'prompt': prompt}),
          )
          .timeout(const Duration(seconds: 30));
      final data = await _handleResponse(response);
      final aiResponse = data.toString();
      developer.log('Event generation response: $aiResponse}',
          name: 'ApiService');
      return aiResponse;
    } catch (e, stackTrace) {
      developer.log('Event generation error: $e',
          name: 'ApiService', stackTrace: stackTrace);
      throw Exception('Failed to generate event: $e');
    }
  }
}
