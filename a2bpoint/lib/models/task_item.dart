// models/task_item.dart
class TaskItem {
  final String id;
  final String title;
  final String description;
  bool isCompleted;

  TaskItem({
    required this.id,
    required this.title,
    required this.description,
    this.isCompleted = false,
  });

  TaskItem copyWith({
    String? id,
    String? title,
    String? description,
    bool? isCompleted,
  }) {
    return TaskItem(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      isCompleted: isCompleted ?? this.isCompleted,
    );
  }
}