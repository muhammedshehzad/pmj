import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import '../providers/donor_auth_provider.dart';
import '../../models/person_model.dart';
import '../../models/donation_model.dart';
import '../widgets/donor_shimmer_widgets.dart';
import '../widgets/donor_dialogs.dart';
import '../widgets/donor_app_bar.dart';

/// Donor dashboard showing payment status, donation summary, and quick actions
class DonorDashboardScreen extends StatefulWidget {
  const DonorDashboardScreen({super.key});

  @override
  State<DonorDashboardScreen> createState() => _DonorDashboardScreenState();
}

class _DonorDashboardScreenState extends State<DonorDashboardScreen> {
  bool _isLoading = true;
  Person? _donorProfile;
  Map<String, dynamic> _paymentStatus = {};
  List<Donation> _recentPayments = [];
  double _yearlyTotal = 0;
  int _paymentStreak = 0;
  DonorAuthProvider? _authProviderRef; // Store reference for safe disposal

  // List of Islamic quotes about charity
  final List<String> _charityQuotes = [
    '"The best of people are those that bring most benefit to the rest of mankind." (Hadith)',
    '"Charity does not decrease wealth." (Hadith)',
    '"Give charity without delay, for it stands in the way of calamity." (Hadith)',
    '"Those who spend in charity will be richly rewarded." (Quran 57:10)',
    '"A man\'s true wealth is the good he does in this world." (Hadith)',
    '"Save yourself from Hell-fire even by giving half a date-fruit in charity." (Hadith)',
    '"Spending in the way of Allah is a trade that will never fail." (Quran 35:29)',
    '"Allah is with those who do good." (Quran 29:69)',
    '"The believer\'s shade on the Day of Resurrection will be his charity." (Hadith)',
    '"Charity extinguishes sins like water extinguishes fire." (Hadith)',
    '"Who is it that would loan Allah a goodly loan so He may multiply it for him many times over?" (Quran 2:245)',
    '"You will not attain righteousness until you spend in charity of the things you love." (Quran 3:92)',
    '"Do not shut your money bag; otherwise Allah will also shut His money bag for you." (Hadith)',
    '"Every act of goodness is charity." (Hadith)',
    '"Allah is in the aid of His servant as long as the servant is in the aid of his brother." (Hadith)',
  ];

  late String _currentQuote;

