import 'package:flutter/material.dart';

class SignInScreen extends StatefulWidget {
  const SignInScreen({super.key});

  @override
  _SignInScreenState createState() => _SignInScreenState();
}

class _SignInScreenState extends State<SignInScreen> {
  final _phoneController = TextEditingController();

  // Заготовки для API (будут заполнены позже)
  final String apiUrl = 'https://api.example.com/auth';
  final String apiKey = 'your_api_key_here';

  @override
  void dispose() {
    _phoneController.dispose();
    super.dispose();
  }

  void _signInWithPhone() {
    if (_phoneController.text.isNotEmpty) {
      Navigator.pushNamed(context, '/sign-up');
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Введите номер телефона')),
      );
    }
  }

  void _navigateToSocialSignIn(String provider) {
    Navigator.pushNamed(context, '/social-sign-in', arguments: provider);
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final padding = size.width * 0.05;

    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: EdgeInsets.symmetric(horizontal: padding),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Stack(
                  alignment: Alignment.center,
                  children: [
                    Image.asset(
                      'assets/logo_background.png',
                      height: size.height * 0.3,
                      fit: BoxFit.contain,
                    ),
                  ],
                ),
                SizedBox(height: size.height * 0.05),
                TextField(
                  controller: _phoneController,
                  decoration: InputDecoration(
                    labelText: 'Your phone number',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: BorderSide(color: Colors.purple),
                    ),
                  ),
                  keyboardType: TextInputType.phone,
                ),
                SizedBox(height: size.height * 0.03),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _signInWithPhone,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.purple,
                      padding:
                          EdgeInsets.symmetric(vertical: size.height * 0.02),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    child: Text(
                      'Sign in',
                      style: TextStyle(
                        fontSize: size.width * 0.045,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
                SizedBox(height: size.height * 0.03),
                const Text(
                  'Or',
                  style: TextStyle(fontSize: 16),
                ),
                SizedBox(height: size.height * 0.03),
                Column(
                  children: [
                    SizedBox(
                      width: double.infinity,
                      child: OutlinedButton.icon(
                        onPressed: () => _navigateToSocialSignIn('email'),
                        icon: Image.asset(
                          'assets/email_icon.png',
                          height: 24,
                        ),
                        label: const Text('Sign in with E-mail'),
                        style: OutlinedButton.styleFrom(
                          side: const BorderSide(color: Colors.grey),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                          minimumSize: Size(double.infinity, 50),
                        ),
                      ),
                    ),
                    SizedBox(height: size.height * 0.01),
                    SizedBox(
                      width: double.infinity,
                      child: OutlinedButton.icon(
                        onPressed: () => _navigateToSocialSignIn('facebook'),
                        icon: Image.asset(
                          'assets/facebook_icon.png',
                          height: 24,
                        ),
                        label: const Text('Sign in with Facebook'),
                        style: OutlinedButton.styleFrom(
                          side: const BorderSide(color: Colors.grey),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                          minimumSize: Size(double.infinity, 50),
                        ),
                      ),
                    ),
                    SizedBox(height: size.height * 0.01),
                    SizedBox(
                      width: double.infinity,
                      child: OutlinedButton.icon(
                        onPressed: () => _navigateToSocialSignIn('google'),
                        icon: Image.asset(
                          'assets/google_icon.png',
                          height: 24,
                        ),
                        label: const Text('Sign in with Google'),
                        style: OutlinedButton.styleFrom(
                          side: const BorderSide(color: Colors.grey),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                          minimumSize: Size(double.infinity, 50),
                        ),
                      ),
                    ),
                    SizedBox(height: size.height * 0.01),
                    SizedBox(
                      width: double.infinity,
                      child: OutlinedButton.icon(
                        onPressed: () => _navigateToSocialSignIn('apple'),
                        icon: Image.asset(
                          'assets/apple_icon.png',
                          height: 24,
                        ),
                        label: const Text('Sign in with Apple'),
                        style: OutlinedButton.styleFrom(
                          side: const BorderSide(color: Colors.grey),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                          minimumSize: Size(double.infinity, 50),
                        ),
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
