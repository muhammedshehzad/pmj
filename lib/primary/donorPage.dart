import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:provider/provider.dart';

import '../assets/custom widgets/PeopleListViewDonor.dart';
import '../assets/custom widgets/logoutpopup.dart';
import 'package:flutter/material.dart';

class DonorProvider extends ChangeNotifier {
  List<Person> _people = [
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

  List<Person> _filteredPeople = [];

  DonorProvider() {
    _filteredPeople = _people;
  }

  List<Person> get filteredPeople => _filteredPeople;

  void filterPeople(String query) {
    if (query.isEmpty) {
      _filteredPeople = _people;
    } else {
      _filteredPeople = _people
          .where((person) =>
              person.name.toLowerCase().contains(query.toLowerCase()) ||
              person.house.toLowerCase().contains(query.toLowerCase()))
          .toList();
    }
    notifyListeners();
  }
}

class donorPage extends StatelessWidget {
  const donorPage({super.key});

  @override
  Widget build(BuildContext context) {

    TextEditingController search = TextEditingController();
    return ChangeNotifierProvider(
      create: (context) => DonorProvider(),
      child: Scaffold(
        backgroundColor: Color(0xffFFFFFF),
        appBar: PreferredSize(
          preferredSize: Size.fromHeight(100),
          child: AppBar(
            elevation: 0,
            backgroundColor: Color(0xff1BA3A1),
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
                      padding: const EdgeInsets.only(bottom: 8.0),
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
                            elevation: 0),
                        child: Center(
                          child: Text(
                            'Logout',
                            style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.w600,
                                fontFamily: "Inter"),
                          ),
                        ),
                      ),
                    ),                  ],
                ),
              ),
            ),
          ),
        ),
        body: Consumer<DonorProvider>(builder: (context, donorProvider, child) {
          return SizedBox(
            height: MediaQuery.of(context).size.height,
            width: MediaQuery.of(context).size.width,
            child: Stack(
              children: [
                Column(
                  children: [
                    Padding(
                      padding:
                          const EdgeInsets.only(left: 16.0, right: 16, top: 8),
                      child: SizedBox(
                        height: 40,
                        child: TextField(
                          controller: search,
                          keyboardType: TextInputType.multiline,
                          onChanged: (value) {
                            donorProvider.filterPeople(
                                value); // Call the provider's filter method
                          },
                          decoration: InputDecoration(
                            hintText: 'Search Donor',
                            hintStyle: TextStyle(
                                fontSize: 10,
                                fontFamily: "Inter",
                                fontWeight: FontWeight.w400,
                                color: Color(0xffA7A4AD)),
                            suffixIcon: Padding(
                              padding: const EdgeInsets.all(10.0),
                              child: SvgPicture.asset(
                                'lib/assets/images/search.svg',
                                height: 16,
                                width: 16,
                              ),
                            ),
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
                    PeopleListViewDonor(
                      people: donorProvider._filteredPeople,
                    ),
                  ],
                ),
                Positioned(
                  bottom: 13,
                  right: 13,
                  child: FloatingActionButton(
                    onPressed: () {
                      Navigator.pushNamed(context, '/donorAdd');
                    },
                    child: SvgPicture.asset(
                      'lib/assets/images/fltbtn.svg',
                      height: 24,
                      width: 24,
                    ),
                    backgroundColor: Color(0xff1BA3A1),
                    foregroundColor: Colors.transparent,
                    elevation: 0,
                  ),
                ),
              ],
            ),
          );
        }),
      ),
    );
  }
}
