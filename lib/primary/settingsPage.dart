import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:pmj_application/assets/custom%20widgets/GPay.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart'; // For formatting dates
import 'package:pdf/pdf.dart'; // For PDF generation
import 'package:pdf/widgets.dart' as pw; // For PDF widgets
import 'package:path_provider/path_provider.dart'; // For file storage
import 'package:share_plus/share_plus.dart'; // For sharing the PDF
import 'dart:io';
import '../assets/custom widgets/logoutpopup.dart';
import '../assets/custom widgets/transition.dart'; // For file operations

class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key});

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  bool _isLoading = false;

  void _setLoading(bool value) {
    setState(() {
      _isLoading = value;
    });
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              children: [
                const Center(
                  child: Text(
                    'Reports',
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 16,
                      fontFamily: "Inter",
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                ReportsSection(
                  onLoadingChanged: _setLoading,
                ),
                const SizedBox(height: 8),
                GestureDetector(
                  onTap: () {
                    Navigator.push(
                        context,
                        SlidingPageTransitionRL(
                            page: const NotificationsPage()));
                  },
                  child: Container(
                    margin: const EdgeInsets.only(left: 2),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            SvgPicture.asset(
                              'lib/assets/images/notification.svg',
                              height: 32,
                              width: 32,
                            ),
                            const SizedBox(width: 12),
                            const Text(
                              "Notifications",
                              style: TextStyle(
                                fontWeight: FontWeight.w400,
                                fontSize: 14,
                                fontFamily: "Inter",
                              ),
                            ),
                          ],
                        ),
                        const Padding(
                          padding: EdgeInsets.only(left: 8.0),
                          child: Icon(
                            Icons.arrow_forward_ios,
                            size: 16,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                GestureDetector(
                  onTap: () {
                    Navigator.push(
                        context, SlidingPageTransitionRL(page: GPay()));
                  },
                  child: Container(
                    margin: const EdgeInsets.only(left: 2),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            SvgPicture.asset(
                              'lib/assets/images/scanner.svg',
                              height: 32,
                              width: 32,
                            ),
                            const SizedBox(width: 12),
                            const Text(
                              "Google Pay Scanner",
                              style: TextStyle(
                                fontWeight: FontWeight.w400,
                                fontSize: 14,
                                fontFamily: "Inter",
                              ),
                            ),
                          ],
                        ),
                        const Icon(
                          Icons.arrow_forward_ios,
                          size: 16,
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 250),
                const Center(
                  child: Text(
                    'App version 2.01',
                    style: TextStyle(
                      fontWeight: FontWeight.w400,
                      fontSize: 10,
                      fontFamily: "Inter",
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class NotificationsPage extends StatelessWidget {
  const NotificationsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(100),
        child: AppBar(
          elevation: 0,
          backgroundColor: const Color(0xff1BA3A1),
          automaticallyImplyLeading: false,
          flexibleSpace: Align(
            alignment: Alignment.bottomCenter,
            child: Padding(
              padding:
                  const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Padding(
                    padding: const EdgeInsets.only(bottom: 8.0),
                    child: GestureDetector(
                      onTap: () => Navigator.pop(context),
                      child: Image.asset(
                        'lib/assets/images/pmj white.png',
                        height: 50,
                      ),
                    ),
                  ),
                  Container(
                    height: 26,
                    width: 84,
                    child: ElevatedButton(
                      onPressed: () => showLogoutConfirmation(context),
                      style: ElevatedButton.styleFrom(
                        foregroundColor: Colors.black,
                        backgroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(2),
                        ),
                        elevation: 0,
                      ),
                      child: const Center(
                        child: Text(
                          'Logout',
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w600,
                            fontFamily: "Inter",
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
      body: Container(
        color: Colors.white,
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.start,
            children: [
              Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.05),
                      spreadRadius: 1,
                      blurRadius: 3,
                      offset: Offset(0, 2),
                    ),
                  ],
                ),
                child: ListTile(
                  leading: GestureDetector(
                    onTap: () {
                      Navigator.pop(context);
                    },
                    child: SvgPicture.asset(
                      'lib/assets/images/Back.svg',
                      height: 40,
                      width: 40,
                    ),
                  ),
                  title: Center(
                    child: Text(
                      'Notifications Page',
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 18,
                        color: Color(0xff1BA3A1),
                      ),
                    ),
                  ),
                  trailing: SvgPicture.asset(
                    'lib/assets/images/settingsnew.svg',
                    height: 40,
                    width: 40,
                  ),
                ),
              ),
              const SizedBox(height: 150),
              const Text(
                'Coming Soon',
                style: TextStyle(
                  fontFamily: "Inter",
                  fontWeight: FontWeight.w600,
                  fontSize: 20,
                  color: Colors.black87,
                ),
              ),
              const SizedBox(height: 12),
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 32),
                child: Text(
                  'Notifications will be available in the next version of the app.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontFamily: "Inter",
                    fontWeight: FontWeight.w400,
                    fontSize: 14,
                    color: Colors.black54,
                  ),
                ),
              ),
              const SizedBox(height: 24),
              const Text(
                'Coming in v2.1',
                style: TextStyle(
                  fontFamily: "Inter",
                  fontWeight: FontWeight.w500,
                  fontSize: 12,
                  color: Colors.black54,
                ),
              ),
              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
    );
  }
}

class ReportsSection extends StatefulWidget {
  final Function(bool) onLoadingChanged;

  const ReportsSection({super.key, required this.onLoadingChanged});

  @override
  State<ReportsSection> createState() => _ReportsSectionState();
}

class _ReportsSectionState extends State<ReportsSection> {
  late List<String> years;
  late List<String> months;
  final List<String> filterOptions = [
    "Payment received only",
    "Payments to be received",
    "All payments",
  ];
  List<String> peopleList = ['All People'];
  String selectedPerson = 'All People';
  late String selectedYear;
  late String selectedMonth;
  late String selectedFilter;
  bool _isLoading = false;
  bool useDateRange = false;
  DateTime? startDate;
  DateTime? endDate;
  bool useAdvancedFilters = false;

  @override
  void initState() {
    super.initState();
    final currentYear = DateTime.now().year;
    years = List.generate(
        currentYear - 2010 + 1, (index) => (2010 + index).toString());
    years.sort((a, b) => b.compareTo(a));
    months = [
      "Whole Year",
      "January",
      "February",
      "March",
      "April",
      "May",
      "June",
      "July",
      "August",
      "September",
      "October",
      "November",
      "December",
    ];
    selectedYear = currentYear.toString();
    selectedMonth = DateFormat('MMMM').format(DateTime.now());
    selectedFilter = filterOptions[0];
    final now = DateTime.now();
    startDate = DateTime(now.year, now.month, 1);
    endDate = DateTime(now.year, now.month + 1, 0);
    _fetchPeopleList();
  }

  Future<void> _fetchPeopleList() async {
    setState(() {
      widget.onLoadingChanged(true);
    });
    try {
      final querySnapshot =
          await FirebaseFirestore.instance.collection('donors').get();
      final uniquePeople = querySnapshot.docs
          .map((doc) => doc['name'] as String?)
          .where((name) => name != null && name.isNotEmpty)
          .toSet()
          .toList()
          .cast<String>();
      uniquePeople.sort();
      print('Fetched people: $uniquePeople'); // Debug log
      setState(() {
        peopleList = ['All People', ...uniquePeople];
        // Only reset selectedPerson if current value is invalid
        if (!peopleList.contains(selectedPerson)) {
          selectedPerson = 'All People';
        }
      });
      if (uniquePeople.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('No donors found in Firebase.'),
          ),
        );
      }
    } catch (e) {
      print('Error fetching people list: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to fetch people list: $e'),
          backgroundColor: Colors.red,
        ),
      );
      setState(() {
        peopleList = ['All People'];
        selectedPerson = 'All People';
      });
    } finally {
      setState(() {
        widget.onLoadingChanged(false);
      });
    }
  }

  Future<void> _selectDateRange(BuildContext context) async {
    final initialDateRange = DateTimeRange(
      start: startDate ?? DateTime.now(),
      end: endDate ?? DateTime.now().add(const Duration(days: 7)),
    );
    final DateTimeRange? pickedDateRange = await showDateRangePicker(
      context: context,
      initialDateRange: initialDateRange,
      firstDate: DateTime(2010),
      lastDate: DateTime(2030),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: Color(0xFF00A699),
              onPrimary: Colors.white,
              onSurface: Colors.black,
            ),
          ),
          child: child!,
        );
      },
    );
    if (pickedDateRange != null) {
      setState(() {
        startDate = pickedDateRange.start;
        endDate = pickedDateRange.end;
      });
    }
  }

  Future<List<Map<String, dynamic>>> _fetchPayments() async {
    widget.onLoadingChanged(true);
    try {
      final List<Map<String, dynamic>> payments = [];
      final donorSnapshot =
          await FirebaseFirestore.instance.collection('donors').get();
      final allDonors = donorSnapshot.docs
          .map((doc) =>
              {'id': doc.id, 'name': doc['name'] as String? ?? 'Unknown'})
          .toList();

      if (selectedPerson != 'All People') {
        // Filter for a specific person
        final donor = allDonors.firstWhere(
          (d) => d['name'] == selectedPerson,
          orElse: () => {'id': '', 'name': ''},
        );
        if (donor['id']!.isEmpty) {
          return [];
        }

        // Query paymentStatus for the donor
        Query<Map<String, dynamic>> query = FirebaseFirestore.instance
            .collection('donors')
            .doc(donor['id'])
            .collection('paymentStatus');

        // Apply date or month/year filter
        if (useDateRange && startDate != null && endDate != null) {
          final startTimestamp = Timestamp.fromDate(startDate!);
          final endTimestamp =
              Timestamp.fromDate(endDate!.add(const Duration(days: 1)));
          query = query
              .where('timestamp', isGreaterThanOrEqualTo: startTimestamp)
              .where('timestamp', isLessThan: endTimestamp);
        } else {
          query = query.where('year', isEqualTo: selectedYear);
          if (selectedMonth != "Whole Year") {
            query = query.where('month', isEqualTo: selectedMonth);
          }
        }

        // Fetch all relevant payments
        final snapshot = await query.get();

        // Add payments based on filter
        for (var doc in snapshot.docs) {
          final data = doc.data();
          if (selectedFilter == "Payment received only" &&
              data['status'] != 'paid') {
            continue;
          }
          if (selectedFilter == "Payments to be received" &&
              data['status'] != 'unpaid') {
            continue;
          }
          // For "All payments", include both paid and unpaid
          payments.add({
            'name': donor['name'],
            'amount': data['amount'],
            'paymentMethod': data['paymentMethod'],
            'month': data['month'],
            'year': data['year'],
            'timestamp': data['timestamp'],
            'status': data['status'],
          });
        }

        // Handle unpaid entries for specific filters
        if (!useDateRange && selectedMonth != "Whole Year") {
          if (selectedFilter == "Payments to be received" ||
              selectedFilter == "All payments") {
            final hasPaid = snapshot.docs.any((doc) =>
                doc['month'] == selectedMonth &&
                doc['year'] == selectedYear &&
                doc['status'] == 'paid');
            final hasUnpaid = snapshot.docs.any((doc) =>
                doc['month'] == selectedMonth &&
                doc['year'] == selectedYear &&
                doc['status'] == 'unpaid');
            if (!hasPaid && !hasUnpaid) {
              payments.add({
                'name': donor['name'],
                'amount': null,
                'paymentMethod': null,
                'month': selectedMonth,
                'year': selectedYear,
                'timestamp': null,
                'status': 'unpaid',
              });
            }
          }
        }

        // Handle "Whole Year" for "All payments" and "Payments to be received"
        if (!useDateRange &&
            selectedMonth == "Whole Year" &&
            (selectedFilter == "Payments to be received" ||
                selectedFilter == "All payments")) {
          const months = [
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
            'December',
          ];
          final paidMonths = snapshot.docs
              .where((doc) => doc['status'] == 'paid')
              .map((doc) => doc['month'] as String?)
              .toSet();
          final unpaidMonths = snapshot.docs
              .where((doc) => doc['status'] == 'unpaid')
              .map((doc) => doc['month'] as String?)
              .toSet();
          for (var month in months) {
            if (!paidMonths.contains(month) && !unpaidMonths.contains(month)) {
              payments.add({
                'name': donor['name'],
                'amount': null,
                'paymentMethod': null,
                'month': month,
                'year': selectedYear,
                'timestamp': null,
                'status': 'unpaid',
              });
            }
          }
        }
      } else {
        // Handle all donors
        for (var donor in allDonors) {
          // Query paymentStatus for the donor
          Query<Map<String, dynamic>> query = FirebaseFirestore.instance
              .collection('donors')
              .doc(donor['id'])
              .collection('paymentStatus');

          // Apply date or month/year filter
          if (useDateRange && startDate != null && endDate != null) {
            final startTimestamp = Timestamp.fromDate(startDate!);
            final endTimestamp =
                Timestamp.fromDate(endDate!.add(const Duration(days: 1)));
            query = query
                .where('timestamp', isGreaterThanOrEqualTo: startTimestamp)
                .where('timestamp', isLessThan: endTimestamp);
          } else {
            query = query.where('year', isEqualTo: selectedYear);
            if (selectedMonth != "Whole Year") {
              query = query.where('month', isEqualTo: selectedMonth);
            }
          }

          // Fetch all relevant payments
          final snapshot = await query.get();

          // Add payments based on filter
          for (var doc in snapshot.docs) {
            final data = doc.data();
            if (selectedFilter == "Payment received only" &&
                data['status'] != 'paid') {
              continue;
            }
            if (selectedFilter == "Payments to be received" &&
                data['status'] != 'unpaid') {
              continue;
            }
            // For "All payments", include both paid and unpaid
            payments.add({
              'name': donor['name'],
              'amount': data['amount'],
              'paymentMethod': data['paymentMethod'],
              'month': data['month'],
              'year': data['year'],
              'timestamp': data['timestamp'],
              'status': data['status'],
            });
          }

          // Handle unpaid entries for specific filters
          if (!useDateRange && selectedMonth != "Whole Year") {
            if (selectedFilter == "Payments to be received" ||
                selectedFilter == "All payments") {
              final hasPaid = snapshot.docs.any((doc) =>
                  doc['month'] == selectedMonth &&
                  doc['year'] == selectedYear &&
                  doc['status'] == 'paid');
              final hasUnpaid = snapshot.docs.any((doc) =>
                  doc['month'] == selectedMonth &&
                  doc['year'] == selectedYear &&
                  doc['status'] == 'unpaid');
              if (!hasPaid && !hasUnpaid) {
                payments.add({
                  'name': donor['name'],
                  'amount': null,
                  'paymentMethod': null,
                  'month': selectedMonth,
                  'year': selectedYear,
                  'timestamp': null,
                  'status': 'unpaid',
                });
              }
            }
          }

          // Handle "Whole Year" for "All payments" and "Payments to be received"
          if (!useDateRange &&
              selectedMonth == "Whole Year" &&
              (selectedFilter == "Payments to be received" ||
                  selectedFilter == "All payments")) {
            const months = [
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
              'December',
            ];
            final paidMonths = snapshot.docs
                .where((doc) => doc['status'] == 'paid')
                .map((doc) => doc['month'] as String?)
                .toSet();
            final unpaidMonths = snapshot.docs
                .where((doc) => doc['status'] == 'unpaid')
                .map((doc) => doc['month'] as String?)
                .toSet();
            for (var month in months) {
              if (!paidMonths.contains(month) &&
                  !unpaidMonths.contains(month)) {
                payments.add({
                  'name': donor['name'],
                  'amount': null,
                  'paymentMethod': null,
                  'month': month,
                  'year': selectedYear,
                  'timestamp': null,
                  'status': 'unpaid',
                });
              }
            }
          }
        }
      }

      return payments;
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error fetching payments: $e'),
          backgroundColor: Colors.red,
        ),
      );
      print(e);
      return [];
    } finally {
      widget.onLoadingChanged(false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Stack(
        children: [
          Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  TextButton(
                    onPressed: _isLoading ? null : _fetchPeopleList,
                    child: const Text(
                      'Refresh Users',
                      style: TextStyle(
                        fontSize: 12,
                        color: Color(0xFF00A699),
                        fontFamily: "Inter",
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  TextButton(
                    onPressed: () {
                      setState(() {
                        useAdvancedFilters = !useAdvancedFilters;
                      });
                    },
                    child: Text(
                      useAdvancedFilters
                          ? 'Use Simple Filters'
                          : 'Use Advanced Filters',
                      style: const TextStyle(
                        color: Color(0xFF00A699),
                        fontFamily: "Inter",
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              if (useAdvancedFilters)
                Container(
                  margin: const EdgeInsets.only(bottom: 16),
                  decoration: BoxDecoration(
                    color: const Color(0xffF2F2F3),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Row(
                    children: [
                      Checkbox(
                        value: useDateRange,
                        activeColor: const Color(0xFF00A699),
                        onChanged: (value) {
                          setState(() {
                            useDateRange = value ?? false;
                          });
                        },
                      ),
                      const Text(
                        'Use Date Range',
                        style: TextStyle(
                          fontFamily: "Inter",
                          fontWeight: FontWeight.w400,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
              if (useAdvancedFilters && useDateRange)
                GestureDetector(
                  onTap: () => _selectDateRange(context),
                  child: Container(
                    margin: const EdgeInsets.only(bottom: 16),
                    padding: const EdgeInsets.symmetric(
                        vertical: 12, horizontal: 16),
                    decoration: BoxDecoration(
                      color: const Color(0xffF2F2F3),
                      borderRadius: BorderRadius.circular(4),
                      border: Border.all(color: const Color(0xFFE0E0E0)),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          startDate != null && endDate != null
                              ? '${DateFormat('dd MMM yyyy').format(startDate!)} - ${DateFormat('dd MMM yyyy').format(endDate!)}'
                              : 'Select Date Range',
                          style: const TextStyle(
                            fontFamily: "Inter",
                            fontWeight: FontWeight.w400,
                            fontSize: 12,
                          ),
                        ),
                        const Icon(Icons.calendar_today, size: 16),
                      ],
                    ),
                  ),
                ),
              if (!useAdvancedFilters || !useDateRange)
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Container(
                        decoration: const BoxDecoration(
                          color: Color(0xffF2F2F3),
                          borderRadius: BorderRadius.all(Radius.circular(4)),
                        ),
                        child: DropdownButtonFormField<String>(
                          value: selectedYear,
                          isExpanded: true,
                          dropdownColor: Colors.white,
                          elevation: 1,
                          items: years.map((String year) {
                            return DropdownMenuItem<String>(
                              value: year,
                              child: Text(
                                year,
                                style: const TextStyle(
                                  fontFamily: "Inter",
                                  fontWeight: FontWeight.w400,
                                  fontSize: 12,
                                ),
                              ),
                            );
                          }).toList(),
                          onChanged: (String? newValue) {
                            setState(() {
                              selectedYear = newValue!;
                            });
                          },
                          decoration: const InputDecoration(
                            contentPadding:
                                EdgeInsets.symmetric(horizontal: 12),
                            border: InputBorder.none,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Container(
                        decoration: const BoxDecoration(
                          color: Color(0xffF2F2F3),
                          borderRadius: BorderRadius.all(Radius.circular(4)),
                        ),
                        child: DropdownButtonFormField<String>(
                          value: selectedMonth,
                          items: months.map((String month) {
                            return DropdownMenuItem<String>(
                              value: month,
                              child: Text(
                                month,
                                style: const TextStyle(
                                  fontFamily: "Inter",
                                  fontWeight: FontWeight.w400,
                                  fontSize: 12,
                                ),
                              ),
                            );
                          }).toList(),
                          onChanged: (String? newValue) {
                            setState(() {
                              selectedMonth = newValue!;
                            });
                          },
                          decoration: const InputDecoration(
                            border: InputBorder.none,
                            contentPadding:
                                EdgeInsets.symmetric(horizontal: 12),
                          ),
                          isExpanded: true,
                          dropdownColor: Colors.white,
                          elevation: 1,
                        ),
                      ),
                    ),
                  ],
                ),
              const SizedBox(height: 16),
              Container(
                decoration: const BoxDecoration(
                  color: Color(0xffF2F2F3),
                  borderRadius: BorderRadius.all(Radius.circular(4)),
                ),
                child: DropdownButtonFormField<String>(
                  value: selectedPerson,
                  items: peopleList.map((String person) {
                    return DropdownMenuItem<String>(
                      value: person,
                      child: Text(
                        person,
                        style: const TextStyle(
                          fontFamily: "Inter",
                          fontWeight: FontWeight.w400,
                          fontSize: 12,
                        ),
                      ),
                    );
                  }).toList(),
                  onChanged: (String? newValue) {
                    setState(() {
                      selectedPerson = newValue!;
                    });
                  },
                  decoration: const InputDecoration(
                    border: InputBorder.none,
                    contentPadding: EdgeInsets.symmetric(horizontal: 12),
                  ),
                  isExpanded: true,
                  dropdownColor: Colors.white,
                  elevation: 1,
                ),
              ),
              const SizedBox(height: 16),
              Container(
                decoration: const BoxDecoration(
                  color: Color(0xffF2F2F3),
                  borderRadius: BorderRadius.all(Radius.circular(4)),
                ),
                child: DropdownButtonFormField<String>(
                  value: selectedFilter,
                  items: filterOptions.map((String filter) {
                    return DropdownMenuItem<String>(
                      value: filter,
                      child: Text(
                        filter,
                        style: const TextStyle(
                          fontFamily: "Inter",
                          fontWeight: FontWeight.w400,
                          fontSize: 12,
                        ),
                      ),
                    );
                  }).toList(),
                  onChanged: (String? newValue) {
                    setState(() {
                      selectedFilter = newValue!;
                    });
                  },
                  decoration: const InputDecoration(
                    border: InputBorder.none,
                    contentPadding: EdgeInsets.symmetric(horizontal: 12),
                  ),
                  isExpanded: true,
                  dropdownColor: Colors.white,
                  elevation: 1,
                ),
              ),
              const SizedBox(height: 16),
              SizedBox(
                height: 50,
                child: ElevatedButton(
                  onPressed: _isLoading
                      ? null
                      : () async {
                          setState(() {
                            _isLoading = true;
                          });
                          try {
                            final payments = await _fetchPayments();
                            if (payments.isEmpty) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text(
                                      'No payments found for the selected filters'),
                                ),
                              );
                              return;
                            }
                            Navigator.push(
                              context,
                              SlidingPageTransitionLR(
                                page: ReportPreviewPage(
                                  payments: payments,
                                  selectedYear: useDateRange
                                      ? "${DateFormat('yyyy').format(startDate!)} - ${DateFormat('yyyy').format(endDate!)}"
                                      : selectedYear,
                                  selectedMonth: useDateRange
                                      ? "${DateFormat('MMM dd').format(startDate!)} - ${DateFormat('MMM dd').format(endDate!)}"
                                      : selectedMonth,
                                  selectedFilter: selectedFilter,
                                  selectedPerson: selectedPerson,
                                ),
                              ),
                            );
                          } finally {
                            setState(() {
                              _isLoading = false;
                            });
                          }
                        },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF00A699),
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Text(
                        'Preview Report',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.white,
                          fontFamily: "Inter",
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      if (_isLoading) ...[
                        const SizedBox(width: 8),
                        // Spacing between text and indicator
                        const SizedBox(
                          height: 16,
                          width: 16,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor:
                                AlwaysStoppedAnimation<Color>(Colors.white),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
            ],
          ),
        ],
      ),
    );
  }
}

class ReportPreviewPage extends StatelessWidget {
  final List<Map<String, dynamic>> payments;
  final String selectedYear;
  final String selectedMonth;
  final String selectedFilter;
  final String selectedPerson;

  const ReportPreviewPage({
    super.key,
    required this.payments,
    required this.selectedYear,
    required this.selectedMonth,
    required this.selectedFilter,
    required this.selectedPerson,
  });

  int _monthToNumberForSorting(String month) {
    const monthMap = {
      'January': 1,
      'February': 2,
      'March': 3,
      'April': 4,
      'May': 5,
      'June': 6,
      'July': 7,
      'August': 8,
      'September': 9,
      'October': 10,
      'November': 11,
      'December': 12,
      'Unknown': 0,
    };
    return monthMap[month] ?? 0;
  }

  List<Map<String, dynamic>> _sortPaymentsByMonth(
      List<Map<String, dynamic>> payments) {
    final sortedPayments = List<Map<String, dynamic>>.from(payments);
    sortedPayments.sort((a, b) {
      final monthA = _monthToNumberForSorting(a['month'] ?? 'Unknown');
      final monthB = _monthToNumberForSorting(b['month'] ?? 'Unknown');
      return monthA.compareTo(monthB);
    });
    return sortedPayments;
  }

  double _calculateTotalAmount() {
    return payments.fold(0.0, (sum, payment) {
      if (payment['status'] == 'paid') {
        final amount = (payment['amount'] as num?)?.toDouble() ?? 0.0;
        return sum + amount;
      }
      return sum;
    });
  }

  Future<void> _generateAndDownloadPDF(BuildContext context) async {
    try {
      final pdf = pw.Document();
      final dateFormat = DateFormat('dd MMMM yyyy');
      final currentDate = dateFormat.format(DateTime.now());

      pdf.addPage(
        pw.MultiPage(
          pageFormat: PdfPageFormat.a4,
          margin: const pw.EdgeInsets.all(32),
          header: (pw.Context context) {
            return pw.Container(
              margin: const pw.EdgeInsets.only(bottom: 20),
              child: pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Row(
                    mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                    children: [
                      pw.Column(
                        crossAxisAlignment: pw.CrossAxisAlignment.start,
                        children: [
                          pw.Text('PAYMENT REPORT',
                              style: pw.TextStyle(
                                  fontSize: 24,
                                  fontWeight: pw.FontWeight.bold,
                                  color: PdfColors.teal)),
                          pw.Text(
                            '$selectedMonth $selectedYear',
                            style: pw.TextStyle(
                                fontSize: 16, fontWeight: pw.FontWeight.bold),
                          ),
                        ],
                      ),
                      pw.Text(
                        'Generated: $currentDate',
                        style: const pw.TextStyle(
                            fontSize: 12, color: PdfColors.grey700),
                      ),
                    ],
                  ),
                  pw.SizedBox(height: 10),
                  pw.Divider(color: PdfColors.teal, thickness: 2),
                ],
              ),
            );
          },
          footer: (pw.Context context) {
            return pw.Container(
              margin: const pw.EdgeInsets.only(top: 20),
              child: pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Text(
                    'PMJ App - Payment Report',
                    style: const pw.TextStyle(
                        fontSize: 10, color: PdfColors.grey700),
                  ),
                  pw.Text(
                    'Page ${context.pageNumber} of ${context.pagesCount}',
                    style: const pw.TextStyle(
                        fontSize: 10, color: PdfColors.grey700),
                  ),
                ],
              ),
            );
          },
          build: (pw.Context context) {
            if (selectedMonth == "Whole Year") {
              return _buildWholeYearTable();
            } else {
              return _buildSingleMonthTable();
            }
          },
        ),
      );

      final directory = await getTemporaryDirectory();
      final file = File(
          '${directory.path}/payment_report_${selectedMonth == "Whole Year" ? "All_Months" : selectedMonth}_${selectedYear}_${selectedPerson.replaceAll(' ', '_')}.pdf');
      await file.writeAsBytes(await pdf.save());

      await Share.shareXFiles(
        [XFile(file.path)],
        text:
            'Payment Report for ${selectedMonth == "Whole Year" ? "All Months" : selectedMonth} $selectedYear - $selectedPerson',
      );

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('PDF generated and shared successfully'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to generate PDF: $e'),
          backgroundColor: Colors.red,
        ),
      );
      print(e);
    }
  }

  List<pw.Widget> _buildWholeYearTable() {
    final uniqueNames = payments
        .map((p) => p['name'] as String?)
        .where((name) => name != null)
        .toSet()
        .toList()
        .cast<String>()
      ..sort(); // Sort names alphabetically

    final months = [
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

    final paymentStatus = <String, Map<String, String>>{};
    for (var name in uniqueNames) {
      paymentStatus[name] = {};
      final userPayments = payments.where((p) => p['name'] == name);
      for (var payment in userPayments) {
        final month = payment['month'] as String?;
        final status = payment['status'] as String?;
        if (month != null && status != null && months.contains(month)) {
          paymentStatus[name]![month] = status;
        }
      }
    }

    return [
      pw.Container(
        padding: const pw.EdgeInsets.all(16),
        decoration: pw.BoxDecoration(
          color: PdfColors.grey100,
          borderRadius: const pw.BorderRadius.all(pw.Radius.circular(8)),
        ),
        child: pw.Row(
          mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
          children: [
            pw.Text('Filter: $selectedFilter',
                style: const pw.TextStyle(fontSize: 12)),
            pw.Text('Person: $selectedPerson',
                style: const pw.TextStyle(fontSize: 12)),
          ],
        ),
      ),
      pw.SizedBox(height: 20),
      pw.Text(
        'Payment Status by Person',
        style: pw.TextStyle(
          fontSize: 16,
          fontWeight: pw.FontWeight.bold,
          color: PdfColors.teal,
        ),
      ),
      pw.SizedBox(height: 10),
      pw.Table(
        border: pw.TableBorder.all(color: PdfColors.grey400),
        columnWidths: {
          0: const pw.FixedColumnWidth(40), // S.No. column
          1: const pw.FixedColumnWidth(100), // Person column
          for (int i = 0; i < months.length; i++)
            i + 2: const pw.FixedColumnWidth(50), // Month columns
        },
        children: [
          pw.TableRow(
            decoration: const pw.BoxDecoration(color: PdfColors.teal),
            children: [
              pw.Container(
                padding: const pw.EdgeInsets.all(8),
                alignment: pw.Alignment.center,
                child: pw.Text(
                  'S.No.',
                  style: pw.TextStyle(
                    color: PdfColors.white,
                    fontWeight: pw.FontWeight.bold,
                    fontSize: 10,
                  ),
                ),
              ),
              pw.Container(
                padding: const pw.EdgeInsets.all(8),
                alignment: pw.Alignment.center,
                child: pw.Text(
                  'Person',
                  style: pw.TextStyle(
                    color: PdfColors.white,
                    fontWeight: pw.FontWeight.bold,
                    fontSize: 10,
                  ),
                ),
              ),
              ...months.map((month) => pw.Container(
                    padding: const pw.EdgeInsets.all(8),
                    alignment: pw.Alignment.center,
                    child: pw.Text(
                      month.substring(0, 3), // Abbreviated month
                      style: pw.TextStyle(
                        color: PdfColors.white,
                        fontWeight: pw.FontWeight.bold,
                        fontSize: 10,
                      ),
                    ),
                  )),
            ],
          ),
          ...uniqueNames.asMap().entries.map((entry) {
            final index = entry.key;
            final name = entry.value;
            return pw.TableRow(
              children: [
                pw.Container(
                  padding: const pw.EdgeInsets.all(8),
                  alignment: pw.Alignment.center,
                  child: pw.Text(
                    '${index + 1}',
                    style: const pw.TextStyle(fontSize: 8),
                  ),
                ),
                pw.Container(
                  padding: const pw.EdgeInsets.all(8),
                  alignment: pw.Alignment.centerLeft,
                  child: pw.Text(
                    name,
                    style: const pw.TextStyle(fontSize: 8),
                  ),
                ),
                ...months.map((month) {
                  final status = paymentStatus[name]![month];
                  if (selectedFilter == "Payment received only") {
                    if (status == 'paid') {
                      return pw.Container(
                        padding: const pw.EdgeInsets.all(8),
                        alignment: pw.Alignment.center,
                        decoration: pw.BoxDecoration(
                          color: PdfColors.green,
                          border: pw.Border.all(color: PdfColors.grey400),
                        ),
                        child: pw.Text(
                          'Paid',
                          style: const pw.TextStyle(
                            color: PdfColors.white,
                            fontSize: 8,
                          ),
                        ),
                      );
                    } else {
                      return pw.Container(
                        padding: const pw.EdgeInsets.all(8),
                        alignment: pw.Alignment.center,
                        child: pw.Text(
                          '',
                          style: const pw.TextStyle(fontSize: 8),
                        ),
                      );
                    }
                  } else if (selectedFilter == "Payments to be received") {
                    if (status == 'unpaid') {
                      return pw.Container(
                        padding: const pw.EdgeInsets.all(8),
                        alignment: pw.Alignment.center,
                        child: pw.Text(
                          'Unpaid',
                          style: const pw.TextStyle(
                            color: PdfColors.red,
                            fontSize: 8,
                          ),
                        ),
                      );
                    } else {
                      return pw.Container(
                        padding: const pw.EdgeInsets.all(8),
                        alignment: pw.Alignment.center,
                        child: pw.Text(
                          '',
                          style: const pw.TextStyle(fontSize: 8),
                        ),
                      );
                    }
                  } else {
                    // "All payments"
                    final displayText = status == 'paid'
                        ? 'Paid'
                        : status == 'unpaid'
                            ? 'Unpaid'
                            : '';
                    final displayColor = status == 'paid'
                        ? PdfColors.white
                        : status == 'unpaid'
                            ? PdfColors.red
                            : PdfColors.black;
                    return pw.Container(
                      padding: const pw.EdgeInsets.all(6),
                      alignment: pw.Alignment.center,
                      decoration: status == 'paid'
                          ? pw.BoxDecoration(
                              color: PdfColors.green,
                              border: pw.Border.all(color: PdfColors.grey400),
                            )
                          : null,
                      child: pw.Text(
                        displayText,
                        style: pw.TextStyle(
                          color: displayColor,
                          fontSize: 6,
                          fontWeight: pw.FontWeight.bold,
                        ),
                      ),
                    );
                  }
                }),
              ],
            );
          }),
        ],
      ),
    ];
  }

  List<pw.Widget> _buildSingleMonthTable() {
    final totalAmount = _calculateTotalAmount();
    final sortedPayments = _sortPaymentsByMonth(payments);

    return [
      pw.Container(
        padding: const pw.EdgeInsets.all(16),
        decoration: pw.BoxDecoration(
          color: PdfColors.grey100,
          borderRadius: const pw.BorderRadius.all(pw.Radius.circular(8)),
        ),
        child: pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              children: [
                pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Text('Report Details',
                        style: pw.TextStyle(
                            fontWeight: pw.FontWeight.bold, fontSize: 14)),
                    pw.SizedBox(height: 8),
                    pw.Text('Filter: $selectedFilter'),
                    pw.Text('Person: $selectedPerson'),
                  ],
                ),
                pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.end,
                  children: [
                    pw.Text('Summary',
                        style: pw.TextStyle(
                            fontWeight: pw.FontWeight.bold, fontSize: 14)),
                    pw.SizedBox(height: 8),
                    pw.Text(
                        'Total Payments: ${payments.where((p) => p['status'] == 'paid').length}'),
                    pw.Text('Total Amount: ${totalAmount.toStringAsFixed(0)}',
                        style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
      pw.SizedBox(height: 20),
      pw.Text('Payment Details',
          style: pw.TextStyle(
              fontSize: 16,
              fontWeight: pw.FontWeight.bold,
              color: PdfColors.teal)),
      pw.SizedBox(height: 10),
      pw.Table(
        border: pw.TableBorder.all(color: PdfColors.grey400),
        columnWidths: {
          0: const pw.FixedColumnWidth(100), // Name column
        },
        defaultColumnWidth: const pw.IntrinsicColumnWidth(),
        children: [
          pw.TableRow(
            decoration: const pw.BoxDecoration(color: PdfColors.teal),
            children: [
              pw.Container(
                padding: const pw.EdgeInsets.all(4),
                alignment: pw.Alignment.center,
                child: pw.Text(
                  'Name',
                  style: pw.TextStyle(
                      color: PdfColors.white, fontWeight: pw.FontWeight.bold),
                ),
              ),
              pw.Container(
                padding: const pw.EdgeInsets.all(4),
                alignment: pw.Alignment.center,
                child: pw.Text(
                  'Amount',
                  style: pw.TextStyle(
                      color: PdfColors.white, fontWeight: pw.FontWeight.bold),
                ),
              ),
              pw.Container(
                padding: const pw.EdgeInsets.all(4),
                alignment: pw.Alignment.center,
                child: pw.Text(
                  'Payment Method',
                  style: pw.TextStyle(
                      color: PdfColors.white, fontWeight: pw.FontWeight.bold),
                ),
              ),
              pw.Container(
                padding: const pw.EdgeInsets.all(4),
                alignment: pw.Alignment.center,
                child: pw.Text(
                  'Payment For',
                  style: pw.TextStyle(
                      color: PdfColors.white, fontWeight: pw.FontWeight.bold),
                ),
              ),
              pw.Container(
                padding: const pw.EdgeInsets.all(4),
                alignment: pw.Alignment.center,
                child: pw.Text(
                  'Date Paid',
                  style: pw.TextStyle(
                      color: PdfColors.white, fontWeight: pw.FontWeight.bold),
                ),
              ),
              pw.Container(
                padding: const pw.EdgeInsets.all(4),
                alignment: pw.Alignment.center,
                child: pw.Text(
                  'Status',
                  style: pw.TextStyle(
                      color: PdfColors.white, fontWeight: pw.FontWeight.bold),
                ),
              ),
            ],
          ),
          ...sortedPayments.map((payment) {
            final timestamp = (payment['timestamp'] as Timestamp?)?.toDate();
            final datePaid = timestamp != null
                ? "${timestamp.day.toString().padLeft(2, '0')}.${timestamp.month.toString().padLeft(2, '0')}.${timestamp.year}"
                : '-';
            final paymentFor =
                "${payment['month'] ?? 'Unknown'} ${payment['year'] ?? 'Unknown'}";
            final status = payment['status'] == 'paid'
                ? 'Paid'
                : payment['status'] == 'unpaid'
                    ? 'Unpaid'
                    : 'Unknown';
            return pw.TableRow(
              children: [
                pw.Container(
                  padding: const pw.EdgeInsets.all(4),
                  alignment: pw.Alignment.centerLeft,
                  child: pw.Text(
                    payment['name'] ?? 'Unknown',
                    style: const pw.TextStyle(fontSize: 8),
                  ),
                ),
                pw.Container(
                  padding: const pw.EdgeInsets.all(4),
                  alignment: pw.Alignment.centerRight,
                  child: pw.Text(
                    payment['status'] == 'paid'
                        ? '${(payment['amount'] as num?)?.toStringAsFixed(0) ?? '0'}'
                        : '-',
                    style: const pw.TextStyle(fontSize: 8),
                  ),
                ),
                pw.Container(
                  padding: const pw.EdgeInsets.all(4),
                  alignment: pw.Alignment.center,
                  child: pw.Text(
                    payment['status'] == 'paid'
                        ? (payment['paymentMethod'] ?? 'Unknown')
                        : '-',
                    style: const pw.TextStyle(fontSize: 8),
                  ),
                ),
                pw.Container(
                  padding: const pw.EdgeInsets.all(4),
                  alignment: pw.Alignment.center,
                  child: pw.Text(
                    paymentFor,
                    style: const pw.TextStyle(fontSize: 8),
                  ),
                ),
                pw.Container(
                  padding: const pw.EdgeInsets.all(4),
                  alignment: pw.Alignment.center,
                  child: pw.Text(
                    payment['status'] == 'paid' ? datePaid : '-',
                    style: const pw.TextStyle(fontSize: 8),
                  ),
                ),
                pw.Container(
                  padding: const pw.EdgeInsets.all(4),
                  alignment: pw.Alignment.center,
                  child: pw.Text(
                    status,
                    style: pw.TextStyle(
                      fontSize: 8,
                      color: status == 'Paid' ? PdfColors.green : PdfColors.red,
                    ),
                  ),
                ),
              ],
            );
          }),
        ],
      ),
      pw.SizedBox(height: 20),
      pw.Container(
        padding: const pw.EdgeInsets.all(10),
        decoration: pw.BoxDecoration(
          border: pw.Border.all(color: PdfColors.grey400),
          borderRadius: const pw.BorderRadius.all(pw.Radius.circular(4)),
        ),
        child: pw.Row(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            pw.Text('Note: ',
                style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
            pw.Expanded(
              child: pw.Text(
                  'This is an auto-generated report created by PMJ Application. For any queries regarding this report, please contact support.'),
            ),
          ],
        ),
      ),
    ];
  }

  @override
  Widget build(BuildContext context) {
    final totalAmount = _calculateTotalAmount();
    final sortedPayments = _sortPaymentsByName(payments); // Updated sorting
    final screenWidth = MediaQuery.of(context).size.width;

    return Scaffold(
        appBar: AppBar(
          title: Text(
            'Report - ${selectedMonth == "Whole Year" ? "All Months" : selectedMonth} $selectedYear',
            style: const TextStyle(
              fontFamily: "Inter",
              fontWeight: FontWeight.w600,
              fontSize: 16,
            ),
          ),
          backgroundColor: Colors.white,
          elevation: 0,
          iconTheme: const IconThemeData(color: Color(0xFF00A699)),
        ),
        body: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Heading Row
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Flexible(
                    child: Text(
                      'Filter: $selectedFilter',
                      style: const TextStyle(
                        fontFamily: "Inter",
                        fontWeight: FontWeight.w600,
                        fontSize: 14,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Flexible(
                    child: Text(
                      'Person: $selectedPerson',
                      style: const TextStyle(
                        fontFamily: "Inter",
                        fontWeight: FontWeight.w600,
                        fontSize: 14,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              // Payment Table with Vertical and Horizontal Scrolling
              Expanded(
                child: SingleChildScrollView(
                  scrollDirection: Axis.vertical,
                  child: SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: ConstrainedBox(
                      constraints: BoxConstraints(minWidth: screenWidth),
                      child: DataTable(
                        columnSpacing: 16,
                        headingRowColor:
                            WidgetStateProperty.all(Colors.grey[100]),
                        dataRowMinHeight: 48,
                        dataRowMaxHeight: 48,
                        columns: const [
                          DataColumn(
                            label: Text(
                              'S.No.',
                              style: TextStyle(
                                fontFamily: "Inter",
                                fontWeight: FontWeight.w600,
                                fontSize: 12,
                              ),
                            ),
                          ),
                          DataColumn(
                            label: Text(
                              'Name',
                              style: TextStyle(
                                fontFamily: "Inter",
                                fontWeight: FontWeight.w600,
                                fontSize: 12,
                              ),
                            ),
                          ),
                          DataColumn(
                            label: Text(
                              'Amount',
                              style: TextStyle(
                                fontFamily: "Inter",
                                fontWeight: FontWeight.w600,
                                fontSize: 12,
                              ),
                            ),
                          ),
                          DataColumn(
                            label: Text(
                              'Method',
                              style: TextStyle(
                                fontFamily: "Inter",
                                fontWeight: FontWeight.w600,
                                fontSize: 12,
                              ),
                            ),
                          ),
                          DataColumn(
                            label: Text(
                              'Payment For',
                              style: TextStyle(
                                fontFamily: "Inter",
                                fontWeight: FontWeight.w600,
                                fontSize: 12,
                              ),
                            ),
                          ),
                          DataColumn(
                            label: Text(
                              'Date Paid',
                              style: TextStyle(
                                fontFamily: "Inter",
                                fontWeight: FontWeight.w600,
                                fontSize: 12,
                              ),
                            ),
                          ),
                          DataColumn(
                            label: Text(
                              'Status',
                              style: TextStyle(
                                fontFamily: "Inter",
                                fontWeight: FontWeight.w600,
                                fontSize: 12,
                              ),
                            ),
                          ),
                        ],
                        rows: sortedPayments.asMap().entries.map((entry) {
                          final index = entry.key;
                          final payment = entry.value;
                          final timestamp =
                              (payment['timestamp'] as Timestamp?)?.toDate();
                          final datePaid = timestamp != null
                              ? "${timestamp.day.toString().padLeft(2, '0')}.${timestamp.month.toString().padLeft(2, '0')}.${timestamp.year}"
                              : '-';
                          final paymentFor =
                              "${payment['month'] ?? 'Unknown'} ${payment['year'] ?? 'Unknown'}";
                          final status = payment['status'] == 'paid'
                              ? 'Paid'
                              : payment['status'] == 'unpaid'
                                  ? 'Unpaid'
                                  : 'Unknown';
                          return DataRow(
                            cells: [
                              DataCell(
                                Text(
                                  '${index + 1}',
                                  style: const TextStyle(
                                    fontFamily: "Inter",
                                    fontSize: 12,
                                  ),
                                ),
                              ),
                              DataCell(
                                Text(
                                  payment['name'] ?? 'Unknown',
                                  style: const TextStyle(
                                    fontFamily: "Inter",
                                    fontSize: 12,
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              DataCell(
                                Text(
                                  payment['status'] == 'paid'
                                      ? '${(payment['amount'] as num?)?.toStringAsFixed(0) ?? '0'}'
                                      : '-',
                                  style: const TextStyle(
                                    fontFamily: "Inter",
                                    fontSize: 12,
                                  ),
                                ),
                              ),
                              DataCell(
                                Text(
                                  payment['status'] == 'paid'
                                      ? (payment['paymentMethod'] ?? 'Unknown')
                                      : '-',
                                  style: const TextStyle(
                                    fontFamily: "Inter",
                                    fontSize: 12,
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              DataCell(
                                Text(
                                  paymentFor,
                                  style: const TextStyle(
                                    fontFamily: "Inter",
                                    fontSize: 12,
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              DataCell(
                                Text(
                                  payment['status'] == 'paid' ? datePaid : '-',
                                  style: const TextStyle(
                                    fontFamily: "Inter",
                                    fontSize: 12,
                                  ),
                                ),
                              ),
                              DataCell(
                                Text(
                                  status,
                                  style: TextStyle(
                                    fontFamily: "Inter",
                                    fontSize: 12,
                                    color: status == 'Paid'
                                        ? Colors.green
                                        : Colors.red,
                                  ),
                                ),
                              ),
                            ],
                          );
                        }).toList(),
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              // Totals Row
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Total Payments: ${payments.where((p) => p['status'] == 'paid').length}',
                    style: const TextStyle(
                      fontFamily: "Inter",
                      fontWeight: FontWeight.w600,
                      fontSize: 14,
                    ),
                  ),
                  Text(
                    'Total Amount: ${totalAmount.toStringAsFixed(0)}',
                    style: const TextStyle(
                      fontFamily: "Inter",
                      fontWeight: FontWeight.w600,
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                height: 48,
                child: ElevatedButton(
                  onPressed: () async {
                    await _generateAndDownloadPDF(context);
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF00A699),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    elevation: 0,
                  ),
                  child: const Text(
                    'Download PDF',
                    style: TextStyle(
                      fontFamily: "Inter",
                      fontWeight: FontWeight.w600,
                      fontSize: 14,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ));
  }

  // New sorting function for alphabetical order by name
  List<Map<String, dynamic>> _sortPaymentsByName(
      List<Map<String, dynamic>> payments) {
    return List.from(payments)
      ..sort(
          (a, b) => (a['name'] ?? 'Unknown').compareTo(b['name'] ?? 'Unknown'));
  }
}
