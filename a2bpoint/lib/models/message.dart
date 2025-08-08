// lib/models/message.dart
enum MessageType {
  text,
  image,
  video,
  audio,
  file,
  location,
  gif,
  sticker,
  contact,
  call,
  system
}

enum MessageStatus {
  sending,
  sent,
  delivered,
  read,
  failed
}

class Message {
  final String id;
  final String chatId;
  final String senderId;
  final String? senderName;
  final String? senderAvatar;
  final MessageType type;
  final String content;
  final Map<String, dynamic>? metadata;
  final DateTime timestamp;
  final MessageStatus status;
  final String? replyToId;
  final bool isEdited;
  final DateTime? editedAt;

  Message({
    required this.id,
    required this.chatId,
    required this.senderId,
    this.senderName,
    this.senderAvatar,
    required this.type,
    required this.content,
    this.metadata,
    required this.timestamp,
    this.status = MessageStatus.sending,
    this.replyToId,
    this.isEdited = false,
    this.editedAt,
  });

  factory Message.fromJson(Map<String, dynamic> json) {
    return Message(
      id: json['id'],
      chatId: json['chatId'],
      senderId: json['senderId'],
      senderName: json['senderName'],
      senderAvatar: json['senderAvatar'],
      type: MessageType.values.firstWhere(
        (e) => e.toString() == 'MessageType.${json['type']}',
        orElse: () => MessageType.text,
      ),
      content: json['content'],
      metadata: json['metadata'],
      timestamp: DateTime.parse(json['timestamp']),
      status: MessageStatus.values.firstWhere(
        (e) => e.toString() == 'MessageStatus.${json['status']}',
        orElse: () => MessageStatus.sent,
      ),
      replyToId: json['replyToId'],
      isEdited: json['isEdited'] ?? false,
      editedAt: json['editedAt'] != null ? DateTime.parse(json['editedAt']) : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'chatId': chatId,
      'senderId': senderId,
      'senderName': senderName,
      'senderAvatar': senderAvatar,
      'type': type.toString().split('.').last,
      'content': content,
      'metadata': metadata,
      'timestamp': timestamp.toIso8601String(),
      'status': status.toString().split('.').last,
      'replyToId': replyToId,
      'isEdited': isEdited,
      'editedAt': editedAt?.toIso8601String(),
    };
  }

  Message copyWith({
    String? id,
    String? chatId,
    String? senderId,
    String? senderName,
    String? senderAvatar,
    MessageType? type,
    String? content,
    Map<String, dynamic>? metadata,
    DateTime? timestamp,
    MessageStatus? status,
    String? replyToId,
    bool? isEdited,
    DateTime? editedAt,
  }) {
    return Message(
      id: id ?? this.id,
      chatId: chatId ?? this.chatId,
      senderId: senderId ?? this.senderId,
      senderName: senderName ?? this.senderName,
      senderAvatar: senderAvatar ?? this.senderAvatar,
      type: type ?? this.type,
      content: content ?? this.content,
      metadata: metadata ?? this.metadata,
      timestamp: timestamp ?? this.timestamp,
      status: status ?? this.status,
      replyToId: replyToId ?? this.replyToId,
      isEdited: isEdited ?? this.isEdited,
      editedAt: editedAt ?? this.editedAt,
    );
  }
}

// Специальные классы для метаданных разных типов сообщений
class MediaMetadata {
  final String fileName;
  final int fileSize;
  final int? duration; // для видео/аудио в секундах
  final int? width;
  final int? height;
  final String? thumbnail;

  MediaMetadata({
    required this.fileName,
    required this.fileSize,
    this.duration,
    this.width,
    this.height,
    this.thumbnail,
  });

  factory MediaMetadata.fromJson(Map<String, dynamic> json) {
    return MediaMetadata(
      fileName: json['fileName'],
      fileSize: json['fileSize'],
      duration: json['duration'],
      width: json['width'],
      height: json['height'],
      thumbnail: json['thumbnail'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'fileName': fileName,
      'fileSize': fileSize,
      'duration': duration,
      'width': width,
      'height': height,
      'thumbnail': thumbnail,
    };
  }
}

class LocationMetadata {
  final double latitude;
  final double longitude;
  final String? address;
  final String? name;

  LocationMetadata({
    required this.latitude,
    required this.longitude,
    this.address,
    this.name,
  });

  factory LocationMetadata.fromJson(Map<String, dynamic> json) {
    return LocationMetadata(
      latitude: json['latitude'].toDouble(),
      longitude: json['longitude'].toDouble(),
      address: json['address'],
      name: json['name'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'latitude': latitude,
      'longitude': longitude,
      'address': address,
      'name': name,
    };
  }
}

class ContactMetadata {
  final String name;
  final String? phoneNumber;
  final String? email;
  final String? avatar;

  ContactMetadata({
    required this.name,
    this.phoneNumber,
    this.email,
    this.avatar,
  });

  factory ContactMetadata.fromJson(Map<String, dynamic> json) {
    return ContactMetadata(
      name: json['name'],
      phoneNumber: json['phoneNumber'],
      email: json['email'],
      avatar: json['avatar'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'phoneNumber': phoneNumber,
      'email': email,
      'avatar': avatar,
    };
  }
}

class CallMetadata {
  final String type; // 'audio' или 'video'
  final int duration; // в секундах
  final String status; // 'completed', 'missed', 'declined'
  final List<String> participants;

  CallMetadata({
    required this.type,
    required this.duration,
    required this.status,
    required this.participants,
  });

  factory CallMetadata.fromJson(Map<String, dynamic> json) {
    return CallMetadata(
      type: json['type'],
      duration: json['duration'],
      status: json['status'],
      participants: List<String>.from(json['participants']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'type': type,
      'duration': duration,
      'status': status,
      'participants': participants,
    };
  }
}