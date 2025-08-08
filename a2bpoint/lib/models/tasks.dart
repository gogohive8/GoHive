class Task {
  final String id;
  final String title;
  final String? description;
  final bool completed;

  Task({
    required this.id,
    required this.title,
    this.description,
    this.completed = false,
  });

  factory Task.fromJson(Map<String, dynamic> json) {
    return Task(
      id: json['id']?.toString() ?? 
          json['_id']?.toString() ?? 
          DateTime.now().millisecondsSinceEpoch.toString(), // Fallback ID
      title: json['title']?.toString() ?? 
             json['name']?.toString() ?? 
             'Untitled Task',
      description: json['description']?.toString(),
      completed: json['completed'] == true || 
                 json['is_completed'] == true ||
                 json['done'] == true,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'completed': completed,
    };
  }

  Task copyWith({
    String? id,
    String? title,
    String? description,
    bool? completed,
  }) {
    return Task(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      completed: completed ?? this.completed,
    );
  }

  @override
  String toString() {
    return 'Task(id: $id, title: $title, completed: $completed)';
  }
}