import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../primary/homePage.dart';
import '../../primary/paymentsPage.dart';

void showSubmitConfirmation(BuildContext context) {
  showDialog(
    context: context,
    builder: (BuildContext context) {
      return AlertDialog(
        content: Text(
          'Donor Added Successfully !',
          style: TextStyle(
              fontFamily: "Inter", fontWeight: FontWeight.w400, fontSize: 12),
        ),
        actions: <Widget>[
          Container(
            height: 26,
            width: 60,
            margin: EdgeInsets.only(right: 4, bottom: 4),
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                  foregroundColor: Colors.white,
                  backgroundColor: Color(0xffF44336),
                  elevation: 0),
              child: Text(
                'OK',
                style: TextStyle(
                    fontFamily: "Inter",
                    fontWeight: FontWeight.w400,
                    fontSize: 11),
              ),
              onPressed: () {
                Navigator.of(context).pop();
                _performSubmit(context);
              },
            ),
          ),
        ],
      );
    },
  );
}

void _performSubmit(BuildContext context) {
  Navigator.of(context).pop();
  final rootContext = Provider.of<NavBarProvider>(context, listen: false);
  rootContext.changeIndex(2);
}
