import 'package:flutter_typeahead/flutter_typeahead.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:pmj_application/assets/custom widgets/logoutpopup.dart';
import 'package:pmj_application/models/donation_model.dart';
import 'package:pmj_application/models/person_model.dart';
import 'package:pmj_application/services/local_database_service.dart';
import 'package:provider/provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'package:shimmer/shimmer.dart';
import '../assets/custom%20widgets/shimmer_widgets.dart';
import '../assets/custom widgets/transition.dart';
import '../secondary/all_donations.dart';
import '../services/image_cache_service.dart';
import '../services/local_database_service.dart';
import '../utils/month_formatter.dart';

class MonthlyStatus {
  final String userName;
  final String month;
  final String year;
  final String status;

  MonthlyStatus({
    required this.userName,
    required this.month,
    required this.year,
    required this.status,
  });
}

class PaymentsPageProvider extends ChangeNotifier {
  String? _selectedMonth;
  String? _selectedPayment;
  String? _selectedDonor;
  String? _selectedYear;
  List<Map<String, dynamic>> _donors = [];
  List<MonthlyStatus> _paymentStatuses = [];
  bool _isMultiMonthMode = false;
  List<String> _selectedMonths = [];

  List<String> get months => [
        'January',
        'February',
        'March',
        'April',
        'May',
        'June',
        'July',
        'August',
        'September',
        'October',
        'November',
        'December'
      ];

  List<String> get years {
    final currentYear = DateTime.now().year;
    return List.generate(3, (index) => (currentYear - index).toString());
  }

  TextEditingController amountController = TextEditingController();
  TextEditingController donorController = TextEditingController();

  String? get selectedMonth => _selectedMonth;

  String? get selectedPayment => _selectedPayment;

  String? get selectedDonor => _selectedDonor;

  String? get selectedYear => _selectedYear;

  List<Map<String, dynamic>> get donors => _donors;

  List<MonthlyStatus> get paymentStatuses => _paymentStatuses;

  bool get isMultiMonthMode => _isMultiMonthMode;

  List<String> get selectedMonths => _selectedMonths;

  PaymentsPageProvider() {
    _selectedYear = DateTime.now().year.toString();
    initializePaymentStatuses();
  }

  void setSelectedMonth(String? month) {
    if (_isMultiMonthMode) {
      if (month != null) {
        if (_selectedMonths.contains(month)) {
          _selectedMonths.remove(month);
        } else {
          _selectedMonths.add(month);
        }
      }
    } else {
      _selectedMonth = month;
    }
    notifyListeners();
  }

  void toggleMultiMonthMode() {
    _isMultiMonthMode = !_isMultiMonthMode;
    if (!_isMultiMonthMode) {
      _selectedMonths.clear();
      if (_selectedMonths.isNotEmpty) {
        _selectedMonth = _selectedMonths.first;
      }
    } else {
      if (_selectedMonth != null) {
        _selectedMonths = [_selectedMonth!];
      }
      _selectedMonth = null;
    }
    notifyListeners();
  }

  void clearSelectedMonths() {
    _selectedMonths.clear();
    notifyListeners();
  }

  void setSelectedPayment(String? paymentMethod) {
    _selectedPayment = paymentMethod;
    notifyListeners();
  }

  void setSelectedDonor(String? donorName) {
    _selectedDonor = donorName;
    if (donorName != null) {
      if (donorController.text != donorName) {
        donorController.text = donorName;
      }
      final donor = _donors.firstWhere((d) => d['name'] == donorName,
          orElse: () => {'amount': 0});
      amountController.text = donor['amount'].toString();
      fetchPaymentStatuses(donor['id']);
    } else {
      amountController.clear();
      donorController.clear();
      _paymentStatuses = [];
    }
    notifyListeners();
  }

  void setSelectedYear(String? year) {
    _selectedYear = year;
    notifyListeners();
  }

  Future<void> fetchDonors() async {
    try {
      final snapshot =
          await FirebaseFirestore.instance.collection('donors').get();
      _donors = snapshot.docs.map((doc) {
        final data = doc.data();
        return {
          'name': data['name'] ?? 'Unknown',
          'amount': (data['amount'] as num?)?.toInt() ?? 0,
          'imageUrl': data['imageUrl'] ?? data['photoUrl'],
          'id': doc.id,
        };
      }).toList();
      _donors.sort((a, b) => (a['name'] as String)
          .toLowerCase()
          .compareTo((b['name'] as String).toLowerCase()));
      notifyListeners();
    } catch (e) {
      print('Error fetching donors: $e');
      throw Exception('Failed to fetch donors');
    }
  }

