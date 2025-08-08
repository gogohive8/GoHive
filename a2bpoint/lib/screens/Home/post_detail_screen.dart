// lib/screens/post_detail_screen.dart
import 'package:flutter/material.dart';
import 'package:ionicons/ionicons.dart';
import 'package:provider/provider.dart';
import 'dart:convert';
import 'dart:io';
import 'package:image_picker/image_picker.dart';
import 'dart:developer' as developer;

import '../../models/post.dart';
import '../../models/comment.dart';
import '../../models/tasks.dart';
import '../../services/api_services.dart';
import '../../services/post_service.dart';
import '../../services/comment_service.dart';
import '../../providers/auth_provider.dart';

// Import widgets
import '../../widgets/post_detail/post_header_widget.dart';
import '../../widgets/post_detail/post_media_widget.dart';
import '../../widgets/post_detail/task_list_widget.dart';
import '../../widgets/post_detail/comments_section_widget.dart';
import '../../widgets/post_detail/comment_input_widget.dart';

class PostDetailScreen extends StatefulWidget {
  final String postId;
  final String postType;

  const PostDetailScreen({
    Key? key,
    required this.postId,
    required this.postType,
  }) : super(key: key);

  @override
  _PostDetailScreenState createState() => _PostDetailScreenState();
}

class _PostDetailScreenState extends State<PostDetailScreen> {
  final _commentController = TextEditingController();
  final _taskCommentControllers = <String, TextEditingController>{};
  Post? _post;
  List<Comment> _comments = [];
  Map<String, List<Comment>> _taskComments = {};
  bool _isLoading = true;
  bool _isCommenting = false;
  String? _error;
  File? _selectedImage;
  final ImagePicker _picker = ImagePicker();
  
  final ApiService _apiService = ApiService();
  final PostService _postService = PostService();
  final CommentService _commentService = CommentService();

  @override
  void initState() {
    super.initState();
    _fetchPostAndComments();
  }

  @override
  void dispose() {
    _commentController.dispose();
    for (var controller in _taskCommentControllers.values) {
      controller.dispose();
    }
    _apiService.dispose();
    super.dispose();
  }

