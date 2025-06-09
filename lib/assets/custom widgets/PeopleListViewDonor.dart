import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_svg/svg.dart';
import 'package:pmj_application/assets/custom%20widgets/transition.dart';
import '../../secondary/donorDetails.dart';

class Person {
  final String name;
  final String house;
  final double amount;
  final String photoUrl;

  Person({
    required this.name,
    required this.house,
    required this.amount,
    required this.photoUrl,
  });

  factory Person.fromFirestore(Map<String, dynamic> data) {
    return Person(
      name: data['name'] ?? 'Unknown',
      house: data['address'] ?? 'No Address',
      amount: (data['amount'] as num?)?.toDouble() ?? 0.0,
      photoUrl: data['imageUrl'] ?? '',
    );
  }
}

class PeopleListViewDonor extends StatefulWidget {
  const PeopleListViewDonor({Key? key}) : super(key: key);

  @override
  _PeopleListViewDonorState createState() => _PeopleListViewDonorState();
}

class _PeopleListViewDonorState extends State<PeopleListViewDonor> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _searchController.addListener(() {
      setState(() {
        _searchQuery = _searchController.text.toLowerCase();
      });
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
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
                  setState(() {
                    _searchQuery = value.toLowerCase();
                  });
                },
                textAlignVertical: TextAlignVertical.center, // Vertically center the text
                style: TextStyle(
                  fontSize: 12,
                  fontFamily: "Inter",
                  fontWeight: FontWeight.w400,
                  color: Colors.black, // Color for typed text
                ),
                decoration: InputDecoration(
                  hintText: 'Search Donor',
                  hintStyle: TextStyle(
                    fontSize: 12,
                    fontFamily: "Inter",
                    fontWeight: FontWeight.w400,
                    color: Color(0xffA7A4AD),
                  ),
                  suffixIcon: Padding(
                    padding: const EdgeInsets.all(10.0),
                    child: SvgPicture.asset(
                      'lib/assets/images/search.svg',
                      height: 16,
                      width: 16,
                    ),
                  ),
                  contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 0), // Adjust padding to center vertically
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(4.0),
                    borderSide: BorderSide(
                      color: Color(0xff1BA3A1),
                      width: 2.0,
                    ),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(4.0),
                    borderSide: BorderSide(
                      color: Color(0xff1BA3A1),
                      width: 2.0,
                    ),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(4.0),
                    borderSide: BorderSide(
                      color: Color(0xff1BA3A1),
                      width: 1.0,
                    ),
                  ),
                ),
              ),
            ),
          ),
          SizedBox(height:7),
          // Donor List
          Expanded(
            child: StreamBuilder<User?>(
              stream: FirebaseAuth.instance.authStateChanges(),
              builder: (context, authSnapshot) {
                if (authSnapshot.connectionState == ConnectionState.waiting) {
                  return Center(child: CircularProgressIndicator());
                }

                if (!authSnapshot.hasData) {
                  FirebaseAuth.instance.signInAnonymously();
                  return Center(child: Text('Signing in...'));
                }

                return StreamBuilder<QuerySnapshot>(
                  stream: FirebaseFirestore.instance
                      .collection('donors')
                      .orderBy('name', descending: false) // Sort by name in ascending order (A-Z)
                      .snapshots(),
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return Center(child: CircularProgressIndicator());
                    }

                    if (snapshot.hasError) {
                      return Center(child: Text('Error: ${snapshot.error}'));
                    }

                    if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                      return Center(child: Text('No donors found'));
                    }

                    final people = snapshot.data!.docs
                        .map((doc) => Person.fromFirestore(doc.data() as Map<String, dynamic>))
                        .toList();

                    // Filter the list based on the search query
                    final filteredPeople = people.where((person) {
                      final nameMatch = person.name.toLowerCase().contains(_searchQuery);
                      final amountMatch = person.amount.toString().contains(_searchQuery);
                      return nameMatch || amountMatch;
                    }).toList();

                    if (filteredPeople.isEmpty) {
                      return Center(child: Text('No matching donors found'));
                    }

                    return ListView.builder(
                      itemCount: filteredPeople.length,
                      itemBuilder: (context, index) {
                        final person = filteredPeople[index];
                        return GestureDetector(
                          onTap: () {
                            Navigator.push(
                              context,
                              SlidingPageTransitionRL(page: donorDetails(
                                donorId: snapshot.data!.docs
                                    .firstWhere((doc) =>
                                Person.fromFirestore(doc.data() as Map<String, dynamic>).name ==
                                    person.name)
                                    .id,
                              )),
                            );
                          },
                          child: ListTile(
                            leading: CircleAvatar(
                              radius: 25,
                              backgroundImage: person.photoUrl.isNotEmpty
                                  ? NetworkImage(person.photoUrl)
                                  : null, // Set to null when no photoUrl
                              backgroundColor: person.photoUrl.isNotEmpty
                                  ? null
                                  : Color(0xff1BA3A1), // Use a fallback color when no image
                              child: person.photoUrl.isEmpty
                                  ? Text(
                                person.name.isNotEmpty ? person.name[0].toUpperCase() : '',
                                style: TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                ),
                              )
                                  : null, // Show text only when no image
                            ),
                            title: Text(
                              person.name,
                              style: TextStyle(
                                fontSize: 16,
                                fontFamily: "Inter",
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            subtitle: Text(
                              person.house,
                              style: TextStyle(
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
                                style: TextStyle(
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
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}