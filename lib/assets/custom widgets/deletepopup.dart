import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../primary/homePage.dart';

void showDeleteConfirmation(BuildContext context) {
  showDialog(
    context: context,
    builder: (BuildContext context) {
      return AlertDialog(
        content: Text(
          'Are you sure you want to Delete?',
          style: TextStyle(
              fontFamily: "Inter", fontWeight: FontWeight.w400, fontSize: 12),
        ),
        actions: <Widget>[
          Container(
            height: 26,
            width: 72,
            margin: EdgeInsets.only(right: 4, bottom: 4),
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                  foregroundColor: Colors.white,
                  backgroundColor: Color(0xff29B6F6),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(4)),
                  elevation: 0),
              child: Text(
                'Cancel',
                style: TextStyle(
                    fontFamily: "Inter",
                    fontWeight: FontWeight.w600,
                    fontSize: 7),
              ),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
          ),
          Container(
            height: 26,
            width: 72,
            margin: EdgeInsets.only(right: 0, bottom: 4),
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                  foregroundColor: Colors.white,
                  backgroundColor: Color(0xffF44336),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(4)),
                  elevation: 0),
              child: Text(
                'Delete',
                style: TextStyle(
                    fontFamily: "Inter",
                    fontWeight: FontWeight.w600,
                    fontSize: 7),
              ),
              onPressed: () {
                Navigator.of(context).pop();
                _performDelete(context);
              },
            ),
          ),
        ],
      );
    },
  );
}

void _performDelete(BuildContext context) {
  Navigator.of(context).pop();
  final rootContext = Provider.of<NavBarProvider>(context, listen: false);
  rootContext.changeIndex(1);
}
