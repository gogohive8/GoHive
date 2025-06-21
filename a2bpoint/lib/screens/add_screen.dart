import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'dart:developer' as developer;
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
  final _taskController = TextEditingController();
  // // Комментарий: Закомментировано для удаления функционала фотографий
  // final ImagePicker _picker = ImagePicker();
  // List<XFile> _images = [];

  int _selectedTabIndex = 0;
  String? _selectedInterest;
  List<Map<String, dynamic>> _tasks = [];
  bool _isLoading = false;
  String _errorMessage = '';

  @override
  void initState() {
    super.initState();
    _loadInitialData();
  }

  Future<void> _loadInitialData() async {
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
    super.dispose();
  }

  // // Комментарий: Закомментировано для удаления функционала фотографий
  // Future<void> _pickImage() async {
  //   if (_images.length >= 3) {
  //     ScaffoldMessenger.of(context)
  //         .showSnackBar(const SnackBar(content: Text('Maximum 3 photos')));
  //     return;
  //   }
  //   try {
  //     final pickedFile = await _picker.pickImage(source: ImageSource.gallery);
  //     if (pickedFile != null) {
  //       developer.log('Picked image: ${pickedFile.path}', name: 'AddScreen');
  //       setState(() => _images.add(pickedFile));
  //     } else {
  //       developer.log('No image picked', name: 'AddScreen');
  //     }
  //   } catch (e) {
  //     developer.log('Error picking image: $e', name: 'AddScreen');
  //     ScaffoldMessenger.of(context)
  //         .showSnackBar(SnackBar(content: Text('Failed to pick image: $e')));
  //   }
  // }

  // // Комментарий: Закомментировано для удаления функционала фотографий
  // void _removeImage(int index) {
  //   setState(() {
  //     _images.removeAt(index);
  //   });
  // }

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

        final imageUrls = <String>[]; // Пустой список для imageUrls
        final String userId = authProvider.userId!;
        final String token = authProvider.token!;

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
            imageUrls: imageUrls.isNotEmpty ? imageUrls : null,
            token: token,
          );
        } else {
          await _apiService.createEvent(
            userId: userId,
            description: _descriptionController.text,
            location: _locationController.text,
            interest: _selectedInterest!,
            dateTime: _dateTimeController.text,
            imageUrls: imageUrls.isNotEmpty ? imageUrls : null,
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
          if (e.toString().contains('Неавторизован')) {
            // TODO: Убедитесь, что метод logout реализован в AuthProvider
            // await authProvider.logout();
            Navigator.pushReplacementNamed(context, '/sign_in');
          }
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

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final padding = size.width * 0.05;

    return Scaffold(
      backgroundColor: const Color(0xFFF9F6F2), // Светло-бежевый фон
      appBar: AppBar(
        elevation: 0,
        backgroundColor: const Color(0xFFF9F6F2),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Color(0xFF333333)), // Серый
          onPressed: () => Navigator.pushReplacementNamed(
              context, '/profile'), // Ведёт на ProfileScreen
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  color: const Color(0xFFF9F6F2), // Светло-бежевый
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
                                ? const Color.fromRGBO(175, 203, 234,
                                    0.1) // Голубой с прозрачностью
                                : Colors.transparent,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            'Goal',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: _selectedTabIndex == 0
                                  ? const Color(0xFFAFCBEA) // Голубой
                                  : const Color(0xFF333333), // Серый
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
                                ? const Color.fromRGBO(175, 203, 234, 0.1)
                                : Colors.transparent,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            'Event',
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
                    padding: EdgeInsets.all(padding),
                    child: Form(
                      key: _formKey,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          TextFormField(
                            controller: _descriptionController,
                            decoration: InputDecoration(
                              labelText: 'Description',
                              labelStyle: const TextStyle(
                                  color: Color(0xFF1A1A1A)), // Тёмно-серый
                              filled: true,
                              fillColor: const Color.fromRGBO(
                                  221, 221, 221, 0.2), // Светло-серый
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(10),
                                borderSide: BorderSide.none,
                              ),
                              prefixIcon: const Icon(Icons.description,
                                  color: Color(0xFF333333)), // Серый
                            ),
                            style: const TextStyle(
                                color: Color(0xFF1A1A1A)), // Тёмно-серый
                            validator: (value) => value?.isEmpty ?? true
                                ? 'Enter description'
                                : null,
                          ),
                          SizedBox(height: size.height * 0.02),
                          TextFormField(
                            controller: _locationController,
                            decoration: InputDecoration(
                              labelText: 'Location',
                              labelStyle:
                                  const TextStyle(color: Color(0xFF1A1A1A)),
                              filled: true,
                              fillColor:
                                  const Color.fromRGBO(221, 221, 221, 0.2),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(10),
                                borderSide: BorderSide.none,
                              ),
                              prefixIcon: const Icon(Icons.location_on,
                                  color: Color(0xFF333333)),
                            ),
                            style: const TextStyle(color: Color(0xFF1A1A1A)),
                            validator: (value) => value?.isEmpty ?? true
                                ? 'Enter location'
                                : null,
                          ),
                          SizedBox(height: size.height * 0.02),
                          if (_selectedTabIndex == 0)
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'Interests',
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    color: Color(0xFF000000), // Чёрный
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Wrap(
                                  spacing: 8,
                                  runSpacing: 8,
                                  children: [
                                    'Health',
                                    'Yoga',
                                    'Sport',
                                    'Music',
                                    'Science',
                                    'Book',
                                    'Swimming',
                                  ].map((interest) {
                                    return ChoiceChip(
                                      label: Text(interest),
                                      selected: _selectedInterest == interest,
                                      onSelected: (selected) => setState(() =>
                                          _selectedInterest =
                                              selected ? interest : null),
                                      selectedColor:
                                          const Color(0xFFAFCBEA), // Голубой
                                      labelStyle: TextStyle(
                                        color: _selectedInterest == interest
                                            ? const Color(0xFF000000) // Чёрный
                                            : const Color(
                                                0xFF1A1A1A), // Тёмно-серый
                                      ),
                                      backgroundColor: const Color.fromRGBO(
                                          221, 221, 221, 0.2), // Светло-серый
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
                                labelText: 'Date and Time',
                                labelStyle:
                                    const TextStyle(color: Color(0xFF1A1A1A)),
                                filled: true,
                                fillColor:
                                    const Color.fromRGBO(221, 221, 221, 0.2),
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
                                labelText: 'Point A',
                                labelStyle:
                                    const TextStyle(color: Color(0xFF1A1A1A)),
                                filled: true,
                                fillColor:
                                    const Color.fromRGBO(221, 221, 221, 0.2),
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
                                labelText: 'Point B',
                                labelStyle:
                                    const TextStyle(color: Color(0xFF1A1A1A)),
                                filled: true,
                                fillColor:
                                    const Color.fromRGBO(221, 221, 221, 0.2),
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
                              'Tasks',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF000000), // Чёрный
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
                                            color: Color(
                                                0xFF1A1A1A)), // Тёмно-серый
                                      ),
                                    ),
                                    IconButton(
                                      icon: const Icon(Icons.close,
                                          color: Color(0xFF333333)), // Серый
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
                                      hintStyle: const TextStyle(
                                          color: Color(0xFF333333)), // Серый
                                      filled: true,
                                      fillColor: const Color.fromRGBO(
                                          221, 221, 221, 0.2),
                                      border: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(10),
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
                                      color: Color(0xFFAFCBEA)), // Голубой
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
                                backgroundColor:
                                    const Color(0xFFAFCBEA), // Голубой
                                foregroundColor:
                                    const Color(0xFF000000), // Чёрный
                                padding: EdgeInsets.symmetric(
                                    vertical: size.height * 0.02),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(10),
                                ),
                              ),
                              child: const Text('Create'),
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
