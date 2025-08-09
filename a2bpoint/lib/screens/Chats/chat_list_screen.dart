import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/chat.dart';
import '../../providers/chat_provider.dart';
import '../../providers/auth_provider.dart';
import '../../services/api_services.dart';
import 'chat_screen.dart';
import 'create_chat_screen.dart';
import '../AI_mentor/ai_mentor_screen.dart';

class ChatListScreen extends StatefulWidget {
  @override
  _ChatListScreenState createState() => _ChatListScreenState();
}

class _ChatListScreenState extends State<ChatListScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final TextEditingController _searchController = TextEditingController();
  final ApiService _apiService = ApiService();
  final Map<String, Map<String, dynamic>> _userProfiles = {};
  bool _isSearching = false;
  bool _isLoadingProfiles = false;
  List<Chat> _filteredChats = [];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _tabController.addListener(() {
      setState(() {});
    });

    WidgetsBinding.instance.addPostFrameCallback((_) {
      final authProvider = context.read<AuthProvider>();
      final token = authProvider.token;
      if (token != null) {
        context.read<ChatProvider>().initialize().then((_) {
          context.read<ChatProvider>().loadChats(token);
          _loadUserProfiles();
        });
      } else {
        Navigator.pushReplacementNamed(context, '/login');
      }
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadUserProfiles() async {
    if (_isLoadingProfiles) return;
    
    setState(() => _isLoadingProfiles = true);
    
    try {
      final authProvider = context.read<AuthProvider>();
      final chatProvider = context.read<ChatProvider>();
      
      final Set<String> allParticipants = {};
      for (final chat in chatProvider.chats) {
        allParticipants.addAll(chat.participants);
      }
      
      allParticipants.remove(authProvider.userId);
      
      for (final participantId in allParticipants) {
        if (!_userProfiles.containsKey(participantId)) {
          try {
            final profile = await _apiService.getProfile(
              participantId, 
              authProvider.token!
            );
            _userProfiles[participantId] = profile;
          } catch (e) {
            print('Error loading profile for $participantId: $e');
            _userProfiles[participantId] = {
              'username': 'User',
              'avatar': '',
              'userId': participantId,
            };
          }
        }
      }
    } catch (e) {
      print('Error loading user profiles: $e');
    } finally {
      setState(() => _isLoadingProfiles = false);
    }
  }

  void _startSearch() {
    setState(() {
      _isSearching = true;
    });
  }

  void _stopSearch() {
    setState(() {
      _isSearching = false;
      _searchController.clear();
      _filteredChats.clear();
    });
  }

  void _onSearchChanged(String query) {
    final chatProvider = context.read<ChatProvider>();
    setState(() {
      _filteredChats = chatProvider.searchChats(query);
    });
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = context.watch<AuthProvider>();
    final token = authProvider.token;

    if (token == null) {
      return Scaffold(
        backgroundColor: Color(0xFFF4F3EE),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.lock, size: 64, color: Colors.grey),
              SizedBox(height: 16),
              Text(
                'Please log in',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: Colors.black87,
                ),
              ),
              SizedBox(height: 16),
              ElevatedButton(
                onPressed: () => Navigator.pushReplacementNamed(context, '/login'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Color(0xFF6B73FF),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: Text('Login', style: TextStyle(color: Colors.white)),
              ),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: Color(0xFFF4F3EE),
      appBar: AppBar(
        backgroundColor: Color(0xFFF4F3EE),
        elevation: 0,
        toolbarHeight: 80,
        automaticallyImplyLeading: false,
        title: Container(
          child: Row(
            children: [
              // Кнопка назад
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.1),
                      blurRadius: 4,
                      offset: Offset(0, 2),
                    ),
                  ],
                ),
                child: IconButton(
                  icon: Icon(Icons.arrow_back_ios, color: Colors.black87, size: 18),
                  onPressed: () => Navigator.pop(context),
                  padding: EdgeInsets.zero,
                ),
              ),
              
              SizedBox(width: 16),
              
              // Табы (All, Unread)
              Expanded(
                child: Row(
                  children: [
                    _buildTabButton('All', 0),
                    SizedBox(width: 12),
                    _buildTabButton('Unread', 1),
                  ],
                ),
              ),
              
              SizedBox(width: 16),
              
              // AI Mentor кнопка
              GestureDetector(
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => AIMentorScreen(),
                    ),
                  );
                },
                child: Container(
                  padding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.1),
                        blurRadius: 4,
                        offset: Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 20,
                        height: 20,
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [Color(0xFF6B73FF), Color(0xFF9A4CEE)],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Icon(
                          Icons.auto_awesome,
                          color: Colors.white,
                          size: 12,
                        ),
                      ),
                      SizedBox(width: 8),
                      Text(
                        'AI mentor',
                        style: TextStyle(
                          color: Colors.black87,
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
      body: Consumer<ChatProvider>(
        builder: (context, chatProvider, child) {
          if (chatProvider.isLoading || _isLoadingProfiles) {
            return Center(
              child: CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF6B73FF)),
              ),
            );
          }

          if (chatProvider.error != null) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.error_outline, size: 64, color: Colors.grey),
                  SizedBox(height: 16),
                  Text(
                    'Error loading chats',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                      color: Colors.black87,
                    ),
                  ),
                  SizedBox(height: 8),
                  Text(
                    chatProvider.error!,
                    style: TextStyle(color: Colors.grey[600]),
                    textAlign: TextAlign.center,
                  ),
                  SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () {
                      chatProvider.loadChats(token);
                      _loadUserProfiles();
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Color(0xFF6B73FF),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: Text('Try again', style: TextStyle(color: Colors.white)),
                  ),
                ],
              ),
            );
          }

          if (_isSearching) {
            return _buildSearchResults(_filteredChats);
          }

          return TabBarView(
            controller: _tabController,
            children: [
              _buildChatList(chatProvider.chats),
              _buildChatList(chatProvider.getUnreadChats()),
            ],
          );
        },
      ),
      floatingActionButton: Container(
        width: 56,
        height: 56,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFF6B73FF), Color(0xFF9A4CEE)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(28),
          boxShadow: [
            BoxShadow(
              color: Color(0xFF6B73FF).withOpacity(0.3),
              blurRadius: 12,
              offset: Offset(0, 6),
            ),
          ],
        ),
        child: IconButton(
          onPressed: () => _createNewChat(ChatType.direct),
          icon: Icon(Icons.chat_outlined, color: Colors.white, size: 24),
        ),
      ),
    );
  }

  Widget _buildTabButton(String text, int index) {
    final isSelected = _tabController.index == index;
    
    return GestureDetector(
      onTap: () {
        _tabController.animateTo(index);
      },
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected 
            ? Color(0x1F5F93E6) // #5F93E6 с прозрачностью 12%
            : Colors.transparent,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(
          text,
          style: TextStyle(
            color: isSelected ? Color(0xFF5F93E6) : Colors.grey[600],
            fontWeight: FontWeight.w500,
            fontSize: 14,
          ),
        ),
      ),
    );
  }

  Widget _buildChatList(List<Chat> chats) {
    if (chats.isEmpty) {
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
                Icons.chat_bubble_outline,
                size: 40,
                color: Colors.grey[400],
              ),
            ),
            SizedBox(height: 24),
            Text(
              'No chats yet',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: Colors.black87,
              ),
            ),
            SizedBox(height: 8),
            Text(
              'Start a new conversation!',
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
      padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      itemCount: chats.length,
      itemBuilder: (context, index) {
        final chat = chats[index];
        return _buildChatTile(chat);
      },
    );
  }

  Widget _buildSearchResults(List<Chat> results) {
    if (results.isEmpty && _searchController.text.isNotEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.search_off, size: 64, color: Colors.grey),
            SizedBox(height: 16),
            Text(
              'Nothing found',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: Colors.black87,
              ),
            ),
          ],
        ),
      );
    }

    return _buildChatList(results);
  }

  Widget _buildChatTile(Chat chat) {
    final token = context.read<AuthProvider>().token!;
    final currentUserId = context.read<AuthProvider>().userId;
    
    // Находим другого участника чата
    final otherParticipantId = chat.participants
        .firstWhere((id) => id != currentUserId, orElse: () => '');
    
    // Получаем данные профиля
    final userProfile = _userProfiles[otherParticipantId];
    final displayName = userProfile?['username'] ?? chat.name;
    final avatarUrl = userProfile?['avatar'] ?? chat.avatar;

    return Dismissible(
      key: Key(chat.id),
      direction: DismissDirection.endToStart,
      background: Container(
        color: Colors.red.withOpacity(0.2),
        alignment: Alignment.centerRight,
        padding: EdgeInsets.only(right: 20),
        child: Icon(Icons.delete, color: Colors.red),
      ),
      confirmDismiss: (direction) async {
        return await showDialog<bool>(
              context: context,
              builder: (context) => AlertDialog(
                backgroundColor: Color(0xFFF4F3EE),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                title: Text(
                  'Delete chat?',
                  style: TextStyle(fontWeight: FontWeight.w600),
                ),
                content: Text(
                  'This action cannot be undone.',
                  style: TextStyle(color: Colors.grey[700]),
                ),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.pop(context, false),
                    child: Text(
                      'Cancel',
                      style: TextStyle(color: Colors.grey[600]),
                    ),
                  ),
                  TextButton(
                    onPressed: () => Navigator.pop(context, true),
                    style: TextButton.styleFrom(
                      backgroundColor: Colors.red[50],
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    child: Text(
                      'Delete',
                      style: TextStyle(
                        color: Colors.red,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            ) ??
            false;
      },
      onDismissed: (direction) {
        context.read<ChatProvider>().leaveChat(chat.id, token);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Chat deleted'),
            backgroundColor: Color(0xFF6B73FF),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        );
      },
      child: Container(
        margin: EdgeInsets.only(bottom: 4),
        child: ListTile(
          contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          leading: Stack(
            children: [
              CircleAvatar(
                radius: 24,
                backgroundImage: (avatarUrl != null && avatarUrl.isNotEmpty) 
                  ? NetworkImage(avatarUrl) 
                  : null,
                backgroundColor: Colors.grey[300],
                child: (avatarUrl == null || avatarUrl.isEmpty)
                  ? Text(
                      _getChatInitials(displayName),
                      style: TextStyle(
                        fontSize: 16, 
                        fontWeight: FontWeight.w600,
                        color: Colors.black87,
                      ),
                    )
                  : null,
              ),
              if (chat.type == ChatType.group)
                Positioned(
                  right: 0,
                  bottom: 0,
                  child: Container(
                    width: 16,
                    height: 16,
                    decoration: BoxDecoration(
                      color: Color(0xFF6B73FF),
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white, width: 2),
                    ),
                    child: Icon(
                      Icons.group,
                      size: 10,
                      color: Colors.white,
                    ),
                  ),
                ),
              if (chat.unreadCount > 0)
                Positioned(
                  right: 0,
                  top: 0,
                  child: Container(
                    padding: EdgeInsets.all(2),
                    decoration: BoxDecoration(
                      color: Color(0xFF6B73FF),
                      shape: BoxShape.circle,
                    ),
                    constraints: BoxConstraints(minWidth: 18, minHeight: 18),
                    child: Text(
                      chat.unreadCount > 99 ? '99+' : chat.unreadCount.toString(),
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ),
            ],
          ),
          title: Row(
            children: [
              Expanded(
                child: Text(
                  displayName,
                  style: TextStyle(
                    fontWeight: chat.unreadCount > 0
                        ? FontWeight.w600
                        : FontWeight.w500,
                    fontSize: 16,
                    color: Colors.black87,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              if (chat.isMuted)
                Padding(
                  padding: EdgeInsets.only(left: 4),
                  child: Icon(Icons.volume_off, size: 16, color: Colors.grey[400]),
                ),
            ],
          ),
          subtitle: Padding(
            padding: EdgeInsets.only(top: 4),
            child: Text(
              chat.lastMessage ?? 'No messages',
              style: TextStyle(
                color: chat.unreadCount > 0 ? Colors.black87 : Colors.grey[600],
                fontSize: 14,
                fontWeight: chat.unreadCount > 0 
                  ? FontWeight.w500 
                  : FontWeight.normal,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
          trailing: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              if (chat.lastMessageTime != null)
                Text(
                  _formatTime(chat.lastMessageTime!),
                  style: TextStyle(
                    color: chat.unreadCount > 0
                        ? Color(0xFF6B73FF)
                        : Colors.grey[500],
                    fontSize: 12,
                    fontWeight: chat.unreadCount > 0
                        ? FontWeight.w600
                        : FontWeight.normal,
                  ),
                ),
            ],
          ),
          onTap: () {
            context.read<ChatProvider>().selectChat(chat.id, token);
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => ChatScreen(chatId: chat.id),
              ),
            );
          },
          onLongPress: () {
            _showChatOptions(chat);
          },
        ),
      ),
    );
  }

  String _getChatInitials(String name) {
    if (name.isEmpty) return '?';
    final words = name.trim().split(' ');
    if (words.length >= 2) {
      return '${words[0][0]}${words[1][0]}'.toUpperCase();
    }
    return name[0].toUpperCase();
  }

  String _formatTime(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);

    if (difference.inDays > 7) {
      return '${dateTime.day.toString().padLeft(2, '0')}/${dateTime.month.toString().padLeft(2, '0')}';
    } else if (difference.inDays > 0) {
      return '${difference.inDays}d';
    } else if (difference.inHours > 0) {
      return '${difference.inHours}h';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes}m';
    } else {
      return 'now';
    }
  }

  void _showChatOptions(Chat chat) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Color(0xFFF4F3EE),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Container(
        padding: EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40,
              height: 4,
              margin: EdgeInsets.only(bottom: 20),
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            ListTile(
              leading: Container(
                padding: EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  chat.isMuted ? Icons.volume_up : Icons.volume_off,
                  color: Colors.black87,
                ),
              ),
              title: Text(
                chat.isMuted ? 'Unmute' : 'Mute',
                style: TextStyle(fontWeight: FontWeight.w500),
              ),
              onTap: () {
                context.read<ChatProvider>().toggleChatMute(chat.id);
                Navigator.pop(context);
              },
            ),
            ListTile(
              leading: Container(
                padding: EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.red[50],
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(Icons.delete, color: Colors.red),
              ),
              title: Text(
                'Delete chat',
                style: TextStyle(
                  color: Colors.red,
                  fontWeight: FontWeight.w500,
                ),
              ),
              onTap: () {
                Navigator.pop(context);
                _confirmDeleteChat(chat);
              },
            ),
            SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  void _confirmDeleteChat(Chat chat) async {
    final token = context.read<AuthProvider>().token!;
    final currentUserId = context.read<AuthProvider>().userId;
    final otherParticipantId = chat.participants
        .firstWhere((id) => id != currentUserId, orElse: () => '');
    final userProfile = _userProfiles[otherParticipantId];
    final displayName = userProfile?['username'] ?? chat.name;

    final result = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Color(0xFFF4F3EE),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        title: Text(
          'Delete "$displayName"?',
          style: TextStyle(fontWeight: FontWeight.w600),
        ),
        content: Text(
          'This action cannot be undone. All messages will be lost.',
          style: TextStyle(color: Colors.grey[700]),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(
              'Cancel',
              style: TextStyle(color: Colors.grey[600]),
            ),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(
              backgroundColor: Colors.red[50],
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            child: Text(
              'Delete',
              style: TextStyle(
                color: Colors.red,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );

    if (result == true) {
      try {
        await context.read<ChatProvider>().leaveChat(chat.id, token);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Chat deleted'),
            backgroundColor: Color(0xFF6B73FF),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        );
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error deleting chat'),
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

  void _createNewChat(ChatType type) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => CreateChatScreen(chatType: type),
      ),
    ).then((_) {
      final token = context.read<AuthProvider>().token;
      if (token != null) {
        context.read<ChatProvider>().loadChats(token);
        _loadUserProfiles();
      }
    });
  }
}