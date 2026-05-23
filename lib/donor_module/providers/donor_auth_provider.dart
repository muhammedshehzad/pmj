import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import '../models/donor_user_model.dart';
import '../services/donor_auth_service.dart';

/// Authentication state for donor module using Provider
class DonorAuthProvider with ChangeNotifier {
  final DonorAuthService _authService = DonorAuthService();

  // Auth state
  User? _currentUser;
  DonorUser? _donorUser;
  bool _isLoading = false;
  String? _errorMessage;
  bool _isInitialized = false;

  // OTP verification state
  String? _verificationId;
  int? _forceResendingToken;
  bool _otpSent = false;
  bool _isVerifying = false;

  // Phone number for registration
  String? _phoneNumber;
  String? _donorId; // Linked donor ID

  // Getters
  User? get currentUser => _currentUser;
  DonorUser? get donorUser => _donorUser;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  bool get isAuthenticated => _currentUser != null;
  bool get isInitialized => _isInitialized;
  bool get otpSent => _otpSent;
  bool get isVerifying => _isVerifying;
  String? get phoneNumber => _phoneNumber;
  String? get donorId => _donorId;

  DonorAuthProvider() {
    // Listen to auth state changes
    _authService.authStateChanges.listen((User? user) {
      _currentUser = user;
      if (user != null) {
        _loadDonorUser(user.uid);
      } else {
        _donorUser = null;
      }
      notifyListeners();
    });

    // Initialize current user
    _currentUser = _authService.currentUser;
    if (_currentUser != null) {
      _loadDonorUser(_currentUser!.uid);
    }
  }

  /// Load donor user data from Firestore
  Future<void> _loadDonorUser(String userId) async {
    try {
      debugPrint('DonorAuthProvider: Loading donor user for userId: $userId');
      _donorUser = await _authService.getDonorUser(userId);
      debugPrint('DonorAuthProvider: Loaded donorUser: ${_donorUser?.donorId}');
      await _authService.updateLastLogin(userId);
      _isInitialized = true;
      notifyListeners();
    } catch (e) {
      debugPrint('DonorAuthProvider ERROR loading donor user: $e');
      _isInitialized = true;
      notifyListeners();
    }
  }

