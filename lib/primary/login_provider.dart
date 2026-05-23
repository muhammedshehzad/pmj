import 'dart:async';
import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../secondary/user_service.dart';
import '../services/permission_service.dart';

/// Login + Signup provider. Sign-up creates a Firebase Auth account and a
/// `donorUsers/{uid}` doc with `status: 'pending'`. The user is then signed
/// out — they can't enter the app until an admin approves them via the
/// "Manage Users" screen.
class LoginProvider extends ChangeNotifier {
  final emailController = TextEditingController();
  final passwordController = TextEditingController();
  final confirmPasswordController = TextEditingController();
  final nameController = TextEditingController();

  /// What role the user requested at signup ('admin' or 'collector').
  /// Donor signups go through the (currently disabled) donor login flow.
  String requestedRole = 'collector';

  bool _isLoading = false;
  bool get isLoading => _isLoading;

  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final UserService _userService = UserService();
  static const Duration _networkTimeout = Duration(seconds: 12);

  // ── Validation ─────────────────────────────────────────────────────────
  String? validateEmail(String? value) {
    if (value == null || value.isEmpty) return 'Please enter your email';
    if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(value)) {
      return 'Please enter a valid email';
    }
    return null;
  }

  String? validatePassword(String? value) {
    if (value == null || value.isEmpty) return 'Please enter your password';
    if (value.length < 6) return 'Password must be at least 6 characters';
    return null;
  }

  String? validateConfirmPassword(String? value) {
    if (value == null || value.isEmpty) return 'Please confirm your password';
    if (value != passwordController.text) return 'Passwords do not match';
    return null;
  }

  String? validateName(String? value) {
    if (value == null || value.isEmpty) return 'Please enter your name';
    return null;
  }

  void setRequestedRole(String role) {
    requestedRole = role;
    notifyListeners();
  }

  // ── Login ──────────────────────────────────────────────────────────────
  Future<void> login(BuildContext context) async {
    if (validateEmail(emailController.text) != null ||
        validatePassword(passwordController.text) != null) {
      _showErrorSnackBar(context, 'Please fix the errors');
      return;
    }

    try {
      _isLoading = true;
      notifyListeners();

      User? user;
      try {
        final userCredential = await _auth
            .signInWithEmailAndPassword(
              email: emailController.text.trim(),
              password: passwordController.text.trim(),
            )
            .timeout(_networkTimeout);
        user = userCredential.user;
      } catch (signInErr) {
        // Some firebase_auth versions throw a Pigeon decode error even when
        // the user is actually signed in. Detect that and proceed with
        // currentUser so the post-auth flow (status check, role) still runs.
        final looksLikePigeon =
            signInErr.toString().contains('PigeonUserDetails') ||
                signInErr.toString().contains('PigeonUserCredential') ||
                signInErr.toString().contains('StandardMessageCodec');
        if (!looksLikePigeon) rethrow;
        await Future.delayed(const Duration(milliseconds: 200));
        user = _auth.currentUser;
        if (user == null) rethrow;
      }

      if (user == null) throw Exception('No user data after authentication');

      await _completePostAuth(context, user);
    } on TimeoutException {
      _showErrorSnackBar(
          context, 'Login timed out. Check your internet connection.');
    } on SocketException {
      _showErrorSnackBar(context, 'Network error. Check your connection.');
    } on FirebaseAuthException catch (e) {
      _showErrorSnackBar(context, _firebaseAuthMessage(e.code));
    } catch (e) {
      debugPrint('Login error: $e');
      _showErrorSnackBar(context, 'Login failed. Please try again.');
    } finally {
      if (_isLoading) {
        _isLoading = false;
        notifyListeners();
      }
    }
  }

  /// Runs the post-authentication flow shared by the normal sign-in path and
  /// the Pigeon-bug recovery path. Reads role + status, gates non-approved
  /// users, then sets Permissions and navigates.
  Future<void> _completePostAuth(BuildContext context, User user) async {
    final doc = await _firestore.collection('donorUsers').doc(user.uid).get();
    String role;
    String status;
    if (doc.exists) {
      final data = doc.data()!;
      role = (data['role'] as String?) ?? 'donor';
      status = (data['status'] as String?) ?? 'approved';
    } else {
      // Legacy admin accounts created before donorUsers tracking
      role = 'admin';
      status = 'approved';
    }

    if (status == 'pending') {
      await _auth.signOut();
      if (!context.mounted) return;
      _showErrorSnackBar(
        context,
        'Your account is awaiting admin approval. Please try again later.',
      );
      return;
    }
    if (status == 'rejected') {
      await _auth.signOut();
      if (!context.mounted) return;
      _showErrorSnackBar(
        context,
        'Your account request was rejected. Contact an admin.',
      );
      return;
    }

    await _userService.saveLoginState(true, user: user);
    await _userService.syncRoleToLocal(role);
    _firestore.collection('donorUsers').doc(user.uid).set(
      {'lastLogin': Timestamp.fromDate(DateTime.now())},
      SetOptions(merge: true),
    ).catchError((_) {});

    if (!context.mounted) return;

    final perms = context.read<Permissions>();
    perms.setRole(role);
    perms.bindToCurrentUser();

    _isLoading = false;
    notifyListeners();

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Login successful'),
        backgroundColor: Colors.green,
        duration: Duration(seconds: 2),
      ),
    );

    final destination =
        role == 'donor' ? '/donor/dashboard' : '/BottomNavBarExample';

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (context.mounted) {
        Navigator.of(context, rootNavigator: true)
            .pushNamedAndRemoveUntil(destination, (route) => false);
      }
    });
  }

  // ── Sign Up ────────────────────────────────────────────────────────────
  Future<void> signup(BuildContext context) async {
    if (validateEmail(emailController.text) != null ||
        validatePassword(passwordController.text) != null ||
        validateConfirmPassword(confirmPasswordController.text) != null ||
        validateName(nameController.text) != null) {
      _showErrorSnackBar(context, 'Please fix the errors');
      return;
    }

    try {
      _isLoading = true;
      notifyListeners();

      final userCredential = await _auth
          .createUserWithEmailAndPassword(
            email: emailController.text.trim(),
            password: passwordController.text.trim(),
          )
          .timeout(_networkTimeout);

      final user = userCredential.user;
      if (user == null) throw Exception('No user data after sign-up');

      await user.updateDisplayName(nameController.text.trim());

      // Create the pending donorUsers record. Role stays 'donor' (lowest
      // privilege) until admin approves and assigns the actual role.
      await _firestore.collection('donorUsers').doc(user.uid).set({
        'email': user.email,
        'name': nameController.text.trim(),
        'role': 'donor',
        'status': 'pending',
        'requestedRole': requestedRole,
        'phoneNumber': '',
        'donorId': '',
        'preferences': {
          'smsNotifications': true,
          'whatsappNotifications': true,
          'emailNotifications': false,
          'pushNotifications': true,
        },
        'createdAt': FieldValue.serverTimestamp(),
        'lastLogin': FieldValue.serverTimestamp(),
      });

      // Sign out immediately — user can't enter the app until approved.
      await _auth.signOut();

      if (!context.mounted) return;
      _isLoading = false;
      notifyListeners();

      // Clear sensitive fields
      passwordController.clear();
      confirmPasswordController.clear();

      _showApprovalPendingDialog(context);
    } on TimeoutException {
      _showErrorSnackBar(
          context, 'Sign-up timed out. Check your internet connection.');
    } on SocketException {
      _showErrorSnackBar(context, 'Network error. Check your connection.');
    } on FirebaseAuthException catch (e) {
      _showErrorSnackBar(context, _firebaseSignupMessage(e.code));
    } catch (e) {
      debugPrint('Signup error: $e');
      _showErrorSnackBar(context, 'Sign-up failed. Please try again.');
    } finally {
      if (_isLoading) {
        _isLoading = false;
        notifyListeners();
      }
    }
  }

  // ── Helpers ────────────────────────────────────────────────────────────
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

  void _showApprovalPendingDialog(BuildContext context) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        backgroundColor: Theme.of(ctx).cardColor,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        title: const Text(
          'Account Created',
          style: TextStyle(
              fontFamily: 'Inter', fontSize: 18, fontWeight: FontWeight.w600),
        ),
        content: const Text(
          'Your account request has been submitted. An admin will review and '
          'approve it. You will be able to sign in once approved.',
          style: TextStyle(fontFamily: 'Inter', fontSize: 14),
        ),
        actions: [
          ElevatedButton(
            onPressed: () => Navigator.of(ctx).pop(),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xff1BA3A1),
              foregroundColor: Colors.white,
            ),
            child: const Text('OK',
                style: TextStyle(fontFamily: 'Inter', fontWeight: FontWeight.w600)),
          ),
        ],
      ),
    );
  }

  String _firebaseAuthMessage(String code) {
    switch (code) {
      case 'user-not-found':
        return 'No account found for this email.';
      case 'wrong-password':
        return 'Incorrect password.';
      case 'invalid-email':
        return 'Invalid email format.';
      case 'user-disabled':
        return 'This account has been disabled.';
      case 'too-many-requests':
        return 'Too many attempts. Please wait and try again.';
      case 'network-request-failed':
        return 'Unable to reach the server. Check your connection.';
      case 'invalid-credential':
        return 'Invalid login credentials.';
      case 'operation-not-allowed':
        return 'Email/password sign-in is not enabled.';
      default:
        return 'Sign-in failed. Please try again.';
    }
  }

  String _firebaseSignupMessage(String code) {
    switch (code) {
      case 'email-already-in-use':
        return 'This email is already registered.';
      case 'invalid-email':
        return 'Invalid email format.';
      case 'weak-password':
        return 'Password is too weak (use 6+ characters).';
      case 'operation-not-allowed':
        return 'Sign-up is currently unavailable.';
      case 'network-request-failed':
        return 'Unable to reach the server. Check your connection.';
      default:
        return 'Sign-up failed. Please try again.';
    }
  }

  void clearForm() {
    emailController.clear();
    passwordController.clear();
    confirmPasswordController.clear();
    nameController.clear();
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
