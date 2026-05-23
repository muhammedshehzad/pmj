import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:pmj_application/primary/donorPage.dart';
import 'package:pmj_application/primary/homePage.dart';
import 'package:pmj_application/primary/login.dart';
import 'package:pmj_application/primary/manage_users_page.dart';
import 'package:pmj_application/primary/paymentsPage.dart';
import 'package:pmj_application/primary/splashscreen.dart';
import 'package:pmj_application/secondary/donations_provider.dart';
import 'package:pmj_application/secondary/donorAdd.dart';
import 'package:pmj_application/secondary/user_service.dart';
import 'package:pmj_application/providers/payment_provider.dart';
import 'package:pmj_application/primary/paymentsPage.dart' show PaymentsPageProvider;
import 'package:provider/provider.dart';
import 'firebase_options.dart';
import 'package:pmj_application/services/local_database_service.dart';
import 'package:pmj_application/donor_module/providers/donor_auth_provider.dart';
import 'package:pmj_application/donor_module/providers/payment_history_provider.dart';
import 'package:pmj_application/donor_module/providers/donor_profile_provider.dart';
import 'package:pmj_application/donor_module/providers/payment_submission_provider.dart';
import 'package:pmj_application/donor_module/screens/donor_login_screen.dart';
import 'package:pmj_application/donor_module/screens/donor_dashboard_screen.dart';
import 'package:pmj_application/donor_module/screens/login_choice_screen.dart';
import 'package:pmj_application/donor_module/screens/payment_history_screen.dart';
import 'package:pmj_application/donor_module/screens/donor_profile_screen.dart';
import 'package:pmj_application/donor_module/screens/payment_submission_screen.dart';
import 'package:pmj_application/providers/transaction_provider.dart';
import 'package:pmj_application/services/permission_service.dart';
import 'package:pmj_application/theme/app_theme.dart';


Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Initialize Firebase
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  // Enable Firestore offline persistence
  FirebaseFirestore.instance.settings = const Settings(
    persistenceEnabled: true,
    cacheSizeBytes: Settings.CACHE_SIZE_UNLIMITED,
  );
  
  // Initialize LocalDatabaseService (Isar)
  final localDb = LocalDatabaseService();
  await localDb.init();
  
  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => NavBarProvider()),
        ChangeNotifierProvider(create: (_) => PaymentProvider()),
        ChangeNotifierProvider(create: (_) => PaymentsPageProvider()),
        ChangeNotifierProvider(create: (_) => DonationsProvider()),
        ChangeNotifierProvider(create: (_) => DonorAuthProvider()),
        ChangeNotifierProvider(create: (_) => PaymentHistoryProvider()),
        ChangeNotifierProvider(create: (_) => DonorProfileProvider()),
        ChangeNotifierProvider(create: (_) => PaymentSubmissionProvider()),
        ChangeNotifierProvider(create: (_) => TransactionProvider()),
        ChangeNotifierProvider(create: (_) => Permissions()),
        Provider(create: (_) => UserService()),
        Provider<LocalDatabaseService>.value(value: localDb),
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
      theme: AppTheme.light,
      darkTheme: AppTheme.dark,
      themeMode: ThemeMode.system,
      initialRoute: '/',
      routes: {
        '/': (context) => const splashscreen(),
        '/login/choice': (context) => const LoginChoiceScreen(),
        '/login': (context) => const AuthScreens(),
        '/manage-users': (context) => const ManageUsersPage(),
        '/donor/login': (context) => const DonorLoginScreen(),
        '/donor/dashboard': (context) => const DonorDashboardScreen(),
        '/donor/payment-history': (context) => const PaymentHistoryScreen(),
        '/donor/profile': (context) => const DonorProfileScreen(),
        '/donor/payment-submission': (context) => const PaymentSubmissionScreen(),
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