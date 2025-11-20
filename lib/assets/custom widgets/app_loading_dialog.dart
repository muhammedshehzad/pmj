import 'package:flutter/material.dart';

/// Minimal app-themed loading dialog.
/// Usage: call `showAppLoadingDialog(context, message: 'Recording payment...');`
/// Make sure to dismiss with `Navigator.of(context, rootNavigator: true).pop();`
void showAppLoadingDialog(BuildContext context, {String message = 'Please wait...'}) {
  showDialog(
    context: context,
    barrierDismissible: false,
    builder: (ctx) {
      return AlertDialog(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        content: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(
              height: 22,
              width: 22,
              child: CircularProgressIndicator(
                strokeWidth: 2.4,
                valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF1BA3A1)),
              ),
            ),
            const SizedBox(width: 12),
            Flexible(
              child: Text(
                message,
                style: const TextStyle(
                  fontFamily: 'Inter',
                  fontWeight: FontWeight.w400,
                  fontSize: 12,
                  color: Color(0xFF0B190C),
                ),
              ),
            ),
          ],
        ),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      );
    },
  );
}
