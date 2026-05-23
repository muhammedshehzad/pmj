import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:intl/intl.dart';
import 'package:pmj_application/assets/custom widgets/PeopleListViewHome.dart';
import 'package:pmj_application/assets/custom widgets/logoutpopup.dart';
import '../assets/custom widgets/transition.dart';
import '../utils/month_formatter.dart';
import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'dart:ui' as ui;
import 'package:flutter/rendering.dart';
import 'package:provider/provider.dart';
import 'donations_provider.dart';
import '../models/person_model.dart';
import '../services/image_cache_service.dart';
import '../services/local_database_service.dart';
import 'deletion_history_page.dart';
import 'package:shimmer/shimmer.dart';
import '../assets/custom%20widgets/shimmer_widgets.dart';
import '../assets/custom widgets/transition.dart';

class AllDonationsPage extends StatefulWidget {
  @override
  _AllDonationsPageState createState() => _AllDonationsPageState();
}

class _AllDonationsPageState extends State<AllDonationsPage> {
  final Map<String, Map<String, dynamic>> _donorCache = {};
  bool _isLoading = false;
  double _loadingProgress = 0.0;
  int _totalDocuments = 0;
  int _loadedDocuments = 0;
  List<Person> _processedDonations = [];
  QuerySnapshot? _latestSnapshot;
  final _loadingController = StreamController<double>.broadcast();
  String _searchFilter = '';
  final _searchController = TextEditingController();
  String? _errorMessage;
  StreamSubscription<QuerySnapshot>? _donationsSubscription;
  bool _hasInitialData = false;
  final ScrollController _scrollController = ScrollController();
  List<Person> _paginatedDonations = [];
  bool _isPaginating = false;
  bool _hasMore = true;
  bool _initialLoading = true;
  DocumentSnapshot? _lastDocument;
  static const int _pageSize = 30;

  // Server-assisted search state
  bool _isSearching = false;
  bool _searchPaginating = false;
  bool _searchHasMore = true;
  DocumentSnapshot? _lastSearchDocument;
  final List<Person> _searchResults = [];
  Timer? _searchDebounce;

  // Batched display to avoid piecemeal updates
  final List<Person> _stagedSearchResults = [];
  bool _searchPriming = false; // true until first batch committed
  static const int _searchBatchThreshold = 10;

  @override
  void initState() {
    super.initState();
    _setupLoadingController();
    _setupSearchController();
    _fetchInitialDonations();
    _scrollController.addListener(_onScroll);
  }

  void _setupLoadingController() {
    _loadingController.stream.listen((progress) {
      if (mounted) {
        setState(() {
          _loadingProgress = progress;
        });
      }
    });
  }

  void _setupSearchController() {
    _searchController.addListener(() {
      _handleSearchChange(_searchController.text);
    });
  }

  void _handleSearchChange(String value) {
    final q = value.trim();
    _searchDebounce?.cancel();
    _searchDebounce = Timer(const Duration(milliseconds: 350), () {
      setState(() {
        _searchFilter = q.toLowerCase();
      });
      if (_searchFilter.isEmpty) {
        // Exit search mode
        setState(() {
          _isSearching = false;
          _searchResults.clear();
          _searchHasMore = true;
          _lastSearchDocument = null;
        });
      } else {
        // Start server-assisted search
        _startServerSearch();
      }
    });
  }

