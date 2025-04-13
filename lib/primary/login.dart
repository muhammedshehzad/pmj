import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'login_provider.dart';

class AuthScreens extends StatefulWidget {
  const AuthScreens({super.key});

  @override
  State<AuthScreens> createState() => _AuthScreensState();
}

class _AuthScreensState extends State<AuthScreens> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => LoginProvider(),
      child: Scaffold(
        backgroundColor: Colors.white,
        body: SafeArea(
          child: SingleChildScrollView(
            keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
            child: SizedBox(
              height: MediaQuery.of(context).size.height,
              child: Column(
                children: [
                  SizedBox(height: MediaQuery.of(context).size.height * 0.15),
                  Hero(
                    tag: 'hero-tag',
                    child: SizedBox(
                      height: 110,
                      width: 84,
                      child: Image.asset('lib/assets/images/PMJ Logo.png'),
                    ),
                  ),
                  SizedBox(height: 58),
                  _LoginForm(formKey: _formKey),
                  const Spacer(),
                  const Padding(
                    padding: EdgeInsets.only(bottom: 50.0),
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
      ),
    );
  }
}

class _LoginForm extends StatelessWidget {
  final GlobalKey<FormState> formKey;

  const _LoginForm({required this.formKey});

  @override
  Widget build(BuildContext context) {
    return Consumer<LoginProvider>(
      builder: (context, loginProvider, child) {
        return Padding(
          padding: EdgeInsets.symmetric(
            horizontal: MediaQuery.of(context).size.width * 0.05,
          ),
          child: Form(
            key: formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildTextField(
                  label: 'Email Id',
                  controller: loginProvider.emailController,
                  hint: 'example@gmail.com',
                  keyboardType: TextInputType.emailAddress,
                  validator: (value) {
                    if (loginProvider.validateEmail != null) {
                      return loginProvider.validateEmail(value);
                    }
                    if (value == null || value.isEmpty) {
                      return 'Please enter your email';
                    }
                    if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$')
                        .hasMatch(value)) {
                      return 'Please enter a valid email';
                    }
                    return null;
                  },
                  iconPath: 'lib/assets/images/img.png',
                ),
                SizedBox(height: 16),
                _buildTextField(
                  label: 'Password',
                  controller: loginProvider.passwordController,
                  hint: '********',
                  obscureText: true,
                  validator: (value) {
                    if (loginProvider.validatePassword != null) {
                      return loginProvider.validatePassword(value);
                    }
                    if (value == null || value.isEmpty) {
                      return 'Please enter your password';
                    }
                    if (value.length < 6) {
                      return 'Password must be at least 6 characters';
                    }
                    return null;
                  },
                  iconPath: 'lib/assets/images/img_1.png',
                ),
                SizedBox(height: 24),
                SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      foregroundColor: Colors.white,
                      backgroundColor: const Color(0xff1BA3A1),
                      elevation: 0.0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                    onPressed: loginProvider.isLoading
                        ? null
                        : () async {
                      if (formKey.currentState!.validate()) {
                        try {
                          await loginProvider.login(context);
                        } catch (e) {
                          String errorMessage;
                          // Assuming FirebaseAuthException for error handling
                          if (e.toString().contains('wrong-password')) {
                            errorMessage = 'Incorrect password. Please try again.';
                          } else if (e.toString().contains('user-not-found')) {
                            errorMessage = 'No account found with this email.';
                          } else if (e.toString().contains('invalid-credential')) {
                            errorMessage = 'Invalid email or password.';
                          } else if (e.toString().contains('network-request-failed')) {
                            errorMessage = 'Network error. Please check your connection.';
                          } else if (e.toString().contains('too-many-requests')) {
                            errorMessage = 'Too many attempts. Try again later.';
                          } else if (e.toString().contains('user-disabled')) {
                            errorMessage = 'This account has been disabled.';
                          } else if (e.toString().contains('invalid-email')) {
                            errorMessage = 'Invalid email format.';
                          } else {
                            errorMessage = 'An error occurred. Please try again.';
                          }
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(errorMessage),
                              backgroundColor: Colors.red,
                            ),
                          );
                        }
                      }
                    },
                    child: loginProvider.isLoading
                        ? const CircularProgressIndicator(color: Colors.white)
                        : Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Text(
                          'Login',
                          style: TextStyle(
                            fontWeight: FontWeight.w600,
                            fontSize: 16,
                          ),
                        ),
                        const SizedBox(width: 5),
                        Padding(
                          padding: const EdgeInsets.only(left: 6.0),
                          child: Image.asset(
                            'lib/assets/images/img_2.png',
                            width: 20,
                            height: 20,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildTextField({
    required String label,
    required TextEditingController controller,
    required String hint,
    bool obscureText = false,
    TextInputType? keyboardType,
    String? Function(String?)? validator,
    required String iconPath,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 10,
            color: Colors.black,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 3),
        TextFormField(
          controller: controller,
          obscureText: obscureText,
          keyboardType: keyboardType,
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: const TextStyle(fontSize: 12, color: Color(0xffA7A4AD)),
            suffixIcon: Padding(
              padding: const EdgeInsets.all(14.0),
              child: Image.asset(
                iconPath,
                width: 16,
                height: 16,
              ),
            ),
            enabledBorder: const OutlineInputBorder(
              borderSide: BorderSide(color: Color(0xFF1BA3A1), width: 1.0),
            ),
            focusedBorder: const OutlineInputBorder(
              borderSide: BorderSide(color: Color(0xFF1BA3A1), width: 2.0),
            ),
            errorBorder: const OutlineInputBorder(
              borderSide: BorderSide(color: Colors.red, width: 1.0),
            ),
            focusedErrorBorder: const OutlineInputBorder(
              borderSide: BorderSide(color: Colors.red, width: 2.0),
            ),
          ),
          validator: validator,
        ),
      ],
    );
  }
}