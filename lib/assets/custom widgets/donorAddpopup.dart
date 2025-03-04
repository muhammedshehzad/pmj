import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../primary/homePage.dart';

void showAddedConfirmation(BuildContext context) {
  final rootContext = context;
  showDialog(
    context: context,
    builder: (BuildContext context) {
      return AlertDialog(
        content: Text(
          'Donor Added Succesfully !',
          style: TextStyle(
              fontFamily: "Inter", fontWeight: FontWeight.w400, fontSize: 12),
        ),
        actions: <Widget>[
          Container(
            height: 27,
            width: 60,
            margin: EdgeInsets.only(right: 4, bottom: 4),
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                  foregroundColor: Colors.white,
                  backgroundColor: Color(0xffF44336), shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(4)),
                  elevation: 0),
              child: Text(
                'OK',
                style: TextStyle(
                    fontFamily: "Inter",
                    fontWeight: FontWeight.w600,
                    fontSize: 8.75),
              ),
              onPressed: () {
                Navigator.of(context).pop();
                _performAdd(rootContext);              },
            ),
          ),
        ],
      );
    },
  );
}
void _performAdd(BuildContext context) {
  print('Changing to DonorPage');

  Navigator.of(context).pop();

  final rootContext = Provider.of<NavBarProvider>(context, listen: false);
  // rootContext.changeIndex(2);
}
