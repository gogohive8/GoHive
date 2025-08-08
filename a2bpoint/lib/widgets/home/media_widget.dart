// widgets/home/media_widget.dart
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';
import '../../models/post.dart';
import 'dart:developer' as developer;

class MediaWidget extends StatefulWidget {
  final Post post;
  final Map<String, VideoPlayerController> videoControllers;
  final VoidCallback onVideoControllerUpdate;

  const MediaWidget({
    Key? key,
    required this.post,
    required this.videoControllers,
    required this.onVideoControllerUpdate,
  }) : super(key: key);

  @override
  State<MediaWidget> createState() => _MediaWidgetState();
}

class _MediaWidgetState extends State<MediaWidget> {
  @override
  Widget build(BuildContext context) {
    if (widget.post.imageUrls == null || widget.post.imageUrls!.isEmpty) {
      return const SizedBox.shrink();
    }

    String cleanUrl = widget.post.imageUrls![0];
    if (cleanUrl.startsWith('[') && cleanUrl.endsWith(']')) {
      cleanUrl = cleanUrl.substring(1, cleanUrl.length - 1);
    }
    cleanUrl = cleanUrl.trim();

    if (!cleanUrl.startsWith('http://') && !cleanUrl.startsWith('https://')) {
      developer.log('Invalid URL format: $cleanUrl', name: 'MediaWidget');
      return _buildErrorContainer('Invalid image URL');
    }

    developer.log('Loading cleaned media: $cleanUrl', name: 'MediaWidget');

    final isVideo = _isVideoUrl(cleanUrl);

    if (isVideo) {
      return _buildVideoPlayer(cleanUrl);
    }

    return _buildCachedImage(cleanUrl);
  }

  bool _isVideoUrl(String url) {
    return url.toLowerCase().endsWith('.mp4') ||
        url.toLowerCase().endsWith('.mov') ||
        url.toLowerCase().endsWith('.avi');
  }

  Widget _buildVideoPlayer(String url) {
    if (!widget.videoControllers.containsKey(widget.post.id)) {
      widget.videoControllers[widget.post.id] =
          VideoPlayerController.networkUrl(Uri.parse(url))
            ..initialize().then((_) {
              widget.onVideoControllerUpdate();
            });
    }

    final controller = widget.videoControllers[widget.post.id]!;
    
    return controller.value.isInitialized
        ? Stack(
            alignment: Alignment.center,
            children: [
              AspectRatio(
                aspectRatio: controller.value.aspectRatio,
                child: VideoPlayer(controller),
              ),
              IconButton(
                icon: Icon(
                  controller.value.isPlaying ? Icons.pause : Icons.play_arrow,
                  color: Colors.white,
                  size: 50,
                ),
                onPressed: () {
                  setState(() {
                    controller.value.isPlaying
                        ? controller.pause()
                        : controller.play();
                  });
                },
              ),
            ],
          )
        : Container(
            height: 200,
            child: const Center(child: CircularProgressIndicator()),
          );
  }

  Widget _buildCachedImage(String url) {
    return CachedNetworkImage(
      imageUrl: url,
      height: 200,
      width: double.infinity,
      fit: BoxFit.cover,
      placeholder: (context, url) => Container(
        height: 200,
        child: const Center(child: CircularProgressIndicator()),
      ),
      errorWidget: (context, url, error) {
        developer.log('Image load error: $error for URL: $url',
            name: 'MediaWidget');
        return _buildErrorContainer('Image not available');
      },
      httpHeaders: const {
        'User-Agent': 'Flutter App',
      },
    );
  }

  Widget _buildErrorContainer(String message) {
    return Container(
      height: 200,
      color: Colors.grey[300],
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.broken_image, size: 50, color: Colors.grey),
          const SizedBox(height: 8),
          Text(message, style: TextStyle(color: Colors.grey)),
        ],
      ),
    );
  }
}