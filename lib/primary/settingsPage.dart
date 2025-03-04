import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../assets/custom widgets/logoutpopup.dart';

class settingsPage extends StatefulWidget {
  settingsPage({super.key});

  @override
  State<settingsPage> createState() => _homePageState();
}

class _homePageState extends State<settingsPage> {
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
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                children: [
                  Center(
                      child: Text(
                    'Reports',
                    style: TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 16,
                        fontFamily: "Inter"),
                  )),
                  SizedBox(
                    width: double.infinity * .45,
                  ),
                  ReportsSection(),
                  SizedBox(
                    height: 8,
                  ),
                  Container(
                    margin: EdgeInsets.only(left: 2),
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
                            SizedBox(
                              width: 12,
                            ),
                            Text(
                              "Notifications",
                              style: TextStyle(
                                  fontWeight: FontWeight.w400,
                                  fontSize: 14,
                                  fontFamily: "Inter"),
                            ),
                          ],
                        ),
                        Padding(
                          padding: const EdgeInsets.only(left: 8.0),
                          child: IconButton(
                              onPressed: () {},
                              icon: Icon(
                                Icons.arrow_forward_ios,
                                size: 16,
                              )),
                        ),
                      ],
                    ),
                  ),
                  SizedBox(
                    height: 8,
                  ),
                  GestureDetector(
                    onTap: (){
                      Navigator.pushNamed(context, '/GPay');
                    },
                    child: Container(
                      margin: EdgeInsets.only(left: 2),
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
                              SizedBox(
                                width: 12,
                              ),
                              Text(
                                "Google Pay Scanner",
                                style: TextStyle(
                                    fontWeight: FontWeight.w400,
                                    fontSize: 14,
                                    fontFamily: "Inter"),
                              ),
                            ],
                          ),
                          IconButton(
                              onPressed: () {},
                              icon: Icon(
                                Icons.arrow_forward_ios,
                                size: 16,
                              )),
                        ],
                      ),
                    ),
                  ),
                  SizedBox(
                    height: 250,
                  ),
                  Center(
                      child: Text(
                    'App version 2.01',
                    style: TextStyle(
                        fontWeight: FontWeight.w400,
                        fontSize: 10,
                        fontFamily: "Inter"),
                  )),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class ReportsSection extends StatelessWidget {
  ReportsSection({Key? key}) : super(key: key);

  // Dummy dropdown items
  List<String> years = [
    "2020",
    "2021",
    "2022",
    "2023",
    "2024",
  ];
  List<String> months = [
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
    "December"
  ];
  List<String> filterOptions = [
    "Payment received only",
    "Payments to be received",
    "All payments"
  ];

  // Selected values
  String selectedYear = "2021";
  String selectedMonth = "January";
  String selectedFilter = "Payment received only";

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              // Year Dropdown
              Expanded(
                child: Container(
                  decoration: BoxDecoration(
                    color: Color(0xffF2F2F3),
                    borderRadius: BorderRadius.all(
                      Radius.circular(4), // Curves the top edges
                    ),
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
                          style: TextStyle(
                              fontFamily: "Inter",
                              fontWeight: FontWeight.w400,
                              fontSize: 12),
                        ),
                      );
                    }).toList(),
                    onChanged: (String? newValue) {
                      // Update selected year
                      selectedYear = newValue!;
                    },
                    decoration: InputDecoration(
                      contentPadding: EdgeInsets.symmetric(horizontal: 12),
                      border: InputBorder.none, // Removes the underline
                    ),
                  ),
                ),
              ),
              SizedBox(width: 16),
              // Month Dropdown
              Expanded(
                child: Container(
                  decoration: BoxDecoration(
                    color: Color(0xffF2F2F3),
                    borderRadius: BorderRadius.all(
                      Radius.circular(4), // Curves the top edges
                    ),
                  ),
                  child: DropdownButtonFormField<String>(
                    value: selectedMonth,
                    items: months.map((String month) {
                      return DropdownMenuItem<String>(
                        value: month,
                        child: Text(
                          month,
                          style: TextStyle(
                              fontFamily: "Inter",
                              fontWeight: FontWeight.w400,
                              fontSize: 12),
                        ),
                      );
                    }).toList(),
                    onChanged: (String? newValue) {
                      // Update selected month
                      selectedMonth = newValue!;
                    },
                    decoration: InputDecoration(
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
          SizedBox(height: 16),
          // Payment filter Dropdown
          Container(
            decoration: BoxDecoration(
              color: Color(0xffF2F2F3),
              borderRadius: BorderRadius.all(
                Radius.circular(4), // Curves the top edges
              ),
            ),
            child: DropdownButtonFormField<String>(
              value: selectedFilter,
              items: filterOptions.map((String filter) {
                return DropdownMenuItem<String>(
                  value: filter,
                  child: Text(
                    filter,
                    style: TextStyle(
                        fontFamily: "Inter",
                        fontWeight: FontWeight.w400,
                        fontSize: 12),
                  ),
                );
              }).toList(),
              onChanged: (String? newValue) {
                // Update selected filter
                selectedFilter = newValue!;
              },
              decoration: InputDecoration(
                border: InputBorder.none,
                contentPadding: EdgeInsets.symmetric(horizontal: 12),
              ),
              isExpanded: true,
              dropdownColor: Colors.white,
              elevation: 1,
            ),
          ),
          SizedBox(height: 16),
          // Download button
          SizedBox(
            height: 50,
            child: ElevatedButton(
              onPressed: () {
                // Add your download functionality here
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Color(0xFF00A699), // Teal button color
                padding: EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(4)),
              ),
              child: Text(
                'Download',
                style: TextStyle(
                    fontSize: 12,
                    color: Colors.white,
                    fontFamily: "Inter",
                    fontWeight: FontWeight.w600),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
