// lib/screens/chat_list_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/chat.dart';
import '../../providers/chat_provider.dart';
import 'chat_screen.dart';
import 'create_chat_screen.dart';

class ChatListScreen extends StatefulWidget {
  @override
  _ChatListScreenState createState() => _ChatListScreenState();
}

class _ChatListScreenState extends State<ChatListScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final TextEditingController _searchController = TextEditingController();
  bool _isSearching = false;
  List<Chat> _filteredChats = [];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<ChatProvider>().initialize();
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    _searchController.dispose();
    super.dispose();
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
    return Scaffold(
      appBar: AppBar(
        title: _isSearching 
          ? TextField(
              controller: _searchController,
              autofocus: true,
              decoration: InputDecoration(
                hintText: 'Поиск чатов...',
                border: InputBorder.none,
                hintStyle: TextStyle(color: Colors.white70),
              ),
              style: TextStyle(color: Colors.white),
              onChanged: _onSearchChanged,
            )
          : Text('Чаты'),
        backgroundColor: Theme.of(context).primaryColor,
        foregroundColor: Colors.white,
        actions: [
          if (_isSearching)
            IconButton(
              icon: Icon(Icons.close),
              onPressed: _stopSearch,
            )
          else ...[
            IconButton(
              icon: Icon(Icons.search),
              onPressed: _startSearch,
            ),
            PopupMenuButton<String>(
              onSelected: (value) {
                switch (value) {
                  case 'new_group':
                    _createNewChat(ChatType.group);
                    break;
                  case 'new_conference':
                    _createNewChat(ChatType.conference);
                    break;
                  case 'settings':
                    // Navigate to settings
                    break;
                }
              },
              itemBuilder: (context) => [
                PopupMenuItem(
                  value: 'new_group',
                  child: Row(
                    children: [
                      Icon(Icons.group_add),
                      SizedBox(width: 12),
                      Text('Новая группа'),
                    ],
                  ),
                ),
                PopupMenuItem(
                  value: 'new_conference',
                  child: Row(
                    children: [
                      Icon(Icons.video_call),
                      SizedBox(width: 12),
                      Text('Конференция'),
                    ],
                  ),
                ),
                PopupMenuItem(
                  value: 'settings',
                  child: Row(
                    children: [
                      Icon(Icons.settings),
                      SizedBox(width: 12),
                      Text('Настройки'),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ],
        bottom: _isSearching ? null : TabBar(
          controller: _tabController,
          indicatorColor: Colors.white,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
          tabs: [
            Tab(text: 'Все'),
            Tab(text: 'Непрочитанные'),
            Tab(text: 'Архив'),
          ],
        ),
      ),
      body: Consumer<ChatProvider>(
        builder: (context, chatProvider, child) {
          if (chatProvider.isLoading) {
            return Center(child: CircularProgressIndicator());
          }

          if (chatProvider.error != null) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.error_outline, size: 64, color: Colors.grey),
                  SizedBox(height: 16),
                  Text(
                    'Ошибка загрузки чатов',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  SizedBox(height: 8),
                  Text(chatProvider.error!),
                  SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () => chatProvider.loadChats(),
                    child: Text('Повторить'),
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
              _buildChatList(chatProvider.getArchivedChats()),
            ],
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _createNewChat(ChatType.direct),
        child: Icon(Icons.chat),
        backgroundColor: Theme.of(context).primaryColor,
      ),
    );
  }

  Widget _buildChatList(List<Chat> chats) {
    if (chats.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.chat_bubble_outline, size: 64, color: Colors.grey),
            SizedBox(height: 16),
            Text(
              'Нет чатов',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            SizedBox(height: 8),
            Text('Начните новый разговор!'),
          ],
        ),
      );
    }

    return ListView.builder(
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
            Text('Ничего не найдено'),
          ],
        ),
      );
    }

    return _buildChatList(results);
  }

  Widget _buildChatTile(Chat chat) {
    return Dismissible(
      key: Key(chat.id),
      background: Container(
        color: Colors.green,
        alignment: Alignment.centerLeft,
        padding: EdgeInsets.only(left: 20),
        child: Icon(Icons.archive, color: Colors.white),
      ),
      secondaryBackground: Container(
        color: Colors.red,
        alignment: Alignment.centerRight,
        padding: EdgeInsets.only(right: 20),
        child: Icon(Icons.delete, color: Colors.white),
      ),
      confirmDismiss: (direction) async {
        if (direction == DismissDirection.startToEnd) {
          // Archive/Unarchive
          context.read<ChatProvider>().toggleChatArchive(chat.id);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(chat.isArchived ? 'Чат разархивирован' : 'Чат архивирован'),
            ),
          );
          return false;
        } else {
          // Delete
          return await showDialog<bool>(
            context: context,
            builder: (context) => AlertDialog(
              title: Text('Удалить чат?'),
              content: Text('Это действие нельзя отменить.'),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context, false),
                  child: Text('Отмена'),
                ),
                TextButton(
                  onPressed: () => Navigator.pop(context, true),
                  child: Text('Удалить', style: TextStyle(color: Colors.red)),
                ),
              ],
            ),
          ) ?? false;
        }
      },
      onDismissed: (direction) {
        if (direction == DismissDirection.endToStart) {
          context.read<ChatProvider>().leaveChat(chat.id);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Чат удален')),
          );
        }
      },
      child: ListTile(
        leading: Stack(
          children: [
            CircleAvatar(
              radius: 25,
              backgroundImage: chat.avatar != null 
                ? NetworkImage(chat.avatar!) 
                : null,
              child: chat.avatar == null 
                ? Text(
                    _getChatInitials(chat.name),
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
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
                    color: Theme.of(context).primaryColor,
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
                right: -2,
                top: -2,
                child: Container(
                  padding: EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    color: Colors.red,
                    shape: BoxShape.circle,
                  ),
                  constraints: BoxConstraints(minWidth: 16, minHeight: 16),
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
                chat.name,
                style: TextStyle(
                  fontWeight: chat.unreadCount > 0 
                    ? FontWeight.bold 
                    : FontWeight.normal,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
            if (chat.isMuted)
              Padding(
                padding: EdgeInsets.only(left: 4),
                child: Icon(Icons.volume_off, size: 16, color: Colors.grey),
              ),
          ],
        ),
        subtitle: Row(
          children: [
            if (chat.lastMessage != null) ...[
              Expanded(
                child: Text(
                  chat.lastMessage!,
                  style: TextStyle(
                    color: chat.unreadCount > 0 ? Colors.black87 : Colors.grey[600],
                    fontWeight: chat.unreadCount > 0 
                      ? FontWeight.w500 
                      : FontWeight.normal,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ] else ...[
              Expanded(
                child: Text(
                  'Нет сообщений',
                  style: TextStyle(color: Colors.grey[600]),
                ),
              ),
            ],
          ],
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
                    ? Theme.of(context).primaryColor
                    : Colors.grey[600],
                  fontSize: 12,
                  fontWeight: chat.unreadCount > 0 
                    ? FontWeight.bold 
                    : FontWeight.normal,
                ),
              ),
            SizedBox(height: 2),
            if (chat.isArchived)
              Icon(Icons.archive, size: 16, color: Colors.grey),
          ],
        ),
        onTap: () {
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
      return '${dateTime.day}/${dateTime.month}/${dateTime.year}';
    } else if (difference.inDays > 0) {
      return '${difference.inDays}д';
    } else if (difference.inHours > 0) {
      return '${difference.inHours}ч';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes}м';
    } else {
      return 'сейчас';
    }
  }

  void _showChatOptions(Chat chat) {
    showModalBottomSheet(
      context: context,
      builder: (context) => Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          ListTile(
            leading: Icon(chat.isMuted ? Icons.volume_up : Icons.volume_off),
            title: Text(chat.isMuted ? 'Включить уведомления' : 'Отключить уведомления'),
            onTap: () {
              context.read<ChatProvider>().toggleChatMute(chat.id);
              Navigator.pop(context);
            },
          ),
          ListTile(
            leading: Icon(chat.isArchived ? Icons.unarchive : Icons.archive),
            title: Text(chat.isArchived ? 'Разархивировать' : 'Архивировать'),
            onTap: () {
              context.read<ChatProvider>().toggleChatArchive(chat.id);
              Navigator.pop(context);
            },
          ),
          ListTile(
            leading: Icon(Icons.delete, color: Colors.red),
            title: Text('Удалить чат', style: TextStyle(color: Colors.red)),
            onTap: () {
              Navigator.pop(context);
              _confirmDeleteChat(chat);
            },
          ),
        ],
      ),
    );
  }

  void _confirmDeleteChat(Chat chat) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Удалить чат "${chat.name}"?'),
        content: Text('Это действие нельзя отменить. Все сообщения будут потеряны.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text('Отмена'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text('Удалить', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (result == true) {
      context.read<ChatProvider>().leaveChat(chat.id);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Чат удален')),
      );
    }
  }

  void _createNewChat(ChatType type) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => CreateChatScreen(chatType: type),
      ),
    );
  }
}