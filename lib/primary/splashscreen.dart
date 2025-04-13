import 'package:flutter/material.dart';

import '../secondary/auth_state_manager.dart';


class splashscreen extends StatefulWidget {
  const splashscreen({super.key});

  @override
  State<splashscreen> createState() => _HomeState();
}

class _HomeState extends State<splashscreen> {
  final AuthStateManager _authStateManager = AuthStateManager();

  @override
  void initState() {
    super.initState();
    _navigateToMainPage();
    _checkAuthAndNavigate();

  }
  Future<void> _checkAuthAndNavigate() async {
    // Initialize auth listener
    _authStateManager.initAuthStateListener(context);

    // Wait for splash animation or delay
    await Future.delayed(const Duration(seconds: 2));

    // Check auth state and get route
    String route = await _authStateManager.checkAuthState();

    // Navigate to appropriate route
    if (mounted) {
      Navigator.pushReplacementNamed(context, route);
    }
  }


  Future<void> _navigateToMainPage() async {
    await Future.delayed(Duration(seconds: 2));
    Navigator.pushReplacementNamed(context, '/login');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color(0xFFFFFFFF),
      body: Center(
        child: Hero(
          tag: 'hero-tag',
          flightShuttleBuilder: (flightContext, animation, direction,
              fromHeroContext, toHeroContext) {
            return FadeTransition(
              opacity: animation,
              child: fromHeroContext.widget,
            );
          },
          child: SizedBox(
            height: 327,
            width: 128,
            child: Image.asset('lib/assets/images/PMJ Logo.png'),
          ),
        ),
      ),
    );
  }
}
