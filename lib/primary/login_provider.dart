// Update your login_provider.dart file
import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:pmj_application/assets/custom%20widgets/transition.dart';
import 'package:pmj_application/primary/homePage.dart';
import 'package:flutter/foundation.dart';

import '../secondary/user_service.dart';

class LoginProvider extends ChangeNotifier {
  final emailController = TextEditingController();
  final passwordController = TextEditingController();
  final confirmPasswordController = TextEditingController();
  final nameController = TextEditingController();

  bool _isLoading = false;

  bool get isLoading => _isLoading;

  final FirebaseAuth _auth = FirebaseAuth.instance;
  final UserService _userService = UserService(); // Add user service
  static const Duration _networkTimeout = Duration(seconds: 12);

  String? validateEmail(String? value) {
    if (value == null || value.isEmpty) {
      return 'Please enter your email';
    }
    if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(value)) {
      return 'Please enter a valid email';
    }
    return null;
  }

  String? validatePassword(String? value) {
    if (value == null || value.isEmpty) {
      return 'Please enter your password';
    }
    if (value.length < 6) {
      return 'Password must be at least 6 characters';
    }
    return null;
  }

  String? validateConfirmPassword(String? value) {
    if (value == null || value.isEmpty) {
      return 'Please confirm your password';
    }
    if (value != passwordController.text) {
      return 'Passwords do not match';
    }
    return null;
  }

  String? validateName(String? value) {
    if (value == null || value.isEmpty) {
      return 'Please enter your name';
    }
    return null;
  }

  Future<void> login(BuildContext context) async {
    if (validateEmail(emailController.text) != null ||
        validatePassword(passwordController.text) != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please fix the errors')),
      );
      return;
    }

    try {
      _isLoading = true;
      notifyListeners();

      debugPrint('LoginProvider: Starting authentication process...');
      
      // Perform Firebase authentication without problematic operations
      final userCredential = await _auth
          .signInWithEmailAndPassword(
            email: emailController.text.trim(),
            password: passwordController.text.trim(),
          )
          .timeout(_networkTimeout);
      
      final user = userCredential.user;
      if (user == null) {
        throw Exception('Authentication succeeded but no user data received');
      }
      
      debugPrint('LoginProvider: Authentication successful for user: ${user.uid}');
      
      // Save login state with user data (avoiding problematic reload operations)
      await _userService.saveLoginState(true, user: user);
      debugPrint('LoginProvider: User session saved successfully');

      if (!context.mounted) return;
      
      // Set loading to false before navigation
      _isLoading = false;
      notifyListeners();
      
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Login successful'),
          backgroundColor: Colors.green,
          duration: Duration(seconds: 2),
        ),
      );

      debugPrint('LoginProvider: Navigating to home page...');
      
      // Navigate using post frame callback for UI stability
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (context.mounted) {
          Navigator.of(context, rootNavigator: true).pushNamedAndRemoveUntil(
            '/BottomNavBarExample',
            (route) => false,
          );
          debugPrint('LoginProvider: Navigation completed successfully');
        }
      });
      
    } on TimeoutException catch (e) {
      debugPrint('LoginProvider: Timeout exception: $e');
      _showErrorSnackBar(context, 'Login timed out. Please check your internet connection and try again.');
    } on SocketException catch (e) {
      debugPrint('LoginProvider: Socket exception: $e');
      _showErrorSnackBar(context, 'Network error. Please check your connection and try again.');
    } on FirebaseAuthException catch (e) {
      debugPrint('LoginProvider: Firebase auth exception - Code: ${e.code}, Message: ${e.message}');
      final errorMessage = _getFirebaseAuthErrorMessage(e.code);
      _showErrorSnackBar(context, errorMessage);
    } catch (e, stackTrace) {
      debugPrint('LoginProvider: Unexpected exception: $e');
      debugPrint('LoginProvider: Stack trace: $stackTrace');

      // Some versions of firebase_auth (Pigeon) may throw a decode/type error
      // even though the user is actually signed in. If auth state indicates a
      // valid user, treat this as success instead of failing the login.
      try {
        // Give Firebase a moment to finalize auth state
        await Future.delayed(const Duration(milliseconds: 200));
        final currentUser = _auth.currentUser;

        final looksLikePigeonDecodeIssue =
            e.toString().contains('PigeonUserDetails') ||
            e.toString().contains('PigeonUserCredential') ||
            e.toString().contains('StandardMessageCodec');

        if (currentUser != null && currentUser.uid.isNotEmpty && looksLikePigeonDecodeIssue) {
          debugPrint('LoginProvider: Detected Pigeon decode error but user is signed in. Proceeding as success.');

          // Persist session and navigate
          await _userService.saveLoginState(true, user: currentUser);

          if (!context.mounted) return;

          _isLoading = false;
          notifyListeners();

          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Login successful'),
              backgroundColor: Colors.green,
              duration: Duration(seconds: 2),
            ),
          );

          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (context.mounted) {
              Navigator.of(context, rootNavigator: true).pushNamedAndRemoveUntil(
                '/BottomNavBarExample',
                (route) => false,
              );
              debugPrint('LoginProvider: Navigation completed (fallback success)');
            }
          });
          return; // Exit early – handled as success
        }
      } catch (fallbackHandleError) {
        debugPrint('LoginProvider: Error during fallback success handling: $fallbackHandleError');
      }

      // If we reach here, it was a real failure – show message and clean up
      _showErrorSnackBar(context, 'Login failed due to an unexpected error. Please try again.');

      try {
        await _userService.clearUserData();
        debugPrint('LoginProvider: Cleared user data after error');
      } catch (clearError) {
        debugPrint('LoginProvider: Error clearing user data: $clearError');
      }
    } finally {
      if (_isLoading) {
        _isLoading = false;
        notifyListeners();
      }
    }
  }

  // Helper method to show error snackbars
  void _showErrorSnackBar(BuildContext context, String message) {
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor: Colors.red,
          duration: const Duration(seconds: 4),
        ),
      );
    }
  }

  // Helper method to get user-friendly Firebase Auth error messages
  String _getFirebaseAuthErrorMessage(String errorCode) {
    switch (errorCode) {
      case 'user-not-found':
        return 'No account found for this email.';
      case 'wrong-password':
        return 'Incorrect password. Please try again.';
      case 'invalid-email':
        return 'Invalid email format.';
      case 'user-disabled':
        return 'This account has been disabled.';
      case 'too-many-requests':
        return 'Too many attempts. Please wait a moment and try again.';
      case 'network-request-failed':
        return 'Unable to reach the server. Please check your connection and try again.';
      case 'invalid-credential':
        return 'Invalid login credentials. Please check your email and password.';
      case 'operation-not-allowed':
        return 'Email/password sign-in is not enabled. Please contact support.';
      default:
        return 'Sign-in failed. Please try again.';
    }
  }

  Future<void> signup(BuildContext context) async {
    if (validateEmail(emailController.text) != null ||
        validatePassword(passwordController.text) != null ||
        validateConfirmPassword(confirmPasswordController.text) != null ||
        validateName(nameController.text) != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please fix the errors')),
      );
      return;
    }

    try {
      _isLoading = true;
      notifyListeners();

      UserCredential userCredential = await _auth
          .createUserWithEmailAndPassword(
            email: emailController.text.trim(),
            password: passwordController.text.trim(),
          )
          .timeout(_networkTimeout);

      // Update user profile with name
      await userCredential.user?.updateDisplayName(nameController.text.trim());

      // Save login state with user data
      await _userService.saveLoginState(true, user: userCredential.user);

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Signup successful')),
      );

      // Navigate to home screen and clear back stack on next frame using root navigator
      if (!context.mounted) return;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!context.mounted) return;
        Navigator.of(context, rootNavigator: true).pushNamedAndRemoveUntil(
          '/BottomNavBarExample',
          (route) => false,
        );
      });
    } on TimeoutException {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Signup timed out. Please check your internet connection and try again.'),
          backgroundColor: Colors.red,
        ),
      );
    } on SocketException {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Network error. Please check your connection and try again.'),
          backgroundColor: Colors.red,
        ),
      );
    } on FirebaseAuthException catch (e) {
      String errorMessage;
      switch (e.code) {
        case 'email-already-in-use':
          errorMessage = 'This email is already registered.';
          break;
        case 'invalid-email':
          errorMessage = 'Invalid email format.';
          break;
        case 'weak-password':
          errorMessage = 'Password is too weak.';
          break;
        case 'operation-not-allowed':
          errorMessage = 'Signup is currently unavailable. Please contact support.';
          break;
        case 'network-request-failed':
          errorMessage = 'Unable to reach the server. Please check your connection and try again.';
          break;
        default:
          errorMessage = 'Signup failed. Please try again.';
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(errorMessage),
          backgroundColor: Colors.red,
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('An unexpected error occurred. Please try again.'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  @override
  void dispose() {
    emailController.dispose();
    passwordController.dispose();
    confirmPasswordController.dispose();
    nameController.dispose();
    super.dispose();
  }
}