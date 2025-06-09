import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import '../assets/custom widgets/logoutpopup.dart';
import '../assets/custom widgets/transition.dart';
import '../assets/custom widgets/GPay.dart';

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
                const SizedBox(height: 12),
                ReportsSection(
                  onLoadingChanged: _setLoading,
                ),
                const SizedBox(height: 8),
                GestureDetector(
                  onTap: () {
                    Navigator.push(
                      context,
                      SlidingPageTransitionRL(page: const NotificationsPage()),
                    );
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
                const SizedBox(height: 14),
                GestureDetector(
                  onTap: () {
                    Navigator.push(
                      context,
                      SlidingPageTransitionRL(page: const GPay()),
                    );
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
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: ListTile(
                  leading: GestureDetector(
                    onTap: () => Navigator.pop(context),
                    child: SvgPicture.asset(
                      'lib/assets/images/Back.svg',
                      height: 40,
                      width: 40,
                    ),
                  ),
                  title: const Center(
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
            ],
          ),
        ),
      ),
    );
  }
}

class ReportsSection extends StatefulWidget {
  final Function(bool) onLoadingChanged;

  const ReportsSection({Key? key, required this.onLoadingChanged})
      : super(key: key);

  @override
  _ReportsSectionState createState() => _ReportsSectionState();
}

