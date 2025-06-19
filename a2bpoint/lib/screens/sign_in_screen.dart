import 'dart:developer' as developer;
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../services/api_services.dart';

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
        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (context) =>
              const Center(child: CircularProgressIndicator()),
        );
        final authData = await _apiService.login(
            _emailController.text, _passwordController.text);
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
            SnackBar(content: Text('Login error: $e')),
          );
        }
      }
    }
  }

  Future<void> _signInWithGoogle() async {
    developer.log('SignIn with Google', name: 'SignInScreen');
    try {
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const Center(child: CircularProgressIndicator()),
      );
      final authData = await _apiService.signInWithGoogle();
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
          SnackBar(content: Text('Google sign-in error: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final padding = size.width * 0.05;

    return Scaffold(
      backgroundColor: const Color(0xFFF5E9D6), // Бежевый фон
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
                    height: size.height * 0.15, // Уменьшенный размер логотипа
                    fit: BoxFit.contain,
                  ),
                  const SizedBox(
                      height: 8), // Отступ между логотипом и надписью
                  const Text(
                    'GoHive',
                    style: TextStyle(
                      fontWeight: FontWeight.bold, // Эквивалент 700
                      fontSize: 32,
                      height:
                          40 / 32, // Высота строки: 40px / размер шрифта: 32px
                      letterSpacing: -0.02 * 32, // Отступ между буквами: -2%
                      color: Color(0xFF2A2A2A), // Темно-серый текст
                    ),
                    textAlign: TextAlign.center,
                  ),
                  SizedBox(height: size.height * 0.05),
                  TextFormField(
                    controller: _emailController,
                    decoration: InputDecoration(
                      labelText: 'Email',
                      labelStyle: const TextStyle(
                          color: Color(0xFF2A2A2A)), // Темно-серый
                      filled: true,
                      fillColor: Colors.white
                          .withOpacity(0.2), // Легкий белый для контраста
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide: BorderSide.none,
                      ),
                      prefixIcon: const Icon(Icons.email,
                          color: Color(0xFF2A2A2A)), // Темно-серый
                    ),
                    keyboardType: TextInputType.emailAddress,
                    style: const TextStyle(
                        color: Color(0xFF2A2A2A)), // Темно-серый
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
                      labelStyle: const TextStyle(
                          color: Color(0xFF2A2A2A)), // Темно-серый
                      filled: true,
                      fillColor: Colors.white.withOpacity(0.2), // Легкий белый
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide: BorderSide.none,
                      ),
                      prefixIcon: const Icon(Icons.lock,
                          color: Color(0xFF2A2A2A)), // Темно-серый
                    ),
                    obscureText: true,
                    style: const TextStyle(
                        color: Color(0xFF2A2A2A)), // Темно-серый
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
                    onFieldSubmitted: (_) => _signInWithEmail(),
                  ),
                  SizedBox(height: size.height * 0.03),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: _signInWithEmail,
                      style: ElevatedButton.styleFrom(
                        backgroundColor:
                            const Color(0xFF8A9ED9), // Голубовато-сиреневый
                        foregroundColor: Colors.white, // Белый текст
                        padding:
                            EdgeInsets.symmetric(vertical: size.height * 0.02),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                      child: Text(
                        'Sign In',
                        style: TextStyle(fontSize: size.width * 0.045),
                      ),
                    ),
                  ),
                  SizedBox(height: size.height * 0.03),
                  const Text('Or',
                      style:
                          TextStyle(color: Color(0xFF2A2A2A))), // Темно-серый
                  SizedBox(height: size.height * 0.03),
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton(
                      onPressed: () => Navigator.pushNamed(context, '/sign-up'),
                      style: OutlinedButton.styleFrom(
                        side: const BorderSide(
                            color: Color(0xFF2A2A2A)), // Темно-серый
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                        backgroundColor:
                            Colors.white.withOpacity(0.1), // Легкий фон
                      ),
                      child: const Text(
                        'Sign Up',
                        style:
                            TextStyle(color: Color(0xFF2A2A2A)), // Темно-серый
                      ),
                    ),
                  ),
                  SizedBox(height: size.height * 0.01),
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton.icon(
                      onPressed: _signInWithGoogle,
                      icon: Image.asset('assets/google_icon.png', height: 24),
                      label: const Text(
                        'Sign in with Google',
                        style:
                            TextStyle(color: Color(0xFF2A2A2A)), // Темно-серый
                      ),
                      style: OutlinedButton.styleFrom(
                        side: const BorderSide(
                            color: Color(0xFF2A2A2A)), // Темно-серый
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                        backgroundColor:
                            Colors.white.withOpacity(0.1), // Легкий фон
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
