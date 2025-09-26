import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:pmj_application/models/donation_model.dart';
import 'package:pmj_application/models/person_model.dart';
import 'package:pmj_application/services/local_database_service.dart';
import 'package:shimmer/shimmer.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:intl/intl.dart';
import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:pdf/pdf.dart';
import 'package:share_plus/share_plus.dart';
import 'package:photo_view/photo_view.dart';
import '../services/image_cache_service.dart';
import '../assets/custom%20widgets/shimmer_widgets.dart';
import 'dart:io';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:url_launcher/url_launcher.dart';
import '../models/person_model.dart';
import '../services/local_database_service.dart';
import '../services/image_cache_service.dart';
import 'donorAdd.dart';

// Custom page route with slide transition from right to left
class SlidingPageTransitionRL extends PageRouteBuilder {
  final Widget page;

  SlidingPageTransitionRL({required this.page})
      : super(
          transitionDuration: const Duration(milliseconds: 220),
          reverseTransitionDuration: const Duration(milliseconds: 200),
          pageBuilder: (context, animation, secondaryAnimation) => page,
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            const begin = Offset(0.06, 0.0); // shorter travel for snappier feel
            const end = Offset.zero;
            const curve = Curves.easeOutCubic;

            final curved = CurvedAnimation(parent: animation, curve: curve);
            final slide = Tween(begin: begin, end: end).animate(curved);
            final fade = Tween<double>(begin: 0.0, end: 1.0).animate(curved);

            return FadeTransition(
              opacity: fade,
              child: SlideTransition(
                position: slide,
                child: child,
              ),
            );
          },
        );
}

Future<Map<String, dynamic>> fetchDonorData(String donorId) async {
  try {
    DocumentSnapshot doc = await FirebaseFirestore.instance
        .collection('donors')
        .doc(donorId)
        .get();
    if (doc.exists) {
      final raw = doc.data() as Map<String, dynamic>? ?? {};
      final imageUrl = (raw['imageUrl']?.toString() ?? '').trim();
      final photoUrl = (raw['photoUrl']?.toString() ?? '').trim();
      final data = {
        'name': raw['name'] ?? 'Unknown',
        'number': raw['number'] ?? 'No Number',
        'address': raw['address'] ?? 'No Address',
        'imageUrl': imageUrl.isNotEmpty ? imageUrl : photoUrl,
        'amount': (raw['amount'] as num?)?.toDouble() ?? 0.0,
      };
      return data;
    }
    return {
      'name': 'Unknown',
      'number': 'No Number',
      'address': 'No Address',
      'imageUrl': '',
      'amount': 0.0,
    };
  } catch (e) {
    print('Error fetching donor data: $e');
    return {
      'name': 'Unknown',
      'number': 'No Number',
      'address': 'No Address',
      'imageUrl': '',
      'amount': 0.0,
    };
  }
}

class donorDetails extends StatefulWidget {
  final String donorId;

  const donorDetails({super.key, required this.donorId});

  @override
  State<donorDetails> createState() => _donorDetailsState();
}

class _donorDetailsState extends State<donorDetails> {
  String? _selectedYear;
  late List<String> _years;
  bool _isLoadingPDF = false;
  final LocalDatabaseService _localDb = LocalDatabaseService();

