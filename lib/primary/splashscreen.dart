import 'package:flutter/material.dart';


class splashscreen extends StatefulWidget {
  const splashscreen({super.key});

  @override
  State<splashscreen> createState() => _HomeState();
}

class _HomeState extends State<splashscreen> {
  @override
  void initState() {
    super.initState();
    _navigateToMainPage();
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
