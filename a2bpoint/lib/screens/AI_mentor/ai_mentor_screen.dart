import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../services/ai_service.dart';
import 'dart:developer' as developer;
import '../navbar.dart';

class AIMentorScreen extends StatefulWidget {
  const AIMentorScreen({super.key});

  @override
  AIMentorScreenState createState() => AIMentorScreenState();
}

class AIMentorScreenState extends State<AIMentorScreen> {
  final TextEditingController _controller = TextEditingController();
  final List<Map<String, dynamic>> _messages = [];
  final ScrollController _scrollController = ScrollController();
  bool _isLoading = false;
  String _requestType = 'goal'; // Default to goal

  void _sendMessage() async {
    final message = _controller.text.trim();
    if (message.isEmpty) return;

    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final userId = authProvider.userId;
    final aiService = AIService();

    setState(() {
      _messages.add({
        'text': message,
        'isUser': true,
        'timestamp': DateTime.now(),
      });
      _isLoading = true;
      _controller.clear();
    });

    // Scroll to bottom after adding user message
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _scrollToBottom();
    });

    try {
      String response;
      if (_requestType == 'goal') {
        response = await aiService.generateGoal(
            message, authProvider.token ?? '', userId!);
      } else {
        response = await aiService.generateEvent(
            message, authProvider.token ?? '', userId!);
      }

      setState(() {
        _messages.add({
          'text': response,
          'isUser': false,
          'timestamp': DateTime.now(),
        });
        _isLoading = false;
      });

      // Scroll to bottom after adding AI response
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _scrollToBottom();
      });
    } catch (e) {
      developer.log('Error sending AI request: $e', name: 'AIMentorScreen');
      setState(() {
        _messages.add({
          'text':
              'Sorry, an error occurred while processing your request. Please try again.',
          'isUser': false,
          'timestamp': DateTime.now(),
        });
        _isLoading = false;
      });

      // Scroll to bottom after adding error message
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _scrollToBottom();
      });
    }
  }

  void _scrollToBottom() {
    if (_scrollController.hasClients) {
      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('AI Mentor'),
        backgroundColor: const Color(0xFFF9F6F2),
        elevation: 0,
      ),
      backgroundColor: const Color(0xFFF9F6F2),
      body: Column(
        children: [
          // Choice chips for selecting request type
          Container(
            padding:
                const EdgeInsets.symmetric(vertical: 8.0, horizontal: 16.0),
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
                  backgroundColor: Colors.white,
                ),
                const SizedBox(width: 12),
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
                  backgroundColor: Colors.white,
                ),
              ],
            ),
          ),

          // Messages list
          Expanded(
            child: _messages.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.chat_bubble_outline,
                          size: 64,
                          color: Colors.grey[400],
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'Start conversation with AI Mentor',
                          style: TextStyle(
                            fontSize: 16,
                            color: Colors.grey[600],
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Select request type above and ask your question',
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey[500],
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  )
                : ListView.builder(
                    controller: _scrollController,
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16.0, vertical: 8.0),
                    itemCount: _messages.length,
                    itemBuilder: (context, index) {
                      final message = _messages[index];
                      final isUser = message['isUser'] as bool;

                      return Container(
                        margin: const EdgeInsets.only(bottom: 12.0),
                        child: Row(
                          mainAxisAlignment: isUser
                              ? MainAxisAlignment.end
                              : MainAxisAlignment.start,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            if (!isUser) ...[
                              CircleAvatar(
                                radius: 16,
                                backgroundColor: const Color(0xFFAFCBEA),
                                child: const Icon(
                                  Icons.smart_toy,
                                  size: 16,
                                  color: Colors.white,
                                ),
                              ),
                              const SizedBox(width: 8),
                            ],
                            Flexible(
                              child: Container(
                                constraints: BoxConstraints(
                                  maxWidth:
                                      MediaQuery.of(context).size.width * 0.75,
                                ),
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 16.0,
                                  vertical: 12.0,
                                ),
                                decoration: BoxDecoration(
                                  color: isUser
                                      ? const Color(0xFFAFCBEA)
                                      : Colors.white,
                                  borderRadius: BorderRadius.circular(18.0),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black.withOpacity(0.05),
                                      blurRadius: 5,
                                      offset: const Offset(0, 2),
                                    ),
                                  ],
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      message['text'] as String,
                                      style: TextStyle(
                                        color: isUser
                                            ? Colors.white
                                            : const Color(0xFF1A1A1A),
                                        fontSize: 15,
                                        height: 1.4,
                                      ),
                                    ),
                                    const SizedBox(height: 6),
                                    Text(
                                      _formatTimestamp(
                                          message['timestamp'] as DateTime),
                                      style: TextStyle(
                                        color: isUser
                                            ? Colors.white.withOpacity(0.8)
                                            : const Color(0xFF999999),
                                        fontSize: 11,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                            if (isUser) ...[
                              const SizedBox(width: 8),
                              CircleAvatar(
                                radius: 16,
                                backgroundColor: const Color(0xFF1A1A1A),
                                child: const Icon(
                                  Icons.person,
                                  size: 16,
                                  color: Colors.white,
                                ),
                              ),
                            ],
                          ],
                        ),
                      );
                    },
                  ),
          ),

          // Loading indicator
          if (_isLoading)
            Container(
              padding: const EdgeInsets.all(16.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.start,
                children: [
                  CircleAvatar(
                    radius: 16,
                    backgroundColor: const Color(0xFFAFCBEA),
                    child: const Icon(
                      Icons.smart_toy,
                      size: 16,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16.0,
                      vertical: 12.0,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(18.0),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.05),
                          blurRadius: 5,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation<Color>(
                              Colors.grey[600]!,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'AI is thinking...',
                          style: TextStyle(
                            color: Colors.grey[600],
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

          // Input field
          Container(
            padding: const EdgeInsets.all(16.0),
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 10,
                  offset: const Offset(0, -2),
                ),
              ],
            ),
            child: SafeArea(
              child: Row(
                children: [
                  Expanded(
                    child: Container(
                      decoration: BoxDecoration(
                        color: const Color(0xFFF5F5F5),
                        borderRadius: BorderRadius.circular(25),
                      ),
                      child: TextField(
                        controller: _controller,
                        maxLines: null,
                        textCapitalization: TextCapitalization.sentences,
                        decoration: const InputDecoration(
                          hintText: 'Enter your message...',
                          border: InputBorder.none,
                          contentPadding: EdgeInsets.symmetric(
                            horizontal: 20,
                            vertical: 12,
                          ),
                          hintStyle: TextStyle(
                            color: Color(0xFF999999),
                          ),
                        ),
                        onSubmitted: (_) => _sendMessage(),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  GestureDetector(
                    onTap: _sendMessage,
                    child: Container(
                      width: 44,
                      height: 44,
                      decoration: const BoxDecoration(
                        color: Color(0xFFAFCBEA),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.send_rounded,
                        color: Colors.white,
                        size: 20,
                      ),
                    ),
                  ),
                ],
              ),
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
    _scrollController.dispose();
    super.dispose();
  }
}
