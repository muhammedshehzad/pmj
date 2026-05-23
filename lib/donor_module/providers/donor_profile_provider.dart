import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../models/person_model.dart';

/// Provider for managing donor profile data and operations
class DonorProfileProvider with ChangeNotifier {
  Person? _donorProfile;
  bool _isLoading = false;
  String? _errorMessage;
  bool _isEditing = false;

  // Getters
  Person? get donorProfile => _donorProfile;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  bool get isEditing => _isEditing;

  /// Load donor profile from Firebase
  Future<void> loadDonorProfile(String donorId) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final donorDoc = await FirebaseFirestore.instance
          .collection('donors')
          .doc(donorId)
          .get();

      if (donorDoc.exists) {
        _donorProfile = Person.fromFirestore(donorDoc);
      } else {
        _errorMessage = 'Donor profile not found';
      }
    } catch (e) {
      debugPrint('Error loading donor profile: $e');
      _errorMessage = 'Failed to load profile: ${e.toString()}';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Toggle edit mode
  void toggleEditMode() {
    _isEditing = !_isEditing;
    notifyListeners();
  }

  /// Cancel editing and revert changes
  void cancelEditing() {
    _isEditing = false;
    notifyListeners();
  }

  /// Update donor profile in Firebase
  Future<bool> updateDonorProfile({
    required String donorId,
    String? name, // Optional - only update if provided
    required String address,
    required String contactNumber,
    String? photoUrl, // Optional photo URL
  }) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      // Validate inputs
      if (address.trim().isEmpty) {
        _errorMessage = 'Address cannot be empty';
        _isLoading = false;
        notifyListeners();
        return false;
      }

      if (contactNumber.trim().isEmpty) {
        _errorMessage = 'Contact number cannot be empty';
        _isLoading = false;
        notifyListeners();
        return false;
      }

      // Validate phone number format (10 digits)
      if (!RegExp(r'^\d{10}$').hasMatch(contactNumber.trim())) {
        _errorMessage = 'Contact number must be 10 digits';
        _isLoading = false;
        notifyListeners();
        return false;
      }

      // Prepare update data
      final updateData = {
        'address': address.trim(),
        'number': contactNumber.trim(),
      };
      
      // Add name if provided
      if (name != null && name.trim().isNotEmpty) {
        updateData['name'] = name.trim();
      }
      
      // Add photoUrl if provided
      if (photoUrl != null) {
        updateData['imageUrl'] = photoUrl;
      }

      // Update in Firebase
      await FirebaseFirestore.instance
          .collection('donors')
          .doc(donorId)
          .update(updateData);

      // Update local profile
      if (_donorProfile != null) {
        _donorProfile = Person(
          id: _donorProfile!.id,
          name: name?.trim() ?? _donorProfile!.name,
          house: address.trim(),
          phoneNumber: contactNumber.trim(),
          amount: _donorProfile!.amount,
          photoUrl: photoUrl ?? _donorProfile!.photoUrl,
        );
      }

      _isEditing = false;
      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      debugPrint('Error updating donor profile: $e');
      _errorMessage = 'Failed to update profile: ${e.toString()}';
      _isLoading = false;
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
    _donorProfile = null;
    _isLoading = false;
    _errorMessage = null;
    _isEditing = false;
    notifyListeners();
  }
}
