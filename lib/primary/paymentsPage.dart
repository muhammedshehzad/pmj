import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../assets/custom widgets/PeopleListViewHome.dart';
import '../assets/custom widgets/logoutpopup.dart';


import 'package:flutter/material.dart';

import '../assets/custom widgets/paymentRecordepopup.dart';

class PaymentProvider extends ChangeNotifier {
  String? _selectedMonth;
  String? _selectedPayment;

  List<String>  get months => [
    'January', 'February', 'March', 'April', 'May', 'June',
    'July', 'August', 'September', 'October', 'November', 'December'
  ];

  TextEditingController nameController = TextEditingController();
  TextEditingController amountController = TextEditingController();

  String? get selectedMonth => _selectedMonth;
  String? get selectedPayment => _selectedPayment;

  void setSelectedMonth(String month) {
    _selectedMonth = month;
    notifyListeners();
  }

  void setSelectedPayment(String paymentMethod) {
    _selectedPayment = paymentMethod;
    notifyListeners();
  }

  void clearFields() {
    nameController.clear();
    amountController.clear();
    _selectedMonth = null;
    _selectedPayment = null;
    notifyListeners();
  }
}

class paymentsPage extends StatefulWidget {
  const paymentsPage({super.key});

  @override
  State<paymentsPage> createState() => _homePageState();
}

class _homePageState extends State<paymentsPage> {


