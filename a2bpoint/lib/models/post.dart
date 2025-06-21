import 'dart:developer' as developer;

class Post {
  final String id;
  final String userId;
  final String username;
  final String? title;
  final String? text;
  final String? category;
  final DateTime createdAt;
  final int numOfLikes;
  final int numOfComments;
  final String? type;
  final List<Map<String, dynamic>>? tasks;
  final String? dateTime;

  Post({
    required this.id,
    required this.userId,
    required this.username,
    this.title,
    this.text,
    this.category,
    required this.createdAt,
    required this.numOfLikes,
    required this.numOfComments,
    this.type,
    this.tasks,
    this.dateTime,
  });

  factory Post.fromJson(Map<String, dynamic> json, {String? type}) {
    developer.log('Parsing Post JSON: $json, type: $type',
        name: 'Post.fromJson');
    try {
      String? textValue = json['description']?.toString() ??
          json['text']?.toString() ??
          'No description available';
      String? titleValue = json['title']?.toString() ??
          json['goalInfo']?.toString() ??
          json['description']?.toString();
      return Post(
        id: json['id']?.toString() ?? '',
        userId: json['user_id']?.toString() ?? json['userID']?.toString() ?? '',
        username: json['username']?.toString() ?? 'Unknown',
        title: titleValue,
        text: textValue,
        category: json['interest']?.toString() ?? json['category']?.toString(),
        createdAt: json['created_at'] != null
            ? DateTime.tryParse(json['created_at'] as String) ?? DateTime.now()
            : DateTime.now(),
        numOfLikes: (json['numOfLikes'] as int?) ?? 0,
        numOfComments: (json['numOfComments'] as int?) ?? 0,
        type: type,
        tasks: type == 'goal'
            ? (json['tasks'] as List<dynamic>?)?.cast<Map<String, dynamic>>()
            : null,
        dateTime: type == 'event' ? json['date_time']?.toString() : null,
      );
    } catch (e, stackTrace) {
      developer.log('Error parsing Post: $e',
          name: 'Post.fromJson', stackTrace: stackTrace);
      rethrow;
    }
  }
}
