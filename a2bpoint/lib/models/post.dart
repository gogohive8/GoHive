import 'dart:developer' as developer;

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

  factory Post.fromJson(Map<String, dynamic> json, {String? type}) {
    developer.log('Parsing Post JSON: $json', name: 'Post.fromJson');
    try {
      return Post(
        id: (json['id']?.toString() ?? ''),
        user: User.fromJson({
          'id': json['userID']?.toString() ?? json['user_id']?.toString() ?? '',
          'username': json['username']?.toString() ?? 'Unknown',
          'avatar_url': json['avatarUrl']?.toString() ??
              json['avatar_url']?.toString() ??
              '',
        }),
        imageUrls: (json['image_urls'] as List<dynamic>?)?.cast<String>(),
        text: type == 'goal'
            ? json['goalInfo']?.toString() ?? json['goalinfo']?.toString()
            : json['description']?.toString() ?? json['title']?.toString(),
        createdAt: json['created_at'] != null
            ? DateTime.tryParse(json['created_at'] as String) ?? DateTime.now()
            : DateTime.now(),
        likes: (json['numOfLikes'] as int?) ?? 0,
        comments: (json['numOfComments'] as int?) ?? 0,
        type: type,
        tasks: type == 'goal'
            ? (json['tasks'] as List<dynamic>?)?.cast<Map<String, dynamic>>()
            : null,
      );
    } catch (e, stackTrace) {
      developer.log('Error parsing Post: $e',
          name: 'Post.fromJson', stackTrace: stackTrace);
      rethrow;
    }
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
    developer.log('Parsing User JSON: $json', name: 'User.fromJson');
    return User(
      id: json['id']?.toString() ?? '',
      username: json['username']?.toString() ?? 'Unknown',
      avatarUrl: json['avatar_url']?.toString() ?? '',
    );
  }
}
