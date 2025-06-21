import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../services/api_services.dart';
import 'dart:developer' as developer;

class SignUpScreen extends StatefulWidget {
  const SignUpScreen({super.key});

  @override
  _SignUpScreenState createState() => _SignUpScreenState();
}

class _SignUpScreenState extends State<SignUpScreen> {
  final _formKey = GlobalKey<FormState>();
  final _usernameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _firstNameController = TextEditingController();
  final _lastNameController = TextEditingController();
  final _ageController = TextEditingController();
  final _phoneController = TextEditingController();
  final ApiService _apiService = ApiService();
  bool _isLoading = false;

  @override
  void dispose() {
    _usernameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _firstNameController.dispose();
    _lastNameController.dispose();
    _ageController.dispose();
    _phoneController.dispose();
    _apiService.dispose();
    super.dispose();
  }

  Future<void> _signUp() async {
    if (_formKey.currentState!.validate()) {
      setState(() => _isLoading = true);
      try {
        developer.log('Attempting sign up with email: ${_emailController.text}',
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
        if (authData != null &&
            authData['token'].isNotEmpty &&
            authData['userId'].isNotEmpty) {
          final authProvider =
              Provider.of<AuthProvider>(context, listen: false);
          await authProvider.setAuthData(authData['token'], authData['userId'],
              authData['username'], true);
          if (authProvider.isAuthenticated) {
            developer.log('User signed up, navigating to /welcome',
                name: 'SignUpScreen');
            Navigator.pushReplacementNamed(context, '/welcome');
          } else {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Failed to authenticate')),
            );
          }
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Sign up failed')),
          );
        }
      } catch (e, stackTrace) {
        developer.log('SignUp error: $e',
            name: 'SignUpScreen', stackTrace: stackTrace);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Sign up error: $e')),
        );
      } finally {
        setState(() => _isLoading = false);
      }
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
          padding: EdgeInsets.symmetric(horizontal: padding),
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                SizedBox(height: size.height * 0.05),
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
                    color: Color(0xFF000000),
                  ),
                  textAlign: TextAlign.center,
                ),
                SizedBox(height: size.height * 0.03),
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
                  validator: (value) =>
                      value?.isEmpty ?? true ? 'Enter username' : null,
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
                  keyboardType: TextInputType.emailAddress,
                  style: const TextStyle(color: Color(0xFF1A1A1A)),
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
                  validator: (value) =>
                      value?.isEmpty ?? true ? 'Enter first name' : null,
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
                  validator: (value) =>
                      value?.isEmpty ?? true ? 'Enter last name' : null,
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
                    if (int.tryParse(value) == null || int.parse(value) < 1) {
                      return 'Enter a valid age';
                    }
                    return null;
                  },
                ),
                SizedBox(height: size.height * 0.02),
                TextFormField(
                  controller: _phoneController,
                  decoration: InputDecoration(
                    labelText: 'Phone',
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
                  validator: (value) =>
                      value?.isEmpty ?? true ? 'Enter phone number' : null,
                ),
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
                    child: _isLoading
                        ? const CircularProgressIndicator(
                            color: Color(0xFF000000))
                        : const Text('Sign Up'),
                  ),
                ),
                SizedBox(height: size.height * 0.02),
                TextButton(
                  onPressed: () => Navigator.pushNamed(context, '/sign_in'),
                  child: const Text(
                    'Already have an account? Sign In',
                    style: TextStyle(color: Color(0xFFAFCBEA)),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
