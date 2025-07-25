import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:ionicons/ionicons.dart';
import 'package:like_button/like_button.dart';
import 'package:provider/provider.dart';
import 'package:timeago/timeago.dart' as timeago;
import '../models/post.dart';
import '../models/comment.dart';
import '../services/api_services.dart';
import '../services/exceptions.dart';
import '../providers/auth_provider.dart';
import 'dart:developer' as developer;

class PostDetailScreen extends StatefulWidget {
  final String postId;
  final String postType;

  const PostDetailScreen({Key? key, required this.postId, required this.postType}) : super(key: key);

  @override
  _PostDetailScreenState createState() => _PostDetailScreenState();
}

class _PostDetailScreenState extends State<PostDetailScreen> {
  final _commentController = TextEditingController();
  Post? _post;
  List<Comment> _comments = [];
  bool _isLoading = true;
  bool _isCommenting = false;
  String? _error;
  final ApiService _apiService = ApiService();

  @override
  void initState() {
    super.initState();
    _fetchPostAndComments();
  }

  @override
  void dispose() {
    _commentController.dispose();
    _apiService.dispose();
    super.dispose();
  }

  void _fetchPostAndComments() async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    if (!authProvider.isAuthenticated || authProvider.token == null || authProvider.userId == null) {
      authProvider.handleAuthError(context, AuthenticationException('Not authenticated'));
      return;
    }
    setState(() {
      _isLoading = true;
      _error = null;
    });
    try {
      final post = await _apiService.getPostById(widget.postId, authProvider.token!);
      final comments = await _apiService.getComments(widget.postId, authProvider.token!, widget.postType);
      if (mounted) {
        setState(() {
          _post = post;
          _comments = comments;
          _isLoading = false;
        });
      }
    } catch (e) {
      developer.log('Fetch post/comments error: $e', name: 'PostDetailScreen');
      if (mounted) {
        setState(() {
          _isLoading = false;
          _error = e.toString();
        });
      }
    }
  }

  Future<bool> _onLikeButtonTapped(bool isLiked) async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final userId = authProvider.userId ?? '';
    final token = authProvider.token ?? '';
    if (userId.isEmpty || token.isEmpty) {
      authProvider.handleAuthError(context, AuthenticationException('Not authenticated'));
      return isLiked;
    }
    try {
      if (!isLiked) {
        final result = await _apiService.likePost(widget.postId, userId, token);
        if (mounted) {
          setState(() {
            _post = _post?.copyWith(numOfLikes: result['numOfLikes'] as int);
          });
        }
      }
      return !isLiked;
    } catch (e) {
      developer.log('Like post error: $e', name: 'PostDetailScreen');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to like post: $e')),
      );
      return isLiked;
    }
  }

  void _addComment() async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final userId = authProvider.userId ?? '';
    final token = authProvider.token ?? '';
    if (userId.isEmpty || token.isEmpty) {
      authProvider.handleAuthError(context, AuthenticationException('Not authenticated'));
      return;
    }
    final commentText = _commentController.text.trim();
    if (commentText.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Comment cannot be empty')),
      );
      return;
    }
    setState(() {
      _isCommenting = true;
    });
    try {
      final commentData = await _apiService.createComment(
        widget.postId,
        userId,
        commentText,
        widget.postType,
        token,
      );
      final newComment = Comment.fromJson(commentData);
      if (mounted) {
        setState(() {
          _comments = [newComment, ..._comments];
          _post = _post?.copyWith(numComments: _post!.numComments + 1);
          _commentController.clear();
          _isCommenting = false;
        });
      }
    } catch (e) {
      developer.log('Add comment error: $e', name: 'PostDetailScreen');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to comment: $e')),
      );
      if (mounted) {
        setState(() {
          _isCommenting = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }
    if (_error != null || _post == null) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('Error'),
          leading: IconButton(
            icon: const Icon(Ionicons.chevron_back),
            onPressed: () => Navigator.pop(context),
          ),
        ),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text('Error: ${_error ?? 'Post not found'}'),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: _fetchPostAndComments,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFAFCBEA),
                  foregroundColor: const Color(0xFF000000),
                ),
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
      );
    }
    return Scaffold(
      appBar: AppBar(
        title: Text('${_post!.user.username}\'s Post'),
        backgroundColor: const Color(0xFFF9F6F2),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Ionicons.chevron_back),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      CircleAvatar(
                        backgroundImage: _post!.user.profileImage.isNotEmpty
                            ? NetworkImage(_post!.user.profileImage)
                            : null,
                        backgroundColor: const Color(0xFF333333),
                        radius: 20,
                        child: _post!.user.profileImage.isEmpty
                            ? Text(
                                _post!.user.username[0].toUpperCase(),
                                style: const TextStyle(color: Colors.white),
                              )
                            : null,
                      ),
                      const SizedBox(width: 12),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            _post!.user.username,
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 18,
                              color: Color(0xFF000000),
                            ),
                          ),
                          Text(
                            timeago.format(_post!.createdAt),
                            style: const TextStyle(
                              fontSize: 12,
                              color: Color(0xFF333333),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  if (_post!.imageUrls != null && _post!.imageUrls!.isNotEmpty)
                    CachedNetworkImage(
                      imageUrl: _post!.imageUrls![0],
                      height: 300,
                      width: double.infinity,
                      fit: BoxFit.cover,
                      placeholder: (context, url) => const Center(child: CircularProgressIndicator()),
                      errorWidget: (context, url, error) => const Icon(Icons.error, size: 100),
                    ),
                  const SizedBox(height: 12),
                  Text(
                    _post!.text ?? 'No description',
                    style: const TextStyle(
                      fontSize: 16,
                      color: Color(0xFF1A1A1A),
                    ),
                  ),
                  if (widget.postType == 'goal' && _post!.tasks != null && _post!.tasks!.isNotEmpty) ...[
                    const SizedBox(height: 12),
                    const Text(
                      'Tasks',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF000000),
                      ),
                    ),
                    ..._post!.tasks!.map((task) => Padding(
                          padding: const EdgeInsets.symmetric(vertical: 4),
                          child: Text(
                            task['title']?.toString() ?? 'No title',
                            style: const TextStyle(color: Color(0xFF333333)),
                          ),
                        )),
                  ],
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Text(
                        '${_post!.numOfLikes} likes',
                        style: const TextStyle(color: Color(0xFF000000)),
                      ),
                      const SizedBox(width: 12),
                      Text(
                        '${_post!.numComments} comments',
                        style: const TextStyle(color: Color(0xFF000000)),
                      ),
                      const Spacer(),
                      if (widget.postType == 'goal')
                        LikeButton(
                          onTap: _onLikeButtonTapped,
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
                        ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'Comments',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF000000),
                    ),
                  ),
                  if (_comments.isEmpty)
                    const Center(child: Text('No comments yet')),
                  ..._comments.map((comment) => Padding(
                        padding: const EdgeInsets.symmetric(vertical: 8.0),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            CircleAvatar(
                              backgroundColor: const Color(0xFF333333),
                              radius: 20,
                              child: Text(
                                comment.username[0].toUpperCase(),
                                style: const TextStyle(color: Colors.white),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    comment.username,
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                      color: Color(0xFF000000),
                                    ),
                                  ),
                                  Text(
                                    timeago.format(comment.createdAt),
                                    style: const TextStyle(
                                      fontSize: 12,
                                      color: Color(0xFF333333),
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    comment.text,
                                    style: const TextStyle(color: Color(0xFF1A1A1A)),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      )),
                ],
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _commentController,
                    decoration: const InputDecoration(
                      labelText: 'Add a comment',
                      border: OutlineInputBorder(),
                    ),
                    maxLines: null,
                  ),
                ),
                const SizedBox(width: 8),
                _isCommenting
                    ? const CircularProgressIndicator()
                    : IconButton(
                        icon: const Icon(Icons.send),
                        onPressed: _addComment,
                      ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}