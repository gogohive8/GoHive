class Task {
  final String title;
  final bool completed;

  Task({
    required this.title,
    required this.completed,
  });

  factory Task.fromJson(Map<String, dynamic> json) {
    return Task(
      title: json['title']?.toString() ?? '',
      completed: json['completed'] ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'title': title,
      'completed': completed,
    };
  }

  Task copyWith({
    String? title,
    bool? completed,
  }) {
    return Task(
      title: title ?? this.title,
      completed: completed ?? this.completed,
    );
  }

  @override
  String toString() {
    return 'Task(title: $title, completed: $completed)';
  }
}