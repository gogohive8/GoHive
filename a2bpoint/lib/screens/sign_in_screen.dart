import 'package:flutter/material.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Sign In App',
      theme: ThemeData(
        primarySwatch: Colors.purple,
        visualDensity: VisualDensity.adaptivePlatformDensity,
      ),
      home: const SignInScreen(),
    );
  }
}

class SignInScreen extends StatelessWidget {
  const SignInScreen({super.key});

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
                // Логотип и декоративные элементы
                Stack(
                  alignment: Alignment.center,
                  children: [
                    Image.asset(
                      'assets/logo_background.png', // Замените на путь к вашему изображению
                      height: size.height * 0.3,
                      fit: BoxFit.contain,
                    ),
                    Text(
                      'A2B',
                      style: TextStyle(
                        fontSize: size.width * 0.1,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
                SizedBox(height: size.height * 0.05),

                // Поле для номера телефона
                TextField(
                  decoration: InputDecoration(
                    labelText: 'Your phone number',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: BorderSide(color: Colors.blue),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: BorderSide(color: Colors.blue),
                    ),
                  ),
                  keyboardType: TextInputType.phone,
                ),
                SizedBox(height: size.height * 0.03),

                // Кнопка Sign In
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () {
                      // Логика входа
                    },
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

                // Текст "Or"
                Text(
                  'Or',
                  style: TextStyle(fontSize: size.width * 0.04),
                ),
                SizedBox(height: size.height * 0.03),

                // Варианты входа
                Column(
                  children: [
                    OutlinedButton.icon(
                      onPressed: () {
                        // Логика входа через email
                      },
                      icon: Icon(Icons.email, color: Colors.black),
                      label: Text('Sign in with E-mail'),
                      style: OutlinedButton.styleFrom(
                        side: BorderSide(color: Colors.grey),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                    ),
                    SizedBox(height: size.height * 0.01),
                    OutlinedButton.icon(
                      onPressed: () {
                        // Логика входа через Facebook
                      },
                      icon: Image.asset(
                        'assets/facebook_icon.png', // Замените на путь к иконке
                        height: 24,
                      ),
                      label: Text('Sign in with Facebook'),
                      style: OutlinedButton.styleFrom(
                        side: BorderSide(color: Colors.grey),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                    ),
                    SizedBox(height: size.height * 0.01),
                    OutlinedButton.icon(
                      onPressed: () {
                        // Логика входа через Google
                      },
                      icon: Image.asset(
                        'assets/google_icon.png', // Замените на путь к иконке
                        height: 24,
                      ),
                      label: Text('Sign in with Google'),
                      style: OutlinedButton.styleFrom(
                        side: BorderSide(color: Colors.grey),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                    ),
                    SizedBox(height: size.height * 0.01),
                    OutlinedButton.icon(
                      onPressed: () {
                        // Логика входа через Apple
                      },
                      icon: Image.asset(
                        'assets/apple_icon.png', // Замените на путь к иконке
                        height: 24,
                      ),
                      label: Text('Sign in with Apple'),
                      style: OutlinedButton.styleFrom(
                        side: BorderSide(color: Colors.grey),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
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