class _ReportsSectionState extends State<ReportsSection> {
  late List<String> years;
  late List<String> months;
  final List<String> filterOptions = [
    "All payments",
    "Payment received only",
    "Payments to be received",
  ];
  List<String> peopleList = ['All People'];
  String selectedPerson = 'All People';
  late String selectedYear;
  String selectedMonth = "Whole Year";
  late String selectedFilter;
  bool _isLoadingPreview = false; // Separate loading for Preview button
  bool _isLoadingPDF = false; // Separate loading for PDF button
  bool useAdvancedFilters = false;
  bool useMonthRange = false;
  int startMonthIndex = 0; // Jan
  int endMonthIndex = 11; // Dec
  int selectedMonthIndex = 0;

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
    selectedMonth = "Whole Year";
    selectedMonthIndex = 0;
    selectedFilter = filterOptions[0];
    _fetchPeopleList();
  }

  Future<void> _fetchPeopleList() async {
    try {
      final querySnapshot =
          await FirebaseFirestore.instance.collection('donors').get();
      final uniquePeople = querySnapshot.docs
          .map((doc) => doc['name'] as String?)
          .where((name) => name != null && name.isNotEmpty)
          .toSet()
          .toList()
          .cast<String>()
        ..sort();
      setState(() {
        peopleList = ['All People', ...uniquePeople];
        if (!peopleList.contains(selectedPerson)) {
          selectedPerson = 'All People';
        }
      });
      if (uniquePeople.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('No donors found.')),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to fetch donors: $e'),
          backgroundColor: Colors.red,
        ),
      );
      setState(() {
        peopleList = ['All People'];
        selectedPerson = 'All People';
      });
    }
  }

  Future<List<Map<String, dynamic>>> _fetchPayments() async {
    setState(() {
      _isLoadingPreview = true;
    });
    widget.onLoadingChanged(true);
    try {
      final List<Map<String, dynamic>> payments = [];
      final donorSnapshot =
          await FirebaseFirestore.instance.collection('donors').get();

      List<Map<String, dynamic>> donorsToProcess = [];
      if (selectedPerson != 'All People') {
        final matchingDocs = donorSnapshot.docs
            .where((doc) => doc['name'] == selectedPerson)
            .toList();
        if (matchingDocs.isEmpty) return [];
        donorsToProcess.add({
          'id': matchingDocs.first.id,
          'name': selectedPerson,
        });
      } else {
        donorsToProcess = donorSnapshot.docs
            .map((doc) => {
                  'id': doc.id,
                  'name': doc['name'] as String? ?? 'Unknown',
                })
            .toList();
      }

      for (var donor in donorsToProcess) {
        Query<Map<String, dynamic>> query = FirebaseFirestore.instance
            .collection('donors')
            .doc(donor['id'])
            .collection('paymentStatus')
            .where('year', isEqualTo: selectedYear);

        if (useAdvancedFilters && useMonthRange) {
          query = FirebaseFirestore.instance
              .collection('donors')
              .doc(donor['id'])
              .collection('paymentStatus')
              .where('year', isEqualTo: selectedYear);
        } else if (selectedMonth != "Whole Year") {
          query = query.where('month', isEqualTo: months[selectedMonthIndex]);
        }

        final snapshot = await query.get();
        for (var doc in snapshot.docs) {
          final data = doc.data();
          if (useAdvancedFilters && useMonthRange) {
            int monthIndex = months.indexOf(data['month']) - 1;
            if (monthIndex < 0) continue;
            if (monthIndex < startMonthIndex || monthIndex > endMonthIndex) {
              continue;
            }
          }

          if (selectedFilter == "Payment received only" &&
              data['status'] != 'paid') {
            continue;
          }
          if (selectedFilter == "Payments to be received" &&
              data['status'] != 'unpaid') {
            continue;
          }

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

        if (useAdvancedFilters && useMonthRange) {
          if (selectedFilter == "Payments to be received" ||
              selectedFilter == "All payments") {
            for (int i = startMonthIndex + 1; i <= endMonthIndex + 1; i++) {
              if (i >= months.length) continue;
              String month = months[i];
              bool hasPaidOrUnpaid = snapshot.docs.any((doc) =>
                  doc['month'] == month && doc['year'] == selectedYear);
              if (!hasPaidOrUnpaid) {
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
        } else if (selectedMonth != "Whole Year") {
          if (selectedFilter == "Payments to be received" ||
              selectedFilter == "All payments") {
            final currentMonth = months[selectedMonthIndex];
            final hasAnyPayment = snapshot.docs.any((doc) =>
                doc['month'] == currentMonth && doc['year'] == selectedYear);
            if (!hasAnyPayment) {
              payments.add({
                'name': donor['name'],
                'amount': null,
                'paymentMethod': null,
                'month': currentMonth,
                'year': selectedYear,
                'timestamp': null,
                'status': 'unpaid',
              });
            }
          }
        } else if (selectedMonth == "Whole Year" &&
            (selectedFilter == "Payments to be received" ||
                selectedFilter == "All payments")) {
          const monthsWithoutWhole = [
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
          final existingMonths =
              snapshot.docs.map((doc) => doc['month'] as String?).toSet();
          for (var month in monthsWithoutWhole) {
            if (!existingMonths.contains(month)) {
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

      return payments;
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error fetching payments: $e'),
          backgroundColor: Colors.red,
        ),
      );
      return [];
    } finally {
      setState(() {
        _isLoadingPreview = false;
      });
      widget.onLoadingChanged(false);
    }
  }

  Future<void> _generateAllPeoplePDF() async {
    setState(() {
      _isLoadingPDF = true;
      widget.onLoadingChanged(true);
    });
    try {
      final pdf = pw.Document();
      final dateFormat = DateFormat('dd MMMM yyyy');
      final currentDate = dateFormat.format(DateTime.now());

      final donorSnapshot =
          await FirebaseFirestore.instance.collection('donors').get();
      final donors = donorSnapshot.docs
          .map((doc) => {
                'id': doc.id,
                'name': doc['name'] as String? ?? 'Unknown',
                'amount': (doc['amount'] as num?)?.toDouble() ?? 0.0,
              })
          .toList()
        ..sort((a, b) => (a['name'] as String).compareTo(b['name'] as String));

      pdf.addPage(
        pw.MultiPage(
          pageFormat: PdfPageFormat.a4.portrait,
          margin: const pw.EdgeInsets.all(20),
          header: (pw.Context context) {
            return pw.Container(
              margin: const pw.EdgeInsets.only(bottom: 10),
              child: pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Row(
                    mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                    children: [
                      pw.Column(
                        crossAxisAlignment: pw.CrossAxisAlignment.start,
                        children: [
                          pw.Text(
                            'DONOR MONTHLY OBLIGATIONS',
                            style: pw.TextStyle(
                              fontSize: 20,
                              fontWeight: pw.FontWeight.bold,
                              color: PdfColors.teal,
                            ),
                          ),
                          pw.Text(
                            'Year $selectedYear',
                            style: pw.TextStyle(
                              fontSize: 14,
                              fontWeight: pw.FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                      pw.Text(
                        'Generated: $currentDate',
                        style: const pw.TextStyle(
                          fontSize: 10,
                          color: PdfColors.grey700,
                        ),
                      ),
                    ],
                  ),
                  pw.SizedBox(height: 5),
                  pw.Divider(color: PdfColors.teal, thickness: 1),
                ],
              ),
            );
          },
          footer: (pw.Context context) {
            return pw.Container(
              margin: const pw.EdgeInsets.only(top: 10),
              child: pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Text(
                    'PMJ App - Donor Monthly Obligations',
                    style: const pw.TextStyle(
                      fontSize: 8,
                      color: PdfColors.grey700,
                    ),
                  ),
                  pw.Text(
                    'Page ${context.pageNumber} of ${context.pagesCount}',
                    style: const pw.TextStyle(
                      fontSize: 8,
                      color: PdfColors.grey700,
                    ),
                  ),
                ],
              ),
            );
          },
          build: (pw.Context context) {
            return [
              pw.Text(
                'Donor Monthly Obligations',
                style: pw.TextStyle(
                  fontSize: 14,
                  fontWeight: pw.FontWeight.bold,
                  color: PdfColors.teal,
                ),
              ),
              pw.SizedBox(height: 5),
              pw.Table(
                border: pw.TableBorder.all(color: PdfColors.grey400),
                columnWidths: {
                  0: const pw.FixedColumnWidth(50), // S.No.
                  1: const pw.FlexColumnWidth(3), // Person
                  2: const pw.FlexColumnWidth(2), // Monthly Amount
                },
                defaultVerticalAlignment: pw.TableCellVerticalAlignment.middle,
                children: [
                  pw.TableRow(
                    decoration: const pw.BoxDecoration(color: PdfColors.teal),
                    children: [
                      pw.Padding(
                        padding: const pw.EdgeInsets.all(3),
                        child: pw.Center(
                          child: pw.Text(
                            'S.No.',
                            style: pw.TextStyle(
                              color: PdfColors.white,
                              fontWeight: pw.FontWeight.bold,
                              fontSize: 9,
                            ),
                          ),
                        ),
                      ),
                      pw.Padding(
                        padding: const pw.EdgeInsets.all(3),
                        child: pw.Center(
                          child: pw.Text(
                            'Person',
                            style: pw.TextStyle(
                              color: PdfColors.white,
                              fontWeight: pw.FontWeight.bold,
                              fontSize: 9,
                            ),
                          ),
                        ),
                      ),
                      pw.Padding(
                        padding: const pw.EdgeInsets.all(3),
                        child: pw.Center(
                          child: pw.Text(
                            'Monthly Amount',
                            style: pw.TextStyle(
                              color: PdfColors.white,
                              fontWeight: pw.FontWeight.bold,
                              fontSize: 9,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  ...donors.asMap().entries.map((entry) {
                    final index = entry.key;
                    final donor = entry.value;
                    final name = donor['name'] ?? 'Unknown';
                    final monthlyAmount = donor['amount']?.toString();
                    return pw.TableRow(
                      children: [
                        pw.Padding(
                          padding: const pw.EdgeInsets.all(3),
                          child: pw.Center(
                            child: pw.Text(
                              '${index + 1}',
                              style: const pw.TextStyle(fontSize: 9),
                              textAlign: pw.TextAlign.center,
                            ),
                          ),
                        ),
                        pw.Padding(
                          padding: const pw.EdgeInsets.symmetric(
                            horizontal: 4,
                            vertical: 3,
                          ),
                          child: pw.Text(
                            '$name',
                            style: const pw.TextStyle(fontSize: 9),
                          ),
                        ),
                        pw.Padding(
                          padding: const pw.EdgeInsets.all(3),
                          child: pw.Center(
                            child: pw.Text(
                              '$monthlyAmount',
                              style: const pw.TextStyle(fontSize: 9),
                              textAlign: pw.TextAlign.center,
                            ),
                          ),
                        ),
                      ],
                    );
                  }),
                ],
              ),
              pw.SizedBox(height: 10),
              pw.Container(
                padding: const pw.EdgeInsets.all(8),
                decoration: pw.BoxDecoration(
                  border: pw.Border.all(color: PdfColors.grey400),
                  borderRadius:
                      const pw.BorderRadius.all(pw.Radius.circular(4)),
                ),
                child: pw.Row(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Text(
                      'Note: ',
                      style: pw.TextStyle(
                          fontWeight: pw.FontWeight.bold, fontSize: 9),
                    ),
                    pw.Expanded(
                      child: pw.Text(
                        'This report lists the fixed monthly payment obligations for all donors for $selectedYear.',
                        style: pw.TextStyle(fontSize: 9),
                      ),
                    ),
                  ],
                ),
              ),
            ];
          },
        ),
      );

      final directory = await getTemporaryDirectory();
      final file = File(
          '${directory.path}/donor_monthly_obligations_${selectedYear}.pdf');
      await file.writeAsBytes(await pdf.save());

      await Share.shareXFiles(
        [XFile(file.path)],
        text: 'Donor Monthly Obligations - $selectedYear',
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
    } finally {
      setState(() {
        _isLoadingPDF = false;
        widget.onLoadingChanged(false);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              TextButton(
                onPressed: _isLoadingPDF
                    ? null // Disable button while loading
                    : () async {
                        setState(() {
                          _isLoadingPDF = true; // Start loading
                        });
                        try {
                          await _generateAllPeoplePDF();
                        } finally {
                          setState(() {
                            _isLoadingPDF = false; // Stop loading
                          });
                        }
                      },
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text(
                      "See Monthly Donor List",
                      style: TextStyle(
                        fontSize: 12,
                        color: Color(0xFF00A699),
                        fontFamily: "Inter",
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    if (_isLoadingPDF) ...[
                      const SizedBox(width: 8),
                      const SizedBox(
                        height: 16,
                        width: 16,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor:
                              AlwaysStoppedAnimation<Color>(Color(0xFF00A699)),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              TextButton(
                onPressed: () {
                  setState(() {
                    useAdvancedFilters = !useAdvancedFilters;
                    if (!useAdvancedFilters) {
                      useMonthRange = false;
                      selectedMonthIndex = 0;
                      selectedMonth = "Whole Year";
                    }
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
                    value: useMonthRange,
                    activeColor: const Color(0xFF00A699),
                    onChanged: (value) {
                      setState(() {
                        useMonthRange = value ?? false;
                      });
                    },
                  ),
                  const Text(
                    'Use Month Range',
                    style: TextStyle(
                      fontFamily: "Inter",
                      fontWeight: FontWeight.w400,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
          if (useAdvancedFilters && useMonthRange)
            Row(
              children: [
                Expanded(
                  child: Container(
                    margin: const EdgeInsets.only(bottom: 16, right: 8),
                    decoration: BoxDecoration(
                      color: const Color(0xffF2F2F3),
                      borderRadius: BorderRadius.circular(4),
                      border: Border.all(color: const Color(0xFFE0E0E0)),
                    ),
                    child: DropdownButtonFormField<int>(
                      value: startMonthIndex,
                      isExpanded: true,
                      dropdownColor: Colors.white,
                      elevation: 1,
                      items: List.generate(months.length - 1, (index) {
                        return DropdownMenuItem<int>(
                          value: index,
                          child: Text(
                            months[index + 1],
                            style: const TextStyle(
                              fontFamily: "Inter",
                              fontWeight: FontWeight.w400,
                              fontSize: 12,
                            ),
                          ),
                        );
                      }),
                      onChanged: (int? newValue) {
                        if (newValue != null) {
                          setState(() {
                            startMonthIndex = newValue;
                            if (startMonthIndex > endMonthIndex) {
                              endMonthIndex = startMonthIndex;
                            }
                          });
                        }
                      },
                      decoration: const InputDecoration(
                        labelText: 'From',
                        labelStyle: TextStyle(
                          fontSize: 12,
                          fontFamily: "Inter",
                        ),
                        contentPadding: EdgeInsets.symmetric(horizontal: 12),
                        border: InputBorder.none,
                      ),
                    ),
                  ),
                ),
                Expanded(
                  child: Container(
                    margin: const EdgeInsets.only(bottom: 16, left: 8),
                    decoration: BoxDecoration(
                      color: const Color(0xffF2F2F3),
                      borderRadius: BorderRadius.circular(4),
                      border: Border.all(color: const Color(0xFFE0E0E0)),
                    ),
                    child: DropdownButtonFormField<int>(
                      value: endMonthIndex,
                      isExpanded: true,
                      dropdownColor: Colors.white,
                      elevation: 1,
                      items: List.generate(months.length - 1, (index) {
                        final isDisabled = index < startMonthIndex;
                        return DropdownMenuItem<int>(
                          enabled: !isDisabled,
                          value: index,
                          child: Text(
                            months[index + 1],
                            style: TextStyle(
                              fontFamily: "Inter",
                              fontWeight: FontWeight.w400,
                              fontSize: 12,
                              color: isDisabled ? Colors.grey[400] : null,
                            ),
                          ),
                        );
                      }),
                      onChanged: (int? newValue) {
                        if (newValue != null) {
                          setState(() {
                            endMonthIndex = newValue;
                          });
                        }
                      },
                      decoration: const InputDecoration(
                        labelText: 'To',
                        labelStyle: TextStyle(
                          fontSize: 12,
                          fontFamily: "Inter",
                        ),
                        contentPadding: EdgeInsets.symmetric(horizontal: 12),
                        border: InputBorder.none,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          if (!useAdvancedFilters || !useMonthRange)
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
                        if (newValue != null) {
                          setState(() {
                            selectedYear = newValue;
                          });
                        }
                      },
                      decoration: const InputDecoration(
                        contentPadding: EdgeInsets.symmetric(horizontal: 12),
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
                    child: DropdownButtonFormField<int>(
                      value: selectedMonthIndex,
                      items: List.generate(months.length, (index) {
                        return DropdownMenuItem<int>(
                          value: index,
                          child: Text(
                            months[index],
                            style: const TextStyle(
                              fontFamily: "Inter",
                              fontWeight: FontWeight.w400,
                              fontSize: 12,
                            ),
                          ),
                        );
                      }),
                      onChanged: (int? newValue) {
                        if (newValue != null) {
                          setState(() {
                            selectedMonthIndex = newValue;
                            selectedMonth = months[newValue];
                          });
                        }
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
                if (newValue != null) {
                  setState(() {
                    selectedPerson = newValue;
                  });
                }
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
                if (newValue != null) {
                  setState(() {
                    selectedFilter = newValue;
                  });
                }
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
              onPressed: _isLoadingPreview
                  ? null
                  : () async {
                      setState(() {
                        _isLoadingPreview = true;
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

                        String displayMonth;
                        if (useAdvancedFilters && useMonthRange) {
                          displayMonth =
                              "${months[startMonthIndex + 1]} - ${months[endMonthIndex + 1]}";
                        } else {
                          displayMonth = months[selectedMonthIndex];
                        }

                        Navigator.push(
                          context,
                          SlidingPageTransitionLR(
                            page: ReportPreviewPage(
                              payments: payments,
                              selectedYear: selectedYear,
                              selectedMonth: displayMonth,
                              selectedFilter: selectedFilter,
                              selectedPerson: selectedPerson,
                            ),
                          ),
                        );
                      } finally {
                        setState(() {
                          _isLoadingPreview = false;
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
                  if (_isLoadingPreview) ...[
                    const SizedBox(width: 8),
                    const SizedBox(
                      height: 16,
                      width: 16,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
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
    );
  }
}

class ReportPreviewPage extends StatefulWidget {
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

  @override
  State<ReportPreviewPage> createState() => _ReportPreviewPageState();
}

class _ReportPreviewPageState extends State<ReportPreviewPage> {
  int _currentPage = 1;
  final int _itemsPerPage = 10;

  double _calculateTotalAmount() {
    return widget.payments.fold(0.0, (sum, payment) {
      if (payment['status'] == 'paid') {
        final amount = (payment['amount'] as num?)?.toDouble() ?? 0.0;
        return sum + amount;
      }
      return sum;
    });
  }

  List<Map<String, dynamic>> _sortPaymentsByName(
      List<Map<String, dynamic>> payments) {
    return List.from(payments)
      ..sort(
          (a, b) => (a['name'] ?? 'Unknown').compareTo(b['name'] ?? 'Unknown'));
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
                          pw.Text(
                            'PAYMENT REPORT',
                            style: pw.TextStyle(
                              fontSize: 24,
                              fontWeight: pw.FontWeight.bold,
                              color: PdfColors.teal,
                            ),
                          ),
                          pw.Text(
                            '${widget.selectedMonth} ${widget.selectedYear}',
                            style: pw.TextStyle(
                              fontSize: 16,
                              fontWeight: pw.FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                      pw.Text(
                        'Generated: $currentDate',
                        style: const pw.TextStyle(
                          fontSize: 12,
                          color: PdfColors.grey700,
                        ),
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
                      fontSize: 10,
                      color: PdfColors.grey700,
                    ),
                  ),
                  pw.Text(
                    'Page ${context.pageNumber} of ${context.pagesCount}',
                    style: const pw.TextStyle(
                      fontSize: 10,
                      color: PdfColors.grey700,
                    ),
                  ),
                ],
              ),
            );
          },
          build: (pw.Context context) {
            if (widget.selectedMonth.contains('-') ||
                widget.selectedMonth == "Whole Year") {
              return _buildWholeYearTable();
            } else {
              return _buildSingleMonthTable();
            }
          },
        ),
      );

      final directory = await getTemporaryDirectory();
      final file = File(
          '${directory.path}/payment_report_${widget.selectedMonth == "Whole Year" ? "All_Months" : widget.selectedMonth}_${widget.selectedYear}_${widget.selectedPerson.replaceAll(' ', '_')}.pdf');
      await file.writeAsBytes(await pdf.save());

      await Share.shareXFiles(
        [XFile(file.path)],
        text:
            'Payment Report for ${widget.selectedMonth == "Whole Year" ? "All Months" : widget.selectedMonth} ${widget.selectedYear} - ${widget.selectedPerson}',
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
    }
  }

  List<pw.Widget> _buildWholeYearTable() {
    final uniqueNames = widget.payments
        .map((p) => p['name'] as String?)
        .where((name) => name != null)
        .toSet()
        .toList()
        .cast<String>()
      ..sort();

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

    final paymentStatus = <String, Map<String, String>>{};
    for (var name in uniqueNames) {
      paymentStatus[name] = {};
      final userPayments =
          widget.payments.where((p) => p['name'] == name).toList();
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
            pw.Text(
              'Filter: ${widget.selectedFilter}',
              style: const pw.TextStyle(fontSize: 12),
            ),
            pw.Text(
              'Person: ${widget.selectedPerson}',
              style: const pw.TextStyle(fontSize: 12),
            ),
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
          0: const pw.FixedColumnWidth(50), // Increased width for S.No.
          1: const pw.FixedColumnWidth(120), // Increased width for Person
          for (int i = 0; i < months.length; i++)
            i + 2: const pw.FixedColumnWidth(70), // Increased width for months
        },
        defaultVerticalAlignment: pw.TableCellVerticalAlignment.middle,
        children: [
          pw.TableRow(
            decoration: const pw.BoxDecoration(color: PdfColors.teal),
            children: [
              pw.Container(
                padding:
                    const pw.EdgeInsets.symmetric(vertical: 8, horizontal: 4),
                alignment: pw.Alignment.center,
                child: pw.Text(
                  'No',
                  style: pw.TextStyle(
                    color: PdfColors.white,
                    fontWeight: pw.FontWeight.bold,
                    fontSize: 9,
                  ),
                  textAlign: pw.TextAlign.center,
                ),
              ),
              pw.Container(
                padding:
                    const pw.EdgeInsets.symmetric(vertical: 8, horizontal: 4),
                alignment: pw.Alignment.center,
                child: pw.Text(
                  'Person',
                  style: pw.TextStyle(
                    color: PdfColors.white,
                    fontWeight: pw.FontWeight.bold,
                    fontSize: 9,
                  ),
                  textAlign: pw.TextAlign.center,
                ),
              ),
              ...months.map(
                (month) => pw.Container(
                  padding:
                      const pw.EdgeInsets.symmetric(vertical: 8, horizontal: 4),
                  alignment: pw.Alignment.center,
                  child: pw.Text(
                    month.substring(0, 3),
                    style: pw.TextStyle(
                      color: PdfColors.white,
                      fontWeight: pw.FontWeight.bold,
                      fontSize: 9,
                    ),
                    textAlign: pw.TextAlign.center,
                  ),
                ),
              ),
            ],
          ),
          ...uniqueNames.asMap().entries.map((entry) {
            final index = entry.key;
            final name = entry.value;
            return pw.TableRow(
              children: [
                pw.Container(
                  padding:
                      const pw.EdgeInsets.symmetric(vertical: 8, horizontal: 4),
                  alignment: pw.Alignment.center,
                  child: pw.Text(
                    '${index + 1}',
                    style: const pw.TextStyle(fontSize: 7),
                    textAlign: pw.TextAlign.center,
                    softWrap: false, // Prevent text wrapping
                  ),
                ),
                pw.Container(
                  padding:
                      const pw.EdgeInsets.symmetric(vertical: 8, horizontal: 4),
                  alignment: pw.Alignment.centerLeft,
                  child: pw.Text(
                    name,
                    style: const pw.TextStyle(fontSize: 7),
                    textAlign: pw.TextAlign.left,
                    softWrap: false, // Prevent text wrapping
                  ),
                ),
                ...months.map((month) {
                  final status = paymentStatus[name]![month];
                  if (widget.selectedFilter == "Payment received only") {
                    if (status == 'paid') {
                      return pw.Container(
                        padding: const pw.EdgeInsets.symmetric(
                            vertical: 8, horizontal: 4),
                        alignment: pw.Alignment.center,
                        decoration: pw.BoxDecoration(
                          color: PdfColors.green,
                          border: pw.Border.all(color: PdfColors.grey400),
                        ),
                        child: pw.Text(
                          'Paid',
                          style: pw.TextStyle(
                            color: PdfColors.white,
                            fontSize: 7,
                            fontWeight: pw.FontWeight.bold,
                          ),
                          textAlign: pw.TextAlign.center,
                          softWrap: false,
                        ),
                      );
                    } else {
                      return pw.Container(
                        padding: const pw.EdgeInsets.symmetric(
                            vertical: 8, horizontal: 4),
                        alignment: pw.Alignment.center,
                        child: pw.Text(
                          '',
                          style: const pw.TextStyle(fontSize: 7),
                          textAlign: pw.TextAlign.center,
                        ),
                      );
                    }
                  } else if (widget.selectedFilter ==
                      "Payments to be received") {
                    if (status == 'unpaid') {
                      return pw.Container(
                        padding: const pw.EdgeInsets.symmetric(
                            vertical: 8, horizontal: 4),
                        alignment: pw.Alignment.center,
                        child: pw.Text(
                          'Unpaid',
                          style: pw.TextStyle(
                            color: PdfColors.red,
                            fontSize: 7,
                            fontWeight: pw.FontWeight.bold,
                          ),
                          textAlign: pw.TextAlign.center,
                          softWrap: false,
                        ),
                      );
                    } else {
                      return pw.Container(
                        padding: const pw.EdgeInsets.symmetric(
                            vertical: 8, horizontal: 4),
                        alignment: pw.Alignment.center,
                        child: pw.Text(
                          '',
                          style: const pw.TextStyle(fontSize: 7),
                          textAlign: pw.TextAlign.center,
                        ),
                      );
                    }
                  } else {
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
                      padding: const pw.EdgeInsets.symmetric(
                          vertical: 8, horizontal: 4),
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
                          fontSize: 7,
                          fontWeight: pw.FontWeight.bold,
                        ),
                        textAlign: pw.TextAlign.center,
                        softWrap: false,
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
    final sortedPayments = _sortPaymentsByName(widget.payments);

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
                    pw.Text(
                      'Report Details',
                      style: pw.TextStyle(
                        fontWeight: pw.FontWeight.bold,
                        fontSize: 14,
                      ),
                    ),
                    pw.SizedBox(height: 8),
                    pw.Text('Filter: ${widget.selectedFilter}'),
                    pw.Text('Person: ${widget.selectedPerson}'),
                  ],
                ),
                pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.end,
                  children: [
                    pw.Text(
                      'Summary',
                      style: pw.TextStyle(
                        fontWeight: pw.FontWeight.bold,
                        fontSize: 14,
                      ),
                    ),
                    pw.SizedBox(height: 8),
                    pw.Text(
                        'Total Payments: ${widget.payments.where((p) => p['status'] == 'paid').length}'),
                    pw.Text(
                      'Total Amount: ${totalAmount.toStringAsFixed(0)}',
                      style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
                    ),
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
      pw.SizedBox(height: 20),
      pw.Text(
        'Payment Details',
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
          0: const pw.FixedColumnWidth(120), // Name
          1: const pw.FixedColumnWidth(80), // Amount
          2: const pw.FixedColumnWidth(100), // Payment Method
          3: const pw.FixedColumnWidth(100), // Payment For
          4: const pw.FixedColumnWidth(80), // Date Paid
          5: const pw.FixedColumnWidth(80), // Status
        },
        defaultVerticalAlignment: pw.TableCellVerticalAlignment.middle,
        children: [
          pw.TableRow(
            decoration: const pw.BoxDecoration(color: PdfColors.teal),
            children: [
              pw.Container(
                padding:
                    const pw.EdgeInsets.symmetric(vertical: 8, horizontal: 4),
                alignment: pw.Alignment.center,
                child: pw.Text(
                  'Name',
                  style: pw.TextStyle(
                    color: PdfColors.white,
                    fontWeight: pw.FontWeight.bold,
                    fontSize: 9,
                  ),
                  textAlign: pw.TextAlign.center,
                ),
              ),
              pw.Container(
                padding:
                    const pw.EdgeInsets.symmetric(vertical: 8, horizontal: 4),
                alignment: pw.Alignment.center,
                child: pw.Text(
                  'Amount',
                  style: pw.TextStyle(
                    color: PdfColors.white,
                    fontWeight: pw.FontWeight.bold,
                    fontSize: 9,
                  ),
                  textAlign: pw.TextAlign.center,
                ),
              ),
              pw.Container(
                padding:
                    const pw.EdgeInsets.symmetric(vertical: 8, horizontal: 4),
                alignment: pw.Alignment.center,
                child: pw.Text(
                  'Payment Method',
                  style: pw.TextStyle(
                    color: PdfColors.white,
                    fontWeight: pw.FontWeight.bold,
                    fontSize: 9,
                  ),
                  textAlign: pw.TextAlign.center,
                ),
              ),
              pw.Container(
                padding:
                    const pw.EdgeInsets.symmetric(vertical: 8, horizontal: 4),
                alignment: pw.Alignment.center,
                child: pw.Text(
                  'Payment For',
                  style: pw.TextStyle(
                    color: PdfColors.white,
                    fontWeight: pw.FontWeight.bold,
                    fontSize: 9,
                  ),
                  textAlign: pw.TextAlign.center,
                ),
              ),
              pw.Container(
                padding:
                    const pw.EdgeInsets.symmetric(vertical: 8, horizontal: 4),
                alignment: pw.Alignment.center,
                child: pw.Text(
                  'Date Paid',
                  style: pw.TextStyle(
                    color: PdfColors.white,
                    fontWeight: pw.FontWeight.bold,
                    fontSize: 9,
                  ),
                  textAlign: pw.TextAlign.center,
                ),
              ),
              pw.Container(
                padding:
                    const pw.EdgeInsets.symmetric(vertical: 8, horizontal: 4),
                alignment: pw.Alignment.center,
                child: pw.Text(
                  'Status',
                  style: pw.TextStyle(
                    color: PdfColors.white,
                    fontWeight: pw.FontWeight.bold,
                    fontSize: 9,
                  ),
                  textAlign: pw.TextAlign.center,
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
                  padding:
                      const pw.EdgeInsets.symmetric(vertical: 8, horizontal: 4),
                  alignment: pw.Alignment.centerLeft,
                  child: pw.Text(
                    payment['name'] ?? 'Unknown',
                    style: const pw.TextStyle(fontSize: 7),
                    textAlign: pw.TextAlign.left,
                    softWrap: false,
                  ),
                ),
                pw.Container(
                  padding:
                      const pw.EdgeInsets.symmetric(vertical: 8, horizontal: 4),
                  alignment: pw.Alignment.centerRight,
                  child: pw.Text(
                    payment['status'] == 'paid'
                        ? '${(payment['amount'] as num?)?.toStringAsFixed(0) ?? '0'}'
                        : '-',
                    style: const pw.TextStyle(fontSize: 7),
                    textAlign: pw.TextAlign.right,
                    softWrap: false,
                  ),
                ),
                pw.Container(
                  padding:
                      const pw.EdgeInsets.symmetric(vertical: 8, horizontal: 4),
                  alignment: pw.Alignment.center,
                  child: pw.Text(
                    payment['status'] == 'paid'
                        ? (payment['paymentMethod'] ?? 'Unknown')
                        : '-',
                    style: const pw.TextStyle(fontSize: 7),
                    textAlign: pw.TextAlign.center,
                    softWrap: false,
                  ),
                ),
                pw.Container(
                  padding:
                      const pw.EdgeInsets.symmetric(vertical: 8, horizontal: 4),
                  alignment: pw.Alignment.center,
                  child: pw.Text(
                    paymentFor,
                    style: const pw.TextStyle(fontSize: 7),
                    textAlign: pw.TextAlign.center,
                    softWrap: false,
                  ),
                ),
                pw.Container(
                  padding:
                      const pw.EdgeInsets.symmetric(vertical: 8, horizontal: 4),
                  alignment: pw.Alignment.center,
                  child: pw.Text(
                    payment['status'] == 'paid' ? datePaid : '-',
                    style: const pw.TextStyle(fontSize: 7),
                    textAlign: pw.TextAlign.center,
                    softWrap: false,
                  ),
                ),
                pw.Container(
                  padding:
                      const pw.EdgeInsets.symmetric(vertical: 8, horizontal: 4),
                  alignment: pw.Alignment.center,
                  child: pw.Text(
                    status,
                    style: pw.TextStyle(
                      fontSize: 7,
                      color: status == 'Paid' ? PdfColors.green : PdfColors.red,
                      fontWeight: pw.FontWeight.bold,
                    ),
                    textAlign: pw.TextAlign.center,
                    softWrap: false,
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
            pw.Text(
              'Note: ',
              style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
            ),
            pw.Expanded(
              child: pw.Text(
                'This is an auto-generated report created by PMJ Application. For any queries regarding this report, please contact support.',
              ),
            ),
          ],
        ),
      ),
    ];
  }

  @override
  Widget build(BuildContext context) {
    final totalAmount = _calculateTotalAmount();
    final sortedPayments = _sortPaymentsByName(widget.payments);
    final totalItems = sortedPayments.length;
    final totalPages = (totalItems / _itemsPerPage).ceil();
    final startIndex = (_currentPage - 1) * _itemsPerPage;
    final endIndex = (_currentPage * _itemsPerPage).clamp(0, totalItems);
    final currentPagePayments = sortedPayments.sublist(startIndex, endIndex);

    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Report - ${widget.selectedMonth == "Whole Year" ? "All Months" : widget.selectedMonth} ${widget.selectedYear}',
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
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Flexible(
                  child: Text(
                    'Filter: ${widget.selectedFilter}',
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
                    'Person: ${widget.selectedPerson}',
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
            Expanded(
              child: SingleChildScrollView(
                scrollDirection: Axis.vertical,
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: DataTable(
                    columnSpacing: 16,
                    headingRowColor: WidgetStateProperty.all(Colors.grey[100]),
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
                    rows: currentPagePayments.asMap().entries.map((entry) {
                      final index = entry.key + startIndex;
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
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Total Payments: ${widget.payments.where((p) => p['status'] == 'paid').length}',
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
            if (totalPages > 1)
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  IconButton(
                    icon: const Icon(Icons.arrow_back_ios),
                    onPressed: _currentPage > 1
                        ? () {
                            setState(() {
                              _currentPage--;
                            });
                          }
                        : null,
                  ),
                  Text(
                    'Page $_currentPage of $totalPages',
                    style: const TextStyle(
                      fontFamily: "Inter",
                      fontSize: 14,
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.arrow_forward_ios),
                    onPressed: _currentPage < totalPages
                        ? () {
                            setState(() {
                              _currentPage++;
                            });
                          }
                        : null,
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
      ),
    );
  }
}
