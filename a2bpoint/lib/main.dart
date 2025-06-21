import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'providers/auth_provider.dart';
import 'screens/sign_in_screen.dart';
import 'screens/home_screen.dart';
import 'screens/add_screen.dart';
import 'screens/profile_screen.dart';
import 'screens/search_screen.dart';
import 'screens/ai_mentor_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (context) {
        final authProvider = AuthProvider();
        authProvider.initialize();
        return authProvider;
      },
      child: Consumer<AuthProvider>(
        builder: (context, authProvider, child) {
          return MaterialApp(
            title: 'Your App',
            theme: ThemeData(primarySwatch: Colors.blue),
            initialRoute: authProvider.isAuthenticated ? '/home' : '/sign_in',
            routes: {
              '/sign_in': (context) => const SignInScreen(),
              '/home': (context) => const HomeScreen(),
              '/add': (context) => const AddScreen(),
              '/profile': (context) => const ProfileScreen(),
              '/search': (context) => const SearchScreen(),
              '/ai-mentor': (context) => const AIMentorScreen(),
            },
            onGenerateRoute: (settings) {
              if (!authProvider.isAuthenticated &&
                  settings.name != '/sign_in') {
                return MaterialPageRoute(
                  builder: (context) => const SignInScreen(),
                );
              }
              return null;
            },
          );
        },
      ),
    );
  }
}
