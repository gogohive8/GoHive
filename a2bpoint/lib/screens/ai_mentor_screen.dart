import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../services/api_services.dart';
import 'dart:developer' as developer;
import 'navbar.dart';

class AIMentorScreen extends StatefulWidget {
  const AIMentorScreen({super.key});

  @override
  AIMentorScreenState createState() => AIMentorScreenState();
}

class AIMentorScreenState extends State<AIMentorScreen> {
  final TextEditingController _controller = TextEditingController();
  final List<Map<String, dynamic>> _messages = [];
  bool _isLoading = false;
  String _requestType = 'goal'; // Default to goal

  void _sendMessage() async {
    final message = _controller.text.trim();
    if (message.isEmpty) return;

    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final apiService = ApiService();

    setState(() {
      _messages.add({
        'text': message,
        'isUser': true,
        'timestamp': DateTime.now(),
      });
      _isLoading = true;
      _controller.clear();
    });

    try {
      String response;
      if (_requestType == 'goal') {
        response =
            await apiService.generateGoal(message, authProvider.token ?? '');
      } else {
        response =
            await apiService.generateEvent(message, authProvider.token ?? '');
      }

      setState(() {
        _messages.add({
          'text': response,
          'isUser': false,
          'timestamp': DateTime.now(),
        });
        _isLoading = false;
      });
    } catch (e) {
      developer.log('Error sending AI request: $e', name: 'AIMentorScreen');
      setState(() {
        _messages.add({
          'text': 'Error: $e',
          'isUser': false,
          'timestamp': DateTime.now(),
        });
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('AI Mentor'),
        backgroundColor: const Color(0xFFF9F6F2),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                ChoiceChip(
                  label: const Text('Goal'),
                  selected: _requestType == 'goal',
                  onSelected: (selected) {
                    if (selected) {
                      setState(() {
                        _requestType = 'goal';
                      });
                    }
                  },
                  selectedColor: const Color(0xFFAFCBEA),
                ),
                const SizedBox(width: 8),
                ChoiceChip(
                  label: const Text('Event'),
                  selected: _requestType == 'event',
                  onSelected: (selected) {
                    if (selected) {
                      setState(() {
                        _requestType = 'event';
                      });
                    }
                  },
                  selectedColor: const Color(0xFFAFCBEA),
                ),
              ],
            ),
          ),
          Expanded(
            child: ListView.builder(
              reverse: true,
              padding: const EdgeInsets.all(8.0),
              itemCount: _messages.length,
              itemBuilder: (context, index) {
                final message = _messages[_messages.length - 1 - index];
                final isUser = message['isUser'] as bool;
                return Align(
                  alignment:
                      isUser ? Alignment.centerRight : Alignment.centerLeft,
                  child: Container(
                    margin: const EdgeInsets.symmetric(vertical: 4.0),
                    padding: const EdgeInsets.all(12.0),
                    decoration: BoxDecoration(
                      color: isUser
                          ? const Color(0xFFAFCBEA)
                          : const Color(0xFFE0E0E0),
                      borderRadius: BorderRadius.circular(12.0),
                    ),
                    child: Column(
                      crossAxisAlignment: isUser
                          ? CrossAxisAlignment.end
                          : CrossAxisAlignment.start,
                      children: [
                        Text(
                          message['text'] as String,
                          style: const TextStyle(color: Color(0xFF1A1A1A)),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          _formatTimestamp(message['timestamp'] as DateTime),
                          style: const TextStyle(
                            color: Color(0xFF666666),
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
          if (_isLoading)
            const Padding(
              padding: EdgeInsets.all(8.0),
              child: CircularProgressIndicator(),
            ),
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _controller,
                    decoration: InputDecoration(
                      hintText: 'Enter your message...',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    onSubmitted: (_) => _sendMessage(),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.send),
                  onPressed: _sendMessage,
                ),
              ],
            ),
          ),
        ],
      ),
      bottomNavigationBar: Navbar(
        selectedIndex: 4, // AI Mentor is the 5th item (index 4)
        onTap: (index) {
          final routes = ['/home', '/search', '/add', '/profile', '/ai-mentor'];
          Navigator.pushReplacementNamed(context, routes[index]);
        },
      ),
    );
  }

  String _formatTimestamp(DateTime timestamp) {
    return '${timestamp.hour}:${timestamp.minute.toString().padLeft(2, '0')}';
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }
}