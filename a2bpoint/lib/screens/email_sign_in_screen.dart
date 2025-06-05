import 'package:flutter/material.dart';

class EmailSignInScreen extends StatefulWidget {
  const EmailSignInScreen({super.key});

  @override
  _EmailSignInScreenState createState() => _EmailSignInScreenState();
}

class _EmailSignInScreenState extends State<EmailSignInScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  // Заготовки для API
  final String apiUrl = 'https://api.example.com/auth/email';
  final String apiKey = 'your_email_api_key_here';

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void _signInWithEmail() {
    if (_emailController.text.isNotEmpty &&
        _passwordController.text.isNotEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Вход через email (API будет здесь)')),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Введите email и пароль')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final padding = size.width * 0.05;

    return Scaffold(
      appBar: AppBar(title: const Text('Sign in with E-mail')),
      body: SafeArea(
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: padding),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
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
              ),
              SizedBox(height: size.height * 0.03),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _signInWithEmail,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.purple,
                    padding: EdgeInsets.symmetric(vertical: size.height * 0.02),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  child: const Text('Sign in'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
