// lib/screens/chat_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'dart:io';
import 'package:image_picker/image_picker.dart';
import 'package:file_picker/file_picker.dart';
import 'package:location/location.dart';
import 'package:record/record.dart';
import '../../models/chat.dart';
import '../../models/message.dart';
import '../../providers/chat_provider.dart';
import '../../widgets/chat/message_bubble.dart';
import '../../widgets/chat/chat_input.dart';
import '../../widgets/chat/recording_overlay.dart' hide RecordingOverlay;
import '../../widgets/chat/media_picker_bottom_sheet.dart';

class ChatScreen extends StatefulWidget {
  final String chatId;

  const ChatScreen({Key? key, required this.chatId}) : super(key: key);

  @override
  _ChatScreenState createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final TextEditingController _textController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final ImagePicker _imagePicker = ImagePicker();
  final AudioRecorder _audioRecorder = AudioRecorder();
  
  bool _isRecording = false;
  bool _isTyping = false;
  String? _replyToMessageId;
  Message? _replyToMessage;
  
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<ChatProvider>().loadChatMessages(widget.chatId);
    });
    _textController.addListener(_onTextChanged);
  }

  @override
  void dispose() {
    _textController.dispose();
    _scrollController.dispose();
    _audioRecorder.dispose();
    super.dispose();
  }

  void _onTextChanged() {
    setState(() {
      _isTyping = _textController.text.isNotEmpty;
    });
  }

  void _scrollToBottom() {
    if (_scrollController.hasClients) {
      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent,
        duration: Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<ChatProvider>(
      builder: (context, chatProvider, child) {
        final chat = chatProvider.getCurrentChat();
        final messages = chatProvider.getCurrentChatMessages();

        return Scaffold(
          appBar: _buildAppBar(chat),
          body: Column(
            children: [
              Expanded(
                child: Stack(
                  children: [
                    _buildMessagesList(messages),
                    if (_isRecording)
                      RecordingOverlay(
                        onCancel: _cancelRecording,
                        onSend: _sendRecording,
                      ),
                  ],
                ),
              ),
              if (_replyToMessage != null) _buildReplyPreview(),
              ChatInput(
                controller: _textController,
                onSendText: _sendTextMessage,
                onSendMedia: _showMediaPicker,
                onStartRecording: _startRecording,
                onStopRecording: _stopRecording,
                isRecording: _isRecording,
                isTyping: _isTyping,
                onSendLocation: _sendLocation,
                onSendFile: _pickAndSendFile,
              ),
            ],
          ),
        );
      },
    );
  }

  PreferredSizeWidget _buildAppBar(Chat? chat) {
    if (chat == null) return AppBar(title: Text('Загрузка...'));

    return AppBar(
      title: Row(
        children: [
          CircleAvatar(
            radius: 18,
            backgroundImage: chat.avatar != null ? NetworkImage(chat.avatar!) : null,
            child: chat.avatar == null 
              ? Text(chat.name.isNotEmpty ? chat.name[0].toUpperCase() : '?')
              : null,
          ),
          SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  chat.name,
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
                if (chat.type == ChatType.group)
                  Text(
                    '${chat.participants.length} участников',
                    style: TextStyle(fontSize: 12, color: Colors.white70),
                  ),
              ],
            ),
          ),
        ],
      ),
      actions: [
        if (chat.type == ChatType.mentorship || chat.type == ChatType.direct)
          IconButton(
            icon: Icon(Icons.call),
            onPressed: () => _startCall('audio'),
          ),
        IconButton(
          icon: Icon(Icons.videocam),
          onPressed: () => _startCall('video'),
        ),
        PopupMenuButton<String>(
          onSelected: (value) {
            switch (value) {
              case 'view_profile':
                // Navigate to chat profile
                break;
              case 'mute':
                context.read<ChatProvider>().toggleChatMute(chat.id);
                break;
              case 'clear_history':
                _clearChatHistory();
                break;
            }
          },
          itemBuilder: (context) => [
            PopupMenuItem(
              value: 'view_profile',
              child: Row(
                children: [
                  Icon(Icons.info_outline),
                  SizedBox(width: 12),
                  Text('Информация'),
                ],
              ),
            ),
            PopupMenuItem(
              value: 'mute',
              child: Row(
                children: [
                  Icon(chat.isMuted ? Icons.volume_up : Icons.volume_off),
                  SizedBox(width: 12),
                  Text(chat.isMuted ? 'Включить звук' : 'Отключить звук'),
                ],
              ),
            ),
            PopupMenuItem(
              value: 'clear_history',
              child: Row(
                children: [
                  Icon(Icons.delete_sweep, color: Colors.red),
                  SizedBox(width: 12),
                  Text('Очистить историю', style: TextStyle(color: Colors.red)),
                ],
              ),
            ),
          ],
        ),
      ],
      backgroundColor: Theme.of(context).primaryColor,
      foregroundColor: Colors.white,
    );
  }

  Widget _buildMessagesList(List<Message> messages) {
    if (messages.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.chat_bubble_outline, size: 64, color: Colors.grey[400]),
            SizedBox(height: 16),
            Text(
              'Начните разговор!',
              style: TextStyle(fontSize: 18, color: Colors.grey[600]),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      controller: _scrollController,
      padding: EdgeInsets.all(8),
      itemCount: messages.length,
      itemBuilder: (context, index) {
        final message = messages[index];
        final isLastMessage = index == messages.length - 1;
        final showDateSeparator = _shouldShowDateSeparator(messages, index);

        return Column(
          children: [
            if (showDateSeparator) _buildDateSeparator(message.timestamp),
            MessageBubble(
              message: message,
              onReply: () => _setReplyMessage(message),
              onEdit: (newText) => _editMessage(message.id, newText),
              onDelete: () => _deleteMessage(message.id),
              onTap: () => _onMessageTap(message),
            ),
            if (isLastMessage) SizedBox(height: 8),
          ],
        );
      },
    );
  }

  Widget _buildDateSeparator(DateTime date) {
    String dateText;
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final yesterday = today.subtract(Duration(days: 1));
    final messageDate = DateTime(date.year, date.month, date.day);

    if (messageDate == today) {
      dateText = 'Сегодня';
    } else if (messageDate == yesterday) {
      dateText = 'Вчера';
    } else {
      dateText = '${date.day}.${date.month}.${date.year}';
    }

    return Container(
      margin: EdgeInsets.symmetric(vertical: 16),
      child: Row(
        children: [
          Expanded(child: Divider()),
          Container(
            padding: EdgeInsets.symmetric(horizontal: 16, vertical: 4),
            decoration: BoxDecoration(
              color: Colors.grey[300],
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              dateText,
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey[700],
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          Expanded(child: Divider()),
        ],
      ),
    );
  }

  Widget _buildReplyPreview() {
    if (_replyToMessage == null) return SizedBox.shrink();

    return Container(
      padding: EdgeInsets.all(8),
      margin: EdgeInsets.only(left: 8, right: 8, bottom: 4),
      decoration: BoxDecoration(
        color: Colors.grey[100],
        borderRadius: BorderRadius.circular(8),
        border: Border(
          left: BorderSide(color: Theme.of(context).primaryColor, width: 3),
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _replyToMessage!.senderName ?? 'Пользователь',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Theme.of(context).primaryColor,
                    fontSize: 12,
                  ),
                ),
                SizedBox(height: 2),
                Text(
                  _getMessagePreview(_replyToMessage!),
                  style: TextStyle(fontSize: 14),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          IconButton(
            icon: Icon(Icons.close, size: 20),
            onPressed: () => _clearReply(),
          ),
        ],
      ),
    );
  }

  bool _shouldShowDateSeparator(List<Message> messages, int index) {
    if (index == 0) return true;
    
    final currentMessage = messages[index];
    final previousMessage = messages[index - 1];
    
    final currentDate = DateTime(
      currentMessage.timestamp.year,
      currentMessage.timestamp.month,
      currentMessage.timestamp.day,
    );
    
    final previousDate = DateTime(
      previousMessage.timestamp.year,
      previousMessage.timestamp.month,
      previousMessage.timestamp.day,
    );
    
    return currentDate != previousDate;
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
        return '🎵 Аудиосообщение';
      case MessageType.file:
        return '📁 Файл';
      case MessageType.location:
        return '📍 Местоположение';
      default:
        return 'Сообщение';
    }
  }

  void _sendTextMessage() {
    final text = _textController.text.trim();
    if (text.isEmpty) return;

    context.read<ChatProvider>().sendTextMessage(text, replyToId: _replyToMessageId);
    _textController.clear();
    _clearReply();
    
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _scrollToBottom();
    });
  }

  void _showMediaPicker() {
    showModalBottomSheet(
      context: context,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => MediaPickerBottomSheet(
        onImagePicked: (source) => _pickAndSendImage(source),
        onVideoPicked: (source) => _pickAndSendVideo(source),
        onGifPicked: (gifUrl) => _sendGif(gifUrl),
        onStickerPicked: (stickerUrl) => _sendSticker(stickerUrl),
        onContactPicked: _pickAndSendContact,
      ),
    );
  }

  Future<void> _pickAndSendImage(ImageSource source) async {
    try {
      final XFile? image = await _imagePicker.pickImage(source: source);
      if (image != null) {
        final file = File(image.path);
        await context.read<ChatProvider>().sendMediaMessage(
          file, 
          MessageType.image,
        );
        _scrollToBottom();
      }
    } catch (e) {
      _showErrorSnackBar('Ошибка при отправке изображения: $e');
    }
  }

  Future<void> _pickAndSendVideo(ImageSource source) async {
    try {
      final XFile? video = await _imagePicker.pickVideo(source: source);
      if (video != null) {
        final file = File(video.path);
        await context.read<ChatProvider>().sendMediaMessage(
          file, 
          MessageType.video,
        );
        _scrollToBottom();
      }
    } catch (e) {
      _showErrorSnackBar('Ошибка при отправке видео: $e');
    }
  }

  Future<void> _pickAndSendFile() async {
    try {
      FilePickerResult? result = await FilePicker.platform.pickFiles();
      if (result != null) {
        final file = File(result.files.single.path!);
        await context.read<ChatProvider>().sendFileMessage(file);
        _scrollToBottom();
      }
    } catch (e) {
      _showErrorSnackBar('Ошибка при отправке файла: $e');
    }
  }

  Future<void> _sendLocation() async {
    try {
      Location location = Location();
      
      bool serviceEnabled = await location.serviceEnabled();
      if (!serviceEnabled) {
        serviceEnabled = await location.requestService();
        if (!serviceEnabled) {
          _showErrorSnackBar('Службы геолокации отключены');
          return;
        }
      }

      PermissionStatus permissionGranted = await location.hasPermission();
      if (permissionGranted == PermissionStatus.denied) {
        permissionGranted = await location.requestPermission();
        if (permissionGranted != PermissionStatus.granted) {
          _showErrorSnackBar('Доступ к геолокации не предоставлен');
          return;
        }
      }

      final locationData = await location.getLocation();
      
      await context.read<ChatProvider>().sendLocationMessage(
        locationData.latitude!,
        locationData.longitude!,
      );
      _scrollToBottom();
    } catch (e) {
      _showErrorSnackBar('Ошибка при отправке местоположения: $e');
    }
  }

  Future<void> _startRecording() async {
    try {
      if (await _audioRecorder.hasPermission()) {
        await _audioRecorder.start(const RecordConfig(), path: '/temp/audio_${DateTime.now().millisecondsSinceEpoch}.aac');
        setState(() {
          _isRecording = true;
        });
      } else {
        _showErrorSnackBar('Доступ к микрофону не предоставлен');
      }
    } catch (e) {
      _showErrorSnackBar('Ошибка при начале записи: $e');
    }
  }

  Future<void> _stopRecording() async {
    try {
      final path = await _audioRecorder.stop();
      setState(() {
        _isRecording = false;
      });

      if (path != null) {
        final file = File(path);
        // Получаем длительность аудио (здесь нужно использовать соответствующий пакет)
        const duration = 0; // Placeholder
        await context.read<ChatProvider>().sendAudioMessage(file, duration);
        _scrollToBottom();
      }
    } catch (e) {
      setState(() {
        _isRecording = false;
      });
      _showErrorSnackBar('Ошибка при остановке записи: $e');
    }
  }

  void _cancelRecording() {
    _audioRecorder.cancel();
    setState(() {
      _isRecording = false;
    });
  }

  Future<void> _sendRecording() async {
    await _stopRecording();
  }

  void _sendGif(String gifUrl) {
    context.read<ChatProvider>().sendGifMessage(gifUrl, MessageType.gif);
    _scrollToBottom();
  }

  void _sendSticker(String stickerUrl) {
    context.read<ChatProvider>().sendGifMessage(stickerUrl, MessageType.sticker);
    _scrollToBottom();
  }

  Future<void> _pickAndSendContact() async {
    // Здесь можно использовать контакты или показать диалог для ввода контакта
    final result = await showDialog<Map<String, String>>(
      context: context,
      builder: (context) => _ContactPickerDialog(),
    );
    
    if (result != null) {
      await context.read<ChatProvider>().sendContactMessage(
        result['name']!,
        phoneNumber: result['phone'],
        email: result['email'],
      );
      _scrollToBottom();
    }
  }

  void _startCall(String callType) {
    context.read<ChatProvider>().startCall(callType);
    // Здесь можно открыть экран звонка
  }

  void _setReplyMessage(Message message) {
    setState(() {
      _replyToMessage = message;
      _replyToMessageId = message.id;
    });
  }

  void _clearReply() {
    setState(() {
      _replyToMessage = null;
      _replyToMessageId = null;
    });
  }

  void _editMessage(String messageId, String newText) {
    context.read<ChatProvider>().editMessage(messageId, newText);
  }

  void _deleteMessage(String messageId) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Удалить сообщение?'),
        content: Text('Это действие нельзя отменить.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Отмена'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              context.read<ChatProvider>().deleteMessage(messageId);
            },
            child: Text('Удалить', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  void _onMessageTap(Message message) {
    // Обработка нажатия на сообщение (например, просмотр медиа)
    if (message.type == MessageType.image || message.type == MessageType.video) {
      // Открыть просмотрщик медиа
    }
  }

  void _clearChatHistory() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Очистить историю чата?'),
        content: Text('Все сообщения будут удалены безвозвратно.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Отмена'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              // Здесь можно добавить метод для очистки истории
            },
            child: Text('Очистить', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
      ),
    );
  }
}

