import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import '../assets/custom widgets/deletepopup.dart';
import '../assets/custom widgets/logoutpopup.dart';
import '../assets/custom widgets/paymentRecordepopup.dart';

class donorDetails extends StatefulWidget {
  const donorDetails({super.key});

  @override
  State<donorDetails> createState() => _homePageState();
}

class _homePageState extends State<donorDetails> {
  String? _selectedYear;
  final List<String> _years =
      List.generate(5, (index) => (2020 + index).toString());
  TextEditingController name = TextEditingController();
  TextEditingController amount = TextEditingController();

  String? _selectedpayment;
  String? _selectedMonth;
  List<String> payment = ["Cash", "Account"];

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
                    padding: const EdgeInsets.only(bottom: 8.0),
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
                  ),                ],
              ),
            ),
          ),
        ),
      ),
      body: Stack(
        children: [
          Column(
            children: [
              ListTile(
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
                    'Details',
                    style: TextStyle(fontWeight: FontWeight.w600, fontSize: 16),
                  ),
                ),
                trailing: SvgPicture.asset(
                  'lib/assets/images/settingsnew.svg',
                  height: 40,
                  width: 40,
                ),
              ),
              Container(
                height: 135,
                width: MediaQuery.of(context).size.width,
                child: Stack(
                  children: [
                    Positioned(
                      left: 20,
                      top: 20,
                      child: CircleAvatar(
                        child: Image.asset('lib/assets/images/faisalk.png'),
                        radius: 50,
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
                              'Faisal K',
                              style: TextStyle(
                                fontSize: 16,
                                fontFamily: "Inter",
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            Text(
                              '₹250',
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
                      right: 20,
                      top: 36,
                      child: Container(
                        height: 60,
                        width: 212,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              '8080168455',
                              style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                  color: Color(0xff817D8A),
                                  fontFamily: "Inter"),
                            ),
                            Text(
                              'Konhantavida, Perakool \nPonmeri Parambil PO',
                              style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w400,
                                  color: Color(0xff817D8A),
                                  fontFamily: "Inter"),
                            ),
                          ],
                        ),
                      ),
                    ),
                    Positioned(
                      right: 22,
                      bottom: 8,
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
                                      borderRadius: BorderRadius.circular(4)),
                                  elevation: 0),
                              child: Text(
                                'Edit',
                                style: TextStyle(
                                    fontFamily: "Inter",
                                    fontWeight: FontWeight.w400,
                                    fontSize: 11),
                              ),
                              onPressed: () {},
                            ),
                          ),
                          SizedBox(
                            width: 3,
                          ),
                          Container(
                            height: 26,
                            width: 102,
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
                                    fontWeight: FontWeight.w400,
                                    fontSize: 11),
                              ),
                              onPressed: () => showDeleteConfirmation(context),
                            ),
                          ),
                        ],
                      ),
                    )
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.only(top: 15.0, left: 24, right: 24),
                child: Container(
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Payment History',
                        style: TextStyle(
                          fontSize: 14,
                          fontFamily: "Inter",
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      Container(
                        height: 33,
                        width: 88,
                        padding: EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          border:
                              Border.all(color: Color(0xFF817D8A), width: 1.0),
                          borderRadius: BorderRadius.circular(5),
                        ),
                        child: DropdownButton<String>(
                          isExpanded: true,
                          value: _selectedYear,
                          hint: Text(
                            '2024',
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
                              _selectedYear =
                                  newValue; // Update the selected year
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
              ),
              Expanded(
                child: PaymentHistoryList(),
              ),
              SizedBox(
                height: 60,
              )
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
                      return Container(
                        decoration: BoxDecoration(
                          color: Color(0xffFFFFFF),
                          borderRadius: BorderRadius.vertical(
                            top: Radius.circular(16),
                          ),
                        ),
                        height: MediaQuery.of(context).size.height * .5,
                        child: Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: Column(
                            children: <Widget>[
                              Center(
                                child: IconButton(
                                    onPressed: () {
                                      Navigator.pop(context);
                                    },
                                    icon: SvgPicture.asset(
                                        'lib/assets/images/dropdown.svg')),
                              ),
                              SizedBox(
                                height: 5,
                              ),
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Full name',
                                    style: TextStyle(
                                        fontSize: 10,
                                        color: Colors.black,
                                        fontWeight: FontWeight.bold),
                                  ),
                                  SizedBox(
                                    height: 4,
                                  ),
                                  TextFormField(
                                    controller: name,
                                    obscureText: false,
                                    keyboardType: TextInputType.name,
                                    decoration: InputDecoration(
                                      hintText: 'Faisal Tk',
                                      hintStyle: TextStyle(
                                          fontSize: 12,
                                          color: Color(0xffA7A4AD)),
                                      enabledBorder: OutlineInputBorder(
                                        borderSide: BorderSide(
                                            color: Color(0xFF1BA3A1),
                                            width: 1.0),
                                      ),
                                      focusedBorder: OutlineInputBorder(
                                        borderSide: BorderSide(
                                            color: Color(0xFF1BA3A1),
                                            width: 2.0),
                                      ),
                                    ),
                                  ),
                                  SizedBox(
                                    height: 10,
                                  ),
                                  Text(
                                    'Select Month',
                                    style: TextStyle(
                                        fontSize: 10,
                                        color: Colors.black,
                                        fontWeight: FontWeight.bold),
                                  ),
                                  SizedBox(
                                    height: 4,
                                  ),
                                  DropdownButtonFormField<String>(
                                      decoration: InputDecoration(
                                        labelText: "January",
                                        labelStyle: TextStyle(
                                            color: Colors.grey.shade500,
                                            fontWeight: FontWeight.w400,
                                            fontSize: 12),
                                        floatingLabelBehavior:
                                            FloatingLabelBehavior.never,
                                        enabledBorder: OutlineInputBorder(
                                          borderSide: BorderSide(
                                              color: Color(0xFF1BA3A1),
                                              width: 1.0),
                                        ),
                                        focusedBorder: OutlineInputBorder(
                                          borderSide: BorderSide(
                                              color: Color(0xFF1BA3A1),
                                              width: 1.0),
                                        ),
                                      ),
                                      value: _selectedMonth,
                                      items: _months.map((String month) {
                                        return DropdownMenuItem<String>(
                                          value: month,
                                          child: Text(
                                            month,
                                            style: TextStyle(
                                              fontSize: 12,
                                            ),
                                          ),
                                        );
                                      }).toList(),
                                      onChanged: (String? newValue) {
                                        setState(() {
                                          _selectedMonth = newValue;
                                        });
                                      }),
                                  SizedBox(
                                    height: 10,
                                  ),
                                  Text(
                                    'Amount',
                                    style: TextStyle(
                                        fontSize: 10,
                                        color: Colors.black,
                                        fontWeight: FontWeight.bold),
                                  ),
                                  SizedBox(
                                    height: 4,
                                  ),
                                  Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceBetween,
                                    children: [
                                      SizedBox(
                                        width:
                                            MediaQuery.of(context).size.width *
                                                .45,
                                        child: TextFormField(
                                          controller: amount,
                                          obscureText: false,
                                          keyboardType: TextInputType.number,
                                          decoration: InputDecoration(
                                            hintText: '250',
                                            hintStyle: TextStyle(
                                                fontSize: 12,
                                                color: Color(0xffA7A4AD)),
                                            enabledBorder: OutlineInputBorder(
                                              borderSide: BorderSide(
                                                  color: Color(0xFF1BA3A1),
                                                  width: 1.0),
                                            ),
                                            focusedBorder: OutlineInputBorder(
                                              borderSide: BorderSide(
                                                  color: Color(0xFF1BA3A1),
                                                  width: 2.0),
                                            ),
                                          ),
                                        ),
                                      ),
                                      Container(
                                        decoration: BoxDecoration(
                                          color: _selectedpayment == null
                                              ? Color(0xff29B6F6)
                                              : Colors.white,
                                          borderRadius:
                                              BorderRadius.circular(4),
                                          border: Border.all(
                                            color: Color(0xff1BA3A1),
                                            width: 1.0,
                                          ),
                                        ),
                                        width:
                                            MediaQuery.of(context).size.width *
                                                .45,
                                        height: 63,
                                        child: Center(
                                          child: DropdownButton<String>(
                                            elevation: 0,
                                            hint: Padding(
                                              padding:
                                                  const EdgeInsets.all(8.0),
                                              child: Text(
                                                "Payment Method",
                                                style: TextStyle(
                                                    color:
                                                        _selectedpayment == null
                                                            ? Colors.white
                                                            : Colors.black,
                                                    fontWeight: FontWeight.w600,
                                                    fontSize: 12),
                                              ),
                                            ),
                                            icon: Padding(
                                              padding:
                                                  const EdgeInsets.all(8.0),
                                              child: Icon(
                                                Icons.arrow_drop_down_sharp,
                                                color: _selectedpayment == null
                                                    ? Color(0xffFFFFFF)
                                                    : Colors.grey.shade700,
                                              ),
                                            ),
                                            dropdownColor: Colors.white,
                                            underline: Container(
                                              height: 0,
                                              color: Color(0xff1BA3A1),
                                            ),
                                            isExpanded: true,
                                            value: _selectedpayment,
                                            items: payment.map((String method) {
                                              return DropdownMenuItem<String>(
                                                value: method,
                                                child: Padding(
                                                  padding:
                                                      const EdgeInsets.all(8.0),
                                                  child: Text(
                                                    method,
                                                    style:
                                                        TextStyle(fontSize: 12),
                                                  ),
                                                ),
                                              );
                                            }).toList(),
                                            onChanged: (String? newValue) {
                                              setState(() {
                                                _selectedpayment = newValue;
                                              });
                                            },
                                          ),
                                        ),
                                      )
                                    ],
                                  ),
                                  SizedBox(
                                    height: 10,
                                  ),
                                  SizedBox(
                                    width: MediaQuery.sizeOf(context).width,
                                    height: 50,
                                    child: ElevatedButton(
                                      style: ElevatedButton.styleFrom(
                                        foregroundColor: Colors.white,
                                        backgroundColor: Color(0xff1BA3A1),
                                        elevation: 0.0,
                                        shape: RoundedRectangleBorder(
                                            borderRadius:
                                                BorderRadius.circular(4)),
                                      ),
                                      onPressed: () =>
                                          showRecordConfirmation(context),
                                      child: Text(
                                        'Submit',
                                        style: TextStyle(
                                          fontWeight: FontWeight.w600,
                                          fontSize: 14,
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  );
                },
                child: Text(
                  'Record Payment',
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class PaymentStatus {
  final String month;
  final bool isPaid;

  PaymentStatus({required this.month, required this.isPaid});
}

List<PaymentStatus> paymentHistory = [
  PaymentStatus(month: "January", isPaid: true),
  PaymentStatus(month: "February", isPaid: true),
  PaymentStatus(month: "March", isPaid: true),
  PaymentStatus(month: "April", isPaid: true),
  PaymentStatus(month: "May", isPaid: true),
  PaymentStatus(month: "June", isPaid: true),
  PaymentStatus(month: "July", isPaid: true),
  PaymentStatus(month: "August", isPaid: true),
  PaymentStatus(month: "September", isPaid: true),
  PaymentStatus(month: "October", isPaid: false),
  PaymentStatus(month: "November", isPaid: false),
  PaymentStatus(month: "December", isPaid: false),
];

class PaymentHistoryList extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      itemCount: paymentHistory.length,
      itemBuilder: (context, index) {
        final payment = paymentHistory[index];
        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 4.0),
          child: Container(
            decoration: BoxDecoration(
              border: Border(bottom: BorderSide(color: Colors.white, width: 0)),
            ),
            child: ListTile(
              title: Text(
                payment.month,
                style: TextStyle(
                  fontFamily: "Inter",
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: Color(0xff1BA3A1),
                ),
              ),
              trailing: Text(
                payment.isPaid ? 'Paid' : 'Pending',
                style: TextStyle(
                  fontFamily: "Inter",
                  fontSize: 14,
                  fontWeight: FontWeight.w400,
                  color: payment.isPaid ? Colors.green : Colors.red,
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}
