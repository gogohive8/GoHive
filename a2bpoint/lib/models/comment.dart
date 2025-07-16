class Comment {
  final String id;
  final String post_id;
  final String userId;
  final String username;
  final String text;
  final DateTime createdAt;

  Comment({
    required this.id,
    required this.post_id,
    required this.userId,
    required this.username,
    required this.text,
    required this.createdAt,
  });

  factory Comment.fromJson(Map<String, dynamic> json) {
    return Comment(
      id: json['id']?.toString() ?? '',
      post_id: json['post_id']?.toString() ?? '',
      userId: json['userId']?.toString() ?? 'unknown',
      username: json['username']?.toString() ?? 'Unknown',
      text: json['text']?.toString() ?? '',
      createdAt: DateTime.parse(
          json['created_at']?.toString() ?? DateTime.now().toIso8601String()),
    );
  }
}
