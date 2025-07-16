class Post {
  final String id;
  final User user;
  final String? text;
  final List<String>? imageUrls;
  final String type;
  final int numOfLikes;
  final int numComments;
  final DateTime createdAt;
  final List<Map<String, dynamic>>? tasks;

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
    return Post(
      id: json['id']?.toString() ?? '',
      user: User(
        id: json['userID']?.toString() ?? 'unknown',
        username: json['username']?.toString() ?? 'Unknown',
        profileImage: json['avatar']?.toString() ?? '',
      ),
      text: json['description']?.toString(),
      imageUrls: json['image_urls'] != null
          ? List<String>.from(json['image_urls'])
          : null,
      type: type,
      numOfLikes: (json['numOfnumOfLikes'] as num?)?.toInt() ?? 0,
      numComments: (json['numOfComments'] as num?)?.toInt() ?? 0,
      createdAt: DateTime.parse(
          json['created_at']?.toString() ?? DateTime.now().toIso8601String()),
      tasks: json['tasks'] != null
          ? List<Map<String, dynamic>>.from(json['tasks'])
          : null,
    );
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
    List<Map<String, dynamic>>? tasks,
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
}

class User {
  final String id;
  final String username;
  final String profileImage;

  User({
    required this.id,
    required this.username,
    required this.profileImage,
  });
}
