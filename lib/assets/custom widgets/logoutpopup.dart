import 'package:flutter/material.dart';

import '../../primary/login.dart';


void showLogoutConfirmation(BuildContext context) {
  showDialog(
    context: context,
    builder: (BuildContext context) {
      return AlertDialog(
        content: Text(
          'Are you sure you want to log out?',
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
                'Logout',
                style: TextStyle(
                    fontFamily: "Inter",
                    fontWeight: FontWeight.w600,
                    fontSize: 7),
              ),
              onPressed: () {
                Navigator.of(context).pop();
                _performLogout(context);
              },
            ),
          ),
        ],
      );
    },
  );
}

void _performLogout(BuildContext context) {
  Navigator.push(
    context,
    MaterialPageRoute(builder: (context) => LoginScreen()),
  );
}
