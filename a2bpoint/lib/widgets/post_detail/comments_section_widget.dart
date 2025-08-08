// lib/widgets/post_detail/comments_section_widget.dart
import 'package:flutter/material.dart';
import '../../models/comment.dart';
import 'comment_item_widget.dart';

class CommentsSectionWidget extends StatelessWidget {
  final List<Comment> comments;
  final String title;

  const CommentsSectionWidget({
    Key? key,
    required this.comments,
    this.title = 'General Comments',
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    if (comments.isEmpty) {
      return const SizedBox.shrink();
    }

    return Container(
      margin: const EdgeInsets.only(top: 24),
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
                Icons.chat_bubble_outline,
                color: Color(0xFFAFCBEA),
                size: 24,
              ),
              const SizedBox(width: 12),
              Text(
                '$title (${comments.length})',
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF1A1A1A),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          ...comments.map((comment) => CommentItemWidget(comment: comment)),
        ],
      ),
    );
  }
}