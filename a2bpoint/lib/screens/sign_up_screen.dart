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
  final _nameController = TextEditingController();
  final _surnameController = TextEditingController();
  final _usernameController = TextEditingController();
  final _ageController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _phoneController = TextEditingController();
  final ApiService _apiService = ApiService();
  bool _isLoading = false;
  bool _isGoogleSignUp = false;
  String? _userId;
  String? _googleEmail;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final args =
        ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;
    if (args != null && args['isGoogleSignUp'] == true) {
      _isGoogleSignUp = true;
      _userId = args['userId'];
      _googleEmail = args['email'];
      _emailController.text = _googleEmail ?? '';
    }
  }

  Future<void> _signUp() async {
    if (!mounted || _isLoading || !_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);
    developer.log('Attempting sign-up, isGoogleSignUp: $_isGoogleSignUp',
        name: 'SignUpScreen');

    try {
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const Center(child: CircularProgressIndicator()),
      );

      final authProvider = Provider.of<AuthProvider>(context, listen: false);

      if (_isGoogleSignUp && _userId != null) {
        // Update profile for Google user
        await _apiService.updateProfile(
          _userId!,
          authProvider.token!,
          {
            'name': _nameController.text.trim(),
            'surname': _surnameController.text.trim(),
            'username': _usernameController.text.trim(),
            'age': int.parse(_ageController.text.trim()),
            'phone': _phoneController.text.trim(),
          },
        );
        developer.log('Google profile updated for userId: $_userId',
            name: 'SignUpScreen');
        if (mounted) Navigator.pop(context);
        if (mounted) Navigator.pushReplacementNamed(context, '/home');
      } else {
        // Regular email sign-up
        final authData = await _apiService.signUp(
          _usernameController.text.trim(),
          _emailController.text.trim(),
          _passwordController.text.trim(),
          _nameController.text.trim(),
          _surnameController.text.trim(),
          int.parse(_ageController.text.trim()),
          _phoneController.text.trim(),
        );
        developer.log('Email sign-up response: $authData',
            name: 'SignUpScreen');
        if (mounted) Navigator.pop(context);
        if (authData != null &&
            authData['token']?.isNotEmpty == true &&
            authData['userId']?.isNotEmpty == true) {
          await authProvider.setAuthData(
              authData['token']!, authData['userId']!);
          if (mounted) Navigator.pushReplacementNamed(context, '/home');
        } else {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Sign-up failed')),
            );
          }
        }
      }
    } catch (e, stackTrace) {
      developer.log('Sign-up error: $e',
          name: 'SignUpScreen', stackTrace: stackTrace);
      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Sign-up error: ${e.toString()}')),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _surnameController.dispose();
    _usernameController.dispose();
    _ageController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _phoneController.dispose();
    _apiService.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final padding = size.width * 0.05;

    return Scaffold(
      backgroundColor: const Color(0xFFF9F6F2),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: EdgeInsets.symmetric(horizontal: padding),
            child: Form(
              key: _formKey,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Image.asset(
                    'assets/logo_background.png',
                    height: size.height * 0.15,
                    fit: BoxFit.contain,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    _isGoogleSignUp ? 'Complete Your Profile' : 'Sign Up',
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 32,
                      height: 40 / 32,
                      letterSpacing: -0.02 * 32,
                      color: Color(0xFF000000),
                    ),
                    textAlign: TextAlign.center,
                  ),
                  SizedBox(height: size.height * 0.05),
                  TextFormField(
                    controller: _nameController,
                    decoration: InputDecoration(
                      labelText: 'Name',
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
                        return 'Please enter your name';
                      }
                      return null;
                    },
                  ),
                  SizedBox(height: size.height * 0.02),
                  TextFormField(
                    controller: _surnameController,
                    decoration: InputDecoration(
                      labelText: 'Surname',
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
                        return 'Please enter your surname';
                      }
                      return null;
                    },
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
                      prefixIcon: const Icon(Icons.person_outline,
                          color: Color(0xFF333333)),
                    ),
                    style: const TextStyle(color: Color(0xFF1A1A1A)),
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
                    keyboardType: TextInputType.number,
                    style: const TextStyle(color: Color(0xFF1A1A1A)),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Please enter your age';
                      }
                      final age = int.tryParse(value);
                      if (age == null || age < 13) {
                        return 'Age must be at least 13';
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
                    keyboardType: TextInputType.phone,
                    style: const TextStyle(color: Color(0xFF1A1A1A)),
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
                  if (!_isGoogleSignUp) ...[
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
                      keyboardType: TextInputType.emailAddress,
                      style: const TextStyle(color: Color(0xFF1A1A1A)),
                      enabled: !_isGoogleSignUp,
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please enter your email';
                        }
                        if (!RegExp(r'^[^\s@]+@[^\s@]+\.[^\s@]+$')
                            .hasMatch(value)) {
                          return 'Invalid email format';
                        }
                        return null;
                      },
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
                      ),
                      obscureText: true,
                      style: const TextStyle(color: Color(0xFF1A1A1A)),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please enter your password';
                        }
                        if (value.length < 6) {
                          return 'Password must be at least 6 characters';
                        }
                        return null;
                      },
                      textInputAction: TextInputAction.done,
                      onFieldSubmitted: (_) => _signUp(),
                    ),
                  ],
                  SizedBox(height: size.height * 0.03),
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
                      ),
                      child: Text(
                        _isGoogleSignUp ? 'Complete Profile' : 'Sign Up',
                        style: TextStyle(fontSize: size.width * 0.045),
                      ),
                    ),
                  ),
                  if (!_isGoogleSignUp) ...[
                    SizedBox(height: size.height * 0.03),
                    SizedBox(
                      width: double.infinity,
                      child: OutlinedButton(
                        onPressed: _isLoading
                            ? null
                            : () => Navigator.pushNamed(context, '/sign_in'),
                        style: OutlinedButton.styleFrom(
                          side: const BorderSide(color: Color(0xFF333333)),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                          backgroundColor:
                              const Color.fromRGBO(221, 221, 221, 0.1),
                        ),
                        child: const Text(
                          'Sign In',
                          style: TextStyle(color: Color(0xFF1A1A1A)),
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
