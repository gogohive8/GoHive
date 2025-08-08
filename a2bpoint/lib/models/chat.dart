// lib/models/chat.dart
enum ChatType {
  direct,
  group,
  mentorship,
  conference
}

class Chat {
  final String id;
  final String name;
  final String? description;
  final String? avatar;
  final ChatType type;
  final List<String> participants;
  final String? lastMessageId;
  final String? lastMessage;
  final DateTime? lastMessageTime;
  final int unreadCount;
  final bool isArchived;
  final bool isMuted;
  final Map<String, dynamic>? settings;
  final DateTime createdAt;
  final DateTime updatedAt;
  final String? createdBy;

  Chat({
    required this.id,
    required this.name,
    this.description,
    this.avatar,
    required this.type,
    required this.participants,
    this.lastMessageId,
    this.lastMessage,
    this.lastMessageTime,
    this.unreadCount = 0,
    this.isArchived = false,
    this.isMuted = false,
    this.settings,
    required this.createdAt,
    required this.updatedAt,
    this.createdBy,
  });

  factory Chat.fromJson(Map<String, dynamic> json) {
    return Chat(
      id: json['id'],
      name: json['name'],
      description: json['description'],
      avatar: json['avatar'],
      type: ChatType.values.firstWhere(
        (e) => e.toString() == 'ChatType.${json['type']}',
        orElse: () => ChatType.direct,
      ),
      participants: List<String>.from(json['participants'] ?? []),
      lastMessageId: json['lastMessageId'],
      lastMessage: json['lastMessage'],
      lastMessageTime: json['lastMessageTime'] != null 
          ? DateTime.parse(json['lastMessageTime']) 
          : null,
      unreadCount: json['unreadCount'] ?? 0,
      isArchived: json['isArchived'] ?? false,
      isMuted: json['isMuted'] ?? false,
      settings: json['settings'],
      createdAt: DateTime.parse(json['createdAt']),
      updatedAt: DateTime.parse(json['updatedAt']),
      createdBy: json['createdBy'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'avatar': avatar,
      'type': type.toString().split('.').last,
      'participants': participants,
      'lastMessageId': lastMessageId,
      'lastMessage': lastMessage,
      'lastMessageTime': lastMessageTime?.toIso8601String(),
      'unreadCount': unreadCount,
      'isArchived': isArchived,
      'isMuted': isMuted,
      'settings': settings,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
      'createdBy': createdBy,
    };
  }

  Chat copyWith({
    String? id,
    String? name,
    String? description,
    String? avatar,
    ChatType? type,
    List<String>? participants,
    String? lastMessageId,
    String? lastMessage,
    DateTime? lastMessageTime,
    int? unreadCount,
    bool? isArchived,
    bool? isMuted,
    Map<String, dynamic>? settings,
    DateTime? createdAt,
    DateTime? updatedAt,
    String? createdBy,
  }) {
    return Chat(
      id: id ?? this.id,
      name: name ?? this.name,
      description: description ?? this.description,
      avatar: avatar ?? this.avatar,
      type: type ?? this.type,
      participants: participants ?? this.participants,
      lastMessageId: lastMessageId ?? this.lastMessageId,
      lastMessage: lastMessage ?? this.lastMessage,
      lastMessageTime: lastMessageTime ?? this.lastMessageTime,
      unreadCount: unreadCount ?? this.unreadCount,
      isArchived: isArchived ?? this.isArchived,
      isMuted: isMuted ?? this.isMuted,
      settings: settings ?? this.settings,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      createdBy: createdBy ?? this.createdBy,
    );
  }
}

class ChatParticipant {
  final String userId;
  final String name;
  final String? avatar;
  final String role; // 'admin', 'member', 'mentor'
  final DateTime joinedAt;
  final DateTime? lastSeen;
  final bool isOnline;

  ChatParticipant({
    required this.userId,
    required this.name,
    this.avatar,
    this.role = 'member',
    required this.joinedAt,
    this.lastSeen,
    this.isOnline = false,
  });

  factory ChatParticipant.fromJson(Map<String, dynamic> json) {
    return ChatParticipant(
      userId: json['userId'],
      name: json['name'],
      avatar: json['avatar'],
      role: json['role'] ?? 'member',
      joinedAt: DateTime.parse(json['joinedAt']),
      lastSeen: json['lastSeen'] != null ? DateTime.parse(json['lastSeen']) : null,
      isOnline: json['isOnline'] ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'userId': userId,
      'name': name,
      'avatar': avatar,
      'role': role,
      'joinedAt': joinedAt.toIso8601String(),
      'lastSeen': lastSeen?.toIso8601String(),
      'isOnline': isOnline,
    };
  }
}