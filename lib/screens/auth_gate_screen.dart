import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import 'main_screen.dart';
import 'onboarding_screen.dart';

class AuthGateScreen extends StatelessWidget {
  static const routeName = '/auth-gate';

  const AuthGateScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);

    // You might want to use a FutureBuilder or StreamBuilder here
    // if your authProvider.tryAutoLogin() or similar returns a Future/Stream.
    // For this example, assuming authProvider updates isAuthenticated synchronously
    // after checking stored credentials or Firebase auth state.

    // A common pattern is to use StreamBuilder with FirebaseAuth.instance.authStateChanges()
    // within the AuthProvider to update isAuthenticated.

    if (authProvider.isAuthenticated) {
      return MainScreen();
    } else {
      // If you have a separate login screen, navigate there.
      // Otherwise, OnboardingScreen might handle both registration and login.
      return OnboardingScreen();
    }
  }
}