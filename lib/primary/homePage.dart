import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:pmj_application/primary/paymentsPage.dart';
import 'package:pmj_application/primary/settingsPage.dart';
import 'package:pmj_application/screens/transactions_page.dart';
import 'package:pmj_application/services/permission_service.dart';
import 'package:provider/provider.dart';
import 'package:shimmer/shimmer.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../assets/custom%20widgets/shimmer_widgets.dart';
import '../assets/custom widgets/PeopleListViewHome.dart';
import '../assets/custom widgets/logoutpopup.dart';
import '../assets/custom widgets/transition.dart';
import '../secondary/all_donations.dart';
import '../services/local_database_service.dart';
import '../models/donation_model.dart';
import '../models/person_model.dart';
import '../widgets/stable_avatar.dart';
import 'donorPage.dart';
import 'package:intl/intl.dart';
import '../services/image_cache_service.dart';
import '../utils/month_formatter.dart';

class NavBarProvider with ChangeNotifier {
  int _selectedIndex = 0;

  int get selectedIndex => _selectedIndex;

  void changeIndex(int index) {
    _selectedIndex = index;
    notifyListeners();
  }
}

class homePage extends StatefulWidget {
  const homePage({Key? key}) : super(key: key);
  
  @override
  State<homePage> createState() => _homePageState();
}

class _homePageState extends State<homePage> with AutomaticKeepAliveClientMixin {
  final LocalDatabaseService _localDb = LocalDatabaseService();
  bool _isInitialLoad = true;
  bool _isSyncing = false;

