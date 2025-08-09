import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/chat.dart';
import '../../models/user.dart';
import '../../providers/chat_provider.dart';
import '../../providers/auth_provider.dart';
import '../../services/api_services.dart';

class CreateChatScreen extends StatefulWidget {
  final ChatType chatType;

  const CreateChatScreen({Key? key, required this.chatType}) : super(key: key);

  @override
  _CreateChatScreenState createState() => _CreateChatScreenState();
}

class _CreateChatScreenState extends State<CreateChatScreen> {
  final _searchController = TextEditingController();
  final ApiService _apiService = ApiService();

  List<Map<String, dynamic>> _searchResults = [];
  bool _isSearching = false;
  String _searchError = '';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _searchUsers(String query) async {
    if (query.trim().isEmpty) {
      setState(() {
        _searchResults = [];
        _isSearching = false;
        _searchError = '';
      });
      return;
    }

    setState(() {
      _isSearching = true;
      _searchError = '';
    });

    try {
      final authProvider = context.read<AuthProvider>();
      final token = authProvider.token!;
      final userId = authProvider.userId!;

      final results = await _apiService.searchUsers(
        query.trim(),
        token: token,
        userId: userId,
      );

      if (mounted) {
        setState(() {
          _searchResults = results;
          _isSearching = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _searchResults = [];
          _isSearching = false;
          _searchError = 'Error searching users: ${e.toString().split(':').last.trim()}';
        });
      }
    }
  }

  void _openChatWithUser(Map<String, dynamic> userData) async {
    final user = User(
      id: userData['userID']?.toString() ?? userData['id']?.toString() ?? '',
      username: userData['username']?.toString() ?? 'Unknown',
      profileImage: userData['profileImage']?.toString() ?? '',
    );

    // Показываем индикатор загрузки
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return Center(
          child: CircularProgressIndicator(
            valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF6B73FF)),
          ),
        );
      },
    );

    try {
      final authProvider = context.read<AuthProvider>();
      final token = authProvider.token!;

      // Создаем или находим существующий чат
      await context.read<ChatProvider>().createChat(
        user.username,
        [user.id],
        ChatType.direct,
        token,
      );

      if (mounted) {
        // Закрываем индикатор загрузки
        Navigator.pop(context);
        // Закрываем экран поиска
        Navigator.pop(context);
        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Chat with ${user.username} opened'),
            backgroundColor: Color(0xFF6B73FF),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        // Закрываем индикатор загрузки
        Navigator.pop(context);
        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error opening chat: ${e.toString().split(':').last.trim()}'),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        );
      }
    }
  }

  String _getChatTypeTitle() {
    switch (widget.chatType) {
      case ChatType.direct:
        return 'New Chat';
      case ChatType.group:
        return 'New Group';
      case ChatType.mentorship:
        return 'Mentorship Chat';
      case ChatType.conference:
        return 'Conference';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color(0xFFF4F3EE),
      appBar: AppBar(
        backgroundColor: Color(0xFFF4F3EE),
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: Colors.black87),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          _getChatTypeTitle(),
          style: TextStyle(
            color: Colors.black87,
            fontSize: 20,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      body: Column(
        children: [
          _buildUserSearch(),
          Expanded(child: _buildUserList()),
        ],
      ),
    );
  }

  Widget _buildUserSearch() {
    return Container(
      padding: EdgeInsets.all(16),
      child: TextField(
        controller: _searchController,
        decoration: InputDecoration(
          hintText: 'Search users...',
          hintStyle: TextStyle(color: Colors.grey[500]),
          filled: true,
          fillColor: Colors.white,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(25),
            borderSide: BorderSide.none,
          ),
          prefixIcon: Icon(Icons.search, color: Color(0xFF6B73FF)),
          suffixIcon: _isSearching
              ? Container(
                  width: 20,
                  height: 20,
                  padding: EdgeInsets.all(12),
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF6B73FF)),
                  ),
                )
              : _searchController.text.isNotEmpty
                  ? IconButton(
                      icon: Icon(Icons.clear, color: Colors.grey),
                      onPressed: () {
                        _searchController.clear();
                        setState(() {
                          _searchResults = [];
                          _searchError = '';
                        });
                      },
                    )
                  : null,
        ),
        onChanged: (value) {
          // Debounce search
          Future.delayed(Duration(milliseconds: 500), () {
            if (_searchController.text == value) {
              _searchUsers(value);
            }
          });
        },
      ),
    );
  }

  Widget _buildUserList() {
    if (_searchController.text.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: Colors.grey[200],
                borderRadius: BorderRadius.circular(40),
              ),
              child: Icon(
                Icons.search,
                size: 40,
                color: Colors.grey[400],
              ),
            ),
            SizedBox(height: 24),
            Text(
              'Search for users',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: Colors.black87,
              ),
            ),
            SizedBox(height: 8),
            Text(
              'Enter a username to find users',
              style: TextStyle(
                color: Colors.grey[600],
                fontSize: 14,
              ),
            ),
          ],
        ),
      );
    }

    if (_searchError.isNotEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline, size: 64, color: Colors.red),
            SizedBox(height: 16),
            Text(
              'Search Error',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: Colors.black87,
              ),
            ),
            SizedBox(height: 8),
            Text(
              _searchError,
              style: TextStyle(color: Colors.grey[600]),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: 16),
            ElevatedButton(
              onPressed: () => _searchUsers(_searchController.text),
              style: ElevatedButton.styleFrom(
                backgroundColor: Color(0xFF6B73FF),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: Text('Try Again', style: TextStyle(color: Colors.white)),
            ),
          ],
        ),
      );
    }

    if (_isSearching) {
      return Center(
        child: CircularProgressIndicator(
          valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF6B73FF)),
        ),
      );
    }

    if (_searchResults.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.people_outline,
              size: 64,
              color: Colors.grey,
            ),
            SizedBox(height: 16),
            Text(
              'No users found',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: Colors.black87,
              ),
            ),
            SizedBox(height: 8),
            Text(
              'Try a different search term',
              style: TextStyle(
                color: Colors.grey[600],
                fontSize: 14,
              ),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: EdgeInsets.symmetric(horizontal: 16),
      itemCount: _searchResults.length,
      itemBuilder: (context, index) {
        final userData = _searchResults[index];
        final username = userData['username']?.toString() ?? 'Unknown';
        final profileImage = userData['profileImage']?.toString() ?? '';
        final biography = userData['biography']?.toString() ?? '';

        return Container(
          margin: EdgeInsets.only(bottom: 8),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 4,
                offset: Offset(0, 2),
              ),
            ],
          ),
          child: ListTile(
            contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            leading: CircleAvatar(
              backgroundImage: profileImage.isNotEmpty
                  ? NetworkImage(profileImage)
                  : null,
              backgroundColor: Colors.grey[300],
              radius: 24,
              child: profileImage.isEmpty
                  ? Text(
                      username.isNotEmpty ? username[0].toUpperCase() : 'U',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                        color: Colors.black87,
                      ),
                    )
                  : null,
            ),
            title: Text(
              username,
              style: TextStyle(
                fontWeight: FontWeight.w600,
                fontSize: 16,
                color: Colors.black87,
              ),
            ),
            subtitle: biography.isNotEmpty
                ? Text(
                    biography,
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey[600],
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  )
                : null,
            trailing: Icon(
              Icons.chat_bubble_outline,
              color: Color(0xFF6B73FF),
              size: 20,
            ),
            onTap: () => _openChatWithUser(userData),
          ),
        );
      },
    );
  }
}