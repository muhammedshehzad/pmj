import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../models/donation_model.dart';

/// Provider for managing payment history for donors
class PaymentHistoryProvider with ChangeNotifier {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  
  // State
  List<Donation> _allPayments = [];
  List<Donation> _filteredPayments = [];
  bool _isLoading = false;
  String? _errorMessage;
  
  // Filters
  String? _selectedYear;
  String? _selectedMonth;
  String _selectedStatus = 'All'; // All, Paid, Pending
  String _selectedMethod = 'All'; // All, Cash, UPI, Bank Transfer
  
  // Getters
  List<Donation> get filteredPayments => _filteredPayments;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  String? get selectedYear => _selectedYear;
  String? get selectedMonth => _selectedMonth;
  String get selectedStatus => _selectedStatus;
  String get selectedMethod => _selectedMethod;
  
  // Summary statistics
  double get totalAmountThisYear {
    final currentYear = DateTime.now().year.toString();
    return _allPayments
        .where((p) => p.year == currentYear && (p.status == 'paid' || p.status == 'approved'))
        .fold(0.0, (sum, p) => sum + p.amount);
  }
  
  int get totalPaymentsCount => _allPayments.where((p) => p.status == 'paid' || p.status == 'approved').length;
  
  int get currentStreak {
    if (_allPayments.isEmpty) return 0;
    
    // 1. Create a set of paid months (normalized to first of month)
    final paidMonths = <DateTime>{};
    
    for (final p in _allPayments) {
      if (p.status == 'paid' || p.status == 'approved') {
        if (p.monthsList != null && p.monthsList!.isNotEmpty) {
          for (final monthStr in p.monthsList!) {
            try {
              // Parse "Month Year" string
              final date = DateFormat('MMMM yyyy').parse(monthStr);
              paidMonths.add(DateTime(date.year, date.month));
            } catch (e) {
              debugPrint('Error parsing month string in streak calculation: $monthStr');
            }
          }
        } else {
          try {
            paidMonths.add(DateTime(int.parse(p.year), _monthToNumber(p.month)));
          } catch (e) {
             debugPrint('Error parsing month/year in streak calculation: ${p.month} ${p.year}');
          }
        }
      }
    }
        
    if (paidMonths.isEmpty) return 0;
    
    int streak = 0;
    final now = DateTime.now();
    DateTime checkDate = DateTime(now.year, now.month);
    
    // Iterate backwards from current month
    while (true) {
      final found = paidMonths.any((d) => d.year == checkDate.year && d.month == checkDate.month);
      
      if (found) {
        streak++;
        checkDate = DateTime(checkDate.year, checkDate.month - 1);
      } else {
        break;
      }
    }
    
    return streak;
  }
  
  /// Load payment history for a donor
  Future<void> loadPaymentHistory(String donorId) async {
    try {
      debugPrint('PaymentHistoryProvider: Loading payment history for donorId: $donorId');
      _isLoading = true;
      _errorMessage = null;
      notifyListeners();
      
      // Get all donations for this donor (without orderBy to avoid index requirement)
      final querySnapshot = await _firestore
          .collection('donations')
          .where('donorId', isEqualTo: donorId)
          .get();
      
      debugPrint('PaymentHistoryProvider: Found ${querySnapshot.docs.length} donation documents');
      
      _allPayments = querySnapshot.docs
          .map((doc) {
            debugPrint('PaymentHistoryProvider: Processing doc with data: ${doc.data()}');
            return Donation.fromFirestore(doc.data());
          })
          .toList();
      
      debugPrint('PaymentHistoryProvider: Parsed ${_allPayments.length} donations');
      
      // Sort in memory by year and month (most recent first)
      _allPayments.sort((a, b) {
        final aYear = int.tryParse(a.year) ?? 0;
        final bYear = int.tryParse(b.year) ?? 0;
        if (aYear != bYear) return bYear.compareTo(aYear);
        
        final aMonth = _monthToNumber(a.month);
        final bMonth = _monthToNumber(b.month);
        return bMonth.compareTo(aMonth);
      });
      
      _applyFilters();
      
      debugPrint('PaymentHistoryProvider: After filtering, ${_filteredPayments.length} payments to display');
      
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      debugPrint('PaymentHistoryProvider ERROR: $e');
      _errorMessage = 'Failed to load payment history: ${e.toString()}';
      _isLoading = false;
      notifyListeners();
    }
  }
  
  /// Set year filter
  void setYearFilter(String? year) {
    _selectedYear = year;
    _applyFilters();
  }
  
  /// Set month filter
  void setMonthFilter(String? month) {
    _selectedMonth = month;
    _applyFilters();
  }
  
  /// Set status filter
  void setStatusFilter(String status) {
    _selectedStatus = status;
    _applyFilters();
  }
  
  /// Set payment method filter
  void setMethodFilter(String method) {
    _selectedMethod = method;
    _applyFilters();
  }
  
  /// Clear all filters
  void clearFilters() {
    _selectedYear = null;
    _selectedMonth = null;
    _selectedStatus = 'All';
    _selectedMethod = 'All';
    _applyFilters();
  }
  
  /// Apply current filters to payment list
  void _applyFilters() {
    _filteredPayments = _allPayments.where((payment) {
      // Year filter
      if (_selectedYear != null && payment.year != _selectedYear) {
        return false;
      }
      
      // Month filter
      if (_selectedMonth != null && payment.month != _selectedMonth) {
        return false;
      }
      
      // Status filter
      if (_selectedStatus != 'All') {
        if (_selectedStatus == 'Paid' && payment.status != 'paid') {
          return false;
        }
        if (_selectedStatus == 'Pending' && payment.status != 'pending') {
          return false;
        }
      }
      
      // Method filter
      if (_selectedMethod != 'All' && payment.method != _selectedMethod) {
        return false;
      }
      
      return true;
    }).toList();
    
    notifyListeners();
  }
  
  /// Get list of available years from payments
  List<String> getAvailableYears() {
    final years = _allPayments.map((p) => p.year).toSet().toList();
    years.sort((a, b) => b.compareTo(a)); // Most recent first
    return years;
  }
  
  /// Get list of available months
  List<String> getAvailableMonths() {
    return [
      'January', 'February', 'March', 'April', 'May', 'June',
      'July', 'August', 'September', 'October', 'November', 'December'
    ];
  }
  
  /// Convert month name to number
  int _monthToNumber(String month) {
    const months = {
      'January': 1, 'February': 2, 'March': 3, 'April': 4,
      'May': 5, 'June': 6, 'July': 7, 'August': 8,
      'September': 9, 'October': 10, 'November': 11, 'December': 12,
    };
    return months[month] ?? 1;
  }
  
  /// Refresh payment history
  Future<void> refresh(String donorId) async {
    await loadPaymentHistory(donorId);
  }
}
