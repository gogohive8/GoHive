// lib/widgets/post_detail/task_item_widget.dart
import 'package:flutter/material.dart';
import '../../models/tasks.dart';
import '../../models/comment.dart';
import 'comment_item_widget.dart';
import 'comment_input_widget.dart';
import 'dart:io';

class TaskItemWidget extends StatelessWidget {
  final Task task;
  final int index;
  final bool isAuthor;
  final List<Comment> comments;
  final TextEditingController commentController;
  final bool isCommenting;
  final Function(bool) onToggleCompletion;
  final VoidCallback onAddComment;
  final VoidCallback? onPickImage;
  final File? selectedImage;
  final VoidCallback? onRemoveImage;

  const TaskItemWidget({
    Key? key,
    required this.task,
    required this.index,
    required this.isAuthor,
    required this.comments,
    required this.commentController,
    required this.isCommenting,
    required this.onToggleCompletion,
    required this.onAddComment,
    this.onPickImage,
    this.selectedImage,
    this.onRemoveImage,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: task.completed
              ? Colors.green.withOpacity(0.3)
              : Colors.grey.withOpacity(0.2),
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Task header
          Padding(
            padding: const EdgeInsets.all(16),
            child: _buildTaskHeader(),
          ),

          // Task comments section
          if (comments.isNotEmpty) ...[
            Container(
              width: double.infinity,
              height: 1,
              color: Colors.grey.withOpacity(0.1),
            ),
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Comments (${comments.length})',
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF333333),
                    ),
                  ),
                  const SizedBox(height: 12),
                  ...comments.map((comment) => CommentItemWidget(comment: comment)),
                ],
              ),
            ),
          ],

          // Add comment to task
          Container(
            width: double.infinity,
            height: 1,
            color: Colors.grey.withOpacity(0.1),
          ),
          CommentInputWidget(
            controller: commentController,
            isLoading: isCommenting,
            isAuthor: isAuthor,
            hintText: 'Comment on this step...',
            onSend: onAddComment,
            onPickImage: onPickImage,
            selectedImage: selectedImage,
            onRemoveImage: onRemoveImage,
          ),
        ],
      ),
    );
  }

  Widget _buildTaskHeader() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Checkbox - только для автора
            GestureDetector(
              onTap: isAuthor ? () => onToggleCompletion(!task.completed) : null,
              child: Container(
                width: 28,
                height: 28,
                decoration: BoxDecoration(
                  color: task.completed ? Colors.green : Colors.transparent,
                  border: Border.all(
                    color: task.completed ? Colors.green : Colors.grey.shade400,
                    width: 2,
                  ),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: task.completed
                    ? const Icon(Icons.check, size: 18, color: Colors.white)
                    : null,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '${index + 1}. ${task.title}',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: const Color(0xFF1A1A1A),
                      decoration: task.completed ? TextDecoration.lineThrough : null,
                      decorationColor: Colors.grey,
                    ),
                  ),
                  if (task.description?.isNotEmpty == true) ...[
                    const SizedBox(height: 4),
                    Text(
                      task.description!,
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey[600],
                        decoration: task.completed ? TextDecoration.lineThrough : null,
                        decorationColor: Colors.grey,
                      ),
                    ),
                  ],
                ],
              ),
            ),
            // Status badge
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: task.completed
                    ? Colors.green.withOpacity(0.1)
                    : Colors.orange.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                task.completed ? 'Done' : 'Pending',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                  color: task.completed ? Colors.green.shade700 : Colors.orange.shade700,
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }
}