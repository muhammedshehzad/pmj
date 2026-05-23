import 'package:firebase_auth/firebase_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/foundation.dart';
import 'dart:async';

class UserService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  static const String _loginStateKey = 'pmj_user_login_state_v2';
  static const String _userEmailKey = 'pmj_user_email_v2';
  static const String _userUidKey = 'pmj_user_uid_v2';
  static const String _userRoleKey = 'pmj_user_role_v2';
  
  // Singleton pattern for better resource management
  static final UserService _instance = UserService._internal();
  factory UserService() => _instance;
  UserService._internal();

  // Check if user is logged in with comprehensive validation
  Future<bool> isLoggedIn() async {
    try {
      // Primary check: Firebase Auth current user (without reload)
      User? currentUser = _auth.currentUser;
      
      if (currentUser != null) {
        // Validate user session is still active by checking basic properties
        if (currentUser.uid.isNotEmpty && currentUser.email != null) {
          // Sync local state with Firebase state
          await _syncUserDataToLocal(currentUser);
          return true;
        }
      }

      // Secondary check: Local storage validation
      final localLoginState = await _safeGetLoginState();
      if (localLoginState) {
        // Validate local data integrity
        final localEmail = await _getStoredEmail();
        final localUid = await _getStoredUid();
        
        if (localEmail != null && localUid != null) {
          // Check if Firebase user matches local data
          if (currentUser != null && 
              currentUser.email == localEmail && 
              currentUser.uid == localUid) {
            return true;
          } else {
            // Mismatch detected, clear local state
            await clearUserData();
            return false;
          }
        }
      }

      return false;
    } catch (e) {
      debugPrint('UserService: Error checking login state: $e');
      return false;
    }
  }

  // Sync Firebase user data to local storage
  Future<void> _syncUserDataToLocal(User user) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await Future.wait([
        prefs.setBool(_loginStateKey, true),
        prefs.setString(_userEmailKey, user.email ?? ''),
        prefs.setString(_userUidKey, user.uid),
      ]);
      debugPrint('UserService: User data synced to local storage');
    } catch (e) {
      debugPrint('UserService: Error syncing user data: $e');
    }
  }

  // Sync role to local storage
  Future<void> syncRoleToLocal(String role) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_userRoleKey, role);
      debugPrint('UserService: Role $role synced to local storage');
    } catch (e) {
      debugPrint('UserService: Error syncing role: $e');
    }
  }

  // Get stored role
  Future<String?> getStoredRole() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getString(_userRoleKey);
    } catch (e) {
      debugPrint('UserService: Error getting stored role: $e');
      return null;
    }
  }

  // Safe method to get login state from SharedPreferences
  Future<bool> _safeGetLoginState() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getBool(_loginStateKey) ?? false;
    } catch (e) {
      debugPrint('UserService: Error getting login state: $e');
      return false;
    }
  }

  // Safe method to set login state in SharedPreferences
  Future<void> _safeSetLoginState(bool isLoggedIn) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_loginStateKey, isLoggedIn);
      debugPrint('UserService: Login state saved: $isLoggedIn');
    } catch (e) {
      debugPrint('UserService: Error saving login state: $e');
    }
  }

  // Get stored email
  Future<String?> _getStoredEmail() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getString(_userEmailKey);
    } catch (e) {
      debugPrint('UserService: Error getting stored email: $e');
      return null;
    }
  }

  // Get stored UID
  Future<String?> _getStoredUid() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getString(_userUidKey);
    } catch (e) {
      debugPrint('UserService: Error getting stored UID: $e');
      return null;
    }
  }

  // Save login state with user data
  Future<void> saveLoginState(bool isLoggedIn, {User? user}) async {
    if (isLoggedIn && user != null) {
      await _syncUserDataToLocal(user);
    } else {
      await _safeSetLoginState(isLoggedIn);
    }
  }

  // Get current user safely without problematic operations
  User? getCurrentUser() {
    try {
      return _auth.currentUser;
    } catch (e) {
      debugPrint('UserService: Error getting current user: $e');
      return null;
    }
  }

  // Validate current user session
  Future<bool> validateUserSession() async {
    try {
      final currentUser = _auth.currentUser;
      if (currentUser == null) return false;
      
      // Basic validation without calling reload()
      return currentUser.uid.isNotEmpty && currentUser.email != null;
    } catch (e) {
      debugPrint('UserService: Error validating user session: $e');
      return false;
    }
  }

  // Sign out with comprehensive cleanup
  Future<void> signOut() async {
    try {
      // Clear local data first
      await clearUserData();
      
      // Then sign out from Firebase
      await _auth.signOut();
      
      debugPrint('UserService: User signed out successfully');
    } catch (e) {
      debugPrint('UserService: Error during sign out: $e');
      // Ensure local state is cleared even if Firebase signOut fails
      await clearUserData();
      rethrow;
    }
  }

  // Clear all user data comprehensively
  Future<void> clearUserData() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await Future.wait([
        prefs.remove(_loginStateKey),
        prefs.remove(_userEmailKey),
        prefs.remove(_userUidKey),
        prefs.remove(_userRoleKey),
      ]);
      debugPrint('UserService: All user data cleared');
    } catch (e) {
      debugPrint('UserService: Error clearing user data: $e');
    }
  }

  // Get user info safely
  Future<Map<String, String?>> getUserInfo() async {
    try {
      final currentUser = _auth.currentUser;
      if (currentUser != null) {
        return {
          'uid': currentUser.uid,
          'email': currentUser.email,
          'displayName': currentUser.displayName,
        };
      }
      
      // Fallback to stored data
      return {
        'uid': await _getStoredUid(),
        'email': await _getStoredEmail(),
        'displayName': null,
      };
    } catch (e) {
      debugPrint('UserService: Error getting user info: $e');
      return {'uid': null, 'email': null, 'displayName': null};
    }
  }
}