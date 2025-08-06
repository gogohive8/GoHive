import 'dart:developer' as developer;
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../services/api_services.dart';
import 'pages/step_one_page.dart';
import 'pages/step_two_page.dart';
import 'pages/welcome_page.dart';

class OnboardingController extends StatefulWidget {
  const OnboardingController({super.key});

  @override
  State<OnboardingController> createState() => _OnboardingControllerState();
}

class _OnboardingControllerState extends State<OnboardingController> {
  final PageController _pageController = PageController();
  final ApiService _apiService = ApiService();

  int _currentStep = 0;
  bool _isLoading = false;
  bool _isGoogleSignUp = false;
  String? _userId;
  String? _googleEmail;

  // Данные пользователя собираемые по шагам
  final OnboardingData _data = OnboardingData();

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final args =
        ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;
    if (args != null && args['isGoogleSignUp'] == true) {
      _isGoogleSignUp = true;
      _userId = args['userId'];
      _googleEmail = args['email'];
      _data.email = _googleEmail ?? '';
    }
  }

  void _nextStep() {
    if (_currentStep < 2) {
      setState(() => _currentStep++);
      _pageController.nextPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    }
  }

  void _previousStep() {
    if (_currentStep > 0) {
      setState(() => _currentStep--);
      _pageController.previousPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    }
  }

  Future<void> _completeSignUp() async {
    if (_isLoading) return;

    setState(() => _isLoading = true);
    developer.log('Completing sign-up, isGoogleSignUp: $_isGoogleSignUp',
        name: 'OnboardingController');

    try {
      _showLoadingDialog();

      final authProvider = Provider.of<AuthProvider>(context, listen: false);

      if (_isGoogleSignUp && _userId != null) {
        // Google Sign-Up: обновляем профиль
        await _apiService.updateProfile(
          _userId!,
          authProvider.token!,
          {
            'name': _data.name,
            'surname': _data.surname,
            'username': _data.username,
            'age': _data.age,
            'phone': _data.phone,
            'interests': _data.interests,
            'birthDate': _data.birthDate?.toIso8601String(),
            'gender': _data.gender,
          },
          '', // photoURL
        );

        await authProvider.setAuthData(
          authProvider.token!,
          _userId!,
          _googleEmail ?? '',
          _data.username,
          isGoogleLogin: true,
        );
      } else {
        // Email Sign-Up: создаем нового пользователя
        final authData = await _apiService.signUp(
            _data.username, // username
            _data.email, // email
            _data.password, // password
            _data.name, // firstName (name)
            _data.surname, // lastName (surname)
            _data.age, // age
            _data.phone, // phoneNumber
            _data.birthDate,
            _data.gender,
            _data.city,
            _data.country);

        if (authData['token']?.isNotEmpty == true &&
            authData['userId']?.isNotEmpty == true) {
          await authProvider.setAuthData(
            authData['token']!,
            authData['userId']!,
            authData['email'] ?? _data.email,
            authData['username'] ?? _data.username,
          );
        } else {
          throw Exception('Sign-up failed: Invalid response');
        }
      }

      await authProvider.updateProfile(
        _data.username,
        '', // bio
        _data.email,
        null, // newAvatar
      );

      if (mounted) {
        Navigator.pop(context); // Закрываем loading dialog
        _nextStep(); // Переходим к Welcome экрану
      }
    } catch (e, stackTrace) {
      developer.log('Sign-up error: $e',
          name: 'OnboardingController', stackTrace: stackTrace);
      if (mounted) {
        Navigator.pop(context);
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _showLoadingDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(
        child: CircularProgressIndicator(color: Color(0xFF0056F7)),
      ),
    );
  }

  void _goToHome() {
    Navigator.pushReplacementNamed(context, '/home');
  }

  @override
  void dispose() {
    _pageController.dispose();
    _apiService.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor:
          _currentStep == 2 ? const Color(0xFF0056F7) : const Color(0xFFF4F3EE),
      body: SafeArea(
        child: Column(
          children: [
            // Custom App Bar с кнопкой назад
            if (_currentStep > 0)
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Row(
                  children: [
                    GestureDetector(
                      onTap: _previousStep,
                      child: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Icon(
                          Icons.arrow_back_ios,
                          color:
                              _currentStep == 2 ? Colors.white : Colors.black,
                          size: 20,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

            // Progress Indicator
            if (_currentStep < 2)
              Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                child: Row(
                  children: [
                    Expanded(
                      child: LinearProgressIndicator(
                        value: (_currentStep + 1) / 2,
                        backgroundColor: Colors.grey.withOpacity(0.3),
                        valueColor: const AlwaysStoppedAnimation<Color>(
                            Color(0xFF0056F7)),
                        minHeight: 4,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Text(
                      'Step ${_currentStep + 1}',
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        color: Color(0xFF666666),
                      ),
                    ),
                  ],
                ),
              ),

            // Page Content
            Expanded(
              child: PageView(
                controller: _pageController,
                physics: const NeverScrollableScrollPhysics(),
                onPageChanged: (index) => setState(() => _currentStep = index),
                children: [
                  StepOnePage(
                    data: _data,
                    isGoogleSignUp: _isGoogleSignUp,
                    onNext: _nextStep,
                  ),
                  StepTwoPage(
                    data: _data,
                    onNext: _completeSignUp,
                    isLoading: _isLoading,
                  ),
                  WelcomePage(
                    username: _data.name,
                    onContinue: _goToHome,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// Класс для хранения данных между шагами
class OnboardingData {
  String name = '';
  String surname = '';
  String username = '';
  String email = '';
  String password = '';
  String phone = '';
  int age = 0;
  DateTime? birthDate;
  String gender = '';
  List<String> interests = [];

  // Новые поля для локации и кода страны телефона
  String country = 'Kazakhstan';
  String city = 'Almaty';
  String phoneCountryCode = '+7';

  bool get isStepOneValid {
    return name.isNotEmpty &&
        surname.isNotEmpty &&
        username.isNotEmpty &&
        email.isNotEmpty &&
        password.isNotEmpty &&
        phone.isNotEmpty &&
        birthDate != null &&
        gender.isNotEmpty &&
        age >= 5 &&
        age <= 99 &&
        country.isNotEmpty &&
        city.isNotEmpty;
  }

  bool get isStepTwoValid {
    return interests.isNotEmpty;
  }

  void clear() {
    name = '';
    surname = '';
    username = '';
    email = '';
    password = '';
    phone = '';
    age = 0;
    birthDate = null;
    gender = '';
    interests.clear();
    country = 'Kazakhstan';
    city = 'Almaty';
    phoneCountryCode = '+7';
  }
}
