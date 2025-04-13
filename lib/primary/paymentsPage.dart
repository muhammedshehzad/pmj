import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import '../assets/custom widgets/transition.dart';
import '../secondary/all_donations.dart';

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

class PaymentProvider extends ChangeNotifier {
  String? _selectedMonth;
  String? _selectedPayment;
  String? _selectedDonor;
  String? _selectedYear;
  List<Map<String, dynamic>> _donors = [];
  List<MonthlyStatus> _paymentStatuses = [];

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

  String? get selectedMonth => _selectedMonth;

  String? get selectedPayment => _selectedPayment;

  String? get selectedDonor => _selectedDonor;

  String? get selectedYear => _selectedYear;

  List<Map<String, dynamic>> get donors => _donors;

  List<MonthlyStatus> get paymentStatuses => _paymentStatuses;

  PaymentProvider() {
    _selectedYear = DateTime.now().year.toString();
    initializePaymentStatuses();
  }

  void setSelectedMonth(String? month) {
    _selectedMonth = month;
    notifyListeners();
  }

  void setSelectedPayment(String? paymentMethod) {
    _selectedPayment = paymentMethod;
    notifyListeners();
  }

  void setSelectedDonor(String? donorName) {
    _selectedDonor = donorName;
    if (donorName != null) {
      final donor = _donors.firstWhere((d) => d['name'] == donorName,
          orElse: () => {'amount': 0});
      amountController.text = donor['amount'].toString();
      fetchPaymentStatuses(donor['id']);
    } else {
      amountController.clear();
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
          'id': doc.id,
        };
      }).toList();
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
    if (_selectedMonth == null ||
        _selectedYear == null ||
        _selectedPayment == null ||
        amountController.text.isEmpty) {
      throw Exception('Please fill all required fields');
    }

    final amount = int.tryParse(amountController.text);
    if (amount == null || amount <= 0) {
      throw Exception('Please enter a valid amount');
    }

    final donorRef =
        FirebaseFirestore.instance.collection('donors').doc(donorId);
    final monthYearKey = '$_selectedMonth-$_selectedYear';
    final statusRef = donorRef.collection('paymentStatus').doc(monthYearKey);

    // Check if payment already exists
    final existingPayment = await statusRef.get();
    if (existingPayment.exists) {
      throw Exception(
          'Payment already added for $_selectedMonth $_selectedYear');
    }

    await statusRef.set({
      'month': _selectedMonth,
      'year': _selectedYear,
      'status': 'paid',
      'amount': amount,
      'paymentMethod': _selectedPayment,
      'timestamp': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));

    await fetchPaymentStatuses(donorId);
  }

  void clearFields() {
    amountController.clear();
    _selectedMonth = null;
    _selectedPayment = null;
    _selectedDonor = null;
    _selectedYear = DateTime.now().year.toString();
    _paymentStatuses = [];
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

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      setState(() => _isLoading = true);
      try {
        await Provider.of<PaymentProvider>(context, listen: false)
            .fetchDonors();
      } catch (e) {
        _showErrorDialog('Failed to load donors: $e');
      } finally {
        setState(() => _isLoading = false);
      }
    });
  }

  void _showErrorDialog(String message) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        content: Text(
          message,
          style: const TextStyle(
            fontFamily: "Inter",
            fontWeight: FontWeight.w400,
            fontSize: 12,
          ),
        ),
        actions: [
          Container(
            height: 26,
            width: 70,
            margin: const EdgeInsets.only(right: 4, bottom: 4),
            clipBehavior: Clip.hardEdge,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(8),
            ),
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                foregroundColor: Colors.white,
                backgroundColor: const Color(0xffF44336),
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(6),
                ),
              ),
              child: const Text(
                'OK',
                style: TextStyle(
                  fontFamily: "Inter",
                  fontWeight: FontWeight.w400,
                  fontSize: 9,
                ),
              ),
              onPressed: () => Navigator.pop(context),
            ),
          ),
        ],
      ),
    );
  }

  void _showSuccessDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        content: const Text(
          'Payment Recorded!',
          style: TextStyle(
            fontFamily: "Inter",
            fontWeight: FontWeight.w400,
            fontSize: 12,
          ),
        ),
        actions: [
          Container(
            height: 26,
            width: 49,
            margin: const EdgeInsets.only(right: 4, bottom: 4),
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                foregroundColor: Colors.white,
                backgroundColor: const Color(0xffF44336),
                elevation: 0,
              ),
              child: const Text(
                'OK',
                style: TextStyle(
                  fontFamily: "Inter",
                  fontWeight: FontWeight.w400,
                  fontSize: 11,
                ),
              ),
              onPressed: () {
                Navigator.pop(context);
                Provider.of<PaymentProvider>(context, listen: false)
                    .clearFields();
              },
            ),
          ),
        ],
      ),
    );
  }

  void _showAlreadyAddedDialog(String month, String year) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        content: Text(
          'Payment already added for $month $year',
          style: const TextStyle(
            fontFamily: "Inter",
            fontWeight: FontWeight.w400,
            fontSize: 12,
          ),
        ),
        actions: [
          Container(
            height: 26,
            width: 49,
            margin: const EdgeInsets.only(right: 4, bottom: 4),
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                foregroundColor: Colors.white,
                backgroundColor: const Color(0xffF44336),
                elevation: 0,
              ),
              child: const Text(
                'OK',
                style: TextStyle(
                  fontFamily: "Inter",
                  fontWeight: FontWeight.w400,
                  fontSize: 11,
                ),
              ),
              onPressed: () => Navigator.pop(context),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _recordPayment(String donorId) async {
    setState(() => _isLoading = true);
    try {
      await Provider.of<PaymentProvider>(context, listen: false)
          .recordPayment(donorId);
      _showSuccessDialog();
    } catch (e) {
      if (e.toString().contains('Payment already added')) {
        final provider = Provider.of<PaymentProvider>(context, listen: false);
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
    final provider = Provider.of<PaymentProvider>(context);

    return Scaffold(
      backgroundColor: Colors.white,
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
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
                              color: Colors.black,
                              fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 4),
                        DropdownButtonFormField<String>(
                          decoration: InputDecoration(
                            hintText: "Select a donor",
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
                          value: provider.selectedDonor,
                          items: provider.donors.map((donor) {
                            return DropdownMenuItem<String>(
                              value: donor['name'],
                              child: Text(
                                donor['name'],
                                style: const TextStyle(fontSize: 12),
                              ),
                            );
                          }).toList(),
                          onChanged: (String? newValue) {
                            provider.setSelectedDonor(newValue);
                          },
                        ),
                        const SizedBox(height: 10),
                        const Text(
                          'Select Month',
                          style: TextStyle(
                              fontSize: 10,
                              color: Colors.black,
                              fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 4),
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
                        const SizedBox(height: 10),
                        const Text(
                          'Select Year',
                          style: TextStyle(
                              fontSize: 10,
                              color: Colors.black,
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
                              color: Colors.black,
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
                                        color: Colors.white
                                      ),
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
                                  dropdownColor: Colors.white,
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
                            child: _isLoading
                                ? const CircularProgressIndicator(
                                    color: Colors.white)
                                : const Text(
                                    'Submit',
                                    style: TextStyle(
                                        fontWeight: FontWeight.w600,
                                        fontSize: 14),
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
                                  SlidingPageTransitionRL(
                                      page: AllDonationsPage()),
                                );
                              },
                              child: const Text(
                                "View More",
                                style: TextStyle(
                                  fontSize: 10,
                                  fontFamily: "Inter",
                                  fontWeight: FontWeight.w400,
                                  decoration: TextDecoration.underline,
                                  color: Color(0xff0B190C),
                                ),
                              ),
                            ),
                          ],
                        ),
                        SizedBox(
                          height: 300,
                          child: StreamBuilder<QuerySnapshot>(
                            stream: FirebaseFirestore.instance
                                .collectionGroup('paymentStatus')
                                .where('status', isEqualTo: 'paid')
                                .orderBy('timestamp', descending: true)
                                .limit(10)
                                .snapshots(),
                            builder: (context, snapshot) {
                              if (snapshot.connectionState ==
                                  ConnectionState.waiting) {
                                return const Center(
                                    child: CircularProgressIndicator());
                              }
                              if (snapshot.hasError) {
                                return Center(
                                    child: Text('Error: ${snapshot.error}'));
                              }
                              if (!snapshot.hasData ||
                                  snapshot.data!.docs.isEmpty) {
                                return const Center(
                                    child: Text('No recent donations found'));
                              }

                              final payments = snapshot.data!.docs;

                              return ListView.builder(
                                shrinkWrap: true,
                                physics: const BouncingScrollPhysics(),
                                itemCount: payments.length,
                                itemBuilder: (context, index) {
                                  final payment = payments[index].data()
                                      as Map<String, dynamic>;
                                  final donorId = payments[index]
                                      .reference
                                      .parent
                                      .parent
                                      ?.id;

                                  return FutureBuilder<DocumentSnapshot>(
                                    future: FirebaseFirestore.instance
                                        .collection('donors')
                                        .doc(donorId)
                                        .get(),
                                    builder: (context, donorSnapshot) {
                                      if (!donorSnapshot.hasData) {
                                        return const ListTile(
                                            title: Text('Loading...'));
                                      }

                                      final donorData = donorSnapshot.data!
                                          .data() as Map<String, dynamic>;
                                      final donorName =
                                          donorData['name'] ?? 'Unknown';
                                      final donorImage =
                                          donorData['imageUrl'] ??
                                              'https://via.placeholder.com/150';

                                      return ListTile(
                                        leading: CircleAvatar(
                                          backgroundImage:
                                              NetworkImage(donorImage),
                                          radius: 20,
                                        ),
                                        title: Text(
                                          donorName,
                                          style: const TextStyle(
                                            fontSize: 14,
                                            fontFamily: "Inter",
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                        subtitle: Text(
                                          "${payment['month']} ${payment['year']}",
                                          style: const TextStyle(
                                            fontSize: 10,
                                            fontFamily: "Inter",
                                            fontWeight: FontWeight.w400,
                                            color: Color(0xff817D8A),
                                          ),
                                        ),
                                        trailing: Padding(
                                          padding:
                                              const EdgeInsets.only(right: 1.0),
                                          child: Column(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.end,
                                            mainAxisAlignment:
                                                MainAxisAlignment.center,
                                            children: [
                                              Text(
                                                "₹${payment['amount'].toString()}",
                                                style: const TextStyle(
                                                  fontSize: 16,
                                                  fontFamily: "Inter",
                                                  fontWeight: FontWeight.w600,
                                                ),
                                              ),
                                              Padding(
                                                padding: const EdgeInsets.only(
                                                    top: 4.0),
                                                child: Text(
                                                  payment['paymentMethod'] ??
                                                      'Unknown',
                                                  style: const TextStyle(
                                                    fontSize: 10,
                                                    fontFamily: "Inter",
                                                    fontWeight: FontWeight.w400,
                                                    color: Color(0xff817D8A),
                                                  ),
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      );
                                    },
                                  );
                                },
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
