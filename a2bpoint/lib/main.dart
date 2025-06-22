import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'screens/sign_in_screen.dart';
import 'screens/sign_up_screen.dart';
import 'screens/home_screen.dart';
import 'screens/add_screen.dart';
import 'screens/profile_screen.dart';
import 'screens/ai_mentor_screen.dart';
import 'providers/auth_provider.dart';
import 'screens/search_screen.dart';
import 'dart:developer' as developer;
import 'providers/posts_provider.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  try {
    await Supabase.initialize(
      url: 'https://osyajqltbkudsfcppqgh.supabase.co',
      anonKey:
          'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Im9zeWFqcWx0Ymt1ZHNmY3BwcWdoIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NDkyOTA2MjIsImV4cCI6MjA2NDg2NjYyMn0.nL4ENxcHrchOK3HgCyG6sQkxsj_KXwpriZhpmmV7liA',
    );
    developer.log('Supabase initialized successfully', name: 'Main');
  } catch (e) {
    developer.log('Supabase initialization error: $e', name: 'Main');
  }

  runApp(
    ChangeNotifierProvider(
      create: (_) => AuthProvider()..initialize(),
      child: MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthProvider()),
        ChangeNotifierProvider(create: (_) => PostsProvider()),
      ],
      child: MaterialApp(
        title: 'GoHive',
        theme: ThemeData(
          primaryColor: const Color(0xFFAFCBEA),
          scaffoldBackgroundColor: const Color(0xFFF9F6F2),
        ),
        initialRoute: '/sign_in',
        routes: {
          '/sign_in': (context) => const SignInScreen(),
          '/sign_up': (context) => const SignUpScreen(),
          '/home': (context) => const HomeScreen(),
          '/add': (context) => const AddScreen(),
          '/profile': (context) => const ProfileScreen(),
          '/search': (context) => const SearchScreen(),
          '/ai-mentor': (context) => const AIMentorScreen(),
        },
      ),
    );
  }
}
