
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'dart:ui' as ui; // Import for ui.ImageByteFormat
import 'dart:io';
import 'package:flutter/rendering.dart'; // Import for RenderRepaintBoundary
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../providers/payment_history_provider.dart';
import '../providers/donor_auth_provider.dart';
import '../widgets/donor_shimmer_widgets.dart';
import '../widgets/donor_app_bar.dart';
import '../widgets/donor_sub_header.dart';
import '../../models/donation_model.dart';

/// Payment history screen for donors to view all their donations
class PaymentHistoryScreen extends StatefulWidget {
  const PaymentHistoryScreen({super.key});

  @override
  State<PaymentHistoryScreen> createState() => _PaymentHistoryScreenState();
}

class _PaymentHistoryScreenState extends State<PaymentHistoryScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadPaymentHistory();
    });
  }

  Future<void> _loadPaymentHistory() async {
    try {
      final authProvider = Provider.of<DonorAuthProvider>(context, listen: false);
      final paymentProvider = Provider.of<PaymentHistoryProvider>(context, listen: false);
      
      debugPrint('Loading payment history...');
      debugPrint('Auth user: ${authProvider.currentUser?.uid}');
      debugPrint('Donor user: ${authProvider.donorUser?.userId}');
      debugPrint('Donor ID: ${authProvider.donorUser?.donorId}');
      
      if (authProvider.donorUser?.donorId != null) {
        debugPrint('Calling loadPaymentHistory with donorId: ${authProvider.donorUser!.donorId}');
        await paymentProvider.loadPaymentHistory(authProvider.donorUser!.donorId);
        debugPrint('Payment history loaded. Count: ${paymentProvider.filteredPayments.length}');
      } else {
        debugPrint('ERROR: Donor ID is null!');
        // Show error to user
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Unable to load payment history. Please try logging in again.'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    } catch (e) {
      debugPrint('Error in _loadPaymentHistory: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: const DonorAppBar(),
      body: Consumer<PaymentHistoryProvider>(
        builder: (context, provider, child) {
          if (provider.isLoading) {
            return const SingleChildScrollView(
              padding: EdgeInsets.all(16),
              child: Column(
                children: [
                  PaymentHistoryFiltersShimmer(),
                  SizedBox(height: 24),
                  PaymentHistoryListShimmer(),
                ],
              ),
            );
          }

          if (provider.errorMessage != null) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.error_outline, size: 60, color: Colors.red),
                  const SizedBox(height: 16),
                  Text(
                    provider.errorMessage!,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontSize: 14,
                      color: Colors.red,
                      fontFamily: "Inter",
                    ),
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () {
                      final user = Provider.of<DonorAuthProvider>(context, listen: false).donorUser;
                      if (user != null) {
                        Provider.of<PaymentHistoryProvider>(context, listen: false).loadPaymentHistory(user.donorId);
                      }
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xff1BA3A1),
                    ),
                    child: const Text('Retry'),
                  ),
                ],
              ),
            );
          }

          return Column(
            children: [
              DonorSubHeader(
                title: 'Payment History',
                trailing: IconButton(
                  icon: const Icon(Icons.filter_list, color: Color(0xff1BA3A1)),
                  onPressed: () => _showFilterBottomSheet(),
                ),
              ),
              Expanded(
                child: RefreshIndicator(
                  onRefresh: () async {
                    final user = Provider.of<DonorAuthProvider>(context, listen: false).donorUser;
                    if (user != null) {
                      await Provider.of<PaymentHistoryProvider>(context, listen: false).loadPaymentHistory(user.donorId);
                    }
                  },
                  color: const Color(0xff1BA3A1),
                  child: SingleChildScrollView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    child: Column(
                      children: [
                        // Summary Statistics
                        _buildSummarySection(provider),
                        
                        // Active Filters
                        if (_hasActiveFilters(provider))
                          _buildActiveFiltersChips(provider),
                        
                        // Payment List
                        if (provider.filteredPayments.isEmpty)
                          _buildEmptyState()
                        else
                          _buildPaymentList(provider),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  /// Build summary statistics section
  Widget _buildSummarySection(PaymentHistoryProvider provider) {
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xff1BA3A1).withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xff1BA3A1).withOpacity(0.3)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _buildStatCard(
            'Total Paid',
            '₹${provider.totalAmountThisYear.toStringAsFixed(0)}',
            Icons.payments_outlined,
          ),
          Container(width: 1, height: 50, color: Colors.grey[300]),
          _buildStatCard(
            'Payments',
            provider.totalPaymentsCount.toString(),
            Icons.receipt_long_outlined,
          ),
          Container(width: 1, height: 50, color: Colors.grey[300]),
          _buildStatCard(
            'Streak',
            '${provider.currentStreak} months',
            Icons.local_fire_department_outlined,
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard(String label, String value, IconData icon) {
    return Column(
      children: [
        Icon(icon, color: const Color(0xff1BA3A1), size: 24),
        const SizedBox(height: 8),
        Text(
          value,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            fontFamily: "Inter",
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: TextStyle(
            fontSize: 10,
            color: Colors.grey[600],
            fontFamily: "Inter",
          ),
        ),
      ],
    );
  }

  /// Build active filters chips
  Widget _buildActiveFiltersChips(PaymentHistoryProvider provider) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Wrap(
        spacing: 8,
        runSpacing: 8,
        children: [
          if (provider.selectedYear != null)
            _buildFilterChip(
              'Year: ${provider.selectedYear}',
              () => provider.setYearFilter(null),
            ),
          if (provider.selectedMonth != null)
            _buildFilterChip(
              'Month: ${provider.selectedMonth}',
              () => provider.setMonthFilter(null),
            ),
          if (provider.selectedStatus != 'All')
            _buildFilterChip(
              'Status: ${provider.selectedStatus}',
              () => provider.setStatusFilter('All'),
            ),
          if (provider.selectedMethod != 'All')
            _buildFilterChip(
              'Method: ${provider.selectedMethod}',
              () => provider.setMethodFilter('All'),
            ),
          if (_hasActiveFilters(provider))
            TextButton.icon(
              onPressed: () => provider.clearFilters(),
              icon: const Icon(Icons.clear_all, size: 16),
              label: const Text('Clear All'),
              style: TextButton.styleFrom(
                foregroundColor: const Color(0xff1BA3A1),
                padding: const EdgeInsets.symmetric(horizontal: 8),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildFilterChip(String label, VoidCallback onDelete) {
    return Chip(
      label: Text(
        label,
        style: const TextStyle(fontSize: 12, fontFamily: "Inter"),
      ),
      deleteIcon: const Icon(Icons.close, size: 16),
      onDeleted: onDelete,
      backgroundColor: const Color(0xff1BA3A1).withOpacity(0.1),
      deleteIconColor: const Color(0xff1BA3A1),
    );
  }

  bool _hasActiveFilters(PaymentHistoryProvider provider) {
    return provider.selectedYear != null ||
        provider.selectedMonth != null ||
        provider.selectedStatus != 'All' ||
        provider.selectedMethod != 'All';
  }

  /// Build payment list
  Widget _buildPaymentList(PaymentHistoryProvider provider) {
    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      padding: const EdgeInsets.symmetric(horizontal: 16),
      itemCount: provider.filteredPayments.length,
      itemBuilder: (context, index) {
        final payment = provider.filteredPayments[index];
        return _buildPaymentCard(payment);
      },
    );
  }

  /// Build individual payment card
  Widget _buildPaymentCard(Donation payment) {
    final isPaid = payment.status == 'paid' || payment.status == 'approved';
    
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: isPaid ? const Color(0xff66BB6A) : const Color(0xffF44336),
          width: 1,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                // Month & Year
                Text(
                  payment.monthsList != null && payment.monthsList!.isNotEmpty
                      ? (payment.monthsList!.length > 1 
                          ? '${payment.monthsList!.first} - ${payment.monthsList!.last}'
                          : payment.monthsList!.first)
                      : '${payment.month} ${payment.year}',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    fontFamily: "Inter",
                  ),
                ),
                // Status Badge
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                  decoration: BoxDecoration(
                    color: isPaid
                        ? const Color(0xff66BB6A).withOpacity(0.2)
                        : const Color(0xffF44336).withOpacity(0.2),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    isPaid ? 'PAID' : 'PENDING',
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                      color: isPaid ? const Color(0xff66BB6A) : const Color(0xffF44336),
                      fontFamily: "Inter",
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            // Amount
            Row(
              children: [
                const Icon(Icons.currency_rupee, size: 20, color: Colors.grey),
                const SizedBox(width: 4),
                Text(
                  payment.amount.toStringAsFixed(0),
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    fontFamily: "Inter",
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            // Payment Details
            Row(
              children: [
                _buildDetailItem(Icons.calendar_today, payment.date),
                const SizedBox(width: 16),
                _buildDetailItem(Icons.payment, payment.method),
              ],
            ),
            if (isPaid) ...[
              const SizedBox(height: 12),
              // Download Receipt Button
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: () => _downloadReceipt(payment),
                  icon: const Icon(Icons.download, size: 18),
                  label: const Text('Download Receipt'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: const Color(0xff1BA3A1),
                    side: const BorderSide(color: Color(0xff1BA3A1)),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildDetailItem(IconData icon, String text) {
    return Row(
      children: [
        Icon(icon, size: 14, color: Colors.grey),
        const SizedBox(width: 4),
        Text(
          text,
          style: TextStyle(
            fontSize: 12,
            color: Colors.grey[700],
            fontFamily: "Inter",
          ),
        ),
      ],
    );
  }

  /// Build empty state
  Widget _buildEmptyState() {
    return Container(
      padding: const EdgeInsets.all(40),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.receipt_long_outlined,
            size: 80,
            color: Colors.grey[300],
          ),
          const SizedBox(height: 16),
          Text(
            'No payments found',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: Colors.grey[600],
              fontFamily: "Inter",
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Your payment history will appear here',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey[500],
              fontFamily: "Inter",
            ),
          ),
        ],
      ),
    );
  }

  /// Show filter bottom sheet
  void _showFilterBottomSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Consumer<PaymentHistoryProvider>(
        builder: (context, provider, child) {
          return Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Filter Payments',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    fontFamily: "Inter",
                  ),
                ),
                const SizedBox(height: 24),
                
                // Year Filter
                _buildFilterDropdown(
                  'Year',
                  provider.selectedYear,
                  ['All', ...provider.getAvailableYears()],
                  (value) => provider.setYearFilter(value == 'All' ? null : value),
                ),
                
                const SizedBox(height: 16),
                
                // Month Filter
                _buildFilterDropdown(
                  'Month',
                  provider.selectedMonth,
                  ['All', ...provider.getAvailableMonths()],
                  (value) => provider.setMonthFilter(value == 'All' ? null : value),
                ),
                
                const SizedBox(height: 16),
                
                // Status Filter
                _buildFilterDropdown(
                  'Status',
                  provider.selectedStatus,
                  ['All', 'Paid', 'Pending'],
                  (value) => provider.setStatusFilter(value!),
                ),
                
                const SizedBox(height: 16),
                
                // Method Filter
                _buildFilterDropdown(
                  'Payment Method',
                  provider.selectedMethod,
                  ['All', 'Cash', 'UPI', 'Bank Transfer'],
                  (value) => provider.setMethodFilter(value!),
                ),
                
                const SizedBox(height: 24),
                
                // Buttons
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () {
                          provider.clearFilters();
                          Navigator.pop(context);
                        },
                        child: const Text('Clear All'),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () => Navigator.pop(context),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xff1BA3A1),
                        ),
                        child: const Text('Apply'),
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
  }

  Widget _buildFilterDropdown(
    String label,
    String? value,
    List<String> items,
    Function(String?) onChanged,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            fontFamily: "Inter",
          ),
        ),
        const SizedBox(height: 8),
        DropdownButtonFormField<String>(
          value: value ?? 'All',
          decoration: InputDecoration(
            contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: const BorderSide(color: Color(0xff1BA3A1)),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(color: Colors.grey[300]!),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: const BorderSide(color: Color(0xff1BA3A1)),
            ),
          ),
          items: items.map((item) {
            return DropdownMenuItem(
              value: item,
              child: Text(
                item,
                style: const TextStyle(fontSize: 14, fontFamily: "Inter"),
              ),
            );
          }).toList(),
          onChanged: onChanged,
        ),
      ],
    );
  }

  /// Download receipt for a payment
  Future<void> _downloadReceipt(Donation payment) async {
    // Show initial loading dialog
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => Dialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: Container(
          padding: const EdgeInsets.all(24.0),
          constraints: const BoxConstraints(maxWidth: 300),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(Color(0xff1BA3A1)),
                strokeWidth: 3,
              ),
              const SizedBox(height: 24),
              Text(
                'Generating Receipt...',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: Colors.grey[800],
                  fontFamily: 'Inter',
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Please wait while we prepare your receipt',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey[600],
                  fontFamily: 'Inter',
                ),
              ),
            ],
          ),
        ),
      ),
    );

    try {
      // Get donor information
      final authProvider = Provider.of<DonorAuthProvider>(context, listen: false);
      final donorId = authProvider.donorUser?.donorId;
      
      if (donorId == null) {
        throw Exception('Donor ID not found');
      }

      // Fetch donor details from Firestore
      final donorDoc = await FirebaseFirestore.instance
          .collection('donors')
          .doc(donorId)
          .get();

      if (!donorDoc.exists) {
        throw Exception('Donor information not found');
      }

      final donorData = donorDoc.data()!;
      final donorName = donorData['name'] ?? 'Unknown';
      final donorAddress = donorData['address'] ?? '';
      
      // Close loading dialog
      if (mounted) {
        Navigator.of(context, rootNavigator: true).pop();
      }
      
      // Generate and save the receipt image using the same approach as admin module
      final String imagePath = await _generateAndSaveImage(payment, donorName, donorAddress, donorId);
      
      if (mounted) {
        // Show success message and sharing options
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Receipt generated successfully!'),
            backgroundColor: Color(0xFF41c057),
          ),
        );
        
        // Offer sharing option
        await Share.shareXFiles(
          [XFile(imagePath)],
          text: 'Payment Receipt - ${payment.month} ${payment.year}',
        );
      }
      
    } catch (e) {
      // Close any open dialogs
      if (mounted && Navigator.canPop(context)) {
        Navigator.of(context, rootNavigator: true).pop();
      }
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error generating receipt: $e')),
        );
      }
    }
  }
  
  /// Generate and save receipt image using the same approach as admin module
  Future<String> _generateAndSaveImage(Donation payment, String donorName, String donorAddress, String donorId) async {
    // Create a GlobalKey to capture the widget
    final GlobalKey receiptKey = GlobalKey();

    // Show the receipt in an overlay to render it (same approach as admin module)
    final overlay = Overlay.of(context);
    if (overlay == null) {
      throw Exception('Could not access overlay');
    }
    
    late OverlayEntry overlayEntry;

    overlayEntry = OverlayEntry(
      builder: (context) => Positioned(
        left: -10000, // Position off-screen
        top: -10000,
        child: Material(
          color: Colors.transparent,
          child: RepaintBoundary(
            key: receiptKey,
            child: _buildReceiptWidget(payment, donorName, donorAddress, donorId),
          ),
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
      final imageFile = File(
          '${tempDir.path}/PMJ_Receipt_${payment.month}_${payment.year}_${DateTime.now().millisecondsSinceEpoch}.png');
      await imageFile.writeAsBytes(bytes);

      return imageFile.path;
    } finally {
      // Remove the overlay entry
      overlayEntry.remove();
    }
  }
  
  // Helper to build the receipt widget
  Widget _buildReceiptWidget(Donation payment, String donorName, String donorAddress, String donorId) {
    return Center(
      child: Container(
        constraints: const BoxConstraints(maxWidth: 420),
        decoration: BoxDecoration(
          color: Colors.white,
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
                  const Text(
                    'PMJ Monthly Donation Receipt',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 0.2,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Receipt No: $donorId',
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

            // Receipt Details
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 28),
              child: Column(
                children: [
                  _buildReceiptRow('Date:', payment.date),
                  const SizedBox(height: 8),
                  _buildReceiptRow('Name:', donorName),
                  const SizedBox(height: 8),
                  _buildReceiptRow('Donor ID:', donorId),
                  const SizedBox(height: 8),
                  _buildReceiptRow(
                    'Month:',
                    payment.monthsList != null && payment.monthsList!.isNotEmpty
                        ? (payment.monthsList!.length > 1 
                            ? '${payment.monthsList!.first} - ${payment.monthsList!.last}'
                            : payment.monthsList!.first)
                        : '${payment.month} ${payment.year}',
                  ),
                  const SizedBox(height: 8),
                  _buildReceiptRow(
                    'Amount',
                    '₹${payment.amount.toStringAsFixed(0)}/-',
                    isAmount: true,
                  ),
                  const SizedBox(height: 8),
                  _buildReceiptRow('Payment Method:', payment.method),
                  const SizedBox(height: 18),
                ],
              ),
            ),

            // Amount in Words Container
            Container(
              width: double.infinity,
              margin: const EdgeInsets.symmetric(horizontal: 28),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                color: const Color(0xFFeafbe7),
                borderRadius: BorderRadius.zero,
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
                    _numberToWords(payment.amount),
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
            const Text(
              'Thank you for your donation!',
              style: TextStyle(
                color: Color(0xFF41c057),
                fontSize: 13,
                fontWeight: FontWeight.w600,
                fontStyle: FontStyle.italic,
                letterSpacing: 0.1,
              ),
            ),
            const SizedBox(height: 6),
            const Text(
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
            maxLines: 2,
          ),
        ),
      ],
    );
  }

  String _numberToWords(double number) {
    if (number == 0) return 'Zero Rupees Only';

    int wholeNumber = number.floor();
    int paise = ((number - wholeNumber) * 100).round();

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
      paiseText = ' and ${paise < 10 ? 'Zero ' : ''}${convertLessThanOneThousand(paise)} Paise';
    }

    return '${result.trim()} Rupees$paiseText Only';
  }
}














