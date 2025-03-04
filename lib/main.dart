import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:pmj_application/primary/donorPage.dart';
import 'package:pmj_application/primary/homePage.dart';
import 'package:pmj_application/primary/login.dart';
import 'package:pmj_application/primary/paymentsPage.dart';
import 'package:pmj_application/primary/splashscreen.dart';
import 'package:pmj_application/secondary/donorAdd.dart';
import 'package:pmj_application/secondary/donorDetails.dart';
import 'package:provider/provider.dart';

import 'assets/custom widgets/GPay.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (context) => NavBarProvider(),child: BottomNavBarExample(),),
        ChangeNotifierProvider(create: (context) => PeopleProvider()),
        ChangeNotifierProvider(create: (_) => PaymentProvider()),
        // Add other providers if necessary
      ],
      child: MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      theme: ThemeData(fontFamily: "Inter"),
      initialRoute: '/',
      routes: {
        '/': (context) => const splashscreen(),
        '/login': (context) => const LoginScreen(),
        '/donorPage': (context) => const donorPage(),
        '/homePage': (context) => homePage(),
        '/BottomNavBarExample': (context) => BottomNavBarExample(),
        '/donorDetails': (context) => donorDetails(),
        '/donorAdd': (context) => donorAdd(),
        '/paymentsPage': (context) => paymentsPage(),
        '/GPay': (context) => GPay(),

      },
      debugShowCheckedModeBanner: false,
    );
  }
}

class MyHomePage extends StatelessWidget {
  const MyHomePage({super.key, required this.title});

  final String title;

  @override
  Widget build(BuildContext context) {
    final navBarProvider = Provider.of<NavBarProvider>(context);
    return  Scaffold();
  }
}