  Future<void> initializePaymentStatuses() async {
    if (_selectedDonor == null) return;

    final currentYear = DateTime.now().year;
    final currentMonth = DateTime.now().month;
    final donorId =
        _donors.firstWhere((d) => d['name'] == _selectedDonor)['id'];

    WriteBatch batch = FirebaseFirestore.instance.batch();
    final donorRef =
        FirebaseFirestore.instance.collection('donors').doc(donorId);

    // Initialize last 2 years and current year up to current month
    for (int year = currentYear - 2; year <= currentYear; year++) {
      for (int month = 1; month <= 12; month++) {
        if (year == currentYear && month > currentMonth)
          continue; // Skip future months
        final monthName = months[month - 1];
        final monthYearKey = '$monthName-$year';
        final statusRef =
            donorRef.collection('paymentStatus').doc(monthYearKey);

        // Check if status exists, if not set to unpaid
        final doc = await statusRef.get();
        if (!doc.exists) {
          batch.set(statusRef, {
            'month': monthName,
            'year': year.toString(),
            'status': 'unpaid',
            'amount': 0,
            'paymentMethod': '',
            'timestamp': FieldValue.serverTimestamp(),
          });
        }
      }
    }

    await batch.commit();
    await fetchPaymentStatuses(donorId);
  }

  Future<void> fetchPaymentStatuses(String donorId) async {
    try {
      final currentYear = DateTime.now().year;
      final currentMonth = DateTime.now().month;
      final snapshot = await FirebaseFirestore.instance
          .collection('donors')
          .doc(donorId)
          .collection('paymentStatus')
          .where('year', isGreaterThanOrEqualTo: (currentYear - 2).toString())
          .orderBy('year', descending: true)
          .orderBy('month', descending: false)
          .get();

      _paymentStatuses = snapshot.docs.map((doc) {
        final data = doc.data();
        final monthIndex = months.indexOf(data['month']) + 1;
        final year = int.parse(data['year']);
        // Set future months to unpaid by default
        String status = data['status'];
        if (year == currentYear && monthIndex > currentMonth) {
          status = 'unpaid';
        }
        return MonthlyStatus(
          userName: _selectedDonor ?? 'Unknown',
          month: data['month'],
          year: data['year'],
          status: status,
        );
      }).toList();
      notifyListeners();
    } catch (e) {
      print('Error fetching payment statuses: $e');
    }
  }

  Future<void> recordPayment(String donorId) async {
    // Validate fields based on mode
    if (_isMultiMonthMode) {
      if (_selectedMonths.isEmpty ||
          _selectedYear == null ||
          _selectedPayment == null ||
          amountController.text.isEmpty) {
        throw Exception('Please fill all required fields');
      }
    } else {
      if (_selectedMonth == null ||
          _selectedYear == null ||
          _selectedPayment == null ||
          amountController.text.isEmpty) {
        throw Exception('Please fill all required fields');
      }
    }

    final amount = int.tryParse(amountController.text);
    if (amount == null || amount <= 0) {
      throw Exception('Please enter a valid amount');
    }

    final donorRef =
        FirebaseFirestore.instance.collection('donors').doc(donorId);
    
    // Get months to process
    List<String> monthsToProcess = _isMultiMonthMode ? _selectedMonths : [_selectedMonth!];
    
    // Check for existing payments first
    List<String> existingPayments = [];
    for (String month in monthsToProcess) {
      final monthYearKey = '$month-$_selectedYear';
      final statusRef = donorRef.collection('paymentStatus').doc(monthYearKey);
      final existingPayment = await statusRef.get();
      if (existingPayment.exists && existingPayment.data()?['status'] == 'paid') {
        existingPayments.add('$month $_selectedYear');
      }
    }
    
    if (existingPayments.isNotEmpty) {
      throw Exception(
          'Payment already exists for: ${existingPayments.join(', ')}');
    }

    // Record payments for all selected months
    WriteBatch batch = FirebaseFirestore.instance.batch();
    
    // Fetch donor info for the top-level donation record
    final donorDoc = await donorRef.get();
    final donorData = donorDoc.data() ?? {};
    final donorName = donorData['name'] ?? 'Unknown';
    final imageUrl = donorData['imageUrl'];
    
    final totalAmount = (amount * monthsToProcess.length).toDouble();

    // Create a top-level donation record for history and dashboard
    final donationDocId = FirebaseFirestore.instance.collection('donations').doc().id;
    final donationRef = FirebaseFirestore.instance.collection('donations').doc(donationDocId);
    
    batch.set(donationRef, {
      'donorId': donorId,
      'name': donorName,
      'amount': totalAmount,
      'method': _selectedPayment,
      'month': _isMultiMonthMode ? _selectedMonths.first : _selectedMonth,
      'year': _selectedYear,
      'status': 'paid',
      'monthsList': monthsToProcess,
      'date': DateFormat('dd MMM yyyy, hh:mm a').format(DateTime.now()),
      'timestamp': FieldValue.serverTimestamp(),
      'imageUrl': imageUrl,
    });

    for (int i = 0; i < monthsToProcess.length; i++) {
      final month = monthsToProcess[i];
      final monthYearKey = '$month-$_selectedYear';
      final statusRef = donorRef.collection('paymentStatus').doc(monthYearKey);
      
      final Map<String, dynamic> statusData = {
        'month': month,
        'year': _selectedYear,
        'status': 'paid',
        'amount': amount, // Individual month amount for stats
        'paymentMethod': _selectedPayment,
        'timestamp': FieldValue.serverTimestamp(),
        'donationId': donationDocId,
      };
      
      if (i == 0) {
        // Main entry for history consolidation
        statusData['isMainEntry'] = true;
        statusData['totalDonationAmount'] = totalAmount;
        statusData['monthsList'] = monthsToProcess;
      } else {
        // Subsidiary entry to be hidden from consolidated history
        statusData['hideFromHistory'] = true;
      }
      
      batch.set(statusRef, statusData, SetOptions(merge: true));
    }
    
    await batch.commit();
    await fetchPaymentStatuses(donorId);
  }

