import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../primary/homePage.dart';
import '../../primary/paymentsPage.dart';

void showRecordConfirmation(BuildContext context) {
  showDialog(
    context: context,
    builder: (BuildContext context) {
      return AlertDialog(
        content: Text(
          'Payment Recorded!',
          style: TextStyle(
              fontFamily: "Inter", fontWeight: FontWeight.w400, fontSize: 12),
        ),
        actions: <Widget>[
          Container(
            height: 30,
            width: 70,
            margin: const EdgeInsets.only(right: 4, bottom: 4),
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                foregroundColor: Colors.white,
                backgroundColor: const Color(0xffF44336),
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
              child: const Text(
                'OK',
                style: TextStyle(
                  fontFamily: "Inter",
                  fontWeight: FontWeight.bold,
                  fontSize: 9,
                ),
              ),
              onPressed: () => Navigator.pop(context),
            ),
          ),
        ],
      );
    },
  );
}

void _performRecord(BuildContext context) {
  Navigator.of(context).pop();

  final rootContext = Provider.of<NavBarProvider>(context, listen: false);
  rootContext.changeIndex(1);
}
