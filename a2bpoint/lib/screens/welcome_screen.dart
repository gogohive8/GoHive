import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import 'dart:developer' as developer;

class WelcomeScreen extends StatelessWidget {
  const WelcomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final authProvider = Provider.of<AuthProvider>(context, listen: false);

    return Scaffold(
      backgroundColor: const Color(0xFFF9F6F2),
      body: SafeArea(
        child: Padding(
          padding: EdgeInsets.all(size.width * 0.05),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Image.asset(
                'assets/logo_background.png',
                height: size.height * 0.15,
                fit: BoxFit.contain,
              ),
              const SizedBox(height: 16),
              const Text(
                'Welcome to Gohive!',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF1A1A1A),
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              const Text(
                'Это не просто приложение. Это твоя личная история достижений.\n'
                'Делись целями, двигайся шаг за шагом и будь частью комьюнити, '
                'которое реально тебя понимает.\n'
                'Gohive — вместе дойдём.',
                style: TextStyle(
                  fontSize: 16,
                  color: Color(0xFF333333),
                  height: 1.5,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 32),
              ElevatedButton(
                onPressed: () async {
                  developer.log('Welcome screen: Next pressed',
                      name: 'WelcomeScreen');
                  await authProvider.markWelcomeShown();
                  Navigator.pushReplacementNamed(context, '/home');
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFAFCBEA),
                  foregroundColor: const Color(0xFF000000),
                  padding: EdgeInsets.symmetric(
                    horizontal: size.width * 0.1,
                    vertical: size.height * 0.02,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                child: const Text('Далее'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
