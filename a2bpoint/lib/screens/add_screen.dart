// add_screen.dart
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart'; // Импортируем для FileOptions
import '../providers/auth_provider.dart';
import '../services/api_services.dart';
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
  final ImagePicker _picker = ImagePicker();
  List<File> _images = []; // Список загруженных изображений
  int _selectedTabIndex = 0; // 0 for Goals, 1 for Events
  String? _selectedInterest;
  List<String> _tasks = []; // Список задач
  final _taskController = TextEditingController();

  @override
  void dispose() {
    _descriptionController.dispose();
    _locationController.dispose();
    _pointAController.dispose();
    _pointBController.dispose();
    _taskController.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    if (_images.length >= 3) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Максимум 3 фото')),
      );
      return;
    }
    final pickedFile = await _picker.pickImage(source: ImageSource.gallery);
    if (pickedFile != null) {
      setState(() {
        _images.add(File(pickedFile.path));
      });
    }
  }

  void _removeImage(int index) {
    setState(() {
      _images.removeAt(index);
    });
  }

  void _addTask() {
    if (_taskController.text.isNotEmpty) {
      setState(() {
        _tasks.add(_taskController.text);
        _taskController.clear();
      });
    }
  }

  void _removeTask(int index) {
    setState(() {
      _tasks.removeAt(index);
    });
  }

  Future<List<String>> _uploadImages() async {
    List<String> imageUrls = [];
    for (var image in _images) {
      final fileName = DateTime.now().millisecondsSinceEpoch.toString();
      try {
        await _apiService.supabase.storage.from('images').uploadBinary(
              fileName,
              await image.readAsBytes(),
              fileOptions: FileOptions(
                contentType: 'image/jpeg',
                upsert: true,
              ),
            );
        final url =
            _apiService.supabase.storage.from('images').getPublicUrl(fileName);
        imageUrls.add(url);
      } catch (e) {
        print('Error uploading image: $e');
        // Продолжаем, даже если одно изображение не загрузилось
      }
    }
    return imageUrls;
  }

  Future<void> _saveData() async {
    if (_formKey.currentState!.validate()) {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      if (!authProvider.isAuthenticated || authProvider.userId == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Требуется авторизация')),
        );
        return;
      }
      try {
        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (context) =>
              const Center(child: CircularProgressIndicator()),
        );

        final imageUrls = await _uploadImages();
        final userId = authProvider.userId!;

        if (_selectedTabIndex == 0) {
          // Save as Goal
          await _apiService.createGoal(
            userId,
            _descriptionController.text,
            _locationController.text,
            _selectedInterest ?? 'Health',
            pointA: _pointAController.text,
            pointB: _pointBController.text,
            tasks: _tasks,
            imageUrls: imageUrls,
          );
        } else {
          // Save as Event
          await _apiService.createEvent(
            userId,
            _descriptionController.text,
            _locationController.text,
            pointA: _pointAController.text,
            pointB: _pointBController.text,
            tasks: _tasks,
            imageUrls: imageUrls,
          );
        }

        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Данные сохранены')),
        );
        _descriptionController.clear();
        _locationController.clear();
        _pointAController.clear();
        _pointBController.clear();
        setState(() {
          _selectedInterest = null;
          _images.clear();
          _tasks.clear();
        });
      } catch (e) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Ошибка сохранения: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final padding = size.width * 0.05;

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.purple),
          onPressed: () => Navigator.pop(context),
        ),
        elevation: 0,
        backgroundColor: Colors.white,
        toolbarHeight:
            0, // Убираем лишнее пространство, оставляя только leading
      ),
      body: Column(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(vertical: 8),
            color: Colors.white,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                GestureDetector(
                  onTap: () => setState(() => _selectedTabIndex = 0),
                  child: Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    decoration: BoxDecoration(
                      color: _selectedTabIndex == 0
                          ? Colors.purple.withOpacity(0.1)
                          : Colors.transparent,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      'Goal',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: _selectedTabIndex == 0
                            ? Colors.purple
                            : Colors.grey,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                GestureDetector(
                  onTap: () => setState(() => _selectedTabIndex = 1),
                  child: Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    decoration: BoxDecoration(
                      color: _selectedTabIndex == 1
                          ? Colors.purple.withOpacity(0.1)
                          : Colors.transparent,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      'Event',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: _selectedTabIndex == 1
                            ? Colors.purple
                            : Colors.grey,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: SingleChildScrollView(
              padding: EdgeInsets.all(padding),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        GestureDetector(
                          onTap: _pickImage,
                          child: Container(
                            width: 50,
                            height: 174,
                            decoration: BoxDecoration(
                              color: Colors.grey[200],
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: const Icon(Icons.add_a_photo,
                                size: 40, color: Colors.grey),
                          ),
                        ),
                        Expanded(
                          child: Container(
                            height: 174,
                            child: _images.isEmpty
                                ? const SizedBox.shrink()
                                : ListView.builder(
                                    scrollDirection: Axis.horizontal,
                                    itemCount: _images.length,
                                    itemBuilder: (context, index) {
                                      return Stack(
                                        children: [
                                          Padding(
                                            padding: const EdgeInsets.only(
                                                left: 8.0),
                                            child: Image.file(_images[index],
                                                width: 156,
                                                height: 174,
                                                fit: BoxFit.cover),
                                          ),
                                          Positioned(
                                            top: 0,
                                            right: 0,
                                            child: IconButton(
                                              icon: const Icon(Icons.close,
                                                  color: Colors.red),
                                              onPressed: () =>
                                                  _removeImage(index),
                                            ),
                                          ),
                                        ],
                                      );
                                    },
                                  ),
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: size.height * 0.02),
                    TextFormField(
                      controller: _descriptionController,
                      decoration: InputDecoration(
                        labelText: 'Description',
                        border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10)),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                          borderSide: const BorderSide(color: Colors.purple),
                        ),
                      ),
                      validator: (value) =>
                          value?.isEmpty ?? true ? 'Введите описание' : null,
                    ),
                    SizedBox(height: size.height * 0.02),
                    TextFormField(
                      controller: _locationController,
                      decoration: InputDecoration(
                        labelText: 'Location',
                        border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10)),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                          borderSide: const BorderSide(color: Colors.purple),
                        ),
                      ),
                      validator: (value) =>
                          value?.isEmpty ?? true ? 'Введите локацию' : null,
                    ),
                    SizedBox(height: size.height * 0.02),
                    if (_selectedTabIndex ==
                        0) // Показываем интересы только для Goals
                      Wrap(
                        spacing: 8,
                        children: [
                          'Health',
                          'Yoga',
                          'Sport',
                          'Music',
                          'Science',
                          'Book',
                          'Swimming'
                        ].map((interest) {
                          return ElevatedButton(
                            onPressed: () =>
                                setState(() => _selectedInterest = interest),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: _selectedInterest == interest
                                  ? Colors.purple
                                  : Colors.grey[200],
                              foregroundColor: _selectedInterest == interest
                                  ? Colors.white
                                  : Colors.black,
                            ),
                            child: Text(interest),
                          );
                        }).toList(),
                      ),
                    SizedBox(height: size.height * 0.02),
                    TextFormField(
                      controller: _pointAController,
                      decoration: InputDecoration(
                        labelText: 'Point A',
                        border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10)),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                          borderSide: const BorderSide(color: Colors.purple),
                        ),
                      ),
                      validator: (value) => value?.isEmpty ?? true
                          ? 'Введите начальную точку'
                          : null,
                    ),
                    SizedBox(height: size.height * 0.02),
                    TextFormField(
                      controller: _pointBController,
                      decoration: InputDecoration(
                        labelText: 'Point B',
                        border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10)),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                          borderSide: const BorderSide(color: Colors.purple),
                        ),
                      ),
                      validator: (value) => value?.isEmpty ?? true
                          ? 'Введите конечную точку'
                          : null,
                    ),
                    SizedBox(height: size.height * 0.02),
                    const Text('Tasks'),
                    ListView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: _tasks.length,
                      itemBuilder: (context, index) {
                        return Row(
                          children: [
                            Expanded(child: Text(_tasks[index])),
                            IconButton(
                              icon: const Icon(Icons.close, color: Colors.red),
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
                              hintText: 'Add a task',
                              border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(10)),
                            ),
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.add, color: Colors.purple),
                          onPressed: _addTask,
                        ),
                      ],
                    ),
                    SizedBox(height: size.height * 0.03),
                    ElevatedButton.icon(
                      onPressed: () {},
                      icon: const Icon(Icons.smart_toy),
                      label: const Text('Edit with AI Mentor'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.purple[100],
                        foregroundColor: Colors.black,
                      ),
                    ),
                    SizedBox(height: size.height * 0.02),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: _saveData,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.purple,
                          padding: EdgeInsets.symmetric(
                              vertical: size.height * 0.02),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                        child: const Text('Create',
                            style: TextStyle(color: Colors.white)),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
      bottomNavigationBar: Navbar(
        selectedIndex: 2,
        onTap: (index) {
          _onItemTapped(index);
        },
      ),
    );
  }

  void _onItemTapped(int index) {
    final routes = ['/home', '/search', '/add', '/profile', '/ai-mentor'];
    Navigator.pushReplacementNamed(context, routes[index]);
  }
}
