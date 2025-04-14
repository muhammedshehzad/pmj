import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import '../assets/custom widgets/PeopleListViewHome.dart';
import '../assets/custom widgets/logoutpopup.dart';

class AllDonationsPage extends StatefulWidget {
  @override
  _AllDonationsPageState createState() => _AllDonationsPageState();
}

class _AllDonationsPageState extends State<AllDonationsPage> {
  // Cache for donor data to avoid repeated queries
  final Map<String, Map<String, dynamic>> _donorCache = {};

  // Store loading state
  bool _isLoading = false;
  double _loadingProgress = 0.0;
  int _totalDocuments = 0;
  int _loadedDocuments = 0;

  // Store processed donations
  List<personHome> _processedDonations = [];

  // Store the latest snapshot for processing
  QuerySnapshot? _latestSnapshot;

  // Controller for loading status updates
  final _loadingController = StreamController<double>.broadcast();

  @override
  void initState() {
    super.initState();
    _loadingController.stream.listen((progress) {
      if (mounted) {
        setState(() {
          _loadingProgress = progress;
        });
      }
    });
  }

  @override
  void dispose() {
    _loadingController.close();
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
                        elevation: 0,
                      ),
                      child: const Center(
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
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
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
                  color: Color(0xff1BA3A1)),
            ),
            const SizedBox(height: 6),
            Expanded(
              child: _buildDonationsList(),
            ),
          ],
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
        // Handle error state
        if (snapshot.hasError) {
          return Center(child: Text('Error: ${snapshot.error}'));
        }

        // Handle initial loading state (only show loading on first load)
        if (snapshot.connectionState == ConnectionState.waiting &&
            !_isLoading &&
            _processedDonations.isEmpty) {
          return const Center(
              child: CircularProgressIndicator(
                color: Color(0xff1BA3A1),
              )
          );
        }

        // Handle empty data state
        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return const Center(child: Text('No donations found'));
        }

        // Check if we have new data that needs processing
        // Only process if it's new data or first load
        if (snapshot.hasData && (_latestSnapshot == null ||
            _latestSnapshot!.docs.length != snapshot.data!.docs.length)) {
          _latestSnapshot = snapshot.data;

          // Schedule the processing for after the build completes
          WidgetsBinding.instance.addPostFrameCallback((_) {
            _processDocumentsAsync(snapshot.data!.docs);
          });
        }

        // Show loading UI only for first load, not for updates
        if (_isLoading && _processedDonations.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Stack(
                  alignment: Alignment.center,
                  children: [
                    SizedBox(
                      width: 80,
                      height: 80,
                      child: CircularProgressIndicator(
                        value: _loadingProgress,
                        strokeWidth: 6,
                        backgroundColor: const Color(0xffE0F7FA),
                        color: const Color(0xff1BA3A1),
                      ),
                    ),
                    Text(
                      "${(_loadingProgress * 100).toInt()}%",
                      style: const TextStyle(
                        fontFamily: "Inter",
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                        color: Color(0xff1BA3A1),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Text(
                  'Loading donations... $_loadedDocuments/$_totalDocuments',
                  style: const TextStyle(
                    fontFamily: "Inter",
                    color: Color(0xff1BA3A1),
                  ),
                ),
              ],
            ),
          );
        }

        // During updates with existing data, just show the current data
        // The updated data will replace it when ready without intermediate loading state
        return _buildDonationListView();
      },
    );
  }
  // Process documents asynchronously
