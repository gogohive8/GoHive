import 'dart:io';
import 'dart:async';
import 'dart:typed_data';
import 'package:http/http.dart' as http;
import 'package:supabase_flutter/supabase_flutter.dart';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import '../models/chat.dart';
import '../models/message.dart';

class ChatService {
  static final ChatService _instance = ChatService._internal();
  factory ChatService() => _instance;
  ChatService._internal();

  final _supabase = Supabase.instance.client;
  final _baseUrl =
      'https://gohive-chat-service-91df19df1b1f.herokuapp.com/api'; // Replace with your backend URL
  String? _authToken; // Set this via AuthProvider or similar

  final List<Chat> _chats = [];
  final Map<String, List<Message>> _messages = {};
  RealtimeChannel? _messageChannel;
  final _messageStreamController = StreamController<Message>.broadcast();

  // Initialize Supabase and auth token
  void initialize(String authToken) {
    _authToken = authToken;
    _setupRealtime();
  }

  // Setup real-time subscription for messages
  void _setupRealtime() {
    _messageChannel = _supabase
        .channel('messages')
        .onPostgresChanges(
          event: PostgresChangeEvent.insert,
          schema: 'chats',
          table: 'messages',
          callback: (payload) {
            final messageData = payload.newRecord as Map<String, dynamic>;
            final message = Message.fromJson(messageData);
            _messages[message.chatId] = _messages[message.chatId] ?? [];
            _messages[message.chatId]!.add(message);
            _messageStreamController.add(message); // Emit to stream
          },
        )
        .subscribe();
  }

  Stream<Message> get messageStream {
    return _messageStreamController.stream;
  }

  // Get all chats for the user
  Future<List<Chat>> getChats() async {
    try {
      final response = await http.get(
        Uri.parse('$_baseUrl/chats'),
        headers: {'Authorization': 'Bearer $_authToken'},
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as List;
        _chats.clear();
        _chats.addAll(data.map((e) => Chat.fromJson(e)).toList());
        return _chats;
      } else {
        throw Exception('Failed to fetch chats: ${response.body}');
      }
    } catch (e) {
      throw Exception('Error fetching chats: $e');
    }
  }

  // Get messages for a specific chat
  Future<List<Message>> getChatMessages(String chatId,
      {int limit = 50, int offset = 0}) async {
    try {
      final response = await http.get(
        Uri.parse(
            '$_baseUrl/chats/$chatId/messages?limit=$limit&offset=$offset'),
        headers: {'Authorization': 'Bearer $_authToken'},
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as List;
        _messages[chatId] = data.map((e) => Message.fromJson(e)).toList();
        return _messages[chatId]!;
      } else {
        throw Exception('Failed to fetch messages: ${response.body}');
      }
    } catch (e) {
      throw Exception('Error fetching messages: $e');
    }
  }

