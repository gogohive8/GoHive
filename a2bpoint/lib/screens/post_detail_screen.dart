import 'package:a2bpoint/models/user.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:video_player/video_player.dart';
import 'dart:developer' as developer;
import '../models/post.dart';
import '../models/comment.dart';
import '../services/api_services.dart';
import '../services/exceptions.dart';
import '../providers/auth_provider.dart';
import '../providers/posts_provider.dart';

class PostDetailScreen extends StatefulWidget {
  final Post post;

  const PostDetailScreen({super.key, required this.post});

  @override
  _PostDetailScreenState createState() => _PostDetailScreenState();
}

class _PostDetailScreenState extends State<PostDetailScreen> {
  final ApiService _apiService = ApiService();
  late Future<List<Comment>> _commentsFuture;
  final TextEditingController _commentController = TextEditingController();
  VideoPlayerController? _videoController;
  bool _isLoading = false;
  String? _error;
  int _offset = 0;
  final int _limit = 10;
  List<Comment> _comments = [];
  bool _isLiked = false;
  int _likes = 0;

  @override
  void initState() {
    super.initState();
    _likes = widget.post.likes;
    _isLiked =
        false; // Можно добавить API-проверку лайка для текущего пользователя
    _fetchComments();
  }

  @override
  void dispose() {
    _videoController?.dispose();
    _commentController.dispose();
    super.dispose();
  }

  void _fetchComments() {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    if (!authProvider.isAuthenticated || authProvider.token == null) {
      authProvider.handleAuthError(
          context, AuthenticationException('Not authenticated'));
      return;
    }
    _commentsFuture = _apiService
        .getComments(widget.post.id, authProvider.token!,
            limit: _limit, offset: _offset)
        .then((comments) {
      setState(() {
        _comments.addAll(comments);
        _offset += comments.length;
      });
      return _comments;
    }).catchError((e, stackTrace) {
      developer.log('Fetch comments error: $e',
          name: 'PostDetailScreen', stackTrace: stackTrace);
      setState(() {
        _error = e.toString();
      });
      return _comments;
    });
  }

