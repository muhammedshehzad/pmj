import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';

/// Provider for handling payment submissions from donors
class PaymentSubmissionProvider with ChangeNotifier {
  bool _isSubmitting = false;
  String? _errorMessage;
  String _selectedMethod = 'Cash';

  // Getters
  bool get isSubmitting => _isSubmitting;
  String? get errorMessage => _errorMessage;
  String get selectedMethod => _selectedMethod;

  /// Set payment method
  void setPaymentMethod(String method) {
    _selectedMethod = method;
    notifyListeners();
  }

  /// Submit payment to Firebase
  Future<bool> submitPayment({
    required String donorId,
    required String donorName,
    required double amount,
    required List<Map<String, String>> selectedMonths, // List of {'month': '...', 'year': '...'}
  }) async {
    _isSubmitting = true;
    _errorMessage = null;
    notifyListeners();

    try {
      // Validate inputs
      if (amount <= 0) {
        _errorMessage = 'Invalid payment amount';
        _isSubmitting = false;
        notifyListeners();
        return false;
      }

      if (selectedMonths.isEmpty) {
        _errorMessage = 'No months selected';
        _isSubmitting = false;
        notifyListeners();
        return false;
      }

      final now = DateTime.now();
      final dateFormat = DateFormat('dd MMM yyyy');
      final paymentDate = dateFormat.format(now);

      // Create display string for months
      final List<String> monthsList = selectedMonths.map((m) => "${m['month']} ${m['year']}").toList();

      final firestore = FirebaseFirestore.instance;
      final batch = firestore.batch();
      
      // Create donation record reference to get ID
      final donationRef = firestore.collection('donations').doc();
      final donationId = donationRef.id;

      // Create donation record
      batch.set(donationRef, {
        'donorId': donorId,
        'name': donorName, // Assuming donorName is passed correctly
        'amount': amount,
        'month': selectedMonths.first['month'],
        'year': selectedMonths.first['year'],
        'monthsList': monthsList,
        'date': paymentDate,
        'method': _selectedMethod,
        'status': 'paid',
        'timestamp': FieldValue.serverTimestamp(),
      });

      // Update payment status in donor's subcollection for EACH month
      final monthlyAmount = amount / selectedMonths.length;
      
      for (int i = 0; i < selectedMonths.length; i++) {
        final monthData = selectedMonths[i];
        final month = monthData['month']!;
        final year = monthData['year']!;
        
        final monthYearKey = '$month-$year';
        final statusRef = firestore
            .collection('donors')
            .doc(donorId)
            .collection('paymentStatus')
            .doc(monthYearKey);

        final Map<String, dynamic> statusData = {
          'month': month,
          'year': year,
          'status': 'paid',
          'paidDate': paymentDate,
          'method': _selectedMethod,
          'amount': monthlyAmount,
          'timestamp': FieldValue.serverTimestamp(),
          'donationId': donationId,
        };

        if (i == 0) {
          statusData['isMainEntry'] = true;
          statusData['totalDonationAmount'] = amount;
          statusData['monthsList'] = monthsList;
        } else {
          statusData['hideFromHistory'] = true;
        }

        batch.set(statusRef, statusData, SetOptions(merge: true));
      }

      await batch.commit();

      _isSubmitting = false;
      notifyListeners();
      return true;
    } catch (e) {
      debugPrint('Error submitting payment: $e');
      _errorMessage = 'Failed to submit payment: ${e.toString()}';
      _isSubmitting = false;
      notifyListeners();
      return false;
    }
  }

  /// Clear error message
  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }

  /// Reset provider state
  void reset() {
    _isSubmitting = false;
    _errorMessage = null;
    _selectedMethod = 'Cash';
    notifyListeners();
  }
}
