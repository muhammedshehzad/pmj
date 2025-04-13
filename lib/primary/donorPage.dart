import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:provider/provider.dart';

import '../assets/custom widgets/PeopleListViewDonor.dart';
import '../assets/custom widgets/logoutpopup.dart';
import 'package:flutter/material.dart';

import '../assets/custom widgets/transition.dart';
import '../secondary/donorAdd.dart';
import 'login.dart';

class DonorProvider extends ChangeNotifier {
  List<Person> _people = [];

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
      child: Consumer<DonorProvider>(builder: (context, donorProvider, child) {
        return SizedBox(
          height: MediaQuery.of(context).size.height,
          width: MediaQuery.of(context).size.width,
          child: Stack(
            children: [
              Column(
                children: [
                  SizedBox(
                    height: 6,
                  ),
                  SizedBox(
                    height: 6,
                  ),
                  PeopleListViewDonor(),
                ],
              ),
              Positioned(
                bottom: 13,
                right: 13,
                child: FloatingActionButton(
                  onPressed: () {
                    Navigator.push(
                        context, SlidingPageTransitionRL(page: DonorAdd()));
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
    );
  }
}
