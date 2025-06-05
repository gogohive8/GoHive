import 'dart:convert';

class Post {
  final String id;
  final User user;
  final String imageUrl;
  final String text;
  final DateTime createdAt;
  int likes;
  int comments;

  Post({
    required this.id,
    required this.user,
    required this.imageUrl,
    required this.text,
    required this.createdAt,
    required this.likes,
    required this.comments,
  });

  factory Post.fromJson(Map<String, dynamic> json) {
    return Post(
      id: json['id'],
      user: User.fromJson(json['user']),
      imageUrl: json['image_url'],
      text: json['text'],
      createdAt: DateTime.parse(json['created_at']),
      likes: json['likes'],
      comments: json['comments'],
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