  @override
  void initState() {
    super.initState();
    _currentQuote = _charityQuotes[DateTime.now().microsecond % _charityQuotes.length];
    
    // Listen to auth provider changes
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final authProvider = Provider.of<DonorAuthProvider>(context, listen: false);
      _authProviderRef = authProvider; // Store reference
      
      // Load data if already authenticated
      if (authProvider.donorUser != null) {
        _loadDonorData();
      }
      
      // Listen for auth changes
      authProvider.addListener(_onAuthChanged);
    });
  }
  
  @override
  void dispose() {
    // Safely remove listener using stored reference
    _authProviderRef?.removeListener(_onAuthChanged);
    _authProviderRef = null;
    super.dispose();
  }
  
  void _onAuthChanged() {
    final authProvider = Provider.of<DonorAuthProvider>(context, listen: false);
    debugPrint('DonorDashboard: Auth changed - donorUser: ${authProvider.donorUser?.donorId}');
    
    // Reload data when donor user becomes available
    if (authProvider.donorUser != null && mounted) {
      _loadDonorData();
    }
  }

  Future<void> _loadDonorData() async {
    final authProvider = Provider.of<DonorAuthProvider>(context, listen: false);
    
    debugPrint('DonorDashboard: Starting data load');
    debugPrint('DonorDashboard: donorUser = ${authProvider.donorUser?.donorId}');
    
    if (authProvider.donorUser == null) {
      debugPrint('DonorDashboard: donorUser is null, stopping load');
      setState(() => _isLoading = false);
      return;
    }

    setState(() => _isLoading = true);

    try {
      final donorId = authProvider.donorUser!.donorId;
      debugPrint('DonorDashboard: Loading data for donorId: $donorId');

      // Load donor profile
      final donorDoc = await FirebaseFirestore.instance
          .collection('donors')
          .doc(donorId)
          .get();

      debugPrint('DonorDashboard: Donor doc exists: ${donorDoc.exists}');
      if (donorDoc.exists) {
        _donorProfile = Person.fromFirestore(donorDoc);
        debugPrint('DonorDashboard: Loaded profile: ${_donorProfile?.name}');
      }

      // Load current month payment status
      final now = DateTime.now();
      final currentMonth = DateFormat('MMMM').format(now);
      final currentYear = now.year.toString();
      debugPrint('DonorDashboard: Current month/year: $currentMonth $currentYear');

      final paymentStatusDoc = await FirebaseFirestore.instance
          .collection('donors')
          .doc(donorId)
          .collection('paymentStatus')
          .where('month', isEqualTo: currentMonth)
          .where('year', isEqualTo: currentYear)
          .limit(1)
          .get();

      debugPrint('DonorDashboard: Payment status docs found: ${paymentStatusDoc.docs.length}');
      if (paymentStatusDoc.docs.isNotEmpty) {
        _paymentStatus = paymentStatusDoc.docs.first.data();
        debugPrint('DonorDashboard: Payment status: $_paymentStatus');
      }

      // Load recent payments (last 5) - without orderBy to avoid index requirement
      final paymentsSnapshot = await FirebaseFirestore.instance
          .collection('donations')
          .where('donorId', isEqualTo: donorId)
          .get();

      debugPrint('DonorDashboard: Found ${paymentsSnapshot.docs.length} total donations');
      _recentPayments = paymentsSnapshot.docs
          .map((doc) {
            debugPrint('DonorDashboard: Donation doc data: ${doc.data()}');
            return Donation.fromFirestore(doc.data());
          })
          .toList();
      
      // Sort in memory and take last 5
      _recentPayments.sort((a, b) {
        // Parse dates for comparison (assuming format like "17 Nov 2025")
        try {
          final aDate = DateFormat('dd MMM yyyy').parse(a.date);
          final bDate = DateFormat('dd MMM yyyy').parse(b.date);
          return bDate.compareTo(aDate); // Most recent first
        } catch (e) {
          return 0;
        }
      });
      _recentPayments = _recentPayments.take(5).toList();
      debugPrint('DonorDashboard: Recent payments count: ${_recentPayments.length}');

      // Calculate yearly total
      final yearlySnapshot = await FirebaseFirestore.instance
          .collection('donations')
          .where('donorId', isEqualTo: donorId)
          .where('year', isEqualTo: currentYear)
          .get();

      debugPrint('DonorDashboard: Yearly donations found: ${yearlySnapshot.docs.length}');
      _yearlyTotal = yearlySnapshot.docs.fold(
        0.0,
        (sum, doc) {
          final data = doc.data();
          final status = data['status'] as String? ?? '';
          // Only count if status is paid or approved
          if (status == 'paid' || status == 'approved') {
            final amount = (data['amount'] as num?)?.toDouble() ?? 0;
            debugPrint('DonorDashboard: Adding amount: $amount');
            return sum + amount;
          }
          return sum;
        },
      );
      debugPrint('DonorDashboard: Yearly total: $_yearlyTotal');

      // Calculate payment streak (consecutive months paid)
      _paymentStreak = await _calculatePaymentStreak(donorId);
      debugPrint('DonorDashboard: Payment streak: $_paymentStreak');

      setState(() => _isLoading = false);
      debugPrint('DonorDashboard: Data load complete');
    } catch (e) {
      debugPrint('DonorDashboard ERROR: $e');
      debugPrint('DonorDashboard ERROR Stack: ${StackTrace.current}');
      setState(() => _isLoading = false);
    }
  }

  Future<int> _calculatePaymentStreak(String donorId) async {
    int streak = 0;
    final now = DateTime.now();
    
    // We need to fetch all donations for the donor to accurately calculate streak with multi-month receipts
    final donationsSnapshot = await FirebaseFirestore.instance
        .collection('donations')
        .where('donorId', isEqualTo: donorId)
        .where('status', whereIn: ['paid', 'approved'])
        .get();

    final paidMonths = <DateTime>{};
    for (final doc in donationsSnapshot.docs) {
      final data = doc.data();
      final monthsList = data['monthsList'] as List<dynamic>?;
      if (monthsList != null && monthsList.isNotEmpty) {
        for (final monthStr in monthsList) {
          try {
            final date = DateFormat('MMMM yyyy').parse(monthStr as String);
            paidMonths.add(DateTime(date.year, date.month));
          } catch (e) {
            debugPrint('Error parsing month string: $monthStr');
          }
        }
      } else {
        final month = data['month'] as String?;
        final year = data['year'] as String?;
        if (month != null && year != null) {
          try {
            final monthIndex = _monthToNumber(month);
            paidMonths.add(DateTime(int.parse(year), monthIndex));
          } catch (e) {
            debugPrint('Error parsing month/year: $month $year');
          }
        }
      }
    }

    DateTime checkDate = DateTime(now.year, now.month, 1);
    
    for (int i = 0; i < 36; i++) { // Check up to 3 years back
      final found = paidMonths.any((d) => d.year == checkDate.year && d.month == checkDate.month);
      
      if (found) {
        streak++;
        checkDate = DateTime(checkDate.year, checkDate.month - 1, 1);
      } else {
        break;
      }
    }

    return streak;
  }

  int _monthToNumber(String month) {
    const months = {
      'January': 1, 'February': 2, 'March': 3, 'April': 4,
      'May': 5, 'June': 6, 'July': 7, 'August': 8,
      'September': 9, 'October': 10, 'November': 11, 'December': 12,
    };
    return months[month] ?? 1;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xffF5F5F5),
      appBar: DonorAppBar(
        actions: [
          Container(
            height: 26,
            width: 84,
            margin: const EdgeInsets.only(left: 12),
            child: ElevatedButton(
              onPressed: () => showDonorLogoutDialog(context),
              style: ElevatedButton.styleFrom(
                foregroundColor: Colors.black,
                backgroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(2)),
                elevation: 0,
                padding: EdgeInsets.zero,
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
      body: _isLoading
          ? SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 16),
                  const DonorDashboardStatsShimmer(),
                  const SizedBox(height: 24),
                  const DonorQuickActionsShimmer(),
                  const SizedBox(height: 24),
                  Container(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: const Text(
                      'Recent Payments',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        fontFamily: "Inter",
                      ),
                    ),
                  ),
                  const DonorRecentPaymentsShimmer(),
                ],
              ),
            )
          : RefreshIndicator(
              onRefresh: _loadDonorData,
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildWelcomeSection(),
                    const SizedBox(height: 24),
                    _buildPaymentStatusCard(),
                    const SizedBox(height: 16),
                    _buildStatsRow(),
                    const SizedBox(height: 24),
                    _buildQuickActions(),
                    const SizedBox(height: 24),
                    _buildRecentPayments(),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _buildWelcomeSection() {
    final name = _donorProfile?.name ?? 'Donor';
    final photoUrl = _donorProfile?.photoUrl;
    
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xff1BA3A1), Color(0xff159B99)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          Container(
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: Colors.white, width: 2),
            ),
            child: CircleAvatar(
              radius: 30,
              backgroundColor: Colors.white.withOpacity(0.2),
              backgroundImage: (photoUrl != null && photoUrl.isNotEmpty)
                  ? NetworkImage(photoUrl)
                  : null,
              child: (photoUrl == null || photoUrl.isEmpty)
                  ? const Icon(Icons.person, color: Colors.white, size: 30)
                  : null,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Welcome back,',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.white.withOpacity(0.9),
                    fontFamily: "Inter",
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  name,
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                    fontFamily: "Inter",
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                Text(
                  _currentQuote,
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.white.withOpacity(0.9),
                    fontFamily: "Inter",
                    fontStyle: FontStyle.italic,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPaymentStatusCard() {
    final now = DateTime.now();
    final currentMonth = DateFormat('MMMM').format(now);
    final isPaid = _paymentStatus['status'] == 'paid';
    final amount = _donorProfile?.amount ?? 0;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            spreadRadius: 1,
            blurRadius: 10,
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
                'This Month',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  fontFamily: "Inter",
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: isPaid ? Colors.green.withOpacity(0.1) : Colors.orange.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  children: [
                    Icon(
                      isPaid ? Icons.check_circle : Icons.pending,
                      size: 16,
                      color: isPaid ? Colors.green : Colors.orange,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      isPaid ? 'PAID' : 'PENDING',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: isPaid ? Colors.green : Colors.orange,
                        fontFamily: "Inter",
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            currentMonth,
            style: const TextStyle(
              fontSize: 14,
              color: Colors.grey,
              fontFamily: "Inter",
            ),
          ),
          const SizedBox(height: 8),
          Text(
            '₹${amount.toStringAsFixed(0)}',
            style: const TextStyle(
              fontSize: 32,
              fontWeight: FontWeight.bold,
              color: Color(0xff1BA3A1),
              fontFamily: "Inter",
            ),
          ),
          if (!isPaid) ...[
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () async {
                  final result = await Navigator.pushNamed(context, '/donor/payment-submission');
                  // Refresh dashboard if payment was successful
                  if (result == true && mounted) {
                    _loadDonorData();
                  }
                },
                icon: const Icon(Icons.payment, size: 20),
                label: const Text('Pay Now'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xff1BA3A1),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildStatsRow() {
    return Row(
      children: [
        Expanded(
          child: _buildStatCard(
            'This Year',
            '₹${_yearlyTotal.toStringAsFixed(0)}',
            Icons.calendar_today,
            Colors.blue,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _buildStatCard(
            'Streak',
            '$_paymentStreak ${_paymentStreak == 1 ? 'Month' : 'Months'}',
            Icons.local_fire_department,
            Colors.orange,
          ),
        ),
      ],
    );
  }

  Widget _buildStatCard(String label, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            spreadRadius: 1,
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color, size: 24),
          const SizedBox(height: 12),
          Text(
            label,
            style: const TextStyle(
              fontSize: 12,
              color: Colors.grey,
              fontFamily: "Inter",
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              fontFamily: "Inter",
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickActions() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Quick Actions',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            fontFamily: "Inter",
          ),
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _buildActionButton(
                'Payment History',
                Icons.history,
                () => Navigator.pushNamed(context, '/donor/payment-history'),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildActionButton(
                'My Profile',
                Icons.person,
                () => Navigator.pushNamed(context, '/donor/profile'),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildActionButton(String label, IconData icon, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.grey[200]!),
        ),
        child: Column(
          children: [
            Icon(icon, color: const Color(0xff1BA3A1), size: 28),
            const SizedBox(height: 8),
            Text(
              label,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w500,
                fontFamily: "Inter",
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRecentPayments() {
    if (_recentPayments.isEmpty) {
      return const SizedBox.shrink();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Recent Payments',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            fontFamily: "Inter",
          ),
        ),
        const SizedBox(height: 12),
        Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
          ),
          child: ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: _recentPayments.length,
            separatorBuilder: (context, index) => const Divider(height: 1),
            itemBuilder: (context, index) {
              final payment = _recentPayments[index];
              return ListTile(
                leading: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.green.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(
                    Icons.check_circle,
                    color: Colors.green,
                    size: 20,
                  ),
                ),
                title: Text(
                  payment.monthsList != null && payment.monthsList!.isNotEmpty
                      ? (payment.monthsList!.length > 1 
                          ? '${payment.monthsList!.first} - ${payment.monthsList!.last}'
                          : payment.monthsList!.first)
                      : '${payment.month} ${payment.year}',
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    fontFamily: "Inter",
                  ),
                ),
                subtitle: Text(
                  payment.date,
                  style: const TextStyle(
                    fontSize: 12,
                    color: Colors.grey,
                    fontFamily: "Inter",
                  ),
                ),
                trailing: Text(
                  '₹${payment.amount}',
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: Color(0xff1BA3A1),
                    fontFamily: "Inter",
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}
