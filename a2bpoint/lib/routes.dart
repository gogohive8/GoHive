import 'package:flutter/material.dart';
import 'screens/Auth/sign_in_screen.dart';

class Routes {
  static const String signIn = '/sign-in';

  static Route<dynamic> generateRoute(RouteSettings settings) {
    switch (settings.name) {
      case signIn:
        return MaterialPageRoute(builder: (_) => const SignInScreen());
      default:
        return MaterialPageRoute(builder: (_) => const SignInScreen());
    }
  }
}