  // Memoized dashboard stats
  late Future<Map<String, double>> _statsFuture;
  Map<String, double>? _lastStats; // cache to prevent UI flicker on refresh
  late String _currentMonth;
  late String _currentYear;
  // Stable stream and cache for recent donations list to avoid flicker
  late final Stream<List<Donation>> _recentDonationsStream;
  List<Donation>? _lastRecentDonations;

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    // Set up initial data without immediate sync to prevent unnecessary refreshes
    _currentMonth = DateFormat('MMMM').format(DateTime.now());
    _currentYear = DateTime.now().year.toString();
    // Initialize stats future immediately to prevent late init issues on first build
    _statsFuture = _calculateDashboardStats(_currentMonth, _currentYear);
    // Populate cache when first stats load completes
    _statsFuture.then((value) {
      if (mounted) {
        setState(() {
          _lastStats = value;
        });
      }
    });
    // Only sync if needed, not on every init to avoid unnecessary refreshes
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      if (_isInitialLoad && mounted) {
        // For now, always sync on initial load to ensure data is up-to-date
        // This prevents the issue where the page would refresh after loading
        _syncData();
      }
    });

    // Initialize stable stream for recent donations to avoid resubscribe on rebuilds
    _recentDonationsStream = _localDb.watchDonations();
  }

  Future<void> _syncData() async {
    // Prevent multiple simultaneous sync operations
    if (_isSyncing) return;
    
    try {
      _isSyncing = true;
      await _localDb.syncWithFirestore();
      if (mounted) {
        setState(() {
          _isInitialLoad = false;
          _statsFuture = _calculateDashboardStats(_currentMonth, _currentYear);
        });
        // update cache without forcing shimmer
        _statsFuture.then((value) {
          if (mounted) {
            setState(() {
              _lastStats = value;
            });
          }
        });
      }
    } catch (error) {
      debugPrint('Error syncing with Firestore: $error');
      if (mounted) {
        setState(() {
          _isInitialLoad = false;
        });
      }
    }
    finally {
      _isSyncing = false;
    }
  }

  // Add method to refresh data when page becomes visible
  void _refreshData() {
    // Prevent multiple simultaneous refresh operations
    if (_isSyncing) return;
    _isSyncing = true;
    _localDb.syncWithFirestore().then((_) {
      if (mounted) {
        setState(() {
          _statsFuture = _calculateDashboardStats(_currentMonth, _currentYear);
        });
        _statsFuture.then((value) {
          if (mounted) {
            setState(() {
              _lastStats = value;
            });
          }
        });
      }
    }).catchError((error) {
      debugPrint('Error refreshing data: $error');
    }).whenComplete(() {
      _isSyncing = false;
    });
  }

  

  // Calculate dashboard stats directly from Firestore
  Future<Map<String, double>> _calculateDashboardStats(String currentMonth, String currentYear) async {
    try {
      // Get all donors to calculate total expected amount
      final donorsSnapshot = await FirebaseFirestore.instance.collection('donors').get();
      double totalAmount = 0;
      
      for (var doc in donorsSnapshot.docs) {
        final data = doc.data();
        final amount = (data['amount'] as num?)?.toDouble() ?? 0.0;
        totalAmount += amount;
      }

      // Get collected amount for current month/year
      double collectedAmount = 0;
      final paymentsQuery = await FirebaseFirestore.instance
          .collectionGroup('paymentStatus')
          .where('status', isEqualTo: 'paid')
          .where('month', isEqualTo: currentMonth)
          .where('year', isEqualTo: currentYear)
          .get();

      for (var doc in paymentsQuery.docs) {
        final data = doc.data();
        final amount = (data['amount'] as num?)?.toDouble() ?? 0.0;
        collectedAmount += amount;
      }

      final balanceAmount = totalAmount - collectedAmount;

      return {
        'total': totalAmount,
        'collected': collectedAmount,
        'balance': balanceAmount,
      };
    } catch (e) {
      debugPrint('Error calculating dashboard stats: $e');
      return {'total': 0.0, 'collected': 0.0, 'balance': 0.0};
    }
  }



  @override
  Widget build(BuildContext context) {
    super.build(context); // Required for AutomaticKeepAliveClientMixin

    return RefreshIndicator(
      onRefresh: () async {
        try {
          setState(() {
            _isInitialLoad = true;
          });
          await _localDb.syncWithFirestore();
          if (mounted) {
            setState(() {
              _isInitialLoad = false;
              _statsFuture = _calculateDashboardStats(_currentMonth, _currentYear);
            });
          }
        } catch (e) {
          debugPrint('Refresh error: $e');
          if (mounted) {
            setState(() {
              _isInitialLoad = false;
            });
          }
        }
      },
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        child: Padding(
          padding: const EdgeInsets.only(top: 16.0, left: 16, right: 16),
          child: Column(
            children: [
              FutureBuilder<Map<String, double>>(
                future: _statsFuture,
                initialData: _lastStats,
                builder: (context, statsSnapshot) {
                  // Only show shimmer if we have never loaded stats before or if we are still in initial load
                  if ((statsSnapshot.connectionState == ConnectionState.waiting || _isInitialLoad) &&
                      (statsSnapshot.data == null && _lastStats == null)) {
                    return StatsShimmer();
                  }

                  if (statsSnapshot.hasError && (statsSnapshot.data == null && _lastStats == null)) {
                    return Container(
                      height: 115,
                      decoration: BoxDecoration(
                        border: Border.all(width: 1, color: Color(0xff1BA3A1)),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      width: MediaQuery.of(context).size.width,
                      child: Center(child: Text('Error loading stats')),
                    );
                  }

                  final stats = statsSnapshot.data ?? _lastStats ?? {'total': 0.0, 'collected': 0.0, 'balance': 0.0};
                  final totalAmount = stats['total'] ?? 0.0;
                  final collectedAmount = stats['collected'] ?? 0.0;

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
                              _currentMonth,
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
                        decorationColor: Theme.of(context).brightness == Brightness.dark ? Colors.white70 : Colors.black,
                        color: Theme.of(context).brightness == Brightness.dark ? Colors.white : const Color(0xff0B190C),
                      ),
                    ),
                  ),
                ],
              ),
              StreamBuilder<List<Donation>>(
                stream: _recentDonationsStream,
                initialData: _lastRecentDonations,
                builder: (context, snapshot) {
                  // Show shimmer while we are still in initial load or before the first ever data arrives
                  final hasAnyData = (snapshot.data != null && snapshot.data!.isNotEmpty) || (_lastRecentDonations != null && _lastRecentDonations!.isNotEmpty);
                  if ((snapshot.connectionState == ConnectionState.waiting || _isInitialLoad) && !hasAnyData) {
                    return DonationListShimmer();
                  }

                  if (snapshot.hasError && !hasAnyData) {
                    debugPrint('Database Error: ${snapshot.error}');
                    return Center(child: Text('Error: ${snapshot.error}'));
                  }

                  final allDonations = snapshot.data ?? _lastRecentDonations ?? [];
                  // keep cache updated without triggering rebuild loop
                  _lastRecentDonations = allDonations;

                  // Filter for paid donations, take only recent 10, and skip hidden history entries
                  final recentDonations = allDonations
                      .where((donation) => 
                        donation.status == 'paid' && 
                        donation.hideFromHistory != true &&
                        (donation.monthsList == null || donation.monthsList!.isNotEmpty)
                      )
                      .toList();
                  
                  // Sort and take 10 (though watchDonations should already sort)
                  // We also need to manualy filter out the "hidden" entries if they are in the stream
                  // Note: Donations from SQLite already have monthsList
                  
                  final filteredDonations = <Donation>[];
                  final seenMainEntries = <String>{};

                  for (var donation in recentDonations) {
                    // If it has a monthsList and status is paid, it's likely a consolidated entry or a single month
                    // We want to avoid showing the same donation twice if the stream has both
                    final key = '${donation.donorId}_${donation.month}_${donation.year}';
                    if (!seenMainEntries.contains(key)) {
                      filteredDonations.add(donation);
                      seenMainEntries.add(key);
                    }
                  }

                  final displayDonations = filteredDonations.take(10).toList();

                  if (displayDonations.isEmpty) {
                    // Show an empty friendly state instead of shimmer to avoid flicker
                    return Padding(
                      padding: const EdgeInsets.symmetric(vertical: 16.0),
                      child: Center(
                        child: Text(
                          'No recent donations',
                          style: const TextStyle(
                            fontSize: 12,
                            fontFamily: 'Inter',
                            color: Color(0xff817D8A),
                          ),
                        ),
                      ),
                    );
                  }

                  return Material(
                    color: Colors.transparent,
                    child: ListView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: displayDonations.length,
                      itemBuilder: (context, index) {
                      final donation = displayDonations[index];
                      final formattedDate = donation.date.isNotEmpty ? '${donation.date} • ' : '';
                      
                      String monthYear;
                      if (donation.monthsList != null && donation.monthsList!.isNotEmpty) {
                        monthYear = MonthFormatter.formatMonthList(donation.monthsList!, donation.year);
                      } else {
                        monthYear = '${donation.month} ${donation.year}';
                      }

                      final amount = donation.totalDonationAmount ?? donation.amount;

                      return ListTile(
                        onTap: () {
                          // Handle donation tap if needed
                        },
                        leading: StableAvatar(
                          imageUrl: donation.imageUrl,
                          name: donation.name,
                          radius: 20,
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
                                  "₹${amount.toStringAsFixed(0)}",
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
            ],
          ),
        ),
      ),
    );
  }


}

class BottomNavBarExample extends StatefulWidget {
  @override
  _BottomNavBarExampleState createState() => _BottomNavBarExampleState();
}

/// One bottom-nav entry. Used by [BottomNavBarExample] so the role-based
/// filter can pick the right combination at build time.
class _NavEntry {
  final String key; // 'home' | 'donor' | 'payments' | 'accounts' | 'settings'
  final String label;
  final Widget page;
  final Widget Function(bool selected, BuildContext ctx) iconBuilder;
  _NavEntry({
    required this.key,
    required this.label,
    required this.page,
    required this.iconBuilder,
  });
}

class _BottomNavBarExampleState extends State<BottomNavBarExample> {
  final GlobalKey<_homePageState> _homePageKey = GlobalKey<_homePageState>();
  late final List<_NavEntry> _allEntries;
  int _lastIndex = 0;
  late final NavBarProvider _navBarProvider;
  DateTime? _lastHomeRefreshAt; // throttle home auto-refresh

  @override
  void initState() {
    super.initState();
    _navBarProvider = NavBarProvider();
    _allEntries = [
      _NavEntry(
        key: 'home',
        label: 'Home',
        page: homePage(key: _homePageKey),
        iconBuilder: (sel, _) => SvgPicture.asset(
          sel ? 'lib/assets/images/home.svg' : 'lib/assets/images/homeuns.svg',
          height: 24,
          width: 24,
        ),
      ),
      _NavEntry(
        key: 'donor',
        label: 'Donor',
        page: donorPage(),
        iconBuilder: (sel, _) => SvgPicture.asset(
          sel
              ? 'lib/assets/images/donor.svg'
              : 'lib/assets/images/donoruns.svg',
          height: 24,
          width: 24,
        ),
      ),
      _NavEntry(
        key: 'payments',
        label: 'Payments',
        page: PaymentsPage(),
        iconBuilder: (sel, _) => SvgPicture.asset(
          sel
              ? 'lib/assets/images/payments.svg'
              : 'lib/assets/images/paymentsuns.svg',
          height: 24,
          width: 24,
        ),
      ),
      _NavEntry(
        key: 'accounts',
        label: 'Accounts',
        page: const TransactionsPage(),
        iconBuilder: (sel, ctx) => Icon(
          Icons.swap_horiz_rounded,
          size: 24,
          color: sel
              ? (Theme.of(ctx).brightness == Brightness.dark
                  ? Colors.white
                  : const Color(0xff101011))
              : const Color(0xff817D8A),
        ),
      ),
      _NavEntry(
        key: 'settings',
        label: 'Settings',
        page: SettingsPage(),
        iconBuilder: (sel, _) => SvgPicture.asset(
          sel
              ? 'lib/assets/images/settings.svg'
              : 'lib/assets/images/settingsuns.svg',
          height: 24,
          width: 24,
        ),
      ),
    ];
  }

  /// Filter entries by role. Collectors don't see Accounts.
  List<_NavEntry> _visibleEntries(Permissions perms) {
    return _allEntries.where((e) {
      switch (e.key) {
        case 'home':
          return perms.canSeeHomeTab;
        case 'donor':
          return perms.canSeeDonorTab;
        case 'payments':
          return perms.canSeePaymentsTab;
        case 'accounts':
          return perms.canSeeAccountsTab;
        case 'settings':
          return perms.canSeeSettingsTab;
        default:
          return false;
      }
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final perms = context.watch<Permissions>();
    final entries = _visibleEntries(perms);

    return ChangeNotifierProvider.value(
      value: _navBarProvider,
      child: Consumer<NavBarProvider>(
        builder: (context, navBarProvider, child) {
          // Clamp selected index to the new list length (in case role changed)
          int currentIndex = navBarProvider.selectedIndex;
          if (currentIndex >= entries.length) {
            currentIndex = 0;
            WidgetsBinding.instance.addPostFrameCallback((_) {
              navBarProvider.changeIndex(0);
            });
          }

          if (currentIndex != _lastIndex) {
            if (entries.isNotEmpty && entries[currentIndex].key == 'home') {
              final now = DateTime.now();
              final shouldRefresh = _lastHomeRefreshAt == null ||
                  now.difference(_lastHomeRefreshAt!).inSeconds > 30;
              if (shouldRefresh) {
                WidgetsBinding.instance.addPostFrameCallback((_) {
                  _homePageKey.currentState?._refreshData();
                });
                _lastHomeRefreshAt = now;
              }
            }
            _lastIndex = currentIndex;
          }
          return Scaffold(
            backgroundColor: Theme.of(context).scaffoldBackgroundColor,
            appBar: PreferredSize(
              preferredSize: const Size.fromHeight(100),
              child: AppBar(
                elevation: 0,
                backgroundColor: const Color(0xff1BA3A1),
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
                            SizedBox(
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
                      ],
                    ),
                  ),
                ),
              ),
            ),
            body: IndexedStack(
              index: currentIndex,
              children: [for (final e in entries) e.page],
            ),
            bottomNavigationBar: BottomNavigationBar(
              items: [
                for (int i = 0; i < entries.length; i++)
                  BottomNavigationBarItem(
                    icon: entries[i].iconBuilder(i == currentIndex, context),
                    label: entries[i].label,
                  ),
              ],
              currentIndex: currentIndex,
              onTap: (index) => navBarProvider.changeIndex(index),
              elevation: 0,
              backgroundColor: Theme.of(context).brightness == Brightness.dark
                  ? const Color(0xFF1E1E1E)
                  : const Color(0xffF2F2F3),
              selectedItemColor: Theme.of(context).brightness == Brightness.dark
                  ? Colors.white
                  : const Color(0xff101011),
              unselectedItemColor: const Color(0xff817D8A),
              selectedLabelStyle: const TextStyle(
                  fontFamily: "Inter", fontWeight: FontWeight.w400, fontSize: 10),
              unselectedLabelStyle: const TextStyle(
                  fontFamily: "Inter", fontWeight: FontWeight.w400, fontSize: 10),
              type: BottomNavigationBarType.fixed,
            ),
          );
        },
      ),
    );
  }
}