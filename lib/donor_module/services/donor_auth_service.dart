import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/cupertino.dart';
import '../models/donor_user_model.dart';

/// Service for handling donor authentication using Firebase Auth with phone OTP
class DonorAuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Collections
  static const String donorUsersCollection = 'donorUsers';
  static const String donorsCollection = 'donors';

  /// Get current authenticated user
  User? get currentUser => _auth.currentUser;

  /// Stream of auth state changes
  Stream<User?> get authStateChanges => _auth.authStateChanges();

  /// Send OTP to phone number
  /// 
  /// [phoneNumber] must be in format: +91XXXXXXXXXX
  /// [verificationCompleted] callback when auto-verification succeeds
  /// [verificationFailed] callback when verification fails
  /// [codeSent] callback when OTP is sent
  /// [codeAutoRetrievalTimeout] callback when auto-retrieval times out
  Future<void> sendOTP({
    required String phoneNumber,
    required Function(PhoneAuthCredential) verificationCompleted,
    required Function(FirebaseAuthException) verificationFailed,
    required Function(String verificationId, int? forceResendingToken) codeSent,
    required Function(String verificationId) codeAutoRetrievalTimeout,
  }) async {
    try {
      await _auth.verifyPhoneNumber(
        phoneNumber: phoneNumber,
        verificationCompleted: verificationCompleted,
        verificationFailed: verificationFailed,
        codeSent: codeSent,
        codeAutoRetrievalTimeout: codeAutoRetrievalTimeout,
        timeout: const Duration(seconds: 60),
      );
    } catch (e) {
      throw _handleAuthError(e);
    }
  }

  /// Verify OTP and sign in
  /// 
  /// [verificationId] received from codeSent callback
  /// [otp] 6-digit code entered by user
  /// Returns the signed-in User or throws an error
  Future<User> verifyOTPAndSignIn({
    required String verificationId,
    required String otp,
  }) async {
    try {
      // Create credential from OTP
      final credential = PhoneAuthProvider.credential(
        verificationId: verificationId,
        smsCode: otp,
      );

      // Sign in with credential
      final userCredential = await _auth.signInWithCredential(credential);
      
      if (userCredential.user == null) {
        throw Exception('Sign in failed - no user returned');
      }

      return userCredential.user!;
    } on FirebaseAuthException catch (e) {
      throw _handleAuthError(e);
    } on TypeError catch (e) {
      // Handle Firebase type casting errors
      debugPrint('Firebase type error: $e');
      // Check if user is actually signed in despite the error
      final currentUser = _auth.currentUser;
      if (currentUser != null) {
        return currentUser;
      }
      throw Exception('Failed to verify OTP: Type error occurred');
    } catch (e) {
      debugPrint('Failed to verify OTP: ${e.toString()}');
      throw Exception('Failed to verify OTP: ${e.toString()}');
    }
  }

  /// Check if donor exists in system
  /// 
  /// [phoneNumber] must match a donor's phone number in Firestore
  /// Returns the donor's document ID if found, null otherwise
  Future<String?> checkDonorExists(String phoneNumber) async {
    try {
      // Remove +91 country code if present for comparison
      final cleanNumber = phoneNumber.replaceAll('+91', '').replaceAll('+', '');
      
      final querySnapshot = await _firestore
          .collection(donorsCollection)
          .where('number', isEqualTo: cleanNumber)
          .limit(1)
          .get();

      if (querySnapshot.docs.isNotEmpty) {
        return querySnapshot.docs.first.id;
      }
      
      return null;
    } catch (e) {
      throw Exception('Failed to check donor existence: ${e.toString()}');
    }
  }

  /// Create donor user account in Firestore
  /// 
  /// Links Firebase Auth user with donor profile
  /// [userId] Firebase Auth UID
  /// [donorId] Reference to donor document
  /// [phoneNumber] User's phone number
  Future<DonorUser> createDonorUser({
    required String userId,
    required String donorId,
    required String phoneNumber,
    String? email,
  }) async {
    try {
      final now = DateTime.now();
      final donorUser = DonorUser(
        userId: userId,
        donorId: donorId,
        phoneNumber: phoneNumber,
        email: email,
        role: 'donor',
        preferences: DonorPreferences(),
        createdAt: now,
        lastLogin: now,
      );

      // Save to Firestore
      await _firestore
          .collection(donorUsersCollection)
          .doc(userId)
          .set(donorUser.toFirestore());

      // Update donor document with userId link
      await _firestore
          .collection(donorsCollection)
          .doc(donorId)
          .update({
        'userId': userId,
        'memberSince': Timestamp.fromDate(now),
      });

      return donorUser;
    } catch (e) {
      throw Exception('Failed to create donor user: ${e.toString()}');
    }
  }

  /// Get donor user data from Firestore
  /// 
  /// [userId] Firebase Auth UID
  /// Returns DonorUser or null if not found
  Future<DonorUser?> getDonorUser(String userId) async {
    try {
      final doc = await _firestore
          .collection(donorUsersCollection)
          .doc(userId)
          .get();

      if (!doc.exists) {
        return null;
      }

      return DonorUser.fromFirestore(doc);
    } catch (e) {
      throw Exception('Failed to get donor user: ${e.toString()}');
    }
  }

  /// Update last login timestamp
  Future<void> updateLastLogin(String userId) async {
    try {
      await _firestore
          .collection(donorUsersCollection)
          .doc(userId)
          .update({
        'lastLogin': Timestamp.fromDate(DateTime.now()),
      });
    } catch (e) {
      // Non-critical error, just log it
      print('Failed to update last login: $e');
    }
  }

  /// Update FCM token for push notifications
  Future<void> updateFCMToken(String userId, String fcmToken) async {
    try {
      await _firestore
          .collection(donorUsersCollection)
          .doc(userId)
          .update({
        'fcmToken': fcmToken,
      });
    } catch (e) {
      print('Failed to update FCM token: $e');
    }
  }

  /// Update donor preferences
  Future<void> updatePreferences(String userId, DonorPreferences preferences) async {
    try {
      await _firestore
          .collection(donorUsersCollection)
          .doc(userId)
          .update({
        'preferences': preferences.toMap(),
      });
    } catch (e) {
      throw Exception('Failed to update preferences: ${e.toString()}');
    }
  }

  /// Sign out current user
  Future<void> signOut() async {
    try {
      await _auth.signOut();
    } catch (e) {
      throw Exception('Failed to sign out: ${e.toString()}');
    }
  }

  /// Handle Firebase Auth errors and convert to user-friendly messages
  Exception _handleAuthError(dynamic error) {
    if (error is FirebaseAuthException) {
      switch (error.code) {
        case 'invalid-phone-number':
          return Exception('Invalid phone number format');
        case 'invalid-verification-code':
          return Exception('Invalid OTP code. Please try again.');
        case 'invalid-verification-id':
          return Exception('Verification session expired. Please request a new OTP.');
        case 'session-expired':
          return Exception('Verification session expired. Please try again.');
        case 'quota-exceeded':
          return Exception('Too many requests. Please try again later.');
        case 'network-request-failed':
          return Exception('Network error. Please check your connection.');
        case 'too-many-requests':
          return Exception('Too many attempts. Please try again later.');
        case 'user-disabled':
          return Exception('This account has been disabled.');
        case 'operation-not-allowed':
          return Exception('Phone authentication is not enabled.');
        default:
          return Exception('Authentication failed: ${error.message ?? error.code}');
      }
    }
    return Exception('Authentication failed: ${error.toString()}');
  }

  /// Check if user is admin
  Future<bool> isAdmin(String userId) async {
    try {
      final donorUser = await getDonorUser(userId);
      return donorUser?.role == 'admin';
    } catch (e) {
      return false;
    }
  }

  /// Check authentication status and get user role
  /// 
  /// Returns 'admin', 'donor', or null if not authenticated
  Future<String?> getUserRole() async {
    try {
      final user = currentUser;
      if (user == null) return null;

      final donorUser = await getDonorUser(user.uid);
      return donorUser?.role;
    } catch (e) {
      return null;
    }
  }
}
