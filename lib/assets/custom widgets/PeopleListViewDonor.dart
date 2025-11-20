import 'package:flutter/material.dart';
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:pmj_application/models/person_model.dart';
import 'package:pmj_application/secondary/donorDetails.dart';
import 'package:pmj_application/services/local_database_service.dart';
import 'package:shimmer/shimmer.dart';
import '../../services/image_cache_service.dart';
import '../../widgets/stable_avatar.dart';
import 'shimmer_widgets.dart';
import '../../secondary/donorDetails.dart';

class PeopleListViewDonor extends StatefulWidget {
  const PeopleListViewDonor({Key? key}) : super(key: key);

  @override
  _PeopleListViewDonorState createState() => _PeopleListViewDonorState();
}

class _PeopleListViewDonorState extends State<PeopleListViewDonor> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  final LocalDatabaseService _localDb = LocalDatabaseService();
  Timer? _searchDebounce;

  @override
  void initState() {
    super.initState();
    _searchController.addListener(() {
      final text = _searchController.text;
      _searchDebounce?.cancel();
      _searchDebounce = Timer(const Duration(milliseconds: 350), () {
        if (!mounted) return;
        setState(() {
          _searchQuery = text.trim().toLowerCase();
        });
      });
    });
    
    // Only sync with Firestore if needed to prevent unnecessary refreshes
    // The watchPeople stream will automatically update when data changes
    // This prevents forced refreshes on every tab switch
  }

  @override
  void dispose() {
    _searchDebounce?.cancel();
    _searchController.dispose();
    super.dispose();
  }

  Widget _buildProfileAvatar(Person person) {
    // Prefer photoUrl; if empty, fallback to imageUrl (legacy field)
    final effectivePhotoUrl =
        (person.photoUrl.isNotEmpty ? person.photoUrl : (person.imageUrl ?? ''));

    return StableAvatar(
      imageUrl: effectivePhotoUrl,
      name: person.name,
      radius: 25,
    );
  }

  Future<void> _refreshDonors() async {
    try {
      await _localDb.syncWithFirestore();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Donors refreshed successfully'),
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

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Column(
        children: [
          // Search Field
          Padding(
            padding: const EdgeInsets.only(left: 16.0, right: 16, top: 8),
            child: SizedBox(
              height: 40,
              child: TextField(
                controller: _searchController,
                keyboardType: TextInputType.multiline,
                onChanged: (value) {
                  // handled by listener with debounce
                },
                textAlignVertical: TextAlignVertical.center,
                style: const TextStyle(
                  fontSize: 12,
                  fontFamily: "Inter",
                  fontWeight: FontWeight.w400,
                  color: Colors.black,
                ),
                decoration: InputDecoration(
                  hintText: 'Search Donor',
                  hintStyle: const TextStyle(
                    fontSize: 12,
                    fontFamily: "Inter",
                    fontWeight: FontWeight.w400,
                    color: Color(0xffA7A4AD),
                  ),
                  suffixIcon: _searchQuery.isNotEmpty
                      ? IconButton(
                          icon: const Icon(Icons.clear, color: Color(0xff1BA3A1), size: 16),
                          onPressed: () {
                            _searchController.clear();
                            setState(() => _searchQuery = '');
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
          ),
          const SizedBox(height: 7),
          // Donor List with Pull-to-Refresh
          Expanded(
            child: StreamBuilder<List<Person>>(
              stream: _localDb.watchPeople(query: _searchQuery),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return DonorListShimmer();
                }

                if (snapshot.hasError) {
                  return RefreshIndicator(
                    onRefresh: _refreshDonors,
                    color: const Color(0xff1BA3A1),
                    child: SingleChildScrollView(
                      physics: const AlwaysScrollableScrollPhysics(),
                      child: SizedBox(
                        height: MediaQuery.of(context).size.height * 0.6,
                        child: Center(
                          child: Text('Error loading donors: ${snapshot.error}'),
                        ),
                      ),
                    ),
                  );
                }

                final people = snapshot.data ?? [];

                if (people.isEmpty) {
                  return RefreshIndicator(
                    onRefresh: _refreshDonors,
                    color: const Color(0xff1BA3A1),
                    child: SingleChildScrollView(
                      physics: const AlwaysScrollableScrollPhysics(),
                      child: SizedBox(
                        height: MediaQuery.of(context).size.height * 0.6,
                        child: _buildNoSearchResultsUI(_searchQuery),
                      ),
                    ),
                  );
                }

                return RefreshIndicator(
                  onRefresh: _refreshDonors,
                  color: const Color(0xff1BA3A1),
                  child: ListView.builder(
                    physics: const AlwaysScrollableScrollPhysics(),
                    itemCount: people.length,
                    itemBuilder: (context, index) {
                      final person = people[index];
                      return GestureDetector(
                        onTap: () async {
                          if (person.donorId == null || person.donorId!.isEmpty) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('Donor details are not available offline yet. Please try again when connected.'),
                              ),
                            );
                            return;
                          }
                          final targetDonorId = person.donorId!;
                          final result = await Navigator.push(
                            context,
                            SlidingPageTransitionRL(
                              page: donorDetails(
                                donorId: targetDonorId,
                              ),
                            ),
                          );

                          if (result == true) {
                            _refreshDonors();
                          }
                        },
                        child: ListTile(
                          leading: Hero(
                            tag: 'donor_avatar_${person.donorId ?? person.id}',
                            child: _buildProfileAvatar(person),
                          ),
                          title: Text(
                            person.name,
                            style: const TextStyle(
                              fontSize: 16,
                              fontFamily: "Inter",
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          subtitle: Text(
                            person.house,
                            style: const TextStyle(
                              fontSize: 10,
                              fontFamily: "Inter",
                              fontWeight: FontWeight.w400,
                              color: Color(0xff817D8A),
                            ),
                          ),
                          trailing: Padding(
                            padding: const EdgeInsets.only(left: 22.0),
                            child: Text(
                              "₹${person.amount.toStringAsFixed(0)}",
                              style: const TextStyle(
                                fontSize: 16,
                                fontFamily: "Inter",
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNoSearchResultsUI(String q) {
    final query = q.trim();
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
              child: const Icon(
                Icons.person_search,
                size: 56,
                color: Color(0xff1BA3A1),
              ),
            ),
            const SizedBox(height: 18),
            Text(
              query.isEmpty ? 'No donors available' : 'No donors found',
              style: const TextStyle(
                fontFamily: 'Inter',
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: Color(0xff1BA3A1),
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            if (query.isNotEmpty)
              Text(
                "We couldn't find any donors matching \"$query\".",
                style: const TextStyle(
                  fontSize: 12,
                  color: Colors.grey,
                  fontFamily: 'Inter',
                ),
                textAlign: TextAlign.center,
              ),

          ],
        ),
      ),
    );
  }
}