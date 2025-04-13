// Create a new file: lib/services/user_service.dart
import 'package:firebase_auth/firebase_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';

class UserService {
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // Check if user is logged in
  Future<bool> isLoggedIn() async {
    // First check Firebase Auth state
    User? currentUser = _auth.currentUser;

    if (currentUser != null) {
      return true;
    }

    // If Firebase says not logged in, check shared preferences as fallback
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool('isLoggedIn') ?? false;
  }

  // Save login state
  Future<void> saveLoginState(bool isLoggedIn) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('isLoggedIn', isLoggedIn);
  }

  // Get current user
  User? getCurrentUser() {
    return _auth.currentUser;
  }

  // Sign out
  Future<void> signOut() async {
    await _auth.signOut();
    await saveLoginState(false);
  }
}