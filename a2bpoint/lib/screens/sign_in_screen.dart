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
  String? _email;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _signInWithEmail() async {
    if (_formKey.currentState!.validate()) {
      try {
        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (context) =>
              const Center(child: CircularProgressIndicator()),
        );
        final authData = await _apiService.login(
            _emailController.text, _passwordController.text);
        if (authData != null && mounted) {
          Provider.of<AuthProvider>(context, listen: false)
              .setAuthData(authData['token'] ?? '', authData['userId'] ?? '');
          Navigator.pop(context);
          Navigator.pushReplacementNamed(context, '/home');
        }
      } catch (e) {
        if (mounted) {
          Navigator.pop(context);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Ошибка входа: $e')),
          );
        }
      }
    }
  }

  Future<void> _signInWithGoogle() async {
    // Комментарий для второго разработчика:
    // Для работы Google-авторизации через Supabase необходимо:
    // 1. Убедиться, что пакет 'supabase_flutter' добавлен в pubspec.yaml.
    // 2. Настроить OAuth в Supabase Dashboard (раздел Authentication -> Providers -> Google):
    //    - Включить Google Provider.
    //    - Указать Client ID и Client Secret из Google Cloud Console.
    // 3. Настроить redirect URL в Supabase и приложении:
    //    - В Supabase: Authentication -> Settings -> Redirect URLs (например, 'io.supabase.flutterquickstart://callback').
    //    - В Android: android/app/src/main/AndroidManifest.xml добавить <intent-filter> с scheme='io.supabase.flutterquickstart'.
    //    - В iOS: ios/Runner/Info.plist добавить CFBundleURLSchemes с 'io.supabase.flutterquickstart'.
    // 4. Проверить, что Supabase клиент инициализирован в main.dart (Supabase.initialize).
    try {
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const Center(child: CircularProgressIndicator()),
      );
      final authData = await _apiService.signInWithGoogle();
      if (authData != null && mounted) {
        Provider.of<AuthProvider>(context, listen: false)
            .setAuthData(authData['token'] ?? '', authData['userId'] ?? '');
        Navigator.pop(context);
        Navigator.pushReplacementNamed(context, '/home');
      }
    } catch (e) {
      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Ошибка Google входа: $e')),
        );
      }
    }
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
            child: Form(
              key: _formKey,
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
                  TextFormField(
                    controller: _emailController,
                    onChanged: (value) => _email = value,
                    decoration: InputDecoration(
                      labelText: 'Your email',
                      border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10)),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide: const BorderSide(color: Colors.purple),
                      ),
                      prefixIcon:
                          Image.asset('assets/email_icon.png', height: 24),
                    ),
                    keyboardType: TextInputType.emailAddress,
                    validator: (value) {
                      if (value == null || value.isEmpty)
                        return 'Введите email';
                      if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$')
                          .hasMatch(value!)) return 'Неверный формат email';
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
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide: const BorderSide(color: Colors.purple),
                      ),
                    ),
                    obscureText: true,
                    validator: (value) {
                      if (value == null || value.isEmpty)
                        return 'Введите пароль';
                      if (value.length < 6) return 'Минимум 6 символов';
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
                  const Text('Or', style: TextStyle(fontSize: 16)),
                  SizedBox(height: size.height * 0.03),
                  Column(
                    children: [
                      SizedBox(
                        width: double.infinity,
                        child: OutlinedButton(
                          onPressed: () =>
                              Navigator.pushNamed(context, '/sign-up'),
                          style: OutlinedButton.styleFrom(
                            side: const BorderSide(color: Colors.purple),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                            minimumSize: Size(double.infinity, 50),
                            backgroundColor: Colors.purple.withOpacity(0.1),
                          ),
                          child: const Text('Sign up',
                              style: TextStyle(color: Colors.purple)),
                        ),
                      ),
                      SizedBox(height: size.height * 0.01),
                      SizedBox(
                        width: double.infinity,
                        child: OutlinedButton.icon(
                          onPressed: _signInWithGoogle,
                          icon:
                              Image.asset('assets/google_icon.png', height: 24),
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
                    ],
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
