import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:pmj_application/primary/donorPage.dart';
import 'package:pmj_application/primary/homePage.dart';
import 'package:pmj_application/primary/login.dart';
import 'package:pmj_application/primary/paymentsPage.dart';
import 'package:pmj_application/primary/splashscreen.dart';
import 'package:pmj_application/secondary/donorAdd.dart';
import 'package:pmj_application/secondary/donorDetails.dart';
import 'package:pmj_application/secondary/user_service.dart';
import 'package:provider/provider.dart';
import 'firebase_options.dart';
import 'assets/custom widgets/GPay.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(
          create: (context) => NavBarProvider(), child: BottomNavBarExample(),),
        ChangeNotifierProvider(create: (context) => PeopleProvider()),
        ChangeNotifierProvider(create: (_) => PaymentProvider()),
        Provider(create: (_) => UserService()), // Add UserService provider

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
        '/login': (context) => const AuthScreens(),
        '/donorPage': (context) => const donorPage(),
        '/homePage': (context) => homePage(),
        '/BottomNavBarExample': (context) => BottomNavBarExample(),
        '/donorAdd': (context) => DonorAdd(),
        '/paymentsPage': (context) => PaymentsPage(),
        // '/GPay': (context) => GPay(),

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
    return Scaffold();
  }
}
//shehzadbinfaisal@gmail.com
//chechu1