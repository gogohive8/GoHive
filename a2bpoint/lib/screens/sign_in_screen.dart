import 'dart:developer' as developer;
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../services/api_services.dart';
import 'sign_up_screen.dart';

class SignInScreen extends StatefulWidget {
  const SignInScreen({super.key});

  @override
  _SignInScreenState createState() => _SignInScreenState();
}

class _SignInScreenState extends State<SignInScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final ApiService _apiService = ApiService();
  bool _isPasswordVisible = false;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _apiService.dispose();
    super.dispose();
  }

  Future<void> _signInWithEmail() async {
    if (_formKey.currentState!.validate()) {
      developer.log('SignIn with email: email=${_emailController.text}',
          name: 'SignInScreen');
      try {
        developer.log('Sending login request: email=${_emailController.text}',
            name: 'SignInScreen');
        final authData = await _apiService.login(
            _emailController.text, _passwordController.text);
        developer.log('Login response: $authData', name: 'SignInScreen');
        if (!mounted) return;
        Navigator.pop(context);
        if (authData != null) {
          Provider.of<AuthProvider>(context, listen: false)
              .setAuthData(authData['token'] ?? '', authData['userId'] ?? '');
          Navigator.pushReplacementNamed(context, '/home');
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Invalid email or password')),
          );
        }
      } catch (e, stackTrace) {
        developer.log('SignIn error: $e',
            name: 'SignInScreen', stackTrace: stackTrace);
        if (mounted) {
          Navigator.pop(context);
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
                content: Text('Failed to sign in. Please try again.')),
          );
        }
      }
    } else {
      developer.log(
          'Form validation failed: email=${_emailController.text}, password=${_passwordController.text}',
          name: 'SignInScreen');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please check your email and password')),
      );
    }
  }

  Future<void> _signInWithGoogle() async {
    developer.log('SignIn with Google', name: 'SignInScreen');
    try {
      developer.log('Starting Google sign-in', name: 'SignInScreen');
      final authData = await _apiService.signInWithGoogle();
      developer.log('Google sign-in response: $authData', name: 'SignInScreen');
      if (!mounted) return;
      Navigator.pop(context);
      if (authData != null) {
        Provider.of<AuthProvider>(context, listen: false)
            .setAuthData(authData['token'] ?? '', authData['userId'] ?? '');
        Navigator.pushReplacementNamed(context, '/home');
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Google sign-in failed')),
        );
      }
    } catch (e, stackTrace) {
      developer.log('Google sign-in error: $e',
          name: 'SignInScreen', stackTrace: stackTrace);
      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content:
                  Text('Failed to sign in with Google. Please try again.')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    return Scaffold(
      body: SingleChildScrollView(
        child: Padding(
          padding: EdgeInsets.all(size.width * 0.05),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                SizedBox(height: size.height * 0.1),
                Image.asset('assets/images/logo.png',
                    height: size.height * 0.15),
                SizedBox(height: size.height * 0.02),
                const Text(
                  'Welcome Back!',
                  style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                ),
                SizedBox(height: size.height * 0.02),
                TextFormField(
                  controller: _emailController,
                  decoration: InputDecoration(
                    labelText: 'Email',
                    border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10)),
                    prefixIcon: const Icon(Icons.email),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter your email';
                    }
                    // Менее строгий RegExp для email
                    if (!RegExp(r'^[^\s@]+@[^\s@]+\.[^\s@]+$')
                        .hasMatch(value)) {
                      return 'Please enter a valid email';
                    }
                    return null;
                  },
                ),
                SizedBox(height: size.height * 0.02),
                TextFormField(
                  controller: _passwordController,
                  decoration: InputDecoration(
                    labelText: 'Password',
                    border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10)),
                    prefixIcon: const Icon(Icons.lock),
                    suffixIcon: IconButton(
                      icon: Icon(_isPasswordVisible
                          ? Icons.visibility
                          : Icons.visibility_off),
                      onPressed: () {
                        setState(() {
                          _isPasswordVisible = !_isPasswordVisible;
                        });
                      },
                    ),
                    keyboardType: TextInputType.emailAddress,
                    style: const TextStyle(color: Colors.white),
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
                    child: const Text('Forgot Password?',
                        style: TextStyle(color: Colors.purple)),
                  ),
                ),
                SizedBox(height: size.height * 0.02),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _signInWithEmail,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.purple,
                      padding:
                          EdgeInsets.symmetric(vertical: size.height * 0.02),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    child: const Text('Sign In',
                        style: TextStyle(color: Colors.white)),
                  ),
                ),
                SizedBox(height: size.height * 0.02),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: _signInWithGoogle,
                    icon: Image.asset('assets/images/google_icon.png',
                        height: 24),
                    label: const Text('Sign in with Google'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.white,
                      foregroundColor: Colors.black,
                      padding:
                          EdgeInsets.symmetric(vertical: size.height * 0.02),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                        side: const BorderSide(color: Colors.grey),
                      ),
                    ),
                  ),
                ),
                SizedBox(height: size.height * 0.02),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Text("Don't have an account?"),
                    TextButton(
                      onPressed: () {
                        developer.log('Navigating to SignUpScreen',
                            name: 'SignInScreen');
                        Navigator.pushNamed(context, '/sign-up');
                      },
                      child: const Text('Sign Up',
                          style: TextStyle(color: Colors.purple)),
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