  Future<void> _fetchPostAndComments() async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);

    if (!authProvider.isAuthenticated ||
        authProvider.token == null ||
        authProvider.userId == null) {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _error = 'Not authenticated';
        });
      }
      return;
    }

    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      developer.log('Fetching post ${widget.postId} and comments',
          name: 'PostDetailScreen');

      // Fetch post details
      final post =
          await _postService.getPostById(widget.postId, authProvider.token!);

      // Fetch comments
      final comments = await _commentService.getComments(
          widget.postId, authProvider.token!, widget.postType);

      // Initialize task comment controllers
      if (post.tasks != null) {
        for (var task in post.tasks!) {
          _taskCommentControllers[task.id] = TextEditingController();
        }
      }

      // Group comments by task
      _taskComments.clear();
      _taskComments['general'] = []; // Общие комментарии к посту
      
      for (var comment in comments) {
        final taskId = comment.taskId ?? 'general';
        if (!_taskComments.containsKey(taskId)) {
          _taskComments[taskId] = [];
        }
        _taskComments[taskId]!.add(comment);
      }

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
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Please login to like posts')),
        );
      }
      return isLiked;
    }

    try {
      if (!isLiked) {
        final result =
            await _postService.likePost(widget.postId, userId, token);
        if (mounted && _post != null) {
          setState(() {
            _post = _post!.copyWith(
                numOfLikes:
                    result['numOfLikes'] as int? ?? _post!.numOfLikes + 1);
          });
        }
      }
      return !isLiked;
    } catch (e) {
      developer.log('Like post error: $e', name: 'PostDetailScreen');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to like post: $e')),
        );
      }
      return isLiked;
    }
  }

  void _toggleTaskCompletion(String taskId, bool completed) async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final userId = authProvider.userId ?? '';
    final token = authProvider.token ?? '';
    
    // Проверяем, является ли пользователь автором поста
    if (userId != _post?.user.id) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Only the post author can mark tasks as completed'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    try {
      // Обновляем локальное состояние сразу для быстрого отклика
      if (mounted && _post != null) {
        setState(() {
          final updatedTasks = _post!.tasks!.map((task) {
            if (task.id == taskId) {
              return task.copyWith(completed: completed);
            }
            return task;
          }).toList();
          _post = _post!.copyWith(tasks: updatedTasks);
        });
      }

      developer.log('Task $taskId marked as ${completed ? "completed" : "incomplete"}', 
          name: 'PostDetailScreen');
      
    } catch (e) {
      developer.log('Update task error: $e', name: 'PostDetailScreen');
      // Откатываем изменения в случае ошибки
      if (mounted && _post != null) {
        setState(() {
          final updatedTasks = _post!.tasks!.map((task) {
            if (task.id == taskId) {
              return task.copyWith(completed: !completed);
            }
            return task;
          }).toList();
          _post = _post!.copyWith(tasks: updatedTasks);
        });
      }
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to update task: $e')),
      );
    }
  }

  Future<void> _pickImage() async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final userId = authProvider.userId ?? '';
    
    // Только автор поста может добавлять изображения
    if (userId != _post?.user.id) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Only the post author can add images to comments'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    final XFile? image = await _picker.pickImage(
      source: ImageSource.gallery,
      maxWidth: 1024,
      maxHeight: 1024,
      imageQuality: 80,
    );
    
    if (image != null) {
      setState(() {
        _selectedImage = File(image.path);
      });
    }
  }

  void _removeSelectedImage() {
    setState(() {
      _selectedImage = null;
    });
  }

  void _addComment({String? taskId}) async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final userId = authProvider.userId ?? '';
    final token = authProvider.token ?? '';

    if (userId.isEmpty || token.isEmpty) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Please login to comment')),
        );
      }
      return;
    }

    final controller = taskId != null 
        ? _taskCommentControllers[taskId]! 
        : _commentController;
    final commentText = controller.text.trim();
    
    if (commentText.isEmpty && _selectedImage == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Comment cannot be empty')),
      );
      return;
    }

    setState(() {
      _isCommenting = true;
    });

    try {
      String? imageUrl;
      if (_selectedImage != null) {
        // Загружаем изображение сначала
        imageUrl = await _postService.uploadMedia(_selectedImage!, token);
      }

      // Создаем комментарий
      final commentData = await _commentService.createComment(
        widget.postId,
        userId,
        commentText,
        widget.postType,
        token,
      );

      // Создаем новый комментарий с дополнительными данными
      final newComment = Comment.fromJson({
        ...commentData,
        'task_id': taskId,
        'image_url': imageUrl,
      });

      if (mounted && _post != null) {
        setState(() {
          final targetTaskId = taskId ?? 'general';
          if (!_taskComments.containsKey(targetTaskId)) {
            _taskComments[targetTaskId] = [];
          }
          _taskComments[targetTaskId]!.insert(0, newComment);
          
          _post = _post!.copyWith(numComments: _post!.numComments + 1);
          controller.clear();
          _selectedImage = null;
          _isCommenting = false;
        });

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Comment added successfully'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      developer.log('Add comment error: $e', name: 'PostDetailScreen');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to comment: $e')),
        );
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
        backgroundColor: Color(0xFFF9F6F2),
        body: Center(
          child: CircularProgressIndicator(color: Color(0xFFAFCBEA)),
        ),
      );
    }

    if (_error != null || _post == null) {
      return Scaffold(
        backgroundColor: const Color(0xFFF9F6F2),
        appBar: AppBar(
          title: const Text('Error'),
          backgroundColor: const Color(0xFFF9F6F2),
          leading: IconButton(
            icon: const Icon(Ionicons.chevron_back),
            onPressed: () => Navigator.pop(context),
          ),
        ),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.error_outline, size: 64, color: Colors.red[300]),
              const SizedBox(height: 16),
              const Text(
                'Error loading post',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              Text(
                _error ?? 'Post not found',
                textAlign: TextAlign.center,
                style: const TextStyle(color: Colors.grey),
              ),
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

    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final isAuthor = authProvider.userId == _post?.user.id;
    final generalComments = _taskComments['general'] ?? [];

    return Scaffold(
      backgroundColor: const Color(0xFFF9F6F2),
      appBar: AppBar(
        title: Text('${_post!.user.username}\'s Goal'),
        backgroundColor: const Color(0xFFF9F6F2),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Ionicons.chevron_back),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          if (isAuthor)
            Container(
              margin: const EdgeInsets.only(right: 16),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: const Color(0xFFAFCBEA).withOpacity(0.2),
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
      body: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Post header
                  PostHeaderWidget(
                    post: _post!,
                    isAuthor: isAuthor,
                    onLikePressed: _onLikeButtonTapped,
                  ),

                  // Post media
                  PostMediaWidget(imageUrls: _post!.imageUrls),

                  // Task list
                  TaskListWidget(
                    tasks: _post!.tasks,
                    isAuthor: isAuthor,
                    taskComments: _taskComments,
                    taskCommentControllers: _taskCommentControllers,
                    isCommenting: _isCommenting,
                    onToggleTaskCompletion: _toggleTaskCompletion,
                    onAddTaskComment: (taskId) => _addComment(taskId: taskId),
                    onPickImage: _pickImage,
                    selectedImage: _selectedImage,
                    onRemoveImage: _removeSelectedImage,
                  ),

                  // General comments
                  CommentsSectionWidget(
                    comments: generalComments,
                    title: 'General Comments',
                  ),
                ],
              ),
            ),
          ),

          // Bottom comment input for general comments
          CommentInputWidget(
            controller: _commentController,
            isLoading: _isCommenting,
            isAuthor: isAuthor,
            hintText: 'Add a general comment...',
            onSend: () => _addComment(),
            onPickImage: _pickImage,
            selectedImage: _selectedImage,
            onRemoveImage: _removeSelectedImage,
          ),
        ],
      ),
    );
  }
}