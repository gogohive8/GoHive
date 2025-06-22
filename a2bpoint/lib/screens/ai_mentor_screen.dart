import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'dart:developer' as developer;
import '../providers/auth_provider.dart';
import '../services/api_services.dart';
import 'navbar.dart';

class AIMentorScreen extends StatefulWidget {
  const AIMentorScreen({super.key});

  @override
  _AIMentorScreenState createState() => _AIMentorScreenState();
}

class _AIMentorScreenState extends State<AIMentorScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final TextEditingController _messageController = TextEditingController();
  final List<Map<String, dynamic>> _messages = [];
  final ApiService _apiService = ApiService();

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _tabController.addListener(_handleTabChange);
  }

  @override
  void dispose() {
    _tabController.removeListener(_handleTabChange);
    _tabController.dispose();
    _messageController.dispose();
    _apiService.dispose();
    super.dispose();
  }

  void _handleTabChange() {
    if (!_tabController.indexIsChanging) {
      setState(() {});
    }
  }

  void _sendMessage() {
    if (_messageController.text.isNotEmpty) {
      final messageText = _messageController.text.trim();
      try {
        setState(() {
          _messages.add({
            'text': messageText,
            'isUser': true,
            'time': TimeOfDay.now().format(context),
          });

          // Проверка триггерного слова "preorder"
          if (messageText.toLowerCase() == 'preorder') {
            _handlePreOrder();
          } else {
            // Стандартный ответ бота
            _messages.add({
              'text':
                  'Эта функция сейчас находится в стадии разработки, и совсем скоро будет доступна для использования.\n\nУже сейчас вы можете оформить предзаказ полного доступа ко всем функциям ИИ-ассистента и получить скидку 75% на годовой пакет после релиза.',
              'isUser': false,
              'time': TimeOfDay.now().format(context),
              'hasPreOrderButton': true, // Флаг для кнопки
            });
          }
          _messageController.clear();
        });
      } catch (e, stackTrace) {
        developer.log('Error sending message: $e',
            name: 'AIMentorScreen', stackTrace: stackTrace);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error sending message: $e')),
        );
      }
    }
  }

  void _handlePreOrder() async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final userId = authProvider.userId ?? '';
    final token = authProvider.token ?? '';

    if (userId.isEmpty || token.isEmpty) {
      developer.log('No userId or token for pre-order', name: 'AIMentorScreen');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please sign in to place a pre-order')),
      );
      return;
    }

    try {
      developer.log('Placing pre-order for userId: $userId',
          name: 'AIMentorScreen');
      await _apiService.createPreOrder(userId, token);
      setState(() {
        _messages.add({
          'text':
              'Ваша заявка принята, служба поддержки свяжется с вами к дате релиза.',
          'isUser': false,
          'time': TimeOfDay.now().format(context),
        });
      });
    } catch (e, stackTrace) {
      developer.log('Error placing pre-order: $e',
          name: 'AIMentorScreen', stackTrace: stackTrace);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error placing pre-order: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);
    final size = MediaQuery.of(context).size;
    final padding = size.width * 0.05;

    if (!authProvider.isInitialized) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      backgroundColor: const Color(0xFFF9F6F2),
      appBar: AppBar(
        elevation: 0,
        backgroundColor: const Color(0xFFF9F6F2),
        automaticallyImplyLeading: false, // Убираем кнопку "назад"
        title: const Text(
          'AI Mentor',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: Color(0xFF1A1A1A),
          ),
        ),
        actions: [
          IconButton(
            icon: Image.asset('assets/images/ai_mentor.png', height: 24),
            onPressed: () {},
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'Goals'),
            Tab(text: 'Events'),
          ],
          indicatorColor: const Color(0xFFAFCBEA),
          labelColor: const Color(0xFFAFCBEA),
          unselectedLabelColor: const Color(0xFF333333),
        ),
      ),
      bottomNavigationBar: Navbar(
        selectedIndex: 4,
        onTap: (index) {
          final routes = ['/home', '/search', '/add', '/profile', '/ai-mentor'];
          Navigator.pushReplacementNamed(context, routes[index]);
        },
      ),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: TabBarView(
                controller: _tabController,
                children: [
                  Padding(
                    padding: EdgeInsets.all(padding),
                    child: ListView.builder(
                      itemCount: _messages.length,
                      itemBuilder: (context, index) {
                        final message = _messages[index];
                        return Align(
                          alignment: message['isUser']
                              ? Alignment.centerRight
                              : Alignment.centerLeft,
                          child: Container(
                            margin: const EdgeInsets.symmetric(vertical: 4),
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: message['isUser']
                                  ? const Color(0xFFAFCBEA).withOpacity(0.1)
                                  : const Color(0xFFDDDDDD),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  message['text'],
                                  style: const TextStyle(
                                    color: Color(0xFF1A1A1A),
                                  ),
                                ),
                                Text(
                                  message['time'],
                                  style: const TextStyle(
                                    fontSize: 12,
                                    color: Color(0xFF333333),
                                  ),
                                ),
                                if (message['hasPreOrderButton'] == true)
                                  Padding(
                                    padding: const EdgeInsets.only(top: 8),
                                    child: ElevatedButton(
                                      onPressed: _handlePreOrder,
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor:
                                            const Color(0xFFAFCBEA),
                                        foregroundColor:
                                            const Color(0xFF1A1A1A),
                                        shape: RoundedRectangleBorder(
                                          borderRadius:
                                              BorderRadius.circular(8),
                                        ),
                                      ),
                                      child: const Text('Pre-order'),
                                    ),
                                  ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                  const Center(child: Text('Events tab content')),
                ],
              ),
            ),
            Padding(
              padding: EdgeInsets.all(padding),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _messageController,
                      decoration: InputDecoration(
                        hintText: 'Message...',
                        hintStyle: const TextStyle(color: Color(0xFF333333)),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(20),
                          borderSide:
                              const BorderSide(color: Color(0xFFAFCBEA)),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(20),
                          borderSide:
                              const BorderSide(color: Color(0xFFAFCBEA)),
                        ),
                        contentPadding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 8),
                      ),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.send, color: Color(0xFFAFCBEA)),
                    onPressed: _sendMessage,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
