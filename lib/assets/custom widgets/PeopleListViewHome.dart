import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:hive/hive.dart';
part 'PeopleListViewHome.g.dart';

@HiveType(typeId: 0)
class personHome {
  @HiveField(0)
  final String name;
  @HiveField(1)
  final String date;
  @HiveField(2)
  final int amount;
  @HiveField(3)
  final String donorId;
  @HiveField(4)
  final String method;
  @HiveField(5)
  final String month;
  @HiveField(6)
  final String year;
  @HiveField(7)
  final String status;
  @HiveField(8)
  final String? documentPath;

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
  final Function(personHome)? onTap;

  const PeopleListViewHome({Key? key, required this.peoplesHome, this.onTap})
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
            onTap: onTap != null ? () => onTap!(person) : null,
            leading: CircleAvatar(
              radius: 20,
              backgroundImage: null, // No network image for empty donorId
              backgroundColor: Colors.teal,
              child: Text(
                person.name.isNotEmpty ? person.name[0].toUpperCase() : '',
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
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
              return const SizedBox();
            }
            if (donorSnapshot.hasError ||
                !donorSnapshot.hasData ||
                !donorSnapshot.data!.exists) {
              return ListTile(
                onTap: onTap != null ? () => onTap!(person) : null,
                leading: CircleAvatar(
                  radius: 20,
                  backgroundImage: null, // No valid donor data
                  backgroundColor: Colors.teal,
                  child: Text(
                    person.name.isNotEmpty ? person.name[0].toUpperCase() : '',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
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
            final donorImage = donorData['imageUrl'] as String?;

            return ListTile(
              onTap: onTap != null ? () => onTap!(person) : null,
              leading: CircleAvatar(
                radius: 20,
                backgroundImage: donorImage != null && donorImage.isNotEmpty
                    ? NetworkImage(donorImage)
                    : null,
                backgroundColor: donorImage != null && donorImage.isNotEmpty
                    ? null
                    : Color(0xff1BA3A1),
                child: donorImage == null || donorImage.isEmpty
                    ? Text(
                  person.name.isNotEmpty ? person.name[0].toUpperCase() : '',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                )
                    : null,
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
          },
        );
      },
    );
  }
}