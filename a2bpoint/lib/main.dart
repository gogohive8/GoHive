import 'package:flutter/material.dart';
import 'screens/sign_in_screen.dart';
import 'screens/email_sign_in_screen.dart';
import 'screens/social_sign_in_screen.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'A2B Sign In',
      theme: ThemeData(
        primarySwatch: Colors.purple,
        visualDensity: VisualDensity.adaptivePlatformDensity,
        useMaterial3: true,
      ),
      initialRoute: '/sign-in',
      routes: {
        '/sign-in': (context) => const SignInScreen(),
        '/email-sign-in': (context) => const EmailSignInScreen(),
        '/social-sign-in': (context) => const SocialSignInScreen(),
      },
    );
  }
}
