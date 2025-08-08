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

  /// Extract clean text from any API response format
  String _extractCleanText(dynamic data) {
    if (data == null) return 'No response received';
    
    // If it's already a clean string, return it
    if (data is String) {
      String cleaned = data.trim();
      
      // Remove common wrapper patterns
      cleaned = _removeWrappers(cleaned);
      
      return cleaned.isNotEmpty ? cleaned : 'Empty response received';
    }
    
    // If it's a Map, try to extract the actual message
    if (data is Map<String, dynamic>) {
      // Try common response field names
      final possibleKeys = [
        'message', 'response', 'text', 'content', 'answer', 'result',
        'data', 'output', 'reply', 'body', 'value', 'payload'
      ];
      
      for (String key in possibleKeys) {
        if (data.containsKey(key) && data[key] != null) {
          return _extractCleanText(data[key]);
        }
      }
      
      // If no standard keys found, try to find any string value
      for (var value in data.values) {
        if (value is String && value.trim().isNotEmpty) {
          return _removeWrappers(value.trim());
        }
      }
      
      // If still nothing found, convert the whole map but clean it
      return _removeWrappers(data.toString());
    }
    
    // If it's a List, try to extract from first element
    if (data is List && data.isNotEmpty) {
      return _extractCleanText(data.first);
    }
    
    // Fallback: convert to string and clean
    return _removeWrappers(data.toString());
  }
  
  /// Remove various wrapper patterns from text
  String _removeWrappers(String text) {
    String cleaned = text.trim();
    
    // Remove JSON-like wrappers
    if (cleaned.startsWith('{') && cleaned.endsWith('}')) {
      // Try to parse as JSON first
      try {
        final parsed = jsonDecode(cleaned);
        if (parsed is Map<String, dynamic>) {
          return _extractCleanText(parsed);
        }
      } catch (e) {
        // If JSON parsing fails, manually remove braces
        cleaned = cleaned.substring(1, cleaned.length - 1).trim();
      }
    }
    
    // Remove array wrappers
    if (cleaned.startsWith('[') && cleaned.endsWith(']')) {
      try {
        final parsed = jsonDecode(cleaned);
        if (parsed is List && parsed.isNotEmpty) {
          return _extractCleanText(parsed.first);
        }
      } catch (e) {
        cleaned = cleaned.substring(1, cleaned.length - 1).trim();
      }
    }
    
    // Remove common prefixes like "message:", "response:", etc.
    final prefixPatterns = [
      RegExp(r'^message\s*:\s*', caseSensitive: false),
      RegExp(r'^response\s*:\s*', caseSensitive: false),
      RegExp(r'^text\s*:\s*', caseSensitive: false),
      RegExp(r'^content\s*:\s*', caseSensitive: false),
      RegExp(r'^answer\s*:\s*', caseSensitive: false),
      RegExp(r'^result\s*:\s*', caseSensitive: false),
      RegExp(r'^data\s*:\s*', caseSensitive: false),
      RegExp(r'^output\s*:\s*', caseSensitive: false),
    ];
    
    for (RegExp pattern in prefixPatterns) {
      cleaned = cleaned.replaceFirst(pattern, '');
    }
    
    // Remove quotes if the entire string is wrapped in quotes
    if ((cleaned.startsWith('"') && cleaned.endsWith('"')) ||
        (cleaned.startsWith("'") && cleaned.endsWith("'"))) {
      cleaned = cleaned.substring(1, cleaned.length - 1);
    }
    
    // Remove escape characters
    cleaned = cleaned.replaceAll(r'\"', '"')
                    .replaceAll(r"\'", "'")
                    .replaceAll(r'\\', '\\');
    
    return cleaned.trim();
  }

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
            body: jsonEncode({'message': prompt}),
          )
          .timeout(const Duration(seconds: 30));
      
      final data = await _handleResponse(response);
      final aiResponse = _extractCleanText(data);
      
      developer.log('Goal generation response: $aiResponse', name: 'ApiService');
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
            body: jsonEncode({'message': prompt}),
          )
          .timeout(const Duration(seconds: 30));
      
      final data = await _handleResponse(response);
      final aiResponse = _extractCleanText(data);
      
      developer.log('Event generation response: $aiResponse', name: 'ApiService');
      return aiResponse;
    } catch (e, stackTrace) {
      developer.log('Event generation error: $e',
          name: 'ApiService', stackTrace: stackTrace);
      throw Exception('Failed to generate event: $e');
    }
  }
}