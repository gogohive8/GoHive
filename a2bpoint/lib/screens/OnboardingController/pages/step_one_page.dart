import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../onboarding_controller.dart';

class StepOnePage extends StatefulWidget {
  final OnboardingData data;
  final bool isGoogleSignUp;
  final VoidCallback onNext;

  const StepOnePage({
    super.key,
    required this.data,
    required this.isGoogleSignUp,
    required this.onNext,
  });

  @override
  State<StepOnePage> createState() => _StepOnePageState();
}

class _StepOnePageState extends State<StepOnePage> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _surnameController = TextEditingController();
  final _usernameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _phoneController = TextEditingController();

  String _selectedGender = '';
  DateTime? _selectedDate;

  @override
  void initState() {
    super.initState();
    _initializeControllers();
  }

  void _initializeControllers() {
    _nameController.text = widget.data.name;
    _surnameController.text = widget.data.surname;
    _usernameController.text = widget.data.username;
    _emailController.text = widget.data.email;
    _passwordController.text = widget.data.password;
    _phoneController.text = widget.data.phone;
    _selectedGender = widget.data.gender;
    _selectedDate = widget.data.birthDate;
  }

  void _updateData() {
    widget.data.name = _nameController.text.trim();
    widget.data.surname = _surnameController.text.trim();
    widget.data.username = _usernameController.text.trim();
    widget.data.email = _emailController.text.trim();
    widget.data.password = _passwordController.text.trim();
    widget.data.phone = _phoneController.text.trim();
    widget.data.gender = _selectedGender;
    widget.data.birthDate = _selectedDate;
    
    if (_selectedDate != null) {
      final now = DateTime.now();
      widget.data.age = now.year - _selectedDate!.year;
      if (now.month < _selectedDate!.month || 
          (now.month == _selectedDate!.month && now.day < _selectedDate!.day)) {
        widget.data.age--;
      }
    }
  }

  void _selectDate() async {
    final now = DateTime.now();
    final firstDate = DateTime(now.year - 99, now.month, now.day);
    final lastDate = DateTime(now.year - 5, now.month, now.day);

    final date = await showDatePicker(
      context: context,
      initialDate: _selectedDate ?? lastDate,
      firstDate: firstDate,
      lastDate: lastDate,
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: Color(0xFF0056F7),
              onPrimary: Colors.white,
              onSurface: Colors.black,
            ),
          ),
          child: child!,
        );
      },
    );

    if (date != null) {
      setState(() => _selectedDate = date);
    }
  }

  void _continue() {
    if (_formKey.currentState!.validate() && _selectedDate != null && _selectedGender.isNotEmpty) {
      _updateData();
      widget.onNext();
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please fill all fields correctly'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  double _getResponsiveWidth(BuildContext context) {
    return MediaQuery.of(context).size.width;
  }

  double _getResponsiveHeight(BuildContext context) {
    return MediaQuery.of(context).size.height;
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = _getResponsiveWidth(context);
    final screenHeight = _getResponsiveHeight(context);
    final padding = screenWidth * 0.08;

    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFFF4F3EE),
        borderRadius: BorderRadius.circular(32),
      ),
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: padding),
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SizedBox(height: screenHeight * 0.02),
                
                // Title
                Text(
                  'Enter your details',
                  style: TextStyle(
                    fontSize: screenWidth * 0.08,
                    fontWeight: FontWeight.bold,
                    color: Colors.black,
                  ),
                ),
                
                SizedBox(height: screenHeight * 0.04),

                // Name
                _buildTextField(
                  controller: _nameController,
                  label: 'Name',
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter your name';
                    }
                    return null;
                  },
                ),
                
                SizedBox(height: screenHeight * 0.02),

                // Surname
                _buildTextField(
                  controller: _surnameController,
                  label: 'Surname',
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter your surname';
                    }
                    return null;
                  },
                ),
                
                SizedBox(height: screenHeight * 0.02),

                // Username
                _buildTextField(
                  controller: _usernameController,
                  label: 'Username',
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter your username';
                    }
                    if (value.contains(' ')) {
                      return 'Username cannot contain spaces';
                    }
                    return null;
                  },
                ),
                
                SizedBox(height: screenHeight * 0.02),

                // Date of birth
                GestureDetector(
                  onTap: _selectDate,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.8),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.grey.withOpacity(0.3)),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          _selectedDate != null 
                            ? DateFormat('dd/MM/yyyy').format(_selectedDate!)
                            : 'Date of birth',
                          style: TextStyle(
                            fontSize: 16,
                            color: _selectedDate != null ? Colors.black : Colors.grey[600],
                          ),
                        ),
                        const Icon(Icons.calendar_today, color: Colors.grey),
                      ],
                    ),
                  ),
                ),
                
                SizedBox(height: screenHeight * 0.02),

                // Country & City Row
                Row(
                  children: [
                    Expanded(
                      child: _buildTextField(
                        controller: TextEditingController(text: 'Kazakhstan'), // Default
                        label: 'Country',
                        enabled: false,
                      ),
                    ),
                    SizedBox(width: screenWidth * 0.04),
                    Expanded(
                      child: _buildTextField(
                        controller: TextEditingController(text: 'Almaty'), // Default  
                        label: 'City',
                        enabled: false,
                      ),
                    ),
                  ],
                ),
                
                SizedBox(height: screenHeight * 0.02),

                // Gender Selection
                Text('Sex', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500)),
                SizedBox(height: screenHeight * 0.01),
                Row(
                  children: [
                    _buildGenderButton('Man'),
                    SizedBox(width: screenWidth * 0.04),
                    _buildGenderButton('Woman'),
                  ],
                ),
                
                SizedBox(height: screenHeight * 0.02),

                // Email (disabled for Google signup)
                _buildTextField(
                  controller: _emailController,
                  label: 'E-mail',
                  keyboardType: TextInputType.emailAddress,
                  enabled: !widget.isGoogleSignUp,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter your email';
                    }
                    if (!RegExp(r'^[^\s@]+@[^\s@]+\.[^\s@]+$').hasMatch(value)) {
                      return 'Invalid email format';
                    }
                    return null;
                  },
                ),
                
                SizedBox(height: screenHeight * 0.02),

                // Password (only for email signup)
                if (!widget.isGoogleSignUp) ...[
                  _buildTextField(
                    controller: _passwordController,
                    label: 'Password',
                    obscureText: true,
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Please enter your password';
                      }
                      if (value.length < 6) {
                        return 'Password must be at least 6 characters';
                      }
                      return null;
                    },
                  ),
                  SizedBox(height: screenHeight * 0.02),
                ],

                // Phone Number
                _buildTextField(
                  controller: _phoneController,
                  label: 'Phone number',
                  keyboardType: TextInputType.phone,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter your phone number';
                    }
                    if (value.length < 10) {
                      return 'Phone number must be at least 10 digits';
                    }
                    return null;
                  },
                ),
                
                SizedBox(height: screenHeight * 0.04),

                // Continue Button
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _continue,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF0056F7),
                      foregroundColor: Colors.white,
                      padding: EdgeInsets.symmetric(vertical: screenHeight * 0.02),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      elevation: 0,
                    ),
                    child: Text(
                      'Continue',
                      style: TextStyle(
                        fontSize: screenWidth * 0.045,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
                
                SizedBox(height: screenHeight * 0.02),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    String? Function(String?)? validator,
    TextInputType? keyboardType,
    bool obscureText = false,
    bool enabled = true,
  }) {
    return TextFormField(
      controller: controller,
      validator: validator,
      keyboardType: keyboardType,
      obscureText: obscureText,
      enabled: enabled,
      style: TextStyle(
        color: enabled ? Colors.black : Colors.grey[600],
      ),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: TextStyle(color: Colors.grey[600]),
        filled: true,
        fillColor: enabled ? Colors.white.withOpacity(0.8) : Colors.grey.withOpacity(0.3),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.grey.withOpacity(0.3)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFF0056F7)),
        ),
      ),
    );
  }

  Widget _buildGenderButton(String gender) {
    final isSelected = _selectedGender == gender;
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => _selectedGender = gender),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: isSelected ? const Color(0xFF0056F7) : Colors.white.withOpacity(0.8),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: isSelected ? const Color(0xFF0056F7) : Colors.grey.withOpacity(0.3),
            ),
          ),
          child: Text(
            gender,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: isSelected ? Colors.white : Colors.black,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _nameController.dispose();
    _surnameController.dispose();
    _usernameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _phoneController.dispose();
    super.dispose();
  }
}