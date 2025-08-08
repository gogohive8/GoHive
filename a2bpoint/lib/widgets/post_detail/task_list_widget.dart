// lib/widgets/post_detail/task_list_widget.dart
import 'package:flutter/material.dart';
import '../../models/tasks.dart';
import '../../models/comment.dart';
import 'task_item_widget.dart';
import 'dart:io';

class TaskListWidget extends StatelessWidget {
  final List<Task>? tasks;
  final bool isAuthor;
  final Map<String, List<Comment>> taskComments;
  final Map<String, TextEditingController> taskCommentControllers;
  final bool isCommenting;
  final Function(String, bool) onToggleTaskCompletion;
  final Function(String) onAddTaskComment;
  final VoidCallback? onPickImage;
  final File? selectedImage;
  final VoidCallback? onRemoveImage;

  const TaskListWidget({
    Key? key,
    this.tasks,
    required this.isAuthor,
    required this.taskComments,
    required this.taskCommentControllers,
    required this.isCommenting,
    required this.onToggleTaskCompletion,
    required this.onAddTaskComment,
    this.onPickImage,
    this.selectedImage,
    this.onRemoveImage,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    if (tasks == null || tasks!.isEmpty) {
      return const SizedBox.shrink();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 24),
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.1),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Icon(
                    Icons.checklist,
                    color: Color(0xFFAFCBEA),
                    size: 24,
                  ),
                  const SizedBox(width: 12),
                  Text(
                    'Tasks (${tasks!.length})',
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF1A1A1A),
                    ),
                  ),
                  const Spacer(),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: _getProgressColor().withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      '${_getCompletedTasksCount()}/${tasks!.length}',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: _getProgressColor(),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              // Progress indicator
              _buildProgressIndicator(),
            ],
          ),
        ),
        const SizedBox(height: 16),
        ...tasks!.asMap().entries.map((entry) {
          final index = entry.key;
          final task = entry.value;
          final comments = taskComments[task.id] ?? [];
          final controller = taskCommentControllers[task.id]!;

          return TaskItemWidget(
            task: task,
            index: index,
            isAuthor: isAuthor,
            comments: comments,
            commentController: controller,
            isCommenting: isCommenting,
            onToggleCompletion: (completed) => onToggleTaskCompletion(task.id, completed),
            onAddComment: () => onAddTaskComment(task.id),
            onPickImage: onPickImage,
            selectedImage: selectedImage,
            onRemoveImage: onRemoveImage,
          );
        }),
      ],
    );
  }

  Widget _buildProgressIndicator() {
    final progress = _getProgress();
    
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'Progress',
              style: TextStyle(
                fontSize: 14,
                color: Color(0xFF666666),
                fontWeight: FontWeight.w500,
              ),
            ),
            Text(
              '${(progress * 100).toInt()}%',
              style: TextStyle(
                fontSize: 14,
                color: _getProgressColor(),
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        ClipRRect(
          borderRadius: BorderRadius.circular(6),
          child: LinearProgressIndicator(
            value: progress,
            backgroundColor: Colors.grey.withOpacity(0.2),
            valueColor: AlwaysStoppedAnimation<Color>(_getProgressColor()),
            minHeight: 8,
          ),
        ),
      ],
    );
  }

  double _getProgress() {
    if (tasks == null || tasks!.isEmpty) return 0.0;
    final completedCount = _getCompletedTasksCount();
    return completedCount / tasks!.length;
  }

  int _getCompletedTasksCount() {
    if (tasks == null) return 0;
    return tasks!.where((task) => task.completed).length;
  }

  Color _getProgressColor() {
    final progress = _getProgress();
    if (progress == 1.0) return Colors.green;
    if (progress >= 0.5) return Colors.orange;
    return const Color(0xFFAFCBEA);
  }
}