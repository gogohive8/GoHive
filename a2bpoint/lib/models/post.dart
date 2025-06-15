import 'dart:convert';

class Post {
  final String id;
  final User user;
  final List<String>? imageUrls;
  final String? text;
  final DateTime createdAt;
  int likes;
  int comments;
  final String? type;
  final List<Map<String, dynamic>>? tasks;

  Post({
    required this.id,
    required this.user,
    this.imageUrls,
    this.text,
    required this.createdAt,
    required this.likes,
    required this.comments,
    this.type,
    this.tasks,
  });

  factory Post.fromJson(Map<String, dynamic> json) {
    return Post(
      id: json['id'],
      user: User.fromJson(json['user']),
      imageUrls: json['image_urls']?.cast<String>(),
      text: json['description'],
      createdAt: DateTime.parse(json['created_at']),
      likes: json['likes'] ?? 0,
      comments: json['comments'] ?? 0,
      type: json['type'],
      tasks: json['tasks']?.cast<Map<String, dynamic>>(),
    );
  }
}

class User {
  final String id;
  final String username;
  final String avatarUrl;

  User({
    required this.id,
    required this.username,
    required this.avatarUrl,
  });

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['id'],
      username: json['username'],
      avatarUrl: json['avatar_url'],
    );
  }
}
