import 'package:flutter/material.dart';
import 'package:pmj_application/assets/custom%20widgets/transition.dart';
import 'package:pmj_application/primary/login.dart';
import 'package:pmj_application/secondary/user_service.dart';
import 'package:pmj_application/services/local_database_service.dart';

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
            fontSize: 14,
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
              onPressed: () async {
                await _performLogout(dialogContext);
              },
            ),
          ),
        ],
      );
    },
  ) ??
      false;
}

Future<void> _performLogout(BuildContext context) async {
  final userService = UserService();
  try {
    // 1) Sign out from Firebase and clear login flag
    await userService.signOut();

    // 2) Clear all local data (Isar DB + image cache)
    await LocalDatabaseService().clearAllData();

    // 3) Optionally clear Flutter's in-memory image cache
    // ignore: invalid_use_of_visible_for_testing_member, invalid_use_of_protected_member
    PaintingBinding.instance.imageCache.clear();

    print('Logout completed: Firebase signed out, preferences cleared, local data cleared');
  } catch (e) {
    print('Error during logout: $e');
  }

  // Navigate to AuthScreens and remove all previous routes
  if (!context.mounted) return;
  Navigator.of(context, rootNavigator: true).pushNamedAndRemoveUntil(
    '/login',
    (Route<dynamic> route) => false,
  );
}