  @override
  void dispose() {
    _donationsSubscription?.cancel();
    _loadingController.close();
    _searchController.dispose();
    // Ensure any pending debounced callbacks are cancelled to avoid calling setState after dispose
    _searchDebounce?.cancel();
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - 200) {
      if (_isSearching) {
        if (!_searchPaginating && _searchHasMore) {
          _fetchMoreSearchResults();
        }
      } else {
        if (!_isPaginating && _hasMore && !_initialLoading) {
          _fetchMoreDonations();
        }
      }
    }
  }

  Future<void> _fetchInitialDonations() async {
    setState(() {
      _isPaginating = true;
      _hasMore = true;
      _paginatedDonations.clear();
      _lastDocument = null;
      _initialLoading = true;
    });
    Query query = FirebaseFirestore.instance
        .collectionGroup('paymentStatus')
        .where('status', isEqualTo: 'paid')
        .orderBy('timestamp', descending: true)
        .limit(_pageSize);
    QuerySnapshot snapshot = await query.get();
    await _processPaginatedDocs(snapshot, isInitial: true);
  }

  Future<void> _fetchMoreDonations() async {
    if (!_hasMore || _isPaginating) return;
    setState(() {
      _isPaginating = true;
    });
    Query query = FirebaseFirestore.instance
        .collectionGroup('paymentStatus')
        .where('status', isEqualTo: 'paid')
        .orderBy('timestamp', descending: true)
        .startAfterDocument(_lastDocument!)
        .limit(_pageSize);
    QuerySnapshot snapshot = await query.get();
    await _processPaginatedDocs(snapshot, isInitial: false);
  }

  Future<void> _processPaginatedDocs(QuerySnapshot snapshot,
      {required bool isInitial}) async {
    if (snapshot.docs.isEmpty) {
      if (!mounted) return;
      setState(() {
        _hasMore = false;
        _isPaginating = false;
        _initialLoading = false;
      });
      return;
    }
    Set<String> donorIds = {};
    for (var doc in snapshot.docs) {
      // paymentStatus doc is inside donors/{donorId}/paymentStatus
      final donorId = doc.reference.parent.parent?.id;
      if (donorId != null && donorId.isNotEmpty) {
        donorIds.add(donorId);
      }
    }
    // Prefetch donor data
    final donorCache = <String, Map<String, dynamic>>{};
    if (donorIds.isNotEmpty) {
      final donorIdList = donorIds.toList();
      for (var i = 0; i < donorIdList.length; i += 10) {
        final chunk = donorIdList.sublist(i, (i + 10).clamp(0, donorIdList.length));
        final donorsSnapshot = await FirebaseFirestore.instance
            .collection('donors')
            .where(FieldPath.documentId, whereIn: chunk)
            .get();
        for (var doc in donorsSnapshot.docs) {
          if (doc.exists && doc.data().isNotEmpty) {
            donorCache[doc.id] = doc.data();
          }
        }
      }
    }

    List<Person> newDonations = [];
    for (var doc in snapshot.docs) {
      final data = doc.data() as Map<String, dynamic>?;
      if (data == null) continue;
      
      // Consolidation logic: Skip entries marked to be hidden
      if (data['hideFromHistory'] == true) continue;
      
      final donorId = doc.reference.parent.parent?.id ?? data['donorId'] as String?;
      if (donorId != null && donorId.isNotEmpty) {
        final donorData = donorCache[donorId];
        final donorName = donorData?['name'] ?? data['name'] ?? 'Unknown Donor';
        final donorImageUrl = donorData?['imageUrl'] ?? data['imageUrl'] ?? '';
        final donorAddress = donorData?['address']?.toString() ?? 'Unknown';
        
        final monthsList = data['monthsList'] != null ? List<String>.from(data['monthsList']) : null;
        final amount = (data['totalDonationAmount'] ?? data['amount'] ?? 0);

        newDonations.add(Person(
          name: donorName,
          house: donorAddress,
          photoUrl: donorImageUrl,
          amount: _parseAmount(amount).toDouble(),
          date: _formatTimestamp(data['timestamp'] ?? data['paidDate'] ?? data['date']),
          month: data['month']?.toString() ?? 'Unknown',
          year: data['year']?.toString() ?? 'Unknown',
          method: data['method']?.toString() ?? data['paymentMethod']?.toString() ?? 'Unknown',
          status: data['status']?.toString() ?? 'Paid',
          donorId: donorId,
          documentPath: doc.reference.path,
          donationId: data['donationId']?.toString(), // Added donationId
          imageUrl: donorImageUrl,
          monthsList: monthsList,
          timestamp: (data['timestamp'] is Timestamp)
              ? (data['timestamp'] as Timestamp).toDate()
              : null,
        ));
      }
    }
    if (!mounted) return;
    setState(() {
      _paginatedDonations.addAll(newDonations);
      _lastDocument = snapshot.docs.last;
      _isPaginating = false;
      _initialLoading = false;
      if (snapshot.docs.length < _pageSize) {
        _hasMore = false;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
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
                  //       foregroundColor: Colors.black,
                  //       backgroundColor: Colors.white,
                  //       shape: RoundedRectangleBorder(
                  //         borderRadius: BorderRadius.circular(2),
                  //       ),
                  //       elevation: 0,
                  //     ),
                  //     child: const Center(
                  //       child: Text(
                  //         'Logout',
                  //         style: TextStyle(
                  //           fontSize: 10,
                  //           fontWeight: FontWeight.w600,
                  //           fontFamily: "Inter",
                  //         ),
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
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Padding(
                  padding: const EdgeInsets.only(top: 8.0, bottom: 4),
                  child: GestureDetector(
                    onTap: () => Navigator.pop(context),
                    child: SvgPicture.asset('lib/assets/images/Back.svg',
                        height: 40, width: 40),
                  ),
                ),
                const Text(
                  "All Donations",
                  style: TextStyle(
                    fontSize: 16,
                    fontFamily: "Inter",
                    fontWeight: FontWeight.w600,
                    color: Color(0xff1BA3A1),
                  ),
                ),
                PopupMenuButton<String>(
                  tooltip: 'More',
                  onSelected: (value) {
                    if (value == 'history') {
                      Navigator.push(
                        context,
                        SlidingPageTransitionRL(page: DeletionHistoryPage()),
                      );
                    }
                  },
                  color: Theme.of(context).cardColor,
                  itemBuilder: (context) => [
                    PopupMenuItem<String>(
                      value: 'history',

                      child: Row(
                        children: const [
                          Icon(Icons.history, size: 18, color: Color(0xff1BA3A1)),
                          SizedBox(width: 8),
                          Text(
                            'Deletion History',
                            style: TextStyle(fontFamily: 'Inter'),
                          ),
                        ],
                      ),
                    ),
                  ],
                  child: SvgPicture.asset(
                    'lib/assets/images/settingsnew.svg',
                    height: 40,
                    width: 40,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),
            _buildFilterUI(),
            const SizedBox(height: 10),
            Expanded(
              child: _buildDonationsList(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFilterUI() {
    return Padding(
      padding: const EdgeInsets.only(left: 8.0, right: 8, top: 8),
      child: SizedBox(
        height: 40,
        child: TextField(
          controller: _searchController,
          keyboardType: TextInputType.multiline,
          onChanged: (value) {
            _handleSearchChange(value);
          },
          textAlignVertical: TextAlignVertical.center,
          style: TextStyle(
            fontSize: 12,
            fontFamily: "Inter",
            fontWeight: FontWeight.w400,
            color: Theme.of(context).brightness == Brightness.dark ? Colors.white : Colors.black,
          ),
          decoration: InputDecoration(
            hintText: 'Search by Name, Month, or Amount',
            hintStyle: const TextStyle(
              fontSize: 12,
              fontFamily: "Inter",
              fontWeight: FontWeight.w400,
              color: Color(0xffA7A4AD),
            ),
            suffixIcon: _searchFilter.isNotEmpty
                ? IconButton(
                    icon: const Icon(Icons.clear,
                        color: Color(0xff1BA3A1), size: 16),
                    onPressed: () {
                      _searchController.clear();
                    },
                  )
                : Padding(
                    padding: const EdgeInsets.all(10.0),
                    child: SvgPicture.asset(
                      'lib/assets/images/search.svg',
                      height: 16,
                      width: 16,
                    ),
                  ),
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 12, vertical: 0),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(4.0),
              borderSide: const BorderSide(
                color: Color(0xff1BA3A1),
                width: 2.0,
              ),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(4.0),
              borderSide: const BorderSide(
                color: Color(0xff1BA3A1),
                width: 2.0,
              ),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(4.0),
              borderSide: const BorderSide(
                color: Color(0xff1BA3A1),
                width: 1.0,
              ),
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _refreshDonations() async {
    try {
      // Reset pagination state and refresh data
      setState(() {
        _isPaginating = false;
        _hasMore = true;
        _paginatedDonations.clear();
        _lastDocument = null;
        _initialLoading = true;
        _isSearching = false;
        _searchResults.clear();
        _searchFilter = '';
        _searchController.clear();
      });
      
      await _fetchInitialDonations();
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Donations refreshed successfully'),
            backgroundColor: Color(0xff1BA3A1),
            duration: Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to refresh: ${e.toString()}'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 3),
          ),
        );
      }
    }
  }

  Widget _buildDonationsList() {
    if (_initialLoading && !_isSearching) {
      return _DonationsShimmerList();
    }

    // Decide data source based on search state
    final List<Person> items;
    final bool showLoader;
    final bool showEndIndicator;
    if (_isSearching) {
      items = _searchResults;
      // Show loader only while actively fetching
      showLoader = _searchPaginating;
      showEndIndicator =
          items.isNotEmpty && !_searchHasMore && !_searchPaginating;
    } else {
      // Apply local filter when not searching (should be empty anyway)
      items = _paginatedDonations;
      showLoader = _isPaginating;
      showEndIndicator = items.isNotEmpty && !_hasMore && !_isPaginating;
    }

    // Empty state handling
    if (_isSearching && items.isEmpty) {
      // While search is still loading/priming, show shimmer; else show polished empty state
      if (_searchPaginating || _searchPriming) {
        return _DonationsShimmerList();
      }
      return RefreshIndicator(
        onRefresh: _refreshDonations,
        color: const Color(0xff1BA3A1),
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          child: SizedBox(
            height: MediaQuery.of(context).size.height * 0.6,
            child: _buildNoSearchResultsUI(query: _searchFilter),
          ),
        ),
      );
    }
    if (!_isSearching && items.isEmpty) {
      // No donations at all
      return RefreshIndicator(
        onRefresh: _refreshDonations,
        color: const Color(0xff1BA3A1),
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          child: SizedBox(
            height: MediaQuery.of(context).size.height * 0.6,
            child: _buildEmptyStateUI(),
          ),
        ),
      );
    }

    final extraCount = (showLoader || showEndIndicator) ? 1 : 0;
    return RefreshIndicator(
      onRefresh: _refreshDonations,
      color: const Color(0xff1BA3A1),
      child: ListView.builder(
        controller: _scrollController,
        physics: const AlwaysScrollableScrollPhysics(),
        itemCount: items.length + extraCount,
        itemBuilder: (context, index) {
          if (index == items.length) {
            if (showLoader) return _BottomShimmerLoader();
            if (showEndIndicator) return const _EndOfListIndicator();
          }
          final person = items[index];
          return Dismissible(
            key: Key(person.documentPath ??
                '${person.donorId}_${person.date}_${person.amount}'),
            direction: DismissDirection.endToStart,
            background: Container(
              alignment: Alignment.centerRight,
              padding: const EdgeInsets.only(right: 20.0),
              margin: const EdgeInsets.symmetric(vertical: 4.0, horizontal: 8.0),
              decoration: BoxDecoration(
                color: Colors.red,
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.delete,
                    color: Colors.white,
                    size: 24,
                  ),
                  SizedBox(height: 4),
                  Text(
                    'Delete',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      fontFamily: "Inter",
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
            confirmDismiss: (direction) async {
              return await _showDeleteConfirmation(context, person);
            },
            onDismissed: (direction) async {
              // Optimistically remove from the currently displayed list to satisfy Dismissible contract
              final removed = person;
              final isSearchingNow = _isSearching;
              // Identify which list is currently displayed and capture index for potential rollback
              int removedIndex;
              if (isSearchingNow) {
                removedIndex = _searchResults
                    .indexWhere((p) => p.documentPath == removed.documentPath);
                if (removedIndex != -1) {
                  setState(() {
                    _searchResults.removeAt(removedIndex);
                  });
                }
              } else {
                removedIndex = _paginatedDonations
                    .indexWhere((p) => p.documentPath == removed.documentPath);
                if (removedIndex != -1) {
                  setState(() {
                    _paginatedDonations.removeAt(removedIndex);
                  });
                }
              }

              final success = await _handleDonationDeletion(removed);
              if (!success && removedIndex != -1) {
                // Rollback on failure
                if (!mounted) return;
                setState(() {
                  if (isSearchingNow) {
                    _searchResults.insert(removedIndex, removed);
                  } else {
                    _paginatedDonations.insert(removedIndex, removed);
                  }
                });
              }
            },
            child: _DonationListTile(
              person: person,
              onTap: () => _showPaymentDetailsDialog(context, person),
            ),
          );
        },
      ),
    );
  }

  // Start a new server-assisted search
  Future<void> _startServerSearch() async {
    setState(() {
      _isSearching = true;
      _searchResults.clear();
      _searchHasMore = true;
      _lastSearchDocument = null;
      _searchPaginating = false;
      _stagedSearchResults.clear();
      _searchPriming = true;
    });
    await _fetchMoreSearchResults(initial: true);
    // Auto-fill more pages if needed
    await _ensureSearchFilled();
  }

  // Fetch a page for search mode
  Future<void> _fetchMoreSearchResults({bool initial = false}) async {
    if (!_searchHasMore || _searchPaginating) return;
    setState(() {
      _searchPaginating = true;
    });

    try {
      Query query = FirebaseFirestore.instance
          .collectionGroup('paymentStatus')
          .where('status', isEqualTo: 'paid')
          .orderBy('timestamp', descending: true)
          .limit(_pageSize);

      if (_lastSearchDocument != null) {
        query = query.startAfterDocument(_lastSearchDocument!);
      }

      final snapshot = await query.get();
      if (snapshot.docs.isEmpty) {
        if (!mounted) return;
        setState(() {
          _searchHasMore = false;
          _searchPaginating = false;
        });
        return;
      }

      // Prefetch donor docs for this page
      final Set<String> donorIds = {
        for (final d in snapshot.docs)
          if (d.reference.parent.parent?.id != null)
            d.reference.parent.parent!.id
      };

      // Fetch donors in batches of 10 to respect whereIn limit
      final donorIdList = donorIds.toList();
      final Map<String, Map<String, dynamic>> donorCache = {};
      for (var i = 0; i < donorIdList.length; i += 10) {
        final chunk =
            donorIdList.sublist(i, (i + 10).clamp(0, donorIdList.length));
        if (chunk.isEmpty) continue;
        final donorsSnapshot = await FirebaseFirestore.instance
            .collection('donors')
            .where(FieldPath.documentId, whereIn: chunk)
            .get();
        for (final d in donorsSnapshot.docs) {
          donorCache[d.id] = d.data();
        }
      }

      final List<Person> pagePeople = [];
      for (final doc in snapshot.docs) {
        final data = doc.data() as Map<String, dynamic>?;
        if (data == null) continue;
        
        // Skip hidden entries
        if (data['hideFromHistory'] == true) continue;
        
        final donorId = doc.reference.parent.parent?.id ?? data['donorId'] as String?;
        if (donorId == null || donorId.isEmpty) continue;
        final donorData = donorCache[donorId] ?? {};

        final donorName = donorData['name'] ?? data['name'] ?? 'Unknown Donor';
        final donorImageUrl = donorData['imageUrl'] ?? data['imageUrl'] ?? '';
        final donorAddress = donorData['address']?.toString() ?? 'Unknown';
        
        final monthsList = data['monthsList'] != null ? List<String>.from(data['monthsList']) : null;
        final amount = (data['totalDonationAmount'] ?? data['amount'] ?? 0);

        final person = Person(
          name: donorName.toString(),
          house: donorAddress.toString(),
          photoUrl: donorImageUrl.toString(),
          amount: _parseAmount(amount).toDouble(),
          date: _formatTimestamp(data['timestamp'] ?? data['paidDate'] ?? data['date']),
          month: data['month']?.toString() ?? 'Unknown',
          year: data['year']?.toString() ?? 'Unknown',
          method: data['method']?.toString() ?? data['paymentMethod']?.toString() ?? 'Unknown',
          status: data['status']?.toString() ?? 'Paid',
          donorId: donorId,
          documentPath: doc.reference.path,
          imageUrl: donorImageUrl.toString(),
          monthsList: monthsList,
          timestamp: (data['timestamp'] is Timestamp)
              ? (data['timestamp'] as Timestamp).toDate()
              : null,
        );

        if (_matchesSearch(person, _searchFilter)) {
          pagePeople.add(person);
        }
      }

      if (!mounted) return;
      setState(() {
        // Stage results first
        _stagedSearchResults.addAll(pagePeople);
        _lastSearchDocument = snapshot.docs.last;
        _searchPaginating = false;
        if (snapshot.docs.length < _pageSize) {
          _searchHasMore = false;
        }

        // Commit to UI when threshold reached or no more pages
        final shouldCommit = !_searchHasMore ||
            _stagedSearchResults.length >= _searchBatchThreshold;
        if (shouldCommit) {
          _searchResults.addAll(_stagedSearchResults);
          _stagedSearchResults.clear();
          _searchPriming = false;
        }
      });
      // If still searching and not enough items to fill, continue auto-fetch
      await _ensureSearchFilled();
    } catch (e) {
      if (mounted) {
        setState(() {
          _searchPaginating = false;
          _searchHasMore = false;
        });
      }
      // Optionally log error
      debugPrint('Search fetch error: $e');
    }
  }

  // Load all remaining pages for the current search query
  Future<void> _ensureSearchFilled() async {
    while (mounted && _isSearching && _searchHasMore) {
      await _fetchMoreSearchResults();
    }
  }

  bool _matchesSearch(Person person, String q) {
    if (q.isEmpty) return true;
    final nameMatch = person.name.toLowerCase().contains(q);
    final houseMatch = person.house.toLowerCase().contains(q);
    final donorIdMatch = (person.donorId ?? '').toLowerCase().contains(q);
    final monthMatch = person.month?.toLowerCase().contains(q) ?? false;
    final yearMatch = person.year?.toLowerCase().contains(q) ?? false;
    final methodMatch = person.method?.toLowerCase().contains(q) ?? false;
    final monthsListMatch = person.monthsList?.any((m) => m.toLowerCase().contains(q)) ?? false;
    final amountMatch = person.amount.toString().contains(q) ||
        person.amount.toStringAsFixed(0).contains(q);
    return nameMatch ||
        houseMatch ||
        donorIdMatch ||
        monthMatch ||
        yearMatch ||
        methodMatch ||
        monthsListMatch ||
        amountMatch;
  }

  String _getErrorMessage(dynamic error) {
    if (error.toString().contains('permission-denied')) {
      return 'Permission denied. Please check your access rights.';
    } else if (error.toString().contains('unavailable')) {
      return 'Service temporarily unavailable. Please try again.';
    } else if (error.toString().contains('deadline-exceeded')) {
      return 'Request timeout. Please check your internet connection.';
    } else if (error.toString().contains('not-found')) {
      return 'Collection not found. Please contact support.';
    } else {
      return 'An unexpected error occurred. Please try again.';
    }
  }

  Widget _buildImprovedShimmerLoading() {
    return AllDonationsShimmer();
  }

  Widget _buildEmptyStateUI() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 120,
            height: 120,
            decoration: BoxDecoration(
              color: const Color(0xff1BA3A1).withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.volunteer_activism_outlined,
              size: 60,
              color: Color(0xff1BA3A1),
            ),
          ),
          const SizedBox(height: 24),
          const Text(
            'No Donations Found',
            style: TextStyle(
              fontFamily: "Inter",
              fontSize: 20,
              fontWeight: FontWeight.w600,
              color: Color(0xff1BA3A1),
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'There are no paid donations to display at the moment.',
            style: TextStyle(
              fontFamily: "Inter",
              fontSize: 14,
              color: Colors.grey,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: () {
              setState(() {
                _errorMessage = null;
                _isLoading = false;
                _processedDonations = [];
                _latestSnapshot = null;
                _hasInitialData = false;
              });
            },
            icon: const Icon(Icons.refresh, size: 18),
            label: const Text(
              'Refresh',
              style: TextStyle(
                fontFamily: "Inter",
                fontWeight: FontWeight.w600,
              ),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xff1BA3A1),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNoSearchResultsUI({String? query}) {
    final q = (query ?? '').trim();
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Container(
              width: 110,
              height: 110,
              decoration: BoxDecoration(
                color: const Color(0xff1BA3A1).withOpacity(0.08),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.search_off_rounded,
                size: 56,
                color: Colors.grey[500],
              ),
            ),
            const SizedBox(height: 20),
            Text(
              'No results found',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: Colors.grey[800],
                fontFamily: 'Inter',
              ),
            ),
            const SizedBox(height: 8),
            if (q.isNotEmpty)
              RichText(
                textAlign: TextAlign.center,
                text: TextSpan(
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey[700],
                    fontFamily: 'Inter',
                  ),
                  children: [
                    const TextSpan(text: 'We couldn\'t find any donations matching '),
                    TextSpan(
                      text: '“$q”',
                      style: const TextStyle(
                        fontWeight: FontWeight.w600,
                        color: Color(0xff1BA3A1),
                      ),
                    ),
                    const TextSpan(text: '.'),
                  ],
                ),
              ),

          ],
        ),
      ),
    );
  }

  Widget _buildErrorUI(String error) {
    IconData errorIcon;
    Color errorColor;
    String actionText;

    // Customize error display based on error type
    if (error.contains('Permission denied')) {
      errorIcon = Icons.lock_outline;
      errorColor = Colors.orange;
      actionText = 'Check Permissions';
    } else if (error.contains('unavailable') || error.contains('timeout')) {
      errorIcon = Icons.wifi_off_outlined;
      errorColor = Colors.blue;
      actionText = 'Retry Connection';
    } else {
      errorIcon = Icons.error_outline;
      errorColor = Colors.red;
      actionText = 'Try Again';
    }

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 100,
              height: 100,
              decoration: BoxDecoration(
                color: errorColor.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(
                errorIcon,
                color: errorColor,
                size: 48,
              ),
            ),
            const SizedBox(height: 24),
            Text(
              'Oops! Something went wrong',
              style: TextStyle(
                fontFamily: "Inter",
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: errorColor,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 12),
            Text(
              error,
              style: const TextStyle(
                fontFamily: "Inter",
                fontSize: 14,
                color: Colors.grey,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                ElevatedButton.icon(
                  onPressed: () {
                    setState(() {
                      _errorMessage = null;
                      _isLoading = false;
                      _processedDonations = [];
                      _latestSnapshot = null;
                      _hasInitialData = false;
                    });
                  },
                  icon: const Icon(Icons.refresh, size: 18),
                  label: Text(
                    actionText,
                    style: const TextStyle(
                      fontFamily: "Inter",
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xff1BA3A1),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    padding: const EdgeInsets.symmetric(
                        horizontal: 20, vertical: 12),
                  ),
                ),
                const SizedBox(width: 12),
                TextButton.icon(
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(Icons.arrow_back, size: 18),
                  label: const Text(
                    'Go Back',
                    style: TextStyle(
                      fontFamily: "Inter",
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  style: TextButton.styleFrom(
                    foregroundColor: Colors.grey[600],
                    padding: const EdgeInsets.symmetric(
                        horizontal: 20, vertical: 12),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Future<bool> _handleDonationDeletion(Person person) async {
    try {
      if (person.documentPath == null) return false;

      // Store the deleted item in history collection before deleting
      await FirebaseFirestore.instance.collection('deleted_donations').add({
        'name': person.name,
        'house': person.house,
        'photoUrl': person.photoUrl,
        'imageUrl': person.imageUrl,
        'amount': person.amount,
        'date': person.date,
        'month': person.month,
        'year': person.year,
        'monthsList': person.monthsList,
        'totalDonationAmount': person.totalDonationAmount,
        'method': person.method,
        'status': person.status,
        'donorId': person.donorId,
        'originalDocumentPath': person.documentPath,
        'deletedAt': FieldValue.serverTimestamp(),
        'timestamp': person.timestamp,
      });

      // Delete from Firestore
      final batch = FirebaseFirestore.instance.batch();
      
      // 1. Delete the global donation record if donationId is available
      if (person.donationId != null && person.donationId!.isNotEmpty) {
        final globalDonationRef = FirebaseFirestore.instance
            .collection('donations')
            .doc(person.donationId);
        batch.delete(globalDonationRef);
        debugPrint('Adding global donation deletion to batch: ${globalDonationRef.path}');
      }
      
      // 2. Reset individual month statuses to 'unpaid' in the paymentStatus collection
      if (person.donorId != null) {
        final donorRef = FirebaseFirestore.instance.collection('donors').doc(person.donorId);
        
        List<String> monthsToReset = [];
        if (person.monthsList != null && person.monthsList!.isNotEmpty) {
          monthsToReset = person.monthsList!;
        } else if (person.month != null) {
          monthsToReset = [person.month!];
        }
        
        for (final month in monthsToReset) {
          final monthYearKey = '$month-${person.year}';
          final statusRef = donorRef.collection('paymentStatus').doc(monthYearKey);
          
          // Reset status to unpaid. This also removes it from the "paid" list in this page
          // as we query status == 'paid'.
          batch.update(statusRef, {
            'status': 'unpaid',
            'amount': 0,
            'paymentMethod': '',
            'timestamp': FieldValue.serverTimestamp(),
            // Important: also clear the link to the deleted global donation
            'donationId': FieldValue.delete(),
          });
          debugPrint('Adding payment status reset to batch: ${statusRef.path}');
        }
      }
      
      await batch.commit();

      // Also delete from local cache so UI updates immediately
      await LocalDatabaseService()
          .deleteDonationByDocumentPath(person.documentPath!);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.check_circle, color: Colors.white, size: 20),
                const SizedBox(width: 8),
                const Text(
                  'Donation deleted successfully',
                  style: TextStyle(fontFamily: "Inter"),
                ),
              ],
            ),
            backgroundColor: Colors.green,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
        );
      }
      return true;
    } catch (e) {
      if (mounted) {
        print('Failed to delete donation. Please try again.$e');
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children:  [
                Icon(Icons.error, color: Colors.white, size: 20),
                SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Failed to delete donation. Please try again.$e',
                    style: TextStyle(fontFamily: "Inter"),
                  ),
                ),
              ],
            ),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
        );
      }
      return false;
    }
  }

  String _formatTimestamp(dynamic timestamp) {
    if (timestamp == null) return "N/A";
    try {
      DateTime? date;
      if (timestamp is Timestamp) {
        date = timestamp.toDate();
      } else if (timestamp is DateTime) {
        date = timestamp;
      } else if (timestamp is String) {
        if (timestamp.contains(',') || timestamp.length > 12) {
          return timestamp; // Already formatted
        }
        date = DateTime.tryParse(timestamp);
      }
      
      if (date != null) {
        return DateFormat('dd MMM yyyy, hh:mm a').format(date);
      }
      return timestamp.toString();
    } catch (e) {
      return "N/A";
    }
  }

  void _showPaymentDetailsDialog(BuildContext context, Person person) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cardBg = isDark ? const Color(0xFF1E1E1E) : Colors.white;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (sheetCtx) {
        return Container(
          decoration: BoxDecoration(
            color: cardBg,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
          ),
          child: SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Drag handle
                  Center(
                    child: Container(
                      width: 40,
                      height: 4,
                      decoration: BoxDecoration(
                        color: isDark ? Colors.white24 : Colors.grey.shade300,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),

                  // Header: avatar + name + amount + badge
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: const Color(0xff1BA3A1).withValues(alpha: 0.08),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      children: [
                        CircleAvatar(
                          radius: 28,
                          backgroundImage: (person.imageUrl != null &&
                                  person.imageUrl!.isNotEmpty)
                              ? NetworkImage(person.imageUrl!)
                              : null,
                          backgroundColor: const Color(0xff1BA3A1),
                          child: (person.imageUrl == null ||
                                  person.imageUrl!.isEmpty)
                              ? Text(
                                  person.name.isNotEmpty
                                      ? person.name[0].toUpperCase()
                                      : '',
                                  style: const TextStyle(
                                    fontSize: 22,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white,
                                  ),
                                )
                              : null,
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                person.name,
                                style: const TextStyle(
                                  fontFamily: 'Inter',
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                  color: Color(0xff1BA3A1),
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                '₹${person.amount.toStringAsFixed(0)}',
                                style: const TextStyle(
                                  fontFamily: 'Inter',
                                  fontWeight: FontWeight.w800,
                                  fontSize: 20,
                                  color: Color(0xff1BA3A1),
                                ),
                              ),
                            ],
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 10, vertical: 5),
                          decoration: BoxDecoration(
                            color: const Color(0xff1BA3A1),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            person.status ?? 'Paid',
                            style: const TextStyle(
                              color: Colors.white,
                              fontFamily: 'Inter',
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 20),
                  Divider(height: 1, color: isDark ? Colors.white12 : const Color(0xffeeeeee)),
                  const SizedBox(height: 20),

                  _detailItem(Icons.calendar_today, 'Transaction Date', person.date ?? 'N/A'),
                  _detailItem(Icons.payment, 'Payment Method', person.method ?? 'N/A'),
                  _detailItem(
                    Icons.date_range,
                    'Month',
                    (person.monthsList != null && person.monthsList!.isNotEmpty)
                        ? MonthFormatter.formatMonthLong(person.monthsList!, person.year ?? '', includeYear: false)
                        : (person.month ?? 'N/A'),
                  ),
                  _detailItem(Icons.calendar_view_month, 'Payment Year', person.year ?? 'N/A'),

                  const SizedBox(height: 12),

                  // Buttons
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: () async {
                            try {
                              final imagePath = await _generateAndSaveImage(person);
                              await Share.shareXFiles(
                                [XFile(imagePath)],
                                text: 'Donation Receipt for ${person.name}',
                              );
                            } catch (e) {
                              if (mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text('Failed to generate receipt: $e'),
                                    backgroundColor: Colors.red,
                                  ),
                                );
                              }
                            }
                          },
                          icon: const Icon(Icons.share_rounded, size: 18),
                          label: const Text(
                            'Share Receipt',
                            style: TextStyle(fontFamily: 'Inter', fontWeight: FontWeight.w600),
                          ),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: const Color(0xff1BA3A1),
                            side: const BorderSide(color: Color(0xff1BA3A1), width: 1.5),
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10)),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: ElevatedButton(
                          onPressed: () => Navigator.of(sheetCtx).pop(),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xff1BA3A1),
                            foregroundColor: Colors.white,
                            elevation: 0,
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10)),
                          ),
                          child: const Text(
                            'Close',
                            style: TextStyle(
                                fontFamily: 'Inter',
                                fontWeight: FontWeight.bold,
                                fontSize: 15),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _detailItem(IconData icon, String label, String? value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 20),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: const Color(0xff1BA3A1).withOpacity(0.08),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, size: 20, color: const Color(0xff1BA3A1)),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label.toUpperCase(),
                  style:  TextStyle(
                    fontFamily: "Inter",
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 0.8,
                    color: Theme.of(context).brightness == Brightness.dark ? Colors.grey[400] : Colors.black45,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  value ?? 'N/A',
                  style:  TextStyle(
                    fontFamily: "Inter",
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: Theme.of(context).brightness == Brightness.dark ? Colors.white : const Color(0xff2d2d2d),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Future<String> _generateAndSaveImage(Person person) async {
    // Create a GlobalKey to capture the widget
    final GlobalKey receiptKey = GlobalKey();

    // Fetch donor address from Firestore
    String donorAddress = '';
    try {
      final donorDoc = await FirebaseFirestore.instance
          .collection('donors')
          .doc(person.donorId)
          .get();

      if (donorDoc.exists) {
        final donorData = donorDoc.data() as Map<String, dynamic>;
        donorAddress = donorData['address'] ?? '';
      }
    } catch (e) {
      print('Error fetching donor address: $e');
    }

    // Show the receipt in an overlay to render it
    final overlay = Overlay.of(context);
    late OverlayEntry overlayEntry;

    overlayEntry = OverlayEntry(
      builder: (context) => Positioned(
        left: -10000, // Position off-screen
        top: -10000,
        child: Material(
          color: Colors.transparent,
          child: _buildReceiptWidget(person, receiptKey, donorAddress),
        ),
      ),
    );

    overlay.insert(overlayEntry);

    // Wait for the widget to render
    await Future.delayed(const Duration(milliseconds: 100));

    try {
      // Capture the widget as an image
      final boundary = receiptKey.currentContext!.findRenderObject()
          as RenderRepaintBoundary;
      final image = await boundary.toImage(pixelRatio: 3.0);
      final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
      final bytes = byteData!.buffer.asUint8List();

      // Save image to temporary directory
      final tempDir = await getTemporaryDirectory();
      final imageFile = File(
          '${tempDir.path}/PMJ_Receipt_${person.donorId}_${DateTime.now().millisecondsSinceEpoch}.png');
      await imageFile.writeAsBytes(bytes);

      return imageFile.path;
    } finally {
      // Remove the overlay entry
      overlayEntry.remove();
    }
  }

  Widget _buildReceiptWidget(
      Person person, GlobalKey key, String donorAddress) {
    return RepaintBoundary(
      key: key,
      child: Center(
        child: Container(
          constraints: const BoxConstraints(maxWidth: 420),
          decoration: BoxDecoration(
            color: Colors.white,
            // No border radius for sharp edges
            boxShadow: [
              BoxShadow(
                color: Colors.grey.withOpacity(0.15),
                spreadRadius: 1,
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // Green Header Section (taller, no border radius)
              Container(
                width: double.infinity,
                height: 130,
                color: const Color(0xFF41c057),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      'PMJ Monthly Donation Receipt',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 0.2,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 4),
                    // Move receipt number closer to heading
                    Text(
                      'Receipt No: ${person.donorId}',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 10,
                        fontWeight: FontWeight.w400,
                        letterSpacing: 0.1,
                      ),
                    ),
                  ],
                ),
              ),

              // Overlapping Checkmark Icon (bigger)
              Transform.translate(
                offset: const Offset(0, -32),
                child: Container(
                  width: 80,
                  height: 80,
                  decoration: BoxDecoration(
                    color: const Color(0xFFE0E0E0),
                    borderRadius: BorderRadius.circular(22),
                    border: Border.all(color: Colors.white, width: 4),
                  ),
                  child: const Icon(
                    Icons.check,
                    color: Color(0xFF41c057),
                    size: 52,
                  ),
                ),
              ),

              // Payment Received Text
              Transform.translate(
                offset: const Offset(0, -16),
                child: const Text(
                  'Payment Received',
                  style: TextStyle(
                    color: Color(0xFF41c057),
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 0.1,
                  ),
                ),
              ),

              // Divider Line
              Container(
                margin:
                    const EdgeInsets.symmetric(horizontal: 32, vertical: 10),
                height: 1,
                color: Colors.grey[300],
              ),

              // Receipt Details (no address)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 28),
                child: Column(
                  children: [
                    _buildReceiptRow('Date:', person.date),
                    const SizedBox(height: 8),
                    _buildReceiptRow('Name:', person.name),
                    const SizedBox(height: 8),
                    _buildReceiptRow(
                        'Month:',
                        person.monthsList != null && person.monthsList!.isNotEmpty
                            ? MonthFormatter.formatMonthLong(person.monthsList!, person.year ?? '')
                            : (person.month != null && person.year != null
                                ? '${person.month} ${person.year}'
                                : 'N/A')),
                    const SizedBox(height: 8),
                    _buildReceiptRow(
                        'Amount', '₹${person.amount.toStringAsFixed(0)}/-',
                        isAmount: true),
                    const SizedBox(height: 8),
                    _buildReceiptRow('Payment Method:', person.method),
                    const SizedBox(height: 18),
                  ],
                ),
              ),

              // Amount in Words Container (column, start)
              Container(
                width: double.infinity,
                margin: const EdgeInsets.symmetric(horizontal: 28),
                padding:
                    const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                decoration: BoxDecoration(
                  color: const Color(0xFFeafbe7),
                  borderRadius: BorderRadius.zero, // No curve
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Amount in words:',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w400,
                        color: Colors.black87,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      _numberToWords(person.amount),
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                        fontStyle: FontStyle.italic,
                        color: Colors.black87,
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 22),

              // Footer
              Text(
                'Thank you for your donation!',
                style: TextStyle(
                  color: const Color(0xFF41c057),
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  fontStyle: FontStyle.italic,
                  letterSpacing: 0.1,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                'Perakkool Muslim Jama-ath Committee',
                style: TextStyle(
                  color: Colors.black,
                  fontSize: 8,
                  fontWeight: FontWeight.w400,
                  letterSpacing: 0.2,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 12),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildReceiptRow(String label, String? value,
      {bool isAmount = false}) {
    final displayValue = value ?? 'N/A';
    // Receipt is always light-themed (printed on white background).
    // Hardcode dark text colors so they stay visible in dark mode.
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w500,
            color: Colors.black87,
          ),
        ),
        Flexible(
          child: Text(
            displayValue,
            style: TextStyle(
              fontSize: 13,
              fontWeight: isAmount ? FontWeight.bold : FontWeight.w500,
              color: isAmount ? const Color(0xFF41c057) : Colors.black87,
            ),
            textAlign: TextAlign.right,
            overflow: TextOverflow.ellipsis,
            maxLines: 2,
          ),
        ),
      ],
    );
  }

  Future<bool> _showDeleteConfirmation(
      BuildContext context, Person person) async {
    return await showDialog<bool>(
          context: context,
          barrierDismissible: false,
          builder: (BuildContext dialogContext) {
            return AlertDialog(
              backgroundColor: Theme.of(context).cardColor,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              contentPadding: const EdgeInsets.fromLTRB(24, 20, 24, 0),
              actionsPadding: const EdgeInsets.fromLTRB(24, 16, 24, 20),
              title: const Text(
                'Delete Donation?',
                textAlign: TextAlign.start,
                style: TextStyle(
                  fontFamily: "Inter",
                  fontSize: 20,
                  fontWeight: FontWeight.w600,
                  height: 1.3,
                ),
              ),
              content: Text(
                'Are you sure you want to delete this donation of ₹${person.amount} from ${person.name}?\n\nThis action cannot be undone.',
                textAlign: TextAlign.start,
                style: TextStyle(
                  fontFamily: "Inter",
                  fontWeight: FontWeight.w400,
                  fontSize: 14,
                  height: 1.5,
                ),
              ),
              actions: [
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          side: const BorderSide(
                            color: Color(0xFFE0E0E0),
                            width: 1.5,
                          ),
                          foregroundColor: const Color(0xFF616161),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        onPressed: () {
                          Navigator.of(dialogContext).pop(false);
                        },
                        child: const Text(
                          'Cancel',
                          style: TextStyle(
                            fontFamily: "Inter",
                            fontWeight: FontWeight.w600,
                            fontSize: 14,
                            letterSpacing: 0.2,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          backgroundColor: const Color(0xFFD32F2F),
                          foregroundColor: Colors.white,
                          elevation: 0,
                          shadowColor: Colors.transparent,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        onPressed: () {
                          Navigator.of(dialogContext).pop(true);
                        },
                        child: const Text(
                          'Delete',
                          style: TextStyle(
                            fontFamily: "Inter",
                            fontWeight: FontWeight.w600,
                            fontSize: 14,
                            letterSpacing: 0.2,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            );
          },
        ) ??
        false;
  }

  String _numberToWords(dynamic number) {
    if (number == null) return 'Zero Rupees Only';

    // Handle both int and double
    final isDouble = number is double;
    int wholeNumber = isDouble ? number.floor() : number as int;
    int paise = 0;

    if (isDouble) {
      // Extract paise (2 decimal places)
      paise = ((number - wholeNumber) * 100).round();
    }

    final units = [
      '',
      'One',
      'Two',
      'Three',
      'Four',
      'Five',
      'Six',
      'Seven',
      'Eight',
      'Nine'
    ];
    final teens = [
      'Ten',
      'Eleven',
      'Twelve',
      'Thirteen',
      'Fourteen',
      'Fifteen',
      'Sixteen',
      'Seventeen',
      'Eighteen',
      'Nineteen'
    ];
    final tens = [
      '',
      '',
      'Twenty',
      'Thirty',
      'Forty',
      'Fifty',
      'Sixty',
      'Seventy',
      'Eighty',
      'Ninety'
    ];

    String convertLessThanOneThousand(int n) {
      if (n == 0) return '';
      if (n < 10) return units[n];
      if (n < 20) return teens[n - 10];
      if (n < 100) {
        return '${tens[n ~/ 10]}${n % 10 != 0 ? ' ${units[n % 10]}' : ''}';
      }
      return '${units[n ~/ 100]} Hundred${n % 100 != 0 ? ' and ${convertLessThanOneThousand(n % 100)}' : ''}';
    }

    String result = '';
    int num = wholeNumber;

    if (num == 0) {
      result = 'Zero';
    } else {
      if (num >= 10000000) {
        result += '${convertLessThanOneThousand(num ~/ 10000000)} Crore ';
        num %= 10000000;
      }
      if (num >= 100000) {
        result += '${convertLessThanOneThousand(num ~/ 100000)} Lakh ';
        num %= 100000;
      }
      if (num >= 1000) {
        result += '${convertLessThanOneThousand(num ~/ 1000)} Thousand ';
        num %= 1000;
      }
      if (num > 0) {
        result += convertLessThanOneThousand(num);
      }
    }

    // Add paise if exists
    String paiseText = '';
    if (paise > 0) {
      paiseText =
          ' and ${paise < 10 ? 'Zero ' : ''}${convertLessThanOneThousand(paise)} Paise';
    }

    return '${result.trim()} Rupees$paiseText Only';
  }

  int _parseAmount(dynamic amount) {
    if (amount == null) return 0;
    if (amount is int) return amount;
    if (amount is double) return amount.toInt();
    if (amount is String) {
      try {
        return int.parse(amount);
      } catch (e) {
        try {
          return double.parse(amount).toInt();
        } catch (e) {
          return 0;
        }
      }
    }
    return 0;
  }
}

class _EndOfListIndicator extends StatelessWidget {
  const _EndOfListIndicator();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 16.0),
      child: Center(
        child: Text(
          'All results loaded',
          style: TextStyle(
            fontSize: 12,
            color: Colors.grey[600],
          ),
        ),
      ),
    );
  }
}

// Shimmer for initial loading
class _DonationsShimmerList extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return AllDonationsShimmer();
  }
}

// Shimmer for bottom loading
class _BottomShimmerLoader extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return BottomShimmerLoader();
  }
}

// Shimmer for bottom loading
class _AvatarWithCache extends StatelessWidget {
  final Person person;

  const _AvatarWithCache({required this.person});

  @override
  Widget build(BuildContext context) {
    final effectiveUrl =
        (person.photoUrl != null && person.photoUrl!.isNotEmpty)
            ? person.photoUrl!
            : (person.imageUrl ?? '');

    if (effectiveUrl.isEmpty) {
      return CircleAvatar(
        radius: 20,
        backgroundColor: const Color(0xff1BA3A1),
        child: Text(
          person.name.isNotEmpty ? person.name[0].toUpperCase() : '',
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
      );
    }

    return FutureBuilder<ImageProvider?>(
      future: ImageCacheService().getImageProvider(effectiveUrl),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Shimmer.fromColors(
            baseColor: Colors.grey[300]!,
            highlightColor: Colors.grey[100]!,
            child: Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle,
                border: Border.all(color: Colors.grey[300]!, width: 2),
              ),
            ),
          );
        }

        if (snapshot.hasData && snapshot.data != null) {
          return ClipOval(
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 250),
              child: Image(
                key: ValueKey(effectiveUrl),
                image: snapshot.data!,
                width: 40,
                height: 40,
                fit: BoxFit.cover,
              ),
            ),
          );
        }

        // Fallback to initials
        return CircleAvatar(
          radius: 20,
          backgroundColor: const Color(0xff1BA3A1),
          child: Text(
            person.name.isNotEmpty ? person.name[0].toUpperCase() : '',
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
        );
      },
    );
  }
}

