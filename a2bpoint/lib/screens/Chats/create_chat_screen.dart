import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/chat.dart';
import '../../models/user.dart';
import '../../providers/chat_provider.dart';
import '../../providers/auth_provider.dart';

class CreateChatScreen extends StatefulWidget {
  final ChatType chatType;

  const CreateChatScreen({Key? key, required this.chatType}) : super(key: key);

  @override
  _CreateChatScreenState createState() => _CreateChatScreenState();
}

class _CreateChatScreenState extends State<CreateChatScreen> {
  final _nameController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _searchController = TextEditingController();

  List<User> _selectedUsers = [];
  List<User> _availableUsers = [];
  List<User> _filteredUsers = [];
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _loadAvailableUsers(context.read<AuthProvider>().token!); // Pass token
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  void _loadAvailableUsers(String token) {
    setState(() {
      _isLoading = true;
    });

    // Simulate loading users (replace with real backend call)
    Future.delayed(Duration(seconds: 1), () {
      if (mounted) {
        setState(() {
          _availableUsers = [
            User(id: '1', username: 'Анна Смирнова', profileImage: ''),
            User(id: '2', username: 'Иван Петров', profileImage: ''),
            User(id: '3', username: 'Мария Козлова', profileImage: ''),
            User(id: '4', username: 'Алексей Иванов', profileImage: ''),
            User(id: '5', username: 'Елена Васильева', profileImage: ''),
            User(id: '6', username: 'Дмитрий Сидоров', profileImage: ''),
          ];
          _filteredUsers = List.from(_availableUsers);
          _isLoading = false;
        });
      }
    });
    // TODO: Replace with real backend call, e.g.:
    // context.read<ChatProvider>().getAvailableUsers(token).then((users) {
    //   if (mounted) {
    //     setState(() {
    //       _availableUsers = users;
    //       _filteredUsers = List.from(_availableUsers);
    //       _isLoading = false;
    //     });
    //   }
    // }).catchError((e) {
    //   setState(() { _isLoading = false; });
    //   ScaffoldMessenger.of(context).showSnackBar(
    //     SnackBar(content: Text('Ошибка загрузки пользователей: $e'), backgroundColor: Colors.red),
    //   );
    // });
  }

  void _filterUsers(String query) {
    setState(() {
      if (query.isEmpty) {
        _filteredUsers = List.from(_availableUsers);
      } else {
        _filteredUsers = _availableUsers
            .where((user) =>
                user.username.toLowerCase().contains(query.toLowerCase()))
            .toList();
      }
    });
  }

  void _toggleUserSelection(User user) {
    setState(() {
      if (_selectedUsers.contains(user)) {
        _selectedUsers.remove(user);
      } else {
        _selectedUsers.add(user);
      }
    });
  }

  String _getChatTypeTitle() {
    switch (widget.chatType) {
      case ChatType.direct:
        return 'Новый чат';
      case ChatType.group:
        return 'Новая группа';
      case ChatType.mentorship:
        return 'Менторский чат';
      case ChatType.conference:
        return 'Конференция';
    }
  }

  bool _canCreateChat() {
    if (widget.chatType == ChatType.direct) {
      return _selectedUsers.length == 1;
    } else {
      return _selectedUsers.isNotEmpty &&
          _nameController.text.trim().isNotEmpty;
    }
  }

