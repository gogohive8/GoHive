import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'screens/sign_in_screen.dart';
import 'screens/sign_up_screen.dart';
import 'screens/home_screen.dart';
import 'screens/add_screen.dart';
import 'screens/profile_screen.dart';
import 'screens/ai_mentor_screen.dart';
import 'providers/auth_provider.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Инициализация Supabase
  try {
    await Supabase.initialize(
      url: 'https://osyajqltbkudsfcppqgh.supabase.co',
      anonKey:
          'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Im9zeWFqcWx0Ymt1ZHNmY3BwcWdoIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NDkyOTA2MjIsImV4cCI6MjA2NDg2NjYyMn0.nL4ENxcHrchOK3HgCyG6sQkxsj_KXwpriZhpmmV7liA',
    );
    print('Supabase initialized successfully');
  } catch (e) {
    print('Supabase initialization error: $e');
    // Можно добавить обработку ошибки, например, показ уведомления
  }

  // Загрузка данных из кэша
  final prefs = await SharedPreferences.getInstance();
  String? cachedToken = prefs.getString('token');
  String? cachedUserId = prefs.getString('userId');

  runApp(
    ChangeNotifierProvider(
      create: (_) =>
          AuthProvider()..loadFromCache(), // Загрузка кэша при создании
      child: MyApp(cachedToken: cachedToken, cachedUserId: cachedUserId),
    ),
  );
}

class MyApp extends StatefulWidget {
  final String? cachedToken;
  final String? cachedUserId;

  const MyApp({super.key, this.cachedToken, this.cachedUserId});

  @override
  _MyAppState createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  @override
  void initState() {
    super.initState();
    // Инициализация состояния аутентификации из кэша, если есть
    if (widget.cachedToken != null && widget.cachedUserId != null) {
      Provider.of<AuthProvider>(context, listen: false)
          .setAuthData(widget.cachedToken!, widget.cachedUserId!);
    }

    // Подписка на изменения состояния аутентификации
    Supabase.instance.client.auth.onAuthStateChange.listen((data) {
      final session = data.session;
      if (session != null) {
        Provider.of<AuthProvider>(context, listen: false)
            .setAuthData(session.accessToken, session.user.id);
      } else {
        Provider.of<AuthProvider>(context, listen: false).clearAuth();
      }
    });
  }

  @override
  void dispose() {
    // Отписка от слушателя (опционально, если нужно избежать утечек)
    Supabase.instance.client.auth.onAuthStateChange.drain();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'A2B Sign In',
      theme: ThemeData(
        primarySwatch: Colors.purple,
        visualDensity: VisualDensity.adaptivePlatformDensity,
        useMaterial3: true,
      ),
      // Определяем начальный маршрут в зависимости от состояния аутентификации
      initialRoute: Provider.of<AuthProvider>(context).isAuthenticated
          ? '/home'
          : '/sign-in',
      routes: {
        '/sign-in': (context) => SignInScreen(),
        '/sign-up': (context) => SignUpScreen(),
        '/home': (context) => HomeScreen(),
        '/add': (context) => AddScreen(),
        '/profile': (context) => ProfileScreen(),
        '/ai-mentor': (context) => AIMentorScreen(),
      },
    );
  }
}
