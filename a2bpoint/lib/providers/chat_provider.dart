// lib/providers/chat_provider.dart
import 'package:flutter/foundation.dart';
import 'dart:io';
import '../models/chat.dart';
import '../models/message.dart';
import '../services/chat_service.dart';

class ChatProvider extends ChangeNotifier {
  final ChatService _chatService = ChatService();
  
  List<Chat> _chats = [];
  Map<String, List<Message>> _chatMessages = {};
  bool _isLoading = false;
  String? _error;
  String? _currentChatId;
  
  // Getters
  List<Chat> get chats => _chats;
  Map<String, List<Message>> get chatMessages => _chatMessages;
  bool get isLoading => _isLoading;
  String? get error => _error;
  String? get currentChatId => _currentChatId;
  
  List<Message> getCurrentChatMessages() {
    if (_currentChatId == null) return [];
    return _chatMessages[_currentChatId!] ?? [];
  }
  
  Chat? getCurrentChat() {
    if (_currentChatId == null) return null;
    return _chats.firstWhere(
      (chat) => chat.id == _currentChatId,
      orElse: () => _chats.first,
    );
  }

  // Инициализация
  Future<void> initialize() async {
    await loadChats();
  }

  // Загрузить все чаты
  Future<void> loadChats() async {
    _setLoading(true);
    try {
      _chats = await _chatService.getChats();
      _error = null;
    } catch (e) {
      _error = e.toString();
      debugPrint('Error loading chats: $e');
    } finally {
      _setLoading(false);
    }
  }

  // Загрузить сообщения для чата
  Future<void> loadChatMessages(String chatId) async {
    _setLoading(true);
    try {
      final messages = await _chatService.getChatMessages(chatId);
      _chatMessages[chatId] = messages;
      _currentChatId = chatId;
      _error = null;
      
      // Подключиться к чату для получения сообщений в реальном времени
      _chatService.connectToChat(chatId);
    } catch (e) {
      _error = e.toString();
      debugPrint('Error loading chat messages: $e');
    } finally {
      _setLoading(false);
    }
  }

  // Отправить текстовое сообщение
  Future<void> sendTextMessage(String content, {String? replyToId}) async {
    if (_currentChatId == null) return;
    
    try {
      final message = await _chatService.sendTextMessage(
        _currentChatId!, 
        content, 
        replyToId: replyToId,
      );
      
      _addMessageToChat(_currentChatId!, message);
      _updateLastMessage(_currentChatId!, message);
    } catch (e) {
      _error = e.toString();
      debugPrint('Error sending text message: $e');
    }
  }

  // Отправить медиа-сообщение
  Future<void> sendMediaMessage(File file, MessageType type, {String? caption}) async {
    if (_currentChatId == null) return;
    
    try {
      final message = await _chatService.sendMediaMessage(
        _currentChatId!, 
        file, 
        type, 
        caption: caption,
      );
      
      _addMessageToChat(_currentChatId!, message);
      _updateLastMessage(_currentChatId!, message);
    } catch (e) {
      _error = e.toString();
      debugPrint('Error sending media message: $e');
    }
  }

  // Отправить аудио-сообщение
  Future<void> sendAudioMessage(File audioFile, int duration) async {
    if (_currentChatId == null) return;
    
    try {
      final message = await _chatService.sendAudioMessage(_currentChatId!, audioFile, duration);
      _addMessageToChat(_currentChatId!, message);
      _updateLastMessage(_currentChatId!, message);
    } catch (e) {
      _error = e.toString();
      debugPrint('Error sending audio message: $e');
    }
  }

  // Отправить файл
  Future<void> sendFileMessage(File file) async {
    if (_currentChatId == null) return;
    
    try {
      final message = await _chatService.sendFileMessage(_currentChatId!, file);
      _addMessageToChat(_currentChatId!, message);
      _updateLastMessage(_currentChatId!, message);
    } catch (e) {
      _error = e.toString();
      debugPrint('Error sending file message: $e');
    }
  }

  // Отправить локацию
  Future<void> sendLocationMessage(
    double latitude, 
    double longitude, 
    {String? address, String? name}
  ) async {
    if (_currentChatId == null) return;
    
    try {
      final message = await _chatService.sendLocationMessage(
        _currentChatId!, 
        latitude, 
        longitude,
        address: address,
        name: name,
      );
      _addMessageToChat(_currentChatId!, message);
      _updateLastMessage(_currentChatId!, message);
    } catch (e) {
      _error = e.toString();
      debugPrint('Error sending location message: $e');
    }
  }

