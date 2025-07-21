import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'dart:developer' as developer;
import 'dart:io';
import 'package:image_picker/image_picker.dart';
import 'package:video_player/video_player.dart';
import '../providers/auth_provider.dart';
import '../services/api_services.dart';
import '../services/exceptions.dart';
import 'navbar.dart';

class AddScreen extends StatefulWidget {
  const AddScreen({super.key});

  @override
  _AddScreenState createState() => _AddScreenState();
}

class _AddScreenState extends State<AddScreen> {
  final ApiService _apiService = ApiService();
  final _formKey = GlobalKey<FormState>();
  final _descriptionController = TextEditingController();
  final _locationController = TextEditingController();
  final _pointAController = TextEditingController();
  final _pointBController = TextEditingController();
  final _dateTimeController = TextEditingController();
  final _taskController = TextEditingController();
  final ImagePicker _picker = ImagePicker();
  File? _selectedMedia;
  VideoPlayerController? _videoController;

  int _selectedTabIndex = 0;
  String? _selectedInterest;
  List<Map<String, dynamic>> _tasks = [];
  bool _isLoading = false;
  String _errorMessage = '';

  @override
  void initState() {
    super.initState();
    _checkAuth();
  }

  void _checkAuth() {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    if (!authProvider.isInitialized) {
      authProvider.initialize().then((_) {
        if (mounted && authProvider.shouldRedirectTo()) {
          authProvider.handleAuthError(
              context, AuthenticationException('Not authenticated'));
        }
      });
    } else if (authProvider.shouldRedirectTo()) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        authProvider.handleAuthError(
            context, AuthenticationException('Not authenticated'));
      });
    }
  }

  Future<void> _pickMedia() async {
    try {
      final XFile? pickedFile = await showModalBottomSheet<XFile>(
        context: context,
        builder: (context) => Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.image),
              title: const Text('Выбрать изображение'),
              onTap: () async => Navigator.pop(context,
                  await _picker.pickImage(source: ImageSource.gallery)),
            ),
            ListTile(
              leading: const Icon(Icons.videocam),
              title: const Text('Выбрать видео'),
              onTap: () async => Navigator.pop(context,
                  await _picker.pickVideo(source: ImageSource.gallery)),
            ),
          ],
        ),
      );

      if (pickedFile != null) {
        setState(() {
          _selectedMedia = File(pickedFile.path);
          if (pickedFile.path.endsWith('.mp4') ||
              pickedFile.path.endsWith('.mov')) {
            _videoController = VideoPlayerController.file(_selectedMedia!)
              ..initialize().then((_) => setState(() {}));
          }
        });
      }
    } catch (e, stackTrace) {
      developer.log('Pick media error: $e',
          name: 'AddScreen', stackTrace: stackTrace);
    }
  }

  Future<void> _saveData() async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    if (_selectedInterest == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Выберите интерес')),
      );
      return;
    }
    if (_selectedTabIndex == 1 && _dateTimeController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Выберите дату и время')),
      );
      return;
    }
    if (_formKey.currentState!.validate()) {
      if (!authProvider.isAuthenticated ||
          authProvider.userId == null ||
          authProvider.token == null) {
        authProvider.handleAuthError(
            context, AuthenticationException('Not authenticated'));
        return;
      }
      try {
        developer.log('Saving data: tabIndex=$_selectedTabIndex',
            name: 'AddScreen');
        String? mediaUrl;
        setState(() {
          _isLoading = true;
        });
        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (context) =>
              const Center(child: CircularProgressIndicator()),
        );

        final String userId = authProvider.userId!;
        final String token = authProvider.token!;
        if (_selectedMedia != null) {
          mediaUrl = await _apiService.uploadMedia(_selectedMedia!);
        }

        if (_selectedTabIndex == 0) {
          await _apiService.createGoal(
            userId: userId,
            description: _descriptionController.text,
            location: _locationController.text,
            interest: _selectedInterest!,
            pointA: _pointAController.text.isNotEmpty
                ? _pointAController.text
                : null,
            pointB: _pointBController.text.isNotEmpty
                ? _pointBController.text
                : null,
            tasks: _tasks.isNotEmpty ? _tasks : null,
            imageUrls: mediaUrl != null ? [mediaUrl] : null,
            token: token,
          );
        } else {
          await _apiService.createEvent(
            userId: userId,
            description: _descriptionController.text,
            location: _locationController.text,
            interest: _selectedInterest!,
            dateTime: _dateTimeController.text,
            token: token,
          );
        }

        if (mounted) {
          Navigator.pop(context);
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Данные успешно сохранены')),
          );
          _descriptionController.clear();
          _locationController.clear();
          _pointAController.clear();
          _pointBController.clear();
          _dateTimeController.clear();
          setState(() {
            _selectedInterest = null;
            _tasks.clear();
            _selectedMedia = null;
            _videoController?.dispose();
            _videoController = null;
            _errorMessage = '';
          });
        }
      } catch (e, stackTrace) {
        developer.log('Save data error: $e',
            name: 'AddScreen', stackTrace: stackTrace);
        authProvider.handleAuthError(context, e);
        if (mounted && e is! AuthenticationException) {
          Navigator.pop(context);
          setState(() {
            _errorMessage = e is DataValidationException
                ? e.message
                : 'Ошибка сохранения: $e';
          });
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(_errorMessage)),
          );
        }
      } finally {
        if (mounted) {
          setState(() {
            _isLoading = false;
          });
        }
      }
    }
  }

  void _addTask() {
    if (_taskController.text.isNotEmpty) {
      setState(() {
        _tasks.add({'title': _taskController.text, 'completed': false});
        _taskController.clear();
      });
    }
  }

  void _removeTask(int index) {
    setState(() {
      _tasks.removeAt(index);
    });
  }

  Future<void> _selectDateTime() async {
    final date = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime.now(),
      lastDate: DateTime(2100),
    );
    if (date != null) {
      final time = await showTimePicker(
        context: context,
        initialTime: TimeOfDay.now(),
      );
      if (time != null) {
        final dateTime =
            DateTime(date.year, date.month, date.day, time.hour, time.minute);
        _dateTimeController.text = dateTime.toIso8601String();
      }
    }
  }

  Widget _buildMediaPreview() {
    if (_selectedMedia == null) return const SizedBox.shrink();
    final isVideo = _selectedMedia!.path.endsWith('.mp4') ||
        _selectedMedia!.path.endsWith('.mov');
    return Stack(
      alignment: Alignment.topRight,
      children: [
        Container(
          height: 100,
          width: 100,
          margin: const EdgeInsets.only(top: 8),
          child: isVideo &&
                  _videoController != null &&
                  _videoController!.value.isInitialized
              ? VideoPlayer(_videoController!)
              : Image.file(
                  _selectedMedia!,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) =>
                      const Icon(Icons.broken_image, size: 50),
                ),
        ),
        IconButton(
          icon: const Icon(Icons.close, color: Color(0xFF333333)),
          onPressed: () => setState(() {
            _selectedMedia = null;
            _videoController?.dispose();
            _videoController = null;
          }),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final padding = size.width * 0.05;
    final aspectRatio = 375 / 956; // Соотношение сторон из макета
    final containerHeight = size.width / aspectRatio;

    return Scaffold(
      backgroundColor: const Color(0xFFF4F3EE),
      appBar: AppBar(
        elevation: 0,
        backgroundColor: const Color(0xFFF4F3EE),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Color(0xFF333333)),
          onPressed: () => Navigator.pushReplacementNamed(context, '/profile'),
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Center(
              child: SizedBox(
                width: size.width * 0.9, // Адаптивная ширина
                height: containerHeight * 0.9, // Адаптивная высота
                child: CustomPaint(
                  painter: BackgroundPainter(),
                  child: Padding(
                    padding: EdgeInsets.all(padding),
                    child: Column(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(vertical: 8),
                          color: const Color(0xFFF9F6F2),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              GestureDetector(
                                onTap: () => setState(() => _selectedTabIndex = 0),
                                child: Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 16, vertical: 8),
                                  decoration: BoxDecoration(
                                    color: _selectedTabIndex == 0
                                        ? const Color(0xFFAFCBEA).withOpacity(0.1)
                                        : Colors.transparent,
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Text(
                                    'Цель',
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                      color: _selectedTabIndex == 0
                                          ? const Color(0xFFAFCBEA)
                                          : const Color(0xFF333333),
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 8),
                              GestureDetector(
                                onTap: () => setState(() => _selectedTabIndex = 1),
                                child: Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 16, vertical: 8),
                                  decoration: BoxDecoration(
                                    color: _selectedTabIndex == 1
                                        ? const Color(0xFFAFCBEA).withOpacity(0.1)
                                        : Colors.transparent,
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Text(
                                    'Событие',
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                      color: _selectedTabIndex == 1
                                          ? const Color(0xFFAFCBEA)
                                          : const Color(0xFF333333),
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        Expanded(
                          child: SingleChildScrollView(
                            child: Form(
                              key: _formKey,
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  TextFormField(
                                    controller: _descriptionController,
                                    decoration: InputDecoration(
                                      labelText: 'Описание',
                                      labelStyle:
                                          const TextStyle(color: Color(0xFF1A1A1A)),
                                      filled: true,
                                      fillColor:
                                          const Color(0xFFDDDDDD).withOpacity(0.2),
                                      border: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(10),
                                        borderSide: BorderSide.none,
                                      ),
                                      prefixIcon: const Icon(Icons.description,
                                          color: Color(0xFF333333)),
                                      suffixIcon: IconButton(
                                        icon: const Icon(Icons.attach_file,
                                            color: Color(0xFF333333)),
                                        onPressed: _pickMedia,
                                      ),
                                    ),
                                    style: const TextStyle(color: Color(0xFF1A1A1A)),
                                    validator: (value) => value?.isEmpty ?? true
                                        ? 'Введите описание'
                                        : null,
                                  ),
                                  if (_selectedMedia != null) ...[
                                    SizedBox(height: size.height * 0.02),
                                    _buildMediaPreview(),
                                  ],
                                  SizedBox(height: size.height * 0.02),
                                  TextFormField(
                                    controller: _locationController,
                                    decoration: InputDecoration(
                                      labelText: 'Местоположение',
                                      labelStyle:
                                          const TextStyle(color: Color(0xFF1A1A1A)),
                                      filled: true,
                                      fillColor:
                                          const Color(0xFFDDDDDD).withOpacity(0.2),
                                      border: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(10),
                                        borderSide: BorderSide.none,
                                      ),
                                      prefixIcon: const Icon(Icons.location_on,
                                          color: Color(0xFF333333)),
                                    ),
                                    style: const TextStyle(color: Color(0xFF1A1A1A)),
                                    validator: (value) => value?.isEmpty ?? true
                                        ? 'Введите местоположение'
                                        : null,
                                  ),
                                  SizedBox(height: size.height * 0.02),
                                  Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      const Text(
                                        'Интересы',
                                        style: TextStyle(
                                          fontWeight: FontWeight.bold,
                                          color: Color(0xFF000000),
                                        ),
                                      ),
                                      const SizedBox(height: 8),
                                      Wrap(
                                        spacing: 8,
                                        runSpacing: 8,
                                        children: [
                                          'Здоровье',
                                          'Йога',
                                          'Спорт',
                                          'Музыка',
                                          'Наука',
                                          'Книги',
                                          'Плавание',
                                        ].map((interest) {
                                          return ChoiceChip(
                                            label: Text(interest),
                                            selected: _selectedInterest == interest,
                                            onSelected: (selected) => setState(() =>
                                                _selectedInterest =
                                                    selected ? interest : null),
                                            selectedColor: const Color(0xFFAFCBEA),
                                            labelStyle: TextStyle(
                                              color: _selectedInterest == interest
                                                  ? const Color(0xFF000000)
                                                  : const Color(0xFF1A1A1A),
                                            ),
                                            backgroundColor: const Color(0xFFDDDDDD)
                                                .withOpacity(0.2),
                                          );
                                        }).toList(),
                                      ),
                                    ],
                                  ),
                                  SizedBox(height: size.height * 0.02),
                                  if (_selectedTabIndex == 1)
                                    TextFormField(
                                      controller: _dateTimeController,
                                      decoration: InputDecoration(
                                        labelText: 'Дата и время',
                                        labelStyle:
                                            const TextStyle(color: Color(0xFF1A1A1A)),
                                        filled: true,
                                        fillColor:
                                            const Color(0xFFDDDDDD).withOpacity(0.2),
                                        border: OutlineInputBorder(
                                          borderRadius: BorderRadius.circular(10),
                                          borderSide: BorderSide.none,
                                        ),
                                        prefixIcon: const Icon(Icons.calendar_today,
                                            color: Color(0xFF333333)),
                                        suffixIcon: IconButton(
                                          icon: const Icon(Icons.event,
                                              color: Color(0xFF333333)),
                                          onPressed: _selectDateTime,
                                        ),
                                      ),
                                      readOnly: true,
                                      style: const TextStyle(color: Color(0xFF1A1A1A)),
                                    ),
                                  SizedBox(height: size.height * 0.02),
                                  if (_selectedTabIndex == 0) ...[
                                    TextFormField(
                                      controller: _pointAController,
                                      decoration: InputDecoration(
                                        labelText: 'Точка A',
                                        labelStyle:
                                            const TextStyle(color: Color(0xFF1A1A1A)),
                                        filled: true,
                                        fillColor:
                                            const Color(0xFFDDDDDD).withOpacity(0.2),
                                        border: OutlineInputBorder(
                                          borderRadius: BorderRadius.circular(10),
                                          borderSide: BorderSide.none,
                                        ),
                                        prefixIcon: const Icon(Icons.place,
                                            color: Color(0xFF333333)),
                                      ),
                                      style: const TextStyle(color: Color(0xFF1A1A1A)),
                                    ),
                                    SizedBox(height: size.height * 0.02),
                                    TextFormField(
                                      controller: _pointBController,
                                      decoration: InputDecoration(
                                        labelText: 'Точка B',
                                        labelStyle:
                                            const TextStyle(color: Color(0xFF1A1A1A)),
                                        filled: true,
                                        fillColor:
                                            const Color(0xFFDDDDDD).withOpacity(0.2),
                                        border: OutlineInputBorder(
                                          borderRadius: BorderRadius.circular(10),
                                          borderSide: BorderSide.none,
                                        ),
                                        prefixIcon: const Icon(Icons.place,
                                            color: Color(0xFF333333)),
                                      ),
                                      style: const TextStyle(color: Color(0xFF1A1A1A)),
                                    ),
                                    SizedBox(height: size.height * 0.02),
                                    const Text(
                                      'Задачи',
                                      style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                        color: Color(0xFF000000),
                                      ),
                                    ),
                                    ListView.builder(
                                      shrinkWrap: true,
                                      physics: const NeverScrollableScrollPhysics(),
                                      itemCount: _tasks.length,
                                      itemBuilder: (context, index) {
                                        return Row(
                                          children: [
                                            Expanded(
                                              child: Text(
                                                _tasks[index]['title'],
                                                style: const TextStyle(
                                                    color: Color(0xFF1A1A1A)),
                                              ),
                                            ),
                                            IconButton(
                                              icon: const Icon(Icons.close,
                                                  color: Color(0xFF333333)),
                                              onPressed: () => _removeTask(index),
                                            ),
                                          ],
                                        );
                                      },
                                    ),
                                    Row(
                                      children: [
                                        Expanded(
                                          child: TextFormField(
                                            controller: _taskController,
                                            decoration: InputDecoration(
                                              hintText: 'Добавить задачу',
                                              hintStyle: const TextStyle(
                                                  color: Color(0xFF333333)),
                                              filled: true,
                                              fillColor: const Color(0xFFDDDDDD)
                                                  .withOpacity(0.2),
                                              border: OutlineInputBorder(
                                                borderRadius:
                                                    BorderRadius.circular(10),
                                                borderSide: BorderSide.none,
                                              ),
                                              prefixIcon: const Icon(Icons.task,
                                                  color: Color(0xFF333333)),
                                            ),
                                            style: const TextStyle(
                                                color: Color(0xFF1A1A1A)),
                                          ),
                                        ),
                                        IconButton(
                                          icon: const Icon(Icons.add,
                                              color: Color(0xFFAFCBEA)),
                                          onPressed: _addTask,
                                        ),
                                      ],
                                    ),
                                  ],
                                  SizedBox(height: size.height * 0.03),
                                  SizedBox(
                                    width: double.infinity,
                                    child: ElevatedButton(
                                      onPressed: _saveData,
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: const Color(0xFFAFCBEA),
                                        foregroundColor: const Color(0xFF000000),
                                        padding: EdgeInsets.symmetric(
                                            vertical: size.height * 0.02),
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(10),
                                        ),
                                      ),
                                      child: const Text('Создать'),
                                    ),
                                  ),
                                  if (_errorMessage.isNotEmpty)
                                    Padding(
                                      padding: const EdgeInsets.only(top: 8.0),
                                      child: Text(
                                        _errorMessage,
                                        style: const TextStyle(color: Colors.red),
                                      ),
                                    ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
      bottomNavigationBar: Navbar(
        selectedIndex: 2,
        onTap: (index) {
          final routes = ['/home', '/search', '/add', '/profile', '/ai-mentor'];
          Navigator.pushReplacementNamed(context, routes[index]);
        },
      ),
    );
  }
}

class BackgroundPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = const Color(0xFFF4F3EE);
    final radius = 32.0;
    final path = Path()
      ..moveTo(radius, 0)
      ..lineTo(size.width - radius, 0)
      ..arcToPoint(Offset(size.width, radius), radius: Radius.circular(radius), clockwise: false)
      ..lineTo(size.width, size.height - radius)
      ..arcToPoint(Offset(size.width - radius, size.height), radius: Radius.circular(radius), clockwise: false)
      ..lineTo(radius, size.height)
      ..arcToPoint(Offset(0, size.height - radius), radius: Radius.circular(radius), clockwise: false)
      ..lineTo(0, radius)
      ..arcToPoint(Offset(radius, 0), radius: Radius.circular(radius), clockwise: false)
      ..close();
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}