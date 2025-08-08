// lib/widgets/post_detail/comment_item_widget.dart
import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:timeago/timeago.dart' as timeago;
import '../../models/comment.dart';

class CommentItemWidget extends StatelessWidget {
  final Comment comment;

  const CommentItemWidget({
    Key? key,
    required this.comment,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CircleAvatar(
            backgroundColor: const Color(0xFFAFCBEA),
            radius: 18,
            child: Text(
              comment.username.isNotEmpty
                  ? comment.username[0].toUpperCase()
                  : 'U',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 14,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.grey.withOpacity(0.05),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: Colors.grey.withOpacity(0.1),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        comment.username.isNotEmpty
                            ? comment.username
                            : 'Unknown User',
                        style: const TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 14,
                          color: Color(0xFF000000),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        timeago.format(comment.createdAt),
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey[500],
                        ),
                      ),
                    ],
                  ),
                  if (comment.text.isNotEmpty) ...[
                    const SizedBox(height: 6),
                    Text(
                      comment.text,
                      style: const TextStyle(
                        fontSize: 14,
                        color: Color(0xFF1A1A1A),
                        height: 1.4,
                      ),
                    ),
                  ],
                  // Comment image
                  if (comment.imageUrl?.isNotEmpty == true) ...[
                    const SizedBox(height: 8),
                    _buildCommentImage(comment.imageUrl!),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCommentImage(String imageUrl) {
    return Container(
      margin: const EdgeInsets.only(top: 8),
      height: 150,
      width: 200,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(8),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(8),
        child: CachedNetworkImage(
          imageUrl: imageUrl,
          fit: BoxFit.cover,
          placeholder: (context, url) => Container(
            color: Colors.grey[200],
            child: const Center(
              child: CircularProgressIndicator(
                color: Color(0xFFAFCBEA),
                strokeWidth: 2,
              ),
            ),
          ),
          errorWidget: (context, url, error) => Container(
            color: Colors.grey[200],
            child: const Icon(Icons.error, color: Colors.red),
          ),
        ),
      ),
    );
  }
}