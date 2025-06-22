import 'dart:developer' as developer;

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
    developer.log('User.fromJson keys: ${json.keys.toList()}',
        name: 'User.fromJson');
    return User(
      id: json['userID']?.toString() ?? json['id']?.toString() ?? 'unknown',
      username: json['username']?.toString() ?? 'Unknown',
      avatarUrl: json['avatarUrl']?.toString() ?? '',
    );
  }
}

class Post {
  final String id;
  final User user;
  final String? text;
  final String type;
  final DateTime createdAt;
  int likes;
  final List<String>? imageUrls;
  final List<Map<String, dynamic>>? tasks;

  Post({
    required this.id,
    required this.user,
    this.text,
    required this.type,
    required this.createdAt,
    required this.likes,
    this.imageUrls,
    this.tasks,
  });

  factory Post.fromJson(Map<String, dynamic> json, {required String type}) {
    developer.log('Post.fromJson json: $json', name: 'Post.fromJson');
    String? textValue;
    Map<String, dynamic> userJson = {
      'userID': json['userID']?.toString() ?? '',
      'username': json['username']?.toString() ?? 'Unknown',
      'avatarUrl': json['avatarUrl']?.toString() ?? ''
    };

    if (type == 'goal') {
      textValue =
          json['goalInfo']?.toString() ?? json['description']?.toString();
    } else {
      textValue = json['description']?.toString();
    }

    if (textValue == null) {
      developer.log(
          'No text found for $type. Available keys: ${json.keys.toList()}',
          name: 'Post.fromJson');
    }

    return Post(
      id: json['id']?.toString() ?? '',
      user: User.fromJson(userJson),
      text: textValue ?? 'No description',
      type: type,
      createdAt: DateTime.tryParse(json['created_at']?.toString() ?? '') ??
          DateTime.now(),
      likes: int.tryParse(json['numOfLikes']?.toString() ?? '0') ?? 0,
      imageUrls: (json['image_urls'] as List<dynamic>?)?.cast<String>(),
      tasks: (json['tasks'] as List<dynamic>?)?.cast<Map<String, dynamic>>(),
    );
  }
}