  /// Clear error message
  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }

  /// Set loading state
  void _setLoading(bool value) {
    _isLoading = value;
    notifyListeners();
  }

  /// Set error message
  void _setError(String message) {
    _errorMessage = message;
    _isLoading = false;
    notifyListeners();
  }

  /// Send OTP to phone number
  /// 
  /// [phoneNumber] must be in format: +91XXXXXXXXXX
  /// Returns true if OTP sent successfully
  Future<bool> sendOTP(String phoneNumber) async {
    try {
      clearError();
      _setLoading(true);
      _phoneNumber = phoneNumber;
      _otpSent = false;

      // First check if donor exists with this phone number
      final donorId = await _authService.checkDonorExists(phoneNumber);
      
      if (donorId == null) {
        _setError('No donor found with this phone number. Please contact admin.');
        return false;
      }

      _donorId = donorId;

      // Send OTP
      await _authService.sendOTP(
        phoneNumber: phoneNumber,
        verificationCompleted: (PhoneAuthCredential credential) async {
          // Auto-verification (Android only)
          try {
            await _signInWithCredential(credential);
          } catch (e) {
            _setError('Auto-verification failed: ${e.toString()}');
          }
        },
        verificationFailed: (FirebaseAuthException e) {
          _setError(e.message ?? 'Verification failed');
          _setLoading(false);
        },
        codeSent: (String verificationId, int? forceResendingToken) {
          _verificationId = verificationId;
          _forceResendingToken = forceResendingToken;
          _otpSent = true;
          _setLoading(false);
          debugPrint('OTP sent successfully');
        },
        codeAutoRetrievalTimeout: (String verificationId) {
          _verificationId = verificationId;
          debugPrint('Auto-retrieval timeout');
        },
      );

      return true;
    } catch (e) {
      _setError(e.toString().replaceAll('Exception: ', ''));
      return false;
    }
  }

  /// Verify OTP and complete sign in
  /// 
  /// [otp] 6-digit code entered by user
  /// Returns true if verification successful
  Future<bool> verifyOTP(String otp) async {
    if (_verificationId == null) {
      _setError('Verification session expired. Please request a new OTP.');
      return false;
    }

    try {
      clearError();
      _isVerifying = true;
      notifyListeners();

      final user = await _authService.verifyOTPAndSignIn(
        verificationId: _verificationId!,
        otp: otp,
      );

      // Check if donor user exists, if not create one
      DonorUser? existingUser = await _authService.getDonorUser(user.uid);
      
      if (existingUser == null && _donorId != null && _phoneNumber != null) {
        // Create new donor user
        _donorUser = await _authService.createDonorUser(
          userId: user.uid,
          donorId: _donorId!,
          phoneNumber: _phoneNumber!,
        );
      } else {
        _donorUser = existingUser;
      }

      _currentUser = user;
      _isVerifying = false;
      _otpSent = false;
      _verificationId = null;
      notifyListeners();

      return true;
    } catch (e) {
      _setError(e.toString().replaceAll('Exception: ', ''));
      _isVerifying = false;
      notifyListeners();
      return false;
    }
  }

  /// Sign in with credential (for auto-verification)
  Future<void> _signInWithCredential(PhoneAuthCredential credential) async {
    try {
      final userCredential = await FirebaseAuth.instance.signInWithCredential(credential);
      
      if (userCredential.user != null) {
        // Check if donor user exists
        DonorUser? existingUser = await _authService.getDonorUser(userCredential.user!.uid);
        
        if (existingUser == null && _donorId != null && _phoneNumber != null) {
          _donorUser = await _authService.createDonorUser(
            userId: userCredential.user!.uid,
            donorId: _donorId!,
            phoneNumber: _phoneNumber!,
          );
        } else {
          _donorUser = existingUser;
        }

        _currentUser = userCredential.user;
        _otpSent = false;
        _verificationId = null;
        notifyListeners();
      }
    } catch (e) {
      throw Exception('Sign in failed: ${e.toString()}');
    }
  }

  /// Resend OTP
  Future<bool> resendOTP() async {
    if (_phoneNumber == null) {
      _setError('Phone number not found. Please start again.');
      return false;
    }
    
    return await sendOTP(_phoneNumber!);
  }

  /// Sign out current user
  Future<void> signOut() async {
    try {
      await _authService.signOut();
      _currentUser = null;
      _donorUser = null;
      _phoneNumber = null;
      _donorId = null;
      _verificationId = null;
      _otpSent = false;
      clearError();
      notifyListeners();
    } catch (e) {
      _setError('Failed to sign out: ${e.toString()}');
    }
  }

  /// Update donor preferences
  Future<bool> updatePreferences(DonorPreferences preferences) async {
    if (_currentUser == null) {
      _setError('Not authenticated');
      return false;
    }

    try {
      _setLoading(true);
      await _authService.updatePreferences(_currentUser!.uid, preferences);
      
      // Update local state
      _donorUser = _donorUser?.copyWith(preferences: preferences);
      _setLoading(false);
      notifyListeners();
      
      return true;
    } catch (e) {
      _setError(e.toString().replaceAll('Exception: ', ''));
      return false;
    }
  }

  /// Update FCM token for push notifications
  Future<void> updateFCMToken(String fcmToken) async {
    if (_currentUser != null) {
      try {
        await _authService.updateFCMToken(_currentUser!.uid, fcmToken);
        _donorUser = _donorUser?.copyWith(fcmToken: fcmToken);
        notifyListeners();
      } catch (e) {
        debugPrint('Failed to update FCM token: $e');
      }
    }
  }

  /// Check if current user is admin
  Future<bool> checkIsAdmin() async {
    if (_currentUser == null) return false;
    return await _authService.isAdmin(_currentUser!.uid);
  }

  /// Get user role (admin or donor)
  Future<String?> getUserRole() async {
    return await _authService.getUserRole();
  }

  /// Reset OTP state (for going back to phone input)
  void resetOTPState() {
    _otpSent = false;
    _verificationId = null;
    _isVerifying = false;
    clearError();
    notifyListeners();
  }
}
