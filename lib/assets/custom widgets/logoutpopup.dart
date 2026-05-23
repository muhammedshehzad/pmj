import 'package:flutter/material.dart';
import 'package:pmj_application/assets/custom%20widgets/transition.dart';
import 'package:pmj_application/primary/login.dart';
import 'package:pmj_application/secondary/user_service.dart';
import 'package:pmj_application/services/local_database_service.dart';
import 'package:pmj_application/services/permission_service.dart';
import 'package:provider/provider.dart';

Future<bool> showLogoutConfirmation(BuildContext context) async {
  return await showDialog<bool>(
    context: context,
    barrierDismissible: false,
    builder: (BuildContext dialogContext) {
      return AlertDialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        contentPadding: const EdgeInsets.fromLTRB(24, 20, 24, 0),
        actionsPadding: const EdgeInsets.fromLTRB(24, 16, 24, 20),
        title: const Text(
          'Logout?',
          textAlign: TextAlign.start,
          style: TextStyle(
            fontFamily: "Inter",
            fontSize: 20,
            fontWeight: FontWeight.w600,
            color: Color(0xFF212121),
            height: 1.3,
          ),
        ),
        content: const Text(
          'Are you sure you want to log out? You will need to sign in again to access your account.',
          textAlign: TextAlign.start,
          style: TextStyle(
            fontFamily: "Inter",
            fontWeight: FontWeight.w400,
            fontSize: 14,
            color: Color(0xFF757575),
            height: 1.5,
          ),
        ),
        actions: [
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    side: const BorderSide(
                      color: Color(0xFFE0E0E0),
                      width: 1.5,
                    ),
                    foregroundColor: const Color(0xFF616161),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  onPressed: () {
                    Navigator.of(dialogContext).pop(false);
                  },
                  child: const Text(
                    'Cancel',
                    style: TextStyle(
                      fontFamily: "Inter",
                      fontWeight: FontWeight.w600,
                      fontSize: 14,
                      letterSpacing: 0.2,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    backgroundColor: const Color(0xFFD32F2F),
                    foregroundColor: Colors.white,
                    elevation: 0,
                    shadowColor: Colors.transparent,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  onPressed: () async {
                    await _performLogout(dialogContext);
                  },
                  child: const Text(
                    'Logout',
                    style: TextStyle(
                      fontFamily: "Inter",
                      fontWeight: FontWeight.w600,
                      fontSize: 14,
                      letterSpacing: 0.2,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      );
    },
  ) ??
      false;
}

Future<void> _performLogout(BuildContext context) async {
  final userService = UserService();
  // Capture the Permissions provider before navigation tears the tree.
  Permissions? perms;
  try {
    perms = Provider.of<Permissions>(context, listen: false);
  } catch (_) {/* not provided in this context — fine */}

  try {
    await userService.signOut();
    await LocalDatabaseService().clearAllData();
    perms?.clear();

    // ignore: invalid_use_of_visible_for_testing_member, invalid_use_of_protected_member
    PaintingBinding.instance.imageCache.clear();
  } catch (e) {
    debugPrint('Error during logout: $e');
  }

  if (!context.mounted) return;
  Navigator.of(context, rootNavigator: true).pushNamedAndRemoveUntil(
    '/login',
    (Route<dynamic> route) => false,
  );
}