// Modify your _processDocumentsAsync method to avoid the UI flash
  Future<void> _processDocumentsAsync(List<QueryDocumentSnapshot> docs) async {
    // Don't show loading UI for updates if we already have data
    bool showLoadingUI = _processedDonations.isEmpty;

    if (showLoadingUI) {
      setState(() {
        _isLoading = true;
        _totalDocuments = docs.length;
        _loadedDocuments = 0;
        _loadingProgress = 0.0;
      });
    }

    try {
      // Collect all unique donor IDs
      Set<String> donorIds = {};
      for (var doc in docs) {
        final donorId = doc.reference.parent.parent?.id;
        if (donorId != null && donorId.isNotEmpty) {
          donorIds.add(donorId);
        }
      }

      // Prefetch all donor data in batches
      await _prefetchDonors(donorIds.toList());

      // Process donations with cached donor data
      List<personHome> newProcessedDonations = [];

      for (var i = 0; i < docs.length; i++) {
        var doc = docs[i];
        final data = doc.data() as Map<String, dynamic>;
        final donorId = doc.reference.parent.parent?.id;

        if (donorId != null && donorId.isNotEmpty && _donorCache.containsKey(donorId)) {
          final donorData = _donorCache[donorId]!;
          final donorName = donorData['name'] ?? 'Unknown';

          newProcessedDonations.add(
            personHome(
              name: donorName,
              date: _formatTimestamp(data['timestamp']),
              amount: (data['amount'] as num?)?.toInt() ?? 0,
              donorId: donorId,
              method: data['paymentMethod'] ?? 'Unknown',
              month: data['month'] ?? 'Unknown',
              year: data['year'] ?? 'Unknown',
              status: data['status'] ?? 'Unpaid',
              documentPath: doc.reference.path,
            ),
          );
        }

        // Only update loading progress if showing loading UI
        if (showLoadingUI) {
          _loadedDocuments = i + 1;
          _loadingController.add(_loadedDocuments / _totalDocuments);
        }

        // Add a small delay to avoid blocking the UI
        if (i % 10 == 0) {
          await Future.delayed(Duration(milliseconds: 1));
        }
      }

      // Update state with processed donations
      if (mounted) {
        setState(() {
          _processedDonations = newProcessedDonations;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error loading donations: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }
  // Pre-fetch donor information in batches
  Future<void> _prefetchDonors(List<String> donorIds) async {
    if (donorIds.isEmpty) return;

    // Process in batches of 10 for better performance
    for (int i = 0; i < donorIds.length; i += 10) {
      final end = (i + 10 < donorIds.length) ? i + 10 : donorIds.length;
      final batch = donorIds.sublist(i, end);

      if (batch.isEmpty) continue;

      try {
        final donorsSnapshot = await FirebaseFirestore.instance
            .collection('donors')
            .where(FieldPath.documentId, whereIn: batch)
            .get();

        for (var doc in donorsSnapshot.docs) {
          _donorCache[doc.id] = doc.data();
        }
      } catch (e) {
        print('Error fetching donors batch: $e');
      }
    }
  }

  // Build the ListView with processed data
  Widget _buildDonationListView() {
    if (_processedDonations.isEmpty) {
      return const Center(child: Text('No donations found'));
    }

    return ListView.builder(
      itemCount: _processedDonations.length,
      itemBuilder: (context, index) {
        final person = _processedDonations[index];

        return Dismissible(
          key: Key(person.documentPath ?? '${person.donorId}_${person.date}_${person.amount}'),
          direction: DismissDirection.endToStart,
          background: Container(
            alignment: Alignment.centerRight,
            padding: const EdgeInsets.only(right: 20.0),
            color: Colors.red,
            child: const Icon(
              Icons.delete,
              color: Colors.white,
            ),
          ),
          confirmDismiss: (direction) async {
            return await _showDeleteConfirmation(context, person);
          },
          onDismissed: (direction) async {
            try {
              if (person.documentPath != null) {
                await FirebaseFirestore.instance.doc(person.documentPath!).delete();

                setState(() {
                  _processedDonations.removeAt(index);
                });

                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Donation deleted successfully'),
                    backgroundColor: Color(0xff1BA3A1),
                  ),
                );
              }
            } catch (e) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('Error deleting donation: $e'),
                  backgroundColor: Colors.red,
                ),
              );
            }
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
  String _formatTimestamp(Timestamp? timestamp) {
    if (timestamp == null) return "Unknown Date";
    final date = timestamp.toDate();
    return "${date.day.toString().padLeft(2, '0')}.${date.month.toString().padLeft(2, '0')}.${date.year}";
  }

  // Payment details dialog
  void _showPaymentDetailsDialog(BuildContext context, personHome person) {
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
                // Header
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: const Color(0xff1BA3A1).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.account_circle, color: Color(0xff1BA3A1), size: 28),
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
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
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
                      )
                    ],
                  ),
                ),

                const SizedBox(height: 20),

                // Details section
                _detailItem(Icons.calendar_today, "Date", person.date),
                _detailItem(Icons.payment, "Payment Method", person.method),
                _detailItem(Icons.date_range, "Month", person.month),
                _detailItem(Icons.calendar_view_month, "Year", person.year),

                const SizedBox(height: 16),

                // Close button
                SizedBox(
                  width: double.infinity,
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
                        color: Colors.white
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  // Helper method to create detail item rows
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

  Future<bool> _showDeleteConfirmation(BuildContext context, personHome person) async {
    return await showDialog<bool>(
      context: context,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          content: Text(
            'Are you sure you want to delete this donation of ₹${person.amount} from ${person.name}?',
            style: const TextStyle(
              fontFamily: "Inter",
              fontWeight: FontWeight.w400,
              fontSize: 12,
            ),
          ),
          actions: <Widget>[
            Container(
              height: 26,
              width: 80,
              margin: const EdgeInsets.only(right: 4, bottom: 4),
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  foregroundColor: Colors.white,
                  backgroundColor: const Color(0xff29B6F6),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(4),
                  ),
                  elevation: 0,
                ),
                child: const Text(
                  'Cancel',
                  style: TextStyle(
                    fontFamily: "Inter",
                    fontWeight: FontWeight.w600,
                    fontSize: 9,
                  ),
                ),
                onPressed: () {
                  Navigator.of(dialogContext).pop(false);
                },
              ),
            ),
            Container(
              height: 26,
              width: 80,
              margin: const EdgeInsets.only(right: 4, bottom: 4),
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  foregroundColor: Colors.white,
                  backgroundColor: const Color(0xffF44336),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(4),
                  ),
                  elevation: 0,
                ),
                child: const Text(
                  'Delete',
                  style: TextStyle(
                    fontFamily: "Inter",
                    fontWeight: FontWeight.w600,
                    fontSize: 9,
                  ),
                ),
                onPressed: () {
                  Navigator.of(dialogContext).pop(true);
                },
              ),
            ),
          ],
        );
      },
    ) ?? false;
  }}

// Add this if needed
// import 'dart:async';