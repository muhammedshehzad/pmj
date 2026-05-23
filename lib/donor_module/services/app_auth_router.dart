import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:pmj_application/secondary/user_service.dart';
import 'donor_auth_service.dart';

/// Result of [AppAuthRouter.determineRoute] — both the route to push and the
/// effective role for the [Permissions] provider, plus an optional message
/// (e.g. "Awaiting admin approval").
class AppAuthResult {
  final String route;
  final String role; // 'admin' | 'collector' | 'donor' | 'none'
  final String? message;

  AppAuthResult({required this.route, required this.role, this.message});
}

/// Determines where to send the user on app start, based on their auth state
/// and the `donorUsers/{uid}` doc (role + approval status).
class AppAuthRouter {
  final DonorAuthService _donorAuthService = DonorAuthService();
  final UserService _userService = UserService();

  Future<AppAuthResult> determineRoute() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        return AppAuthResult(route: '/login', role: 'none');
      }

      // Try to read role + status from Firestore
      String? role;
      String status = 'approved'; // back-compat default for missing field
      try {
        final donorUser = await _donorAuthService.getDonorUser(user.uid);
        if (donorUser != null) {
          role = donorUser.role;
          status = donorUser.status;
        } else {
          // No record yet — back-compat: legacy admin accounts created before
          // we tracked donorUsers. Treat as admin/approved.
          role = 'admin';
        }
        await _userService.syncRoleToLocal(role);
      } catch (firestoreError) {
        debugPrint('Firestore unreachable, falling back to local cache: $firestoreError');
        role = await _userService.getStoredRole();
        if (role == null) {
          // Offline + never seen → assume admin (legacy users)
          role = 'admin';
        }
      }

      // Approval gate — block pending/rejected users from reaching the app.
      if (status == 'pending') {
        await FirebaseAuth.instance.signOut();
        return AppAuthResult(
          route: '/login',
          role: 'none',
          message: 'Your account is awaiting admin approval.',
        );
      }
      if (status == 'rejected') {
        await FirebaseAuth.instance.signOut();
        return AppAuthResult(
          route: '/login',
          role: 'none',
          message: 'Your account request was rejected. Contact an admin.',
        );
      }

      switch (role) {
        case 'admin':
        case 'collector':
          return AppAuthResult(route: '/BottomNavBarExample', role: role!);
        case 'donor':
          return AppAuthResult(route: '/donor/dashboard', role: 'donor');
        default:
          // Unknown role → safest fallback
          return AppAuthResult(route: '/BottomNavBarExample', role: 'admin');
      }
    } catch (e) {
      debugPrint('Error determining route: $e');
      if (FirebaseAuth.instance.currentUser == null) {
        return AppAuthResult(route: '/login', role: 'none');
      }
      return AppAuthResult(route: '/BottomNavBarExample', role: 'admin');
    }
  }
}
