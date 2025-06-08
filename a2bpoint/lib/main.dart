import 'package:flutter/material.dart';
import 'screens/sign_in_screen.dart';
import 'screens/sign_up_screen.dart';
import 'screens/social_sign_in_screen.dart';
import 'screens/home_screen.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'services/api_services.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Supabase.initialize(
    url: 'https://osyajqltbkudsfcppqgh.supabase.co',
    anonKey:
        'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Im9zeWFqcWx0Ymt1ZHNmY3BwcWdoIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NDkyOTA2MjIsImV4cCI6MjA2NDg2NjYyMn0.nL4ENxcHrchOK3HgCyG6sQkxsj_KXwpriZhpmmV7liA',
  );

  runApp(
    ChangeNotifierProvider(
      create: (_) => AuthProvider(),
      child: MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'A2B Sign In',
      theme: ThemeData(
        primarySwatch: Colors.purple,
        visualDensity: VisualDensity.adaptivePlatformDensity,
        useMaterial3: true,
      ),
      initialRoute: '/sign-in',
      routes: {
        '/sign-in': (context) => const SignInScreen(),
        '/sign-up': (context) => const SignUpScreen(),
        '/social-sign-in': (context) => const SocialSignInScreen(),
        '/home': (context) => const HomeScreen(),
      },
    );
  }
}
