import 'package:flutter/material.dart';

class SocialSignInScreen extends StatefulWidget {
  const SocialSignInScreen({super.key});

  @override
  _SocialSignInScreenState createState() => _SocialSignInScreenState();
}

class _SocialSignInScreenState extends State<SocialSignInScreen> {
  // Заготовки для API
  final String apiUrl = 'https://api.example.com/auth/social';
  final String apiKey = 'your_social_api_key_here';

  @override
  Widget build(BuildContext context) {
    final provider = ModalRoute.of(context)!.settings.arguments as String?;
    final size = MediaQuery.of(context).size;
    final padding = size.width * 0.05;

    return Scaffold(
      appBar: AppBar(title: Text('Sign in with $provider')),
      body: SafeArea(
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: padding),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                'Вход через $provider (API будет здесь)',
                style: const TextStyle(fontSize: 18),
              ),
              SizedBox(height: size.height * 0.03),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Авторизация через $provider')),
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.purple,
                    padding: EdgeInsets.symmetric(vertical: size.height * 0.02),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  child: Text('Continue with $provider'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
