import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:shimmer/shimmer.dart';
import 'package:intl/intl.dart';
import '../models/donation_model.dart';
import '../models/person_model.dart';
import '../services/image_cache_service.dart';
import '../utils/month_formatter.dart';
import '../assets/custom%20widgets/shimmer_widgets.dart';

class DeletionHistoryPage extends StatefulWidget {
  @override
  _DeletionHistoryPageState createState() => _DeletionHistoryPageState();
}

class _DeletionHistoryPageState extends State<DeletionHistoryPage> {
  List<Person> _deletedDonations = [];
  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _fetchDeletedDonations();
  }

  Future<void> _fetchDeletedDonations() async {
    try {
      setState(() {
        _isLoading = true;
        _errorMessage = null;
      });

      final snapshot = await FirebaseFirestore.instance
          .collection('deleted_donations')
          .orderBy('deletedAt', descending: true)
          .get();

      List<Person> deletedItems = [];
      for (var doc in snapshot.docs) {
        final data = doc.data();
        deletedItems.add(Person(
          name: data['name'] ?? 'Unknown',
          house: data['house'] ?? 'Unknown',
          photoUrl: data['photoUrl'] ?? '',
          amount: _parseAmount(data['amount']).toDouble(),
          date: data['date'] ?? 'Unknown',
          month: data['month'] ?? 'Unknown',
          year: data['year'] ?? 'Unknown',
          method: data['method'] ?? 'Unknown',
          status: data['status'] ?? 'Deleted',
          donorId: data['donorId'] ?? '',
          documentPath: data['originalDocumentPath'] ?? '',
          imageUrl: data['imageUrl'] ?? '',
          monthsList: data['monthsList'] != null ? List<String>.from(data['monthsList']) : null,
          totalDonationAmount: (data['totalDonationAmount'] as num?)?.toDouble(),
          timestamp: data['timestamp'] != null 
              ? (data['timestamp'] as Timestamp).toDate() 
              : null,
        ));
      }

      setState(() {
        _deletedDonations = deletedItems;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = 'Failed to load deletion history: ${e.toString()}';
        _isLoading = false;
      });
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
          return 0;
        }
      }
    }
    return 0;
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
                  // Container(
                  //   height: 26,
                  //   width: 84,
                  //   child: ElevatedButton(
                  //     onPressed: () => Navigator.pop(context),
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
                  //         'Back',
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
                  "Deletion History",
                  style: TextStyle(
                    fontSize: 16,
                    fontFamily: "Inter",
                    fontWeight: FontWeight.w600,
                    color: Color(0xff1BA3A1),
                  ),
                ),
                const SizedBox(width: 40), // For balance
              ],
            ),
            const SizedBox(height: 16),
            Expanded(
              child: _buildHistoryList(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHistoryList() {
    if (_isLoading) {
      return _buildShimmerLoading();
    }

    if (_errorMessage != null) {
      return _buildErrorUI();
    }

    if (_deletedDonations.isEmpty) {
      return _buildEmptyStateUI();
    }

    return ListView.builder(
      itemCount: _deletedDonations.length,
      itemBuilder: (context, index) {
        final person = _deletedDonations[index];
        return _DeletionHistoryTile(person: person);
      },
    );
  }

  Widget _buildShimmerLoading() {
    return DeletionHistoryShimmer();
  }

  Widget _buildErrorUI() {
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
                color: Colors.red.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.error_outline,
                color: Colors.red,
                size: 48,
              ),
            ),
            const SizedBox(height: 24),
            const Text(
              'Error Loading History',
              style: TextStyle(
                fontFamily: "Inter",
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: Colors.red,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 12),
            Text(
              _errorMessage ?? 'An unexpected error occurred',
              style: const TextStyle(
                fontFamily: "Inter",
                fontSize: 14,
                color: Colors.grey,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: _fetchDeletedDonations,
              icon: const Icon(Icons.refresh, size: 18),
              label: const Text(
                'Retry',
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
              Icons.history,
              size: 60,
              color: Color(0xff1BA3A1),
            ),
          ),
          const SizedBox(height: 24),
          const Text(
            'No Deletion History',
            style: TextStyle(
              fontFamily: "Inter",
              fontSize: 20,
              fontWeight: FontWeight.w600,
              color: Color(0xff1BA3A1),
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'No donations have been deleted yet.',
            style: TextStyle(
              fontFamily: "Inter",
              fontSize: 14,
              color: Colors.grey,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: () => Navigator.pop(context),
            icon: const Icon(Icons.arrow_back, size: 18),
            label: const Text(
              'Go Back',
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
}

// Formats a timestamp into: dd MMM yyyy, hh:mm AM/PM
String _formatTimestampHistory(dynamic timestamp) {
  try {
    if (timestamp == null) return 'Unknown Date';

    DateTime date;
    if (timestamp is Timestamp) {
      date = timestamp.toDate();
    } else if (timestamp is DateTime) {
      date = timestamp;
    } else if (timestamp is String) {
      // Attempt to parse ISO 8601 strings
      date = DateTime.tryParse(timestamp) ?? DateTime.fromMillisecondsSinceEpoch(0);
      if (date.millisecondsSinceEpoch == 0) return timestamp; // fallback to raw if unparsable
    } else {
      return 'Unknown Date';
    }

    const monthNames = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
    ];
    final day = date.day.toString().padLeft(2, '0');
    final monthName = monthNames[(date.month - 1).clamp(0, 11)];
    final year = date.year.toString();
    final ampm = date.hour >= 12 ? 'PM' : 'AM';
    int h12 = date.hour % 12;
    if (h12 == 0) h12 = 12;
    final hour = h12.toString().padLeft(2, '0');
    final minute = date.minute.toString().padLeft(2, '0');
    return '$day $monthName $year, $hour:$minute $ampm';
  } catch (_) {
    return 'Unknown Date';
  }
}

class _DeletionHistoryTile extends StatelessWidget {
  final Person person;
  const _DeletionHistoryTile({required this.person});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 4.0, horizontal: 8.0),
      decoration: BoxDecoration(
        color: Colors.red.withOpacity(0.05),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: Colors.red.withOpacity(0.2),
          width: 1,
        ),
      ),
      child: ListTile(
        leading: _AvatarWithCache(person: person),
        title: Row(
          children: [
            Expanded(
              child: Text(
                person.name,
                style: const TextStyle(
                  fontSize: 14,
                  fontFamily: "Inter",
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                color: Colors.red.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: Colors.red.withOpacity(0.3),
                  width: 1,
                ),
              ),
              child: const Text(
                'DELETED',
                style: TextStyle(
                  fontSize: 8,
                  fontFamily: "Inter",
                  fontWeight: FontWeight.w600,
                  color: Colors.red,
                ),
              ),
            ),
          ],
        ),
        subtitle: Text(
          "${person.timestamp != null ? _formatTimestampHistory(person.timestamp) : (person.date ?? 'Unknown Date')} • ${person.monthsList != null && person.monthsList!.isNotEmpty ? MonthFormatter.formatMonthLong(person.monthsList!, person.year ?? '') : '${person.month} ${person.year}'}",
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
      ),
    );
  }
}

class _AvatarWithCache extends StatelessWidget {
  final Person person;
  const _AvatarWithCache({required this.person});

  @override
  Widget build(BuildContext context) {
    final effectiveUrl = (person.photoUrl != null && person.photoUrl!.isNotEmpty)
        ? person.photoUrl!
        : (person.imageUrl ?? '');

    if (effectiveUrl.isEmpty) {
      return CircleAvatar(
        radius: 20,
        backgroundColor: Colors.red.withOpacity(0.7),
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
            child: Stack(
              children: [
                AnimatedSwitcher(
                  duration: const Duration(milliseconds: 250),
                  child: Image(
                    key: ValueKey(effectiveUrl),
                    image: snapshot.data!,
                    width: 40,
                    height: 40,
                    fit: BoxFit.cover,
                  ),
                ),
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: Colors.red.withOpacity(0.2),
                    shape: BoxShape.circle,
                  ),
                ),
              ],
            ),
          );
        }

        // Fallback to initials
        return CircleAvatar(
          radius: 20,
          backgroundColor: Colors.red.withOpacity(0.7),
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
