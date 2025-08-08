class Comment {
  final String id;
  final String postId;
  final String userId;
  final String username;
  final String text;
  final DateTime createdAt;
  final String? taskId; // Добавляем для привязки к конкретной задаче
  final String? imageUrl; // Добавляем для фотографий в комментариях

  Comment({
    required this.id,
    required this.postId,
    required this.userId,
    required this.username,
    required this.text,
    required this.createdAt,
    this.taskId,
    this.imageUrl,
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
      taskId: json['task_id']?.toString(), // Добавляем taskId
      imageUrl: json['image_url']?.toString(), // Добавляем imageUrl
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
      'task_id': taskId,
      'image_url': imageUrl,
    };
  }

  Comment copyWith({
    String? id,
    String? postId,
    String? userId,
    String? username,
    String? text,
    DateTime? createdAt,
    String? taskId,
    String? imageUrl,
  }) {
    return Comment(
      id: id ?? this.id,
      postId: postId ?? this.postId,
      userId: userId ?? this.userId,
      username: username ?? this.username,
      text: text ?? this.text,
      createdAt: createdAt ?? this.createdAt,
      taskId: taskId ?? this.taskId,
      imageUrl: imageUrl ?? this.imageUrl,
    );
  }

  @override
  String toString() {
    return 'Comment(id: $id, postId: $postId, userId: $userId, username: $username, text: $text, taskId: $taskId)';
  }
}