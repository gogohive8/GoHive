// widgets/home/post_card.dart
import 'package:flutter/material.dart';
import 'package:ionicons/ionicons.dart';
import 'package:like_button/like_button.dart';
import 'package:video_player/video_player.dart';
import '../../models/post.dart';
import '../../screens/post_detail_screen.dart';
import 'media_widget.dart';

class PostCard extends StatelessWidget {
  final Post post;
  final String postType;
  final Map<String, VideoPlayerController> videoControllers;
  final Function(String, bool) onLikePressed;
  final Function(String, String) onJoinEvent;
  final VoidCallback onVideoControllerUpdate;

  const PostCard({
    Key? key,
    required this.post,
    required this.postType,
    required this.videoControllers,
    required this.onLikePressed,
    required this.onJoinEvent,
    required this.onVideoControllerUpdate,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Card(
      color: const Color(0xFFDDDDDD),
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      margin: const EdgeInsets.symmetric(vertical: 8),
      child: GestureDetector(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) =>
                  PostDetailScreen(postId: post.id, postType: postType),
            ),
          );
        },
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildUserHeader(),
              const SizedBox(height: 12),
              MediaWidget(
                post: post,
                videoControllers: videoControllers,
                onVideoControllerUpdate: onVideoControllerUpdate,
              ),
              const SizedBox(height: 12),
              _buildPostText(),
              if (_shouldShowTasks()) ...[
                const SizedBox(height: 12),
                _buildTasksList(),
              ],
              const SizedBox(height: 12),
              _buildPostActions(context),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildUserHeader() {
    return Row(
      children: [
        CircleAvatar(
          backgroundImage: post.user.profileImage.isNotEmpty
              ? NetworkImage(post.user.profileImage)
              : null,
          backgroundColor: const Color(0xFF333333),
          radius: 20,
          child: post.user.profileImage.isEmpty
              ? Text(
                  post.user.username.isNotEmpty
                      ? post.user.username[0].toUpperCase()
                      : 'U',
                  style: const TextStyle(color: Colors.white),
                )
              : null,
        ),
        const SizedBox(width: 12),
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
                  color: Color(0xFF000000),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildPostText() {
    return Text(
      post.text ?? 'No description',
      style: const TextStyle(
        fontSize: 16,
        color: Color(0xFF1A1A1A),
      ),
    );
  }

  bool _shouldShowTasks() {
    return postType == 'goal' && 
           post.tasks != null && 
           post.tasks!.isNotEmpty;
  }

  Widget _buildTasksList() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Tasks',
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.bold,
            color: Color(0xFF000000),
          ),
        ),
        ...post.tasks!.map((task) => Container(
              margin: const EdgeInsets.only(bottom: 4),
              padding: const EdgeInsets.symmetric(
                horizontal: 12,
                vertical: 6,
              ),
              decoration: BoxDecoration(
                color: const Color(0xFFF9F6F2),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Text(
                task.title,
                style: const TextStyle(
                  color: Color(0xFF333333),
                  fontSize: 12,
                ),
              ),
            )),
      ],
    );
  }

  Widget _buildPostActions(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Row(
          children: [
            Text(
              '${post.numOfLikes} likes',
              style: const TextStyle(color: Color(0xFF000000)),
            ),
            const SizedBox(width: 8),
            Text(
              '${post.numComments} comments',
              style: const TextStyle(color: Color(0xFF000000)),
            ),
          ],
        ),
        _buildActionButton(context),
      ],
    );
  }

  Widget _buildActionButton(BuildContext context) {
    if (postType == 'goal') {
      return LikeButton(
        onTap: (isLiked) async {
          final result = await onLikePressed(post.id, isLiked);
          return result;
        },
        size: 25,
        circleColor: const CircleColor(
            start: Color(0xffFFC0CB), end: Color(0xffff0000)),
        bubblesColor: const BubblesColor(
          dotPrimaryColor: Color(0xffFFA500),
          dotSecondaryColor: Color(0xffd8392b),
          dotThirdColor: Color(0xffFF69B4),
          dotLastColor: Color(0xffff8c00),
        ),
        likeBuilder: (isLiked) {
          return Icon(
            isLiked ? Ionicons.heart : Ionicons.heart_outline,
            color: isLiked ? Colors.red : const Color(0xFF333333),
            size: 25,
          );
        },
      );
    } else {
      return ElevatedButton(
        onPressed: () => onJoinEvent(post.id, post.text ?? ''),
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFFAFCBEA),
          foregroundColor: const Color(0xFF000000),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
        ),
        child: const Text('Join'),
      );
    }
  }
}