import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import '../assets/custom widgets/PeopleListViewHome.dart';
import '../assets/custom widgets/logoutpopup.dart';

class AllDonationsPage extends StatelessWidget {
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
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(
              child: CircularProgressIndicator(
            color: Color(0xff1BA3A1),
          ));
        }

        if (snapshot.hasError) {
          return Center(child: Text('Error: ${snapshot.error}'));
        }

        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return const Center(child: Text('No donations found'));
        }

        return FutureBuilder<List<personHome>>(
          future: _buildPersonHomeList(snapshot.data!.docs),
          builder: (context, futureSnapshot) {
            if (futureSnapshot.hasError) {
              return Center(child: Text('Error: ${futureSnapshot.error}'));
            }

            if (futureSnapshot.connectionState == ConnectionState.done &&
                (!futureSnapshot.hasData || futureSnapshot.data!.isEmpty)) {
              return const Center(child: Text('No donations found'));
            }

            if (futureSnapshot.connectionState != ConnectionState.done) {
              return const Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    CircularProgressIndicator(
                      color: Color(0xff1BA3A1),
                    ),
                    SizedBox(height: 16),
                    Text(
                      'Loading donations...',
                      style: TextStyle(
                        fontFamily: "Inter",
                        color: Color(0xff1BA3A1),
                      ),
                    ),
                  ],
                ),
              );
            }

            // Build the list with dismissible items
            return ListView.builder(
              itemCount: futureSnapshot.data!.length,
              itemBuilder: (context, index) {
                final person = futureSnapshot.data![index];
                final doc = snapshot.data!.docs[index];

                return Dismissible(
                  key: Key(person.documentPath ??
                      '${person.donorId}_${person.date}_${person.amount}'),
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
                      await FirebaseFirestore.instance
                          .doc(doc.reference.path)
                          .delete();
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Donation deleted successfully'),
                          backgroundColor: Color(0xff1BA3A1),
                        ),
                      );
                    } catch (e) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('Error deleting donation: $e'),
                          backgroundColor: Colors.red,
                        ),
                      );
                    }
                  },
                  child: PeopleListViewHome(peoplesHome: [
                    person
                  ]), // Pass single item to maintain design
                );
              },
            );
          },
        );
      },
    );
  }

  Future<List<personHome>> _buildPersonHomeList(
      List<QueryDocumentSnapshot> docs) async {
    List<personHome> personHomeList = [];
    for (var doc in docs) {
      final data = doc.data() as Map<String, dynamic>;
      final donorId = doc.reference.parent.parent?.id;

      if (donorId == null || donorId.isEmpty) {
        continue;
      }

      final donorSnapshot = await FirebaseFirestore.instance
          .collection('donors')
          .doc(donorId)
          .get();

      if (!donorSnapshot.exists) {
        continue;
      }

      final donorData = donorSnapshot.data() as Map<String, dynamic>;
      final donorName = donorData['name'] ?? 'Unknown';

      personHomeList.add(
        personHome(
          name: donorName,
          date: _formatTimestamp(data['timestamp']),
          amount: (data['amount'] as num?)?.toInt() ?? 0,
          donorId: donorId,
          method: data['paymentMethod'] ?? 'Unknown',
          month: data['month'] ?? 'Unknown',
          year: data['year'] ?? 'Unknown',
          status: data['status'] ?? 'Unpaid',
          documentPath: doc.reference.path, // Store document path for deletion
        ),
      );
    }
    return personHomeList;
  }

  String _formatTimestamp(Timestamp? timestamp) {
    if (timestamp == null) return "Unknown Date";
    final date = timestamp.toDate();
    return "${date.day.toString().padLeft(2, '0')}.${date.month.toString().padLeft(2, '0')}.${date.year}";
  }

  Future<bool> _showDeleteConfirmation(
      BuildContext context, personHome person) async {
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
          actions: [
            Container(
              height: 26,
              width: 72,
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
                    fontSize: 7,
                  ),
                ),
                onPressed: () {
                  Navigator.of(dialogContext).pop(false);
                },
              ),
            ),
            Container(
              height: 26,
              width: 72,
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
                    fontSize: 7,
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
    ) ??
        false;
  }}
