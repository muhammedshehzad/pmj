import 'package:flutter/material.dart';

class personHome {
   final String name;
   final String date;
   final String method;
   final int amount;
  late final String photoUrl;

  personHome({
    required this.name,
    required this.date,
    required this.amount,
    required this.photoUrl,
    required this.method,
  });
}

class PeopleListViewHome extends StatelessWidget {

  List<personHome> peoplesHome = [
    personHome(
      name: "Faisal K",
      date: "12.08.2024",
      amount: 250,
      photoUrl: "lib/assets/images/faisalk.png",
      method: 'Cash',
    ),
    personHome(
      name: "Ammad Parambath",
      date: "12.08.2024",
      amount: 250,
      photoUrl: "lib/assets/images/ammadp.png",
      method: 'Cash',
    ),
    personHome(
      name: "Pocker Haji Kaloli",
      date: "12.08.2024",
      amount: 1000,
      photoUrl: "lib/assets/images/ishakv.png",
      method: 'Cash',
    ),
    personHome(
      name: "Arshad MK",
      date: "12.08.2024",
      amount: 500,
      photoUrl: "lib/assets/images/pkhaji.png",
      method: 'Cash',
    ),
    personHome(
      name: "Ishak Vallil",
      date: "12.08.2024",
      amount: 500,
      photoUrl: "lib/assets/images/arshadmk.png",
      method: 'Account',
    ),
    personHome(
      name: "Shareef Kaloli",
      date: "12.08.2024",
      amount: 250,
      photoUrl: "lib/assets/images/pkhaji.png",
      method: 'Cash',
    ),
    personHome(
      name: "Salam K",
      date: "12.08.2024",
      amount: 250,
      photoUrl: "lib/assets/images/faisalk.png",
      method: 'Cash',
    ),
    personHome(
      name: "Faisal K",
      date: "12.08.2024",
      amount: 250,
      photoUrl: "lib/assets/images/ishakv.png",
      method: 'Account',
    ),
    personHome(
      name: "Faisal K",
      date: "12.08.2024",
      amount: 250,
      photoUrl: "lib/assets/images/faisalk.png",
      method: 'Cash',
    ),
    personHome(
      name: "Ammad Parambath",
      date: "12.08.2024",
      amount: 250,
      photoUrl: "lib/assets/images/ammadp.png",
      method: 'Cash',
    ),
    personHome(
      name: "Pocker Haji Kaloli",
      date: "12.08.2024",
      amount: 250,
      photoUrl: "lib/assets/images/ishakv.png",
      method: 'Cash',
    ),
    personHome(
      name: "Arshad MK",
      date: "12.08.2024",
      amount: 250,
      photoUrl: "lib/assets/images/pkhaji.png",
      method: 'Cash',
    ),
    personHome(
      name: "Ishak Vallil",
      date: "12.08.2024",
      amount: 250,
      photoUrl: "lib/assets/images/arshadmk.png",
      method: 'Account',
    ),
  ];
  PeopleListViewHome({super.key, required this.peoplesHome});

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      shrinkWrap: true,
      physics: BouncingScrollPhysics(),
      itemCount: peoplesHome.length,
      itemBuilder: (context, index) {
        final person = peoplesHome[index];
        return ListTile(
          leading: CircleAvatar(
            backgroundImage: AssetImage(person.photoUrl),
            radius: 20,
          ),
          title: Text(
            person.name,
            style: TextStyle(
              fontSize: 14,
              fontFamily: "Inter",
              fontWeight: FontWeight.w600,
            ),
          ),
          subtitle: Text(
            person.date,
            style: TextStyle(
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
                  style: TextStyle(
                    fontSize: 16,
                    fontFamily: "Inter",
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.only(top: 4.0),
                  child: Text(
                    person.method,
                    style: TextStyle(
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

          },
        );
      },
    );
  }
}
