import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class personHome {
  final String name;
  final String date;
  final int amount;
  final String donorId;
  final String method;
  final String month;
  final String year;
  final String status;
  final String? documentPath; // Added for deletion functionality

  personHome({
    required this.name,
    required this.date,
    required this.amount,
    required this.donorId,
    required this.method,
    required this.month,
    required this.year,
    required this.status,
    this.documentPath,
  });
}

class PeopleListViewHome extends StatelessWidget {
  final List<personHome> peoplesHome;

  const PeopleListViewHome({Key? key, required this.peoplesHome})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      shrinkWrap: true,
      physics: const BouncingScrollPhysics(),
      itemCount: peoplesHome.length,
      itemBuilder: (context, index) {
        final person = peoplesHome[index];

        // Check if donorId is valid
        if (person.donorId.isEmpty) {
          return ListTile(
            leading: const CircleAvatar(
              backgroundImage: NetworkImage('https://via.placeholder.com/150'),
              radius: 20,
            ),
            title: Text(
              person.name,
              style: const TextStyle(
                fontSize: 14,
                fontFamily: "Inter",
                fontWeight: FontWeight.w600,
              ),
            ),
            subtitle: Text(
              "${person.date} • ${person.month} ${person.year}",
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
                  Padding(
                    padding: const EdgeInsets.only(top: 4.0),
                    child: Text(
                      person.method,
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
          );
        }

        return FutureBuilder<DocumentSnapshot>(
          future: FirebaseFirestore.instance
              .collection('donors')
              .doc(person.donorId)
              .get(),
          builder: (context, donorSnapshot) {
            if (donorSnapshot.connectionState == ConnectionState.waiting) {
              return SizedBox();
            }
            if (donorSnapshot.hasError ||
                !donorSnapshot.hasData ||
                !donorSnapshot.data!.exists) {
              return ListTile(
                leading: const CircleAvatar(
                  backgroundImage:
                      NetworkImage('https://via.placeholder.com/150'),
                  radius: 20,
                ),
                title: Text(
                  person.name,
                  style: const TextStyle(
                    fontSize: 14,
                    fontFamily: "Inter",
                    fontWeight: FontWeight.w600,
                  ),
                ),
                subtitle: Text(
                  "${person.date} • ${person.month} ${person.year}",
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
                      Padding(
                        padding: const EdgeInsets.only(top: 4.0),
                        child: Text(
                          person.method,
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
              );
            }

            final donorData =
                donorSnapshot.data!.data() as Map<String, dynamic>;
            final donorImage =
                donorData['imageUrl'] ?? 'https://via.placeholder.com/150';

            return ListTile(
              leading: CircleAvatar(
                backgroundImage: NetworkImage(donorImage),
                radius: 20,
              ),
              title: Text(
                person.name,
                style: const TextStyle(
                  fontSize: 14,
                  fontFamily: "Inter",
                  fontWeight: FontWeight.w600,
                ),
              ),
              subtitle: Text(
                "${person.date} • ${person.month} ${person.year}",
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
                    Padding(
                      padding: const EdgeInsets.only(top: 4.0),
                      child: Text(
                        person.method,
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
              onTap: () {
                // Add navigation or action if needed
              },
            );
          },
        );
      },
    );
  }
}