  void _likePost() async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final postsProvider = Provider.of<PostsProvider>(context, listen: false);
    if (!authProvider.isAuthenticated || authProvider.token == null) {
      authProvider.handleAuthError(
          context, AuthenticationException('Not authenticated'));
      return;
    }
    try {
      setState(() {
        _isLoading = true;
      });
      await _apiService.likePost(widget.post.id, authProvider.token!);
      setState(() {
        _isLiked = !_isLiked;
        _likes = _isLiked ? _likes + 1 : _likes - 1;
        postsProvider.likePost(widget.post.id, _isLiked, widget.post.likes);
      });
    } catch (e, stackTrace) {
      developer.log('Like post error: $e',
          name: 'PostDetailScreen', stackTrace: stackTrace);
      authProvider.handleAuthError(context, e);
      setState(() {
        _error = e.toString();
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Ошибка лайка: $e')),
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _addComment() async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final postsProvider = Provider.of<PostsProvider>(context, listen: false);
    if (!authProvider.isAuthenticated || authProvider.token == null) {
      authProvider.handleAuthError(
          context, AuthenticationException('Not authenticated'));
      return;
    }
    if (_commentController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Введите текст комментария')),
      );
      return;
    }
    try {
      setState(() {
        _isLoading = true;
      });
      await _apiService.createComment(
          widget.post.id, _commentController.text, authProvider.token!);
      await postsProvider.addComment(widget.post.id);
      setState(() {
        _comments.insert(
          0,
          Comment(
            id: 'temp-${DateTime.now().millisecondsSinceEpoch}',
            user: User(
              id: authProvider.userId ?? 'unknown',
              username: authProvider.username ?? 'Unknown',
              avatarUrl: '',
            ),
            text: _commentController.text,
            createdAt: DateTime.now(),
          ),
        );
        _commentController.clear();
      });
      _fetchComments(); // Перезагрузка комментариев для синхронизации
    } catch (e, stackTrace) {
      developer.log('Add comment error: $e',
          name: 'PostDetailScreen', stackTrace: stackTrace);
      authProvider.handleAuthError(context, e);
      setState(() {
        _error = e.toString();
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Ошибка добавления комментария: $e')),
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Widget _buildMediaWidget() {
    if (widget.post.imageUrls == null || widget.post.imageUrls!.isEmpty) {
      return const SizedBox.shrink();
    }
    final url = widget.post.imageUrls![0];
    final isVideo = url.endsWith('.mp4') || url.endsWith('.mov');
    if (isVideo) {
      _videoController ??= VideoPlayerController.networkUrl(Uri.parse(url))
        ..initialize().then((_) => setState(() {}));
      return _videoController!.value.isInitialized
          ? Stack(
              alignment: Alignment.center,
              children: [
                VideoPlayer(_videoController!),
                IconButton(
                  icon: Icon(
                    _videoController!.value.isPlaying
                        ? Icons.pause
                        : Icons.play_arrow,
                    color: Colors.white,
                    size: 50,
                  ),
                  onPressed: () {
                    setState(() {
                      _videoController!.value.isPlaying
                          ? _videoController!.pause()
                          : _videoController!.play();
                    });
                  },
                ),
              ],
            )
          : const Center(child: CircularProgressIndicator());
    }
    return Image.network(
      url,
      width: double.infinity,
      height: 300,
      fit: BoxFit.cover,
      errorBuilder: (context, error, stackTrace) {
        developer.log('Image load error: $error', name: 'PostDetailScreen');
        return const Icon(Icons.broken_image, size: 100);
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF9F6F2),
      appBar: AppBar(
        elevation: 0,
        backgroundColor: const Color(0xFFF9F6F2),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Color(0xFF333333)),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          widget.post.user.username,
          style: const TextStyle(color: Color(0xFF000000)),
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildMediaWidget(),
                  const SizedBox(height: 16),
                  Text(
                    widget.post.text ?? 'Описание отсутствует',
                    style: const TextStyle(
                      fontSize: 16,
                      color: Color(0xFF1A1A1A),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      CircleAvatar(
                        backgroundImage: widget.post.user.avatarUrl.isNotEmpty
                            ? NetworkImage(widget.post.user.avatarUrl)
                            : null,
                        backgroundColor: const Color(0xFF333333),
                        radius: 20,
                        child: widget.post.user.avatarUrl.isEmpty
                            ? Text(
                                widget.post.user.username[0].toUpperCase(),
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
                              widget.post.user.username,
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF000000),
                              ),
                            ),
                            Text(
                              widget.post.createdAt
                                  .toLocal()
                                  .toString()
                                  .split('.')[0],
                              style: const TextStyle(
                                fontSize: 12,
                                color: Color(0xFF333333),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      IconButton(
                        icon: Icon(
                          _isLiked ? Icons.favorite : Icons.favorite_border,
                          color:
                              _isLiked ? Colors.red : const Color(0xFF333333),
                        ),
                        onPressed: _likePost,
                      ),
                      Text(
                        '$_likes',
                        style: const TextStyle(color: Color(0xFF000000)),
                      ),
                      const SizedBox(width: 16),
                      const Icon(Icons.comment, color: Color(0xFF333333)),
                      const SizedBox(width: 8),
                      Text(
                        '${widget.post.numComments}',
                        style: const TextStyle(color: Color(0xFF000000)),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'Комментарии',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF000000),
                    ),
                  ),
                  FutureBuilder<List<Comment>>(
                    future: _commentsFuture,
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return const Center(child: CircularProgressIndicator());
                      }
                      if (snapshot.hasError) {
                        return Text(
                            'Ошибка загрузки комментариев: ${snapshot.error}');
                      }
                      return ListView.builder(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: _comments.length + 1,
                        itemBuilder: (context, index) {
                          if (index == _comments.length) {
                            return _comments.length >= _offset
                                ? TextButton(
                                    onPressed: _fetchComments,
                                    child: const Text('Загрузить ещё'),
                                  )
                                : const SizedBox.shrink();
                          }
                          final comment = _comments[index];
                          return ListTile(
                            leading: CircleAvatar(
                              backgroundColor: const Color(0xFF333333),
                              child: Text(
                                comment.user.username[0].toUpperCase(),
                                style: const TextStyle(color: Colors.white),
                              ),
                            ),
                            title: Text(
                              comment.user.username,
                              style:
                                  const TextStyle(fontWeight: FontWeight.bold),
                            ),
                            subtitle: Text(comment.text),
                            trailing: Text(
                              comment.createdAt
                                  .toLocal()
                                  .toString()
                                  .split('.')[0],
                              style: const TextStyle(
                                  fontSize: 12, color: Color(0xFF333333)),
                            ),
                          );
                        },
                      );
                    },
                  ),
                  if (_error != null)
                    Padding(
                      padding: const EdgeInsets.only(top: 8),
                      child: Text(
                        _error!,
                        style: const TextStyle(color: Colors.red),
                      ),
                    ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _commentController,
                          decoration: InputDecoration(
                            hintText: 'Добавить комментарий...',
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                            filled: true,
                            fillColor: const Color.fromRGBO(221, 221, 221, 0.2),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      IconButton(
                        icon: const Icon(Icons.send, color: Color(0xFFAFCBEA)),
                        onPressed: _addComment,
                      ),
                    ],
                  ),
                ],
              ),
            ),
    );
  }
}
