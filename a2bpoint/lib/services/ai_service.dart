import 'dart:convert';
import 'dart:developer' as developer;
import 'package:http/http.dart' as http;
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'exceptions.dart';

class AIService {
  final http.Client _client = http.Client();
  final SupabaseClient _supabase = Supabase.instance.client;
  static const String _aiUrl =
      'https://gohive-ai-service-38f2e813d406.herokuapp.com';

  SupabaseClient get supabase => _supabase;

  // Save chat history to local storage
  Future<void> _saveChatHistory(
      String userId, List<Map<String, String>> history) async {
    final prefs = await SharedPreferences.getInstance();
    final key = 'chat_history_$userId';
    final jsonString = jsonEncode(history);
    await prefs.setString(key, jsonString);
    developer.log('Saved chat history for user $userId', name: 'AIService');
  }

  // Load chat history from local storage
  Future<List<Map<String, String>>> _loadChatHistory(String userId) async {
    final prefs = await SharedPreferences.getInstance();
    final key = 'chat_history_$userId';
    final jsonString = prefs.getString(key);
    if (jsonString == null) return [];
    try {
      final List<dynamic> decoded = jsonDecode(jsonString);
      return decoded.cast<Map<String, String>>();
    } catch (e) {
      developer.log('Error loading chat history: $e', name: 'AIService');
      return [];
    }
  }

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

    if (data is String) {
      String cleaned = data.trim();
      cleaned = _removeWrappers(cleaned);
      return cleaned.isNotEmpty ? cleaned : 'Empty response received';
    }

    if (data is Map<String, dynamic>) {
      final possibleKeys = [
        'message',
        'response',
        'text',
        'content',
        'answer',
        'result',
        'data',
        'output',
        'reply',
        'body',
        'value',
        'payload'
      ];

      for (String key in possibleKeys) {
        if (data.containsKey(key) && data[key] != null) {
          return _extractCleanText(data[key]);
        }
      }

      for (var value in data.values) {
        if (value is String && value.trim().isNotEmpty) {
          return _removeWrappers(value.trim());
        }
      }

      return _removeWrappers(data.toString());
    }

    if (data is List && data.isNotEmpty) {
      return _extractCleanText(data.first);
    }

    return _removeWrappers(data.toString());
  }

  /// Remove various wrapper patterns from text
  String _removeWrappers(String text) {
    String cleaned = text.trim();

    if (cleaned.startsWith('{') && cleaned.endsWith('}')) {
      try {
        final parsed = jsonDecode(cleaned);
        if (parsed is Map<String, dynamic>) {
          return _extractCleanText(parsed);
        }
      } catch (e) {
        cleaned = cleaned.substring(1, cleaned.length - 1).trim();
      }
    }

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

    if ((cleaned.startsWith('"') && cleaned.endsWith('"')) ||
        (cleaned.startsWith("'") && cleaned.endsWith("'"))) {
      cleaned = cleaned.substring(1, cleaned.length - 1);
    }

    cleaned = cleaned
        .replaceAll(r'\"', '"')
        .replaceAll(r"\'", "'")
        .replaceAll(r'\\', '\\');

    return cleaned.trim();
  }

  Future<String> generateGoal(
      String prompt, String token, String userId) async {
    try {
      developer.log('Sending goal generation request: prompt: $prompt',
          name: 'ApiService');
      // Load existing chat history
      List<Map<String, String>> chatHistory = await _loadChatHistory(userId);

      // Append user prompt to chat history
      chatHistory.add({'role': 'user', 'content': prompt});

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

      // Append AI response to chat history
      chatHistory.add({'role': 'assistant', 'content': aiResponse});

      // Save updated chat history
      await _saveChatHistory(userId, chatHistory);

      developer.log('Goal generation response: $aiResponse',
          name: 'ApiService');
      return aiResponse;
    } catch (e, stackTrace) {
      developer.log('Goal generation error: $e',
          name: 'ApiService', stackTrace: stackTrace);
      throw Exception('Failed to generate goal: $e');
    }
  }

  Future<String> generateEvent(
      String prompt, String token, String userId) async {
    try {
      developer.log('Sending event generation request: prompt: $prompt',
          name: 'ApiService');
      // Load existing chat history
      List<Map<String, String>> chatHistory = await _loadChatHistory(userId);

      // Append user prompt to chat history
      chatHistory.add({'role': 'user', 'content': prompt});

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

      // Append AI response to chat history
      chatHistory.add({'role': 'assistant', 'content': aiResponse});

      // Save updated chat history
      await _saveChatHistory(userId, chatHistory);

      developer.log('Event generation response: $aiResponse',
          name: 'ApiService');
      return aiResponse;
    } catch (e, stackTrace) {
      developer.log('Event generation error: $e',
          name: 'ApiService', stackTrace: stackTrace);
      throw Exception('Failed to generate event: $e');
    }
  }
}
