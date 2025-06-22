import 'dart:developer' as developer;
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../services/api_services.dart';
import '../services/exceptions.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

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
  bool _isLoading = false;
  bool _isPasswordVisible = false;

  @override
  void initState() {
    super.initState();
    // Listen for Supabase auth state changes
    final supabase = Supabase.instance.client;
    supabase.auth.onAuthStateChange.listen((data) {
      final event = data.event;
      if (event == AuthChangeEvent.signedIn && mounted) {
        developer.log('Supabase auth state changed: signed in',
            name: 'SignInScreen');
        _handleGoogleSignIn();
      }
    });
  }

  Future<void> _signInWithEmail() async {
    if (!mounted || _isLoading || !_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);
    developer.log('Attempting to sign in with email: ${_emailController.text}',
        name: 'SignInScreen');

    try {
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const Center(child: CircularProgressIndicator()),
      );

      final authData = await _apiService.login(
          _emailController.text.trim(), _passwordController.text.trim());
      developer.log('Login response: $authData', name: 'SignInScreen');

      if (mounted) Navigator.pop(context);

      if (authData != null &&
          authData['token']?.isNotEmpty == true &&
          authData['userId']?.isNotEmpty == true) {
        final authProvider = Provider.of<AuthProvider>(context, listen: false);
        await authProvider.setAuthData(authData['token']!, authData['userId']!);
        if (authProvider.isAuthenticated && mounted) {
          developer.log('User authenticated, navigating to /home',
              name: 'SignInScreen');
          Navigator.pushReplacementNamed(context, '/home');
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
            const SnackBar(content: Text('Invalid email or password')),
          );
        }
      }
    } catch (e, stackTrace) {
      developer.log('SignIn error: $e',
          name: 'SignInScreen', stackTrace: stackTrace);
      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Login error: ${e.toString()}')),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _handleGoogleSignIn() async {
    if (!mounted || _isLoading) return;

    setState(() => _isLoading = true);
    developer.log('Handling Google sign-in', name: 'SignInScreen');

    try {
      final supabase = Supabase.instance.client;
      final session = supabase.auth.currentSession;
      if (session == null) {
        throw Exception('No session available after Google OAuth');
      }

      final authData = await _apiService.signInWithGoogle();
      developer.log('Google sign-in response: $authData', name: 'SignInScreen');

      if (mounted) Navigator.pop(context);

      if (authData != null &&
          authData['token']?.isNotEmpty == true &&
          authData['userId']?.isNotEmpty == true) {
        final authProvider = Provider.of<AuthProvider>(context, listen: false);
        await authProvider.setAuthData(authData['token']!, authData['userId']!);

        // Check if profile is complete
        final profile = await _apiService.getProfile(
            authData['userId']!, authData['token']!);
        developer.log('Profile check: $profile', name: 'SignInScreen');

        if (mounted) {
          if (profile?['username'] == null || profile?['age'] == null) {
            developer.log('Incomplete profile, redirecting to /sign_up',
                name: 'SignInScreen');
            Navigator.pushReplacementNamed(
              context,
              '/sign_up',
              arguments: {
                'isGoogleSignUp': true,
                'userId': authData['userId'],
                'email': session.user.email,
              },
            );
          } else {
            developer.log('Profile complete, navigating to /home',
                name: 'SignInScreen');
            Navigator.pushReplacementNamed(context, '/home');
          }
        }
      } else {
        developer.log('Google sign-in failed: $authData', name: 'SignInScreen');
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Google sign-in failed')),
          );
        }
      }
    } catch (e, stackTrace) {
      developer.log('Sign-in error: $e',
          name: 'SignInScreen', stackTrace: stackTrace);
      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Google sign-in error: ${e.toString()}')),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _signInWithGoogle() async {
    if (!mounted || _isLoading) return;

    setState(() => _isLoading = true);
    developer.log('Attempting Google sign-in', name: 'SignInScreen');

    try {
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const Center(child: CircularProgressIndicator()),
      );

      final supabase = Supabase.instance.client;
      await supabase.auth
          .signInWithOAuth(
            OAuthProvider.google,
            redirectTo: 'io.supabase.gohive://login-callback/',
          )
          .timeout(const Duration(seconds: 30));
      developer.log('Google OAuth initiated', name: 'SignInScreen');
      // The actual sign-in is handled by _handleGoogleSignIn via onAuthStateChange
    } catch (e, stackTrace) {
      developer.log('Google OAuth error: $e',
          name: 'SignInScreen', stackTrace: stackTrace);
      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Google sign-in error: ${e.toString()}')),
        );
      }
    } finally {
      // Do not reset _isLoading here, as _handleGoogleSignIn will handle it
    }
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _apiService.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final padding = size.width * 0.05;

    return Consumer<AuthProvider>(
      builder: (context, authProvider, child) {
        // Auto-redirect if already authenticated
        if (authProvider.isInitialized && authProvider.isAuthenticated) {
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
                        height: size.height * 0.15,
                        fit: BoxFit.contain,
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        'GoHive',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 32,
                          height: 40 / 32,
                          letterSpacing: -0.02 * 32,
                          color: Color(0xFF000000),
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
                            backgroundColor: const Color(0xFFAFCBEA),
                            foregroundColor: const Color(0xFF000000),
                            padding: EdgeInsets.symmetric(
                                vertical: size.height * 0.02),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
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
                          ),
                          child: const Text(
                            'Sign Up',
                            style: TextStyle(color: Color(0xFF1A1A1A)),
                          ),
                        ),
                      ),
                      SizedBox(height: size.height * 0.01),
                      SizedBox(
                        width: double.infinity,
                        child: OutlinedButton.icon(
                          onPressed: _isLoading ? null : _signInWithGoogle,
                          icon:
                              Image.asset('assets/google_icon.png', height: 24),
                          label: const Text(
                            'Sign in with Google',
                            style: TextStyle(color: Color(0xFF1A1A1A)),
                          ),
                          style: OutlinedButton.styleFrom(
                            side: const BorderSide(color: Color(0xFF333333)),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                            backgroundColor:
                                const Color.fromRGBO(221, 221, 221, 0.1),
                          ),
                        ),
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
}
