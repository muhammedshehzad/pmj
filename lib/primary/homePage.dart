import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:pmj_application/primary/paymentsPage.dart';
import 'package:pmj_application/primary/settingsPage.dart';
import 'package:provider/provider.dart';
import 'package:shimmer/shimmer.dart'; // Add this dependency
import '../assets/custom widgets/PeopleListViewHome.dart';
import '../assets/custom widgets/logoutpopup.dart';
import '../assets/custom widgets/transition.dart';
import '../secondary/all_donations.dart';
import 'donorPage.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart'; // Add this for formatting the month name

class NavBarProvider with ChangeNotifier {
  int _selectedIndex = 0;

  int get selectedIndex => _selectedIndex;

  void changeIndex(int index) {
    _selectedIndex = index;
    notifyListeners();
  }
}

class PeopleProvider with ChangeNotifier {
  List<personHome> _peoplesHome = [];

  List<personHome> get peoplesHome => _peoplesHome;
}

// Shimmer widget for the statistics container
class StatsShimmer extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      height: 115,
      decoration: BoxDecoration(
        border: Border.all(width: 1, color: Color(0xff1BA3A1)),
        borderRadius: BorderRadius.circular(4),
      ),
      width: MediaQuery.of(context).size.width,
      child: Shimmer.fromColors(
        baseColor: Colors.grey[300]!,
        highlightColor: Colors.grey[100]!,
        child: Column(
          children: [
            SizedBox(height: 15),
            Container(
              width: 60,
              height: 14,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(4),
              ),
            ),
            SizedBox(height: 10),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                Column(
                  children: [
                    Container(
                      width: 30,
                      height: 10,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                    SizedBox(height: 5),
                    Container(
                      width: 50,
                      height: 19,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                  ],
                ),
                Container(width: 1, color: Colors.grey[400], height: 50),
                Column(
                  children: [
                    Container(
                      width: 50,
                      height: 10,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                    SizedBox(height: 5),
                    Container(
                      width: 60,
                      height: 19,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                  ],
                ),
                Container(width: 1, color: Colors.grey[400], height: 50),
                Column(
                  children: [
                    Container(
                      width: 40,
                      height: 10,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                    SizedBox(height: 5),
                    Container(
                      width: 55,
                      height: 19,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

// Shimmer widget for donation list items
class DonationListShimmer extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Shimmer.fromColors(
      baseColor: Colors.grey[300]!,
      highlightColor: Colors.grey[100]!,
      child: ListView.builder(
        itemCount: 6,
        itemBuilder: (context, index) {
          return Container(
            margin: EdgeInsets.symmetric(vertical: 8, horizontal: 4),
            padding: EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.grey[200]!),
            ),
            child: Row(
              children: [
                // Avatar shimmer
                CircleAvatar(
                  radius: 25,
                  backgroundColor: Colors.white,
                ),
                SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Name shimmer
                      Container(
                        width: double.infinity,
                        height: 16,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(4),
                        ),
                      ),
                      SizedBox(height: 8),
                      // Date shimmer
                      Container(
                        width: 100,
                        height: 12,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(4),
                        ),
                      ),
                      SizedBox(height: 4),
                      // Method shimmer
                      Container(
                        width: 80,
                        height: 12,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(4),
                        ),
                      ),
                    ],
                  ),
                ),
                // Amount shimmer
                Container(
                  width: 60,
                  height: 20,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

class homePage extends StatefulWidget {
  @override
  State<homePage> createState() => _homePageState();
}

class _homePageState extends State<homePage> {
  Future<List<personHome>> _buildPersonHomeList(
      List<Map<String, dynamic>> donations) async {
    List<personHome> personHomeList = [];
    for (var donation in donations) {
      final data = donation['data'] as Map<String, dynamic>;
      final donorId = donation['donorId'] as String?;

      if (donorId == null || donorId.isEmpty) {
        continue; // Skip invalid donorId
      }

      final donorSnapshot = await FirebaseFirestore.instance
          .collection('donors')
          .doc(donorId)
          .get();

      final donorData = donorSnapshot.data() as Map<String, dynamic>?;
      final donorName = donorData?['name'] ?? 'Unknown';

      personHomeList.add(
        personHome(
          name: donorName,
          date: _formatTimestamp(data['timestamp']),
          amount: (data['amount'] as num?)?.toInt() ?? 0,
          donorId: donorId,
          // Use donorId instead of photoUrl
          method: data['paymentMethod'] ?? 'Unknown',
          month: data['month'] ?? 'Unknown',
          year: data['year'] ?? 'Unknown',
          status: data['status'] ?? 'Unpaid',
        ),
      );
    }
    return personHomeList;
  }

  @override
  Widget build(BuildContext context) {
    final currentMonth = DateFormat('MMMM').format(DateTime.now());
    final currentYear = DateTime.now().year.toString();

    return Padding(
      padding: const EdgeInsets.only(top: 16.0, left: 16, right: 16),
      child: Column(
        children: [
          StreamBuilder<QuerySnapshot>(
            stream: FirebaseFirestore.instance.collection('donors').snapshots(),
            builder: (context, donorSnapshot) {
              if (donorSnapshot.connectionState == ConnectionState.waiting) {
                return StatsShimmer();
              }

              if (donorSnapshot.hasError) {
                return Container(
                  height: 115,
                  decoration: BoxDecoration(
                    border: Border.all(width: 1, color: Color(0xff1BA3A1)),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  width: MediaQuery.of(context).size.width,
                  child: Center(child: Text('Error: ${donorSnapshot.error}')),
                );
              }

              if (!donorSnapshot.hasData || donorSnapshot.data!.docs.isEmpty) {
                return Container(
                  height: 115,
                  decoration: BoxDecoration(
                    border: Border.all(width: 1, color: Color(0xff1BA3A1)),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  width: MediaQuery.of(context).size.width,
                  child: Center(child: Text('No donors found')),
                );
              }

              // Calculate the total expected amount from donors collection
              double totalAmount = 0;
              for (var doc in donorSnapshot.data!.docs) {
                final data = doc.data() as Map<String, dynamic>;
                final amount = (data['amount'] as num?)?.toDouble() ?? 0.0;
                totalAmount += amount;
              }

              return StreamBuilder<QuerySnapshot>(
                stream: FirebaseFirestore.instance
                    .collectionGroup('paymentStatus')
                    .where('month', isEqualTo: currentMonth)
                    .where('year', isEqualTo: currentYear)
                    .snapshots(),
                builder: (context, paymentSnapshot) {
                  double collectedAmount = 0;
                  if (paymentSnapshot.hasData) {
                    for (var doc in paymentSnapshot.data!.docs) {
                      final data = doc.data() as Map<String, dynamic>;
                      if (data['status'] == 'paid') {
                        final amount =
                            (data['amount'] as num?)?.toDouble() ?? 0.0;
                        collectedAmount += amount;
                      }
                    }
                  }

                  double balanceAmount = totalAmount - collectedAmount;

                  return Container(
                    height: 115,
                    decoration: BoxDecoration(
                      border: Border.all(width: 1, color: Color(0xff1BA3A1)),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    width: MediaQuery.of(context).size.width,
                    child: Column(
                      children: [
                        SizedBox(height: 15),
                        Text(
                          currentMonth,
                          style: TextStyle(
                              fontSize: 12,
                              fontFamily: "Inter",
                              fontWeight: FontWeight.w600),
                        ),
                        SizedBox(height: 10),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                          children: [
                            Column(
                              children: [
                                Text("Total",
                                    style: TextStyle(
                                        fontSize: 10,
                                        fontFamily: "Inter",
                                        fontWeight: FontWeight.w400)),
                                Text(
                                  "₹${totalAmount.toStringAsFixed(0)}",
                                  style: TextStyle(
                                      fontSize: 19,
                                      fontFamily: "Inter",
                                      fontWeight: FontWeight.w600),
                                ),
                              ],
                            ),
                            Container(
                                width: .9,
                                color: Color(0xff101011),
                                height: 50),
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
                                  "₹${collectedAmount.toStringAsFixed(0)}",
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
                                height: 50),
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
                                  "₹${balanceAmount.toStringAsFixed(0)}",
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
                        ),
                      ],
                    ),
                  );
                },
              );
            },
          ),
          SizedBox(height: 14),
          GestureDetector(
            onTap: () {
              Provider.of<NavBarProvider>(context, listen: false)
                  .changeIndex(2);
            },
            child: Container(
              height: 102,
              width: MediaQuery.of(context).size.width,
              decoration: BoxDecoration(
                color: Color(0xff1BA3A1),
                border: Border.all(width: 1, color: Color(0xff1BA3A1)),
                borderRadius: BorderRadius.circular(4),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Padding(
                    padding: const EdgeInsets.all(4.0),
                    child: SvgPicture.asset('lib/assets/images/BTN1.svg',
                        height: 40, width: 40),
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
                  Navigator.push(
                    context,
                    SlidingPageTransitionRL(page: AllDonationsPage()),
                  );
                },
                child: Text(
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
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collectionGroup('paymentStatus')
                  .where('status', isEqualTo: 'paid')
                  .orderBy('timestamp', descending: true)
                  .limit(8)
                  .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return DonationListShimmer();
                }
                if (snapshot.hasError) {
                  print('Firestore Error: ${snapshot.error}');
                  return Center(child: Text('Error: ${snapshot.error}'));
                }
                if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                  return Center(child: Text('No recent donations'));
                }

                final donations = snapshot.data!.docs.map((doc) {
                  final data = doc.data() as Map<String, dynamic>;
                  final donorId = doc.reference.parent.parent?.id;
                  return {'data': data, 'donorId': donorId};
                }).toList();

                return FutureBuilder<List<personHome>>(
                  future: _buildPersonHomeList(donations),
                  builder: (context, futureSnapshot) {
                    if (futureSnapshot.connectionState ==
                        ConnectionState.waiting) {
                      return DonationListShimmer();
                    }
                    if (futureSnapshot.hasError) {
                      print('Future Error: ${futureSnapshot.error}');
                      return Center(
                          child: Text('Error: ${futureSnapshot.error}'));
                    }
                    if (!futureSnapshot.hasData ||
                        futureSnapshot.data!.isEmpty) {
                      return Center(child: Text('No recent donations'));
                    }

                    return PeopleListViewHome(
                        peoplesHome: futureSnapshot.data!);
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  String _formatTimestamp(Timestamp? timestamp) {
    if (timestamp == null) return "Unknown Date";
    final date = timestamp.toDate();
    return "${date.day.toString().padLeft(2, '0')}.${date.month.toString().padLeft(2, '0')}.${date.year}";
  }
}

class BottomNavBarExample extends StatelessWidget {
  final List<Widget> _pages = [
    homePage(),
    donorPage(),
    PaymentsPage(),
    SettingsPage(),
  ];

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (context) => NavBarProvider(),
      child: Consumer<NavBarProvider>(
        builder: (context, navBarProvider, child) {
          print('Selected Index: ${navBarProvider.selectedIndex}');
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
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16.0, vertical: 8),
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
                        Row(
                          children: [
                            SizedBox(width: 10),
                            // Space between refresh and logout
                            Container(
                              height: 26,
                              width: 84,
                              child: ElevatedButton(
                                onPressed: () =>
                                    showLogoutConfirmation(context),
                                style: ElevatedButton.styleFrom(
                                  foregroundColor: Colors.black,
                                  backgroundColor: Colors.white,
                                  shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(2)),
                                  elevation: 0,
                                ),
                                child: Center(
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
                      ],
                    ),
                  ),
                ),
              ),
            ),
            body: IndexedStack(
              index: navBarProvider.selectedIndex,
              children: _pages,
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