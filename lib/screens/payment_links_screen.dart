import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:shimmer/shimmer.dart';
import '../models/person_model.dart';
import '../services/upi_payment_service.dart';
import '../assets/custom%20widgets/shimmer_widgets.dart';
import 'package:intl/intl.dart';

class PaymentLinksScreen extends StatefulWidget {
  const PaymentLinksScreen({super.key});

  @override
  State<PaymentLinksScreen> createState() => _PaymentLinksScreenState();
}

class _PaymentLinksScreenState extends State<PaymentLinksScreen> {
  List<Person> _allDonors = [];
  List<Person> _filteredDonors = [];
  List<Person> _selectedDonors = [];
  bool _isLoading = true;
  bool _isProcessing = false;
  String _searchQuery = '';
  Map<String, dynamic>? _lastResult;

  // Pagination state
  final ScrollController _scrollController = ScrollController();
  bool _isPaginating = false;
  bool _hasMore = true;
  DocumentSnapshot? _lastDonorDocument;
  static const int _pageSize = 30;
  bool _initialLoading = true;

  // Cache of paid donor IDs for the current month
  Set<String> _paidDonorIds = {};
  
  final TextEditingController _messageController = TextEditingController();
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
    _loadDonors();
    _messageController.text = _getDefaultMessage();
  }

  @override
  void dispose() {
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    _messageController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  String _getDefaultMessage() {
    final now = DateTime.now();
    final monthName = DateFormat('MMMM').format(now);
    final year = now.year;
    
    return '''Dear {name},

This is a reminder for your monthly donation for $monthName $year.

Amount Due: {amount}

Please pay using this link:
{upi_link}

Thank you for your continued support!

- Team PMJ''';
  }

  void _onScroll() {
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - 200) {
      _fetchMoreDonors();
    }
  }

  Future<void> _loadDonors() async {
    if (!mounted) return;
    
    setState(() {
      _isLoading = true;
      _initialLoading = true;
      _hasMore = true;
      _isPaginating = false;
      _lastDonorDocument = null;
      _allDonors.clear();
      _filteredDonors.clear();
      _selectedDonors.clear();
    });

    try {
      debugPrint('Starting to load donors...');
      
      // Get current month and year
      final now = DateTime.now();
      final currentMonth = DateFormat('MMMM').format(now);
      final currentYear = now.year.toString();

      debugPrint('Checking payment status for $currentMonth $currentYear');

      // Batch fetch all paid statuses for current month in one query
      final paymentStatusSnapshot = await FirebaseFirestore.instance
          .collectionGroup('paymentStatus')
          .where('month', isEqualTo: currentMonth)
          .where('year', isEqualTo: currentYear)
          .where('status', isEqualTo: 'paid')
          .get();

      // Create a set of donor IDs who have paid
      _paidDonorIds = <String>{};
      for (var doc in paymentStatusSnapshot.docs) {
        // Extract donor ID from the document path
        // Path format: donors/{donorId}/paymentStatus/{docId}
        final pathSegments = doc.reference.path.split('/');
        if (pathSegments.length >= 2) {
          _paidDonorIds.add(pathSegments[1]);
        }
      }

      debugPrint('Found ${_paidDonorIds.length} donors who have paid for current month');

      // Fetch first page of donors
      await _fetchInitialDonorPage();
    } catch (e) {
      debugPrint('Error loading donors: $e');
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
        _showSnackBar(
          'Failed to load donors: $e',
          Colors.red,
        );
      }
    }
  }

  Future<void> _fetchInitialDonorPage() async {
    final query = FirebaseFirestore.instance
        .collection('donors')
        .orderBy('name')
        .limit(_pageSize);
    final snapshot = await query.get();
    await _processDonorPage(snapshot, isInitial: true);
  }

  Future<void> _fetchMoreDonors() async {
    if (!_hasMore || _isPaginating || _initialLoading) return;
    if (_lastDonorDocument == null) return;
    setState(() {
      _isPaginating = true;
    });
    Query query = FirebaseFirestore.instance
        .collection('donors')
        .orderBy('name')
        .startAfterDocument(_lastDonorDocument!)
        .limit(_pageSize);
    final snapshot = await query.get();
    await _processDonorPage(snapshot, isInitial: false);
  }

  Future<void> _processDonorPage(QuerySnapshot snapshot, {required bool isInitial}) async {
    if (!mounted) return;
    if (snapshot.docs.isEmpty) {
      setState(() {
        _hasMore = false;
        _isPaginating = false;
        _isLoading = false;
        _initialLoading = false;
      });
      return;
    }

    final List<Person> pageUnpaid = [];
    for (final doc in snapshot.docs) {
      try {
        if (_paidDonorIds.contains(doc.id)) continue; // skip paid
        final donor = Person.fromFirestore(doc);
        pageUnpaid.add(donor);
      } catch (e) {
        debugPrint('Error processing donor ${doc.id}: $e');
      }
    }

    setState(() {
      _allDonors.addAll(pageUnpaid);
      // Apply current search filter
      _applySearchFilter();
      _lastDonorDocument = snapshot.docs.last;
      _isPaginating = false;
      _isLoading = false;
      _initialLoading = false;
      if (snapshot.docs.length < _pageSize) {
        _hasMore = false;
      }
    });
  }

  void _filterDonors() {
    setState(() {
      _applySearchFilter();
    });
  }

  void _applySearchFilter() {
    _filteredDonors = _allDonors.where((donor) {
      final q = _searchQuery.toLowerCase();
      final matchesSearch = q.isEmpty ||
          donor.name.toLowerCase().contains(q) ||
          donor.house.toLowerCase().contains(q) ||
          donor.phoneNumber.contains(_searchQuery);
      return matchesSearch;
    }).toList();
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

                ],
              ),
            ),
          ),
        ),
      ),
      body: _isLoading
          ? DonorDetailsShimmer()
          : SingleChildScrollView(
              controller: _scrollController,
              child: Column(
                children: [
                  // Header with back button and title
                  ListTile(
                    leading: GestureDetector(
                      onTap: () => Navigator.pop(context),
                      child: SvgPicture.asset(
                        'lib/assets/images/Back.svg',
                        height: 40,
                        width: 40,
                      ),
                    ),
                    title: const Center(
                      child: Text(
                        'Monthly Payment Reminders',
                        style: TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 16,
                          fontFamily: "Inter",
                        ),
                      ),
                    ),
                    trailing: const SizedBox(width: 40),
                  ),
                  
                  // Main content area with icon and stats
                  Container(
                    height: 140,
                    width: double.infinity,
                    margin: const EdgeInsets.symmetric(horizontal: 16.0),
                    child: LayoutBuilder(
                      builder: (context, constraints) {
                        final isSmallScreen = constraints.maxWidth < 400;
                        return Stack(
                          children: [
                            Positioned(
                              left: 20,
                              top: 20,
                              child: Container(
                                width: isSmallScreen ? 70 : 80,
                                height: isSmallScreen ? 70 : 80,
                                decoration: BoxDecoration(
                                  color: const Color(0xff1BA3A1),
                                  borderRadius: BorderRadius.circular(isSmallScreen ? 35 : 40),
                                ),
                                child: Icon(
                                  Icons.send,
                                  size: isSmallScreen ? 35 : 40,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                            Positioned(
                              top: 17,
                              right: 20,
                              left: isSmallScreen ? 110 : 120,
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Monthly Reminders',
                                    style: TextStyle(
                                      fontSize: isSmallScreen ? 14 : 16,
                                      fontFamily: "Inter",
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                  const SizedBox(height: 6),
                                  Text(
                                    'Send payment reminders for current month unpaid donations',
                                    style: TextStyle(
                                      fontSize: isSmallScreen ? 10 : 11,
                                      fontFamily: "Inter",
                                      fontWeight: FontWeight.w400,
                                      color: Colors.grey[600],
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  Row(
                                    children: [
                                      _buildMiniStatCard(
                                        'Selected',
                                        _selectedDonors.length.toString(),
                                        Colors.green,
                                      ),
                                      const SizedBox(width: 6),
                                      _buildMiniStatCard(
                                        'Total',
                                        _filteredDonors.length.toString(),
                                        Colors.blue,
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          ],
                        );
                      },
                    ),
                  ),
                  
                  // Search Section
                  Container(
                    margin: const EdgeInsets.all(16.0),
                    padding: const EdgeInsets.all(16.0),
                    decoration: BoxDecoration(
                      color: Theme.of(context).cardColor,
                      borderRadius: BorderRadius.circular(8),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.grey.withOpacity(0.1),
                          spreadRadius: 1,
                          blurRadius: 4,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text(
                              'Select Recipients',
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                                fontFamily: "Inter",
                              ),
                            ),
                            Row(
                              children: [
                                TextButton(
                                  onPressed: () {
                                    setState(() {
                                      _selectedDonors = _filteredDonors
                                          .where((d) => d.phoneNumber.isNotEmpty && d.phoneNumber != '0' && d.phoneNumber.length >= 10)
                                          .toList();
                                    });
                                  },
                                  child: const Text(
                                    'Select All',
                                    style: TextStyle(
                                      fontSize: 12,
                                      fontFamily: "Inter",
                                      color: Color(0xff1BA3A1),
                                    ),
                                  ),
                                ),
                                TextButton(
                                  onPressed: () {
                                    setState(() {
                                      _selectedDonors.clear();
                                    });
                                  },
                                  child: const Text(
                                    'Clear All',
                                    style: TextStyle(
                                      fontSize: 12,
                                      fontFamily: "Inter",
                                      color: Colors.red,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        TextField(
                          controller: _searchController,
                          decoration: InputDecoration(
                            hintText: 'Search donors by name, address, or phone...',
                            hintStyle: const TextStyle(
                              fontSize: 12,
                              fontFamily: "Inter",
                            ),
                            prefixIcon: const Icon(Icons.search, size: 20),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8),
                              borderSide: BorderSide(color: Colors.grey[300]!),
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8),
                              borderSide: BorderSide(color: Colors.grey[300]!),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8),
                              borderSide: const BorderSide(color: Color(0xff1BA3A1)),
                            ),
                            filled: true,
                            fillColor: Theme.of(context).brightness == Brightness.dark ? const Color(0xFF1E1E1E) : Colors.grey[50],
                            contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                          ),
                          style: const TextStyle(fontSize: 14, fontFamily: "Inter"),
                          onChanged: (value) {
                            setState(() {
                              _searchQuery = value;
                            });
                            _filterDonors();
                          },
                        ),
                        const SizedBox(height: 12),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceAround,
                          children: [
                            _buildStatCard(
                              'Total',
                              _filteredDonors.length.toString(),
                              Icons.people,
                              Colors.blue,
                            ),SizedBox(width: 8,),
                            _buildStatCard(
                              'Selected',
                              _selectedDonors.length.toString(),
                              Icons.check_circle,
                              Colors.green,
                            ),SizedBox(width: 8,),
                            _buildStatCard(
                              'Amount',
                              '₹${_selectedDonors.fold<double>(0, (sum, donor) => sum + donor.amount).toStringAsFixed(0)}',
                              Icons.currency_rupee,
                              Colors.orange,
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  
                  // Donors List with Selection
                  if (_filteredDonors.isNotEmpty)
                    Container(
                      margin: const EdgeInsets.symmetric(horizontal: 16.0),
                      decoration: BoxDecoration(
                        color: Theme.of(context).cardColor,
                        borderRadius: BorderRadius.circular(8),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.grey.withOpacity(0.1),
                            spreadRadius: 1,
                            blurRadius: 4,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Column(
                        children: [
                          const Padding(
                            padding: EdgeInsets.all(16.0),
                            child: Text(
                              'Donors List',
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                                fontFamily: "Inter",
                              ),
                            ),
                          ),
                          ListView.builder(
                            physics: const NeverScrollableScrollPhysics(),
                            shrinkWrap: true,
                            itemCount: _filteredDonors.length + ((_isPaginating || (!_hasMore && _filteredDonors.isNotEmpty)) ? 1 : 0),
                            itemBuilder: (context, index) {
                              // Bottom loader or end indicator
                              if (index == _filteredDonors.length) {
                                if (_isPaginating) {
                                  return Padding(
                                    padding: const EdgeInsets.symmetric(vertical: 12.0),
                                    child: Row(
                                      mainAxisAlignment: MainAxisAlignment.center,
                                      children: const [
                                        SizedBox(
                                          width: 18,
                                          height: 18,
                                          child: CircularProgressIndicator(strokeWidth: 2, valueColor: AlwaysStoppedAnimation<Color>(Color(0xff1BA3A1))),
                                        ),
                                        SizedBox(width: 8),
                                        Text('Loading more...', style: TextStyle(fontSize: 12, fontFamily: 'Inter')),
                                      ],
                                    ),
                                  );
                                }
                                if (!_hasMore) {
                                  return const Padding(
                                    padding: EdgeInsets.symmetric(vertical: 12.0),
                                    child: Center(
                                      child: Text(
                                        'End of list',
                                        style: TextStyle(fontSize: 12, color: Colors.grey, fontFamily: 'Inter'),
                                      ),
                                    ),
                                  );
                                }
                              }

                              final donor = _filteredDonors[index];
                              final isSelected = _selectedDonors.contains(donor);
                              final bool hasValidPhone = donor.phoneNumber.isNotEmpty && donor.phoneNumber != '0' && donor.phoneNumber.length >= 10;
                              
                              return CheckboxListTile(
                                dense: true,
                                contentPadding: const EdgeInsets.symmetric(horizontal: 16),
                                title: Text(
                                  donor.name,
                                  style: const TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w500,
                                    fontFamily: "Inter",
                                  ),
                                ),
                                subtitle: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      donor.house,
                                      style: const TextStyle(
                                        fontSize: 12,
                                        fontFamily: "Inter",
                                        color: Color(0xff817D8A),
                                      ),
                                    ),
                                    Row(
                                      children: [
                                        Expanded(
                                          child: Text(
                                            (donor.phoneNumber.isEmpty || donor.phoneNumber == '0')
                                                ? 'No phone number'
                                                : donor.phoneNumber,
                                            style: TextStyle(
                                              color: hasValidPhone ? const Color(0xff1BA3A1) : Colors.red,
                                              fontWeight: FontWeight.w500,
                                              fontSize: 12,
                                              fontFamily: "Inter",
                                            ),
                                          ),
                                        ),
                                        Text(
                                          '₹${donor.amount.toStringAsFixed(0)}',
                                          style: const TextStyle(
                                            color: Color(0xff1BA3A1),
                                            fontWeight: FontWeight.w500,
                                            fontSize: 12,
                                            fontFamily: "Inter",
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                                value: isSelected && hasValidPhone,
                                activeColor: const Color(0xff1BA3A1),
                                onChanged: hasValidPhone
                                    ? (bool? value) {
                                        setState(() {
                                          if (value == true) {
                                            if (!_selectedDonors.contains(donor)) {
                                              _selectedDonors.add(donor);
                                            }
                                          } else {
                                            _selectedDonors.remove(donor);
                                          }
                                        });
                                      }
                                    : null,
                              );
                            },
                          ),
                        ],
                      ),
                    ),
                  
                  // Message Template Section
                  Container(
                    margin: const EdgeInsets.all(16.0),
                    padding: const EdgeInsets.all(16.0),
                    decoration: BoxDecoration(
                      color: Theme.of(context).cardColor,
                      borderRadius: BorderRadius.circular(8),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.grey.withOpacity(0.1),
                          spreadRadius: 1,
                          blurRadius: 4,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Message Template',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            fontFamily: "Inter",
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Use {name}, {amount}, and {upi_link} as placeholders',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey[600],
                            fontFamily: "Inter",
                          ),
                        ),
                        const SizedBox(height: 12),
                        TextField(
                          controller: _messageController,
                          maxLines: 6,
                          style: const TextStyle(
                            fontSize: 12,
                            fontFamily: "Inter",
                          ),
                          decoration: InputDecoration(
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8),
                              borderSide: BorderSide(color: Colors.grey[300]!),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8),
                              borderSide: const BorderSide(color: Color(0xff1BA3A1)),
                            ),
                            hintText: 'Enter your message template...',
                            hintStyle: const TextStyle(
                              fontSize: 12,
                              fontFamily: "Inter",
                            ),
                            filled: true,
                            fillColor: Theme.of(context).brightness == Brightness.dark ? const Color(0xFF1E1E1E) : Colors.grey[50],
                            contentPadding: const EdgeInsets.all(12),
                          ),
                        ),
                      ],
                    ),
                  ),
                  
                  // Action Buttons
                  Container(
                    margin: const EdgeInsets.symmetric(horizontal: 16.0),
                    child: Row(
                      children: [
                        Expanded(
                          child: ElevatedButton.icon(
                            onPressed: _isProcessing || _selectedDonors.isEmpty ? null : _sendViaWhatsApp,
                            icon: const Icon(Icons.message, size: 18),
                            label: const Text(
                              'Send via WhatsApp',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                fontFamily: "Inter",
                              ),
                            ),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xff25D366),
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(vertical: 12),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: ElevatedButton.icon(
                            onPressed: _isProcessing || _selectedDonors.isEmpty ? null : _sendViaSMS,
                            icon: const Icon(Icons.sms, size: 18),
                            label: const Text(
                              'Send via SMS',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                fontFamily: "Inter",
                              ),
                            ),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.blue,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(vertical: 12),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  
                  // Progress/Result Section
                  if (_isProcessing)
                    Container(
                      margin: const EdgeInsets.all(16.0),
                      padding: const EdgeInsets.all(16.0),
                      decoration: BoxDecoration(
                        color: Theme.of(context).cardColor,
                        borderRadius: BorderRadius.circular(8),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.grey.withOpacity(0.1),
                            spreadRadius: 1,
                            blurRadius: 4,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: const Row(
                        children: [
                          CircularProgressIndicator(
                            valueColor: AlwaysStoppedAnimation<Color>(Color(0xff1BA3A1)),
                            strokeWidth: 3,
                          ),
                          SizedBox(width: 16),
                          Text(
                            'Processing...',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                              fontFamily: "Inter",
                            ),
                          ),
                        ],
                      ),
                    ),
                  
                  if (_lastResult != null)
                    Container(
                      margin: const EdgeInsets.all(16.0),
                      padding: const EdgeInsets.all(16.0),
                      decoration: BoxDecoration(
                        color: Theme.of(context).cardColor,
                        borderRadius: BorderRadius.circular(8),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.grey.withOpacity(0.1),
                            spreadRadius: 1,
                            blurRadius: 4,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Operation Result',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              fontFamily: "Inter",
                            ),
                          ),
                          const SizedBox(height: 12),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceAround,
                            children: [
                              _buildResultCard('Total', '${_lastResult!['total']}', Colors.blue),SizedBox(width: 6,),
                              _buildResultCard('Success', '${_lastResult!['success']}', Colors.green),SizedBox(width: 6,),
                              _buildResultCard('Failed', '${_lastResult!['failure']}', Colors.red),
                            ],
                          ),
                          if (_lastResult!['errors'].isNotEmpty) ...[
                            const SizedBox(height: 12),
                            Text(
                              'Errors:',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: Colors.red[700],
                                fontFamily: "Inter",
                              ),
                            ),
                            const SizedBox(height: 4),
                            ...(_lastResult!['errors'] as List<String>).map(
                              (error) => Padding(
                                padding: const EdgeInsets.only(bottom: 2),
                                child: Text(
                                  '• $error',
                                  style: const TextStyle(
                                    color: Colors.red,
                                    fontSize: 11,
                                    fontFamily: "Inter",
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  
                  // Empty state
                  if (_filteredDonors.isEmpty)
                    Container(
                      margin: const EdgeInsets.all(32.0),
                      child: Column(
                        children: [
                          Icon(
                            Icons.phone_disabled,
                            size: 64,
                            color: Colors.grey[400],
                          ),
                          const SizedBox(height: 16),
                          Text(
                            'No unpaid donors for current month',
                            style: TextStyle(
                              fontSize: 16,
                              color: Colors.grey[600],
                              fontFamily: "Inter",
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'All donors have paid for this month or have invalid phone numbers',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey[500],
                              fontFamily: "Inter",
                            ),
                          ),
                        ],
                      ),
                    ),
                  
                  const SizedBox(height: 32), // Bottom padding
                ],
              ),
            ),

    );
  }

  Future<void> _testUpiLink() async {
    try {
      final success = await UpiPaymentService.testUpiLink(
        amount: 100.0,
        transactionId: 'TEST_${DateTime.now().millisecondsSinceEpoch}',
      );
      
      if (mounted) {
        if (success) {
          _showSnackBar('Test UPI link opened successfully!', Colors.green);
        } else {
          _showSnackBar('Failed to open UPI app', Colors.red);
        }
      }
    } catch (e) {
      if (mounted) {
        _showSnackBar('Failed to test UPI link: $e', Colors.red);
      }
    }
  }

  Future<void> _sendViaWhatsApp() async {
    if (_selectedDonors.isEmpty) {
      _showSnackBar('Please select at least one donor', Colors.orange);
      return;
    }

    // Filter donors with valid phone numbers
    final validDonors = _selectedDonors.where((donor) => 
      donor.phoneNumber.isNotEmpty && 
      donor.phoneNumber != '0' && 
      donor.phoneNumber.length >= 10
    ).toList();

    if (validDonors.isEmpty) {
      _showSnackBar('Selected donors do not have valid phone numbers', Colors.red);
      return;
    }

    final skippedCount = _selectedDonors.length - validDonors.length;
    if (skippedCount > 0) {
      _showSnackBar('Skipping $skippedCount donor(s) without valid phone numbers', Colors.orange);
    }

    setState(() {
      _isProcessing = true;
    });

    try {
      final result = await UpiPaymentService.sendBatchWhatsApp(
        donors: validDonors,
        customMessage: _messageController.text.isNotEmpty ? _messageController.text : null,
        onProgress: (donor, success, error) {
          debugPrint('${donor.name}: ${success ? 'Success' : 'Failed - $error'}');
        },
      );

      if (mounted) {
        setState(() {
          _lastResult = result;
          _isProcessing = false;
        });

        final successCount = result['success'] as int;
        final totalCount = result['total'] as int;
        
        if (successCount == totalCount) {
          _showSnackBar('All payment links sent successfully!', Colors.green);
        } else if (successCount > 0) {
          _showSnackBar('$successCount of $totalCount links sent successfully', Colors.orange);
        } else {
          _showSnackBar('Failed to send payment links', Colors.red);
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isProcessing = false;
        });
        _showSnackBar('Error sending payment links: $e', Colors.red);
      }
    }
  }

  Future<void> _sendViaSMS() async {
    if (_selectedDonors.isEmpty) {
      _showSnackBar('Please select at least one donor', Colors.orange);
      return;
    }

    // Filter donors with valid phone numbers
    final validDonors = _selectedDonors.where((donor) => 
      donor.phoneNumber.isNotEmpty && 
      donor.phoneNumber != '0' && 
      donor.phoneNumber.length >= 10
    ).toList();

    if (validDonors.isEmpty) {
      _showSnackBar('Selected donors do not have valid phone numbers', Colors.red);
      return;
    }

    final skippedCount = _selectedDonors.length - validDonors.length;
    if (skippedCount > 0) {
      _showSnackBar('Skipping $skippedCount donor(s) without valid phone numbers', Colors.orange);
    }

    setState(() {
      _isProcessing = true;
    });

    try {
      int successCount = 0;
      int failureCount = 0;
      List<String> errors = [];
      
      for (final donor in validDonors) {
        try {
          await UpiPaymentService.sendToSMS(
            donor: donor,
            customMessage: _messageController.text.isNotEmpty ? _messageController.text : null,
          );
          successCount++;
          
          // Add small delay between SMS opens
          await Future.delayed(const Duration(milliseconds: 500));
        } catch (e) {
          failureCount++;
          final error = e.toString();
          errors.add('${donor.name}: $error');
        }
      }
      
      final result = {
        'success': successCount,
        'failure': failureCount,
        'errors': errors,
        'total': validDonors.length,
      };

      if (mounted) {
        setState(() {
          _lastResult = result;
          _isProcessing = false;
        });

        final totalCount = result['total'] as int;
        
        if (successCount == totalCount) {
          _showSnackBar('All payment links sent successfully!', Colors.green);
        } else if (successCount > 0) {
          _showSnackBar('$successCount of $totalCount links sent successfully', Colors.orange);
        } else {
          _showSnackBar('Failed to send payment links', Colors.red);
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isProcessing = false;
        });
        _showSnackBar('Error sending payment links: $e', Colors.red);
      }
    }
  }

  Widget _buildResultCard(String title, String value, Color color) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(12.0),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: color.withOpacity(0.3)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              value,
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: color,
                fontFamily: "Inter",
              ),
            ),
            const SizedBox(height: 4),
            Text(
              title,
              style: const TextStyle(
                fontSize: 12,
                color: Colors.grey,
                fontFamily: "Inter",
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatCard(String title, String value, IconData icon, Color color) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(8.0),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(6),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: color, size: 16),
            const SizedBox(height: 4),
            Text(
              value,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: color,
                fontFamily: "Inter",
              ),
            ),
            Text(
              title,
              style: const TextStyle(
                fontSize: 10,
                color: Colors.grey,
                fontFamily: "Inter",
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMiniStatCard(String title, String value, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            value,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: color,
              fontFamily: "Inter",
            ),
          ),
          Text(
            title,
            style: const TextStyle(
              fontSize: 10,
              color: Colors.grey,
              fontFamily: "Inter",
            ),
          ),
        ],
      ),
    );
  }

  void _showSnackBar(String message, Color color) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          message,
          style: const TextStyle(
            fontFamily: "Inter",
            fontWeight: FontWeight.w500,
          ),
        ),
        backgroundColor: color,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
        margin: const EdgeInsets.all(16),
      ),
    );
  }
}