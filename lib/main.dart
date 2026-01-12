import 'package:flutter/material.dart';
import 'package:neo_banking/presentation/screen/auth/authentication_screen.dart';
import 'package:neo_banking/presentation/screen/main/user_profile.dart';
import 'package:neo_banking/presentation/screen/main/home_screen.dart';
import 'package:neo_banking/presentation/screen/splash_screen.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Neo Banking',
      initialRoute: SplashScreen.routeName,
      onGenerateRoute: (settings) {
        switch (settings.name) {
          case SplashScreen.routeName:
            return MaterialPageRoute(builder: (_) => const SplashScreen());
          case AuthenticationScreen.routeName:
            return PageRouteBuilder(
              pageBuilder: (_, __, ___) => const AuthenticationScreen(),
              transitionDuration: const Duration(milliseconds: 400),
              transitionsBuilder: (_, animation, __, child) {
                return FadeTransition(opacity: animation, child: child);
              },
            );
          case HomeScreen.routeName:
            final args = settings.arguments;
            final id = args as int;
            return PageRouteBuilder(
              pageBuilder: (_, __, ___) => HomeScreen(id: id),
              transitionDuration: const Duration(milliseconds: 400),
              transitionsBuilder: (_, animation, __, child) {
                return FadeTransition(opacity: animation, child: child);
              },
            );
          case UserProfile.routeName:
            return MaterialPageRoute(builder: (_) => const UserProfile());
          default:
            return MaterialPageRoute(builder: (_) => const SplashScreen());
        }
      },
    );
  }
}
