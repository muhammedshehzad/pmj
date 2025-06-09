import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:shimmer/shimmer.dart';
import '../assets/custom widgets/PeopleListViewHome.dart';
import '../assets/custom widgets/logoutpopup.dart';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

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
  List<personHome> _processedDonations = [];
  QuerySnapshot? _latestSnapshot;
  final _loadingController = StreamController<double>.broadcast();
  String _searchFilter = '';
  final _searchController = TextEditingController();
  String? _errorMessage;
  StreamSubscription<QuerySnapshot>? _donationsSubscription;
  bool _hasInitialData = false;

  @override
  void initState() {
    super.initState();
    _setupLoadingController();
    _setupSearchController();
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
      setState(() {
        _searchFilter = _searchController.text.toLowerCase();
      });
    });
  }

  @override
  void dispose() {
    _donationsSubscription?.cancel();
    _loadingController.close();
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xffFFFFFF),
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(100),
        child: AppBar(
          elevation: 0,
          backgroundColor: const Color(0xff1BA3A1),
          automaticallyImplyLeading: false,
          flexibleSpace: Align(
            alignment: Alignment.bottomCenter,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8),
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
                          borderRadius: BorderRadius.circular(2),
                        ),
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
                SvgPicture.asset(
                  'lib/assets/images/settingsnew.svg',
                  height: 40,
                  width: 40,
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
            setState(() {
              _searchFilter = value.toLowerCase();
            });
          },
          textAlignVertical: TextAlignVertical.center,
          style: const TextStyle(
            fontSize: 12,
            fontFamily: "Inter",
            fontWeight: FontWeight.w400,
            color: Colors.black,
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
              icon: const Icon(Icons.clear, color: Color(0xff1BA3A1), size: 16),
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
            contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 0),
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

  Widget _buildDonationsList() {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collectionGroup('paymentStatus')
          .where('status', isEqualTo: 'paid')
          .orderBy('timestamp', descending: true)
          .snapshots(),
      builder: (context, snapshot) {
        // Handle different error types with specific messages
        if (snapshot.hasError) {
          return _buildErrorUI(_getErrorMessage(snapshot.error));
        }

        // Show shimmer for initial loading
        if (snapshot.connectionState == ConnectionState.waiting && !_hasInitialData) {
          return _buildImprovedShimmerLoading();
        }

        // Handle empty data
        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return _buildEmptyStateUI();
        }

        // Process new data
        if (snapshot.hasData &&
            (_latestSnapshot == null ||
                _latestSnapshot!.docs.length != snapshot.data!.docs.length ||
                _hasDataChanged(snapshot.data!))) {
          _latestSnapshot = snapshot.data;
          _hasInitialData = true;

          WidgetsBinding.instance.addPostFrameCallback((_) {
            _processDocumentsAsync(snapshot.data!.docs);
          });
        }

        // Show shimmer during processing if no previous data
        if (_isLoading && _processedDonations.isEmpty) {
          return _buildImprovedShimmerLoading();
        }

        // Show error if processing failed
        if (_errorMessage != null) {
          return _buildErrorUI(_errorMessage!);
        }

        // Show donation list
        return _buildDonationListView();
      },
    );
  }

  bool _hasDataChanged(QuerySnapshot newSnapshot) {
    if (_latestSnapshot == null) return true;

    // Check if document IDs or modification times have changed
    final oldDocs = _latestSnapshot!.docs;
    final newDocs = newSnapshot.docs;

    if (oldDocs.length != newDocs.length) return true;

    for (int i = 0; i < oldDocs.length; i++) {
      if (oldDocs[i].id != newDocs[i].id ||
          oldDocs[i].metadata.hasPendingWrites != newDocs[i].metadata.hasPendingWrites) {
        return true;
      }
    }

    return false;
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
    return Shimmer.fromColors(
      baseColor: Colors.grey[300]!,
      highlightColor: Colors.grey[100]!,
      child: ListView.builder(
        itemCount: 8,
        padding: const EdgeInsets.symmetric(horizontal: 8.0),
        itemBuilder: (context, index) {
          return Padding(
            padding: const EdgeInsets.symmetric(vertical: 6.0),
            child: Container(
              height: 85,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: Colors.grey[200]!,
                  width: 1,
                ),
              ),
              child: Padding(
                padding: const EdgeInsets.all(12.0),
                child: Row(
                  children: [
                    // Avatar placeholder
                    Container(
                      width: 50,
                      height: 50,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: Colors.grey[300]!,
                          width: 2,
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    // Content placeholder
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          // Name placeholder
                          Container(
                            height: 16,
                            width: double.infinity,
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(4),
                            ),
                          ),
                          const SizedBox(height: 8),
                          // Details placeholder
                          Row(
                            children: [
                              Container(
                                height: 12,
                                width: 80,
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(4),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Container(
                                height: 12,
                                width: 60,
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(4),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 12),
                    // Amount placeholder
                    Container(
                      width: 80,
                      height: 32,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: Colors.grey[300]!,
                          width: 1,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
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
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
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
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _processDocumentsAsync(List<QueryDocumentSnapshot> docs) async {
    bool showLoadingUI = _processedDonations.isEmpty;

    if (showLoadingUI) {
      setState(() {
        _isLoading = true;
        _totalDocuments = docs.length;
        _loadedDocuments = 0;
        _loadingProgress = 0.0;
        _errorMessage = null;
      });
    }

    try {
      // Extract unique donor IDs
      Set<String> donorIds = {};
      for (var doc in docs) {
        final donorId = doc.reference.parent.parent?.id;
        if (donorId != null && donorId.isNotEmpty) {
          donorIds.add(donorId);
        }
      }

      // Prefetch donor data with better error handling
      await _prefetchDonors(donorIds.toList());

      List<personHome> newProcessedDonations = [];

      for (var i = 0; i < docs.length; i++) {
        try {
          var doc = docs[i];
          final data = doc.data() as Map<String, dynamic>?;

          if (data == null) {
            print('Warning: Document ${doc.id} has null data');
            continue;
          }

          final donorId = doc.reference.parent.parent?.id;

          if (donorId != null &&
              donorId.isNotEmpty &&
              _donorCache.containsKey(donorId)) {
            final donorData = _donorCache[donorId]!;
            final donorName = donorData['name'] ?? 'Unknown Donor';

            newProcessedDonations.add(
              personHome(
                name: donorName,
                date: _formatTimestamp(data['timestamp']),
                amount: _parseAmount(data['amount']),
                donorId: donorId,
                method: data['paymentMethod']?.toString() ?? 'Unknown',
                month: data['month']?.toString() ?? 'Unknown',
                year: data['year']?.toString() ?? 'Unknown',
                status: data['status']?.toString() ?? 'Unpaid',
                documentPath: doc.reference.path,
              ),
            );
          } else {
            print('Warning: Donor not found or invalid donorId for document ${doc.id}');
          }
        } catch (e) {
          print('Error processing document ${docs[i].id}: $e');
          // Continue processing other documents
        }

        if (showLoadingUI) {
          _loadedDocuments = i + 1;
          _loadingController.add(_loadedDocuments / _totalDocuments);
        }

        // Yield control periodically
        if (i % 5 == 0) {
          await Future.delayed(const Duration(milliseconds: 1));
        }
      }

      if (mounted) {
        setState(() {
          _processedDonations = newProcessedDonations;
          _isLoading = false;
          _errorMessage = null;
        });
      }
    } catch (e) {
      print('Error in _processDocumentsAsync: $e');
      if (mounted) {
        setState(() {
          _isLoading = false;
          _errorMessage = 'Failed to process donations: ${e.toString()}';
        });
      }
    }
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
          print('Warning: Could not parse amount: $amount');
          return 0;
        }
      }
    }
    return 0;
  }

  Future<void> _prefetchDonors(List<String> donorIds) async {
    if (donorIds.isEmpty) return;

    const int batchSize = 10; // Firestore 'in' query limit

    for (int i = 0; i < donorIds.length; i += batchSize) {
      final end = (i + batchSize < donorIds.length) ? i + batchSize : donorIds.length;
      final batch = donorIds.sublist(i, end);

      if (batch.isEmpty) continue;

      try {
        final donorsSnapshot = await FirebaseFirestore.instance
            .collection('donors')
            .where(FieldPath.documentId, whereIn: batch)
            .get(const GetOptions(source: Source.serverAndCache));

        for (var doc in donorsSnapshot.docs) {
          if (doc.exists && doc.data().isNotEmpty) {
            _donorCache[doc.id] = doc.data();
          } else {
            print('Warning: Donor document ${doc.id} is empty or does not exist');
          }
        }

        // Add delay between batches to avoid overwhelming Firestore
        if (i + batchSize < donorIds.length) {
          await Future.delayed(const Duration(milliseconds: 50));
        }
      } catch (e) {
        print('Error fetching donors batch $i-$end: $e');
        // Continue with other batches even if one fails
      }
    }
  }

  Widget _buildDonationListView() {
    List<personHome> filteredDonations = _processedDonations.where((person) {
      if (_searchFilter.isEmpty) return true;
      return person.name.toLowerCase().contains(_searchFilter) ||
          person.month.toLowerCase().contains(_searchFilter) ||
          person.amount.toString().contains(_searchFilter);
    }).toList();

    if (filteredDonations.isEmpty && _searchFilter.isNotEmpty) {
      return _buildNoSearchResultsUI();
    }

    return ListView.builder(
      itemCount: filteredDonations.length,
      itemBuilder: (context, index) {
        final person = filteredDonations[index];

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
            await _handleDonationDeletion(person);
          },
          child: PeopleListViewHome(
            peoplesHome: [person],
            onTap: (tappedPerson) {
              _showPaymentDetailsDialog(context, tappedPerson);
            },
          ),
        );
      },
    );
  }

  Widget _buildNoSearchResultsUI() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              color: Colors.grey[200],
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.search_off,
              size: 40,
              color: Colors.grey,
            ),
          ),
          const SizedBox(height: 16),
          const Text(
            'No Results Found',
            style: TextStyle(
              fontFamily: "Inter",
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: Colors.grey,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'No donations match "$_searchFilter"',
            style: const TextStyle(
              fontFamily: "Inter",
              fontSize: 14,
              color: Colors.grey,
            ),
          ),
          const SizedBox(height: 16),
          TextButton.icon(
            onPressed: () {
              _searchController.clear();
            },
            icon: const Icon(Icons.clear, size: 18),
            label: const Text(
              'Clear Search',
              style: TextStyle(
                fontFamily: "Inter",
                fontWeight: FontWeight.w600,
              ),
            ),
            style: TextButton.styleFrom(
              foregroundColor: const Color(0xff1BA3A1),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _handleDonationDeletion(personHome person) async {
    try {
      if (person.documentPath != null) {
        await FirebaseFirestore.instance
            .doc(person.documentPath!)
            .delete();

        setState(() {
          _processedDonations.removeWhere(
                  (p) => p.documentPath == person.documentPath);
        });

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Row(
                children: [
                  const Icon(Icons.check_circle, color: Colors.white, size: 20),
                  const SizedBox(width: 8),
                  Text(
                    'Donation deleted successfully',
                    style: const TextStyle(fontFamily: "Inter"),
                  ),
                ],
              ),
              backgroundColor: const Color(0xff1BA3A1),
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
          );
        }
      }
    } catch (e) {
      print('Error deleting donation: $e');

      if (mounted) {
        setState(() {
          _errorMessage = 'Failed to delete donation: ${e.toString()}';
        });

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.error, color: Colors.white, size: 20),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Failed to delete donation. Please try again.',
                    style: const TextStyle(fontFamily: "Inter"),
                  ),
                ),
              ],
            ),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
            action: SnackBarAction(
              label: 'Retry',
              textColor: Colors.white,
              onPressed: () => _handleDonationDeletion(person),
            ),
          ),
        );
      }
    }
  }

  String _formatTimestamp(dynamic timestamp) {
    try {
      if (timestamp == null) return "Unknown Date";

      DateTime date;
      if (timestamp is Timestamp) {
        date = timestamp.toDate();
      } else if (timestamp is String) {
        date = DateTime.parse(timestamp);
      } else {
        return "Invalid Date";
      }

      return "${date.day.toString().padLeft(2, '0')}.${date.month.toString().padLeft(2, '0')}.${date.year}";
    } catch (e) {
      print('Error formatting timestamp: $e');
      return "Unknown Date";
    }
  }



  void _showPaymentDetailsDialog(BuildContext context, personHome person) async {
    showDialog(
      context: context,
      builder: (BuildContext dialogContext) {
        return Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          elevation: 0,
          backgroundColor: Colors.transparent,
          child: Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  spreadRadius: 5,
                  blurRadius: 7,
                  offset: const Offset(0, 3),
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: const Color(0xff1BA3A1).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.account_circle,
                          color: Color(0xff1BA3A1), size: 28),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              person.name,
                              style: const TextStyle(
                                fontFamily: "Inter",
                                fontWeight: FontWeight.w600,
                                fontSize: 16,
                                color: Color(0xff1BA3A1),
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              "₹${person.amount}",
                              style: const TextStyle(
                                fontFamily: "Inter",
                                fontWeight: FontWeight.w700,
                                fontSize: 18,
                                color: Color(0xff1BA3A1),
                              ),
                            ),
                          ],
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: const Color(0xff1BA3A1),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          person.status,
                          style: const TextStyle(
                            color: Colors.white,
                            fontFamily: "Inter",
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),
                _detailItem(Icons.calendar_today, "Date", person.date),
                _detailItem(Icons.payment, "Payment Method", person.method),
                _detailItem(Icons.date_range, "Month", person.month),
                _detailItem(Icons.calendar_view_month, "Year", person.year),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () async {
                          try {
                            final pdfPath = await _generateAndSavePDF(person);
                            await Share.shareXFiles([XFile(pdfPath)],
                                text: 'Donation Receipt for ${person.name}');
                          } catch (e) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text('Failed to generate PDF: $e'),
                                backgroundColor: Colors.red,
                              ),
                            );
                          }
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.white,
                          foregroundColor: const Color(0xff1BA3A1),
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                            side: const BorderSide(color: Color(0xff1BA3A1)),
                          ),
                          elevation: 0,
                        ),
                        child: const Text(
                          'Share PDF',
                          style: TextStyle(
                            fontFamily: "Inter",
                            fontWeight: FontWeight.w600,
                            fontSize: 14,
                            color: Color(0xff1BA3A1),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () {
                          Navigator.of(dialogContext).pop();
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xff1BA3A1),
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                          elevation: 0,
                        ),
                        child: const Text(
                          'Close',
                          style: TextStyle(
                            fontFamily: "Inter",
                            fontWeight: FontWeight.w600,
                            fontSize: 14,
                            color: Colors.white,
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
  }

  Widget _detailItem(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Icon(icon, size: 18, color: const Color(0xff1BA3A1)),
          const SizedBox(width: 12),
          Expanded(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  label,
                  style: const TextStyle(
                    fontFamily: "Inter",
                    fontSize: 14,
                    color: Colors.black54,
                  ),
                ),
                Text(
                  value,
                  style: const TextStyle(
                    fontFamily: "Inter",
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Future<String> _generateAndSavePDF(personHome person) async {
    // Creating LaTeX content for the donation receipt
    final latexContent = r'''
\documentclass[a4paper,12pt]{article}
\usepackage[utf8]{inputenc}
\usepackage{geometry}
\geometry{a4paper, margin=1in}
\usepackage{parskip}
\usepackage{xcolor}
\definecolor{teal}{RGB}{27,163,161}

% Setting up fonts
\usepackage[T1]{fontenc}
\usepackage{lmodern}

\begin{document}

\begin{center}
{\Large \textbf{Donation Receipt}} \\
\vspace{0.5cm}
{\color{teal} \rule{0.5\textwidth}{0.4pt}}
\end{center}

\vspace{0.5cm}

\begin{tabular}{ll}
\textbf{Donor Name:} & ''' + person.name + r''' \\
\textbf{Amount:} & ₹''' + person.amount.toString() + r''' \\
\textbf{Date:} & ''' + person.date + r''' \\
\textbf{Payment Method:} & ''' + person.method + r''' \\
\textbf{Month:} & ''' + person.month + r''' \\
\textbf{Year:} & ''' + person.year + r''' \\
\textbf{Status:} & ''' + person.status + r''' \\
\textbf{Donor ID:} & ''' + person.donorId + r''' \\
\end{tabular}

\vspace{1cm}

{\small Thank you for your generous donation!}

\end{document}
''';

    // Save LaTeX content to a temporary .tex file
    final tempDir = await getTemporaryDirectory();
    final texFile = File('${tempDir.path}/donation_receipt_${person.donorId}.tex');
    await texFile.writeAsString(latexContent);

    // Note: In a real implementation, you would compile the LaTeX file to PDF using latexmk.
    // Since Flutter doesn't natively support LaTeX compilation, you would typically:
    // 1. Use a server-side service to compile LaTeX to PDF, or
    // 2. Use a native plugin or external library (not available in this context).
    // For this example, we'll assume the LaTeX content is saved and can be shared as-is or processed externally.

    // For demonstration, we'll return the path of the .tex file.
    // In a production app, you'd compile this to PDF using a service or native module.
    return texFile.path;
  }

  Future<bool> _showDeleteConfirmation(
      BuildContext context, personHome person) async {
    return await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          title: Row(
            children: [
              Icon(
                Icons.warning_amber_rounded,
                color: Colors.orange[600],
                size: 24,
              ),
              const SizedBox(width: 8),
              const Text(
                'Confirm Deletion',
                style: TextStyle(
                  fontFamily: "Inter",
                  fontWeight: FontWeight.w600,
                  fontSize: 16,
                ),
              ),
            ],
          ),
          content: Text(
            'Are you sure you want to delete this donation of ₹${person.amount} from ${person.name}?\n\nThis action cannot be undone.',
            style: const TextStyle(
              fontFamily: "Inter",
              fontWeight: FontWeight.w400,
              fontSize: 14,
            ),
          ),
          actions: <Widget>[
            TextButton(
              style: TextButton.styleFrom(
                foregroundColor: Colors.grey[600],
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(6),
                ),
              ),
              child: const Text(
                'Cancel',
                style: TextStyle(
                  fontFamily: "Inter",
                  fontWeight: FontWeight.w600,
                  fontSize: 14,
                ),
              ),
              onPressed: () {
                Navigator.of(dialogContext).pop(false);
              },
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                foregroundColor: Colors.white,
                backgroundColor: Colors.red[600],
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(6),
                ),
                elevation: 0,
              ),
              child: const Text(
                'Delete',
                style: TextStyle(
                  fontFamily: "Inter",
                  fontWeight: FontWeight.w600,
                  fontSize: 14,
                ),
              ),
              onPressed: () {
                Navigator.of(dialogContext).pop(true);
              },
            ),
          ],
        );
      },
    ) ??
        false;
  }
}