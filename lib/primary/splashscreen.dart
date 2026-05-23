import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../donor_module/services/app_auth_router.dart';
import '../services/permission_service.dart';


class splashscreen extends StatefulWidget {
  const splashscreen({super.key});

  @override
  State<splashscreen> createState() => _HomeState();
}

class _HomeState extends State<splashscreen> {
  final AppAuthRouter _authRouter = AppAuthRouter();

  @override
  void initState() {
    super.initState();
    _checkAuthAndNavigate();
  }

  Future<void> _checkAuthAndNavigate() async {
    await Future.delayed(const Duration(seconds: 2));

    final result = await _authRouter.determineRoute();

    if (!mounted) return;

    // Set permissions before navigating so the destination has correct role,
    // then bind to the live Firestore doc so future role changes take effect
    // without requiring re-login.
    final perms = context.read<Permissions>();
    perms.setRole(result.role);
    if (result.role != 'none') {
      perms.bindToCurrentUser();
    }

    Navigator.pushReplacementNamed(context, result.route);

    if (result.message != null) {
      // Show after navigation completes — give the new route a frame to mount.
      WidgetsBinding.instance.addPostFrameCallback((_) {
        final ctx = Navigator.of(context, rootNavigator: true).context;
        ScaffoldMessenger.of(ctx).showSnackBar(
          SnackBar(
            content: Text(result.message!),
            backgroundColor: Colors.orange,
            duration: const Duration(seconds: 5),
          ),
        );
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
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
