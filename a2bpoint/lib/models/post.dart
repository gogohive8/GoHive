import 'dart:developer' as developer;

class Post {
  final String? id;
  final String? title;
  final String? text;
  final String? type;
  final String? username;
  final int? numOfLikes;
  final DateTime? createdAt;
  final DateTime? dateTime;
  final List<Map<String, dynamic>>? tasks;

  Post({
    this.id,
    this.title,
    this.text,
    this.type,
    this.username,
    this.numOfLikes,
    this.createdAt,
    this.dateTime,
    this.tasks,
  });

  factory Post.fromJson(Map<String, dynamic> json) {
    try {
      final type = json['type']?.toString().toLowerCase();
      return Post(
        id: json['id']?.toString() ?? json['post_id']?.toString(),
        title: json['title']?.toString() ?? json['description']?.toString(),
        text: json['description']?.toString() ?? json['goalInfo']?.toString(),
        type: type,
        username: json['username']?.toString() ?? 'Unknown',
        numOfLikes: int.tryParse(json['numOfLikes']?.toString() ?? '0') ?? 0,
        createdAt: json['createdAt'] != null
            ? DateTime.tryParse(json['createdAt'].toString())
            : null,
        dateTime: type == 'event' && json['date_time'] != null
            ? DateTime.tryParse(json['date_time'].toString())
            : null,
        tasks: type == 'goal' && json['tasks'] != null
            ? List<Map<String, dynamic>>.from(json['tasks'])
            : null,
      );
    } catch (e, stackTrace) {
      developer.log('Error parsing Post: $e', stackTrace: stackTrace);
      return Post();
    }
  }
}
