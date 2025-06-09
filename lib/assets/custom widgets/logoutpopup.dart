import 'package:flutter/material.dart';
import 'package:pmj_application/assets/custom%20widgets/transition.dart';
import 'package:pmj_application/primary/login.dart';
import 'package:pmj_application/secondary/user_service.dart';

Future<bool> showLogoutConfirmation(BuildContext context) async {
  return await showDialog<bool>(
    context: context,
    builder: (BuildContext dialogContext) {
      return AlertDialog(
        content: const Text(
          'Are you sure you want to log out?',
          style: TextStyle(
            fontFamily: "Inter",
            fontWeight: FontWeight.w400,
            fontSize: 12,
          ),
        ),
        actions: <Widget>[
          Container(
            height: 26,
            width: 80,
            margin: const EdgeInsets.only(right: 4, bottom: 4),
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                foregroundColor: Colors.white,
                backgroundColor: const Color(0xff29B6F6),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(4),
                ),
                elevation: 0,
              ),
              child: const Text(
                'Cancel',
                style: TextStyle(
                  fontFamily: "Inter",
                  fontWeight: FontWeight.w600,
                  fontSize: 9,
                ),
              ),
              onPressed: () {
                Navigator.of(dialogContext).pop(false);
              },
            ),
          ),
          Container(
            height: 26,
            width: 80,
            margin: const EdgeInsets.only(right: 4, bottom: 4),
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                foregroundColor: Colors.white,
                backgroundColor: const Color(0xffF44336),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(4),
                ),
                elevation: 0,
              ),
              child: const Text(
                'Logout',
                style: TextStyle(
                  fontFamily: "Inter",
                  fontWeight: FontWeight.w600,
                  fontSize: 9,
                ),
              ),
              onPressed: () {
                _performLogout;
                Navigator.of(dialogContext).pop(true);
              },
            ),
          ),
        ],
      );
    },
  ) ??
      false;
}
void _performLogout(BuildContext context) async {
  final userService = UserService();
  try {
    await userService.signOut();
    print('Logout completed: Firebase signed out, preferences cleared');
  } catch (e) {
    print('Error during logout: $e');
  }

  // Navigate to AuthScreens and remove all previous routes
  Navigator.pushAndRemoveUntil(
    context,
    SlidingPageTransitionLR(page: AuthScreens()),
        (Route<dynamic> route) => false, // Remove all routes
  );
}