  // Send text message
  Future<Message> sendTextMessage(String chatId, String content,
      {String? replyToId}) async {
    final message = Message(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      chatId: chatId,
      senderId: _supabase.auth.currentUser?.id ?? 'unknown',
      type: MessageType.text,
      content: content,
      timestamp: DateTime.now(),
      replyToId: replyToId,
    );

    try {
      final response = await http.post(
        Uri.parse('$_baseUrl/messages'),
        headers: {
          'Authorization': 'Bearer $_authToken',
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'chat_id': chatId,
          'content': content,
          'type': MessageType.text.toString().split('.').last,
          'reply_to_id': replyToId,
        }),
      );

      if (response.statusCode == 201) {
        _messages[chatId] = _messages[chatId] ?? [];
        _messages[chatId]!.add(message);
        return message;
      } else {
        throw Exception('Failed to send message: ${response.body}');
      }
    } catch (e) {
      throw Exception('Error sending message: $e');
    }
  }

  // Send media message (photo/video)
  Future<Message> sendMediaMessage(String chatId, File file, MessageType type,
      {String? caption}) async {
    final mediaUrl = await _uploadMedia(file, type);

    final metadata = MediaMetadata(
      fileName: file.path.split('/').last,
      fileSize: await file.length(),
    );

    final message = Message(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      chatId: chatId,
      senderId: 'current_user_id',
      type: type,
      content: mediaUrl,
      metadata: metadata.toJson(),
      timestamp: DateTime.now(),
    );

    try {
      final response = await http.post(
        Uri.parse('$_baseUrl/messages'),
        headers: {
          'Authorization': 'Bearer $_authToken',
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'chat_id': chatId,
          'content': mediaUrl,
          'type': type.toString().split('.').last,
          'metadata': metadata.toJson(),
        }),
      );

      if (response.statusCode == 201) {
        _messages[chatId] = _messages[chatId] ?? [];
        _messages[chatId]!.add(message);
        return message;
      } else {
        throw Exception('Failed to send media message: ${response.body}');
      }
    } catch (e) {
      throw Exception('Error sending media message: $e');
    }
  }

  // Send audio message
  Future<Message> sendAudioMessage(
      String chatId, File audioFile, int duration) async {
    final audioUrl = await _uploadMedia(audioFile, MessageType.audio);

    final metadata = MediaMetadata(
      fileName: audioFile.path.split('/').last,
      fileSize: await audioFile.length(),
      duration: duration,
    );

    final message = Message(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      chatId: chatId,
      senderId: 'current_user_id',
      type: MessageType.audio,
      content: audioUrl,
      metadata: metadata.toJson(),
      timestamp: DateTime.now(),
    );

    try {
      final response = await http.post(
        Uri.parse('$_baseUrl/messages'),
        headers: {
          'Authorization': 'Bearer $_authToken',
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'chat_id': chatId,
          'content': audioUrl,
          'type': MessageType.audio.toString().split('.').last,
          'metadata': metadata.toJson(),
        }),
      );

      if (response.statusCode == 201) {
        _messages[chatId] = _messages[chatId] ?? [];
        _messages[chatId]!.add(message);
        return message;
      } else {
        throw Exception('Failed to send audio message: ${response.body}');
      }
    } catch (e) {
      throw Exception('Error sending audio message: $e');
    }
  }

  // Send file message
  Future<Message> sendFileMessage(String chatId, File file) async {
    final fileUrl = await _uploadMedia(file, MessageType.file);

    final metadata = MediaMetadata(
      fileName: file.path.split('/').last,
      fileSize: await file.length(),
    );

    final message = Message(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      chatId: chatId,
      senderId: 'current_user_id',
      type: MessageType.file,
      content: fileUrl,
      metadata: metadata.toJson(),
      timestamp: DateTime.now(),
    );

    try {
      final response = await http.post(
        Uri.parse('$_baseUrl/messages'),
        headers: {
          'Authorization': 'Bearer $_authToken',
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'chat_id': chatId,
          'content': fileUrl,
          'type': MessageType.file.toString().split('.').last,
          'metadata': metadata.toJson(),
        }),
      );

      if (response.statusCode == 201) {
        _messages[chatId] = _messages[chatId] ?? [];
        _messages[chatId]!.add(message);
        return message;
      } else {
        throw Exception('Failed to send file message: ${response.body}');
      }
    } catch (e) {
      throw Exception('Error sending file message: $e');
    }
  }

  // Send location message
  Future<Message> sendLocationMessage(
      String chatId, double latitude, double longitude,
      {String? address, String? name}) async {
    final metadata = LocationMetadata(
      latitude: latitude,
      longitude: longitude,
      address: address,
      name: name,
    );

    final message = Message(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      chatId: chatId,
      senderId: 'current_user_id',
      type: MessageType.location,
      content: '$latitude,$longitude',
      metadata: metadata.toJson(),
      timestamp: DateTime.now(),
    );

    try {
      final response = await http.post(
        Uri.parse('$_baseUrl/messages'),
        headers: {
          'Authorization': 'Bearer $_authToken',
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'chat_id': chatId,
          'content': '$latitude,$longitude',
          'type': MessageType.location.toString().split('.').last,
          'metadata': metadata.toJson(),
        }),
      );

      if (response.statusCode == 201) {
        _messages[chatId] = _messages[chatId] ?? [];
        _messages[chatId]!.add(message);
        return message;
      } else {
        throw Exception('Failed to send location message: ${response.body}');
      }
    } catch (e) {
      throw Exception('Error sending location message: $e');
    }
  }

  // Send contact message
  Future<Message> sendContactMessage(String chatId, String name,
      {String? phoneNumber, String? email, String? avatar}) async {
    final metadata = ContactMetadata(
      name: name,
      phoneNumber: phoneNumber,
      email: email,
      avatar: avatar,
    );

    final message = Message(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      chatId: chatId,
      senderId: 'current_user_id',
      type: MessageType.contact,
      content: name,
      metadata: metadata.toJson(),
      timestamp: DateTime.now(),
    );

    try {
      final response = await http.post(
        Uri.parse('$_baseUrl/messages'),
        headers: {
          'Authorization': 'Bearer $_authToken',
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'chat_id': chatId,
          'content': name,
          'type': MessageType.contact.toString().split('.').last,
          'metadata': metadata.toJson(),
        }),
      );

      if (response.statusCode == 201) {
        _messages[chatId] = _messages[chatId] ?? [];
        _messages[chatId]!.add(message);
        return message;
      } else {
        throw Exception('Failed to send contact message: ${response.body}');
      }
    } catch (e) {
      throw Exception('Error sending contact message: $e');
    }
  }

  // Send GIF or sticker
  Future<Message> sendGifMessage(
      String chatId, String gifUrl, MessageType type) async {
    final message = Message(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      chatId: chatId,
      senderId: 'current_user_id',
      type: type,
      content: gifUrl,
      timestamp: DateTime.now(),
    );

    try {
      final response = await http.post(
        Uri.parse('$_baseUrl/messages'),
        headers: {
          'Authorization': 'Bearer $_authToken',
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'chat_id': chatId,
          'content': gifUrl,
          'type': type.toString().split('.').last,
        }),
      );

      if (response.statusCode == 201) {
        _messages[chatId] = _messages[chatId] ?? [];
        _messages[chatId]!.add(message);
        return message;
      } else {
        throw Exception('Failed to send GIF/sticker message: ${response.body}');
      }
    } catch (e) {
      throw Exception('Error sending GIF/sticker message: $e');
    }
  }

  // Create a new chat
  Future<Chat> createChat(String name, List<String> participants, ChatType type,
      {String? description, String? avatar}) async {
    try {
      final response = await http.post(
        Uri.parse('$_baseUrl/chats'),
        headers: {
          'Authorization': 'Bearer $_authToken',
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'name': name,
          'participants': participants,
          'type': type.toString().split('.').last,
          'description': description,
          'avatar': avatar,
        }),
      );

      if (response.statusCode == 201) {
        final data = jsonDecode(response.body)['chat'];
        final chat = Chat.fromJson(data);
        _chats.add(chat);
        return chat;
      } else {
        throw Exception('Failed to create chat: ${response.body}');
      }
    } catch (e) {
      throw Exception('Error creating chat: $e');
    }
  }

  // Join a chat
  Future<void> joinChat(String chatId) async {
    try {
      final response = await http.post(
        Uri.parse('$_baseUrl/chats/$chatId/join'),
        headers: {'Authorization': 'Bearer $_authToken'},
      );

      if (response.statusCode != 200) {
        throw Exception('Failed to join chat: ${response.body}');
      }
    } catch (e) {
      throw Exception('Error joining chat: $e');
    }
  }

  // Leave a chat
  Future<void> leaveChat(String chatId) async {
    try {
      final response = await http.post(
        Uri.parse('$_baseUrl/chats/$chatId/leave'),
        headers: {'Authorization': 'Bearer $_authToken'},
      );

      if (response.statusCode == 200) {
        _chats.removeWhere((chat) => chat.id == chatId);
        _messages.remove(chatId);
      } else {
        throw Exception('Failed to leave chat: ${response.body}');
      }
    } catch (e) {
      throw Exception('Error leaving chat: $e');
    }
  }

  // Mark messages as read
  Future<void> markMessagesAsRead(
      String chatId, List<String> messageIds) async {
    try {
      final response = await http.post(
        Uri.parse('$_baseUrl/chats/$chatId/mark-read'),
        headers: {
          'Authorization': 'Bearer $_authToken',
          'Content-Type': 'application/json',
        },
        body: jsonEncode({'messageIds': messageIds}),
      );

      if (response.statusCode == 200) {
        final chatMessages = _messages[chatId];
        if (chatMessages != null) {
          for (int i = 0; i < chatMessages.length; i++) {
            if (messageIds.contains(chatMessages[i].id)) {
              _messages[chatId]![i] =
                  chatMessages[i].copyWith(status: MessageStatus.read);
            }
          }
        }
      } else {
        throw Exception('Failed to mark messages as read: ${response.body}');
      }
    } catch (e) {
      throw Exception('Error marking messages as read: $e');
    }
  }

  // Delete a message
  Future<void> deleteMessage(String chatId, String messageId) async {
    try {
      final response = await http.delete(
        Uri.parse('$_baseUrl/messages/$messageId'),
        headers: {'Authorization': 'Bearer $_authToken'},
      );

      if (response.statusCode == 200) {
        _messages[chatId]?.removeWhere((msg) => msg.id == messageId);
      } else {
        throw Exception('Failed to delete message: ${response.body}');
      }
    } catch (e) {
      throw Exception('Error deleting message: $e');
    }
  }

  // Edit a message
  Future<Message> editMessage(String messageId, String newContent) async {
    try {
      final response = await http.patch(
        Uri.parse('$_baseUrl/messages/$messageId'),
        headers: {
          'Authorization': 'Bearer $_authToken',
          'Content-Type': 'application/json',
        },
        body: jsonEncode({'content': newContent}),
      );

      if (response.statusCode == 200) {
        for (final chatMessages in _messages.values) {
          for (int i = 0; i < chatMessages.length; i++) {
            if (chatMessages[i].id == messageId) {
              chatMessages[i] = chatMessages[i].copyWith(
                content: newContent,
                isEdited: true,
                editedAt: DateTime.now(),
              );
              return chatMessages[i];
            }
          }
        }
        throw Exception('Message not found');
      } else {
        throw Exception('Failed to edit message: ${response.body}');
      }
    } catch (e) {
      throw Exception('Error editing message: $e');
    }
  }

  // Start a call (placeholder, as call handling depends on WebRTC or similar)
  Future<void> startCall(String chatId, String callType,
      {bool isGroup = false}) async {
    // Implement call initiation logic (e.g., WebRTC signaling)
    print('Starting $callType call in chat: $chatId (group: $isGroup)');
  }

  // Update _uploadMedia for more MIME type handling
  Future<String> _uploadMedia(File file, MessageType type) async {
    try {
      final fileBytes = await file.readAsBytes();
      final base64File = base64Encode(fileBytes);
      String mimeType;
      switch (type) {
        case MessageType.image:
          final ext = file.path.split('.').last.toLowerCase();
          mimeType =
              'image/${ext == 'png' ? 'png' : ext == 'gif' ? 'gif' : 'jpeg'}';
          break;
        case MessageType.video:
          mimeType = 'video/mp4';
          break;
        case MessageType.audio:
          mimeType = 'audio/aac';
          break;
        case MessageType.file:
          mimeType = 'application/octet-stream';
          break;
        default:
          mimeType = 'application/octet-stream';
      }

      final response = await http.post(
        Uri.parse('$_baseUrl/upload'),
        headers: {
          'Authorization': 'Bearer $_authToken',
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'file': base64File,
          'fileName': file.path.split('/').last,
          'mimeType': mimeType,
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data['url'];
      } else {
        throw Exception('Failed to upload media: ${response.body}');
      }
    } catch (e) {
      throw Exception('Error uploading media: $e');
    }
  }

  // Connect to chat for real-time updates
  void connectToChat(String chatId) {
    // Real-time subscription is handled by _setupRealtime
    print('Connecting to chat: $chatId');
  }

  // Disconnect from chat
  void disconnectFromChat(String chatId) {
    // Unsubscribe if needed
    print('Disconnecting from chat: $chatId');
  }

  void dispose() {
    _messageChannel?.unsubscribe();
    _messageStreamController.close();
  }
}
