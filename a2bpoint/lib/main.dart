import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'screens/Auth/sign_in_screen.dart';
import 'screens/OnboardingController/onboarding_controller.dart';
import 'screens/Home/home_screen.dart';
import 'screens/add_screen.dart';
import 'screens/Profile/profile_screen.dart';
import 'screens/AI_mentor/ai_mentor_screen.dart';
import 'screens/Chats/chat_list_screen.dart'; 
import 'providers/auth_provider.dart';
import 'providers/chat_provider.dart'; 
import 'screens/search_screen.dart';
import 'dart:developer' as developer;
import 'providers/posts_provider.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';

// Background handler
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp();
  print('Background message: ${message.notification?.title}, data: ${message.data}');
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

  try {
    await Supabase.initialize(
      url: 'https://osyajqltbkudsfcppqgh.supabase.co',
      anonKey: 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Im9zeWFqcWx0Ymt1ZHNmY3BwcWdoIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NDkyOTA2MjIsImV4cCI6MjA2NDg2NjYyMn0.nL4ENxcHrchOK3HgCyG6sQkxsj_KXwpriZhpmmV7liA',
    );
    developer.log('Supabase initialized successfully', name: 'Main');
  } catch (e) {
    developer.log('Supabase initialization error: $e', name: 'Main');
  }

  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthProvider()..initialize()),
        ChangeNotifierProvider(create: (_) => PostsProvider()),
        ChangeNotifierProvider(create: (_) => ChatProvider()),
      ],
      child: Consumer<AuthProvider>(
        builder: (context, authProvider, child) {
          return MaterialApp(
            title: 'GoHive',
            navigatorKey: authProvider.navigatorKey, // КРИТИЧЕСКИ ВАЖНО!
            theme: ThemeData(
              primaryColor: const Color(0xFFAFCBEA),
              scaffoldBackgroundColor: const Color(0xFFF9F6F2),
              visualDensity: VisualDensity.adaptivePlatformDensity,
            ),
            
            // ИСПРАВЛЕНО: динамическое определение начального маршрута
            initialRoute: authProvider.isInitialized 
                ? (authProvider.isAuthenticated ? '/home' : '/sign_in')
                : '/sign_in',
            
            // ИСПРАВЛЕНО: все маршруты включая недостающие
            routes: {
              '/sign_in': (context) => const SignInScreen(),
              '/login': (context) => const SignInScreen(), // Алиас для совместимости
              '/sign_up': (context) => const OnboardingController(),
              '/home': (context) => const HomeScreen(),
              '/add': (context) => const AddScreen(),
              '/profile': (context) => const ProfileScreen(),
              '/search': (context) => const SearchScreen(),
              '/ai-mentor': (context) => const AIMentorScreen(),
              '/chat_list': (context) => ChatListScreen(),
            },
            
            // ИСПРАВЛЕНО: обработка неизвестных маршрутов
            onGenerateRoute: (settings) {
              developer.log('Navigating to: ${settings.name}', name: 'Router');
              
              switch (settings.name) {
                case '/sign_in':
                case '/login':
                  return MaterialPageRoute(builder: (context) => const SignInScreen());
                case '/sign_up':
                  return MaterialPageRoute(builder: (context) => const OnboardingController());
                case '/home':
                  return MaterialPageRoute(builder: (context) => const HomeScreen());
                case '/add':
                  return MaterialPageRoute(builder: (context) => const AddScreen());
                case '/profile':
                  return MaterialPageRoute(builder: (context) => const ProfileScreen());
                case '/search':
                  return MaterialPageRoute(builder: (context) => const SearchScreen());
                case '/ai-mentor':
                  return MaterialPageRoute(builder: (context) => const AIMentorScreen());
                case '/chat_list':
                  return MaterialPageRoute(builder: (context) => ChatListScreen());
                default:
                  developer.log('Unknown route: ${settings.name}', name: 'Router');
                  // Безопасное перенаправление
                  if (authProvider.isInitialized && authProvider.isAuthenticated) {
                    return MaterialPageRoute(builder: (context) => const HomeScreen());
                  } else {
                    return MaterialPageRoute(builder: (context) => const SignInScreen());
                  }
              }
            },
            
            // ИСПРАВЛЕНО: обработчик неизвестных маршрутов
            onUnknownRoute: (settings) {
              developer.log('Unknown route fallback: ${settings.name}', name: 'Router');
              if (authProvider.isInitialized && authProvider.isAuthenticated) {
                return MaterialPageRoute(builder: (context) => const HomeScreen());
              } else {
                return MaterialPageRoute(builder: (context) => const SignInScreen());
              }
            },
          );
        },
      ),
    );
  }
}

// ДОПОЛНИТЕЛЬНО: Обертка для проверки аутентификации
class AuthGuard extends StatelessWidget {
  final Widget child;
  final Widget? fallback;

  const AuthGuard({
    Key? key,
    required this.child,
    this.fallback,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Consumer<AuthProvider>(
      builder: (context, authProvider, _) {
        if (!authProvider.isInitialized) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        if (!authProvider.isAuthenticated) {
          return fallback ?? SignInScreen();
        }

        return child;
      },
    );
  }
}