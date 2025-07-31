class Comment {
  final String id;
  final String postId;
  final String userId;
  final String username;
  final String text;
  final DateTime createdAt;

  Comment({
    required this.id,
    required this.postId,
    required this.userId,
    required this.username,
    required this.text,
    required this.createdAt,
  });

  factory Comment.fromJson(Map<String, dynamic> json) {
    // Обработка даты создания
    DateTime createdAt;
    try {
      final createdAtStr = json['created_at']?.toString() ?? 
                          json['createdAt']?.toString() ?? 
                          DateTime.now().toIso8601String();
      createdAt = DateTime.parse(createdAtStr);
    } catch (e) {
      createdAt = DateTime.now();
    }

    return Comment(
      id: json['id']?.toString() ?? '',
      postId: json['post_id']?.toString() ?? 
              json['postId']?.toString() ?? 
              '',
      userId: json['userId']?.toString() ?? 
              json['user_id']?.toString() ?? 
              'unknown',
      username: json['username']?.toString() ?? 'Unknown User',
      text: json['text']?.toString() ?? '',
      createdAt: createdAt,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'post_id': postId,
      'userId': userId,
      'username': username,
      'text': text,
      'created_at': createdAt.toIso8601String(),
    };
  }

  @override
  String toString() {
    return 'Comment(id: $id, postId: $postId, userId: $userId, username: $username, text: $text)';
  }
}