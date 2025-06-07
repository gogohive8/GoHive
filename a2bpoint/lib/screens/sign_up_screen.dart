import 'package:flutter/material.dart';
import '../services/api_services.dart';

class SignUpScreen extends StatefulWidget {
  const SignUpScreen({super.key});

  @override
  _SignUpScreenState createState() => _SignUpScreenState();
}

class _SignUpScreenState extends State<SignUpScreen> {
  final _formKey = GlobalKey<FormState>();
  final _phoneController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  final _lastNameController = TextEditingController();
  final _firstNameController = TextEditingController();
  final _ageController = TextEditingController();
  final _usernameController = TextEditingController();
  final ApiService _apiService = ApiService();
  final bool useDummyAuth = true; // Переключатель для заглушки

  @override
  void dispose() {
    _phoneController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    _lastNameController.dispose();
    _firstNameController.dispose();
    _ageController.dispose();
    _usernameController.dispose();
    super.dispose();
  }

  Future<void> _signUp() async {
    if (_formKey.currentState!.validate()) {
      try {
        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (context) =>
              const Center(child: CircularProgressIndicator()),
        );
        if (useDummyAuth) {
          await Future.delayed(const Duration(seconds: 1)); // Имитация запроса
          _apiService.setToken('dummy_token');
          if (mounted) {
            Navigator.pop(context); // Закрываем индикатор
            Navigator.pushReplacementNamed(context, '/home');
          }
        } else {
          await _apiService.signUp(
            _usernameController.text,
            _emailController.text,
            _passwordController.text,
          );
          if (mounted) {
            Navigator.pop(context); // Закрываем индикатор
            Navigator.pushReplacementNamed(context, '/home');
          }
        }
      } catch (e) {
        if (mounted) {
          Navigator.pop(context); // Закрываем индикатор
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Ошибка регистрации: $e')),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final padding = size.width * 0.05;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Sign up with E-mail'),
        leading: IconButton(
          icon: const Icon(
            Icons.arrow_back_ios,
            color: Colors.purple,
            size: 30,
          ),
          onPressed: () => Navigator.of(context).pop(),
          splashColor: Colors.purple.withOpacity(0.2),
          highlightColor: Colors.purple.withOpacity(0.4),
        ),
        elevation: 2,
        shadowColor: Colors.grey.withOpacity(0.5),
      ),
      body: SafeArea(
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: padding),
          child: Form(
            key: _formKey,
            child: SingleChildScrollView(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  TextField(
                    controller: _firstNameController,
                    decoration: InputDecoration(
                      labelText: 'First Name',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide: BorderSide(color: Colors.purple),
                      ),
                      prefixIcon: const Icon(Icons.person),
                    ),
                    textInputAction: TextInputAction.next,
                    onSubmitted: (value) {
                      FocusScope.of(context).nextFocus();
                    },
                  ),
                  SizedBox(height: size.height * 0.02),
                  TextField(
                    controller: _lastNameController,
                    decoration: InputDecoration(
                      labelText: 'Last Name',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide: BorderSide(color: Colors.purple),
                      ),
                      prefixIcon: const Icon(Icons.person_outline),
                    ),
                    textInputAction: TextInputAction.next,
                    onSubmitted: (value) {
                      FocusScope.of(context).nextFocus();
                    },
                  ),
                  SizedBox(height: size.height * 0.02),
                  TextField(
                    controller: _ageController,
                    decoration: InputDecoration(
                      labelText: 'Age',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide: BorderSide(color: Colors.purple),
                      ),
                      prefixIcon: const Icon(Icons.calendar_today),
                    ),
                    keyboardType: TextInputType.number,
                    textInputAction: TextInputAction.next,
                    onSubmitted: (value) {
                      FocusScope.of(context).nextFocus();
                    },
                  ),
                  SizedBox(height: size.height * 0.02),
                  TextField(
                    controller: _usernameController,
                    decoration: InputDecoration(
                      labelText: 'Username',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide: BorderSide(color: Colors.purple),
                      ),
                      prefixIcon: const Icon(Icons.account_circle),
                    ),
                    textInputAction: TextInputAction.next,
                    onSubmitted: (value) {
                      FocusScope.of(context).nextFocus();
                    },
                  ),
                  SizedBox(height: size.height * 0.02),
                  TextField(
                    controller: _phoneController,
                    decoration: InputDecoration(
                      labelText: 'Phone Number',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide: BorderSide(color: Colors.purple),
                      ),
                      prefixIcon: const Icon(Icons.phone),
                    ),
                    keyboardType: TextInputType.phone,
                    textInputAction: TextInputAction.next,
                    onSubmitted: (value) {
                      FocusScope.of(context).nextFocus();
                    },
                  ),
                  SizedBox(height: size.height * 0.02),
                  TextField(
                    controller: _emailController,
                    decoration: InputDecoration(
                      labelText: 'Email',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide: BorderSide(color: Colors.purple),
                      ),
                      prefixIcon: const Icon(Icons.email),
                    ),
                    keyboardType: TextInputType.emailAddress,
                    textInputAction: TextInputAction.next,
                    onSubmitted: (value) {
                      FocusScope.of(context).nextFocus();
                    },
                  ),
                  SizedBox(height: size.height * 0.02),
                  TextField(
                    controller: _passwordController,
                    decoration: InputDecoration(
                      labelText: 'Password',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide: BorderSide(color: Colors.purple),
                      ),
                      prefixIcon: const Icon(Icons.lock),
                    ),
                    obscureText: true,
                    textInputAction: TextInputAction.next,
                    onSubmitted: (value) {
                      FocusScope.of(context).nextFocus();
                    },
                  ),
                  SizedBox(height: size.height * 0.02),
                  TextField(
                    controller: _confirmPasswordController,
                    decoration: InputDecoration(
                      labelText: 'Confirm Password',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide: BorderSide(color: Colors.purple),
                      ),
                      prefixIcon: const Icon(Icons.lock_outline),
                    ),
                    obscureText: true,
                    textInputAction: TextInputAction.done,
                    onSubmitted: (value) => _signUp(),
                  ),
                  SizedBox(height: size.height * 0.03),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: _signUp,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.purple,
                        padding:
                            EdgeInsets.symmetric(vertical: size.height * 0.02),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                      child: const Text('Sign up'),
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