  // Show logout confirmation dialog
  Future<void> showLogoutConfirmation(BuildContext context) async {
    return showDialog<void>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Logout'),
          content: const Text('Are you sure you want to logout?'),
          actions: <Widget>[
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () async {
                await FirebaseAuth.instance.signOut();
                if (mounted) {
                  Navigator.of(context).pushNamedAndRemoveUntil(
                    '/login',
                    (route) => false,
                  );
                }
              },
              child: const Text('Logout'),
            ),
          ],
        );
      },
    );
  }

  // Create a custom page route with slide transition
  static Route _createRoute(Widget page) {
    return PageRouteBuilder(
      pageBuilder: (context, animation, secondaryAnimation) => page,
      transitionsBuilder: (context, animation, secondaryAnimation, child) {
        const begin = Offset(1.0, 0.0);
        const end = Offset.zero;
        const curve = Curves.easeInOut;

        var tween = Tween(begin: begin, end: end).chain(
          CurveTween(curve: curve),
        );

        return SlideTransition(
          position: animation.drive(tween),
          child: child,
        );
      },
    );
  }

  // Navigate to edit donor screen
  void _navigateToEditDonor() async {
    final donorData = await fetchDonorData(widget.donorId);

    final result = await Navigator.of(context).push(
      SlidingPageTransitionRL(
          page: DonorAdd(
        donorId: widget.donorId,
        initialName: donorData['name'],
        initialNumber: donorData['number'],
        initialAddress: donorData['address'],
        initialAmount: donorData['amount'].toString(),
        initialImageUrl: donorData['imageUrl'],
      )),
    );

    if (result == true && mounted) {
      setState(() {}); // Trigger rebuild to refresh FutureBuilder
    }
  }

  @override
  void initState() {
    super.initState();
    final currentYear = DateTime.now().year;
    _years = List.generate(5, (index) => (currentYear - index).toString());
    _selectedYear = currentYear.toString(); // Default to current year
  }

  Future<List<Map<String, dynamic>>> _fetchYearlyPayments() async {
    final year = _selectedYear ?? DateTime.now().year.toString();
    final currentYear = DateTime.now().year.toString();
    final currentMonth = DateTime.now().month;
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
      'December',
    ];
    // Only show up to current month if current year, else all months
    final monthsToShow =
        months.sublist(0, year == currentYear ? currentMonth : 12);
    final snapshot = await FirebaseFirestore.instance
        .collection('donors')
        .doc(widget.donorId)
        .collection('paymentStatus')
        .where('year', isEqualTo: year)
        .get();
    final paymentMap = <String, Map<String, dynamic>>{};
    for (var doc in snapshot.docs) {
      final data = doc.data();
      final month = data['month'] as String?;
      if (month != null && monthsToShow.contains(month)) {
        paymentMap[month] = data;
      }
    }
    // Fill only monthsToShow
    return monthsToShow.map((month) {
      return paymentMap[month] ??
          {
            'month': month,
            'year': year,
            'status': 'unpaid',
            'amount': null,
            'paymentMethod': null,
          };
    }).toList();
  }

  Future<void> _generateAndDownloadPDF() async {
    setState(() => _isLoadingPDF = true);
    // Show modal loading dialog
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => Dialog(
        backgroundColor: Colors.white,
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
                'Generating PDF...',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: Colors.grey[800],
                  fontFamily: 'Inter',
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Please wait while we prepare your document',
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
    try {
      final payments = await _fetchYearlyPayments();
      final donorData = await fetchDonorData(widget.donorId);
      final pdf = pw.Document();
      final dateFormat = DateFormat('dd MMMM yyyy');
      final currentDate = dateFormat.format(DateTime.now());
      final year = _selectedYear ?? DateTime.now().year.toString();
      pdf.addPage(
        pw.MultiPage(
          pageFormat: PdfPageFormat.a4,
          margin: const pw.EdgeInsets.all(24),
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
                            'DONATION REPORT',
                            style: pw.TextStyle(
                              fontSize: 20,
                              fontWeight: pw.FontWeight.bold,
                              color: PdfColors.teal,
                            ),
                          ),
                          pw.Text(
                            '${donorData['name'] ?? 'Donor'}',
                            style: pw.TextStyle(
                              fontSize: 14,
                              fontWeight: pw.FontWeight.bold,
                            ),
                          ),
                          pw.Text(
                            'Year $year',
                            style: pw.TextStyle(
                              fontSize: 12,
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
                    'PMJ App - Donor Yearly Report',
                    style: const pw.TextStyle(
                      fontSize: 8,
                      color: PdfColors.grey700,
                    ),
                  ),
                  pw.Text(
                    'Page  {context.pageNumber} of  {context.pagesCount}',
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
                'Donation Details',
                style: pw.TextStyle(
                  fontSize: 14,
                  fontWeight: pw.FontWeight.bold,
                  color: PdfColors.teal,
                ),
              ),
              pw.SizedBox(height: 10),
              pw.Table(
                border: pw.TableBorder.all(color: PdfColors.grey400),
                columnWidths: {
                  0: const pw.FixedColumnWidth(60), // Month
                  1: const pw.FixedColumnWidth(60), // Status
                  2: const pw.FixedColumnWidth(60), // Amount
                  3: const pw.FixedColumnWidth(80), // Payment Method
                },
                defaultVerticalAlignment: pw.TableCellVerticalAlignment.middle,
                children: [
                  pw.TableRow(
                    decoration: const pw.BoxDecoration(color: PdfColors.teal),
                    children: [
                      pw.Container(
                        padding: const pw.EdgeInsets.all(6),
                        alignment: pw.Alignment.center,
                        child: pw.Text(
                          'Month',
                          style: pw.TextStyle(
                            color: PdfColors.white,
                            fontWeight: pw.FontWeight.bold,
                            fontSize: 10,
                          ),
                        ),
                      ),
                      pw.Container(
                        padding: const pw.EdgeInsets.all(6),
                        alignment: pw.Alignment.center,
                        child: pw.Text(
                          'Status',
                          style: pw.TextStyle(
                            color: PdfColors.white,
                            fontWeight: pw.FontWeight.bold,
                            fontSize: 10,
                          ),
                        ),
                      ),
                      pw.Container(
                        padding: const pw.EdgeInsets.all(6),
                        alignment: pw.Alignment.center,
                        child: pw.Text(
                          'Amount',
                          style: pw.TextStyle(
                            color: PdfColors.white,
                            fontWeight: pw.FontWeight.bold,
                            fontSize: 10,
                          ),
                        ),
                      ),
                      pw.Container(
                        padding: const pw.EdgeInsets.all(6),
                        alignment: pw.Alignment.center,
                        child: pw.Text(
                          'Method',
                          style: pw.TextStyle(
                            color: PdfColors.white,
                            fontWeight: pw.FontWeight.bold,
                            fontSize: 10,
                          ),
                        ),
                      ),
                    ],
                  ),
                  ...payments.map((payment) {
                    final month = payment['month'] ?? '';
                    final status = payment['status'] ?? 'unpaid';
                    final amount = payment['amount'] != null
                        ? payment['amount'].toString()
                        : '-';
                    final method = payment['paymentMethod'] ?? '-';
                    return pw.TableRow(
                      children: [
                        pw.Container(
                          padding: const pw.EdgeInsets.all(6),
                          alignment: pw.Alignment.center,
                          child: pw.Text(month,
                              style: const pw.TextStyle(fontSize: 9)),
                        ),
                        pw.Container(
                          padding: const pw.EdgeInsets.all(6),
                          alignment: pw.Alignment.center,
                          child: pw.Text(
                            status == 'paid' ? 'Paid' : 'Unpaid',
                            style: pw.TextStyle(
                              fontSize: 9,
                              color: status == 'paid'
                                  ? PdfColors.green
                                  : PdfColors.red,
                              fontWeight: pw.FontWeight.bold,
                            ),
                          ),
                        ),
                        pw.Container(
                          padding: const pw.EdgeInsets.all(6),
                          alignment: pw.Alignment.center,
                          child: pw.Text(amount,
                              style: const pw.TextStyle(fontSize: 9)),
                        ),
                        pw.Container(
                          padding: const pw.EdgeInsets.all(6),
                          alignment: pw.Alignment.center,
                          child: pw.Text(method,
                              style: const pw.TextStyle(fontSize: 9)),
                        ),
                      ],
                    );
                  }).toList(),
                ],
              ),
              pw.SizedBox(height: 20),
              pw.Container(
                padding: const pw.EdgeInsets.all(10),
                decoration: pw.BoxDecoration(
                  border: pw.Border.all(color: PdfColors.grey400),
                  borderRadius:
                      const pw.BorderRadius.all(pw.Radius.circular(4)),
                ),
                child: pw.Text(
                  'This is an auto-generated report for yearly donations. For any queries, contact support.',
                  style: const pw.TextStyle(fontSize: 9),
                ),
              ),
            ];
          },
        ),
      );
      final directory = await getTemporaryDirectory();
      final file = File(
          '${directory.path}/donation_report_${donorData['name']}_${year}.pdf');
      await file.writeAsBytes(await pdf.save());
      await Share.shareXFiles(
        [XFile(file.path)],
        text: 'Donation Report for ${donorData['name']} - $year',
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
      setState(() => _isLoadingPDF = false);
      Navigator.of(context, rootNavigator: true)
          .pop(); // Dismiss loading dialog
    }
  }

  Future<void> _deleteDonor() async {
    try {
      // Delete all paymentStatus documents in the subcollection
      final paymentStatusQuery = await FirebaseFirestore.instance
          .collection('donors')
          .doc(widget.donorId)
          .collection('paymentStatus')
          .get();

      // Delete each paymentStatus document
      for (var doc in paymentStatusQuery.docs) {
        await doc.reference.delete();
      }

      // Delete the donor document
      await FirebaseFirestore.instance
          .collection('donors')
          .doc(widget.donorId)
          .delete();

      // Show success message and navigate back
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Donor deleted successfully')),
      );
      Navigator.pop(context);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error deleting donor: $e')),
      );
    }
  }

  Future<void> _makePhoneCall(String phoneNumber) async {
    // Clean the phone number (remove spaces, dashes, etc.)
    final cleanNumber = phoneNumber.replaceAll(RegExp(r'[^0-9+]'), '');
    
    // Use DIAL action instead of CALL to avoid permission issues
    final Uri phoneUri = Uri(scheme: 'tel', path: cleanNumber);
    
    try {
      if (await canLaunchUrl(phoneUri)) {
        await launchUrl(phoneUri, mode: LaunchMode.externalApplication);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Could not launch phone dialer'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error launching phone dialer: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _openWhatsApp(String phoneNumber) async {
    // Clean the phone number and ensure it starts with country code
    String cleanNumber = phoneNumber.replaceAll(RegExp(r'[^0-9+]'), '');
    
    // If number doesn't start with +, assume it's Indian number and add +91
    if (!cleanNumber.startsWith('+')) {
      if (cleanNumber.startsWith('91')) {
        cleanNumber = '+$cleanNumber';
      } else {
        cleanNumber = '+91$cleanNumber';
      }
    }
    
    // Remove the + for WhatsApp URL format
    final whatsappNumber = cleanNumber.replaceFirst('+', '');
    final Uri whatsappUri = Uri.parse('https://wa.me/$whatsappNumber');
    
    try {
      if (await canLaunchUrl(whatsappUri)) {
        await launchUrl(whatsappUri, mode: LaunchMode.externalApplication);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('WhatsApp is not installed or could not be opened'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error opening WhatsApp: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void _handleDeleteConfirmation(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          content: Text(
            'Are you sure you want to Delete?',
            style: TextStyle(
                fontFamily: "Inter", fontWeight: FontWeight.w400, fontSize: 12),
          ),
          actions: <Widget>[
            Container(
              height: 30,
              width: 70,
              margin: EdgeInsets.only(right: 4, bottom: 4),
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                    foregroundColor: Colors.white,
                    backgroundColor: Color(0xffF44336),
                    elevation: 0),
                child: Text(
                  'Cancel',
                  style: TextStyle(
                      fontFamily: "Inter",
                      fontWeight: FontWeight.bold,
                      fontSize: 9),
                ),
                onPressed: () {
                  Navigator.of(context).pop();
                },
              ),
            ),
            Container(
              height: 30,
              width: 70,
              margin: EdgeInsets.only(right: 0, bottom: 4),
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                    foregroundColor: Colors.white,
                    backgroundColor: Color(0xffF44336),
                    elevation: 0),
                child: Text(
                  'Delete',
                  style: TextStyle(
                      fontFamily: "Inter",
                      fontWeight: FontWeight.bold,
                      fontSize: 9),
                ),
                onPressed: () async {
                  Navigator.of(context).pop();
                  await _deleteDonor();
                },
              ),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color(0xffFFFFFF),
      appBar: PreferredSize(
        preferredSize: Size.fromHeight(100),
        child: AppBar(
          elevation: 0,
          backgroundColor: Color(0xff1BA3A1),
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
                    padding: const EdgeInsets.only(left: 8.0),
                    child: Image.asset(
                      'lib/assets/images/pmj white.png',
                      height: 50,
                    ),
                  ),
                  // Container(
                  //   height: 26,
                  //   width: 84,
                  //   child: ElevatedButton(
                  //     onPressed: () => showLogoutConfirmation(context),
                  //     style: ElevatedButton.styleFrom(
                  //         foregroundColor: Colors.black,
                  //         backgroundColor: Colors.white,
                  //         shape: RoundedRectangleBorder(
                  //             borderRadius: BorderRadius.circular(2)),
                  //         elevation: 0),
                  //     child: Center(
                  //       child: Text(
                  //         'Logout',
                  //         style: TextStyle(
                  //             fontSize: 10,
                  //             fontWeight: FontWeight.w600,
                  //             fontFamily: "Inter"),
                  //       ),
                  //     ),
                  //   ),
                  // ),
                ],
              ),
            ),
          ),
        ),
      ),
      body: FutureBuilder<Map<String, dynamic>>(
        future: fetchDonorData(widget.donorId),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return DonorDetailsShimmer();
          }
          if (snapshot.hasError || !snapshot.hasData) {
            return Center(child: Text('Error loading donor details'));
          }

          final donorData = snapshot.data!;
          final String donorName = donorData['name'] ?? 'Unknown';
          final String donorNumber = donorData['number'] ?? 'No Number';
          final String donorAddress = donorData['address'] ?? 'No Address';
          final double donorAmount =
              (donorData['amount'] as num?)?.toDouble() ?? 0.0;
          final String donorImageUrl = donorData['imageUrl'] ?? '';

          return Stack(
            children: [
              Column(
                children: [
                  ListTile(
                    leading: GestureDetector(
                      onTap: () => Navigator.pop(context),
                      child: SvgPicture.asset('lib/assets/images/Back.svg',
                          height: 40, width: 40),
                    ),
                    title: Center(
                      child: Text(
                        'Details',
                        style: TextStyle(
                            fontWeight: FontWeight.w600, fontSize: 16),
                      ),
                    ),
                    trailing: PopupMenuButton<String>(
                      icon: SvgPicture.asset(
                          'lib/assets/images/settingsnew.svg',
                          height: 40,
                          width: 40),
                      onSelected: (value) async {
                        if (value == 'download_pdf') {
                          await _generateAndDownloadPDF();
                        } else if (value == 'call') {
                          await _makePhoneCall(donorNumber);
                        } else if (value == 'whatsapp') {
                          await _openWhatsApp(donorNumber);
                        }
                      },
                      itemBuilder: (context) => [
                        PopupMenuItem<String>(
                          value: 'call',
                          child: Container(
                            padding: const EdgeInsets.symmetric(vertical: 6),
                            child: Row(
                              children: [
                                Container(
                                  width: 28,
                                  height: 28,
                                  decoration: BoxDecoration(
                                    color: const Color(0x1F4CAF50), // green tint
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                  child: const Icon(
                                    Icons.phone,
                                    color: Color(0xff4CAF50),
                                    size: 18,
                                  ),
                                ),
                                const SizedBox(width: 12),
                                const Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Text(
                                        'Call Donor',
                                        style: TextStyle(
                                          fontFamily: 'Inter',
                                          fontSize: 14,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                      SizedBox(height: 2),
                                      Text(
                                        'Make a phone call',
                                        style: TextStyle(
                                          fontFamily: 'Inter',
                                          fontSize: 11,
                                          color: Color(0xff817D8A),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        PopupMenuItem<String>(
                          value: 'whatsapp',
                          child: Container(
                            padding: const EdgeInsets.symmetric(vertical: 6),
                            child: Row(
                              children: [
                                Container(
                                  width: 28,
                                  height: 28,
                                  decoration: BoxDecoration(
                                    color: const Color(0x1F25D366), // WhatsApp green tint
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                  child: const Icon(
                                    Icons.chat,
                                    color: Color(0xff25D366),
                                    size: 18,
                                  ),
                                ),
                                const SizedBox(width: 12),
                                const Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Text(
                                        'WhatsApp',
                                        style: TextStyle(
                                          fontFamily: 'Inter',
                                          fontSize: 14,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                      SizedBox(height: 2),
                                      Text(
                                        'Send a message',
                                        style: TextStyle(
                                          fontFamily: 'Inter',
                                          fontSize: 11,
                                          color: Color(0xff817D8A),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        PopupMenuItem<String>(
                          value: 'download_pdf',
                          child: Container(
                            padding: const EdgeInsets.symmetric(vertical: 6),
                            child: Row(
                              children: [
                                Container(
                                  width: 28,
                                  height: 28,
                                  decoration: BoxDecoration(
                                    color: const Color(0x1F1BA3A1), // teal tint
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                  child: const Icon(
                                    Icons.picture_as_pdf,
                                    color: Color(0xff1BA3A1),
                                    size: 18,
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    mainAxisSize: MainAxisSize.min,
                                    children: const [
                                      Text(
                                        'Download Yearly PDF',
                                        style: TextStyle(
                                          fontFamily: 'Inter',
                                          fontSize: 14,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                      SizedBox(height: 2),
                                      Text(
                                        'Share or save the report',
                                        style: TextStyle(
                                          fontFamily: 'Inter',
                                          fontSize: 11,
                                          color: Color(0xff817D8A),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                if (_isLoadingPDF) const SizedBox(width: 8),
                                if (_isLoadingPDF)
                                  const SizedBox(
                                    width: 16,
                                    height: 16,
                                    child: CircularProgressIndicator(
                                        strokeWidth: 2),
                                  ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    height: 160,
                    width: MediaQuery.of(context).size.width,
                    child: Stack(
                      children: [
                        Positioned(
                          left: 20,
                          top: 20,
                          child: GestureDetector(
                            onTap: () {
                              if (donorImageUrl.isNotEmpty) {
                                Navigator.push(
                                    context,
                                    SlidingPageTransitionRL(
                                        page: FullScreenImageViewer(
                                      imageUrl: donorImageUrl,
                                    )));
                              }
                            },
                            child: Hero(
                              tag: 'donor_avatar_${widget.donorId}',
                              child: SizedBox(
                                width: 100,
                                height: 100,
                                child: ClipOval(
                                  child: Builder(
                                    builder: (context) {
                                      if (donorImageUrl.isEmpty) {
                                        return Container(
                                          color: const Color(0xff1BA3A1),
                                          child: Center(
                                            child: Text(
                                              donorName.isNotEmpty
                                                  ? donorName[0].toUpperCase()
                                                  : '',
                                              style: const TextStyle(
                                                fontSize: 32,
                                                fontWeight: FontWeight.bold,
                                                color: Colors.white,
                                              ),
                                            ),
                                          ),
                                        );
                                      }

                                      return FutureBuilder<ImageProvider?>(
                                        future: ImageCacheService()
                                            .getImageProvider(donorImageUrl),
                                        builder: (context, snapshot) {
                                          if (snapshot.connectionState ==
                                              ConnectionState.waiting) {
                                            return Shimmer.fromColors(
                                              baseColor:
                                                  const Color(0xFFE0E0E0),
                                              highlightColor:
                                                  const Color(0xFFF5F5F5),
                                              child: Container(
                                                  color: Colors.white),
                                            );
                                          }

                                          if (snapshot.hasData &&
                                              snapshot.data != null) {
                                            return Image(
                                              image: snapshot.data!,
                                              fit: BoxFit.cover,
                                              frameBuilder: (context,
                                                  child,
                                                  frame,
                                                  wasSynchronouslyLoaded) {
                                                if (wasSynchronouslyLoaded)
                                                  return child;
                                                return AnimatedOpacity(
                                                  opacity:
                                                      frame == null ? 0 : 1,
                                                  duration: const Duration(
                                                      milliseconds: 300),
                                                  curve: Curves.easeInOut,
                                                  child: child,
                                                );
                                              },
                                              errorBuilder:
                                                  (context, error, stackTrace) {
                                                return Container(
                                                  color:
                                                      const Color(0xff1BA3A1),
                                                  child: Center(
                                                    child: Text(
                                                      donorName.isNotEmpty
                                                          ? donorName[0]
                                                              .toUpperCase()
                                                          : '',
                                                      style: const TextStyle(
                                                        fontSize: 32,
                                                        fontWeight:
                                                            FontWeight.bold,
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
                                                donorName.isNotEmpty
                                                    ? donorName[0].toUpperCase()
                                                    : '',
                                                style: const TextStyle(
                                                  fontSize: 32,
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
                            ),
                          ),
                        ),
                        Positioned(
                          top: 17,
                          right: 20,
                          child: Container(
                            width: 212,
                            height: 30,
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  donorName,
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontFamily: "Inter",
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                Text(
                                  '₹${donorAmount.toStringAsFixed(0)}',
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontFamily: "Inter",
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        Positioned(
                          right: 22,
                          top: 42,
                          child: Container(
                            width: 212,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  donorNumber,
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                    color: Color(0xff817D8A),
                                    fontFamily: "Inter",
                                  ),
                                ),
                                Text(
                                  donorAddress,
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w400,
                                    color: Color(0xff817D8A),
                                    fontFamily: "Inter",
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        Positioned(
                          right: 22,
                          bottom: 0,
                          child: Row(
                            children: [
                              Container(
                                height: 26,
                                width: 102,
                                margin: EdgeInsets.only(right: 4, bottom: 4),
                                child: ElevatedButton(
                                  style: ElevatedButton.styleFrom(
                                    foregroundColor: Colors.white,
                                    backgroundColor: Color(0xff29B6F6),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(4),
                                    ),
                                    elevation: 0,
                                  ),
                                  child: Text(
                                    'Edit',
                                    style: TextStyle(
                                      fontFamily: "Inter",
                                      fontWeight: FontWeight.w400,
                                      fontSize: 11,
                                    ),
                                  ),
                                  onPressed: () {
                                    _navigateToEditDonor();
                                  },
                                ),
                              ),
                              SizedBox(width: 3),
                              Container(
                                height: 26,
                                width: 102,
                                margin: EdgeInsets.only(right: 0, bottom: 4),
                                child: ElevatedButton(
                                  style: ElevatedButton.styleFrom(
                                    foregroundColor: Colors.white,
                                    backgroundColor: Color(0xffF44336),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(4),
                                    ),
                                    elevation: 0,
                                  ),
                                  child: Text(
                                    'Delete',
                                    style: TextStyle(
                                      fontFamily: "Inter",
                                      fontWeight: FontWeight.w400,
                                      fontSize: 11,
                                    ),
                                  ),
                                  onPressed: () =>
                                      _handleDeleteConfirmation(context),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  Padding(
                    padding:
                        const EdgeInsets.only(top: 15.0, left: 24, right: 24),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Payment History',
                          style: TextStyle(
                              fontSize: 14,
                              fontFamily: "Inter",
                              fontWeight: FontWeight.w600),
                        ),
                        Container(
                          height: 40,
                          width: 88,
                          padding: EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            border: Border.all(
                                color: Color(0xFF817D8A), width: 1.0),
                            borderRadius: BorderRadius.circular(5),
                          ),
                          child: DropdownButton<String>(
                            isExpanded: true,
                            value: _selectedYear,
                            hint: Text(
                              DateTime.now().year.toString(),
                              style: TextStyle(
                                  fontSize: 10,
                                  fontFamily: "Inter",
                                  fontWeight: FontWeight.w600),
                            ),
                            items: _years.map((String year) {
                              return DropdownMenuItem<String>(
                                value: year,
                                child: Text(
                                  year,
                                  style: TextStyle(
                                      fontSize: 10,
                                      fontFamily: "Inter",
                                      fontWeight: FontWeight.w600),
                                ),
                              );
                            }).toList(),
                            onChanged: (String? newValue) {
                              setState(() {
                                _selectedYear = newValue;
                              });
                            },
                            underline: SizedBox(),
                            icon: SvgPicture.asset('lib/assets/images/dd.svg'),
                            dropdownColor: Colors.white,
                            elevation: 0,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Expanded(
                    child: PaymentHistoryList(
                        donorId: widget.donorId, selectedYear: _selectedYear),
                  ),
                  SizedBox(height: 60),
                ],
              ),
              Positioned(
                bottom: 10,
                left: 16,
                right: 16,
                child: SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      foregroundColor: Colors.white,
                      backgroundColor: Color(0xff1BA3A1),
                      elevation: 0.0,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(4)),
                    ),
                    onPressed: () {
                      showModalBottomSheet(
                        elevation: 0,
                        barrierColor: Colors.black.withOpacity(0.4),
                        context: context,
                        builder: (BuildContext context) {
                          return PaymentBottomSheet(
                            donorId: widget.donorId,
                            onSubmit: () => setState(() {}),
                          );
                        },
                      );
                    },
                    child: Text(
                      'Record Payment',
                      style:
                          TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
                    ),
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class PaymentBottomSheet extends StatefulWidget {
  final String donorId;
  final VoidCallback onSubmit;

  const PaymentBottomSheet({required this.donorId, required this.onSubmit});

  @override
  _PaymentBottomSheetState createState() => _PaymentBottomSheetState();
}

class _PaymentBottomSheetState extends State<PaymentBottomSheet> {
  late TextEditingController amount;
  String? _selectedPayment;
  String? _selectedMonth;
  String? _selectedYear;
  late List<String> _years;
  List<String> paymentMethods = ["Cash", "Account"];
  final List<String> _months = [
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

  @override
  void initState() {
    super.initState();
    amount = TextEditingController();
    final currentYear = DateTime.now().year;
    _years = List.generate(5, (index) => (currentYear - index).toString());
    _selectedYear = currentYear.toString(); // Default to current year
    _selectedMonth =
        _months[DateTime.now().month - 1]; // Default to current month
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
            height: 30,
            width: 70,
            margin: const EdgeInsets.only(right: 4, bottom: 4),
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                foregroundColor: Colors.white,
                backgroundColor: const Color(0xffF44336),
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
              child: const Text(
                'OK',
                style: TextStyle(
                  fontFamily: "Inter",
                  fontWeight: FontWeight.bold,
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

  Future<void> _recordPayment() async {
    // Check for missing fields
    List<String> missingFields = [];
    if (_selectedYear == null) missingFields.add('Year');
    if (_selectedMonth == null) missingFields.add('Month');
    if (amount.text.isEmpty) missingFields.add('Amount');
    if (_selectedPayment == null) missingFields.add('Payment Method');

    if (missingFields.isNotEmpty) {
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          content: Text(
            'Please fill the following fields: ${missingFields.join(', ')}',
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
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(4),
                  ),
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
      return;
    }

    double? parsedAmount = double.tryParse(amount.text);
    if (parsedAmount == null || parsedAmount <= 0) {
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          content: const Text(
            'Please enter a valid positive amount',
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
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(4),
                  ),
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
      return;
    }

    try {
      final monthYearKey = '$_selectedMonth-$_selectedYear';
      final statusRef = FirebaseFirestore.instance
          .collection('donors')
          .doc(widget.donorId)
          .collection('paymentStatus')
          .doc(monthYearKey);

      // Check if payment already exists
      final existingPayment = await statusRef.get();
      if (existingPayment.exists) {
        _showAlreadyAddedDialog(_selectedMonth!, _selectedYear!);
        return;
      }

      // Record new payment
      await statusRef.set({
        'amount': parsedAmount,
        'month': _selectedMonth,
        'paymentMethod': _selectedPayment,
        'year': _selectedYear,
        'status': 'paid',
        'timestamp': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));

      widget.onSubmit();
      Navigator.pop(context);
    } catch (e) {
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          content: Text(
            'Error: $e',
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
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(4),
                  ),
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
  }

  // Show logout confirmation dialog
  Future<void> showLogoutConfirmation(BuildContext context) async {
    return showDialog<void>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Confirm Logout'),
          content: const Text('Are you sure you want to logout?'),
          actions: <Widget>[
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () async {
                await FirebaseAuth.instance.signOut();
                if (!mounted) return;
                Navigator.of(context).pushNamedAndRemoveUntil(
                  '/login',
                  (Route<dynamic> route) => false,
                );
              },
              child: const Text('Logout'),
            ),
          ],
        );
      },
    );
  }

  // Custom page transition
  Route _createRoute(Widget page) {
    return PageRouteBuilder(
      pageBuilder: (context, animation, secondaryAnimation) => page,
      transitionsBuilder: (context, animation, secondaryAnimation, child) {
        const begin = Offset(1.0, 0.0);
        const end = Offset.zero;
        const curve = Curves.easeInOut;

        var tween =
            Tween(begin: begin, end: end).chain(CurveTween(curve: curve));
        var offsetAnimation = animation.drive(tween);

        return SlideTransition(
          position: offsetAnimation,
          child: child,
        );
      },
    );
  }

  // Navigate to edit donor page
  void _navigateToEditDonor() async {
    final donorData = await fetchDonorData(widget.donorId);

    Navigator.of(context).push(
      _createRoute(
        DonorAdd(
          donorId: widget.donorId,
          initialName: donorData['name'],
          initialNumber: donorData['number'],
          initialAddress: donorData['address'],
          initialAmount: (donorData['amount'] ?? '').toString(),
          initialImageUrl: donorData['imageUrl'],
        ),
      ),
    );
  }

  @override
  void dispose() {
    amount.dispose();
    super.dispose();
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    bool readOnly = false,
    TextInputType keyboardType = TextInputType.text,
    String? hintText,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: Colors.black87,
          ),
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: controller,
          readOnly: readOnly,
          keyboardType: keyboardType,
          decoration: InputDecoration(
            hintText: hintText,
            hintStyle: const TextStyle(fontSize: 14, color: Color(0xffA7A4AD)),
            contentPadding:
                const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
            enabledBorder: OutlineInputBorder(
              borderSide:
                  const BorderSide(color: Color(0xFF1BA3A1), width: 1.0),
              borderRadius: BorderRadius.circular(8),
            ),
            focusedBorder: OutlineInputBorder(
              borderSide:
                  const BorderSide(color: Color(0xFF1BA3A1), width: 2.0),
              borderRadius: BorderRadius.circular(8),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildDropdown<T>({
    required String label,
    required T? value,
    required List<DropdownMenuItem<T>> items,
    required ValueChanged<T?> onChanged,
    String? hintText,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: Colors.black87,
          ),
        ),
        const SizedBox(height: 8),
        DropdownButtonFormField<T>(
          value: value,
          items: items,
          onChanged: onChanged,
          decoration: InputDecoration(
            hintText: hintText,
            hintStyle: const TextStyle(fontSize: 14, color: Color(0xffA7A4AD)),
            contentPadding:
                const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
            enabledBorder: OutlineInputBorder(
              borderSide:
                  const BorderSide(color: Color(0xFF1BA3A1), width: 1.0),
              borderRadius: BorderRadius.circular(8),
            ),
            focusedBorder: OutlineInputBorder(
              borderSide:
                  const BorderSide(color: Color(0xFF1BA3A1), width: 2.0),
              borderRadius: BorderRadius.circular(8),
            ),
          ),
          style: const TextStyle(fontSize: 14, color: Colors.black87),
          dropdownColor: Colors.white,
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      child: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            return SingleChildScrollView(
              child: Padding(
                padding: EdgeInsets.symmetric(
                  horizontal: constraints.maxWidth > 600 ? 32 : 16,
                  vertical: 16,
                ),
                child: FutureBuilder<Map<String, dynamic>>(
                  future: fetchDonorData(widget.donorId),
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const Center(child: CircularProgressIndicator());
                    }
                    if (snapshot.hasError) {
                      return const Center(
                          child: Text('Error loading donor data'));
                    }

                    if (snapshot.hasData) {
                      amount.text = snapshot.data!['amount'].toString();
                    }

                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Center(
                          child: Container(
                            width: 40,
                            height: 4,
                            margin: const EdgeInsets.only(bottom: 8),
                            decoration: BoxDecoration(
                              color: Colors.grey.shade300,
                              borderRadius: BorderRadius.circular(2),
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),
                        _buildDropdown<String>(
                          label: 'Select Year',
                          value: _selectedYear,
                          items: _years
                              .map((year) => DropdownMenuItem<String>(
                                    value: year,
                                    child: Text(year),
                                  ))
                              .toList(),
                          onChanged: (newValue) {
                            setState(() {
                              _selectedYear = newValue;
                            });
                          },
                          hintText: DateTime.now().year.toString(),
                        ),
                        const SizedBox(height: 16),
                        _buildDropdown<String>(
                          label: 'Select Month',
                          value: _selectedMonth,
                          items: _months
                              .map((month) => DropdownMenuItem<String>(
                                    value: month,
                                    child: Text(month),
                                  ))
                              .toList(),
                          onChanged: (newValue) {
                            setState(() {
                              _selectedMonth = newValue;
                            });
                          },
                          hintText: _months[DateTime.now().month - 1],
                        ),
                        const SizedBox(height: 16),
                        Row(
                          children: [
                            Expanded(
                              child: _buildTextField(
                                controller: amount,
                                label: 'Amount',
                                keyboardType: TextInputType.number,
                                hintText: '250',
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: _buildDropdown<String>(
                                label: 'Payment Method',
                                value: _selectedPayment,
                                items: paymentMethods
                                    .map((method) => DropdownMenuItem<String>(
                                          value: method,
                                          child: Text(method),
                                        ))
                                    .toList(),
                                onChanged: (newValue) {
                                  setState(() {
                                    _selectedPayment = newValue;
                                  });
                                },
                                hintText: 'Select Method',
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 24),
                        ElevatedButton(
                          onPressed: _recordPayment,
                          style: ElevatedButton.styleFrom(
                            foregroundColor: Colors.white,
                            backgroundColor: const Color(0xff1BA3A1),
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8)),
                            elevation: 0,
                            textStyle: const TextStyle(
                                fontSize: 16, fontWeight: FontWeight.w600),
                          ),
                          child: const Text('Submit'),
                        ),
                      ],
                    );
                  },
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}

class PaymentHistoryList extends StatelessWidget {
  final String donorId;
  final String? selectedYear;

  PaymentHistoryList({required this.donorId, this.selectedYear});

  // Map months to numbers for sorting
  static const Map<String, int> _monthOrder = {
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
  };

  @override
  Widget build(BuildContext context) {
    final currentYear = DateTime.now().year.toString();
    final currentMonth = DateTime.now().month;
    final year = selectedYear ?? currentYear;

    // Define months to display (January to current month if current year)
    final monthsToShow = [
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
    ].sublist(0, year == currentYear ? currentMonth : 12);

    // Query paymentStatus for the selected year
    Query<Map<String, dynamic>> query = FirebaseFirestore.instance
        .collection('donors')
        .doc(donorId)
        .collection('paymentStatus')
        .where('year', isEqualTo: year);

    return StreamBuilder<QuerySnapshot>(
      stream: query.snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Center(child: CircularProgressIndicator());
        }
        if (snapshot.hasError) {
          print('Firestore Error: ${snapshot.error}');
          return Center(child: Text('Error: ${snapshot.error}'));
        }

        // Map payments to months
        final payments = snapshot.data?.docs ?? [];
        final paymentMap = <String, Map<String, dynamic>>{};
        for (var doc in payments) {
          final data = doc.data() as Map<String, dynamic>;
          final month = data['month'] as String?;
          if (month != null && monthsToShow.contains(month)) {
            paymentMap[month] = {
              'month': month,
              'year': data['year'] ?? year,
              'status': data['status'] ?? 'unpaid',
              'amount': (data['amount'] as num?)?.toDouble(),
              'paymentMethod': data['paymentMethod'],
            };
          }
        }

        // Create list of all months to display
        final paymentList = monthsToShow.map((month) {
          return paymentMap[month] ??
              {
                'month': month,
                'year': year,
                'status': 'unpaid',
                'amount': null,
                'paymentMethod': null,
              };
        }).toList();

        // Sort by month order
        paymentList.sort((a, b) =>
            _monthOrder[a['month']]!.compareTo(_monthOrder[b['month']]!));

        if (paymentList.isEmpty) {
          return Center(child: Text('No payment history for $year'));
        }

        return ListView.builder(
          itemCount: paymentList.length,
          itemBuilder: (context, index) {
            final payment = paymentList[index];
            final month = payment['month'] ?? 'Unknown';
            final status = payment['status'] ?? 'unpaid';
            final amount = payment['amount'] as double?;
            final paymentMethod = payment['paymentMethod'] as String?;
            final year = payment['year'] ?? 'Unknown';

            return Padding(
              padding:
                  const EdgeInsets.symmetric(horizontal: 8.0, vertical: 4.0),
              child: ListTile(
                title: Text(
                  month,
                  style: TextStyle(
                    fontFamily: "Inter",
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: Color(0xff1BA3A1),
                  ),
                ),
                subtitle:
                    status == 'paid' && amount != null && paymentMethod != null
                        ? Text(
                            'Year: $year • Method: $paymentMethod • ₹${amount.toStringAsFixed(0)}',
                            style: TextStyle(
                              fontFamily: "Inter",
                              fontSize: 10,
                              fontWeight: FontWeight.w400,
                              color: Colors.grey.shade600,
                            ),
                          )
                        : null,
                trailing: Text(
                  status == 'paid' ? 'Paid' : 'Unpaid',
                  style: TextStyle(
                    fontFamily: "Inter",
                    fontSize: 14,
                    fontWeight: FontWeight.w400,
                    color: status == 'paid' ? Colors.green : Colors.red,
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }
}

class FullScreenImageViewer extends StatelessWidget {
  final String imageUrl;

  const FullScreenImageViewer({Key? key, required this.imageUrl})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Center(
        child: PhotoView(
          imageProvider: NetworkImage(imageUrl),
          backgroundDecoration: BoxDecoration(color: Colors.black),
          minScale: PhotoViewComputedScale.contained,
          maxScale: PhotoViewComputedScale.covered * 2,
          loadingBuilder: (context, event) => Center(
            child: CircularProgressIndicator(),
          ),
          errorBuilder: (context, error, stackTrace) => Center(
            child: Text(
              'Failed to load image',
              style: TextStyle(color: Colors.white),
            ),
          ),
        ),
      ),
    );
  }
}

class DonorDetailsShimmer extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Shimmer.fromColors(
      baseColor: Colors.grey[300]!,
      highlightColor: Colors.grey[100]!,
      child: Column(
        children: [
          SizedBox(height: 16),
          // Top bar shimmer
          ListTile(
            leading: Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
              ),
            ),
            title: Center(
              child: Container(
                width: 80,
                height: 18,
                color: Colors.white,
              ),
            ),
            trailing: Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
              ),
            ),
          ),
          SizedBox(height: 8),
          // Avatar and details shimmer
          Container(
            height: 160,
            width: MediaQuery.of(context).size.width,
            child: Stack(
              children: [
                Positioned(
                  left: 20,
                  top: 20,
                  child: Container(
                    width: 100,
                    height: 100,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                    ),
                  ),
                ),
                Positioned(
                  top: 17,
                  right: 20,
                  child: Container(
                    width: 212,
                    height: 30,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Container(
                          width: 100,
                          height: 18,
                          color: Colors.white,
                        ),
                        Container(
                          width: 60,
                          height: 18,
                          color: Colors.white,
                        ),
                      ],
                    ),
                  ),
                ),
                Positioned(
                  right: 22,
                  top: 42,
                  child: Container(
                    width: 212,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          width: 120,
                          height: 14,
                          color: Colors.white,
                        ),
                        SizedBox(height: 8),
                        Container(
                          width: 180,
                          height: 14,
                          color: Colors.white,
                        ),
                      ],
                    ),
                  ),
                ),
                Positioned(
                  right: 22,
                  bottom: 0,
                  child: Row(
                    children: [
                      Container(
                        height: 26,
                        width: 102,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(4),
                        ),
                      ),
                      SizedBox(width: 3),
                      Container(
                        height: 26,
                        width: 102,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(4),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          SizedBox(height: 24),
          // Add more shimmer sections as needed for the rest of the page
        ],
      ),
    );
  }
}
