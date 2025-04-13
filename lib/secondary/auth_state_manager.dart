// Create a new file: lib/services/auth_state_manager.dart
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:pmj_application/secondary/user_service.dart';

class AuthStateManager {
  final UserService _userService = UserService();
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // Set up auth state listener
  void initAuthStateListener(BuildContext context) {
    _auth.authStateChanges().listen((User? user) {
      if (user == null) {
        // User is signed out, update shared preferences
        _userService.saveLoginState(false);
      } else {
        // User is signed in, update shared preferences
        _userService.saveLoginState(true);
      }
    });
  }

  // Check auth state and redirect accordingly
  Future<String> checkAuthState() async {
    bool isLoggedIn = await _userService.isLoggedIn();

    if (isLoggedIn) {
      return '/BottomNavBarExample'; // User is logged in, go to home
    } else {
      return '/login'; // User is not logged in, go to login
    }
  }
}