class _ContactPickerDialog extends StatefulWidget {
  @override
  _ContactPickerDialogState createState() => _ContactPickerDialogState();
}

class _ContactPickerDialogState extends State<_ContactPickerDialog> {
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _emailController = TextEditingController();

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _emailController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text('Отправить контакт'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          TextField(
            controller: _nameController,
            decoration: InputDecoration(
              labelText: 'Имя *',
              border: OutlineInputBorder(),
            ),
          ),
          SizedBox(height: 12),
          TextField(
            controller: _phoneController,
            decoration: InputDecoration(
              labelText: 'Телефон',
              border: OutlineInputBorder(),
            ),
            keyboardType: TextInputType.phone,
          ),
          SizedBox(height: 12),
          TextField(
            controller: _emailController,
            decoration: InputDecoration(
              labelText: 'Email',
              border: OutlineInputBorder(),
            ),
            keyboardType: TextInputType.emailAddress,
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text('Отмена'),
        ),
        TextButton(
          onPressed: () {
            if (_nameController.text.trim().isNotEmpty) {
              Navigator.pop(context, {
                'name': _nameController.text.trim(),
                'phone': _phoneController.text.trim(),
                'email': _emailController.text.trim(),
              });
            }
          },
          child: Text('Отправить'),
        ),
      ],
    );
  }
}