class _DonationListTile extends StatelessWidget {
  final Person person;
  final VoidCallback? onTap;

  const _DonationListTile({required this.person, this.onTap});

  @override
  Widget build(BuildContext context) {
    return ListTile(
      onTap: onTap,
      leading: _AvatarWithCache(person: person),
      title: Text(
        person.name,
        style: const TextStyle(
          fontSize: 14,
          fontFamily: "Inter",
          fontWeight: FontWeight.w600,
        ),
      ),
      subtitle: Text(
        "${person.date} • ${person.monthsList != null && person.monthsList!.isNotEmpty ? MonthFormatter.formatMonthList(person.monthsList!, person.year ?? '') : '${person.month} ${person.year}'}",
        style: const TextStyle(
          fontSize: 10,
          fontFamily: "Inter",
          fontWeight: FontWeight.w400,
          color: Color(0xff817D8A),
        ),
      ),
      trailing: Padding(
        padding: const EdgeInsets.only(bottom: 1.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.end,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              "₹${person.amount.toStringAsFixed(0)}",
              style: const TextStyle(
                fontSize: 16,
                fontFamily: "Inter",
                fontWeight: FontWeight.w600,
              ),
            ),
            if (person.method != null && person.method!.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(top: 4.0),
                child: Text(
                  person.method!,
                  style: const TextStyle(
                    fontSize: 10,
                    fontFamily: "Inter",
                    fontWeight: FontWeight.w400,
                    color: Color(0xff817D8A),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
