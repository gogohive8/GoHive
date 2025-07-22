import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../providers/posts_provider.dart';
import '../models/post.dart';
import 'dart:developer' as developer;

class PostDetailScreen extends StatefulWidget {
  final String post_id;

  const PostDetailScreen({Key? key, required this.post_id}) : super(key: key);

  @override
  _PostDetailScreenState createState() => _PostDetailScreenState();
}

class _PostDetailScreenState extends State<PostDetailScreen> {
  final _commentController = TextEditingController();
  bool _isLoading = false;

  Future<void> _addComment() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final postsProvider = Provider.of<PostsProvider>(context, listen: false);

      if (!authProvider.isAuthenticated) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Please sign in to comment')),
        );
        return;
      }

      final commentText = _commentController.text;
      if (commentText.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Comment cannot be empty')),
        );
        return;
      }

      await postsProvider.addComment(
        widget.post_id,
        authProvider.userId!,
        commentText,
        authProvider.token!,
      );
      _commentController.clear();
      developer.log('Comment added successfully for post_id: ${widget.post_id}',
          name: 'PostDetailScreen');
    } catch (e, stackTrace) {
      developer.log('Error adding comment: $e',
          name: 'PostDetailScreen', stackTrace: stackTrace);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Failed to add comment')),
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  void dispose() {
    _commentController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final postsProvider = Provider.of<PostsProvider>(context);
    final post = postsProvider.posts.firstWhere(
      (post) => post.id == widget.post_id,
      orElse: () => Post(
        id: widget.post_id,
        user: User(id: 'unknown', username: 'Unknown', profileImage: ''),
        type: 'goal',
        numOfLikes: 0,
        numComments: 0,
        createdAt: DateTime.now(),
      ),
    );

    return Scaffold(
      appBar: AppBar(title: const Text('Post Details')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Post by ${post.user.username}',
                style:
                    const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8.0),
            Text(post.text ?? 'No description'),
            const SizedBox(height: 16.0),
            TextField(
              controller: _commentController,
              decoration: const InputDecoration(
                labelText: 'Add a comment',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 8.0),
            _isLoading
                ? const CircularProgressIndicator()
                : ElevatedButton(
                    onPressed: _addComment,
                    child: const Text('Post Comment'),
                  ),
          ],
        ),
      ),
    );
  }
}
