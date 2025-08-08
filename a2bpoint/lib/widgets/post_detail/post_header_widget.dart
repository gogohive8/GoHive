// lib/widgets/post_detail/post_header_widget.dart
import 'package:flutter/material.dart';
import 'package:like_button/like_button.dart';
import 'package:timeago/timeago.dart' as timeago;
import '../../models/post.dart';

class PostHeaderWidget extends StatelessWidget {
  final Post post;
  final bool isAuthor;
  final Future<bool> Function(bool) onLikePressed;

  const PostHeaderWidget({
    Key? key,
    required this.post,
    required this.isAuthor,
    required this.onLikePressed,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // User info
          Row(
            children: [
              CircleAvatar(
                backgroundImage: post.user.profileImage.isNotEmpty
                    ? NetworkImage(post.user.profileImage)
                    : null,
                backgroundColor: const Color(0xFFAFCBEA),
                radius: 28,
                child: post.user.profileImage.isEmpty
                    ? Text(
                        post.user.username.isNotEmpty
                            ? post.user.username[0].toUpperCase()
                            : 'U',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      )
                    : null,
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      post.user.username.isNotEmpty
                          ? post.user.username
                          : 'Unknown User',
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 18,
                        color: Color(0xFF1A1A1A),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      timeago.format(post.createdAt),
                      style: TextStyle(
                        color: Colors.grey[600],
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              ),
              if (isAuthor)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: const Color(0xFFAFCBEA).withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: const Text(
                    'Author',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF333333),
                    ),
                  ),
                ),
            ],
          ),
          
          const SizedBox(height: 16),
          
          // Post content (using text property from Post model)
          if (post.text != null && post.text!.isNotEmpty) ...[
            Text(
              post.text!,
              style: const TextStyle(
                fontSize: 16,
                color: Color(0xFF333333),
                height: 1.5,
              ),
            ),
            const SizedBox(height: 16),
          ],
          
          // Post stats
          Row(
            children: [
              LikeButton(
                size: 24,
                likeCount: post.numOfLikes,
                isLiked: false, // Since Post model doesn't have isLiked, defaulting to false
                onTap: onLikePressed,
                likeBuilder: (isLiked) {
                  return Icon(
                    isLiked ? Icons.favorite : Icons.favorite_border,
                    color: isLiked ? Colors.red : Colors.grey[600],
                    size: 24,
                  );
                },
                countBuilder: (likeCount, isLiked, text) {
                  return Padding(
                    padding: const EdgeInsets.only(left: 8),
                    child: Text(
                      text,
                      style: TextStyle(
                        color: Colors.grey[600],
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  );
                },
              ),
              const SizedBox(width: 24),
              Icon(
                Icons.chat_bubble_outline,
                color: Colors.grey[600],
                size: 22,
              ),
              const SizedBox(width: 8),
              Text(
                post.numComments.toString(),
                style: TextStyle(
                  color: Colors.grey[600],
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const Spacer(),
              // Show post type as a badge instead of difficulty
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: _getTypeColor(post.type).withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  post.type.toUpperCase(),
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: _getTypeColor(post.type),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Color _getTypeColor(String type) {
    switch (type.toLowerCase()) {
      case 'goal':
        return Colors.blue;
      case 'event':
        return Colors.green;
      case 'journey':
        return Colors.purple;
      case 'help':
        return Colors.orange;
      default:
        return Colors.grey;
    }
  }
}