  void clearFields() {
    amountController.clear();
    donorController.clear();
    _selectedMonth = null;
    _selectedPayment = null;
    _selectedDonor = null;
    _selectedYear = DateTime.now().year.toString();
    _paymentStatuses = [];
    _selectedMonths.clear();
    _isMultiMonthMode = false;
    notifyListeners();
  }
}

class PaymentsPage extends StatefulWidget {
  const PaymentsPage({super.key});

  @override
  State<PaymentsPage> createState() => _PaymentsPageState();
}

class _PaymentsPageState extends State<PaymentsPage> {
  final List<String> paymentMethods = ["Cash", "Account"];
  bool _isLoading = false;
  final LocalDatabaseService _localDb = LocalDatabaseService();
  late Stream<List<Donation>> _recentDonationsStream;

  void _showProcessingDialog(String message) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => Dialog(
        backgroundColor: Theme.of(context).cardColor,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: Container(
          padding: const EdgeInsets.all(24.0),
          constraints: const BoxConstraints(maxWidth: 300),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(Color(0xff1BA3A1)),
                strokeWidth: 3,
              ),
              const SizedBox(height: 24),
              Text(
                message,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: Colors.grey[800],
                  fontFamily: 'Inter',
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Please wait while we process your request',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey[600],
                  fontFamily: 'Inter',
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  void initState() {
    super.initState();
    _recentDonationsStream = _localDb.watchDonations();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      try {
        await Provider.of<PaymentsPageProvider>(context, listen: false)
            .fetchDonors();
      } catch (e) {
        _showErrorDialog('Failed to load donors: $e');
      }
    });
  }

