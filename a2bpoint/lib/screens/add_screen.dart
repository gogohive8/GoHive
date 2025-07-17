import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import 'dart:developer' as developer;
import '../services/api_services.dart';
import '../services/exceptions.dart';
import '../providers/auth_provider.dart';

class AddScreen extends StatefulWidget {
  const AddScreen({super.key});

  @override
  _AddScreenState createState() => _AddScreenState();
}

class _AddScreenState extends State<AddScreen> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _descriptionController = TextEditingController();
  final TextEditingController _locationController = TextEditingController();
  final TextEditingController _interestController = TextEditingController();
  final TextEditingController _dateTimeController = TextEditingController();
  final TextEditingController _pointAController = TextEditingController();
  final TextEditingController _pointBController = TextEditingController();
  final TextEditingController _taskController = TextEditingController();
  final List<Map<String, dynamic>> _tasks = [];
  File? _image;
  bool _isEvent = false;
  bool _isLoading = false;
  String? _error;
  final ApiService _apiService = ApiService();

  Future<void> _pickImage() async {
    try {
      final picker = ImagePicker();
      final pickedFile = await picker.pickImage(source: ImageSource.gallery);
      if (pickedFile != null) {
        setState(() {
          _image = File(pickedFile.path);
        });
        developer.log('Image picked: ${pickedFile.path}', name: 'AddScreen');
      }
    } catch (e, stackTrace) {
      developer.log('Pick image error: $e',
          name: 'AddScreen', stackTrace: stackTrace);
      setState(() {
        _error = 'Ошибка выбора изображения: $e';
      });
    }
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    if (!authProvider.isAuthenticated ||
        authProvider.token == null ||
        authProvider.userId == null) {
      authProvider.handleAuthError(
          context, AuthenticationException('Not authenticated'));
      return;
    }

    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      String? imageUrl;
      if (_image != null) {
        imageUrl = await _apiService.uploadMedia(_image!, authProvider.token!);
        developer.log('Image uploaded: $imageUrl', name: 'AddScreen');
      }

      if (_isEvent) {
        await _apiService.createEvent(
          userId: authProvider.userId!,
          description: _descriptionController.text,
          location: _locationController.text,
          interest: _interestController.text,
          dateTime: _dateTimeController.text,
          token: authProvider.token!,
        );
        developer.log('Event created', name: 'AddScreen');
      } else {
        await _apiService.createGoal(
          userId: authProvider.userId!,
          description: _descriptionController.text,
          location: _locationController.text,
          interest: _interestController.text,
          pointA: _pointAController.text,
          pointB: _pointBController.text,
          tasks: _tasks,
          imageUrls: imageUrl != null ? [imageUrl] : null,
          token: authProvider.token!,
        );
        developer.log('Goal created', name: 'AddScreen');
      }

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Пост успешно создан')),
      );
      Navigator.pop(context);
    } catch (e, stackTrace) {
      developer.log('Submit error: $e',
          name: 'AddScreen', stackTrace: stackTrace);
      setState(() {
        _error = e.toString();
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _addTask() {
    if (_taskController.text.isNotEmpty) {
      setState(() {
        _tasks.add({'title': _taskController.text, 'completed': false});
        _taskController.clear();
      });
      developer.log('Task added: ${_tasks.last}', name: 'AddScreen');
    }
  }

  @override
  void dispose() {
    _descriptionController.dispose();
    _locationController.dispose();
    _interestController.dispose();
    _dateTimeController.dispose();
    _pointAController.dispose();
    _pointBController.dispose();
    _taskController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Создать пост'),
        backgroundColor: const Color(0xFFF9F6F2),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SwitchListTile(
                      title: const Text('Создать событие'),
                      value: _isEvent,
                      onChanged: (value) {
                        setState(() {
                          _isEvent = value;
                        });
                      },
                    ),
                    TextFormField(
                      controller: _descriptionController,
                      decoration: const InputDecoration(labelText: 'Описание'),
                      validator: (value) =>
                          value!.isEmpty ? 'Введите описание' : null,
                    ),
                    TextFormField(
                      controller: _locationController,
                      decoration:
                          const InputDecoration(labelText: 'Местоположение'),
                      validator: (value) =>
                          value!.isEmpty ? 'Введите местоположение' : null,
                    ),
                    TextFormField(
                      controller: _interestController,
                      decoration: const InputDecoration(labelText: 'Категория'),
                      validator: (value) =>
                          value!.isEmpty ? 'Введите категорию' : null,
                    ),
                    if (_isEvent)
                      TextFormField(
                        controller: _dateTimeController,
                        decoration:
                            const InputDecoration(labelText: 'Дата и время'),
                        validator: (value) =>
                            value!.isEmpty ? 'Введите дату и время' : null,
                      ),
                    if (!_isEvent) ...[
                      TextFormField(
                        controller: _pointAController,
                        decoration: const InputDecoration(labelText: 'Точка А'),
                      ),
                      TextFormField(
                        controller: _pointBController,
                        decoration: const InputDecoration(labelText: 'Точка Б'),
                      ),
                      TextFormField(
                        controller: _taskController,
                        decoration: const InputDecoration(labelText: 'Шаги'),
                        onFieldSubmitted: (_) => _addTask(),
                      ),
                      ElevatedButton(
                        onPressed: _addTask,
                        child: const Text('Добавить задачу'),
                      ),
                      if (_tasks.isNotEmpty)
                        Column(
                          children: _tasks
                              .asMap()
                              .entries
                              .map((entry) => ListTile(
                                    title: Text(entry.value['title']),
                                    trailing: IconButton(
                                      icon: const Icon(Icons.delete),
                                      onPressed: () {
                                        setState(() {
                                          _tasks.removeAt(entry.key);
                                        });
                                      },
                                    ),
                                  ))
                              .toList(),
                        ),
                    ],
                    const SizedBox(height: 16),
                    ElevatedButton(
                      onPressed: _pickImage,
                      child: const Text('Выбрать изображение'),
                    ),
                    if (_image != null)
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 8.0),
                        child: Image.file(
                          _image!,
                          height: 100,
                          width: 100,
                          fit: BoxFit.cover,
                        ),
                      ),
                    if (_error != null)
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 8.0),
                        child: Text(
                          _error!,
                          style: const TextStyle(color: Colors.red),
                        ),
                      ),
                    const SizedBox(height: 16),
                    ElevatedButton(
                      onPressed: _submit,
                      child: const Text('Создать'),
                    ),
                  ],
                ),
              ),
            ),
    );
  }
}
