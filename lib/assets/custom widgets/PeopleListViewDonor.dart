import 'package:flutter/material.dart';
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:pmj_application/models/person_model.dart';
import 'package:pmj_application/secondary/donorDetails.dart';
import 'package:pmj_application/services/local_database_service.dart';
import 'package:shimmer/shimmer.dart';
import '../../services/image_cache_service.dart';
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
    
    // Initial sync with Firestore
    _localDb.syncWithFirestore().catchError((error) {
      // Handle error silently - we'll still show cached data
      debugPrint('Error syncing with Firestore: $error');
    });
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

    if (effectivePhotoUrl.isEmpty) {
      return CircleAvatar(
        radius: 25,
        backgroundColor: const Color(0xff1BA3A1),
        child: Text(
          person.name.isNotEmpty ? person.name[0].toUpperCase() : '',
          style: const TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
      );
    }

    return FutureBuilder<ImageProvider?>(
      future: ImageCacheService().getImageProvider(effectivePhotoUrl),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Shimmer.fromColors(
            baseColor: const Color(0xFFE0E0E0),
            highlightColor: const Color(0xFFF5F5F5),
            child: const CircleAvatar(
              radius: 25,
              backgroundColor: Colors.white,
            ),
          );
        }

        if (snapshot.hasData && snapshot.data != null) {
          // Fade-in image inside a circular clip
          return ClipOval(
            child: SizedBox(
              width: 50,
              height: 50,
              child: Image(
                image: snapshot.data!,
                fit: BoxFit.cover,
                frameBuilder: (context, child, frame, wasSynchronouslyLoaded) {
                  if (wasSynchronouslyLoaded) {
                    return child;
                  }
                  return AnimatedOpacity(
                    opacity: frame == null ? 0 : 1,
                    duration: const Duration(milliseconds: 300),
                    curve: Curves.easeInOut,
                    child: child,
                  );
                },
                errorBuilder: (context, error, stackTrace) {
                  // On error, fallback to initials
                  return CircleAvatar(
                    radius: 25,
                    backgroundColor: const Color(0xff1BA3A1),
                    child: Text(
                      person.name.isNotEmpty ? person.name[0].toUpperCase() : '',
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  );
                },
              ),
            ),
          );
        }

        // Fallback to initials if image not available
        return CircleAvatar(
          radius: 25,
          backgroundColor: const Color(0xff1BA3A1),
          child: Text(
            person.name.isNotEmpty ? person.name[0].toUpperCase() : '',
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
        );
      },
    );
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
          // Donor List
          Expanded(
            child: StreamBuilder<List<Person>>(
              stream: _localDb.watchPeople(query: _searchQuery),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return DonorListShimmer();
                }

                if (snapshot.hasError) {
                  return Center(
                      child: Text('Error loading donors: ${snapshot.error}'));
                }

                final people = snapshot.data ?? [];

                if (people.isEmpty) {
                  return _buildNoSearchResultsUI(_searchQuery);
                }

                return ListView.builder(
                  itemCount: people.length,
                  itemBuilder: (context, index) {
                    final person = people[index];
                    return GestureDetector(
                      onTap: () {
                        if (person.donorId == null || person.donorId!.isEmpty) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Donor details are not available offline yet. Please try again when connected.'),
                            ),
                          );
                          return;
                        }
                        final targetDonorId = person.donorId!;
                        Navigator.push(
                          context,
                          SlidingPageTransitionRL(
                            page:donorDetails(
                              donorId: targetDonorId,
                            ),
                          ),
                        );
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