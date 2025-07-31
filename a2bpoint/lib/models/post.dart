import 'package:GoHive/models/user.dart';
import 'package:GoHive/models/tasks.dart';

class Post {
  final String id;
  final User user;
  final String? text;
  final List<String>? imageUrls;
  final String type;
  final int numOfLikes;
  final int numComments;
  final DateTime createdAt;
  final List<Task>? tasks; // ИЗМЕНЕНО: теперь List<Task>

  Post({
    required this.id,
    required this.user,
    this.text,
    this.imageUrls,
    required this.type,
    required this.numOfLikes,
    required this.numComments,
    required this.createdAt,
    this.tasks,
  });

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

    // ИЗМЕНЕНО: Обработка задач с использованием модели Task
    List<Task>? tasks;
    if (json['tasks'] != null && json['tasks'] is List) {
      tasks = (json['tasks'] as List)
          .map((taskJson) => Task.fromJson(taskJson))
          .toList();
    }

    return Post(
      id: json['id']?.toString() ?? '',
      user: User(
        id: userId,
        username: username,
        profileImage: profileImage,
      ),
      text: text,
      imageUrls: imageUrls,
      type: type,
      numOfLikes: _safeParseInt(json['numOfLikes']),
      numComments: _safeParseInt(json['numOfComments']),
      createdAt: createdAt,
      tasks: tasks,
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
    List<String>? imageUrls,
    String? type,
    int? numOfLikes,
    int? numComments,
    DateTime? createdAt,
    List<Task>? tasks, // ИЗМЕНЕНО: теперь List<Task>
  }) {
    return Post(
      id: id ?? this.id,
      user: user ?? this.user,
      text: text ?? this.text,
      imageUrls: imageUrls ?? this.imageUrls,
      type: type ?? this.type,
      numOfLikes: numOfLikes ?? this.numOfLikes,
      numComments: numComments ?? this.numComments,
      createdAt: createdAt ?? this.createdAt,
      tasks: tasks ?? this.tasks,
    );
  }

  @override
  String toString() {
    return 'Post(id: $id, user: $user, text: $text, type: $type, likes: $numOfLikes, comments: $numComments)';
  }
}