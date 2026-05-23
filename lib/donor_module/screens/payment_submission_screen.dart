import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../providers/payment_submission_provider.dart';
import '../widgets/donor_app_bar.dart';
import '../widgets/donor_sub_header.dart';
import '../providers/donor_auth_provider.dart';

/// Screen for submitting monthly payments
class PaymentSubmissionScreen extends StatefulWidget {
  const PaymentSubmissionScreen({super.key});

  @override
  State<PaymentSubmissionScreen> createState() => _PaymentSubmissionScreenState();
}

class _PaymentSubmissionScreenState extends State<PaymentSubmissionScreen> {
  final List<String> _paymentMethods = ['Cash', 'UPI', 'Bank Transfer'];
  bool _isLoadingDonor = true;
  String? _donorName;
  double? _donorAmount;
  final List<Map<String, String>> _selectedMonths = [];
  final List<Map<String, String>> _availableMonths = [];

  @override
  void initState() {
    super.initState();
    // Reset provider state when screen opens
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<PaymentSubmissionProvider>(context, listen: false).reset();
      _initializeMonths();
      _loadDonorDetails();
    });
  }

  void _initializeMonths() {
    final now = DateTime.now();
    for (int i = 0; i < 12; i++) {
      final date = DateTime(now.year, now.month + i, 1);
      final month = DateFormat('MMMM').format(date);
      final year = date.year.toString();
      _availableMonths.add({'month': month, 'year': year});
    }
    // Select current month by default
    _selectedMonths.add(_availableMonths[0]);
  }

  Future<void> _loadDonorDetails() async {
    final authProvider = Provider.of<DonorAuthProvider>(context, listen: false);
    
    if (authProvider.donorUser?.donorId == null) {
      setState(() => _isLoadingDonor = false);
      return;
    }

    try {
      final donorDoc = await FirebaseFirestore.instance
          .collection('donors')
          .doc(authProvider.donorUser!.donorId)
          .get();

      if (donorDoc.exists) {
        final data = donorDoc.data()!;
        setState(() {
          _donorName = data['name'] as String? ?? 'Unknown';
          _donorAmount = (data['amount'] as num?)?.toDouble() ?? 0.0;
          _isLoadingDonor = false;
        });
      } else {
        setState(() => _isLoadingDonor = false);
      }
    } catch (e) {
      debugPrint('Error loading donor details: $e');
      setState(() => _isLoadingDonor = false);
    }
  }

  Future<void> _submitPayment() async {
    if (_donorName == null || _donorAmount == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Unable to load donor information. Please try again.'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    final authProvider = Provider.of<DonorAuthProvider>(context, listen: false);
    final paymentProvider = Provider.of<PaymentSubmissionProvider>(context, listen: false);

    if (authProvider.donorUser == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Unable to submit payment. Please try logging in again.'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    final donorUser = authProvider.donorUser!;
    final now = DateTime.now();
    final currentMonth = DateFormat('MMMM').format(now);
    final currentYear = now.year.toString();

    // Show confirmation dialog
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirm Payment'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Months: ${_selectedMonths.map((m) => "${m['month']} ${m['year']}").join(', ')}'),
            const SizedBox(height: 8),
            Text('Amount: ₹${(_donorAmount! * _selectedMonths.length).toStringAsFixed(0)}'),
            const SizedBox(height: 8),
            Text('Method: ${paymentProvider.selectedMethod}'),
            const SizedBox(height: 16),
            const Text(
              'Are you sure you want to submit this payment?',
              style: TextStyle(fontWeight: FontWeight.w500),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xff1BA3A1),
            ),
            child: const Text('Confirm'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    // Submit payment
    final success = await paymentProvider.submitPayment(
      donorId: donorUser.donorId,
      donorName: _donorName!,
      amount: _donorAmount! * _selectedMonths.length,
      selectedMonths: _selectedMonths,
    );

    if (mounted) {
      if (success) {
        // Show success message
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Payment submitted successfully!'),
            backgroundColor: Colors.green,
          ),
        );
        // Navigate back to dashboard
        Navigator.pop(context, true); // Return true to indicate success
      } else if (paymentProvider.errorMessage != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(paymentProvider.errorMessage!),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<DonorAuthProvider>(context);
    final donorUser = authProvider.donorUser;

    if (donorUser == null) {
      return Scaffold(
        appBar: const DonorAppBar(),
        body: Column(
          children: [
            const DonorSubHeader(title: 'Make Payment'),
            Expanded(
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.error_outline, size: 60, color: Colors.red),
                    const SizedBox(height: 16),
                    const Text('Unable to load donor information'),
                    const SizedBox(height: 16),
                    ElevatedButton(
                      onPressed: () {
                        Navigator.pop(context); // Go back if donor info is missing
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xff1BA3A1),
                      ),
                      child: const Text('Go Back'),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      );
    }

    if (_isLoadingDonor) {
      return Scaffold(
        backgroundColor: Colors.white,
        appBar: AppBar(
          elevation: 0,
          backgroundColor: const Color(0xff1BA3A1),
          title: const Text(
            'Submit Payment',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              fontFamily: "Inter",
              color: Colors.white,
            ),
          ),
          leading: IconButton(
            icon: const Icon(Icons.arrow_back, color: Colors.white),
            onPressed: () => Navigator.pop(context),
          ),
        ),
        body: const Center(
          child: CircularProgressIndicator(
            color: Color(0xff1BA3A1),
          ),
        ),
      );
    }

    if (_donorName == null || _donorAmount == null) {
      return Scaffold(
        backgroundColor: Colors.white,
        appBar: AppBar(
          elevation: 0,
          backgroundColor: const Color(0xff1BA3A1),
          title: const Text(
            'Submit Payment',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              fontFamily: "Inter",
              color: Colors.white,
            ),
          ),
          leading: IconButton(
            icon: const Icon(Icons.arrow_back, color: Colors.white),
            onPressed: () => Navigator.pop(context),
          ),
        ),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline, size: 60, color: Colors.red),
              const SizedBox(height: 16),
              const Text('Failed to load donor information'),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: _loadDonorDetails,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xff1BA3A1),
                ),
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
      );
    }

    final now = DateTime.now();
    final currentMonth = DateFormat('MMMM').format(now);
    final currentYear = now.year.toString();

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        elevation: 0,
        backgroundColor: const Color(0xff1BA3A1),
        title: const Text(
          'Submit Payment',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w600,
            fontFamily: "Inter",
            color: Colors.white,
          ),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Consumer<PaymentSubmissionProvider>(
        builder: (context, provider, child) {
          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Payment Info Card
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xff1BA3A1), Color(0xff159B99)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Payment for',
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.white.withOpacity(0.9),
                          fontFamily: "Inter",
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        _selectedMonths.length == 1 
                            ? '${_selectedMonths[0]['month']} ${_selectedMonths[0]['year']}'
                            : '${_selectedMonths.length} Months',
                        style: const TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                          fontFamily: "Inter",
                        ),
                      ),
                      const SizedBox(height: 16),
                      const Divider(color: Colors.white24),
                      const SizedBox(height: 16),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Amount to Pay',
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.white.withOpacity(0.9),
                              fontFamily: "Inter",
                            ),
                          ),
                          Text(
                            '₹${(_donorAmount! * _selectedMonths.length).toStringAsFixed(0)}',
                            style: const TextStyle(
                              fontSize: 32,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                              fontFamily: "Inter",
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 24),

                // Select Months Section
                const Text(
                  'Select Months',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    fontFamily: "Inter",
                  ),
                ),
                const SizedBox(height: 12),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.grey[50],
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.grey[200]!),
                  ),
                  child: Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: _availableMonths.map((monthData) {
                      final isSelected = _selectedMonths.contains(monthData);
                      final isCurrentMonth = monthData == _availableMonths[0];
                      
                      return FilterChip(
                        label: Text(
                          '${monthData['month']!.substring(0, 3)} ${monthData['year']}',
                          style: TextStyle(
                            fontSize: 12,
                            color: isSelected ? Colors.white : Colors.black87,
                            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                            fontFamily: "Inter",
                          ),
                        ),
                        selected: isSelected,
                        onSelected: isCurrentMonth ? null : (selected) {
                          setState(() {
                            if (selected) {
                              _selectedMonths.add(monthData);
                              // Sort selected months to keep them chronological
                              _selectedMonths.sort((a, b) {
                                final aIndex = _availableMonths.indexOf(a);
                                final bIndex = _availableMonths.indexOf(b);
                                return aIndex.compareTo(bIndex);
                              });
                            } else {
                              _selectedMonths.remove(monthData);
                            }
                          });
                        },
                        selectedColor: const Color(0xff1BA3A1),
                        checkmarkColor: Colors.white,
                        backgroundColor: Colors.white,
                        side: BorderSide(
                          color: isSelected ? const Color(0xff1BA3A1) : Colors.grey[300]!,
                        ),
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      );
                    }).toList(),
                  ),
                ),

                const SizedBox(height: 24),

                // Payment Method Selection
                const Text(
                  'Payment Method',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    fontFamily: "Inter",
                  ),
                ),
                const SizedBox(height: 12),

                ..._paymentMethods.map((method) {
                  final isSelected = provider.selectedMethod == method;
                  IconData icon;
                  switch (method) {
                    case 'Cash':
                      icon = Icons.money;
                      break;
                    case 'UPI':
                      icon = Icons.qr_code;
                      break;
                    case 'Bank Transfer':
                      icon = Icons.account_balance;
                      break;
                    default:
                      icon = Icons.payment;
                  }

                  return Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: InkWell(
                      onTap: () => provider.setPaymentMethod(method),
                      borderRadius: BorderRadius.circular(12),
                      child: Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: isSelected
                              ? const Color(0xff1BA3A1).withOpacity(0.1)
                              : Colors.grey[50],
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: isSelected
                                ? const Color(0xff1BA3A1)
                                : Colors.grey[200]!,
                            width: isSelected ? 2 : 1,
                          ),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              icon,
                              color: isSelected
                                  ? const Color(0xff1BA3A1)
                                  : Colors.grey[600],
                              size: 28,
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: Text(
                                method,
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: isSelected
                                      ? FontWeight.w600
                                      : FontWeight.w500,
                                  color: isSelected
                                      ? const Color(0xff1BA3A1)
                                      : Colors.black87,
                                  fontFamily: "Inter",
                                ),
                              ),
                            ),
                            if (isSelected)
                              const Icon(
                                Icons.check_circle,
                                color: Color(0xff1BA3A1),
                                size: 24,
                              ),
                          ],
                        ),
                      ),
                    ),
                  );
                }),

                const SizedBox(height: 32),

                // Important Note
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.blue[50],
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.blue[200]!),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.info_outline, color: Colors.blue[700]),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          'Your payment will be recorded immediately after submission.',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.blue[900],
                            fontFamily: "Inter",
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 24),

                // Submit Button
                SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: ElevatedButton(
                    onPressed: provider.isSubmitting ? null : _submitPayment,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xff1BA3A1),
                      foregroundColor: Colors.white,
                      disabledBackgroundColor: Colors.grey[300],
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: provider.isSubmitting
                        ? const SizedBox(
                            width: 24,
                            height: 24,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                            ),
                          )
                        : const Text(
                            'Submit Payment',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              fontFamily: "Inter",
                            ),
                          ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
