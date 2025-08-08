// widgets/home/posts_view.dart
import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';
import '../../models/post.dart';
import 'post_card.dart';

class PostsView extends StatelessWidget {
  final String postType;
  final List<Post> posts;
  final ScrollController scrollController;
  final bool isLoading;
  final bool isLoadingMore;
  final bool hasMore;
  final bool isTabLoaded;
  final String? error;
  final Map<String, VideoPlayerController> videoControllers;
  final VoidCallback onRefresh;
  final VoidCallback onRetry;
  final VoidCallback onVideoControllerUpdate;
  final Function(String, bool) onLikePressed;
  final Function(String, String) onJoinEvent;

  const PostsView({
    Key? key,
    required this.postType,
    required this.posts,
    required this.scrollController,
    required this.isLoading,
    required this.isLoadingMore,
    required this.hasMore,
    required this.isTabLoaded,
    this.error,
    required this.videoControllers,
    required this.onRefresh,
    required this.onRetry,
    required this.onVideoControllerUpdate,
    required this.onLikePressed,
    required this.onJoinEvent,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    if (!isTabLoaded && posts.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }

    if (isLoading && posts.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }

    if (error != null && posts.isEmpty) {
      return _buildErrorView();
    }

    if (posts.isEmpty && isTabLoaded) {
      return _buildEmptyView();
    }

    return RefreshIndicator(
      onRefresh: () async => onRefresh(),
      child: ListView.builder(
        controller: scrollController,
        padding: const EdgeInsets.all(16),
        itemCount: posts.length + (isLoadingMore ? 1 : 0),
        itemBuilder: (context, index) {
          if (index == posts.length) {
            return hasMore
                ? const Padding(
                    padding: EdgeInsets.all(16.0),
                    child: Center(child: CircularProgressIndicator()),
                  )
                : const SizedBox.shrink();
          }

          final post = posts[index];
          return PostCard(
            post: post,
            postType: postType,
            videoControllers: videoControllers,
            onLikePressed: onLikePressed,
            onJoinEvent: onJoinEvent,
            onVideoControllerUpdate: onVideoControllerUpdate,
          );
        },
      ),
    );
  }

  Widget _buildErrorView() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.error_outline, size: 64, color: Colors.red[300]),
          const SizedBox(height: 16),
          Text(
            'Error loading $postType',
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          Text(
            error!,
            textAlign: TextAlign.center,
            style: const TextStyle(color: Colors.grey),
          ),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: onRetry,
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFAFCBEA),
              foregroundColor: const Color(0xFF000000),
            ),
            child: const Text('Retry'),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyView() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.inbox, size: 64, color: Colors.grey[400]),
          const SizedBox(height: 16),
          Text(
            'No $postType to display',
            style: TextStyle(fontSize: 18, color: Colors.grey[600]),
          ),
          const SizedBox(height: 8),
          Text(
            'Be the first to create a ${postType.toLowerCase()}!',
            style: TextStyle(color: Colors.grey[500]),
          ),
        ],
      ),
    );
  }
}