  void _createChat(String token) async {
    if (!_canCreateChat()) return;

    setState(() {
      _isLoading = true;
    });

    try {
      String chatName;
      if (widget.chatType == ChatType.direct) {
        chatName = _selectedUsers.first.username;
      } else {
        chatName = _nameController.text.trim();
      }

      await context.read<ChatProvider>().createChat(
            chatName,
            _selectedUsers.map((user) => user.id).toList(),
            widget.chatType,
            token,
            description: _descriptionController.text.trim().isNotEmpty
                ? _descriptionController.text.trim()
                : null,
          );

      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('${_getChatTypeTitle()} создан')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Ошибка при создании чата: $e'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_getChatTypeTitle()),
        backgroundColor: Theme.of(context).primaryColor,
        foregroundColor: Colors.white,
        actions: [
          TextButton(
            onPressed: _canCreateChat()
                ? () => _createChat(context.read<AuthProvider>().token!)
                : null,
            child: Text(
              'Создать',
              style: TextStyle(
                color: _canCreateChat() ? Colors.white : Colors.white60,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
      body: _isLoading
          ? Center(child: CircularProgressIndicator())
          : Column(
              children: [
                if (widget.chatType != ChatType.direct) ...[
                  _buildChatInfoForm(),
                  Divider(thickness: 1),
                ],
                _buildSelectedUsers(),
                _buildUserSearch(),
                Expanded(child: _buildUserList()),
              ],
            ),
    );
  }

  Widget _buildChatInfoForm() {
    return Container(
      padding: EdgeInsets.all(16),
      child: Column(
        children: [
          TextField(
            controller: _nameController,
            decoration: InputDecoration(
              labelText:
                  'Название ${widget.chatType == ChatType.group ? 'группы' : 'чата'}',
              border: OutlineInputBorder(),
              prefixIcon: Icon(Icons.edit),
            ),
            textCapitalization: TextCapitalization.words,
            onChanged: (_) => setState(() {}),
          ),
          if (widget.chatType == ChatType.group ||
              widget.chatType == ChatType.conference) ...[
            SizedBox(height: 16),
            TextField(
              controller: _descriptionController,
              decoration: InputDecoration(
                labelText: 'Описание (необязательно)',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.description),
              ),
              maxLines: 2,
              textCapitalization: TextCapitalization.sentences,
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildSelectedUsers() {
    if (_selectedUsers.isEmpty) {
      return SizedBox.shrink();
    }

    return Container(
      padding: EdgeInsets.symmetric(vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 16),
            child: Text(
              'Выбрано: ${_selectedUsers.length}',
              style: Theme.of(context).textTheme.titleSmall?.copyWith(
                    color: Theme.of(context).primaryColor,
                    fontWeight: FontWeight.bold,
                  ),
            ),
          ),
          SizedBox(height: 8),
          Container(
            height: 60,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              padding: EdgeInsets.symmetric(horizontal: 16),
              itemCount: _selectedUsers.length,
              itemBuilder: (context, index) {
                final user = _selectedUsers[index];
                return Container(
                  margin: EdgeInsets.only(right: 8),
                  child: Column(
                    children: [
                      Stack(
                        children: [
                          CircleAvatar(
                            radius: 20,
                            backgroundImage: user.profileImage.isNotEmpty
                                ? NetworkImage(user.profileImage)
                                : null,
                            child: user.profileImage.isEmpty
                                ? Text(user.username[0].toUpperCase())
                                : null,
                          ),
                          Positioned(
                            top: -2,
                            right: -2,
                            child: GestureDetector(
                              onTap: () => _toggleUserSelection(user),
                              child: Container(
                                padding: EdgeInsets.all(2),
                                decoration: BoxDecoration(
                                  color: Colors.red,
                                  shape: BoxShape.circle,
                                ),
                                child: Icon(
                                  Icons.close,
                                  size: 12,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                      SizedBox(height: 4),
                      SizedBox(
                        width: 50,
                        child: Text(
                          user.username.split(' ')[0],
                          style: TextStyle(fontSize: 10),
                          textAlign: TextAlign.center,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
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
          hintText: 'Поиск пользователей...',
          prefixIcon: Icon(Icons.search),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(25),
          ),
          contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        ),
        onChanged: _filterUsers,
      ),
    );
  }

  Widget _buildUserList() {
    if (_filteredUsers.isEmpty) {
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
              _searchController.text.isNotEmpty
                  ? 'Пользователи не найдены'
                  : 'Нет доступных пользователей',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: Colors.grey,
                  ),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      itemCount: _filteredUsers.length,
      itemBuilder: (context, index) {
        final user = _filteredUsers[index];
        final isSelected = _selectedUsers.contains(user);

        return ListTile(
          leading: Stack(
            children: [
              CircleAvatar(
                backgroundImage: user.profileImage.isNotEmpty
                    ? NetworkImage(user.profileImage)
                    : null,
                child: user.profileImage.isEmpty
                    ? Text(user.username[0].toUpperCase())
                    : null,
              ),
              if (isSelected)
                Positioned(
                  bottom: 0,
                  right: 0,
                  child: Container(
                    padding: EdgeInsets.all(2),
                    decoration: BoxDecoration(
                      color: Theme.of(context).primaryColor,
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white, width: 2),
                    ),
                    child: Icon(
                      Icons.check,
                      size: 12,
                      color: Colors.white,
                    ),
                  ),
                ),
            ],
          ),
          title: Text(user.username),
          subtitle: Text('ID: ${user.id}'),
          trailing: widget.chatType == ChatType.direct &&
                  _selectedUsers.isNotEmpty &&
                  !isSelected
              ? null
              : Checkbox(
                  value: isSelected,
                  onChanged: widget.chatType == ChatType.direct &&
                          _selectedUsers.isNotEmpty &&
                          !isSelected
                      ? null
                      : (_) => _toggleUserSelection(user),
                ),
          onTap: () {
            if (widget.chatType == ChatType.direct &&
                _selectedUsers.isNotEmpty &&
                !isSelected) {
              return;
            }
            _toggleUserSelection(user);
          },
          enabled: !(widget.chatType == ChatType.direct &&
              _selectedUsers.isNotEmpty &&
              !isSelected),
        );
      },
    );
  }
}
