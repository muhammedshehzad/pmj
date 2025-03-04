import 'package:flutter/material.dart';

class LoginProvider with ChangeNotifier {
  String email = '';
  String password = '';

  final emailController = TextEditingController();
  final passwordController = TextEditingController();

  String? validateEmail(String value) {
    if (value.isEmpty) {
      return "Email is empty";
    }
    if (!value.contains('@')) {
      return "It is not a valid email";
    }
    return null;
  }

  String? validatePassword(String value) {
    if (value.isEmpty) {
      return "Password is empty";
    }
    if (value.length < 8) {
      return "Password should contain min 8 characters!";
    }
    return null;
  }

  void login(BuildContext context) {
    if (validateEmail(emailController.text) == null &&
        validatePassword(passwordController.text) == null) {
      // Perform your login logic here
      Navigator.pushNamed(context, '/BottomNavBarExample');
    } else {
      notifyListeners();
    }
  }
}
