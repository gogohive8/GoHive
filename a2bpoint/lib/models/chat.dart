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
    try {
      // Вспомогательная функция для безопасного извлечения строк
      String? safeString(dynamic value) {
        if (value == null) return null;
        return value.toString();
      }

      // Вспомогательная функция для обязательных строк
      String requiredString(dynamic value, String fieldName) {
        if (value == null || value.toString().trim().isEmpty) {
          throw FormatException('Required field "$fieldName" is null or empty');
        }
        return value.toString();
      }

      // Безопасное извлечение списка участников
      List<String> parseParticipants(dynamic value) {
        if (value == null) return [];
        
        if (value is List) {
          return value
              .map((e) => e?.toString() ?? '')
              .where((s) => s.isNotEmpty)
              .cast<String>()
              .toList();
        }
        
        // Если это объект с chat_participants (как в вашем JSON)
        if (value is Map && value.containsKey('chat_participants')) {
          final participants = value['chat_participants'];
          if (participants is List) {
            return participants
                .map((participant) {
                  if (participant is Map<String, dynamic>) {
                    return participant['user_id']?.toString() ?? '';
                  }
                  return participant?.toString() ?? '';
                })
                .where((s) => s.isNotEmpty)
                .cast<String>()
                .toList();
          }
        }
        
        return [];
      }

      // Безопасное извлечение даты
      DateTime parseDateTime(dynamic value) {
        if (value == null) return DateTime.now();
        
        if (value is String) {
          try {
            return DateTime.parse(value);
          } catch (e) {
            print('Error parsing date "$value": $e');
            return DateTime.now();
          }
        }
        
        return DateTime.now();
      }

      // Безопасное извлечение типа чата
      ChatType parseChatType(dynamic value) {
        if (value == null) return ChatType.direct;
        
        String typeStr = value.toString().toLowerCase();
        switch (typeStr) {
          case 'group':
            return ChatType.group;
          case 'mentorship':
            return ChatType.mentorship;
          case 'conference':
            return ChatType.conference;
          default:
            return ChatType.direct;
        }
      }

      // Извлечение участников из разных возможных полей
      final participantsData = json['participants'] ?? 
                              json['chat_participants'] ?? 
                              [];

      return Chat(
        id: requiredString(json['id'], 'id'),
        name: requiredString(json['name'], 'name'),
        description: safeString(json['description']),
        avatar: safeString(json['avatar']),
        type: parseChatType(json['type']),
        participants: parseParticipants(participantsData),
        lastMessageId: safeString(json['lastMessageId'] ?? json['last_message_id']),
        lastMessage: safeString(json['lastMessage'] ?? json['last_message']),
        lastMessageTime: json['lastMessageTime'] != null || json['last_message_time'] != null
            ? parseDateTime(json['lastMessageTime'] ?? json['last_message_time'])
            : null,
        unreadCount: int.tryParse((json['unreadCount'] ?? json['unread_count'] ?? 0).toString()) ?? 0,
        isArchived: json['isArchived'] == true || json['is_archived'] == true,
        isMuted: json['isMuted'] == true || json['is_muted'] == true,
        settings: json['settings'] is Map<String, dynamic> ? json['settings'] : null,
        createdAt: parseDateTime(json['createdAt'] ?? json['created_at']),
        updatedAt: parseDateTime(json['updatedAt'] ?? json['updated_at']),
        createdBy: safeString(json['createdBy'] ?? json['created_by']),
      );
    } catch (e, stackTrace) {
      // Детальное логирование ошибки
      print('❌ Error parsing Chat from JSON: $e');
      print('📄 JSON data: $json');
      print('📍 Stack trace: $stackTrace');
      
      // Возвращаем Chat с безопасными значениями по умолчанию, если возможно
      try {
        return Chat(
          id: json['id']?.toString() ?? 'unknown_${DateTime.now().millisecondsSinceEpoch}',
          name: json['name']?.toString() ?? 'Unknown Chat',
          description: json['description']?.toString(),
          avatar: json['avatar']?.toString(),
          type: ChatType.direct,
          participants: [],
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
          createdBy: json['created_by']?.toString() ?? json['createdBy']?.toString(),
        );
      } catch (fallbackError) {
        print('❌ Fallback chat creation also failed: $fallbackError');
        rethrow;
      }
    }
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

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Chat &&
          runtimeType == other.runtimeType &&
          id == other.id;

  @override
  int get hashCode => id.hashCode;

  @override
  String toString() {
    return 'Chat{id: $id, name: $name, type: $type, participants: ${participants.length}}';
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
    try {
      // Вспомогательная функция для безопасного извлечения строк
      String? safeString(dynamic value) {
        if (value == null) return null;
        return value.toString();
      }

      // Вспомогательная функция для обязательных строк
      String requiredString(dynamic value, String fieldName) {
        if (value == null || value.toString().trim().isEmpty) {
          throw FormatException('Required field "$fieldName" is null or empty');
        }
        return value.toString();
      }

      // Безопасное извлечение даты
      DateTime parseDateTime(dynamic value) {
        if (value == null) return DateTime.now();
        
        if (value is String) {
          try {
            return DateTime.parse(value);
          } catch (e) {
            print('Error parsing date "$value": $e');
            return DateTime.now();
          }
        }
        
        return DateTime.now();
      }

      return ChatParticipant(
        userId: requiredString(json['userId'] ?? json['user_id'], 'userId'),
        name: requiredString(json['name'], 'name'),
        avatar: safeString(json['avatar']),
        role: json['role']?.toString() ?? 'member',
        joinedAt: parseDateTime(json['joinedAt'] ?? json['joined_at']),
        lastSeen: json['lastSeen'] != null || json['last_seen'] != null
            ? parseDateTime(json['lastSeen'] ?? json['last_seen'])
            : null,
        isOnline: json['isOnline'] == true || json['is_online'] == true,
      );
    } catch (e, stackTrace) {
      print('❌ Error parsing ChatParticipant from JSON: $e');
      print('📄 JSON data: $json');
      print('📍 Stack trace: $stackTrace');
      rethrow;
    }
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

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ChatParticipant &&
          runtimeType == other.runtimeType &&
          userId == other.userId;

  @override
  int get hashCode => userId.hashCode;

  @override
  String toString() {
    return 'ChatParticipant{userId: $userId, name: $name, role: $role}';
  }
}