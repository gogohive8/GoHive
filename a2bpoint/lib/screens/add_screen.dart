import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:developer' as developer;
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
  final TextEditingController _maxParticipantsController = TextEditingController();
  final List<Map<String, dynamic>> _tasks = [];
  final List<File> _photos = [];
  String _privacy = '';
  String? _error;
  bool _isLoading = false;
  late TabController _tabController;
  final PostService _postService = PostService();

  // List of categories matching design
  final List<String> _categories = [
    'Finances',
    'Relationships', 
    'Purpose',
    'Sport',
    'Health',
    'Mental health',
    'Society',
    'Family',
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
          _photos.clear();
          _privacy = '';
        });
      }
    });
  }

  Future<void> _pickPhoto() async {
    if (_photos.length >= 5) {
      setState(() {
        _error = 'Maximum 5 photos allowed';
      });
      return;
    }

    try {
      final picker = ImagePicker();
      final pickedFile = await picker.pickImage(source: ImageSource.gallery);
      if (pickedFile != null) {
        setState(() {
          _photos.add(File(pickedFile.path));
          _error = null;
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

  void _removePhoto(int index) {
    setState(() {
      _photos.removeAt(index);
      _error = null;
    });
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    // Photo validation
    if (_photos.isEmpty) {
      setState(() {
        _error = 'At least 1 photo is required';
      });
      return;
    }

    // Privacy validation
    if (_privacy.isEmpty) {
      setState(() {
        _error = 'Please select privacy setting';
      });
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
      List<String> photoUrls = [];
      for (File photo in _photos) {
        String photoUrl = await _postService.uploadMedia(photo, authProvider.token!);
        photoUrls.add(photoUrl);
      }
      developer.log('Photos uploaded: $photoUrls', name: 'AddScreen');

      if (_tabController.index == 1) {
        // Event
        await _postService.createEvent(
          userId: authProvider.userId!,
          description: _descriptionController.text.trim(),
          location: _locationController.text.trim(),
          interest: _interestController.text.trim(),
          dateTime: _dateTimeController.text.trim(),
          imageUrls: photoUrls,
          token: authProvider.token!,
          privacy: _privacy,
          maxParticipants: _privacy == 'Private' && _maxParticipantsController.text.isNotEmpty 
              ? int.tryParse(_maxParticipantsController.text) 
              : null,
        );
        developer.log('Event created', name: 'AddScreen');
      } else if (_tabController.index == 0) {
        // Goal
        await _postService.createGoal(
          userId: authProvider.userId!,
          description: _descriptionController.text.trim(),
          location: _locationController.text.trim(),
          interest: _interestController.text.trim(),
          pointA: _pointAController.text.trim(),
          pointB: _pointBController.text.trim(),
          tasks: _tasks,
          imageUrls: photoUrls,
          token: authProvider.token!,
          privacy: _privacy,
        );
        developer.log('Goal created', name: 'AddScreen');
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Post created successfully'),
            backgroundColor: Colors.green,
            duration: Duration(seconds: 2),
          ),
        );
        
        await Future.delayed(const Duration(milliseconds: 500));
        
        if (mounted) {
          Navigator.of(context).pushNamedAndRemoveUntil(
            '/home', 
            (route) => false,
          );
        }
      }
    } catch (e, stackTrace) {
      developer.log('Submit error: $e',
          name: 'AddScreen', stackTrace: stackTrace);
      if (mounted) {
        setState(() {
          _error = e.toString();
        });
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  void _addTask() {
    if (_taskController.text.isNotEmpty) {
      setState(() {
        _tasks.add(Task(title: _taskController.text.trim(), completed: false, id: '')
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
    _maxParticipantsController.dispose();
    _tabController.dispose();
    super.dispose();
  }

  Widget _buildPrivacyChips({required bool isEvent}) {
    List<String> options;
    if (isEvent) {
      options = ['Private', 'Public'];
    } else {
      options = ['Private', 'Public', 'Collaboration'];
    }

    return Wrap(
      spacing: 8.0,
      runSpacing: 8.0,
      children: options.map((option) {
        final isSelected = _privacy == option;
        return GestureDetector(
          onTap: () {
            setState(() {
              _privacy = option;
            });
          },
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: isSelected ? Colors.blue[100] : Colors.grey[200],
              borderRadius: BorderRadius.circular(20),
              border: isSelected ? Border.all(color: Colors.blue) : null,
            ),
            child: Text(
              option,
              style: TextStyle(
                color: isSelected ? Colors.blue[800] : Colors.grey[700],
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
              ),
            ),
          ),
        );
      }).toList(),
    );
  }
  Widget _buildCategoryChips() {
    return Wrap(
      spacing: 8.0,
      runSpacing: 8.0,
      children: _categories.map((category) {
        final isSelected = _interestController.text == category;
        return GestureDetector(
          onTap: () {
            setState(() {
              _interestController.text = category;
            });
          },
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: isSelected ? Colors.blue[100] : Colors.grey[200],
              borderRadius: BorderRadius.circular(20),
              border: isSelected ? Border.all(color: Colors.blue) : null,
            ),
            child: Text(
              category,
              style: TextStyle(
                color: isSelected ? Colors.blue[800] : Colors.grey[700],
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildFormContent({required bool isEvent}) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Photo Section
            const Text(
              'Photo',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: Colors.black,
              ),
            ),
            const SizedBox(height: 12),
            
            // Photos grid with add button
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                // Add photo button
                if (_photos.length < 5)
                  GestureDetector(
                    onTap: _pickPhoto,
                    child: Container(
                      width: 80,
                      height: 80,
                      decoration: BoxDecoration(
                        color: Colors.grey[100],
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.grey[300]!),
                      ),
                      child: const Icon(
                        Icons.add_a_photo,
                        size: 30,
                        color: Colors.grey,
                      ),
                    ),
                  ),
                // Selected photos
                ..._photos.asMap().entries.map((entry) {
                  return Stack(
                    children: [
                      Container(
                        width: 80,
                        height: 80,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(12),
                          child: Image.file(
                            entry.value,
                            fit: BoxFit.cover,
                          ),
                        ),
                      ),
                      Positioned(
                        top: 4,
                        right: 4,
                        child: GestureDetector(
                          onTap: () => _removePhoto(entry.key),
                          child: Container(
                            width: 20,
                            height: 20,
                            decoration: const BoxDecoration(
                              color: Colors.red,
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(
                              Icons.close,
                              size: 14,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ),
                    ],
                  );
                }).toList(),
              ],
            ),
            
            if (_photos.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Text(
                  '${_photos.length}/5 photos',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[600],
                  ),
                ),
              ),

            const SizedBox(height: 24),

            // Privacy Settings
            const Text(
              'Privacy Settings',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: Colors.black,
              ),
            ),
            const SizedBox(height: 12),
            _buildPrivacyChips(isEvent: isEvent),

            // Max participants for private events
            if (isEvent && _privacy == 'Private') ...[
              const SizedBox(height: 24),
              const Text(
                'Maximum Participants',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: Colors.black,
                ),
              ),
              const SizedBox(height: 12),
              Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.grey.withValues(alpha: 0.1),
                      blurRadius: 4,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: TextFormField(
                  controller: _maxParticipantsController,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                    border: InputBorder.none,
                    contentPadding: EdgeInsets.all(16),
                    hintText: 'Enter maximum number of participants...',
                    hintStyle: TextStyle(color: Colors.grey),
                  ),
                  validator: (value) {
                    if (_privacy == 'Private' && isEvent && (value == null || value.trim().isEmpty)) {
                      return 'Enter maximum participants for private event';
                    }
                    if (value != null && value.isNotEmpty) {
                      final number = int.tryParse(value);
                      if (number == null || number < 1) {
                        return 'Enter a valid number greater than 0';
                      }
                    }
                    return null;
                  },
                ),
              ),
            ],

            const SizedBox(height: 24),

            // Description
            Text(
              isEvent ? 'Description event' : 'Description goal',
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: Colors.black,
              ),
            ),
            const SizedBox(height: 12),
            Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: Colors.grey.withValues(alpha: 0.1),
                    blurRadius: 4,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: TextFormField(
                controller: _descriptionController,
                decoration: const InputDecoration(
                  border: InputBorder.none,
                  contentPadding: EdgeInsets.all(16),
                  hintText: 'Enter description...',
                  hintStyle: TextStyle(color: Colors.grey),
                ),
                maxLines: 2,
                validator: (value) => value == null || value.trim().isEmpty
                    ? 'Enter description'
                    : null,
              ),
            ),

            const SizedBox(height: 24),

            // Location
            const Text(
              'Location',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: Colors.black,
              ),
            ),
            const SizedBox(height: 12),
            Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: Colors.grey.withValues(alpha: 0.1),
                    blurRadius: 4,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: TextFormField(
                controller: _locationController,
                decoration: const InputDecoration(
                  border: InputBorder.none,
                  contentPadding: EdgeInsets.all(16),
                  hintText: 'Enter location...',
                  hintStyle: TextStyle(color: Colors.grey),
                ),
              ),
            ),

            const SizedBox(height: 24),

            // Interest (Category chips)
            const Text(
              'Interest (Choose one)',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: Colors.black,
              ),
            ),
            const SizedBox(height: 12),
            _buildCategoryChips(),

            const SizedBox(height: 24),

            // Goal-specific fields
            if (!isEvent) ...[
              // Point A
              const Text(
                'Point A',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: Colors.black,
                ),
              ),
              const SizedBox(height: 12),
              Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.grey.withValues(alpha: 0.1),
                      blurRadius: 4,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: TextFormField(
                  controller: _pointAController,
                  decoration: const InputDecoration(
                    border: InputBorder.none,
                    contentPadding: EdgeInsets.all(16),
                    hintText: 'Starting point...',
                    hintStyle: TextStyle(color: Colors.grey),
                  ),
                ),
              ),

              const SizedBox(height: 24),

              // Point B
              const Text(
                'Point B',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: Colors.black,
                ),
              ),
              const SizedBox(height: 12),
              Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.grey.withValues(alpha: 0.1),
                      blurRadius: 4,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: TextFormField(
                  controller: _pointBController,
                  decoration: const InputDecoration(
                    border: InputBorder.none,
                    contentPadding: EdgeInsets.all(16),
                    hintText: 'End goal...',
                    hintStyle: TextStyle(color: Colors.grey),
                  ),
                ),
              ),

              const SizedBox(height: 24),

              // Steps
              const Text(
                'Steps',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: Colors.black,
                ),
              ),
              const SizedBox(height: 12),

              // Tasks List
              if (_tasks.isNotEmpty)
                Column(
                  children: _tasks.asMap().entries.map((entry) {
                    return Container(
                      margin: const EdgeInsets.only(bottom: 8),
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(8),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.grey.withValues(alpha: 0.1),
                            blurRadius: 2,
                            offset: const Offset(0, 1),
                          ),
                        ],
                      ),
                      child: Row(
                        children: [
                          Container(
                            width: 20,
                            height: 20,
                            decoration: BoxDecoration(
                              color: Colors.blue[100],
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Center(
                              child: Text(
                                '#${entry.key + 1}',
                                style: TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.blue[800],
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              entry.value['title'],
                              style: const TextStyle(fontSize: 14),
                            ),
                          ),
                          IconButton(
                            icon: const Icon(Icons.close, size: 18, color: Colors.red),
                            onPressed: () => _removeTask(entry.key),
                            constraints: const BoxConstraints(),
                            padding: EdgeInsets.zero,
                          ),
                        ],
                      ),
                    );
                  }).toList(),
                ),

              // Add task input
              const SizedBox(height: 12),
              Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.grey.withValues(alpha: 0.1),
                      blurRadius: 4,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: TextFormField(
                        controller: _taskController,
                        decoration: const InputDecoration(
                          border: InputBorder.none,
                          contentPadding: EdgeInsets.all(16),
                          hintText: 'Add task',
                          hintStyle: TextStyle(color: Colors.grey),
                        ),
                        onFieldSubmitted: (_) => _addTask(),
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.add, color: Colors.blue),
                      onPressed: _addTask,
                    ),
                  ],
                ),
              ),
            ],

            // Event-specific field
            if (isEvent) ...[
              const Text(
                'Date and Time',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: Colors.black,
                ),
              ),
              const SizedBox(height: 12),
              Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.grey.withValues(alpha: 0.1),
                      blurRadius: 4,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: TextFormField(
                  controller: _dateTimeController,
                  decoration: const InputDecoration(
                    border: InputBorder.none,
                    contentPadding: EdgeInsets.all(16),
                    hintText: 'Select date and time...',
                    hintStyle: TextStyle(color: Colors.grey),
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
            ],

            const SizedBox(height: 32),

            // Error display
            if (_error != null)
              Container(
                margin: const EdgeInsets.only(bottom: 16),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.red[50],
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.red[200]!),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.error, color: Colors.red, size: 20),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        _error!,
                        style: const TextStyle(color: Colors.red, fontSize: 14),
                      ),
                    ),
                  ],
                ),
              ),

            // Create Button
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                onPressed: _isLoading ? null : _submit,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(25),
                  ),
                  elevation: 0,
                ),
                child: _isLoading
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                        ),
                      )
                    : const Text(
                        'Create',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
              ),
            ),

            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.of(context).pop(),
        ),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(50),
          child: Container(
            color: Colors.white,
            child: TabBar(
              controller: _tabController,
              labelColor: Colors.black,
              unselectedLabelColor: Colors.grey,
              indicatorColor: Colors.purple,
              indicatorWeight: 3,
              labelStyle: const TextStyle(
                fontSize: 16, 
                fontWeight: FontWeight.w600
              ),
              tabs: const [
                Tab(text: 'Goal'),
                Tab(text: 'Event'),
              ],
            ),
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
                _buildFormContent(isEvent: true),  // Events
              ],
            ),
      bottomNavigationBar: Navbar(
        selectedIndex: 2,
        onTap: (index) {
          switch (index) {
            case 0:
              Navigator.pushReplacementNamed(context, '/home');
              break;
            case 1:
              Navigator.pushReplacementNamed(context, '/search');
              break;
            case 2:
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