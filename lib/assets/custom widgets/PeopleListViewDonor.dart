import 'package:flutter/material.dart';

import '../../secondary/donorDetails.dart';

class Person {
  final String name;
  final String house;
  final int amount;
  final String photoUrl;

  Person(
      {required this.name,
      required this.house,
      required this.amount,
      required this.photoUrl});
}

class PeopleListViewDonor extends StatelessWidget {
  List<Person> people = [
    Person(
      name: "Faisal K",
      house: "Konhantavida",
      amount: 250,
      photoUrl: "lib/assets/images/faisalk.png",
    ),
    Person(
      name: "Ammad Parambath",
      house: "Konhantavida",
      amount: 250,
      photoUrl: "lib/assets/images/ammadp.png",
    ),
    Person(
      name: "Pocker Haji Kaloli",
      house: "Konhantavida",
      amount: 250,
      photoUrl: "lib/assets/images/ishakv.png",
    ),
    Person(
      name: "Arshad MK",
      house: "Konhantavida",
      amount: 250,
      photoUrl: "lib/assets/images/pkhaji.png",
    ),
    Person(
      name: "Ishak Vallil",
      house: "Konhantavida",
      amount: 250,
      photoUrl: "lib/assets/images/arshadmk.png",
    ),
    Person(
      name: "Shareef Kaloli",
      house: "Konhantavida",
      amount: 250,
      photoUrl: "lib/assets/images/pkhaji.png",
    ),
    Person(
      name: "Salam K",
      house: "Konhantavida",
      amount: 250,
      photoUrl: "lib/assets/images/faisalk.png",
    ),
    Person(
      name: "Faisal K",
      house: "Konhantavida",
      amount: 250,
      photoUrl: "lib/assets/images/ishakv.png",
    ),
    Person(
      name: "Faisal K",
      house: "Konhantavida",
      amount: 250,
      photoUrl: "lib/assets/images/faisalk.png",
    ),
    Person(
      name: "Ammad Parambath",
      house: "Konhantavida",
      amount: 250,
      photoUrl: "lib/assets/images/ammadp.png",
    ),
    Person(
      name: "Pocker Haji Kaloli",
      house: "Konhantavida",
      amount: 250,
      photoUrl: "lib/assets/images/ishakv.png",
    ),
    Person(
      name: "Arshad MK",
      house: "Konhantavida",
      amount: 250,
      photoUrl: "lib/assets/images/pkhaji.png",
    ),
    Person(
      name: "Ishak Vallil",
      house: "Konhantavida",
      amount: 250,
      photoUrl: "lib/assets/images/arshadmk.png",
    ),
  ];

  PeopleListViewDonor({Key? key, required this.people}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: ListView.builder(
          itemCount: people.length,
          itemBuilder: (context, index) {
            final person = people[index];
            return GestureDetector(
              onTap: (){
                Navigator.push(context,  MaterialPageRoute(
                  builder: (context) => donorDetails(),
                ),);
              },
              child: ListTile(
                leading: CircleAvatar(
                  backgroundImage: AssetImage(person.photoUrl),
                  radius: 25,
                ),
                title: Text(
                  person.name,
                  style: TextStyle(
                      fontSize: 16,
                      fontFamily: "Inter",
                      fontWeight: FontWeight.w600),
                ),
                subtitle: Text(person.house,
                    style: TextStyle(
                        fontSize: 10,
                        fontFamily: "Inter",
                        fontWeight: FontWeight.w400,
                        color: Color(0xff817D8A))),
                trailing: Padding(
                  padding: const EdgeInsets.only(bottom: 22.0),
                  child: Text("₹${person.amount.toStringAsFixed(0)}",
                      style: TextStyle(
                          fontSize: 16,
                          fontFamily: "Inter",
                          fontWeight: FontWeight.w600)),
                ),
              ),
            );
          }),
    );
  }
}
