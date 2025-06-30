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
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'dart:ui' as ui;
import 'package:flutter/rendering.dart';
import 'package:provider/provider.dart';
import 'donations_provider.dart';

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
    return Consumer<DonationsProvider>(
      builder: (context, provider, child) {
        if (provider.errorMessage != null) {
          return _buildErrorUI(provider.errorMessage!);
        }
        if (provider.isLoading) {
          return _buildImprovedShimmerLoading();
        }
        if (provider.donations.isEmpty) {
          return _buildEmptyStateUI();
        }
        // Show donation list
        List<personHome> filteredDonations = provider.donations.where((person) {
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
              key: Key(person.documentPath ?? '${person.donorId}_${person.date}_${person.amount}'),
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
      },
    );
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
                            final imagePath = await _generateAndSaveImage(person);
                            await Share.shareXFiles([XFile(imagePath)],
                                text: 'Donation Receipt for ${person.name}');
                          } catch (e) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text('Failed to generate receipt: $e'),
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
                          'Share Receipt',
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

  Future<String> _generateAndSaveImage(personHome person) async {
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
      final boundary = receiptKey.currentContext!.findRenderObject() as RenderRepaintBoundary;
      final image = await boundary.toImage(pixelRatio: 3.0);
      final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
      final bytes = byteData!.buffer.asUint8List();
      
      // Save image to temporary directory
      final tempDir = await getTemporaryDirectory();
      final imageFile = File('${tempDir.path}/PMJ_Receipt_${person.donorId}_${DateTime.now().millisecondsSinceEpoch}.png');
      await imageFile.writeAsBytes(bytes);
      
      return imageFile.path;
    } finally {
      // Remove the overlay entry
      overlayEntry.remove();
    }
  }

  Widget _buildReceiptWidget(personHome person, GlobalKey key, String donorAddress) {
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
                margin: const EdgeInsets.symmetric(horizontal: 32, vertical: 10),
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
                    _buildReceiptRow('Month:', '${person.month} ${person.year}'),
                    const SizedBox(height: 8),
                    _buildReceiptRow('Amount', '₹${person.amount.toStringAsFixed(0)}/-', isAmount: true),
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
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
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

  Widget _buildReceiptRow(String label, String value, {bool isAmount = false}) {
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
            value,
            style: TextStyle(
              fontSize: 13,
              fontWeight: isAmount ? FontWeight.bold : FontWeight.w500,
              color: isAmount ? const Color(0xFF41c057) : Colors.black87,
            ),
            textAlign: TextAlign.right,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
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

  String _numberToWords(int number) {
    if (number == 0) return 'Zero Rupees Only';
    final units = ['', 'One', 'Two', 'Three', 'Four', 'Five', 'Six', 'Seven', 'Eight', 'Nine'];
    final teens = ['Ten', 'Eleven', 'Twelve', 'Thirteen', 'Fourteen', 'Fifteen', 'Sixteen', 'Seventeen', 'Eighteen', 'Nineteen'];
    final tens = ['', '', 'Twenty', 'Thirty', 'Forty', 'Fifty', 'Sixty', 'Seventy', 'Eighty', 'Ninety'];
    String convertLessThanOneThousand(int n) {
      if (n == 0) return '';
      if (n < 10) return units[n];
      if (n < 20) return teens[n - 10];
      if (n < 100) {
        return tens[n ~/ 10] + (n % 10 != 0 ? ' ' + units[n % 10] : '');
      }
      return units[n ~/ 100] + ' Hundred' + (n % 100 != 0 ? ' and ' + convertLessThanOneThousand(n % 100) : '');
    }
    String result = '';
    int num = number;
    if (num >= 10000000) {
      result += convertLessThanOneThousand(num ~/ 10000000) + ' Crore ';
      num %= 10000000;
    }
    if (num >= 100000) {
      result += convertLessThanOneThousand(num ~/ 100000) + ' Lakh ';
      num %= 100000;
    }
    if (num >= 1000) {
      result += convertLessThanOneThousand(num ~/ 1000) + ' Thousand ';
      num %= 1000;
    }
    if (num > 0) {
      result += convertLessThanOneThousand(num);
    }
    return result.trim() + ' Rupees Only';
  }
}