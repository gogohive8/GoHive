import 'package:flutter/material.dart';
import 'package:intl_phone_number_input/intl_phone_number_input.dart';
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
  final bool useDummyAuth = true; // Переключатель для заглушки
  String? _phoneNumber; // Для хранения отформатированного номера
  PhoneNumber? _initialPhoneNumber; // Для начального значения

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
          await Future.delayed(const Duration(seconds: 1)); // Имитация запроса
          print('Phone number checked: $_phoneNumber'); // Для отладки
          // Проверка с отформатированным номером
          if (_phoneNumber == '+77777777777' &&
              _passwordController.text == 'password123') {
            _apiService.setToken('dummy_token');
            if (mounted) {
              Navigator.pop(context); // Закрываем индикатор
              Navigator.pushReplacementNamed(context, '/home');
            }
          } else {
            if (mounted) {
              Navigator.pop(context); // Закрываем индикатор
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content:
                      Text('У вас нет такого аккаунта. Пройдите регистрацию.'),
                ),
              );
            }
          }
        } else {
          final token = await _apiService.login(
              _phoneNumber ?? '', _passwordController.text);
          if (mounted) {
            Navigator.pop(context); // Закрываем индикатор
            Navigator.pushReplacementNamed(context, '/home');
          }
        }
      } catch (e) {
        if (mounted) {
          Navigator.pop(context); // Закрываем индикатор
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
                      _phoneNumber = number
                          .phoneNumber; // Обновляем с отформатированным номером
                      print(
                          'Phone number updated: $_phoneNumber'); // Для отладки
                    },
                    onInputValidated: (bool value) {
                      if (!value && _phoneNumber != null) {
                        setState(() {
                          _phoneNumber = null;
                        });
                      }
                    },
                    selectorConfig: const SelectorConfig(
                      selectorType: PhoneInputSelectorType.DIALOG,
                      useEmoji: true,
                      trailingSpace: false, // Эмодзи в конце поля
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
                        borderRadius: BorderRadius.circular(10),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide: BorderSide(color: Colors.purple),
                      ),
                      prefixIcon: const Icon(Icons.phone,
                          color: Colors.purple), // Иконка внутри поля
                    ),
                    textStyle: const TextStyle(fontSize: 16),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Пожалуйста, введите номер телефона';
                      }
                      final cleanValue =
                          value.replaceAll(RegExp(r'[\s\-\+\(\)]'), '');
                      if (cleanValue.length > 11) {
                        return 'Номер не должен превышать 11 символов';
                      }
                      if (!RegExp(r'^(8|7|\+7)?\d{10}$').hasMatch(cleanValue)) {
                        return 'Введите корректный номер (например, +7 777 777 77 77)';
                      }
                      return null;
                    },
                    onSaved: (PhoneNumber number) {
                      _phoneNumber = number.phoneNumber;
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
                    ),
                    obscureText: true,
                    textInputAction: TextInputAction.done,
                    onSubmitted: (value) => _signInWithPhone(),
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
                        child: OutlinedButton(
                          onPressed: () =>
                              Navigator.pushNamed(context, '/sign-up'),
                          style: OutlinedButton.styleFrom(
                            side: const BorderSide(color: Colors.purple),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                            minimumSize: Size(double.infinity, 50),
                            backgroundColor: Colors.purple
                                .withOpacity(0.1), // Лёгкий фиолетовый фон
                          ),
                          child: const Text(
                            'Sign up',
                            style: TextStyle(color: Colors.purple),
                          ),
                        ),
                      ),
                      SizedBox(height: size.height * 0.01),
                      SizedBox(
                        width: double.infinity,
                        child: OutlinedButton.icon(
                          onPressed: () =>
                              Navigator.pushNamed(context, '/sign-up'),
                          icon: const Icon(Icons.email, color: Colors.black),
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
                              arguments: 'facebook'),
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
                          onPressed: () => Navigator.pushNamed(
                              context, '/social-sign-in',
                              arguments: 'google'),
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
                          onPressed: () => Navigator.pushNamed(
                              context, '/social-sign-in',
                              arguments: 'apple'),
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
      ),
    );
  }
}
