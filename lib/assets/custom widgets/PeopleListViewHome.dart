import 'package:flutter/material.dart';
import 'package:pmj_application/models/donation_model.dart';
import 'package:pmj_application/services/local_database_service.dart';

class PeopleListViewHome extends StatefulWidget {
  final Function(Donation)? onTap;
  final String searchQuery;

  const PeopleListViewHome({
    Key? key,
    this.onTap,
    this.searchQuery = '',
  }) : super(key: key);

  @override
  _PeopleListViewHomeState createState() => _PeopleListViewHomeState();
}

class _PeopleListViewHomeState extends State<PeopleListViewHome> {
  final LocalDatabaseService _localDb = LocalDatabaseService();

  @override
  void initState() {
    super.initState();
    // Initial sync with Firestore
    _localDb.syncWithFirestore().catchError((error) {
      // Handle error silently - we'll still show cached data
      debugPrint('Error syncing with Firestore: $error');
    });
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<Donation>>(
      stream: _localDb.watchDonations(query: widget.searchQuery),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (snapshot.hasError) {
          return Center(
            child: Text('Error loading donations: ${snapshot.error}'),
          );
        }

        final donations = snapshot.data ?? [];

        if (donations.isEmpty) {
          return const Center(
            child: Text('No donations found'),
          );
        }

        return ListView.builder(
          shrinkWrap: true,
          physics: const BouncingScrollPhysics(),
          itemCount: donations.length,
          itemBuilder: (context, index) {
            final donation = donations[index];
            return _buildDonationTile(donation);
          },
        );
      },
    );
  }

  Widget _buildDonationTile(Donation donation) {
    String formattedDate = donation.date.isNotEmpty ? '${donation.date} • ' : '';
    String monthYear = '${donation.month} ${donation.year}';

    return ListTile(
      onTap: widget.onTap != null ? () => widget.onTap!(donation) : null,
      leading:           CircleAvatar(
        radius: 20,
        backgroundColor: const Color(0xff1BA3A1),
        child: Text(
          donation.name.isNotEmpty ? donation.name[0].toUpperCase() : '',
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: Colors.white,
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
  }
}