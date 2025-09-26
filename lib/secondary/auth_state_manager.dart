import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:pmj_application/secondary/user_service.dart';
import 'dart:async';

class AuthStateManager {
  final UserService _userService = UserService();
  final FirebaseAuth _auth = FirebaseAuth.instance;
  StreamSubscription<User?>? _authStateSubscription;

  // Set up auth state listener with enhanced error handling
  void initAuthStateListener(BuildContext context) {
    _authStateSubscription?.cancel(); // Cancel any existing subscription
    
    _authStateSubscription = _auth.authStateChanges().listen(
      (User? user) async {
        try {
          if (user == null) {
            debugPrint('AuthStateManager: User signed out');
            await _userService.saveLoginState(false);
          } else {
            debugPrint('AuthStateManager: User signed in (${user.uid})');
            await _userService.saveLoginState(true, user: user);
          }
        } catch (e) {
          debugPrint('AuthStateManager: Error in auth state listener: $e');
        }
      },
      onError: (error) {
        debugPrint('AuthStateManager: Auth state stream error: $error');
      },
    );
  }

  // Clean up resources
  void dispose() {
    _authStateSubscription?.cancel();
  }

  // Check auth state and redirect accordingly (without problematic operations)
  Future<String> checkAuthState() async {
    try {
      // Primary check: Firebase Auth current user (no reload)
      User? currentUser = _auth.currentUser;
      
      if (currentUser != null && currentUser.uid.isNotEmpty) {
        debugPrint('AuthStateManager: Firebase user found: ${currentUser.uid}');
        // Sync user data to local storage
        await _userService.saveLoginState(true, user: currentUser);
        return '/BottomNavBarExample';
      }
      
      // Secondary check: UserService comprehensive validation
      bool isLoggedIn = await _userService.isLoggedIn();
      debugPrint('AuthStateManager: UserService login state: $isLoggedIn');

      if (isLoggedIn) {
        // Validate user session without problematic reload
        bool sessionValid = await _userService.validateUserSession();
        if (sessionValid) {
          debugPrint('AuthStateManager: User session validated successfully');
          return '/BottomNavBarExample';
        } else {
          debugPrint('AuthStateManager: User session invalid, clearing state');
          await _userService.clearUserData();
          return '/login';
        }
      }
      
      debugPrint('AuthStateManager: No valid user session found');
      return '/login';
    } catch (e) {
      debugPrint('AuthStateManager: Error checking auth state: $e');
      // Clear potentially corrupted state and default to login
      try {
        await _userService.clearUserData();
      } catch (clearError) {
        debugPrint('AuthStateManager: Error clearing user data: $clearError');
      }
      return '/login';
    }
  }

  // Validate and sync auth state without problematic operations
  Future<bool> validateAndSyncAuthState() async {
    try {
      User? currentUser = _auth.currentUser;
      
      if (currentUser != null && currentUser.uid.isNotEmpty) {
        // User exists, sync to local storage
        await _userService.saveLoginState(true, user: currentUser);
        debugPrint('AuthStateManager: Auth state synced successfully');
        return true;
      } else {
        // No user, clear local state
        await _userService.saveLoginState(false);
        debugPrint('AuthStateManager: No user found, cleared local state');
        return false;
      }
    } catch (e) {
      debugPrint('AuthStateManager: Error validating auth state: $e');
      return false;
    }
  }

  // Get current user info safely
  Future<Map<String, String?>> getCurrentUserInfo() async {
    try {
      return await _userService.getUserInfo();
    } catch (e) {
      debugPrint('AuthStateManager: Error getting user info: $e');
      return {'uid': null, 'email': null, 'displayName': null};
    }
  }

  // Sign out user completely
  Future<void> signOut() async {
    try {
      await _userService.signOut();
      debugPrint('AuthStateManager: User signed out successfully');
    } catch (e) {
      debugPrint('AuthStateManager: Error during sign out: $e');
      rethrow;
    }
  }
}