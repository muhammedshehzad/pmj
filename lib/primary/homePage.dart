import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:pmj_application/primary/paymentsPage.dart';
import 'package:pmj_application/primary/settingsPage.dart';
import 'package:provider/provider.dart';
import '../assets/custom widgets/PeopleListViewHome.dart';
import '../assets/custom widgets/logoutpopup.dart';
import 'donorPage.dart';

class NavBarProvider with ChangeNotifier {
  int _selectedIndex = 0;

  int get selectedIndex => _selectedIndex;

  void changeIndex(int index) {
    _selectedIndex = index;
    notifyListeners();
  }
}

class PeopleProvider with ChangeNotifier {
  List<personHome> _peoplesHome = [
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
      amount: 1000,
      photoUrl: "lib/assets/images/ishakv.png",
      method: 'Cash',
    ),
    personHome(
      name: "Arshad MK",
      date: "12.08.2024",
      amount: 500,
      photoUrl: "lib/assets/images/pkhaji.png",
      method: 'Cash',
    ),
    personHome(
      name: "Ishak Vallil",
      date: "12.08.2024",
      amount: 500,
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

  List<personHome> get peoplesHome => _peoplesHome;
}

class homePage extends StatelessWidget {
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
      body: Padding(
        padding: const EdgeInsets.only(top: 16.0,left: 16,right: 16),
        child: Column(
          children: [
            Container(
              height: 115,
              decoration: BoxDecoration(
                  border: Border.all(width: 1, color: Color(0xff1BA3A1)),
                  borderRadius: BorderRadius.circular(4)),
              width: MediaQuery.of(context).size.width,
              child: Column(
                children: [
                  SizedBox(
                    height: 15,
                  ),
                  Text(
                    "January",
                    style: TextStyle(
                        fontSize: 12,
                        fontFamily: "Inter",
                        fontWeight: FontWeight.w600),
                  ),
                  SizedBox(
                    height: 10,
                  ),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      Column(
                        children: [
                          Text(
                            "Total",
                            style: TextStyle(
                              fontSize: 10,
                              fontFamily: "Inter",
                              fontWeight: FontWeight.w400,
                            ),
                          ),
                          Text(
                            "₹12,500",
                            style: TextStyle(
                              fontSize: 19,
                              fontFamily: "Inter",
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                      Container(
                        width: .9,
                        color: Color(0xff101011),
                        height: 50,
                      ),
                      Column(
                        children: [
                          Text(
                            "Collected",
                            style: TextStyle(
                              fontSize: 10,
                              fontFamily: "Inter",
                              fontWeight: FontWeight.w400,
                              color: Color(0xff66BB6A),
                            ),
                          ),
                          Text(
                            "₹12,500",
                            style: TextStyle(
                              fontSize: 19,
                              fontFamily: "Inter",
                              fontWeight: FontWeight.w600,
                              color: Color(0xff66BB6A),
                            ),
                          ),
                        ],
                      ),
                      Container(
                        width: .9,
                        color: Color(0xff101011),
                        height: 50,
                      ),
                      Column(
                        children: [
                          Text(
                            "Balance",
                            style: TextStyle(
                              fontSize: 10,
                              fontFamily: "Inter",
                              fontWeight: FontWeight.w400,
                              color: Color(0xffF44336),
                            ),
                          ),
                          Text(
                            "₹12,500",
                            style: TextStyle(
                              fontSize: 19,
                              fontFamily: "Inter",
                              fontWeight: FontWeight.w600,
                              color: Color(0xffF44336),
                            ),
                          ),
                        ],
                      ),
                    ],
                  )
                ],
              ),
            ),
            SizedBox(
              height: 14,
            ),
            GestureDetector(
              onTap: () {
                Provider.of<NavBarProvider>(context, listen: false).changeIndex(2);
              },
              child: Container(
                height: 102,
                width: MediaQuery.of(context).size.width,
                decoration: BoxDecoration(
                    color: Color(0xff1BA3A1),
                    border: Border.all(
                      width: 1,
                      color: Color(0xff1BA3A1),
                    ),
                    borderRadius: BorderRadius.circular(4)),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Padding(
                      padding: const EdgeInsets.all(4.0),
                      child: SvgPicture.asset(
                        'lib/assets/images/BTN1.svg',
                        height: 40,
                        width: 40,
                      ),
                    ),
                    Text(
                      "Record Payment",
                      style: TextStyle(
                          fontSize: 10,
                          fontFamily: "Inter",
                          fontWeight: FontWeight.w600,
                          color: Color(0xffF2F2F3)),
                    ),
                  ],
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
                  onPressed: () {

                  },
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
            Expanded(
              child: Consumer<PeopleProvider>(
                builder: (context, peopleProvider, child) {
                  return PeopleListViewHome(
                    peoplesHome: peopleProvider.peoplesHome,
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class BottomNavBarExample extends StatelessWidget {
  final List<Widget> _pages = [
    homePage(),
    donorPage(),
    paymentsPage(),
    settingsPage(),
  ];

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (context) => NavBarProvider(),
      child: Consumer<NavBarProvider>(
        builder: (context, navBarProvider, child) {
          print('Selected Index: ${navBarProvider.selectedIndex}');
          return Scaffold(
            body: IndexedStack(
              index: navBarProvider.selectedIndex,
              children:
                _pages,
            ),
            bottomNavigationBar: BottomNavigationBar(
              items: <BottomNavigationBarItem>[
                BottomNavigationBarItem(
                  icon: SvgPicture.asset(
                    navBarProvider.selectedIndex == 0
                        ? 'lib/assets/images/home.svg'
                        : 'lib/assets/images/homeuns.svg',
                    height: 24,
                    width: 24,
                  ),
                  label: 'Home',
                ),
                BottomNavigationBarItem(
                  icon: SvgPicture.asset(
                    navBarProvider.selectedIndex == 1
                        ? 'lib/assets/images/donor.svg'
                        : 'lib/assets/images/donoruns.svg',
                    height: 24,
                    width: 24,
                  ),
                  label: 'Donor',
                ),
                BottomNavigationBarItem(
                  icon: SvgPicture.asset(
                    navBarProvider.selectedIndex == 2
                        ? 'lib/assets/images/payments.svg'
                        : 'lib/assets/images/paymentsuns.svg',
                    height: 24,
                    width: 24,
                  ),
                  label: 'Payments',
                ),
                BottomNavigationBarItem(
                  icon: SvgPicture.asset(
                    navBarProvider.selectedIndex == 3
                        ? 'lib/assets/images/settings.svg'
                        : 'lib/assets/images/settingsuns.svg',
                    height: 24,
                    width: 24,
                  ),
                  label: 'Settings',
                ),
              ],
              currentIndex: navBarProvider.selectedIndex,
              onTap: (index) => navBarProvider.changeIndex(index),
              elevation: 0,
              backgroundColor: Color(0xffF2F2F3),
              selectedItemColor: Color(0xff101011),
              unselectedItemColor: Color(0xff817D8A),
              selectedLabelStyle: TextStyle(
                  fontFamily: "Inter",
                  fontWeight: FontWeight.w400,
                  fontSize: 10),
              unselectedLabelStyle: TextStyle(
                  fontFamily: "Inter",
                  fontWeight: FontWeight.w400,
                  fontSize: 10),
              type: BottomNavigationBarType.fixed,
            ),
          );
        },
      ),
    );
  }
}
