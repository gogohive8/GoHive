import 'package:flutter/material.dart';
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
    super.dispose();
  }

  void _handleTabChange() {
    if (!_tabController.indexIsChanging) {
      setState(() {});
    }
  }

  void _sendMessage() {
    if (_messageController.text.isNotEmpty) {
      try {
        setState(() {
          _messages.add({
            'text': _messageController.text,
            'isUser': true,
            'time': TimeOfDay.now().format(context),
          });
          _messages.add({
            'text':
                'Эта функция сейчас находится в стадии разработки, и совсем скоро будет доступна для использования.\n\nУже сейчас вы можете оформить предзаказ полного доступа ко всем функциям ИИ-ассистента и получить скидку 75% на годовой пакет после релиза.\n\nДля оформления предзаказа свяжитесь с нами по номеру:\n📞 +90 (535) 082 02 16',
            'isUser': false,
            'time': TimeOfDay.now().format(context),
          });
          _messageController.clear();
        });
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error sending message: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final padding = size.width * 0.05;

    return Scaffold(
      backgroundColor: const Color(0xFFF9F6F2), // Светло-бежевый фон
      appBar: AppBar(
        leading: IconButton(
          icon:
              const Icon(Icons.arrow_back, color: Color(0xFFAFCBEA)), // Голубой
          onPressed: () => Navigator.pop(context),
        ),
        elevation: 0,
        backgroundColor: const Color(0xFFF9F6F2),
        title: const Text(
          'AI Mentor',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: Color(0xFF1A1A1A), // Тёмно-серый
          ),
        ),
        actions: [
          IconButton(
            icon: Image.asset('assets/images/ai_mentor.png', height: 24),
            onPressed: () {}, // Заглушка для действия
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'Goals'),
            Tab(text: 'Events'),
          ],
          indicatorColor: const Color(0xFFAFCBEA), // Голубой
          labelColor: const Color(0xFFAFCBEA),
          unselectedLabelColor: const Color(0xFF333333), // Серый
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
                  // Goals tab
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
                                  ? const Color(0xFFAFCBEA).withOpacity(
                                      0.1) // Голубой с прозрачностью
                                  : const Color(0xFFDDDDDD), // Светло-серый
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  message['text'],
                                  style: TextStyle(
                                    color: message['isUser']
                                        ? const Color(0xFF1A1A1A) // Тёмно-серый
                                        : const Color(0xFF1A1A1A),
                                  ),
                                ),
                                Text(
                                  message['time'],
                                  style: const TextStyle(
                                    fontSize: 12,
                                    color: Color(0xFF333333), // Серый
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                  // Events tab
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
                        hintStyle:
                            const TextStyle(color: Color(0xFF333333)), // Серый
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(20),
                          borderSide: const BorderSide(
                              color: Color(0xFFAFCBEA)), // Голубой
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
                    icon: const Icon(Icons.send,
                        color: Color(0xFFAFCBEA)), // Голубой
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
