import 'package:flutter/material.dart';
import 'package:intl_phone_number_input/intl_phone_number_input.dart';
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
  final _phoneController = TextEditingController();
  final _passwordController = TextEditingController();
  final ApiService _apiService = ApiService();
  final bool useDummyAuth = true;
  String? _phoneNumber;
  PhoneNumber? _initialPhoneNumber;

  @override
  void initState() {
    super.initState();
    _initialPhoneNumber = PhoneNumber(isoCode: 'KZ', dialCode: '+7');
  }

  @override
  void dispose() {
    _phoneController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _signInWithPhone() async {
    if (_formKey.currentState!.validate()) {
      try {
        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (context) =>
              const Center(child: CircularProgressIndicator()),
        );
        if (useDummyAuth) {
          await Future.delayed(const Duration(seconds: 1));
          if (_phoneNumber == '+77777777777' &&
              _passwordController.text == 'password123') {
            Provider.of<AuthProvider>(context, listen: false)
                .setAuthData('dummy_token', 'dummy_user');
            if (mounted) {
              Navigator.pop(context);
              Navigator.pushReplacementNamed(context, '/home');
            }
          } else {
            if (mounted) {
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                    content: Text(
                        'У вас нет такого аккаунта. Пройдите регистрацию.')),
              );
            }
          }
        } else {
          final authData = await _apiService.login(
              _phoneNumber ?? '', _passwordController.text);
          if (authData != null && mounted) {
            Provider.of<AuthProvider>(context, listen: false)
                .setAuthData(authData['token'] ?? '', authData['userId'] ?? '');
            Navigator.pop(context);
            Navigator.pushReplacementNamed(context, '/home');
          }
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
                  InternationalPhoneNumberInput(
                    initialValue: _initialPhoneNumber,
                    onInputChanged: (PhoneNumber number) {
                      _phoneNumber = number.phoneNumber;
                    },
                    selectorConfig: const SelectorConfig(
                      selectorType: PhoneInputSelectorType.DIALOG,
                      useEmoji: true,
                      trailingSpace: false,
                    ),
                    ignoreBlank: false,
                    autoValidateMode: AutovalidateMode.onUserInteraction,
                    selectorTextStyle: const TextStyle(color: Colors.black),
                    textFieldController: _phoneController,
                    formatInput: true,
                    keyboardType: const TextInputType.numberWithOptions(
                        signed: true, decimal: false),
                    inputDecoration: InputDecoration(
                      labelText: 'Your phone number',
                      border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10)),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide: const BorderSide(color: Colors.purple),
                      ),
                      prefixIcon: const Icon(Icons.phone, color: Colors.purple),
                    ),
                    textStyle: const TextStyle(fontSize: 16),
                    validator: (value) {
                      if (value == null || value.isEmpty)
                        return 'Введите номер телефона';
                      final cleanValue =
                          value.replaceAll(RegExp(r'[\s\-\+\(\)]'), '');
                      if (cleanValue.length > 11)
                        return 'Номер не должен превышать 11 символов';
                      if (!RegExp(r'^(8|7|\+7)?\d{10}$').hasMatch(cleanValue))
                        return 'Неверный формат номера';
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
                    textInputAction: TextInputAction.done,
                    validator: (value) {
                      if (value == null || value.isEmpty)
                        return 'Введите пароль';
                      if (value.length < 6) return 'Минимум 6 символов';
                      return null;
                    },
                    onFieldSubmitted: (_) => _signInWithPhone(),
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
                          onPressed: () => Navigator.pushNamed(
                              context, '/social-sign-in',
                              arguments: 'email'),
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
                          onPressed: () => Navigator.pushNamed(
                              context, '/social-sign-in',
                              arguments: 'google'),
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
