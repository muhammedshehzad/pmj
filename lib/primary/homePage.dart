import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:pmj_application/primary/paymentsPage.dart';
import 'package:pmj_application/primary/settingsPage.dart';
import 'package:provider/provider.dart';
import 'package:shimmer/shimmer.dart';
import '../assets/custom%20widgets/shimmer_widgets.dart';
import '../assets/custom widgets/PeopleListViewHome.dart';
import '../assets/custom widgets/logoutpopup.dart';
import '../assets/custom widgets/transition.dart';
import '../secondary/all_donations.dart';
import '../services/local_database_service.dart';
import '../models/donation_model.dart';
import '../models/person_model.dart';
import 'donorPage.dart';
import 'package:intl/intl.dart';
import '../services/image_cache_service.dart';

class NavBarProvider with ChangeNotifier {
  int _selectedIndex = 0;

  int get selectedIndex => _selectedIndex;

  void changeIndex(int index) {
    _selectedIndex = index;
    notifyListeners();
  }
}

class PeopleProvider with ChangeNotifier {
  // This provider is now simplified since we use Isar streams directly
}



class homePage extends StatefulWidget {
  @override
  State<homePage> createState() => _homePageState();
}

class _homePageState extends State<homePage> {
  final LocalDatabaseService _localDb = LocalDatabaseService();

  @override
  void initState() {
    super.initState();
    // Initial sync with Firestore
    _localDb.syncWithFirestore().catchError((error) {
      debugPrint('Error syncing with Firestore: $error');
    });
  }

  @override
  Widget build(BuildContext context) {
    final currentMonth = DateFormat('MMMM').format(DateTime.now());
    final currentYear = DateTime.now().year.toString();

    return Padding(
      padding: const EdgeInsets.only(top: 16.0, left: 16, right: 16),
      child: Column(
        children: [
          StreamBuilder<List<Person>>(
            stream: _localDb.watchPeople(),
            builder: (context, donorSnapshot) {
              if (donorSnapshot.connectionState == ConnectionState.waiting) {
                // Show shimmer while loading top stats
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

              final donors = donorSnapshot.data ?? [];
              if (donors.isEmpty) {
                // Show shimmer placeholder instead of plain empty text
                return StatsShimmer();
              }

              // Calculate the total expected amount from donors
              double totalAmount = 0;
              for (var donor in donors) {
                totalAmount += donor.amount;
              }

              return StreamBuilder<List<Donation>>(
                stream: _localDb.watchDonations(),
                builder: (context, donationSnapshot) {
                  double collectedAmount = 0;
                  if (donationSnapshot.hasData) {
                    for (var donation in donationSnapshot.data!) {
                      if (donation.status == 'paid' && 
                          donation.month == currentMonth && 
                          donation.year == currentYear) {
                        collectedAmount += donation.amount.toDouble();
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
            child: StreamBuilder<List<Donation>>(
              stream: _localDb.watchDonations(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  // Show shimmer for recent donations list while loading
                  return DonationListShimmer();
                }
                if (snapshot.hasError) {
                  debugPrint('Database Error: ${snapshot.error}');
                  return Center(child: Text('Error: ${snapshot.error}'));
                }
                
                final allDonations = snapshot.data ?? [];
                // Filter for paid donations and take only recent 10
                final recentDonations = allDonations
                    .where((donation) => donation.status == 'paid')
                    .take(10)
                    .toList();

                if (recentDonations.isEmpty) {
                  // Show shimmer list placeholder instead of plain empty text
                  return DonationListShimmer();
                }

                return RefreshIndicator(
                  onRefresh: () async {
                    try {
                      await _localDb.syncWithFirestore();
                    } catch (e) {
                      debugPrint('Refresh error: $e');
                    }
                  },
                  child: ListView.builder(
                    physics: const AlwaysScrollableScrollPhysics(),
                    itemCount: recentDonations.length,
                    itemBuilder: (context, index) {
                    final donation = recentDonations[index];
                    final formattedDate = donation.date.isNotEmpty ? '${donation.date} • ' : '';
                    final monthYear = '${donation.month} ${donation.year}';

                    return ListTile(
                      onTap: () {
                        // Handle donation tap if needed
                      },
                      leading: SizedBox(
                        width: 40,
                        height: 40,
                        child: ClipOval(
                          child: Builder(
                            builder: (context) {
                              final effectiveUrl = (donation.imageUrl ?? '').trim();
                              if (effectiveUrl.isEmpty) {
                                return Container(
                                  color: const Color(0xff1BA3A1),
                                  child: Center(
                                    child: Text(
                                      donation.name.isNotEmpty ? donation.name[0].toUpperCase() : '',
                                      style: const TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.white,
                                      ),
                                    ),
                                  ),
                                );
                              }

                              return FutureBuilder<ImageProvider?>(
                                future: ImageCacheService().getImageProvider(effectiveUrl),
                                builder: (context, snapshot) {
                                  if (snapshot.connectionState == ConnectionState.waiting) {
                                    return Shimmer.fromColors(
                                      baseColor: const Color(0xFFE0E0E0),
                                      highlightColor: const Color(0xFFF5F5F5),
                                      child: Container(color: Colors.white),
                                    );
                                  }

                                  if (snapshot.hasData && snapshot.data != null) {
                                    return Image(
                                      image: snapshot.data!,
                                      fit: BoxFit.cover,
                                      frameBuilder: (context, child, frame, wasSynchronouslyLoaded) {
                                        if (wasSynchronouslyLoaded) return child;
                                        return AnimatedOpacity(
                                          opacity: frame == null ? 0 : 1,
                                          duration: const Duration(milliseconds: 300),
                                          curve: Curves.easeInOut,
                                          child: child,
                                        );
                                      },
                                      errorBuilder: (context, error, stackTrace) {
                                        return Container(
                                          color: const Color(0xff1BA3A1),
                                          child: Center(
                                            child: Text(
                                              donation.name.isNotEmpty ? donation.name[0].toUpperCase() : '',
                                              style: const TextStyle(
                                                fontSize: 16,
                                                fontWeight: FontWeight.bold,
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
                                        donation.name.isNotEmpty ? donation.name[0].toUpperCase() : '',
                                        style: const TextStyle(
                                          fontSize: 16,
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
                      title: Text(
                        donation.name,
                        style: const TextStyle(
                          fontSize: 14,
                          fontFamily: "Inter",
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      subtitle: Text(
                        '$formattedDate$monthYear',
                        style: const TextStyle(
                          fontSize: 10,
                          fontFamily: "Inter",
                          fontWeight: FontWeight.w400,
                          color: Color(0xff817D8A),
                        ),
                      ),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                "₹${donation.amount.toString()}",
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    );
                  },
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
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