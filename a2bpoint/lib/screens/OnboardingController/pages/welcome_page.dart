import 'dart:async';
import 'dart:convert';
import '../../../services/exceptions.dart';
import 'dart:developer' as developer;
import 'package:flutter/material.dart';
import 'package:app_links/app_links.dart';
import 'package:http/http.dart' as http;
import '../onboarding_controller.dart';
import '../../../providers/auth_provider.dart';
import 'package:provider/provider.dart';

class WelcomePage extends StatefulWidget {
  final String username;
  final VoidCallback onContinue;
  final OnboardingData data;
  final bool isGoogleSignUp;

  const WelcomePage({
    super.key,
    required this.data,
    required this.username,
    required this.onContinue,
    required this.isGoogleSignUp,
  });

  @override
  State<WelcomePage> createState() => _WelcomePageState();
}

class _WelcomePageState extends State<WelcomePage>
    with TickerProviderStateMixin {
  late AnimationController _fadeController;
  late AnimationController _scaleController;
  late Animation<double> _fadeAnimation;
  late Animation<double> _scaleAnimation;

  StreamSubscription<Uri?>? _deepLinkSub;
  final AppLinks _appLinks = AppLinks();
  bool _isVerified = false;
  bool _isVerifying = false;
  bool _allowContinue = false; // ИСПРАВЛЕНО: блокируем переход по умолчанию
  String _statusMessage = '';

  @override
  void initState() {
    super.initState();
    _initAnimations();
    _startAnimations();
    
    // ИСПРАВЛЕНО: разная логика для Google и Email регистрации
    if (widget.isGoogleSignUp) {
      // Для Google - сразу разрешаем переход
      _allowContinue = true;
      _isVerified = true;
      _statusMessage = 'You\'re all set!';
    } else {
      // Для Email - ждем верификации
      _statusMessage = 'Please check your email';
      _initDeepLinks();
    }
  }

  Future<dynamic> _handleResponse(http.Response response) async {
    developer.log('Response: ${response.statusCode}, body: ${response.body}',
        name: 'WelcomePage');
    if (response.statusCode >= 200 && response.statusCode < 300) {
      if (response.statusCode == 204) return {};
      return response.body.isNotEmpty ? jsonDecode(response.body) : {};
    }
    if (response.statusCode == 400) {
      final errorBody = jsonDecode(response.body);
      final errorMessage = errorBody['error']?.toString() ?? 'Invalid input';
      developer.log('Validation error: $errorMessage', name: 'WelcomePage');
      throw DataValidationException('Invalid input: $errorMessage');
    }
    if (response.statusCode == 401) {
      developer.log('Unauthorized: ${response.body}', name: 'WelcomePage');
      throw AuthenticationException('Unauthorized: ${response.body}');
    }
    throw Exception('Request failed: ${response.statusCode} ${response.body}');
  }

  void _initAnimations() {
    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    );

    _scaleController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );

    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _fadeController,
      curve: Curves.easeInOut,
    ));

    _scaleAnimation = Tween<double>(
      begin: 0.8,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _scaleController,
      curve: Curves.elasticOut,
    ));
  }

  void _startAnimations() {
    Future.delayed(const Duration(milliseconds: 300), () {
      _fadeController.forward();
    });

    Future.delayed(const Duration(milliseconds: 500), () {
      _scaleController.forward();
    });
  }

  Future<void> _initDeepLinks() async {
    try {
      final initialLink = await _appLinks.getInitialLink();
      _handleDeepLink(initialLink);
    } catch (e) {
      developer.log('Initial deep link error: $e', name: 'WelcomePage');
    }

    _deepLinkSub = _appLinks.uriLinkStream.listen(
      (Uri? link) => _handleDeepLink(link),
      onError: (err) {
        developer.log('Deep link error: $err', name: 'WelcomePage');
      },
    );
  }

  Future<void> _handleDeepLink(Uri? link) async {
    if (link != null &&
        (link.toString().contains(
                'https://gohive-web-redirect-ba78112bb5c7.herokuapp.com/verify-email') ||
            link.toString().contains('com.example.a2bpoint://login-callback'))) {

      final uri = Uri.parse(link.toString());
      final token = uri.queryParameters['token'];

      if (token != null) {
        setState(() {
          _isVerifying = true;
          _statusMessage = 'Verifying your email...';
        });

        try {
          developer.log('Received verification token: $token',
              name: 'WelcomePage');

          final res = await http.get(
            Uri.parse(
                'https://gohive-user-service-efb5dea164ed.herokuapp.com/verify-email?token=$token'),
            headers: {'Content-Type': 'application/json'},
          ).timeout(const Duration(seconds: 30));

          if (res.statusCode == 200) {
            final resData = await _handleResponse(res);
            
            if (resData['token']?.isNotEmpty == true &&
                resData['userID']?.isNotEmpty == true) {
              
              // ИСПРАВЛЕНО: устанавливаем данные аутентификации
              final authProvider = Provider.of<AuthProvider>(context, listen: false);
              await authProvider.setAuthData(
                resData['token']!,
                resData['refreshToken'] ?? '',
                resData['userID'],
                widget.data.email,
                widget.data.username,
              );
              
              setState(() {
                _isVerified = true;
                _allowContinue = true;
                _statusMessage = 'Email verified successfully!';
              });
              
              developer.log('Email verification successful', name: 'WelcomePage');
            } else {
              throw Exception('Invalid verification response');
            }
          } else {
            throw Exception('Verification failed: ${res.statusCode}');
          }
        } catch (e, stackTrace) {
          developer.log('Email verification error: $e',
              name: 'WelcomePage', stackTrace: stackTrace);
          setState(() {
            _statusMessage = 'Verification failed. Please try again.';
            _allowContinue = false;
          });
          
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Email verification failed: ${e.toString()}'),
                backgroundColor: Colors.red,
              ),
            );
          }
        } finally {
          setState(() {
            _isVerifying = false;
          });
        }
      }
    }
  }

  // НОВЫЙ метод для повторной отправки email
  Future<void> _resendVerificationEmail() async {
    try {
      setState(() {
        _isVerifying = true;
        _statusMessage = 'Sending verification email...';
      });

      // TODO: Добавить API endpoint для повторной отправки verification email
      // final response = await http.post(
      //   Uri.parse('https://gohive-user-service-efb5dea164ed.herokuapp.com/resend-verification'),
      //   headers: {'Content-Type': 'application/json'},
      //   body: jsonEncode({'email': widget.data.email}),
      // );

      // Временная задержка для демонстрации
      await Future.delayed(const Duration(seconds: 2));
      
      setState(() {
        _statusMessage = 'Verification email sent! Please check your inbox.';
      });
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Verification email sent successfully!'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      setState(() {
        _statusMessage = 'Failed to send verification email.';
      });
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to send email: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      setState(() {
        _isVerifying = false;
      });
    }
  }

  double _getResponsiveWidth(BuildContext context) {
    return MediaQuery.of(context).size.width;
  }

  double _getResponsiveHeight(BuildContext context) {
    return MediaQuery.of(context).size.height;
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = _getResponsiveWidth(context);
    final screenHeight = _getResponsiveHeight(context);

    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color(0xFF0056F7),
            Color(0xFF0041C7),
            Color(0xFF002D97),
          ],
        ),
      ),
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: screenWidth * 0.08),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Spacer(flex: 2),

            // Animated Logo/Icon
            AnimatedBuilder(
              animation: _scaleAnimation,
              builder: (context, child) {
                return Transform.scale(
                  scale: _scaleAnimation.value,
                  child: Container(
                    width: screenWidth * 0.3,
                    height: screenWidth * 0.3,
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(screenWidth * 0.15),
                      border: Border.all(
                        color: Colors.white.withOpacity(0.3),
                        width: 2,
                      ),
                    ),
                    child: Icon(
                      _isVerified 
                          ? Icons.check_circle
                          : _isVerifying
                              ? Icons.hourglass_empty
                              : Icons.email_outlined,
                      size: screenWidth * 0.15,
                      color: Colors.white,
                    ),
                  ),
                );
              },
            ),

            SizedBox(height: screenHeight * 0.06),

            // Welcome Text
            AnimatedBuilder(
              animation: _fadeAnimation,
              builder: (context, child) {
                return Opacity(
                  opacity: _fadeAnimation.value,
                  child: Column(
                    children: [
                      Text(
                        widget.isGoogleSignUp ? 'Welcome!' : 'Almost there!',
                        style: TextStyle(
                          fontSize: screenWidth * 0.12,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                          height: 1.1,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      if (!widget.isGoogleSignUp) ...[
                        SizedBox(height: screenHeight * 0.02),
                        Text(
                          widget.username,
                          style: TextStyle(
                            fontSize: screenWidth * 0.08,
                            fontWeight: FontWeight.w300,
                            color: Colors.white,
                            height: 1.1,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ],
                  ),
                );
              },
            ),

            SizedBox(height: screenHeight * 0.03),

            // Status Message
            AnimatedBuilder(
              animation: _fadeAnimation,
              builder: (context, child) {
                return Opacity(
                  opacity: _fadeAnimation.value * 0.8,
                  child: Text(
                    _statusMessage,
                    style: TextStyle(
                      fontSize: screenWidth * 0.045,
                      fontWeight: FontWeight.w400,
                      color: Colors.white.withOpacity(0.9),
                    ),
                    textAlign: TextAlign.center,
                  ),
                );
              },
            ),

            // Resend Email Button (только для email регистрации)
            if (!widget.isGoogleSignUp && !_isVerified) ...[
              SizedBox(height: screenHeight * 0.02),
              AnimatedBuilder(
                animation: _fadeAnimation,
                builder: (context, child) {
                  return Opacity(
                    opacity: _fadeAnimation.value,
                    child: TextButton(
                      onPressed: _isVerifying ? null : _resendVerificationEmail,
                      child: Text(
                        'Resend verification email',
                        style: TextStyle(
                          fontSize: screenWidth * 0.04,
                          color: Colors.white.withOpacity(0.8),
                          decoration: TextDecoration.underline,
                        ),
                      ),
                    ),
                  );
                },
              ),
            ],

            const Spacer(flex: 3),

            // Continue Button
            AnimatedBuilder(
              animation: _fadeAnimation,
              builder: (context, child) {
                return Opacity(
                  opacity: _fadeAnimation.value,
                  child: SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: _allowContinue && !_isVerifying 
                          ? widget.onContinue 
                          : null,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: _allowContinue 
                            ? Colors.white 
                            : Colors.white.withOpacity(0.5),
                        foregroundColor: const Color(0xFF0056F7),
                        padding:
                            EdgeInsets.symmetric(vertical: screenHeight * 0.02),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(25),
                        ),
                        elevation: 0,
                        shadowColor: Colors.transparent,
                      ),
                      child: _isVerifying
                          ? SizedBox(
                              height: screenHeight * 0.025,
                              width: screenHeight * 0.025,
                              child: const CircularProgressIndicator(
                                  strokeWidth: 2),
                            )
                          : Text(
                              _isVerified || widget.isGoogleSignUp
                                  ? 'Go to Home'
                                  : 'Waiting for verification...',
                              style: TextStyle(
                                fontSize: screenWidth * 0.045,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                    ),
                  ),
                );
              },
            ),

            SizedBox(height: screenHeight * 0.05),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    _fadeController.dispose();
    _scaleController.dispose();
    _deepLinkSub?.cancel();
    super.dispose();
  }
}