  // Отправить контакт
  Future<void> sendContactMessage(
    String name, 
    {String? phoneNumber, String? email, String? avatar}
  ) async {
    if (_currentChatId == null) return;
    
    try {
      final message = await _chatService.sendContactMessage(
        _currentChatId!, 
        name,
        phoneNumber: phoneNumber,
        email: email,
        avatar: avatar,
      );
      _addMessageToChat(_currentChatId!, message);
      _updateLastMessage(_currentChatId!, message);
    } catch (e) {
      _error = e.toString();
      debugPrint('Error sending contact message: $e');
    }
  }

  // Отправить GIF или стикер
  Future<void> sendGifMessage(String gifUrl, MessageType type) async {
    if (_currentChatId == null) return;
    
    try {
      final message = await _chatService.sendGifMessage(_currentChatId!, gifUrl, type);
      _addMessageToChat(_currentChatId!, message);
      _updateLastMessage(_currentChatId!, message);
    } catch (e) {
      _error = e.toString();
      debugPrint('Error sending gif message: $e');
    }
  }

  // Создать новый чат
  Future<void> createChat(
    String name, 
    List<String> participants, 
    ChatType type, 
    {String? description, String? avatar}
  ) async {
    _setLoading(true);
    try {
      final chat = await _chatService.createChat(
        name, 
        participants, 
        type,
        description: description,
        avatar: avatar,
      );
      _chats.insert(0, chat);
      _error = null;
    } catch (e) {
      _error = e.toString();
      debugPrint('Error creating chat: $e');
    } finally {
      _setLoading(false);
    }
  }

  // Присоединиться к чату
  Future<void> joinChat(String chatId) async {
    try {
      await _chatService.joinChat(chatId);
      await loadChats(); // Обновить список чатов
    } catch (e) {
      _error = e.toString();
      debugPrint('Error joining chat: $e');
    }
  }

  // Покинуть чат
  Future<void> leaveChat(String chatId) async {
    try {
      await _chatService.leaveChat(chatId);
      _chats.removeWhere((chat) => chat.id == chatId);
      _chatMessages.remove(chatId);
      
      if (_currentChatId == chatId) {
        _currentChatId = null;
      }
      
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      debugPrint('Error leaving chat: $e');
    }
  }

  // Пометить сообщения как прочитанные
  Future<void> markMessagesAsRead(List<String> messageIds) async {
    if (_currentChatId == null) return;
    
    try {
      await _chatService.markMessagesAsRead(_currentChatId!, messageIds);
      
      // Обновить статус сообщений локально
      final messages = _chatMessages[_currentChatId!];
      if (messages != null) {
        for (int i = 0; i < messages.length; i++) {
          if (messageIds.contains(messages[i].id)) {
            _chatMessages[_currentChatId!]![i] = messages[i].copyWith(
              status: MessageStatus.read
            );
          }
        }
        notifyListeners();
      }
    } catch (e) {
      _error = e.toString();
      debugPrint('Error marking messages as read: $e');
    }
  }

  // Удалить сообщение
  Future<void> deleteMessage(String messageId) async {
    if (_currentChatId == null) return;
    
    try {
      await _chatService.deleteMessage(_currentChatId!, messageId);
      _chatMessages[_currentChatId!]?.removeWhere((msg) => msg.id == messageId);
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      debugPrint('Error deleting message: $e');
    }
  }

  // Редактировать сообщение
  Future<void> editMessage(String messageId, String newContent) async {
    try {
      final editedMessage = await _chatService.editMessage(messageId, newContent);
      
      // Обновить сообщение локально
      if (_currentChatId != null) {
        final messages = _chatMessages[_currentChatId!];
        if (messages != null) {
          for (int i = 0; i < messages.length; i++) {
            if (messages[i].id == messageId) {
              _chatMessages[_currentChatId!]![i] = editedMessage;
              break;
            }
          }
          notifyListeners();
        }
      }
    } catch (e) {
      _error = e.toString();
      debugPrint('Error editing message: $e');
    }
  }

  // Начать звонок
  Future<void> startCall(String callType, {bool isGroup = false}) async {
    if (_currentChatId == null) return;
    
    try {
      await _chatService.startCall(_currentChatId!, callType, isGroup: isGroup);
    } catch (e) {
      _error = e.toString();
      debugPrint('Error starting call: $e');
    }
  }

