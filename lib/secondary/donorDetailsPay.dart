import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../assets/custom widgets/deletepopup.dart';
import '../assets/custom widgets/logoutpopup.dart';

class donorDetailsPay extends StatefulWidget {
  const donorDetailsPay({super.key});

  @override
  State<donorDetailsPay> createState() => _homePageState();
}

class _homePageState extends State<donorDetailsPay> {
  String? _selectedYear;
  final List<String> _years =
      List.generate(5, (index) => (2020 + index).toString());

  @override
  Widget build(BuildContext context) {
    return Scaffold(
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
                  Padding(
                    padding: const EdgeInsets.only(bottom: 7.0, top: 6),
                    child: SizedBox(
                      height: 26,
                      width: 73,
                      child: ElevatedButton(
                        onPressed: () => showLogoutConfirmation(context),
                        style: ElevatedButton.styleFrom(
                            foregroundColor: Colors.black,
                            backgroundColor: Colors.white,
                            elevation: 0),
                        child: Text(
                          'Logout',
                          style: TextStyle(
                              fontSize: 11,
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
      body: Column(
        children: [
          ListTile(
            leading: SvgPicture.asset(
              'lib/assets/images/Back.svg',
              height: 40,
              width: 40,
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
            height: 130,
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
                    height: 20,
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
                    height: 56,
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
                      border: Border.all(color: Color(0xFF817D8A), width: 1.0),
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
          ),
          SizedBox(
            width: double.infinity,
            height: 50,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                foregroundColor: Colors.white,
                backgroundColor: Color(0xff1BA3A1),
                elevation: 0.0,
              ),
              onPressed: () {},
              child: Text(
                'Record Payment',
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                  fontSize: 14,
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
