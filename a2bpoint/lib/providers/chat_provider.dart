import 'package:flutter/foundation.dart';
import 'dart:io';
import '../models/chat.dart';
import '../models/message.dart';
import '../services/chat_service.dart';
import 'dart:developer' as developer;

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

  // Initialize
  Future<void> initialize() async {
    // Token is handled by AuthProvider, so just initialize ChatService
    _chatService.initialize();
  }

  // Load all chats
  Future<void> loadChats(String token) async {
    _setLoading(true);
    try {
      _chats = await _chatService.getChats(token);
      _error = null;
    } catch (e, stackTrace) {
      _error = e.toString();
      developer.log('Error loading chats: $e',
          name: 'ChatProvider', stackTrace: stackTrace);
    } finally {
      _setLoading(false);
    }
  }

  // Load messages for a chat
  Future<void> loadChatMessages(String chatId, String token) async {
    _setLoading(true);
    try {
      final messages = await _chatService.getChatMessages(chatId, token);
      _chatMessages[chatId] = messages;
      _currentChatId = chatId;
      _error = null;

      // Connect to chat for real-time messages
      _chatService.connectToChat(chatId);
    } catch (e, stackTrace) {
      _error = e.toString();
      developer.log('Error loading chat messages: $e',
          name: 'ChatProvider', stackTrace: stackTrace);
    } finally {
      _setLoading(false);
    }
  }

  // Send text message
  Future<void> sendTextMessage(String content, String token,
      {String? replyToId}) async {
    if (_currentChatId == null) {
      _error = 'No chat selected';
      developer.log('Error: No chat selected', name: 'ChatProvider');
      notifyListeners();
      return;
    }

    try {
      final message = await _chatService.sendTextMessage(
        _currentChatId!,
        content,
        token,
        replyToId: replyToId,
      );

      _addMessageToChat(_currentChatId!, message);
      _updateLastMessage(_currentChatId!, message);
    } catch (e, stackTrace) {
      _error = e.toString();
      developer.log('Error sending text message: $e',
          name: 'ChatProvider', stackTrace: stackTrace);
    }
  }

  // Send media message
  Future<void> sendMediaMessage(File file, MessageType type, String token,
      {String? caption}) async {
    if (_currentChatId == null) {
      _error = 'No chat selected';
      developer.log('Error: No chat selected', name: 'ChatProvider');
      notifyListeners();
      return;
    }

    try {
      final message = await _chatService.sendMediaMessage(
        _currentChatId!,
        file,
        type,
        token,
        caption: caption,
      );

      _addMessageToChat(_currentChatId!, message);
      _updateLastMessage(_currentChatId!, message);
    } catch (e, stackTrace) {
      _error = e.toString();
      developer.log('Error sending media message: $e',
          name: 'ChatProvider', stackTrace: stackTrace);
    }
  }

  // Send audio message
  Future<void> sendAudioMessage(
      File audioFile, int duration, String token) async {
    if (_currentChatId == null) {
      _error = 'No chat selected';
      developer.log('Error: No chat selected', name: 'ChatProvider');
      notifyListeners();
      return;
    }

    try {
      final message = await _chatService.sendAudioMessage(
          _currentChatId!, audioFile, duration, token);
      _addMessageToChat(_currentChatId!, message);
      _updateLastMessage(_currentChatId!, message);
    } catch (e, stackTrace) {
      _error = e.toString();
      developer.log('Error sending audio message: $e',
          name: 'ChatProvider', stackTrace: stackTrace);
    }
  }

  // Send file message
  Future<void> sendFileMessage(File file, String token) async {
    if (_currentChatId == null) {
      _error = 'No chat selected';
      developer.log('Error: No chat selected', name: 'ChatProvider');
      notifyListeners();
      return;
    }

    try {
      final message =
          await _chatService.sendFileMessage(_currentChatId!, file, token);
      _addMessageToChat(_currentChatId!, message);
      _updateLastMessage(_currentChatId!, message);
    } catch (e, stackTrace) {
      _error = e.toString();
      developer.log('Error sending file message: $e',
          name: 'ChatProvider', stackTrace: stackTrace);
    }
  }

  // Send location message
  Future<void> sendLocationMessage(
      double latitude, double longitude, String token,
      {String? address, String? name}) async {
    if (_currentChatId == null) {
      _error = 'No chat selected';
      developer.log('Error: No chat selected', name: 'ChatProvider');
      notifyListeners();
      return;
    }

    try {
      final message = await _chatService.sendLocationMessage(
        _currentChatId!,
        latitude,
        longitude,
        token,
        address: address,
        name: name,
      );
      _addMessageToChat(_currentChatId!, message);
      _updateLastMessage(_currentChatId!, message);
    } catch (e, stackTrace) {
      _error = e.toString();
      developer.log('Error sending location message: $e',
          name: 'ChatProvider', stackTrace: stackTrace);
    }
  }

  // Send contact message
  Future<void> sendContactMessage(String name, String token,
      {String? phoneNumber, String? email, String? avatar}) async {
    if (_currentChatId == null) {
      _error = 'No chat selected';
      developer.log('Error: No chat selected', name: 'ChatProvider');
      notifyListeners();
      return;
    }

    try {
      final message = await _chatService.sendContactMessage(
        _currentChatId!,
        name,
        token,
        phoneNumber: phoneNumber,
        email: email,
        avatar: avatar,
      );
      _addMessageToChat(_currentChatId!, message);
      _updateLastMessage(_currentChatId!, message);
    } catch (e, stackTrace) {
      _error = e.toString();
      developer.log('Error sending contact message: $e',
          name: 'ChatProvider', stackTrace: stackTrace);
    }
  }

  // Send GIF or sticker
  Future<void> sendGifMessage(
      String gifUrl, MessageType type, String token) async {
    if (_currentChatId == null) {
      _error = 'No chat selected';
      developer.log('Error: No chat selected', name: 'ChatProvider');
      notifyListeners();
      return;
    }

    try {
      final message = await _chatService.sendGifMessage(
          _currentChatId!, gifUrl, type, token);
      _addMessageToChat(_currentChatId!, message);
      _updateLastMessage(_currentChatId!, message);
    } catch (e, stackTrace) {
      _error = e.toString();
      developer.log('Error sending gif message: $e',
          name: 'ChatProvider', stackTrace: stackTrace);
    }
  }

  // Create a new chat
  Future<void> createChat(
      String name, List<String> participants, ChatType type, String token,
      {String? description, String? avatar}) async {
    _setLoading(true);
    try {
      final chat = await _chatService.createChat(
        name,
        participants,
        type,
        token,
        description: description,
        avatar: avatar,
      );
      _chats.insert(0, chat);
      _error = null;
    } catch (e, stackTrace) {
      _error = e.toString();
      developer.log('Error creating chat: $e',
          name: 'ChatProvider', stackTrace: stackTrace);
    } finally {
      _setLoading(false);
    }
  }

  // Join a chat
  Future<void> joinChat(String chatId, String token) async {
    try {
      await _chatService.joinChat(chatId, token);
      await loadChats(token); // Refresh chat list
    } catch (e, stackTrace) {
      _error = e.toString();
      developer.log('Error joining chat: $e',
          name: 'ChatProvider', stackTrace: stackTrace);
    }
  }

  // Leave a chat
  Future<void> leaveChat(String chatId, String token) async {
    try {
      await _chatService.leaveChat(chatId, token);
      _chats.removeWhere((chat) => chat.id == chatId);
      _chatMessages.remove(chatId);

      if (_currentChatId == chatId) {
        _currentChatId = null;
      }

      notifyListeners();
    } catch (e, stackTrace) {
      _error = e.toString();
      developer.log('Error leaving chat: $e',
          name: 'ChatProvider', stackTrace: stackTrace);
    }
  }

  // Mark messages as read
  Future<void> markMessagesAsRead(List<String> messageIds, String token) async {
    if (_currentChatId == null) {
      _error = 'No chat selected';
      developer.log('Error: No chat selected', name: 'ChatProvider');
      notifyListeners();
      return;
    }

    try {
      await _chatService.markMessagesAsRead(_currentChatId!, messageIds, token);

      // Update message status locally
      final messages = _chatMessages[_currentChatId!];
      if (messages != null) {
        for (int i = 0; i < messages.length; i++) {
          if (messageIds.contains(messages[i].id)) {
            _chatMessages[_currentChatId!]![i] =
                messages[i].copyWith(status: MessageStatus.read);
          }
        }
        notifyListeners();
      }
    } catch (e, stackTrace) {
      _error = e.toString();
      developer.log('Error marking messages as read: $e',
          name: 'ChatProvider', stackTrace: stackTrace);
    }
  }

  // Delete a message
  Future<void> deleteMessage(String messageId, String token) async {
    if (_currentChatId == null) {
      _error = 'No chat selected';
      developer.log('Error: No chat selected', name: 'ChatProvider');
      notifyListeners();
      return;
    }

    try {
      await _chatService.deleteMessage(_currentChatId!, messageId, token);
      _chatMessages[_currentChatId!]?.removeWhere((msg) => msg.id == messageId);
      notifyListeners();
    } catch (e, stackTrace) {
      _error = e.toString();
      developer.log('Error deleting message: $e',
          name: 'ChatProvider', stackTrace: stackTrace);
    }
  }

  // Edit a message
  Future<void> editMessage(
      String messageId, String newContent, String token) async {
    try {
      final editedMessage =
          await _chatService.editMessage(messageId, newContent, token);

      // Update message locally
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
    } catch (e, stackTrace) {
      _error = e.toString();
      developer.log('Error editing message: $e',
          name: 'ChatProvider', stackTrace: stackTrace);
    }
  }

  // Start a call
  Future<void> startCall(String callType, {bool isGroup = false}) async {
    if (_currentChatId == null) {
      _error = 'No chat selected';
      developer.log('Error: No chat selected', name: 'ChatProvider');
      notifyListeners();
      return;
    }

    try {
      await _chatService.startCall(_currentChatId!, callType, isGroup: isGroup);
    } catch (e, stackTrace) {
      _error = e.toString();
      developer.log('Error starting call: $e',
          name: 'ChatProvider', stackTrace: stackTrace);
    }
  }

  // Search chats
  List<Chat> searchChats(String query) {
    if (query.isEmpty) return _chats;

    return _chats.where((chat) {
      return chat.name.toLowerCase().contains(query.toLowerCase()) ||
          (chat.description?.toLowerCase().contains(query.toLowerCase()) ??
              false);
    }).toList();
  }

  // Search messages in current chat
  List<Message> searchMessages(String query) {
    if (_currentChatId == null || query.isEmpty) return [];

    final messages = _chatMessages[_currentChatId!] ?? [];
    return messages.where((message) {
      return message.content.toLowerCase().contains(query.toLowerCase());
    }).toList();
  }

  // Get unread chats
  List<Chat> getUnreadChats() {
    return _chats.where((chat) => chat.unreadCount > 0).toList();
  }

  // Get archived chats
  List<Chat> getArchivedChats() {
    return _chats.where((chat) => chat.isArchived).toList();
  }

  // Archive/unarchive a chat
  void toggleChatArchive(String chatId) {
    final chatIndex = _chats.indexWhere((chat) => chat.id == chatId);
    if (chatIndex != -1) {
      _chats[chatIndex] =
          _chats[chatIndex].copyWith(isArchived: !_chats[chatIndex].isArchived);
      notifyListeners();
    }
  }

  // Mute/unmute chat notifications
  void toggleChatMute(String chatId) {
    final chatIndex = _chats.indexWhere((chat) => chat.id == chatId);
    if (chatIndex != -1) {
      _chats[chatIndex] =
          _chats[chatIndex].copyWith(isMuted: !_chats[chatIndex].isMuted);
      notifyListeners();
    }
  }

  // Select a chat
  void selectChat(String chatId, String token) {
    _currentChatId = chatId;
    if (!_chatMessages.containsKey(chatId)) {
      loadChatMessages(chatId, token);
    }
    notifyListeners();
  }

  // Clear selected chat
  void clearCurrentChat() {
    if (_currentChatId != null) {
      _chatService.disconnectFromChat(_currentChatId!);
      _currentChatId = null;
      notifyListeners();
    }
  }

  // Private methods
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

  // Handle new messages (for WebSocket)
  void onNewMessage(Message message) {
    _addMessageToChat(message.chatId, message);
    _updateLastMessage(message.chatId, message);

    // Increment unread count if chat is not active
    if (_currentChatId != message.chatId) {
      final chatIndex = _chats.indexWhere((chat) => chat.id == message.chatId);
      if (chatIndex != -1) {
        _chats[chatIndex] = _chats[chatIndex]
            .copyWith(unreadCount: _chats[chatIndex].unreadCount + 1);
      }
    }

    notifyListeners();
  }

  // Cleanup on provider disposal
  @override
  void dispose() {
    if (_currentChatId != null) {
      _chatService.disconnectFromChat(_currentChatId!);
    }
    super.dispose();
  }
}