  List<String> payment = ["Cash", "Account"];
  List<personHome> peoplesHome = [
    personHome(
      name: "Faisal K",
      date: "12.08.2024",
      amount: 250,
      photoUrl: "lib/assets/images/faisalk.png",
      method: 'Cash',
    ),
    personHome(
      name: "Ammad Parambath",
      date: "12.08.2024",
      amount: 250,
      photoUrl: "lib/assets/images/ammadp.png",
      method: 'Cash',
    ),
    personHome(
      name: "Pocker Haji Kaloli",
      date: "12.08.2024",
      amount: 250,
      photoUrl: "lib/assets/images/ishakv.png",
      method: 'Cash',
    ),
    personHome(
      name: "Arshad MK",
      date: "12.08.2024",
      amount: 250,
      photoUrl: "lib/assets/images/pkhaji.png",
      method: 'Cash',
    ),
    personHome(
      name: "Ishak Vallil",
      date: "12.08.2024",
      amount: 250,
      photoUrl: "lib/assets/images/arshadmk.png",
      method: 'Account',
    ),
    personHome(
      name: "Shareef Kaloli",
      date: "12.08.2024",
      amount: 250,
      photoUrl: "lib/assets/images/pkhaji.png",
      method: 'Cash',
    ),
    personHome(
      name: "Salam K",
      date: "12.08.2024",
      amount: 250,
      photoUrl: "lib/assets/images/faisalk.png",
      method: 'Cash',
    ),
    personHome(
      name: "Faisal K",
      date: "12.08.2024",
      amount: 250,
      photoUrl: "lib/assets/images/ishakv.png",
      method: 'Account',
    ),
    personHome(
      name: "Faisal K",
      date: "12.08.2024",
      amount: 250,
      photoUrl: "lib/assets/images/faisalk.png",
      method: 'Cash',
    ),
    personHome(
      name: "Ammad Parambath",
      date: "12.08.2024",
      amount: 250,
      photoUrl: "lib/assets/images/ammadp.png",
      method: 'Cash',
    ),
    personHome(
      name: "Pocker Haji Kaloli",
      date: "12.08.2024",
      amount: 250,
      photoUrl: "lib/assets/images/ishakv.png",
      method: 'Cash',
    ),
    personHome(
      name: "Arshad MK",
      date: "12.08.2024",
      amount: 250,
      photoUrl: "lib/assets/images/pkhaji.png",
      method: 'Cash',
    ),
    personHome(
      name: "Ishak Vallil",
      date: "12.08.2024",
      amount: 250,
      photoUrl: "lib/assets/images/arshadmk.png",
      method: 'Account',
    ),
  ];


  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<PaymentProvider>(context);
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
      body: SingleChildScrollView(
        child: Padding(
          padding:  EdgeInsets.all(16.0),
          child: Column(
            children: [
              Center(
                  child: Text(
                'Record Payment',
                style: TextStyle(fontWeight: FontWeight.w600, fontSize: 16),
              )),
              SizedBox(
                height: 5,
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Search Donor name',
                    style: TextStyle(
                        fontSize: 10,
                        color: Colors.black,
                        fontWeight: FontWeight.bold),
                  ),
                  SizedBox(
                    height: 4,
                  ),
                  TextFormField(
                    controller: provider.nameController,
                    obscureText: false,
                    keyboardType: TextInputType.name,
                    decoration: InputDecoration(
                      hintText: 'Faisal Tk',
                      hintStyle:
                          TextStyle(fontSize: 12, color: Color(0xffA7A4AD)),
                      enabledBorder: OutlineInputBorder(
                        borderSide:
                            BorderSide(color: Color(0xFF1BA3A1), width: 1.0),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderSide:
                            BorderSide(color: Color(0xFF1BA3A1), width: 2.0),
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
                        floatingLabelBehavior: FloatingLabelBehavior.never,
                        enabledBorder: OutlineInputBorder(
                          borderSide:
                              BorderSide(color: Color(0xFF1BA3A1), width: 1.0),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderSide:
                              BorderSide(color: Color(0xFF1BA3A1), width: 1.0),
                        ),
                      ),
                      value: provider.selectedMonth,
                      items: provider.months.map((String month) {
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
                        provider.setSelectedMonth(newValue!);
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
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      SizedBox(
                        width: MediaQuery.of(context).size.width * .45,
                        child: TextFormField(
                          controller: provider.amountController,
                          obscureText: false,
                          keyboardType: TextInputType.number,
                          decoration: InputDecoration(
                            hintText: '500',
                            hintStyle: TextStyle(
                                fontSize: 12, color: Color(0xffA7A4AD)),
                            enabledBorder: OutlineInputBorder(
                              borderSide: BorderSide(
                                  color: Color(0xFF1BA3A1), width: 1.0),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderSide: BorderSide(
                                  color: Color(0xFF1BA3A1), width: 2.0),
                            ),
                          ),
                        ),
                      ),
                      Container(
                        decoration: BoxDecoration(
                          color: provider._selectedPayment == null
                              ? Color(0xff29B6F6)
                              : Colors.white,
                          borderRadius: BorderRadius.circular(4),
                          border: Border.all(
                            color: Color(0xff1BA3A1),
                            width: 1.0,
                          ),
                        ),
                        width: MediaQuery.of(context).size.width * .45,
                        height: 60.5,
                        child: Center(
                          child: DropdownButton<String>(
                            elevation: 0,
                            hint: Padding(
                              padding: const EdgeInsets.all(8.0),
                              child: Text(
                                "Payment Method",
                                style: TextStyle(
                                    color: provider._selectedPayment == null
                                        ? Colors.white
                                        : Colors.black,
                                    fontWeight: FontWeight.w600,
                                    fontSize: 12),
                              ),
                            ),
                            icon: Padding(
                              padding: const EdgeInsets.all(8.0),
                              child: Icon(
                                Icons.arrow_drop_down_sharp,
                                color: provider._selectedPayment == null
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
                            value: provider._selectedPayment,
                            items: payment.map((String method) {
                              return DropdownMenuItem<String>(
                                value: method,
                                child: Padding(
                                  padding: const EdgeInsets.all(8.0),
                                  child: Text(
                                    method,
                                    style: TextStyle(fontSize: 12),
                                  ),
                                ),
                              );
                            }).toList(),
                            onChanged: (String? newValue) {
                              setState(() {
                                provider._selectedPayment = newValue;
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
                            borderRadius: BorderRadius.circular(4)
                        ),
                      ),
                      onPressed: () => showRecordConfirmation(context),
                      child: Text(
                        'Submit',
                        style: TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 14,
                        ),
                      ),
                    ),
                  ),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        "Recent Donations",
                        style: TextStyle(
                            fontSize: 16,
                            fontFamily: "Inter",
                            fontWeight: FontWeight.w600,
                            color: Color(0xff1BA3A1)),
                      ),
                      TextButton(
                        onPressed: () {},
                        child: Text(
                          "View More",
                          style: TextStyle(
                              fontSize: 10,
                              fontFamily: "Inter",
                              fontWeight: FontWeight.w400,
                              decoration: TextDecoration.underline,
                              color: Color(0xff0B190C)),
                        ),
                      ),
                    ],
                  ),
                  PeopleListViewHome(peoplesHome: peoplesHome)
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
