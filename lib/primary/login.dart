

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'login_provider.dart';

class LoginScreen extends StatelessWidget {
  const LoginScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => LoginProvider(),
      child: Scaffold(
        backgroundColor: Colors.white,
        body: SingleChildScrollView(
          child: SizedBox(
            height: MediaQuery.of(context).size.height,
            width: MediaQuery.of(context).size.width,
            child: Column(
              children: [
                SizedBox(height: 189),
                Align(
                  alignment: Alignment.topCenter,
                  child: Hero(
                    tag: 'hero-tag',
                    child: SizedBox(
                      height: 110,
                      width: 84,
                      child: Image.asset('lib/assets/images/PMJ Logo.png'),
                    ),
                  ),
                ),
                SizedBox(height: 58),
                Consumer<LoginProvider>(
                  builder: (context, loginProvider, child) {
                    return Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Email Id',
                            style: TextStyle(
                              fontSize: 10,
                              color: Colors.black,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          SizedBox(height: 3),
                          TextFormField(
                            controller: loginProvider.emailController,
                            keyboardType: TextInputType.emailAddress,
                            decoration: InputDecoration(
                              hintText: 'example@gmail.com',
                              hintStyle: TextStyle(fontSize: 12, color: Color(0xffA7A4AD)),
                              enabledBorder: OutlineInputBorder(
                                borderSide: BorderSide(color: Color(0xFF1BA3A1), width: 1.0),
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderSide: BorderSide(color: Color(0xFF1BA3A1), width: 2.0),
                              ),
                            ),
                          ),
                          SizedBox(height: 16),
                          Text(
                            'Password',
                            style: TextStyle(
                              fontSize: 10,
                              color: Colors.black,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          SizedBox(height: 3),
                          TextFormField(
                            controller: loginProvider.passwordController,
                            obscureText: true,
                            decoration: InputDecoration(
                              hintText: '********',
                              hintStyle: TextStyle(fontSize: 12, color: Color(0xffA7A4AD)),
                              enabledBorder: OutlineInputBorder(
                                borderSide: BorderSide(color: Color(0xFF1BA3A1), width: 1.0),
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderSide: BorderSide(color: Color(0xFF1BA3A1), width: 2.0),
                              ),
                            ),
                          ),
                          SizedBox(height: 16),
                          Container(
                            width: MediaQuery.of(context).size.width,
                            height: 50,
                            child: ElevatedButton(
                              style: ElevatedButton.styleFrom(
                                foregroundColor: Colors.white,
                                backgroundColor: Color(0xff1BA3A1),
                                elevation: 0.0,
                                shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(4)
                                ),
                              ),
                              onPressed: () {
                                loginProvider.login(context);
                              },
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Text(
                                    'Login',
                                    style: TextStyle(
                                      fontWeight: FontWeight.w600,
                                      fontSize: 16,
                                    ),
                                  ),
                                  SizedBox(width: 5),
                                  Icon(Icons.login),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),
                Spacer(),
                Padding(
                  padding: const EdgeInsets.only(bottom: 29.0),
                  child: Text(
                    'Perakkool Muslim Jama-ath Committee',
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                      color: Colors.black54,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
