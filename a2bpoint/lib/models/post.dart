import 'package:GoHive/models/user.dart';
import 'package:GoHive/models/tasks.dart';

class Post {
  final String id;
  final User user;
  final String? text;
  final String? title; // Added title property
  final String? content; // Added content property (alias for text)
  final List<String>? imageUrls;
  final String type;
  final int numOfLikes;
  final int numComments;
  final DateTime createdAt;
  final List<Task>? tasks;
  final bool isLiked; // Added isLiked property
  final String? difficulty; // Added difficulty property
  // Добавляем поле additionalData для хранения дополнительных данных
  final Map<String, dynamic>? additionalData;

  Post({
    required this.id,
    required this.user,
    this.text,
    this.title,
    this.content,
    this.imageUrls,
    required this.type,
    required this.numOfLikes,
    required this.numComments,
    required this.createdAt,
    this.tasks,
    this.isLiked = false, // Default to false
    this.difficulty,
    this.additionalData, // Добавляем в конструктор
  });

  // Convenience getter for content
  String? get displayContent => content ?? text;
  
  // Convenience getter for title (fallback to truncated text)
  String? get displayTitle {
    if (title != null && title!.isNotEmpty) return title;
    if (text != null && text!.isNotEmpty) {
      return text!.length > 50 ? '${text!.substring(0, 50)}...' : text;
    }
    return null;
  }

  factory Post.fromJson(Map<String, dynamic> json, {required String type}) {
    // Безопасное извлечение данных с проверками на null
    final userId = json['userID']?.toString() ?? 
                  json['user_id']?.toString() ?? 
                  'unknown';
    
    final username = json['username']?.toString() ?? 'Unknown User';
    
    final profileImage = json['avatar']?.toString() ?? 
                        json['profile_image']?.toString() ?? 
                        '';

    // Обработка массива изображений
    List<String>? imageUrls;
    if (json['image_urls'] != null) {
      if (json['image_urls'] is List) {
        imageUrls = List<String>.from(json['image_urls'].map((url) => url.toString()));
      } else if (json['image_urls'] is String) {
        imageUrls = [json['image_urls'].toString()];
      }
    } else if (json['photoURL'] != null) {
      if (json['photoURL'] is List) {
        imageUrls = List<String>.from(json['photoURL'].map((url) => url.toString()));
      } else if (json['photoURL'] is String) {
        imageUrls = [json['photoURL'].toString()];
      }
    }

    // Обработка текста поста
    final text = json['description']?.toString() ?? 
                json['goalInfo']?.toString() ?? 
                json['text']?.toString();

    // Extract title and content
    final title = json['title']?.toString();
    final content = json['content']?.toString() ?? text;

    // Обработка даты создания
    DateTime createdAt;
    try {
      final createdAtStr = json['created_at']?.toString() ?? 
                          json['createdAt']?.toString() ?? 
                          DateTime.now().toIso8601String();
      createdAt = DateTime.parse(createdAtStr);
    } catch (e) {
      createdAt = DateTime.now();
    }

    List<Task>? tasks;
    if (json['tasks'] != null && json['tasks'] is List) {
      tasks = (json['tasks'] as List)
          .map((taskJson) => Task.fromJson(taskJson))
          .toList();
    }

    // Extract isLiked and difficulty
    final isLiked = json['isLiked'] == true || 
                   json['is_liked'] == true ||
                   json['liked'] == true;
    
    final difficulty = json['difficulty']?.toString();

    // Создаем additionalData из всех возможных полей
    final additionalData = <String, dynamic>{};
    
    // Добавляем поля, которые могут быть в JSON
    if (json['interest'] != null) additionalData['interest'] = json['interest'];
    if (json['location'] != null) additionalData['location'] = json['location'];
    if (json['pointA'] != null) additionalData['pointA'] = json['pointA'];
    if (json['pointB'] != null) additionalData['pointB'] = json['pointB'];
    if (json['dateTime'] != null) additionalData['dateTime'] = json['dateTime'];
    if (json['date'] != null) additionalData['dateTime'] = json['date'];
    if (json['time'] != null) additionalData['time'] = json['time'];
    
    return Post(
      id: json['id']?.toString() ?? '',
      user: User(
        id: userId,
        username: username,
        profileImage: profileImage,
      ),
      text: text,
      title: title,
      content: content,
      imageUrls: imageUrls,
      type: type,
      numOfLikes: _safeParseInt(json['numOfLikes']),
      numComments: _safeParseInt(json['numOfComments']),
      createdAt: createdAt,
      tasks: tasks,
      isLiked: isLiked,
      difficulty: difficulty,
      additionalData: additionalData.isNotEmpty ? additionalData : null, // Добавляем additionalData
    );
  }

  // Вспомогательная функция для безопасного парсинга чисел
  static int _safeParseInt(dynamic value) {
    if (value == null) return 0;
    if (value is int) return value;
    if (value is double) return value.toInt();
    if (value is String) {
      return int.tryParse(value) ?? 0;
    }
    return 0;
  }

  Post copyWith({
    String? id,
    User? user,
    String? text,
    String? title,
    String? content,
    List<String>? imageUrls,
    String? type,
    int? numOfLikes,
    int? numComments,
    DateTime? createdAt,
    List<Task>? tasks,
    bool? isLiked,
    String? difficulty,
    Map<String, dynamic>? additionalData, // Добавляем в copyWith
  }) {
    return Post(
      id: id ?? this.id,
      user: user ?? this.user,
      text: text ?? this.text,
      title: title ?? this.title,
      content: content ?? this.content,
      imageUrls: imageUrls ?? this.imageUrls,
      type: type ?? this.type,
      numOfLikes: numOfLikes ?? this.numOfLikes,
      numComments: numComments ?? this.numComments,
      createdAt: createdAt ?? this.createdAt,
      tasks: tasks ?? this.tasks,
      isLiked: isLiked ?? this.isLiked,
      difficulty: difficulty ?? this.difficulty,
      additionalData: additionalData ?? this.additionalData, // Добавляем в copyWith
    );
  }

  @override
  String toString() {
    return 'Post(id: $id, user: $user, text: $text, type: $type, likes: $numOfLikes, comments: $numComments, isLiked: $isLiked)';
  }
}