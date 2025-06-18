import 'dart:developer' as developer;
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
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
  final _dateTimeController = TextEditingController();
  final ImagePicker _picker = ImagePicker();
  List<File> _images = [];
  int _selectedTabIndex = 0;
  String? _selectedInterest;
  List<String> _tasks = [];
  final _taskController = TextEditingController();

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
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Maximum 3 photos')),
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
        developer.log('Uploading image: $fileName', name: 'AddScreen');
        await _apiService.supabase.storage
            .from('images')
            .upload(fileName, image);
        final url =
            _apiService.supabase.storage.from('images').getPublicUrl(fileName);
        imageUrls.add(url);
      } catch (e, stackTrace) {
        developer.log('Image upload error: $e',
            name: 'AddScreen', stackTrace: stackTrace);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error uploading image: $e')),
          );
        }
      }
    }
    return imageUrls;
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
        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (context) =>
              const Center(child: CircularProgressIndicator()),
        );

        final imageUrls = await _uploadImages();
        final userId = authProvider.userId!;
        final token = authProvider.token!;

        if (_selectedTabIndex == 0) {
          await _apiService.createGoal(
            userId,
            _descriptionController.text,
            _locationController.text,
            _selectedInterest!,
            pointA: _pointAController.text,
            pointB: _pointBController.text,
            tasks: _tasks,
            imageUrls: imageUrls,
            token: token,
          );
        } else {
          await _apiService.createEvent(
            userId,
            _descriptionController.text,
            _locationController.text,
            _selectedInterest ?? 'General',
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
          });
        }
      } catch (e, stackTrace) {
        developer.log('Save data error: $e',
            name: 'AddScreen', stackTrace: stackTrace);
        if (mounted) {
          Navigator.pop(context);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error saving data: $e')),
          );
        }
      }
    }
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
                    padding:
                        const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
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
                                      return Stack(
                                        children: [
                                          Padding(
                                            padding: const EdgeInsets.only(
                                                left: 8.0),
                                            child: Image.file(
                                              _images[index],
                                              width: 50,
                                              height: 174,
                                              fit: BoxFit.cover,
                                            ),
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
                          value?.isEmpty ?? true ? 'Enter description' : null,
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
                          borderSide: const BorderSide(color: Colors.white),
                        ),
                      ),
                      validator: (value) =>
                          value?.isEmpty ?? true ? 'Enter location' : null,
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
                    if (_selectedTabIndex == 1)
                      TextFormField(
                        controller: _dateTimeController,
                        decoration: InputDecoration(
                          labelText: 'Date and Time',
                          border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(10)),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                            borderSide: const BorderSide(color: Colors.purple),
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
                          borderSide: const BorderSide(color: Colors.purple),
                        ),
                      ),
                      validator: (value) => value?.isEmpty ?? true
                          ? 'Enter starting point'
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
                      validator: (value) =>
                          value?.isEmpty ?? true ? 'Enter destination' : null,
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
          final routes = ['/home', '/search', '/add', '/profile', '/ai-mentor'];
          Navigator.pushReplacementNamed(context, routes[index]);
        },
      ),
    );
  }
}