  void _showErrorDialog(String message) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        backgroundColor: Theme.of(context).cardColor,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        contentPadding: const EdgeInsets.fromLTRB(24, 20, 24, 0),
        actionsPadding: const EdgeInsets.fromLTRB(24, 16, 24, 20),
        title: const Text(
          'Error',
          textAlign: TextAlign.start,
          style: TextStyle(
            fontFamily: "Inter",
            fontSize: 20,
            fontWeight: FontWeight.w600,
            color: Color(0xFF212121),
            height: 1.3,
          ),
        ),
        content: Text(
          message,
          textAlign: TextAlign.start,
          style: const TextStyle(
            fontFamily: "Inter",
            fontWeight: FontWeight.w400,
            fontSize: 14,
            color: Color(0xFF757575),
            height: 1.5,
          ),
        ),
        actions: [
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 12),
                backgroundColor: const Color(0xff1BA3A1),
                foregroundColor: Colors.white,
                elevation: 0,
                shadowColor: Colors.transparent,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              onPressed: () => Navigator.pop(context),
              child: const Text(
                'OK',
                style: TextStyle(
                  fontFamily: "Inter",
                  fontWeight: FontWeight.w600,
                  fontSize: 14,
                  letterSpacing: 0.2,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showSuccessDialog() {
    final provider = Provider.of<PaymentsPageProvider>(context, listen: false);
    final monthCount = provider.isMultiMonthMode ? provider.selectedMonths.length : 1;
    final message = monthCount > 1 
        ? 'Payment recorded successfully for $monthCount months!'
        : 'Payment recorded successfully!';
    
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        backgroundColor: Theme.of(context).cardColor,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        contentPadding: const EdgeInsets.fromLTRB(24, 20, 24, 0),
        actionsPadding: const EdgeInsets.fromLTRB(24, 16, 24, 20),
        title: const Text(
          'Success',
          textAlign: TextAlign.start,
          style: TextStyle(
            fontFamily: "Inter",
            fontSize: 20,
            fontWeight: FontWeight.w600,
            color: Color(0xFF212121),
            height: 1.3,
          ),
        ),
        content: Text(
          message,
          textAlign: TextAlign.start,
          style: const TextStyle(
            fontFamily: "Inter",
            fontWeight: FontWeight.w400,
            fontSize: 14,
            color: Color(0xFF757575),
            height: 1.5,
          ),
        ),
        actions: [
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 12),
                backgroundColor: const Color(0xff1BA3A1),
                foregroundColor: Colors.white,
                elevation: 0,
                shadowColor: Colors.transparent,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              onPressed: () => Navigator.pop(context),
              child: const Text(
                'OK',
                style: TextStyle(
                  fontFamily: "Inter",
                  fontWeight: FontWeight.w600,
                  fontSize: 14,
                  letterSpacing: 0.2,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showAlreadyAddedDialog(String month, String year) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        backgroundColor: Theme.of(context).cardColor,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        contentPadding: const EdgeInsets.fromLTRB(24, 20, 24, 0),
        actionsPadding: const EdgeInsets.fromLTRB(24, 16, 24, 20),
        title: const Text(
          'Payment Already Added',
          textAlign: TextAlign.start,
          style: TextStyle(
            fontFamily: "Inter",
            fontSize: 20,
            fontWeight: FontWeight.w600,
            color: Color(0xFF212121),
            height: 1.3,
          ),
        ),
        content: Text(
          'A payment has already been recorded for $month $year.',
          textAlign: TextAlign.start,
          style: const TextStyle(
            fontFamily: "Inter",
            fontWeight: FontWeight.w400,
            fontSize: 14,
            color: Color(0xFF757575),
            height: 1.5,
          ),
        ),
        actions: [
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 12),
                backgroundColor: const Color(0xff1BA3A1),
                foregroundColor: Colors.white,
                elevation: 0,
                shadowColor: Colors.transparent,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              onPressed: () => Navigator.pop(context),
              child: const Text(
                'OK',
                style: TextStyle(
                  fontFamily: "Inter",
                  fontWeight: FontWeight.w600,
                  fontSize: 14,
                  letterSpacing: 0.2,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _recordPayment(String donorId) async {
    setState(() => _isLoading = true);
    // Show the same styled modal loading dialog used in yearly PDF generation
    _showProcessingDialog('Recording payment...');
    try {
      await Provider.of<PaymentsPageProvider>(context, listen: false)
          .recordPayment(donorId);
      
      // Trigger immediate sync to update local database
      await _localDb.syncWithFirestore();
      
      // Dismiss loading before showing success UI
      Navigator.of(context, rootNavigator: true).pop();
      // Clear form fields after successful submission
      Provider.of<PaymentsPageProvider>(context, listen: false).clearFields();
      
      _showSuccessDialog();
    } catch (e) {
      // Dismiss loading before showing error UI
      Navigator.of(context, rootNavigator: true).pop();
      if (e.toString().contains('Payment already added')) {
        final provider = Provider.of<PaymentsPageProvider>(context, listen: false);
        _showAlreadyAddedDialog(provider.selectedMonth ?? 'Unknown',
            provider.selectedYear ?? 'Unknown');
      } else {
        _showErrorDialog(e.toString());
      }
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<PaymentsPageProvider>(context);

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: SingleChildScrollView(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  children: [
                    const Center(
                      child: Text(
                        'Record Payment',
                        style: TextStyle(
                            fontWeight: FontWeight.w600, fontSize: 16),
                      ),
                    ),
                    const SizedBox(height: 5),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Select Donor',
                          style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 4),
                        TypeAheadField<String>(
                          controller: provider.donorController,
                          builder: (context, controller, focusNode) {
                            return TextFormField(
                              controller: controller,
                              focusNode: focusNode,
                              style: TextStyle(
                                fontSize: 14, 
                                color: Theme.of(context).brightness == Brightness.dark ? Colors.white : Colors.black87
                              ),
                              decoration: InputDecoration(
                                hintText: "Select donor...",
                                hintStyle: const TextStyle(fontSize: 12, color: Color(0xffA7A4AD)),
                                suffixIcon: provider.selectedDonor != null ? IconButton(
                                  icon: const Icon(Icons.clear, size: 16),
                                  onPressed: () {
                                    provider.donorController.clear();
                                    provider.setSelectedDonor(null);
                                    focusNode.unfocus();
                                  },
                                ) : const Icon(Icons.arrow_drop_down, color: Color(0xFF1BA3A1)),
                                contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                enabledBorder: OutlineInputBorder(
                                  borderSide: const BorderSide(color: Color(0xFF1BA3A1), width: 1.0),
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                focusedBorder: OutlineInputBorder(
                                  borderSide: const BorderSide(color: Color(0xFF1BA3A1), width: 2.0),
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                filled: Theme.of(context).brightness == Brightness.dark,
                                fillColor: Theme.of(context).brightness == Brightness.dark ? const Color(0xFF1E1E1E) : Colors.white,
                              ),
                              onChanged: (value) {
                                if (value.isEmpty) {
                                  provider.setSelectedDonor(null);
                                }
                              },
                            );
                          },
                          suggestionsCallback: (pattern) async {
                            return provider.donors
                                .map((donor) => donor['name'] as String)
                                .where((name) => name.toLowerCase().contains(pattern.toLowerCase()))
                                .toList();
                          },
                          itemBuilder: (context, suggestion) {
                            final donor = provider.donors.firstWhere((d) => d['name'] == suggestion, orElse: () => {});
                            final imageUrl = donor['imageUrl'] as String?;
                            
                            return ListTile(
                              leading: CircleAvatar(
                                radius: 16,
                                backgroundColor: const Color(0xFF1BA3A1).withOpacity(0.1),
                                backgroundImage: imageUrl != null && imageUrl.isNotEmpty 
                                    ? NetworkImage(imageUrl) 
                                    : null,
                                child: imageUrl == null || imageUrl.isEmpty 
                                    ? Text(
                                        suggestion.isNotEmpty ? suggestion[0].toUpperCase() : '?',
                                        style: const TextStyle(
                                          color: Color(0xFF1BA3A1),
                                          fontSize: 14,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      )
                                    : null,
                              ),
                              title: Text(
                                suggestion,
                                style: TextStyle(
                                  fontSize: 14,
                                  color: Theme.of(context).brightness == Brightness.dark ? Colors.white : Colors.black87,
                                  fontWeight: FontWeight.w500,
                                  fontFamily: "Inter",
                                ),
                              ),
                            );},
                          onSelected: (suggestion) {
                            provider.setSelectedDonor(suggestion);
                            FocusScope.of(context).unfocus();
                          },
                          decorationBuilder: (context, child) {
                            return ConstrainedBox(
                              constraints: const BoxConstraints(maxHeight: 250),
                              child: Material(
                                type: MaterialType.card,
                                elevation: 4,
                                color: Theme.of(context).brightness == Brightness.dark ? const Color(0xFF1E1E1E) : Colors.white,
                                borderRadius: BorderRadius.circular(8),
                                clipBehavior: Clip.antiAlias,
                                child: child,
                              ),
                            );
                          },
                          emptyBuilder: (context) {
                            return Padding(
                              padding: const EdgeInsets.all(16.0),
                              child: Text(
                                'No donors found',
                                style: TextStyle(
                                  color: Theme.of(context).brightness == Brightness.dark ? Colors.white70 : Colors.black54,
                                  fontSize: 14,
                                  fontFamily: "Inter",
                                ),
                              ),
                            );
                          },
                        ),
                        const SizedBox(height: 10),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text(
                              'Select Month(s)',
                              style: TextStyle(
                                  fontSize: 10,
                                  color: Colors.black,
                                  fontWeight: FontWeight.bold),
                            ),
                            Row(
                              children: [
                                Text(
                                  'Multi-month',
                                  style: TextStyle(
                                    fontSize: 9,
                                    color: Colors.grey[600],
                                    fontWeight: FontWeight.w400,
                                  ),
                                ),
                                const SizedBox(width: 4),
                                Transform.scale(
                                  scale: 0.8,
                                  child: Switch(
                                    value: provider.isMultiMonthMode,
                                    onChanged: (value) {
                                      provider.toggleMultiMonthMode();
                                    },
                                    activeColor: const Color(0xFF1BA3A1),
                                    materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        if (!provider.isMultiMonthMode)
                          DropdownButtonFormField<String>(
                            decoration: InputDecoration(
                              labelText: "January",
                              labelStyle: TextStyle(
                                  color: Colors.grey.shade500,
                                  fontWeight: FontWeight.w400,
                                  fontSize: 12),
                              floatingLabelBehavior: FloatingLabelBehavior.never,
                              enabledBorder: OutlineInputBorder(
                                borderSide: const BorderSide(
                                    color: Color(0xFF1BA3A1), width: 1.0),
                                borderRadius: BorderRadius.circular(4),
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderSide: const BorderSide(
                                    color: Color(0xFF1BA3A1), width: 1.0),
                                borderRadius: BorderRadius.circular(4),
                              ),
                            ),
                            value: provider.selectedMonth,
                            items: provider.months.map((String month) {
                              return DropdownMenuItem<String>(
                                value: month,
                                child: Text(
                                  month,
                                  style: const TextStyle(fontSize: 12),
                                ),
                              );
                            }).toList(),
                            onChanged: (String? newValue) {
                              provider.setSelectedMonth(newValue);
                            },
                          ),
                        if (provider.isMultiMonthMode)
                          Column(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  border: Border.all(
                                    color: const Color(0xFF1BA3A1),
                                    width: 1.0,
                                  ),
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                      children: [
                                        Text(
                                          provider.selectedMonths.isEmpty
                                              ? 'Select months'
                                              : '${provider.selectedMonths.length} month(s) selected',
                                          style: TextStyle(
                                            fontSize: 12,
                                            color: provider.selectedMonths.isEmpty
                                                ? Colors.grey.shade500
                                                : Colors.black87,
                                          ),
                                        ),
                                        if (provider.selectedMonths.isNotEmpty)
                                          GestureDetector(
                                            onTap: () => provider.clearSelectedMonths(),
                                            child: Text(
                                              'Clear',
                                              style: TextStyle(
                                                fontSize: 10,
                                                color: const Color(0xFF1BA3A1),
                                                fontWeight: FontWeight.w500,
                                              ),
                                            ),
                                          ),
                                      ],
                                    ),
                                    const SizedBox(height: 8),
                                    Wrap(
                                      spacing: 6,
                                      runSpacing: 6,
                                      children: provider.months.map((month) {
                                        final isSelected = provider.selectedMonths.contains(month);
                                        return GestureDetector(
                                          onTap: () => provider.setSelectedMonth(month),
                                          child: Container(
                                            padding: const EdgeInsets.symmetric(
                                              horizontal: 12,
                                              vertical: 6,
                                            ),
                                            decoration: BoxDecoration(
                                              color: isSelected
                                                  ? const Color(0xFF1BA3A1)
                                                  : Colors.grey[100],
                                              borderRadius: BorderRadius.circular(16),
                                              border: Border.all(
                                                color: isSelected
                                                    ? const Color(0xFF1BA3A1)
                                                    : Colors.grey[300]!,
                                                width: 1,
                                              ),
                                            ),
                                            child: Text(
                                              month.substring(0, 3), // Show abbreviated month
                                              style: TextStyle(
                                                fontSize: 10,
                                                color: isSelected
                                                    ? Colors.white
                                                    : Colors.grey[700],
                                                fontWeight: isSelected
                                                    ? FontWeight.w600
                                                    : FontWeight.w400,
                                              ),
                                            ),
                                          ),
                                        );
                                      }).toList(),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        const SizedBox(height: 10),
                        const Text(
                          'Select Year',
                          style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 4),
                        DropdownButtonFormField<String>(
                          decoration: InputDecoration(
                            labelText: DateTime.now().year.toString(),
                            labelStyle: TextStyle(
                                color: Colors.grey.shade500,
                                fontWeight: FontWeight.w400,
                                fontSize: 12),
                            floatingLabelBehavior: FloatingLabelBehavior.never,
                            enabledBorder: OutlineInputBorder(
                              borderSide: const BorderSide(
                                  color: Color(0xFF1BA3A1), width: 1.0),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderSide: const BorderSide(
                                  color: Color(0xFF1BA3A1), width: 1.0),
                              borderRadius: BorderRadius.circular(4),
                            ),
                          ),
                          value: provider.selectedYear,
                          items: provider.years.map((String year) {
                            return DropdownMenuItem<String>(
                              value: year,
                              child: Text(
                                year,
                                style: const TextStyle(fontSize: 12),
                              ),
                            );
                          }).toList(),
                          onChanged: (String? newValue) {
                            provider.setSelectedYear(newValue);
                          },
                        ),
                        const SizedBox(height: 10),
                        const Text(
                          'Amount',
                          style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 4),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            SizedBox(
                              width: MediaQuery.of(context).size.width * .45,
                              child: TextFormField(
                                controller: provider.amountController,
                                keyboardType: TextInputType.number,
                                decoration: InputDecoration(
                                  hintText: '500',
                                  hintStyle: const TextStyle(
                                      fontSize: 12, color: Color(0xffA7A4AD)),
                                  enabledBorder: OutlineInputBorder(
                                    borderSide: const BorderSide(
                                        color: Color(0xFF1BA3A1), width: 1.0),
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                  focusedBorder: OutlineInputBorder(
                                    borderSide: const BorderSide(
                                        color: Color(0xFF1BA3A1), width: 2.0),
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                ),
                              ),
                            ),
                            Container(
                              decoration: BoxDecoration(
                                color: provider.selectedPayment == null
                                    ? const Color(0xff29B6F6)
                                    : Colors.white,
                                borderRadius: BorderRadius.circular(4),
                                border: Border.all(
                                    color: const Color(0xff1BA3A1), width: 1.0),
                              ),
                              width: MediaQuery.of(context).size.width * .45,
                              height: 60.5,
                              child: Center(
                                child: DropdownButton<String>(
                                  elevation: 0,
                                  hint: const Padding(
                                    padding: EdgeInsets.all(8.0),
                                    child: Text(
                                      "Payment Method",
                                      style: TextStyle(
                                          fontWeight: FontWeight.w600,
                                          fontSize: 12,
                                          color: Colors.white),
                                    ),
                                  ),
                                  icon: Padding(
                                    padding: const EdgeInsets.all(8.0),
                                    child: Icon(
                                      Icons.arrow_drop_down_sharp,
                                      color: provider.selectedPayment == null
                                          ? const Color(0xffFFFFFF)
                                          : Colors.grey.shade700,
                                    ),
                                  ),
                                  dropdownColor: Theme.of(context).cardColor,
                                  underline: Container(
                                      height: 0,
                                      color: const Color(0xff1BA3A1)),
                                  isExpanded: true,
                                  value: provider.selectedPayment,
                                  items: paymentMethods.map((String method) {
                                    return DropdownMenuItem<String>(
                                      value: method,
                                      child: Padding(
                                        padding: const EdgeInsets.all(8.0),
                                        child: Text(method,
                                            style:
                                                const TextStyle(fontSize: 12)),
                                      ),
                                    );
                                  }).toList(),
                                  onChanged: (String? newValue) {
                                    provider.setSelectedPayment(newValue);
                                  },
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 10),
                        SizedBox(
                          width: MediaQuery.sizeOf(context).width,
                          height: 50,
                          child: ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              foregroundColor: Colors.white,
                              backgroundColor: const Color(0xff1BA3A1),
                              elevation: 0.0,
                              shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(4)),
                            ),
                            onPressed: _isLoading
                                ? null
                                : () {
                                    if (provider.selectedDonor == null) {
                                      _showErrorDialog('Please select a donor');
                                      return;
                                    }
                                    final donor = provider.donors.firstWhere(
                                      (d) =>
                                          d['name'] == provider.selectedDonor,
                                    );
                                    _recordPayment(donor['id']);
                                  },
                            child: const Text(
                              'Submit',
                              style: TextStyle(
                                  fontWeight: FontWeight.w600, fontSize: 14),
                            ),
                          ),
                        ),
                        const SizedBox(height: 12),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text(
                              "Recent Donations",
                              style: TextStyle(
                                fontSize: 16,
                                fontFamily: "Inter",
                                fontWeight: FontWeight.w600,
                                color: Color(0xff1BA3A1),
                              ),
                            ),
                            TextButton(
                              onPressed: () {
                                Navigator.push(
                                  context,
                                  SlidingPageTransitionRL(page: AllDonationsPage()),
                                );
                              },
                              child: Text(
                                "View More",
                                style: TextStyle(
                                  fontSize: 10,
                                  fontFamily: "Inter",
                                  fontWeight: FontWeight.w400,
                                  decoration: TextDecoration.underline,decorationColor: Colors.black,
                                  color: Color(0xff0B190C),
                                ),
                              ),
                            ),
                          ],
                        ),
                        SizedBox(
                          height: 300,
                          child: StreamBuilder<List<Donation>>(
                            stream: _recentDonationsStream,
                            builder: (context, snapshot) {
                              if (snapshot.connectionState == ConnectionState.waiting) {
                                return PaymentsFormShimmer();
                              }
                              if (snapshot.hasError) {
                                return Center(child: Text('Error: ${snapshot.error}'));
                              }

                              final allDonations = snapshot.data ?? [];
                              final recentDonations = allDonations
                                  .where((d) => d.status == 'paid' && d.hideFromHistory != true)
                                  .take(10)
                                  .toList();

                              if (recentDonations.isEmpty) {
                                return Shimmer.fromColors(
                                  baseColor: const Color(0xFFE0E0E0),
                                  highlightColor: const Color(0xFFF5F5F5),
                                  child: ListView.builder(
                                    itemCount: 6,
                                    itemBuilder: (context, index) => Container(
                                      margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
                                      height: 64,
                                      decoration: BoxDecoration(
                                        color: Colors.white,
                                        borderRadius: BorderRadius.circular(8),
                                        border: Border.all(color: Colors.grey[200]!),
                                      ),
                                    ),
                                  ),
                                );
                              }

                              return RefreshIndicator(
                                onRefresh: () async {
                                  try {
                                    await _localDb.syncWithFirestore();
                                  } catch (e) {
                                    debugPrint('PaymentsPage refresh error: $e');
                                  }
                                },
                                child: ListView.builder(
                                  physics: const AlwaysScrollableScrollPhysics(),
                                  itemCount: recentDonations.length,
                                  itemBuilder: (context, index) {
                                    final donation = recentDonations[index];
                                    final formattedDate = donation.date.isNotEmpty ? '${donation.date} • ' : '';
                                    final monthYear = donation.monthsList != null && donation.monthsList!.isNotEmpty
                                        ? MonthFormatter.formatMonthLong(donation.monthsList!, donation.year)
                                        : '${donation.month} ${donation.year}';

                                    return ListTile(
                                      leading: SizedBox(
                                        width: 40,
                                        height: 40,
                                        child: ClipOval(
                                          child: Builder(
                                            builder: (context) {
                                              final effectiveUrl = (donation.imageUrl ?? '').trim();
                                              if (effectiveUrl.isEmpty) {
                                                return Container(
                                                  color: const Color(0xff1BA3A1),
                                                  child: Center(
                                                    child: Text(
                                                      donation.name.isNotEmpty ? donation.name[0].toUpperCase() : '',
                                                      style: const TextStyle(
                                                        fontSize: 16,
                                                        fontWeight: FontWeight.bold,
                                                        color: Colors.white,
                                                      ),
                                                    ),
                                                  ),
                                                );
                                              }

                                              return FutureBuilder<ImageProvider?>(
                                                future: ImageCacheService().getImageProvider(effectiveUrl),
                                                builder: (context, snapshot) {
                                                  if (snapshot.connectionState == ConnectionState.waiting) {
                                                    return Shimmer.fromColors(
                                                      baseColor: const Color(0xFFE0E0E0),
                                                      highlightColor: const Color(0xFFF5F5F5),
                                                      child: Container(color: Colors.white),
                                                    );
                                                  }

                                                  if (snapshot.hasData && snapshot.data != null) {
                                                    return Image(
                                                      image: snapshot.data!,
                                                      fit: BoxFit.cover,
                                                      frameBuilder: (context, child, frame, wasSynchronouslyLoaded) {
                                                        if (wasSynchronouslyLoaded) return child;
                                                        return AnimatedOpacity(
                                                          opacity: frame == null ? 0 : 1,
                                                          duration: const Duration(milliseconds: 300),
                                                          curve: Curves.easeInOut,
                                                          child: child,
                                                        );
                                                      },
                                                      errorBuilder: (context, error, stackTrace) {
                                                        return Container(
                                                          color: const Color(0xff1BA3A1),
                                                          child: Center(
                                                            child: Text(
                                                              donation.name.isNotEmpty ? donation.name[0].toUpperCase() : '',
                                                              style: const TextStyle(
                                                                fontSize: 16,
                                                                fontWeight: FontWeight.bold,
                                                                color: Colors.white,
                                                              ),
                                                            ),
                                                          ),
                                                        );
                                                      },
                                                    );
                                                  }

                                                  return Container(
                                                    color: const Color(0xff1BA3A1),
                                                    child: Center(
                                                      child: Text(
                                                        donation.name.isNotEmpty ? donation.name[0].toUpperCase() : '',
                                                        style: const TextStyle(
                                                          fontSize: 16,
                                                          fontWeight: FontWeight.bold,
                                                          color: Colors.white,
                                                        ),
                                                      ),
                                                    ),
                                                  );
                                                },
                                              );
                                            },
                                          ),
                                        ),
                                      ),
                                      title: Text(
                                        donation.name,
                                        style: const TextStyle(
                                          fontSize: 14,
                                          fontFamily: "Inter",
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                      subtitle: Text(
                                        '$formattedDate$monthYear',
                                        style: const TextStyle(
                                          fontSize: 10,
                                          fontFamily: "Inter",
                                          fontWeight: FontWeight.w400,
                                          color: Color(0xff817D8A),
                                        ),
                                      ),
                                      trailing: Column(
                                        crossAxisAlignment: CrossAxisAlignment.end,
                                        mainAxisAlignment: MainAxisAlignment.center,
                                        children: [
                                          Text(
                                            "₹${donation.totalDonationAmount ?? donation.amount}",
                                            style: const TextStyle(
                                              fontSize: 16,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                          const SizedBox(height: 2),
                                          Text(
                                            donation.method,
                                            style: const TextStyle(
                                              fontSize: 10,
                                              fontFamily: "Inter",
                                              fontWeight: FontWeight.w400,
                                              color: Color(0xff817D8A),
                                            ),
                                          ),
                                        ],
                                      ),
                                    );
                                  },
                                ),
                              );
                            },
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
    );
  }
}
