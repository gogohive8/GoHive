import 'dart:convert'; // Для jsonEncode
import 'dart:developer' as developer;
import 'dart:io' show File;
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:http/http.dart' as http; // Для http-запросов
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../services/api_services.dart'; // Для вызова createGoal и createEvent
import 'navbar.dart';

// Предполагаем, что это StatefulWidget для экрана добавления
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
  final ImagePicker _picker = ImagePicker();
  List<XFile> _images = [];
  int _selectedTabIndex = 0;
  String? _selectedInterest;
  List<String> _tasks = [];
  final _taskController = TextEditingController();

  bool _isLoading = false;
  String _errorMessage = '';

  @override
  void initState() {
    super.initState();
    // Инициализация, если была
    _loadInitialData();
  }

  Future<void> _loadInitialData() async {
    // Пример загрузки начальных данных, если был такой функционал
    setState(() {
      _isLoading = true;
    });
    try {
      // Здесь мог быть вызов API для предзагрузки
    } catch (e) {
      setState(() {
        _errorMessage = 'Failed to load initial data: $e';
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  void dispose() {
    _descriptionController.dispose();
    _locationController.dispose();
    _pointAController.dispose();
    _pointBController.dispose();
    _dateTimeController.dispose();
    _taskController.dispose();
    _apiService.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    if (_images.length >= 3) {
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('Maximum 3 photos')));
      return;
    }
    try {
      final pickedFile = await _picker.pickImage(source: ImageSource.gallery);
      if (pickedFile != null) {
        developer.log('Picked image: ${pickedFile.path}', name: 'AddScreen');
        setState(() => _images.add(pickedFile));
      } else {
        developer.log('No image picked', name: 'AddScreen');
      }
    } catch (e) {
      developer.log('Error picking image: $e', name: 'AddScreen');
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('Failed to pick image: $e')));
    }
  }

  void _removeImage(int index) {
    setState(() {
      _images.removeAt(index);
    });
  }

  Future<void> _saveData() async {
    if (_selectedTabIndex == 0 && _selectedInterest == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select an interest')),
      );
      return;
    }
    if (_selectedTabIndex == 1 && _dateTimeController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a date and time')),
      );
      return;
    }
    if (_formKey.currentState!.validate()) {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      if (!authProvider.isAuthenticated ||
          authProvider.userId == null ||
          authProvider.token == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Authorization required')),
        );
        return;
      }
      try {
        developer.log('Saving data: tabIndex=$_selectedTabIndex',
            name: 'AddScreen');
        setState(() {
          _isLoading = true;
        });
        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (context) =>
              const Center(child: CircularProgressIndicator()),
        );

        // Upload images and get URLs
        final imageUrls = _images.isNotEmpty
            ? await _apiService.uploadImages(
                authProvider.userId!,
                _images.map((file) => file.path).toList(),
                authProvider.token!,
              )
            : <String>[];

        final String userId = authProvider.userId!;
        final String token = authProvider.token!;

        if (_selectedTabIndex == 0) {
          await _apiService.createGoal(
            userId,
            _descriptionController.text,
            _locationController.text,
            _selectedInterest!,
            pointA: _pointAController.text.isNotEmpty
                ? _pointAController.text
                : null,
            pointB: _pointBController.text.isNotEmpty
                ? _pointBController.text
                : null,
            tasks: _tasks.isNotEmpty ? _tasks : null,
            imageUrls: imageUrls,
            token: token,
          );
        } else {
          await _apiService.createEvent(
            userId,
            _descriptionController.text,
            _locationController.text,
            _selectedInterest!,
            _dateTimeController.text,
            imageUrls: imageUrls,
            token: token,
          );
        }

        if (mounted) {
          Navigator.pop(context);
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Data saved successfully')),
          );
          _descriptionController.clear();
          _locationController.clear();
          _pointAController.clear();
          _pointBController.clear();
          _dateTimeController.clear();
          setState(() {
            _selectedInterest = null;
            _images.clear();
            _tasks.clear();
            _errorMessage = '';
          });
        }
      } catch (e, stackTrace) {
        developer.log('Save data error: $e',
            name: 'AddScreen', stackTrace: stackTrace);
        if (mounted) {
          Navigator.pop(context);
          setState(() {
            _errorMessage = 'Error saving data: $e';
          });
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error saving data: $e')),
          );
        }
      } finally {
        setState(() {
          _isLoading = false;
        });
      }
    }
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
        toolbarHeight: 0,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
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
                          padding: const EdgeInsets.symmetric(
                              horizontal: 16, vertical: 8),
                          decoration: BoxDecoration(
                            color: _selectedTabIndex == 0
                                ? Colors.purple.withValues(alpha: 0.1)
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
                          padding: const EdgeInsets.symmetric(
                              horizontal: 16, vertical: 8),
                          decoration: BoxDecoration(
                            color: _selectedTabIndex == 1
                                ? Colors.purple.withValues(alpha: 0.1)
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
                                child: SizedBox(
                                  height: 174,
                                  child: _images.isEmpty
                                      ? const SizedBox.shrink()
                                      : ListView.builder(
                                          scrollDirection: Axis.horizontal,
                                          itemCount: _images.length,
                                          itemBuilder: (context, index) {
                                            final image = _images[index];
                                            return Stack(
                                              children: [
                                                Padding(
                                                  padding:
                                                      const EdgeInsets.only(
                                                          left: 8.0),
                                                  child: kIsWeb
                                                      ? FutureBuilder<
                                                          Uint8List>(
                                                          future: image
                                                              .readAsBytes(),
                                                          builder: (context,
                                                              snapshot) {
                                                            if (snapshot
                                                                .hasData) {
                                                              return Image
                                                                  .memory(
                                                                snapshot.data!,
                                                                width: 50,
                                                                height: 174,
                                                                fit: BoxFit
                                                                    .cover,
                                                              );
                                                            }
                                                            return const CircularProgressIndicator();
                                                          },
                                                        )
                                                      : Image.file(
                                                          File(image.path),
                                                          width: 50,
                                                          height: 174,
                                                          fit: BoxFit.cover,
                                                        ),
                                                ),
                                                Positioned(
                                                  top: 0,
                                                  right: 0,
                                                  child: IconButton(
                                                    icon: const Icon(
                                                        Icons.close,
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
                                borderSide:
                                    const BorderSide(color: Colors.purple),
                              ),
                            ),
                            validator: (value) => value?.isEmpty ?? true
                                ? 'Enter description'
                                : null,
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
                                borderSide:
                                    const BorderSide(color: Colors.purple),
                              ),
                            ),
                            validator: (value) => value?.isEmpty ?? true
                                ? 'Enter location'
                                : null,
                          ),
                          SizedBox(height: size.height * 0.02),
                          if (_selectedTabIndex == 0)
                            Wrap(
                              spacing: 8,
                              children: [
                                'Health',
                                'Yoga',
                                'Sport',
                                'Music',
                                'Science',
                                'Book',
                                'Swimming',
                              ].map((interest) {
                                return ElevatedButton(
                                  onPressed: () => setState(
                                      () => _selectedInterest = interest),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor:
                                        _selectedInterest == interest
                                            ? Colors.purple
                                            : Colors.grey[200],
                                    foregroundColor:
                                        _selectedInterest == interest
                                            ? Colors.white
                                            : Colors.black,
                                  ),
                                  child: Text(interest),
                                );
                              }).toList(),
                            ),
                          SizedBox(height: size.height * 0.02),
                          if (_selectedTabIndex == 1)
                            TextFormField(
                              controller: _dateTimeController,
                              decoration: InputDecoration(
                                labelText: 'Date and Time',
                                border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(10)),
                                focusedBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(10),
                                  borderSide:
                                      const BorderSide(color: Colors.purple),
                                ),
                                suffixIcon: IconButton(
                                  icon: const Icon(Icons.calendar_today),
                                  onPressed: _selectDateTime,
                                ),
                              ),
                              readOnly: true,
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
                                borderSide:
                                    const BorderSide(color: Colors.purple),
                              ),
                            ),
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
                                borderSide:
                                    const BorderSide(color: Colors.purple),
                              ),
                            ),
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
                                    icon: const Icon(Icons.close,
                                        color: Colors.red),
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
                                        borderRadius:
                                            BorderRadius.circular(10)),
                                  ),
                                ),
                              ),
                              IconButton(
                                icon:
                                    const Icon(Icons.add, color: Colors.purple),
                                onPressed: _addTask,
                              ),
                            ],
                          ),
                          SizedBox(height: size.height * 0.03),
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
