import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../services/api_services.dart';
import '../screens/navbar.dart';

class ProfileEditScreen extends StatefulWidget {
  const ProfileEditScreen({super.key});

  @override
  _ProfileEditScreenState createState() => _ProfileEditScreenState();
}

class _ProfileEditScreenState extends State<ProfileEditScreen> {
  final TextEditingController _usernameController = TextEditingController();
  final TextEditingController _bioController = TextEditingController();
  bool _isEditing = false;
  final ApiService _apiService = ApiService();

  @override
  void initState() {
    super.initState();
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    _usernameController.text = authProvider.username ?? '';
    _bioController.text = authProvider.bio ?? '';
  }

  @override
  void dispose() {
    _usernameController.dispose();
    _bioController.dispose();
    _apiService.dispose();
    super.dispose();
  }

  Future<void> _saveChanges() async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    if (authProvider.userId == null || authProvider.token == null) {
      authProvider.handleAuthError(context, 'Authentication required');
      return;
    }

    try {
      await _apiService.updateProfile(
        authProvider.userId!,
        authProvider.token!,
        {
          'username': _usernameController.text.trim(),
          'bio': _bioController.text.trim(),
        },
      );
      authProvider.updateProfile(
        _usernameController.text.trim(),
        _bioController.text.trim(),
      );
      setState(() {
        _isEditing = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Профиль обновлён')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Ошибка обновления профиля: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;
    final authProvider = Provider.of<AuthProvider>(context);

    if (!authProvider.isInitialized) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      backgroundColor: const Color(0xFFF9F6F2),
      appBar: PreferredSize(
        preferredSize: Size.fromHeight(screenHeight * 0.12),
        child: Container(
          padding: EdgeInsets.only(top: screenHeight * 0.04),
          child: Row(
            children: [
              IconButton(
                icon: const Icon(Icons.arrow_back, color: Color(0xFF1A1A1A)),
                onPressed: () => Navigator.pop(context),
                padding: EdgeInsets.only(left: screenWidth * 0.04),
              ),
              Expanded(
                child: Center(
                  child: Text(
                    'Редактировать профиль',
                    style: TextStyle(
                      fontSize: screenWidth * 0.05,
                      fontWeight: FontWeight.bold,
                      color: const Color(0xFF1A1A1A),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: screenWidth * 0.04),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(height: screenHeight * 0.05),
              Center(
                child: CustomPaint(
                  painter: CircleImagePainter(),
                  child: Container(
                    width: screenWidth * 0.3,
                    height: screenWidth * 0.3,
                    color: Colors.transparent,
                  ),
                ),
              ),
              SizedBox(height: screenHeight * 0.02),
              Center(
                child: GestureDetector(
                  onTap: () {
                    setState(() {
                      _isEditing = true;
                    });
                  },
                  child: CustomPaint(
                    painter: EditIconPainter(),
                    child: Container(
                      width: screenWidth * 0.085,
                      height: screenWidth * 0.085,
                      color: Colors.transparent,
                    ),
                  ),
                ),
              ),
              SizedBox(height: screenHeight * 0.04),
              Text(
                'Имя пользователя',
                style: TextStyle(
                  fontSize: screenWidth * 0.04,
                  color: const Color(0xFF1A1A1A),
                ),
              ),
              SizedBox(height: screenHeight * 0.01),
              TextField(
                controller: _usernameController,
                enabled: _isEditing,
                decoration: InputDecoration(
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  filled: true,
                  fillColor: const Color(0xFFDDDDDD),
                ),
              ),
              SizedBox(height: screenHeight * 0.03),
              Text(
                'О себе',
                style: TextStyle(
                  fontSize: screenWidth * 0.04,
                  color: const Color(0xFF1A1A1A),
                ),
              ),
              SizedBox(height: screenHeight * 0.01),
              TextField(
                controller: _bioController,
                enabled: _isEditing,
                maxLines: 4,
                decoration: InputDecoration(
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  filled: true,
                  fillColor: const Color(0xFFDDDDDD),
                ),
              ),
              SizedBox(height: screenHeight * 0.06),
              if (_isEditing)
                Center(
                  child: ElevatedButton(
                    onPressed: _saveChanges,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFAFCBEA),
                      foregroundColor: const Color(0xFF000000),
                      minimumSize: Size(screenWidth * 0.5, screenHeight * 0.06),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    child: const Text('Сохранить'),
                  ),
                ),
              SizedBox(height: screenHeight * 0.1),
            ],
          ),
        ),
      ),
      bottomNavigationBar: Navbar(
        selectedIndex: 3,
        onTap: (index) {
          // Пустая функция или навигация, если нужно
          // Например: Navigator.pushNamed(context, '/route$index');
        },
      ),
    );
  }
}

class CircleImagePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = const Color(0xFF333333);
    final center = Offset(size.width / 2, size.height / 2);
    canvas.drawCircle(center, size.width / 2, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class EditIconPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = const Color(0xFFFFFFFF);
    final path = Path()
      ..moveTo(0, size.height)
      ..lineTo(size.width, 0)
      ..lineTo(size.width, size.height)
      ..close();
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
