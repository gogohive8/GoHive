import 'dart:developer' as developer;
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../services/api_services.dart';

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
  bool _isPasswordVisible = false;
  bool _isLoading = false;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _apiService.dispose();
    super.dispose();
  }

  Future<void> _handleSignIn(
      Future<Map<String, String>?> signInMethod, bool isGoogleLogin) async {
    if (_isLoading || !mounted) return;

    setState(() => _isLoading = true);
    try {
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const Center(child: CircularProgressIndicator()),
      );

      final authData = await signInMethod;
      if (!mounted) return;
      Navigator.pop(context);

      if (authData != null &&
          authData['token']?.isNotEmpty == true &&
          authData['userId']?.isNotEmpty == true) {
        developer.log(
            'Setting auth data: token=${authData['token']}, userId=${authData['userId']}, username=${authData['username']}, email=${authData['email']}',
            name: 'SignInScreen');
        final authProvider = Provider.of<AuthProvider>(context, listen: false);
        await authProvider.setAuthData(
          authData['token']!,
          authData['refreshToken']!,
          authData['userId']!,
          authData['email'] ?? _emailController.text,
          authData['username'] ?? '',
          isGoogleLogin: isGoogleLogin,
          isNewUser: authData['isNewUser'] == 'true',
        );

        if (authProvider.isAuthenticated) {
          if (isGoogleLogin) {
            try {
              final profile = await _apiService.getProfile(
                  authData['userId']!, authData['token']!);
              developer.log('Profile check: $profile', name: 'SignInScreen');

              if (mounted) {
                if (profile['username'] == null || profile['age'] == null) {
                  developer.log('Incomplete profile, redirecting to /sign_up',
                      name: 'SignInScreen');
                  Navigator.pushReplacementNamed(
                    context,
                    '/sign_up',
                    arguments: {
                      'isGoogleSignUp': true,
                      'userId': authData['userId'],
                      'email': authData['email'] ?? '',
                    },
                  );
                  return;
                }
              }
            } catch (e, stackTrace) {
              developer.log('Profile fetch error: $e',
                  name: 'SignInScreen', stackTrace: stackTrace);
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Failed to fetch profile: $e')),
                );
              }
              return;
            }
          }

          developer.log('User authenticated, navigating to appropriate route',
              name: 'SignInScreen');
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (mounted) {
              Navigator.pushReplacementNamed(
                context,
                authData['isNewUser'] == 'true' && isGoogleLogin
                    ? '/welcome'
                    : '/home',
              );
            }
          });
        } else {
          developer.log('Authentication failed: AuthProvider not updated',
              name: 'SignInScreen');
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                  content: Text('Failed to authenticate. Please try again.')),
            );
          }
        }
      } else {
        developer.log('Invalid auth data: $authData', name: 'SignInScreen');
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
                content: Text(isGoogleLogin
                    ? 'Google Sign-In failed: Invalid response from server'
                    : 'Invalid email or password')),
          );
        }
      }
    } catch (e, stackTrace) {
      developer.log('Sign-in error: $e',
          name: 'SignInScreen', stackTrace: stackTrace);
      if (mounted) {
        Navigator.pop(context, false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text(isGoogleLogin
                  ? 'Google Sign-In error: $e'
                  : 'Login error: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _signInWithEmail() async {
    if (_formKey.currentState!.validate()) {
      developer.log(
          'Attempting to sign in with email: ${_emailController.text}',
          name: 'SignInScreen');
      await _handleSignIn(
          _apiService.login(_emailController.text, _passwordController.text),
          false);
    } else {
      developer.log('Form validation failed', name: 'SignInScreen');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Please check your input fields')),
        );
      }
    }
  }

  // Future<void> _signInWithFacebook() async {
  //   developer.log('Attempting Facebook sign-in', name: 'SignInScreen');
  //   await _handleSignIn(_apiService.signInWithFacebook(), false);
  // }

  Future<void> _signInWithGoogle() async {
    developer.log('Attempting Google sign-in', name: 'SignInScreen');
    await _handleSignIn(_apiService.signInWithGoogle(), true);
  }

  // Future<void> _signInWithApple() async {
  //   developer.log('Attempting Apple sign-in', name: 'SignInScreen');
  //   await _handleSignIn(_apiService.signInWithApple(), false);
  // }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final padding = size.width * 0.05;

    return Consumer<AuthProvider>(
      builder: (context, authProvider, child) {
        if (authProvider.isInitialized &&
            authProvider.isAuthenticated &&
            !_isLoading) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (mounted) {
              developer.log('Already authenticated, navigating to /home',
                  name: 'SignInScreen');
              Navigator.pushReplacementNamed(context, '/home');
            }
          });
        }

        return Scaffold(
          backgroundColor: const Color(0xFFF9F6F2),
          body: SafeArea(
            child: Center(
              child: SingleChildScrollView(
                padding: EdgeInsets.symmetric(horizontal: padding),
                child: Form(
                  key: _formKey,
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Image.asset(
                        'assets/logo_background.png',
                        height: size.height * 0.28,
                        width: size.width * 0.42,
                        fit: BoxFit.contain,
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        'GoHive',
                        style: TextStyle(
                          fontFamily: 'TT Norms Pro Trial',
                          fontWeight: FontWeight.bold,
                          fontSize: 32,
                          height: 40 / 32,
                          letterSpacing: -0.02 * 32,
                          color: Color(0xFF222220),
                        ),
                        textAlign: TextAlign.center,
                      ),
                      SizedBox(height: size.height * 0.05),
                      TextFormField(
                        controller: _emailController,
                        decoration: InputDecoration(
                          labelText: 'Email',
                          labelStyle: const TextStyle(color: Color(0xFF1A1A1A)),
                          filled: true,
                          fillColor: const Color.fromRGBO(221, 221, 221, 0.2),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                            borderSide: BorderSide.none,
                          ),
                          prefixIcon:
                              const Icon(Icons.email, color: Color(0xFF333333)),
                        ),
                        keyboardType: TextInputType.emailAddress,
                        style: const TextStyle(color: Color(0xFF1A1A1A)),
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Please enter your email';
                          }
                          if (!RegExp(r'^[^\s@]+@[^\s@]+\.[^\s@]+$')
                              .hasMatch(value)) {
                            return 'Invalid email format';
                          }
                          return null;
                        },
                      ),
                      SizedBox(height: size.height * 0.02),
                      TextFormField(
                        controller: _passwordController,
                        decoration: InputDecoration(
                          labelText: 'Password',
                          labelStyle: const TextStyle(color: Color(0xFF1A1A1A)),
                          filled: true,
                          fillColor: const Color.fromRGBO(221, 221, 221, 0.2),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                            borderSide: BorderSide.none,
                          ),
                          prefixIcon:
                              const Icon(Icons.lock, color: Color(0xFF333333)),
                          suffixIcon: IconButton(
                            icon: Icon(
                              _isPasswordVisible
                                  ? Icons.visibility
                                  : Icons.visibility_off,
                              color: const Color(0xFF333333),
                            ),
                            onPressed: () => setState(
                                () => _isPasswordVisible = !_isPasswordVisible),
                          ),
                        ),
                        obscureText: !_isPasswordVisible,
                        style: const TextStyle(color: Color(0xFF1A1A1A)),
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Please enter your password';
                          }
                          if (value.length < 6) {
                            return 'Password must be at least 6 characters';
                          }
                          return null;
                        },
                        textInputAction: TextInputAction.done,
                        onFieldSubmitted: (_) => _signInWithEmail(),
                      ),
                      SizedBox(height: size.height * 0.03),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: _isLoading ? null : _signInWithEmail,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF5F93E6),
                            foregroundColor: const Color(0xFF000000),
                            padding: EdgeInsets.symmetric(
                                vertical: size.height * 0.02),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                            disabledBackgroundColor:
                                const Color(0xFF5F93E6).withValues(alpha: 0.5),
                          ),
                          child: Text(
                            'Sign In',
                            style: TextStyle(fontSize: size.width * 0.045),
                          ),
                        ),
                      ),
                      SizedBox(height: size.height * 0.03),
                      const Text(
                        'Or',
                        style: TextStyle(color: Color(0xFF333333)),
                      ),
                      SizedBox(height: size.height * 0.03),
                      SizedBox(
                        width: double.infinity,
                        child: OutlinedButton(
                          onPressed: _isLoading
                              ? null
                              : () => Navigator.pushNamed(context, '/sign_up'),
                          style: OutlinedButton.styleFrom(
                            side: const BorderSide(color: Color(0xFF333333)),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                            backgroundColor:
                                const Color.fromRGBO(221, 221, 221, 0.1),
                            disabledBackgroundColor:
                                const Color.fromRGBO(221, 221, 221, 0.1),
                          ),
                          child: const Text(
                            'Sign Up',
                            style: TextStyle(color: Color(0xFF1A1A1A)),
                          ),
                        ),
                      ),
                      SizedBox(height: size.height * 0.03),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          _buildSocialButton(
                            icon: Image.asset('assets/email_icon.png',
                                height: 24),
                            onPressed: _signInWithEmail,
                          ),
                          // SizedBox(width: size.width * 0.05),
                          // _buildSocialButton(
                          //   icon: Image.asset('assets/facebook_icon.png',
                          //       height: 24),
                          //   onPressed: _signInWithFacebook,
                          // ),
                          SizedBox(width: size.width * 0.05),
                          _buildSocialButton(
                            icon: Image.asset('assets/google_icon.png',
                                height: 24),
                            onPressed: _signInWithGoogle,
                          ),
                          // SizedBox(width: size.width * 0.05),
                          // _buildSocialButton(
                          //   icon: Image.asset('assets/apple_icon.png',
                          //       height: 24),
                          //   onPressed: _signInWithApple,
                          // ),
                        ],
                      ),
                      SizedBox(height: size.height * 0.03),
                      const Text(
                        'By clicking the “Sign in” button, you confirm that you accept the user agreement and consent to the processing of your personal data.',
                        style: TextStyle(
                          fontFamily: 'Inter',
                          fontSize: 13,
                          color: Color(0xFF222220),
                          height: 18 / 13,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildSocialButton({
    required Widget icon,
    required VoidCallback onPressed,
  }) {
    return OutlinedButton(
      onPressed: _isLoading ? null : onPressed,
      style: OutlinedButton.styleFrom(
        side: const BorderSide(color: Color(0xFF333333)),
        shape: const CircleBorder(),
        padding: const EdgeInsets.all(12),
        backgroundColor: const Color.fromRGBO(221, 221, 221, 0.1),
        disabledBackgroundColor: const Color.fromRGBO(221, 221, 221, 0.1),
      ),
      child: icon,
    );
  }
}
