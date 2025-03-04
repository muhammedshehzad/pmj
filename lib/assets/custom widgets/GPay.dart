import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';

import 'logoutpopup.dart';

class GPay extends StatelessWidget {
  const GPay({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
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
                  ),                    ],
              ),
            ),
          ),
        ),
      ),
      body:

      Column(
        children: [
          ListTile(
            leading: GestureDetector(
              onTap: () {
                Navigator.pop(context);
              },
              child: SvgPicture.asset(
                'lib/assets/images/Back.svg',
                height: 40,
                width: 40,
              ),
            ),
            title: Center(
              child: Text(
                'QR Code',
                style: TextStyle(fontWeight: FontWeight.w600, fontSize: 16),
              ),
            ),
            trailing: SvgPicture.asset(
              'lib/assets/images/settingsnew.svg',
              height: 40,
              width: 40,
            ),
          ),
          Center(
            child: Image.asset('lib/assets/images/gpay.jpg',fit: BoxFit.cover,),
          ),
        ],
      ),

    );
  }
}
