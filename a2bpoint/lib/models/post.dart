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
    return Post(
      id: json['id'].toString(),
      user: User.fromJson({
        'id': json['user_id'],
        'username': 'User${json['user_id']}',
        'avatar_url': ''
      }), // Временное решение для user
      imageUrls: json['image_urls']?.cast<String>(),
      text: type == 'goal'
          ? json['goalinfo'] as String?
          : json['title'] as String? ?? json['description'] as String?,
      createdAt: type == 'goal'
          ? DateTime.now()
          : DateTime.parse(json['created_at'] as String),
      likes: json['numOfLikes'] as int? ?? 0,
      comments: json['numOfComments'] as int? ?? 0,
      type: type,
      tasks:
          type == 'goal' ? json['tasks']?.cast<Map<String, dynamic>>() : null,
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
