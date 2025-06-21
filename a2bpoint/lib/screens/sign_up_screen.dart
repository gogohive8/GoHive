import 'dart:developer' as developer;
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../services/api_services.dart';

class SignUpScreen extends StatefulWidget {
  const SignUpScreen({super.key});

  @override
  _SignUpScreenState createState() => _SignUpScreenState();
}

class _SignUpScreenState extends State<SignUpScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _usernameController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  final _firstNameController = TextEditingController();
  final _lastNameController = TextEditingController();
  final _ageController = TextEditingController();
  final _phoneController = TextEditingController();
  final ApiService _apiService = ApiService();
  bool _isPasswordVisible = false;
  bool _isConfirmPasswordVisible = false;
  bool _isLoading = false;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _usernameController.dispose();
    _confirmPasswordController.dispose();
    _firstNameController.dispose();
    _lastNameController.dispose();
    _ageController.dispose();
    _phoneController.dispose();
    _apiService.dispose();
    super.dispose();
  }

  Future<void> _signUp() async {
    if (_isLoading) return;

    if (_formKey.currentState!.validate()) {
      developer.log('Form validated successfully', name: 'SignUpScreen');
      setState(() => _isLoading = true);
      try {
        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (context) =>
              const Center(child: CircularProgressIndicator()),
        );

        developer.log(
            'SignUp request: username=${_usernameController.text}, email=${_emailController.text}',
            name: 'SignUpScreen');
        final authData = await _apiService.signUp(
          _usernameController.text,
          _emailController.text,
          _passwordController.text,
          _firstNameController.text,
          _lastNameController.text,
          int.parse(_ageController.text),
          _phoneController.text,
        );
        developer.log('SignUp response: $authData', name: 'SignUpScreen');
        Navigator.pop(context);

        if (authData != null &&
            authData['token']?.isNotEmpty == true &&
            authData['userId']?.isNotEmpty == true) {
          final authProvider =
              Provider.of<AuthProvider>(context, listen: false);
          await authProvider.setAuthData(
              authData['token']!, authData['userId']!, null, false);
          if (authProvider.isAuthenticated) {
            developer.log(
                'User registered and authenticated, navigating to /home',
                name: 'SignUpScreen');
            WidgetsBinding.instance.addPostFrameCallback((_) {
              if (mounted) {
                Navigator.pushReplacementNamed(context, '/home');
              }
            });
          } else {
            developer.log('Registration failed: AuthProvider not updated',
                name: 'SignUpScreen');
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                  content: Text('Failed to authenticate. Please try again.')),
            );
          }
        } else {
          developer.log('Registration failed: invalid auth data $authData',
              name: 'SignUpScreen');
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
                content: Text('Registration failed. Please try again.')),
          );
        }
      } catch (e, stackTrace) {
        developer.log('SignUp error: $e',
            name: 'SignUpScreen', stackTrace: stackTrace);
        if (mounted) {
          Navigator.pop(context);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Failed to register: ${e.toString()}')),
          );
        }
      } finally {
        if (mounted) {
          setState(() => _isLoading = false);
        }
      }
    } else {
      developer.log(
          'Form validation failed: username=${_usernameController.text}, email=${_emailController.text}',
          name: 'SignUpScreen');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please check your input fields')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final padding = size.width * 0.05;

    return Scaffold(
      backgroundColor: const Color(0xFFF9F6F2),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: EdgeInsets.all(padding),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                SizedBox(height: size.height * 0.1),
                Image.asset(
                  'assets/logo_background.png',
                  height: size.height * 0.15,
                  fit: BoxFit.contain,
                ),
                const SizedBox(height: 8),
                const Text(
                  'GoHive',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 32,
                    height: 40 / 32,
                    letterSpacing: -0.02 * 32,
                    color: Color(0xFF000000),
                  ),
                  textAlign: TextAlign.center,
                ),
                SizedBox(height: size.height * 0.02),
                const Text(
                  'Create Account',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF000000),
                  ),
                ),
                SizedBox(height: size.height * 0.02),
                TextFormField(
                  controller: _firstNameController,
                  decoration: InputDecoration(
                    labelText: 'First Name',
                    labelStyle: const TextStyle(color: Color(0xFF1A1A1A)),
                    filled: true,
                    fillColor: const Color.fromRGBO(221, 221, 221, 0.2),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: BorderSide.none,
                    ),
                    prefixIcon:
                        const Icon(Icons.person, color: Color(0xFF333333)),
                  ),
                  style: const TextStyle(color: Color(0xFF1A1A1A)),
                  validator: (value) => value?.isEmpty ?? true
                      ? 'Please enter your first name'
                      : null,
                ),
                SizedBox(height: size.height * 0.02),
                TextFormField(
                  controller: _lastNameController,
                  decoration: InputDecoration(
                    labelText: 'Last Name',
                    labelStyle: const TextStyle(color: Color(0xFF1A1A1A)),
                    filled: true,
                    fillColor: const Color.fromRGBO(221, 221, 221, 0.2),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: BorderSide.none,
                    ),
                    prefixIcon:
                        const Icon(Icons.person, color: Color(0xFF333333)),
                  ),
                  style: const TextStyle(color: Color(0xFF1A1A1A)),
                  validator: (value) => value?.isEmpty ?? true
                      ? 'Please enter your last name'
                      : null,
                ),
                SizedBox(height: size.height * 0.02),
                TextFormField(
                  controller: _usernameController,
                  decoration: InputDecoration(
                    labelText: 'Username',
                    labelStyle: const TextStyle(color: Color(0xFF1A1A1A)),
                    filled: true,
                    fillColor: const Color.fromRGBO(221, 221, 221, 0.2),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: BorderSide.none,
                    ),
                    prefixIcon:
                        const Icon(Icons.person, color: Color(0xFF333333)),
                  ),
                  style: const TextStyle(color: Color(0xFF1A1A1A)),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter your username';
                    }
                    if (value.length < 3) {
                      return 'Username must be at least 3 characters';
                    }
                    return null;
                  },
                ),
                SizedBox(height: size.height * 0.02),
                TextFormField(
                  controller: _emailController,
                  decoration: InputDecoration(
                    labelText: 'Email',
                    labelStyle: const TextStyle(color: Color(0xFF1A1A1A)),
                    filled: true,
                    fillColor: const Color.fromRGBO(221, 221, 221, 0.2),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: BorderSide.none,
                    ),
                    prefixIcon:
                        const Icon(Icons.email, color: Color(0xFF333333)),
                  ),
                  style: const TextStyle(color: Color(0xFF1A1A1A)),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter your email';
                    }
                    if (!RegExp(r'^[^\s@]+@[^\s@]+\.[^\s@]+$')
                        .hasMatch(value)) {
                      return 'Please enter a valid email';
                    }
                    return null;
                  },
                ),
                SizedBox(height: size.height * 0.02),
                TextFormField(
                  controller: _ageController,
                  decoration: InputDecoration(
                    labelText: 'Age',
                    labelStyle: const TextStyle(color: Color(0xFF1A1A1A)),
                    filled: true,
                    fillColor: const Color.fromRGBO(221, 221, 221, 0.2),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: BorderSide.none,
                    ),
                    prefixIcon:
                        const Icon(Icons.cake, color: Color(0xFF333333)),
                  ),
                  style: const TextStyle(color: Color(0xFF1A1A1A)),
                  keyboardType: TextInputType.number,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter your age';
                    }
                    if (int.tryParse(value) == null || int.parse(value) < 1) {
                      return 'Please enter a valid age';
                    }
                    return null;
                  },
                ),
                SizedBox(height: size.height * 0.02),
                TextFormField(
                  controller: _phoneController,
                  decoration: InputDecoration(
                    labelText: 'Phone Number',
                    labelStyle: const TextStyle(color: Color(0xFF1A1A1A)),
                    filled: true,
                    fillColor: const Color.fromRGBO(221, 221, 221, 0.2),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: BorderSide.none,
                    ),
                    prefixIcon:
                        const Icon(Icons.phone, color: Color(0xFF333333)),
                  ),
                  style: const TextStyle(color: Color(0xFF1A1A1A)),
                  keyboardType: TextInputType.phone,
                  validator: (value) => value?.isEmpty ?? true
                      ? 'Please enter your phone number'
                      : null,
                ),
                SizedBox(height: size.height * 0.02),
                TextFormField(
                  controller: _passwordController,
                  decoration: InputDecoration(
                    labelText: 'Password',
                    labelStyle: const TextStyle(color: Color(0xFF1A1A1A)),
                    filled: true,
                    fillColor: const Color.fromRGBO(221, 221, 221, 0.2),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: BorderSide.none,
                    ),
                    prefixIcon:
                        const Icon(Icons.lock, color: Color(0xFF333333)),
                    suffixIcon: IconButton(
                      icon: Icon(
                        _isPasswordVisible
                            ? Icons.visibility
                            : Icons.visibility_off,
                        color: const Color(0xFF333333),
                      ),
                      onPressed: () => setState(
                          () => _isPasswordVisible = !_isPasswordVisible),
                    ),
                  ),
                  style: const TextStyle(color: Color(0xFF1A1A1A)),
                  obscureText: !_isPasswordVisible,
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
                SizedBox(height: size.height * 0.02),
                TextFormField(
                  controller: _confirmPasswordController,
                  decoration: InputDecoration(
                    labelText: 'Confirm Password',
                    labelStyle: const TextStyle(color: Color(0xFF1A1A1A)),
                    filled: true,
                    fillColor: const Color.fromRGBO(221, 221, 221, 0.2),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: BorderSide.none,
                    ),
                    prefixIcon:
                        const Icon(Icons.lock, color: Color(0xFF333333)),
                    suffixIcon: IconButton(
                      icon: Icon(
                        _isConfirmPasswordVisible
                            ? Icons.visibility
                            : Icons.visibility_off,
                        color: const Color(0xFF333333),
                      ),
                      onPressed: () => setState(() =>
                          _isConfirmPasswordVisible =
                              !_isConfirmPasswordVisible),
                    ),
                  ),
                  style: const TextStyle(color: Color(0xFF1A1A1A)),
                  obscureText: !_isConfirmPasswordVisible,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please confirm your password';
                    }
                    if (value != _passwordController.text) {
                      return 'Passwords do not match';
                    }
                    return null;
                  },
                ),
                SizedBox(height: size.height * 0.02),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _isLoading ? null : _signUp,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFAFCBEA),
                      foregroundColor: const Color(0xFF000000),
                      padding:
                          EdgeInsets.symmetric(vertical: size.height * 0.02),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                      disabledBackgroundColor:
                          const Color(0xFFAFCBEA).withValues(alpha: 0.5),
                    ),
                    child: const Text('Sign Up'),
                  ),
                ),
                SizedBox(height: size.height * 0.02),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Text(
                      'Already have an account?',
                      style: TextStyle(color: Color(0xFF333333)),
                    ),
                    TextButton(
                      onPressed: _isLoading
                          ? null
                          : () {
                              developer.log('Navigating to SignInScreen',
                                  name: 'SignUpScreen');
                              Navigator.pushNamed(context, '/sign-in');
                            },
                      child: const Text(
                        'Sign In',
                        style: TextStyle(color: Color(0xFFAFCBEA)),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
