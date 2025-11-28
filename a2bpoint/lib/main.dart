import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:app_links/app_links.dart';
import 'dart:async';
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

// Deep link handler
void _handleDeepLink(Uri link, BuildContext? context) {
  developer.log('Handling deep link: $link', name: 'DeepLink');
  
  // Handle the OAuth callback
  if (link.host == 'login-callback') {
    developer.log('Received OAuth callback', name: 'DeepLink');
    
    // Supabase will handle the OAuth session automatically
    // We just need to ensure the app state is updated
    if (context != null) {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      authProvider.initialize(); // Refresh auth state
    }
  }
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

  // Initialize app links for deep linking
  final appLinks = AppLinks();
  
  // Handle deep links when app is opened from a link
  final initialLink = await appLinks.getInitialLink();
  if (initialLink != null) {
    developer.log('Initial deep link: $initialLink', name: 'DeepLink');
    // We'll handle this after the app is fully initialized
  }

  try {
    await Supabase.initialize(
      url: 'https://osyajqltbkudsfcppqgh.supabase.co',
      anonKey: 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Im9zeWFqcWx0Ymt1ZHNmY3BwcWdoIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NDkyOTA2MjIsImV4cCI6MjA2NDg2NjYyMn0.nL4ENxcHrchOK3HgCyG6sQkxsj_KXwpriZhpmmV7liA',
    );
    developer.log('Supabase initialized successfully', name: 'Main');
  } catch (e) {
    developer.log('Supabase initialization error: $e', name: 'Main');
  }

  runApp(MyApp(appLinks: appLinks, initialLink: initialLink));
}

class MyApp extends StatelessWidget {
  final AppLinks appLinks;
  final Uri? initialLink;
  
  const MyApp({
    super.key,
    required this.appLinks,
    this.initialLink,
  });

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
          // Initialize deep link listener here where authProvider is available
          WidgetsBinding.instance.addPostFrameCallback((_) {
            // Handle initial deep link if present
            if (initialLink != null) {
              _handleDeepLink(initialLink!, authProvider.navigatorKey.currentContext);
            }
            
            // Listen for new deep links
            appLinks.uriLinkStream.listen((uri) {
              developer.log('New deep link: $uri', name: 'DeepLink');
              final currentContext = authProvider.navigatorKey.currentContext;
              if (currentContext != null) {
                _handleDeepLink(uri, currentContext);
              }
            });
          });
          
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
