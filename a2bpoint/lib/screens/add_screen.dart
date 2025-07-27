import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:developer' as developer;
import '../services/api_services.dart';
import '../providers/auth_provider.dart';
import '../services/exceptions.dart';
import 'navbar.dart';

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
        photoUrl = await _apiService.uploadMedia(_photo!, authProvider.token!);
        developer.log('Photo uploaded: $photoUrl', name: 'AddScreen');
      }

      if (_tabController.index == 1) {
        // Event
        await _apiService.createEvent(
          userId: authProvider.userId!,
          description: _descriptionController.text.trim(),
          location: _locationController.text.trim(),
          interest: _interestController.text.trim(),
          dateTime: _dateTimeController.text.trim(),
          image_urls: photoUrl != null ? [photoUrl] : null,
          token: authProvider.token!,
        );
        developer.log('Event created', name: 'AddScreen');
      } else {
        // Goal
        await _apiService.createGoal(
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
          const SnackBar(content: Text('Post created successfully')),
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
        _tasks.add({'title': _taskController.text.trim(), 'completed': false});
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
    _tabController.dispose();
    super.dispose();
  }

  Widget _buildFormContent({required bool isEvent}) {
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;
    final padding = screenWidth * 0.0427; // ~16dp for 375dp width
    final maxWidth = screenWidth - 2 * padding;
    final photoSize = screenWidth > 156 ? 156.0 : screenWidth * 0.416;

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
                  fontSize: 14,
                  fontWeight: FontWeight.normal,
                  color: Color(0xFF333333),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.only(top: 28.0),
              child: GestureDetector(
                onTap: _pickPhoto,
                child: Container(
                  width: photoSize,
                  height: photoSize * 174 / 563,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(10.0),
                  ),
                  child: _photo != null
                      ? ClipRRect(
                          borderRadius: BorderRadius.circular(10.0),
                          child: Image.file(
                            _photo!,
                            fit: BoxFit.cover,
                            width: photoSize,
                            height: photoSize * 174 / 563,
                          ),
                        )
                      : const Center(
                          child: Icon(
                            Icons.camera_alt,
                            size: 50,
                            color: Color(0xFF333333),
                          ),
                        ),
                ),
              ),
            ),
            // Description
            Padding(
              padding: const EdgeInsets.only(top: 20.0),
              child: SizedBox(
                width: maxWidth > 343 ? 343 : maxWidth,
                height: 76,
                child: TextFormField(
                  controller: _descriptionController,
                  decoration: const InputDecoration(labelText: 'Description'),
                  validator: (value) => value == null || value.trim().isEmpty
                      ? 'Enter description'
                      : null,
                ),
              ),
            ),
            // Location
            Padding(
              padding: const EdgeInsets.only(top: 20.0),
              child: SizedBox(
                width: maxWidth > 343 ? 343 : maxWidth,
                height: 76,
                child: TextFormField(
                  controller: _locationController,
                  decoration: const InputDecoration(labelText: 'Location'),
                ),
              ),
            ),
            // Category
            Padding(
              padding: const EdgeInsets.only(top: 20.0),
              child: SizedBox(
                width: maxWidth > 343 ? 343 : maxWidth,
                height: 76,
                child: DropdownButtonFormField<String>(
                  value: _interestController.text.isEmpty
                      ? null
                      : _interestController.text,
                  decoration: const InputDecoration(labelText: 'Category'),
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
            ),
            // Goal-specific fields
            if (!isEvent) ...[
              // Point A
              Padding(
                padding: const EdgeInsets.only(top: 20.0),
                child: SizedBox(
                  width: maxWidth > 343 ? 343 : maxWidth,
                  height: 76,
                  child: TextFormField(
                    controller: _pointAController,
                    decoration: const InputDecoration(labelText: 'Point A'),
                  ),
                ),
              ),
              // Point B
              Padding(
                padding: const EdgeInsets.only(top: 20.0),
                child: SizedBox(
                  width: maxWidth > 343 ? 343 : maxWidth,
                  height: 76,
                  child: TextFormField(
                    controller: _pointBController,
                    decoration: const InputDecoration(labelText: 'Point B'),
                  ),
                ),
              ),
              // Tasks
              Padding(
                padding: const EdgeInsets.only(top: 20.0),
                child: SizedBox(
                  width: maxWidth > 343 ? 343 : maxWidth,
                  height: 108,
                  child: TextFormField(
                    controller: _taskController,
                    decoration: const InputDecoration(labelText: 'Tasks'),
                    onFieldSubmitted: (_) => _addTask(),
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.only(top: 8.0),
                child: ElevatedButton(
                  onPressed: _addTask,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFAFCBEA),
                  ),
                  child: const Text('Add Task'),
                ),
              ),
              if (_tasks.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.only(top: 8.0),
                  child: SizedBox(
                    width: maxWidth > 343 ? 343 : maxWidth,
                    child: Column(
                      children: _tasks
                          .asMap()
                          .entries
                          .map((entry) => ListTile(
                                title: Text(entry.value['title']),
                                trailing: IconButton(
                                  icon: const Icon(Icons.delete),
                                  color: const Color(0xFF333333),
                                  onPressed: () {
                                    setState(() {
                                      _tasks.removeAt(entry.key);
                                    });
                                  },
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
                child: SizedBox(
                  width: maxWidth > 343 ? 343 : maxWidth,
                  height: 76,
                  child: TextFormField(
                    controller: _dateTimeController,
                    decoration:
                        const InputDecoration(labelText: 'Date and Time'),
                    validator: (value) => value == null || value.trim().isEmpty
                        ? 'Enter date and time'
                        : null,
                    onTap: () async {
                      final date = await showDatePicker(
                        context: context,
                        initialDate: DateTime.now(),
                        firstDate: DateTime(2000),
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
              ),
            if (_error != null)
              Padding(
                padding: const EdgeInsets.only(top: 16.0),
                child: Text(
                  _error!,
                  style: const TextStyle(color: Colors.red),
                ),
              ),
            Padding(
              padding: EdgeInsets.only(top: 20.0, bottom: screenHeight * 0.05),
              child: SizedBox(
                width: maxWidth > 343 ? 343 : maxWidth,
                height: 48,
                child: ElevatedButton(
                  onPressed: _submit,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFAFCBEA),
                  ),
                  child: const Text('Create'),
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
          ? const Center(child: CircularProgressIndicator())
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