  // Поиск чатов
  List<Chat> searchChats(String query) {
    if (query.isEmpty) return _chats;
    
    return _chats.where((chat) {
      return chat.name.toLowerCase().contains(query.toLowerCase()) ||
             (chat.description?.toLowerCase().contains(query.toLowerCase()) ?? false);
    }).toList();
  }

  // Поиск сообщений в текущем чате
  List<Message> searchMessages(String query) {
    if (_currentChatId == null || query.isEmpty) return [];
    
    final messages = _chatMessages[_currentChatId!] ?? [];
    return messages.where((message) {
      return message.content.toLowerCase().contains(query.toLowerCase());
    }).toList();
  }

  // Получить непрочитанные чаты
  List<Chat> getUnreadChats() {
    return _chats.where((chat) => chat.unreadCount > 0).toList();
  }

  // Получить архивированные чаты
  List<Chat> getArchivedChats() {
    return _chats.where((chat) => chat.isArchived).toList();
  }

  // Архивировать/разархивировать чат
  void toggleChatArchive(String chatId) {
    final chatIndex = _chats.indexWhere((chat) => chat.id == chatId);
    if (chatIndex != -1) {
      _chats[chatIndex] = _chats[chatIndex].copyWith(
        isArchived: !_chats[chatIndex].isArchived
      );
      notifyListeners();
    }
  }

  // Заглушить/включить уведомления для чата
  void toggleChatMute(String chatId) {
    final chatIndex = _chats.indexWhere((chat) => chat.id == chatId);
    if (chatIndex != -1) {
      _chats[chatIndex] = _chats[chatIndex].copyWith(
        isMuted: !_chats[chatIndex].isMuted
      );
      notifyListeners();
    }
  }

  // Выбрать чат
  void selectChat(String chatId) {
    _currentChatId = chatId;
    if (!_chatMessages.containsKey(chatId)) {
      loadChatMessages(chatId);
    }
    notifyListeners();
  }

  // Очистить выбранный чат
  void clearCurrentChat() {
    if (_currentChatId != null) {
      _chatService.disconnectFromChat(_currentChatId!);
      _currentChatId = null;
      notifyListeners();
    }
  }

  // Приватные методы
  void _setLoading(bool loading) {
    _isLoading = loading;
    notifyListeners();
  }

  void _addMessageToChat(String chatId, Message message) {
    _chatMessages[chatId] = _chatMessages[chatId] ?? [];
    _chatMessages[chatId]!.add(message);
    notifyListeners();
  }

  void _updateLastMessage(String chatId, Message message) {
    final chatIndex = _chats.indexWhere((chat) => chat.id == chatId);
    if (chatIndex != -1) {
      _chats[chatIndex] = _chats[chatIndex].copyWith(
        lastMessageId: message.id,
        lastMessage: _getMessagePreview(message),
        lastMessageTime: message.timestamp,
        updatedAt: DateTime.now(),
      );
      notifyListeners();
    }
  }

  String _getMessagePreview(Message message) {
    switch (message.type) {
      case MessageType.text:
        return message.content;
      case MessageType.image:
        return '📷 Фото';
      case MessageType.video:
        return '🎥 Видео';
      case MessageType.audio:
        return '🎵 Аудио';
      case MessageType.file:
        return '📁 Файл';
      case MessageType.location:
        return '📍 Локация';
      case MessageType.gif:
        return '🎭 GIF';
      case MessageType.sticker:
        return '😀 Стикер';
      case MessageType.contact:
        return '👤 Контакт';
      case MessageType.call:
        return '📞 Звонок';
      case MessageType.system:
        return message.content;
      }
  }

  // Метод для получения новых сообщений (для WebSocket)
  void onNewMessage(Message message) {
    _addMessageToChat(message.chatId, message);
    _updateLastMessage(message.chatId, message);
    
    // Увеличить счетчик непрочитанных, если чат не активен
    if (_currentChatId != message.chatId) {
      final chatIndex = _chats.indexWhere((chat) => chat.id == message.chatId);
      if (chatIndex != -1) {
        _chats[chatIndex] = _chats[chatIndex].copyWith(
          unreadCount: _chats[chatIndex].unreadCount + 1
        );
      }
    }
    
    notifyListeners();
  }

  // Очистка при уничтожении провайдера
  @override
  void dispose() {
    if (_currentChatId != null) {
      _chatService.disconnectFromChat(_currentChatId!);
    }
    super.dispose();
  }
}