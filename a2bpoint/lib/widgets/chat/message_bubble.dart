// lib/widgets/chat/message_bubble.dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import '../../models/message.dart';

class MessageBubble extends StatelessWidget {
  final Message message;
  final VoidCallback? onReply;
  final Function(String)? onEdit;
  final VoidCallback? onDelete;
  final VoidCallback? onTap;

  const MessageBubble({
    Key? key,
    required this.message,
    this.onReply,
    this.onEdit,
    this.onDelete,
    this.onTap,
  }) : super(key: key);

  bool get isMe => message.senderId == 'current_user_id'; // Получить из AuthProvider

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onLongPress: () => _showMessageOptions(context),
      onTap: onTap,
      child: Container(
        margin: EdgeInsets.symmetric(vertical: 2, horizontal: 8),
        child: Row(
          mainAxisAlignment: isMe ? MainAxisAlignment.end : MainAxisAlignment.start,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            if (!isMe) _buildAvatar(),
            if (!isMe) SizedBox(width: 8),
            Flexible(
              child: Column(
                crossAxisAlignment: isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
                children: [
                  _buildMessageContent(context),
                  SizedBox(height: 2),
                  _buildMessageInfo(),
                ],
              ),
            ),
            if (isMe) SizedBox(width: 8),
            if (isMe) _buildAvatar(),
          ],
        ),
      ),
    );
  }

  Widget _buildAvatar() {
    if (isMe) return SizedBox.shrink();
    
    return CircleAvatar(
      radius: 12,
      backgroundImage: message.senderAvatar != null 
        ? NetworkImage(message.senderAvatar!) 
        : null,
      child: message.senderAvatar == null 
        ? Text(
            (message.senderName?.isNotEmpty == true ? message.senderName![0] : '?').toUpperCase(),
            style: TextStyle(fontSize: 10),
          )
        : null,
    );
  }

  Widget _buildMessageContent(BuildContext context) {
    return Container(
      constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.75),
      decoration: BoxDecoration(
        color: isMe ? Theme.of(context).primaryColor : Colors.grey[200],
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(16),
          topRight: Radius.circular(16),
          bottomLeft: Radius.circular(isMe ? 16 : 4),
          bottomRight: Radius.circular(isMe ? 4 : 16),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 2,
            offset: Offset(0, 1),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (message.replyToId != null) _buildReplyPreview(context),
          _buildMessageBody(context),
        ],
      ),
    );
  }

  Widget _buildReplyPreview(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(8),
      margin: EdgeInsets.only(bottom: 4),
      decoration: BoxDecoration(
        color: (isMe ? Colors.white : Colors.grey[300])?.withOpacity(0.3),
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(16),
          topRight: Radius.circular(16),
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 3,
            height: 30,
            color: isMe ? Colors.white : Theme.of(context).primaryColor,
          ),
          SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Ответ на сообщение',
                  style: TextStyle(
                    fontSize: 12,
                    color: isMe ? Colors.white70 : Colors.grey[600],
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  'Оригинальное сообщение...',
                  style: TextStyle(
                    fontSize: 12,
                    color: isMe ? Colors.white70 : Colors.grey[600],
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMessageBody(BuildContext context) {
    switch (message.type) {
      case MessageType.text:
        return _buildTextMessage(context);
      case MessageType.image:
        return _buildImageMessage(context);
      case MessageType.video:
        return _buildVideoMessage(context);
      case MessageType.audio:
        return _buildAudioMessage(context);
      case MessageType.file:
        return _buildFileMessage(context);
      case MessageType.location:
        return _buildLocationMessage(context);
      case MessageType.contact:
        return _buildContactMessage(context);
      case MessageType.gif:
        return _buildGifMessage(context);
      case MessageType.sticker:
        return _buildStickerMessage(context);
      default:
        return _buildTextMessage(context);
    }
  }

  Widget _buildTextMessage(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      child: Text(
        message.content,
        style: TextStyle(
          color: isMe ? Colors.white : Colors.black87,
          fontSize: 16,
        ),
      ),
    );
  }

  Widget _buildImageMessage(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(16),
      child: Stack(
        children: [
          Image.network(
            message.content,
            width: 200,
            height: 200,
            fit: BoxFit.cover,
            loadingBuilder: (context, child, loadingProgress) {
              if (loadingProgress == null) return child;
              return Container(
                width: 200,
                height: 200,
                color: Colors.grey[300],
                child: Center(
                  child: CircularProgressIndicator(
                    value: loadingProgress.expectedTotalBytes != null
                      ? loadingProgress.cumulativeBytesLoaded / loadingProgress.expectedTotalBytes!
                      : null,
                  ),
                ),
              );
            },
            errorBuilder: (context, error, stackTrace) {
              return Container(
                width: 200,
                height: 200,
                color: Colors.grey[300],
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.error, color: Colors.red),
                    Text('Ошибка загрузки', style: TextStyle(fontSize: 12)),
                  ],
                ),
              );
            },
          ),
          Positioned(
            bottom: 8,
            right: 8,
            child: Container(
              padding: EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: Colors.black54,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(
                Icons.image,
                color: Colors.white,
                size: 16,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildVideoMessage(BuildContext context) {
    return Container(
      width: 200,
      height: 200,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        color: Colors.black87,
      ),
      child: Stack(
        alignment: Alignment.center,
        children: [
          Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              color: Colors.grey[800],
            ),
          ),
          Icon(
            Icons.play_circle_outline,
            size: 48,
            color: Colors.white,
          ),
          Positioned(
            bottom: 8,
            right: 8,
            child: Container(
              padding: EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: Colors.black54,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.videocam, color: Colors.white, size: 12),
                  SizedBox(width: 2),
                  Text(
                    '0:30', // Получить из metadata
                    style: TextStyle(color: Colors.white, fontSize: 10),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAudioMessage(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(12),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.play_arrow,
            color: isMe ? Colors.white : Theme.of(context).primaryColor,
          ),
          SizedBox(width: 8),
          Container(
            width: 100,
            height: 2,
            decoration: BoxDecoration(
              color: (isMe ? Colors.white : Theme.of(context).primaryColor).withOpacity(0.3),
              borderRadius: BorderRadius.circular(1),
            ),
            child: FractionallySizedBox(
              alignment: Alignment.centerLeft,
              widthFactor: 0.3, // Прогресс воспроизведения
              child: Container(
                decoration: BoxDecoration(
                  color: isMe ? Colors.white : Theme.of(context).primaryColor,
                  borderRadius: BorderRadius.circular(1),
                ),
              ),
            ),
          ),
          SizedBox(width: 8),
          Text(
            '0:15', // Длительность из metadata
            style: TextStyle(
              color: isMe ? Colors.white70 : Colors.grey[600],
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFileMessage(BuildContext context) {
    final metadata = message.metadata;
    final fileName = metadata?['fileName'] ?? 'Файл';
    final fileSize = metadata?['fileSize'] ?? 0;

    return Container(
      padding: EdgeInsets.all(12),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: (isMe ? Colors.white : Theme.of(context).primaryColor).withOpacity(0.2),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              Icons.insert_drive_file,
              color: isMe ? Colors.white : Theme.of(context).primaryColor,
            ),
          ),
          SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  fileName,
                  style: TextStyle(
                    color: isMe ? Colors.white : Colors.black87,
                    fontWeight: FontWeight.w500,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  _formatFileSize(fileSize),
                  style: TextStyle(
                    color: isMe ? Colors.white70 : Colors.grey[600],
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLocationMessage(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            height: 100,
            decoration: BoxDecoration(
              color: Colors.grey[300],
              borderRadius: BorderRadius.circular(8),
            ),
            child: Center(
              child: Icon(Icons.map, size: 32, color: Colors.grey[600]),
            ),
          ),
          SizedBox(height: 8),
          Row(
            children: [
              Icon(
                Icons.location_on,
                size: 16,
                color: isMe ? Colors.white : Theme.of(context).primaryColor,
              ),
              SizedBox(width: 4),
              Expanded(
                child: Text(
                  message.metadata?['address'] ?? 'Местоположение',
                  style: TextStyle(
                    color: isMe ? Colors.white : Colors.black87,
                    fontSize: 14,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildContactMessage(BuildContext context) {
    final metadata = message.metadata;
    final name = metadata?['name'] ?? 'Контакт';
    final phone = metadata?['phoneNumber'];
    final email = metadata?['email'];

    return Container(
      padding: EdgeInsets.all(12),
      child: Row(
        children: [
          CircleAvatar(
            radius: 20,
            backgroundColor: (isMe ? Colors.white : Theme.of(context).primaryColor).withOpacity(0.2),
            child: Icon(
              Icons.person,
              color: isMe ? Colors.white : Theme.of(context).primaryColor,
            ),
          ),
          SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  style: TextStyle(
                    color: isMe ? Colors.white : Colors.black87,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                if (phone != null)
                  Text(
                    phone,
                    style: TextStyle(
                      color: isMe ? Colors.white70 : Colors.grey[600],
                      fontSize: 12,
                    ),
                  ),
                if (email != null)
                  Text(
                    email,
                    style: TextStyle(
                      color: isMe ? Colors.white70 : Colors.grey[600],
                      fontSize: 12,
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGifMessage(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(16),
      child: Image.network(
        message.content,
        width: 150,
        height: 150,
        fit: BoxFit.cover,
        loadingBuilder: (context, child, loadingProgress) {
          if (loadingProgress == null) return child;
          return Container(
            width: 150,
            height: 150,
            color: Colors.grey[300],
            child: Center(child: CircularProgressIndicator()),
          );
        },
      ),
    );
  }

  Widget _buildStickerMessage(BuildContext context) {
    return Image.network(
      message.content,
      width: 100,
      height: 100,
      fit: BoxFit.contain,
    );
  }

  Widget _buildMessageInfo() {
    return Padding(
      padding: EdgeInsets.only(
        left: isMe ? 0 : 4,
        right: isMe ? 4 : 0,
        top: 2,
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (message.isEdited)
            Text(
              'изм. ',
              style: TextStyle(
                color: Colors.grey[600],
                fontSize: 10,
              ),
            ),
          Text(
            DateFormat('HH:mm').format(message.timestamp),
            style: TextStyle(
              color: Colors.grey[600],
              fontSize: 10,
            ),
          ),
          if (isMe) ...[
            SizedBox(width: 4),
            Icon(
              _getStatusIcon(),
              size: 12,
              color: _getStatusColor(),
            ),
          ],
        ],
      ),
    );
  }

  IconData _getStatusIcon() {
    switch (message.status) {
      case MessageStatus.sending:
        return Icons.access_time;
      case MessageStatus.sent:
        return Icons.done;
      case MessageStatus.delivered:
        return Icons.done_all;
      case MessageStatus.read:
        return Icons.done_all;
      case MessageStatus.failed:
        return Icons.error;
      default:
        return Icons.access_time;
    }
  }

  Color _getStatusColor() {
    switch (message.status) {
      case MessageStatus.read:
        return Colors.blue;
      case MessageStatus.failed:
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  String _formatFileSize(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
  }

  void _showMessageOptions(BuildContext context) {
    showModalBottomSheet(
      context: context,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            margin: EdgeInsets.only(top: 8, bottom: 16),
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: Colors.grey[300],
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          if (onReply != null)
            ListTile(
              leading: Icon(Icons.reply),
              title: Text('Ответить'),
              onTap: () {
                Navigator.pop(context);
                onReply!();
              },
            ),
          if (isMe && message.type == MessageType.text && onEdit != null)
            ListTile(
              leading: Icon(Icons.edit),
              title: Text('Редактировать'),
              onTap: () {
                Navigator.pop(context);
                _showEditDialog(context);
              },
            ),
          ListTile(
            leading: Icon(Icons.copy),
            title: Text('Копировать'),
            onTap: () {
              Navigator.pop(context);
              _copyToClipboard();
            },
          ),
          if (isMe && onDelete != null)
            ListTile(
              leading: Icon(Icons.delete, color: Colors.red),
              title: Text('Удалить', style: TextStyle(color: Colors.red)),
              onTap: () {
                Navigator.pop(context);
                onDelete!();
              },
            ),
          SizedBox(height: 20),
        ],
      ),
    );
  }

  void _copyToClipboard() {
    String textToCopy = '';
    switch (message.type) {
      case MessageType.text:
        textToCopy = message.content;
        break;
      case MessageType.contact:
        final metadata = message.metadata;
        textToCopy = '${metadata?['name'] ?? 'Контакт'}\n';
        if (metadata?['phoneNumber'] != null) {
          textToCopy += 'Телефон: ${metadata?['phoneNumber']}\n';
        }
        if (metadata?['email'] != null) {
          textToCopy += 'Email: ${metadata?['email']}';
        }
        break;
      case MessageType.location:
        final metadata = message.metadata;
        textToCopy = metadata?['address'] ?? 'Местоположение';
        break;
      default:
        textToCopy = 'Медиафайл';
    }
    
    Clipboard.setData(ClipboardData(text: textToCopy));
  }

  void _showEditDialog(BuildContext context) {
    final controller = TextEditingController(text: message.content);
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Редактировать сообщение'),
        content: TextField(
          controller: controller,
          maxLines: null,
          decoration: InputDecoration(
            hintText: 'Введите новый текст...',
            border: OutlineInputBorder(),
          ),
          autofocus: true,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Отмена'),
          ),
          TextButton(
            onPressed: () {
              if (controller.text.trim().isNotEmpty && onEdit != null) {
                Navigator.pop(context);
                onEdit!(controller.text.trim());
              }
            },
            child: Text('Сохранить'),
          ),
        ],
      ),
    );
  }
}