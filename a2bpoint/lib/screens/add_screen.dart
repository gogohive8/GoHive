import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:developer' as developer;
import '../services/api_services.dart';
import '../services/post_service.dart';
import '../providers/auth_provider.dart';
import '../services/exceptions.dart';
import 'navbar.dart';
import '../models/tasks.dart';

class AddScreen extends StatefulWidget {
  const AddScreen({super.key});

  @override
  _AddScreenState createState() => _AddScreenState();
}

class _AddScreenState extends State<AddScreen>
    with SingleTickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _descriptionController = TextEditingController();
  final TextEditingController _locationController = TextEditingController();
  final TextEditingController _interestController = TextEditingController();
  final TextEditingController _dateTimeController = TextEditingController();
  final TextEditingController _pointAController = TextEditingController();
  final TextEditingController _pointBController = TextEditingController();
  final TextEditingController _taskController = TextEditingController();
  final List<Map<String, dynamic>> _tasks = [];
  File? _photo;
  String? _error;
  bool _isLoading = false;
  late TabController _tabController;
  final ApiService _apiService = ApiService();
  final PostService _postService = PostService();

  // List of categories
  final List<String> _categories = [
    'Money',
    'Relationships',
    'Purpose',
    'Health',
    'Mental Health',
    'Society',
    'Others',
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _tabController.addListener(() {
      if (_tabController.indexIsChanging) {
        setState(() {
          _error = null;
          _formKey.currentState?.reset();
          _descriptionController.clear();
          _locationController.clear();
          _interestController.clear();
          _dateTimeController.clear();
          _pointAController.clear();
          _pointBController.clear();
          _taskController.clear();
          _tasks.clear();
          _photo = null;
        });
      }
    });
  }

  Future<void> _pickPhoto() async {
    try {
      final picker = ImagePicker();
      final pickedFile = await picker.pickImage(source: ImageSource.gallery);
      if (pickedFile != null) {
        setState(() {
          _photo = File(pickedFile.path);
        });
        developer.log('Photo picked: ${pickedFile.path}', name: 'AddScreen');
      }
    } catch (e, stackTrace) {
      developer.log('Pick photo error: $e',
          name: 'AddScreen', stackTrace: stackTrace);
      setState(() {
        _error = 'Error picking photo: $e';
      });
    }
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

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
      String? photoUrl;
      if (_photo != null) {
        photoUrl = await _postService.uploadMedia(_photo!, authProvider.token!);
        developer.log('Photo uploaded: $photoUrl', name: 'AddScreen');
      }

      if (_tabController.index == 1) {
        // Event
        await _postService.createEvent(
          userId: authProvider.userId!,
          description: _descriptionController.text.trim(),
          location: _locationController.text.trim(),
          interest: _interestController.text.trim(),
          dateTime: _dateTimeController.text.trim(),
          imageUrls: photoUrl != null ? [photoUrl] : null,
          token: authProvider.token!,
        );
        developer.log('Event created', name: 'AddScreen');
      } else {
        // Goal
        await _postService.createGoal(
          userId: authProvider.userId!,
          description: _descriptionController.text.trim(),
          location: _locationController.text.trim(),
          interest: _interestController.text.trim(),
          pointA: _pointAController.text.trim(),
          pointB: _pointBController.text.trim(),
          tasks: _tasks,
          imageUrls: photoUrl != null ? [photoUrl] : null,
          token: authProvider.token!,
        );
        developer.log('Goal created', name: 'AddScreen');
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Post created successfully'),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.pop(context);
      }
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
        _tasks.add(Task(title: _taskController.text.trim(), completed: false)
            .toJson());
        _taskController.clear();
      });
      developer.log('Task added: ${_tasks.last}', name: 'AddScreen');
    }
  }

  void _removeTask(int index) {
    setState(() {
      _tasks.removeAt(index);
    });
    developer.log('Task removed at index: $index', name: 'AddScreen');
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
    _tabController.dispose();
    super.dispose();
  }

  Widget _buildFormContent({required bool isEvent}) {
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;
    final padding = screenWidth * 0.0427; // ~16dp for 375dp width
    final maxWidth = screenWidth - 2 * padding;

    return SingleChildScrollView(
      padding: EdgeInsets.all(padding),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Photo Section
            const Padding(
              padding: EdgeInsets.only(top: 20.0),
              child: Text(
                'Photo',
                style: TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF333333),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.only(top: 12.0),
              child: GestureDetector(
                onTap: _pickPhoto,
                child: Container(
                  width: double.infinity,
                  height: 200,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(10.0),
                    border: Border.all(color: Colors.grey[300]!),
                  ),
                  child: _photo != null
                      ? ClipRRect(
                          borderRadius: BorderRadius.circular(10.0),
                          child: Image.file(
                            _photo!,
                            fit: BoxFit.cover,
                            width: double.infinity,
                            height: 200,
                          ),
                        )
                      : const Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.camera_alt,
                                size: 50,
                                color: Color(0xFF666666),
                              ),
                              SizedBox(height: 8),
                              Text(
                                'Tap to add photo',
                                style: TextStyle(
                                  color: Color(0xFF666666),
                                  fontSize: 14,
                                ),
                              ),
                            ],
                          ),
                        ),
                ),
              ),
            ),

            // Description
            Padding(
              padding: const EdgeInsets.only(top: 20.0),
              child: TextFormField(
                controller: _descriptionController,
                decoration: InputDecoration(
                  labelText: 'Description',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8.0),
                  ),
                ),
                maxLines: 3,
                validator: (value) => value == null || value.trim().isEmpty
                    ? 'Enter description'
                    : null,
              ),
            ),

            // Location
            Padding(
              padding: const EdgeInsets.only(top: 20.0),
              child: TextFormField(
                controller: _locationController,
                decoration: InputDecoration(
                  labelText: 'Location',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8.0),
                  ),
                  prefixIcon: const Icon(Icons.location_on),
                ),
              ),
            ),

            // Category
            Padding(
              padding: const EdgeInsets.only(top: 20.0),
              child: DropdownButtonFormField<String>(
                value: _interestController.text.isEmpty
                    ? null
                    : _interestController.text,
                decoration: InputDecoration(
                  labelText: 'Category',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8.0),
                  ),
                  prefixIcon: const Icon(Icons.category),
                ),
                items: _categories
                    .map((category) => DropdownMenuItem(
                          value: category,
                          child: Text(category),
                        ))
                    .toList(),
                onChanged: (value) {
                  setState(() {
                    _interestController.text = value ?? '';
                  });
                },
                validator: (value) =>
                    value == null ? 'Select a category' : null,
              ),
            ),

            // Goal-specific fields
            if (!isEvent) ...[
              // Point A
              Padding(
                padding: const EdgeInsets.only(top: 20.0),
                child: TextFormField(
                  controller: _pointAController,
                  decoration: InputDecoration(
                    labelText: 'Point A (Starting Point)',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8.0),
                    ),
                    prefixIcon: const Icon(Icons.flag),
                  ),
                ),
              ),

              // Point B
              Padding(
                padding: const EdgeInsets.only(top: 20.0),
                child: TextFormField(
                  controller: _pointBController,
                  decoration: InputDecoration(
                    labelText: 'Point B (End Goal)',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8.0),
                    ),
                    prefixIcon: const Icon(Icons.outlined_flag),
                  ),
                ),
              ),

              // Tasks
              Padding(
                padding: const EdgeInsets.only(top: 20.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Tasks',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF333333),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Expanded(
                          child: TextFormField(
                            controller: _taskController,
                            decoration: InputDecoration(
                              hintText: 'Add a task',
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(8.0),
                              ),
                              prefixIcon: const Icon(Icons.task_alt),
                            ),
                            onFieldSubmitted: (_) => _addTask(),
                          ),
                        ),
                        const SizedBox(width: 8),
                        ElevatedButton(
                          onPressed: _addTask,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFFAFCBEA),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8.0),
                            ),
                          ),
                          child: const Icon(Icons.add),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              // Tasks List
              if (_tasks.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.only(top: 12.0),
                  child: Container(
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.grey[300]!),
                      borderRadius: BorderRadius.circular(8.0),
                    ),
                    child: Column(
                      children: _tasks
                          .asMap()
                          .entries
                          .map((entry) => ListTile(
                                leading: const Icon(Icons.task_alt, size: 20),
                                title: Text(entry.value['title']),
                                trailing: IconButton(
                                  icon: const Icon(Icons.delete,
                                      color: Colors.red),
                                  onPressed: () => _removeTask(entry.key),
                                ),
                              ))
                          .toList(),
                    ),
                  ),
                ),
            ],

            // Event-specific field
            if (isEvent)
              Padding(
                padding: const EdgeInsets.only(top: 20.0),
                child: TextFormField(
                  controller: _dateTimeController,
                  decoration: InputDecoration(
                    labelText: 'Date and Time',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8.0),
                    ),
                    prefixIcon: const Icon(Icons.calendar_today),
                  ),
                  validator: (value) => value == null || value.trim().isEmpty
                      ? 'Enter date and time'
                      : null,
                  onTap: () async {
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
                        final dateTime = DateTime(
                          date.year,
                          date.month,
                          date.day,
                          time.hour,
                          time.minute,
                        );
                        _dateTimeController.text = dateTime.toIso8601String();
                      }
                    }
                  },
                  readOnly: true,
                ),
              ),

            // Error display
            if (_error != null)
              Padding(
                padding: const EdgeInsets.only(top: 16.0),
                child: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.red[50],
                    borderRadius: BorderRadius.circular(8.0),
                    border: Border.all(color: Colors.red[200]!),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.error, color: Colors.red),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          _error!,
                          style: const TextStyle(color: Colors.red),
                        ),
                      ),
                    ],
                  ),
                ),
              ),

            // Submit Button
            Padding(
              padding: EdgeInsets.only(top: 32.0, bottom: screenHeight * 0.05),
              child: SizedBox(
                width: double.infinity,
                height: 48,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _submit,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFAFCBEA),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8.0),
                    ),
                    elevation: 2,
                  ),
                  child: _isLoading
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor:
                                AlwaysStoppedAnimation<Color>(Colors.white),
                          ),
                        )
                      : Text(
                          isEvent ? 'Create Event' : 'Create Goal',
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF4F3EE),
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(60.0),
        child: AppBar(
          backgroundColor: Colors.white,
          elevation: 2,
          title: TabBar(
            controller: _tabController,
            labelColor: Colors.black,
            unselectedLabelColor: Colors.grey,
            indicatorColor: const Color(0xFFAFCBEA),
            labelStyle:
                const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            tabs: const [
              Tab(text: 'Goals'),
              Tab(text: 'Events'),
            ],
          ),
        ),
      ),
      body: _isLoading
          ? const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(),
                  SizedBox(height: 16),
                  Text('Creating post...'),
                ],
              ),
            )
          : TabBarView(
              controller: _tabController,
              children: [
                _buildFormContent(isEvent: false), // Goals
                _buildFormContent(isEvent: true), // Events
              ],
            ),
      bottomNavigationBar: Navbar(
        selectedIndex: 2, // Add tab
        onTap: (index) {
          switch (index) {
            case 0:
              Navigator.pushReplacementNamed(context, '/home');
              break;
            case 1:
              Navigator.pushReplacementNamed(context, '/search');
              break;
            case 2:
              // Уже на этом экране
              break;
            case 3:
              Navigator.pushReplacementNamed(context, '/profile');
              break;
            case 4:
              Navigator.pushReplacementNamed(context, '/ai_mentor');
              break;
          }
        },
      ),
    );
  }
}
