import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:pmj_application/assets/custom%20widgets/transition.dart';
import '../assets/custom widgets/deletepopup.dart';
import '../assets/custom widgets/logoutpopup.dart';
import 'editDonor.dart';
import 'package:flutter/material.dart';
import 'package:photo_view/photo_view.dart';

class donorDetails extends StatefulWidget {
  final String donorId;

  const donorDetails({super.key, required this.donorId});

  @override
  State<donorDetails> createState() => _donorDetailsState();
}

class _donorDetailsState extends State<donorDetails> {
  String? _selectedYear;
  late List<String> _years;

  @override
  void initState() {
    super.initState();
    final currentYear = DateTime.now().year;
    _years = List.generate(5, (index) => (currentYear - index).toString());
    _selectedYear = currentYear.toString(); // Default to current year
  }

  Future<Map<String, dynamic>?> _fetchDonorData() async {
    try {
      DocumentSnapshot doc = await FirebaseFirestore.instance
          .collection('donors')
          .doc(widget.donorId)
          .get();
      return doc.data() as Map<String, dynamic>?;
    } catch (e) {
      print('Error fetching donor data: $e');
      return null;
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
              height: 26,
              width: 72,
              margin: EdgeInsets.only(right: 4, bottom: 4),
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                    foregroundColor: Colors.white,
                    backgroundColor: Color(0xff29B6F6),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(4)),
                    elevation: 0),
                child: Text(
                  'Cancel',
                  style: TextStyle(
                      fontFamily: "Inter",
                      fontWeight: FontWeight.w600,
                      fontSize: 7),
                ),
                onPressed: () {
                  Navigator.of(context).pop();
                },
              ),
            ),
            Container(
              height: 26,
              width: 72,
              margin: EdgeInsets.only(right: 0, bottom: 4),
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                    foregroundColor: Colors.white,
                    backgroundColor: Color(0xffF44336),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(4)),
                    elevation: 0),
                child: Text(
                  'Delete',
                  style: TextStyle(
                      fontFamily: "Inter",
                      fontWeight: FontWeight.w600,
                      fontSize: 7),
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
                  Container(
                    height: 26,
                    width: 84,
                    child: ElevatedButton(
                      onPressed: () => showLogoutConfirmation(context),
                      style: ElevatedButton.styleFrom(
                          foregroundColor: Colors.black,
                          backgroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(2)),
                          elevation: 0),
                      child: Center(
                        child: Text(
                          'Logout',
                          style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w600,
                              fontFamily: "Inter"),
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
      body: FutureBuilder<Map<String, dynamic>?>(
        future: _fetchDonorData(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator());
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
                    trailing: SvgPicture.asset(
                        'lib/assets/images/settingsnew.svg',
                        height: 40,
                        width: 40),
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
                            child: CircleAvatar(
                              radius: 50,
                              backgroundImage: donorImageUrl.isNotEmpty
                                  ? NetworkImage(donorImageUrl)
                                  : null,
                              backgroundColor: donorImageUrl.isNotEmpty
                                  ? null
                                  : Color(0xff1BA3A1),
                              child: donorImageUrl.isEmpty
                                  ? Text(
                                      donorName.isNotEmpty
                                          ? donorName[0].toUpperCase()
                                          : '',
                                      style: const TextStyle(
                                        fontSize: 32,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.white,
                                      ),
                                    )
                                  : null,
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
                            // height: 80,
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
                                    Navigator.push(
                                      context,
                                      SlidingPageTransitionRL(
                                        page:
                                            EditDonor(donorId: widget.donorId),
                                      ),
                                    );
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
                        )
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

  Future<Map<String, dynamic>> _fetchDonorData() async {
    try {
      DocumentSnapshot doc = await FirebaseFirestore.instance
          .collection('donors')
          .doc(widget.donorId)
          .get();
      if (doc.exists) {
        return {
          'amount': (doc['amount'] as num?)?.toDouble() ?? 0.0,
        };
      }
      return {'amount': 0.0};
    } catch (e) {
      print('Error fetching donor data: $e');
      return {'amount': 0.0};
    }
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
                  future: _fetchDonorData(),
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
