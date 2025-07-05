import 'package:a2bpoint/models/user.dart';
import 'dart:developer' as developer;

// Defining the Post class to represent a post or goal in the app
class Post {
  final String id;
  final User user;
  final String? text;
  final String type; // 'post' | 'goal' | 'event'
  final DateTime createdAt;
  final int likes;
  final int numComments; // Number of comments on the post
  final List<String>? imageUrls;
  final List<Map<String, dynamic>>? tasks;

  Post({
    required this.id,
    required this.user,
    this.text,
    required this.type,
    required this.createdAt,
    required this.likes,
    required this.numComments,
    this.imageUrls,
    this.tasks,
  });

  factory Post.fromJson(
    Map<String, dynamic> json, {
    required String type,
  }) {
    developer.log('Post.fromJson keys: ${json.keys.toList()}',
        name: 'Post.fromJson');
    return Post(
      id: json['id']?.toString() ?? '',
      numComments: json['numOfComments'] ?? 0,
      user: User.fromJson({
        'userID': json['userID'] ?? json['user_id'] ?? 'unknown',
        'username': json['username'] ?? 'Unknown',
        'avatar': json['avatar']?.toString() ?? '',
      }),
      text:
          json['description']?.toString() ?? json['goalInfo']?.toString() ?? '',
      type: type,
      createdAt: DateTime.parse(
          json['created_at']?.toString() ?? DateTime.now().toIso8601String()),
      likes: json['numOfLikes'] ?? 0,
      imageUrls: (json['image_urls'] as List<dynamic>?)?.cast<String>(),
      tasks: (json['tasks'] as List<dynamic>?)?.cast<Map<String, dynamic>>(),
    );
  }
}
