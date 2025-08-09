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
    try {
      return _chats.firstWhere(
        (chat) => chat.id == _currentChatId,
        orElse: () => _chats.isNotEmpty ? _chats.first : throw StateError('No chats available'),
      );
    } catch (e) {
      developer.log('Error getting current chat: $e', name: 'ChatProvider');
      return null;
    }
  }

  // Initialize
  Future<void> initialize() async {
    try {
      _chatService.initialize();
    } catch (e) {
      developer.log('Error initializing ChatProvider: $e', name: 'ChatProvider');
    }
  }

  // Load all chats with retry logic
  Future<void> loadChats(String token, {int retryCount = 0}) async {
    const maxRetries = 2;
    
    _setLoading(true);
    try {
      _chats = await _chatService.getChats(token);
      _error = null;
      developer.log('Successfully loaded ${_chats.length} chats', name: 'ChatProvider');
    } catch (e, stackTrace) {
      _error = 'Error loading chats: ${_getErrorMessage(e)}';
      developer.log('Error loading chats (attempt ${retryCount + 1}): $e',
          name: 'ChatProvider', stackTrace: stackTrace);
      
      // Retry logic for server errors
      if (retryCount < maxRetries && _isRetryableError(e)) {
        developer.log('Retrying loadChats in 2 seconds...', name: 'ChatProvider');
        await Future.delayed(Duration(seconds: 2));
        return loadChats(token, retryCount: retryCount + 1);
      }
    } finally {
      _setLoading(false);
    }
  }

  // Load messages for a chat
  Future<void> loadChatMessages(String chatId, String token) async {
    if (chatId.isEmpty) {
      _error = 'Invalid chat ID';
      notifyListeners();
      return;
    }

    _setLoading(true);
    try {
      final messages = await _chatService.getChatMessages(chatId, token);
      _chatMessages[chatId] = messages;
      _currentChatId = chatId;
      _error = null;

      // Connect to chat for real-time messages
      _chatService.connectToChat(chatId);
      developer.log('Loaded ${messages.length} messages for chat $chatId', name: 'ChatProvider');
    } catch (e, stackTrace) {
      _error = 'Error loading chat messages: ${_getErrorMessage(e)}';
      developer.log('Error loading chat messages: $e',
          name: 'ChatProvider', stackTrace: stackTrace);
    } finally {
      _setLoading(false);
    }
  }

  // Create a new chat with improved error handling
  Future<void> createChat(
      String name, 
      List<String> participants, 
      ChatType type, 
      String token,
      {String? description, String? avatar}) async {
    
    // Validate inputs
    if (name.trim().isEmpty) {
      throw ArgumentError('Chat name cannot be empty');
    }
    if (participants.isEmpty) {
      throw ArgumentError('At least one participant is required');
    }
    if (token.isEmpty) {
      throw ArgumentError('Authentication token is required');
    }

    _setLoading(true);
    try {
      // Ensure description is not null
      final safeDescription = description ?? '';
      
      developer.log(
        'Creating chat: name="$name", participants=${participants.length}, type=$type', 
        name: 'ChatProvider'
      );

      final chat = await _chatService.createChat(
        name.trim(),
        participants,
        type,
        token,
        description: safeDescription,
        avatar: avatar,
      );
      
      // Add to the beginning of the chat list
      _chats.insert(0, chat);
      _error = null;
      
      developer.log('Chat created successfully: ${chat.id}', name: 'ChatProvider');
    } catch (e, stackTrace) {
      _error = 'Error creating chat: ${_getErrorMessage(e)}';
      developer.log('Error creating chat: $e',
          name: 'ChatProvider', stackTrace: stackTrace);
      rethrow; // Re-throw to allow UI to handle
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

    if (content.trim().isEmpty) {
      _error = 'Message content cannot be empty';
      notifyListeners();
      return;
    }

    try {
      final message = await _chatService.sendTextMessage(
        _currentChatId!,
        content.trim(),
        token,
        replyToId: replyToId,
      );

      _addMessageToChat(_currentChatId!, message);
      _updateLastMessage(_currentChatId!, message);
    } catch (e, stackTrace) {
      _error = 'Error sending message: ${_getErrorMessage(e)}';
      developer.log('Error sending text message: $e',
          name: 'ChatProvider', stackTrace: stackTrace);
      notifyListeners();
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

    if (!file.existsSync()) {
      _error = 'File does not exist';
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
      _error = 'Error sending media: ${_getErrorMessage(e)}';
      developer.log('Error sending media message: $e',
          name: 'ChatProvider', stackTrace: stackTrace);
      notifyListeners();
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
      _error = 'Error sending audio: ${_getErrorMessage(e)}';
      developer.log('Error sending audio message: $e',
          name: 'ChatProvider', stackTrace: stackTrace);
      notifyListeners();
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
      _error = 'Error sending file: ${_getErrorMessage(e)}';
      developer.log('Error sending file message: $e',
          name: 'ChatProvider', stackTrace: stackTrace);
      notifyListeners();
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
      _error = 'Error sending location: ${_getErrorMessage(e)}';
      developer.log('Error sending location message: $e',
          name: 'ChatProvider', stackTrace: stackTrace);
      notifyListeners();
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
      _error = 'Error sending contact: ${_getErrorMessage(e)}';
      developer.log('Error sending contact message: $e',
          name: 'ChatProvider', stackTrace: stackTrace);
      notifyListeners();
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
      _error = 'Error sending GIF: ${_getErrorMessage(e)}';
      developer.log('Error sending gif message: $e',
          name: 'ChatProvider', stackTrace: stackTrace);
      notifyListeners();
    }
  }

  // Join a chat
  Future<void> joinChat(String chatId, String token) async {
    try {
      await _chatService.joinChat(chatId, token);
      await loadChats(token); // Refresh chat list
    } catch (e, stackTrace) {
      _error = 'Error joining chat: ${_getErrorMessage(e)}';
      developer.log('Error joining chat: $e',
          name: 'ChatProvider', stackTrace: stackTrace);
      notifyListeners();
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
      _error = 'Error leaving chat: ${_getErrorMessage(e)}';
      developer.log('Error leaving chat: $e',
          name: 'ChatProvider', stackTrace: stackTrace);
      notifyListeners();
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
      _error = 'Error marking messages as read: ${_getErrorMessage(e)}';
      developer.log('Error marking messages as read: $e',
          name: 'ChatProvider', stackTrace: stackTrace);
      notifyListeners();
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
      _error = 'Error deleting message: ${_getErrorMessage(e)}';
      developer.log('Error deleting message: $e',
          name: 'ChatProvider', stackTrace: stackTrace);
      notifyListeners();
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
      _error = 'Error editing message: ${_getErrorMessage(e)}';
      developer.log('Error editing message: $e',
          name: 'ChatProvider', stackTrace: stackTrace);
      notifyListeners();
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
      _error = 'Error starting call: ${_getErrorMessage(e)}';
      developer.log('Error starting call: $e',
          name: 'ChatProvider', stackTrace: stackTrace);
      notifyListeners();
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

  // Select a chat with validation
  void selectChat(String chatId, String token) {
    if (chatId.isEmpty) {
      _error = 'Invalid chat ID';
      developer.log('Error: Invalid chat ID', name: 'ChatProvider');
      notifyListeners();
      return;
    }

    _currentChatId = chatId;
    if (!_chatMessages.containsKey(chatId)) {
      loadChatMessages(chatId, token);
    }
    notifyListeners();
  }

  // Clear selected chat
  void clearCurrentChat() {
    if (_currentChatId != null) {
      try {
        _chatService.disconnectFromChat(_currentChatId!);
      } catch (e) {
        developer.log('Error disconnecting from chat: $e', name: 'ChatProvider');
      }
      _currentChatId = null;
      notifyListeners();
    }
  }

  // Clear error
  void clearError() {
    _error = null;
    notifyListeners();
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
        return '📷 Photo';
      case MessageType.video:
        return '🎥 Video';
      case MessageType.audio:
        return '🎵 Audio';
      case MessageType.file:
        return '📁 File';
      case MessageType.location:
        return '📍 Location';
      case MessageType.gif:
        return '🎭 GIF';
      case MessageType.sticker:
        return '😀 Sticker';
      case MessageType.contact:
        return '👤 Contact';
      case MessageType.call:
        return '📞 Call';
      case MessageType.system:
        return message.content;
    }
  }

  // Helper method to extract readable error messages
  String _getErrorMessage(dynamic error) {
    if (error == null) return 'Unknown error';
    
    String errorStr = error.toString();
    
    // Handle different error formats
    if (errorStr.contains('Exception:')) {
      return errorStr.split('Exception:').last.trim();
    } else if (errorStr.contains('Error:')) {
      return errorStr.split('Error:').last.trim();
    } else if (errorStr.contains(':')) {
      List<String> parts = errorStr.split(':');
      return parts.length > 1 ? parts.last.trim() : errorStr;
    }
    
    return errorStr;
  }

  // Helper method to determine if an error is retryable
  bool _isRetryableError(dynamic error) {
    String errorStr = error.toString().toLowerCase();
    return errorStr.contains('http 500') || 
           errorStr.contains('server error') ||
           errorStr.contains('network') ||
           errorStr.contains('timeout') ||
           errorStr.contains('connection');
  }

  // Handle new messages (for WebSocket)
  void onNewMessage(Message message) {
    if (message.chatId.isEmpty) {
      developer.log('Received message with empty chat ID', name: 'ChatProvider');
      return;
    }

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

  // Handle message status updates
  void onMessageStatusUpdate(String messageId, MessageStatus status) {
    if (_currentChatId == null) return;

    final messages = _chatMessages[_currentChatId!];
    if (messages != null) {
      for (int i = 0; i < messages.length; i++) {
        if (messages[i].id == messageId) {
          _chatMessages[_currentChatId!]![i] = messages[i].copyWith(status: status);
          notifyListeners();
          break;
        }
      }
    }
  }

  // Handle chat updates
  void onChatUpdate(Chat updatedChat) {
    final chatIndex = _chats.indexWhere((chat) => chat.id == updatedChat.id);
    if (chatIndex != -1) {
      _chats[chatIndex] = updatedChat;
      notifyListeners();
    }
  }

  // Cleanup on provider disposal
  @override
  void dispose() {
    try {
      if (_currentChatId != null) {
        _chatService.disconnectFromChat(_currentChatId!);
      }
    } catch (e) {
      developer.log('Error during disposal: $e', name: 'ChatProvider');
    }
    super.dispose();
  }
}