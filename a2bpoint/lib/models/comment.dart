import 'package:a2bpoint/models/user.dart';
import 'dart:developer' as developer;

// Defining the Comment class to represent a comment on a post
class Comment {
  final String id;
  final User user;
  final String text;
  final DateTime createdAt;

  Comment({
    required this.id,
    required this.user,
    required this.text,
    required this.createdAt,
  });

  factory Comment.fromJson(Map<String, dynamic> json) {
    developer.log('Comment.fromJson keys: ${json.keys.toList()}',
        name: 'Comment.fromJson');
    return Comment(
      id: json['id']?.toString() ?? '',
      user: User.fromJson({
        'userID': json['userID'] ?? 'unknown',
        'username': json['username'] ?? 'Unknown',
        'avatar': json['avatar']?.toString() ?? '',
      }),
      text: json['text']?.toString() ?? '',
      createdAt: DateTime.parse(
          json['created_at']?.toString() ?? DateTime.now().toIso8601String()),
    );
  }
}
