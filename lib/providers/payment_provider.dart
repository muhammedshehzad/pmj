import 'package:flutter/material.dart';

class PaymentProvider with ChangeNotifier {
  // Simple payment provider for managing payment state
  String _selectedPaymentMethod = 'Cash';
  
  String get selectedPaymentMethod => _selectedPaymentMethod;
  
  void setPaymentMethod(String method) {
    _selectedPaymentMethod = method;
    notifyListeners();
  }
}