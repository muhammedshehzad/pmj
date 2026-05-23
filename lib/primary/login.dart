import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'login_provider.dart';

class AuthScreens extends StatefulWidget {
  const AuthScreens({super.key});

  @override
  State<AuthScreens> createState() => _AuthScreensState();
}

class _AuthScreensState extends State<AuthScreens>
    with SingleTickerProviderStateMixin {
  final _signInKey = GlobalKey<FormState>();
  final _signUpKey = GlobalKey<FormState>();
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return ChangeNotifierProvider(
      create: (_) => LoginProvider(),
      child: Scaffold(
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        body: SafeArea(
          child: Column(
            children: [
              const SizedBox(height: 32),
              Hero(
                tag: 'hero-tag',
                child: SizedBox(
                  height: 90,
                  width: 70,
                  child: Image.asset('lib/assets/images/PMJ Logo.png'),
                ),
              ),
              const SizedBox(height: 24),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Container(
                  decoration: BoxDecoration(
                    color: isDark
                        ? const Color(0xFF1E1E1E)
                        : const Color(0xFFF2F2F3),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: TabBar(
                    controller: _tabController,
                    indicator: BoxDecoration(
                      color: const Color(0xff1BA3A1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    indicatorSize: TabBarIndicatorSize.tab,
                    dividerColor: Colors.transparent,
                    labelColor: Colors.white,
                    unselectedLabelColor:
                        isDark ? Colors.white70 : Colors.black54,
                    labelStyle: const TextStyle(
                        fontFamily: 'Inter',
                        fontWeight: FontWeight.w600,
                        fontSize: 14),
                    tabs: const [
                      Tab(text: 'Sign In'),
                      Tab(text: 'Sign Up'),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),
              Expanded(
                child: TabBarView(
                  controller: _tabController,
                  children: [
                    _SignInForm(formKey: _signInKey),
                    _SignUpForm(formKey: _signUpKey),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.only(bottom: 24, top: 8),
                child: Text(
                  'Perakkool Muslim Jama-ath Committee',
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                    color: isDark ? Colors.white54 : Colors.black54,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ─── Sign In ──────────────────────────────────────────────────────────────
class _SignInForm extends StatelessWidget {
  final GlobalKey<FormState> formKey;
  const _SignInForm({required this.formKey});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Consumer<LoginProvider>(
        builder: (context, provider, _) {
          return Form(
            key: formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _AuthField(
                  label: 'Email',
                  hint: 'example@gmail.com',
                  controller: provider.emailController,
                  validator: provider.validateEmail,
                  keyboardType: TextInputType.emailAddress,
                ),
                const SizedBox(height: 16),
                _AuthField(
                  label: 'Password',
                  hint: '********',
                  controller: provider.passwordController,
                  validator: provider.validatePassword,
                  obscureText: true,
                ),
                const SizedBox(height: 24),
                _PrimaryButton(
                  label: provider.isLoading ? 'Signing in…' : 'Sign In',
                  isLoading: provider.isLoading,
                  onPressed: provider.isLoading
                      ? null
                      : () async {
                          if (formKey.currentState!.validate()) {
                            await provider.login(context);
                          }
                        },
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

// ─── Sign Up ──────────────────────────────────────────────────────────────
class _SignUpForm extends StatelessWidget {
  final GlobalKey<FormState> formKey;
  const _SignUpForm({required this.formKey});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return SingleChildScrollView(
      keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Consumer<LoginProvider>(
        builder: (context, provider, _) {
          return Form(
            key: formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _AuthField(
                  label: 'Full Name',
                  hint: 'Your name',
                  controller: provider.nameController,
                  validator: provider.validateName,
                ),
                const SizedBox(height: 12),
                _AuthField(
                  label: 'Email',
                  hint: 'example@gmail.com',
                  controller: provider.emailController,
                  validator: provider.validateEmail,
                  keyboardType: TextInputType.emailAddress,
                ),
                const SizedBox(height: 12),
                _AuthField(
                  label: 'Password',
                  hint: 'At least 6 characters',
                  controller: provider.passwordController,
                  validator: provider.validatePassword,
                  obscureText: true,
                ),
                const SizedBox(height: 12),
                _AuthField(
                  label: 'Confirm Password',
                  hint: 'Re-enter password',
                  controller: provider.confirmPasswordController,
                  validator: provider.validateConfirmPassword,
                  obscureText: true,
                ),
                const SizedBox(height: 14),
                const Text(
                  'Requested Role',
                  style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      fontFamily: 'Inter'),
                ),
                const SizedBox(height: 6),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  decoration: BoxDecoration(
                    border: Border.all(
                        color: const Color(0xff1BA3A1), width: 1),
                  ),
                  child: DropdownButtonHideUnderline(
                    child: DropdownButton<String>(
                      isExpanded: true,
                      value: provider.requestedRole,
                      dropdownColor: Theme.of(context).cardColor,
                      items: const [
                        DropdownMenuItem(
                            value: 'collector',
                            child: Text('Donation Collector',
                                style: TextStyle(
                                    fontFamily: 'Inter', fontSize: 13))),
                        DropdownMenuItem(
                            value: 'admin',
                            child: Text('Admin',
                                style: TextStyle(
                                    fontFamily: 'Inter', fontSize: 13))),
                      ],
                      onChanged: (v) {
                        if (v != null) provider.setRequestedRole(v);
                      },
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: const Color(0xff1BA3A1).withOpacity(0.08),
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(
                      color: const Color(0xff1BA3A1).withOpacity(0.25),
                    ),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Icon(Icons.info_outline,
                          size: 16, color: Color(0xff1BA3A1)),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Your account will be reviewed by an admin before '
                          'access is granted.',
                          style: TextStyle(
                            fontFamily: 'Inter',
                            fontSize: 11,
                            color: isDark ? Colors.white70 : Colors.black87,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),
                _PrimaryButton(
                  label: provider.isLoading ? 'Submitting…' : 'Request Account',
                  isLoading: provider.isLoading,
                  onPressed: provider.isLoading
                      ? null
                      : () async {
                          if (formKey.currentState!.validate()) {
                            await provider.signup(context);
                          }
                        },
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

// ─── Shared form widgets ──────────────────────────────────────────────────
class _AuthField extends StatelessWidget {
  final String label;
  final String hint;
  final TextEditingController controller;
  final String? Function(String?)? validator;
  final bool obscureText;
  final TextInputType? keyboardType;

  const _AuthField({
    required this.label,
    required this.hint,
    required this.controller,
    this.validator,
    this.obscureText = false,
    this.keyboardType,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w600,
            fontFamily: 'Inter',
            color: isDark ? Colors.white : Colors.black,
          ),
        ),
        const SizedBox(height: 4),
        TextFormField(
          controller: controller,
          obscureText: obscureText,
          keyboardType: keyboardType,
          validator: validator,
          style: const TextStyle(fontFamily: 'Inter', fontSize: 14),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: const TextStyle(
                fontSize: 12,
                color: Color(0xffA7A4AD),
                fontFamily: 'Inter'),
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
            enabledBorder: const OutlineInputBorder(
              borderSide:
                  BorderSide(color: Color(0xFF1BA3A1), width: 1.0),
            ),
            focusedBorder: const OutlineInputBorder(
              borderSide:
                  BorderSide(color: Color(0xFF1BA3A1), width: 2.0),
            ),
            errorBorder: const OutlineInputBorder(
              borderSide: BorderSide(color: Colors.red, width: 1.0),
            ),
            focusedErrorBorder: const OutlineInputBorder(
              borderSide: BorderSide(color: Colors.red, width: 2.0),
            ),
          ),
        ),
      ],
    );
  }
}

class _PrimaryButton extends StatelessWidget {
  final String label;
  final bool isLoading;
  final VoidCallback? onPressed;

  const _PrimaryButton({
    required this.label,
    required this.isLoading,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 50,
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(
          foregroundColor: Colors.white,
          backgroundColor: const Color(0xff1BA3A1),
          elevation: 0,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
        ),
        onPressed: onPressed,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              label,
              style: const TextStyle(
                fontFamily: 'Inter',
                fontWeight: FontWeight.w600,
                fontSize: 16,
              ),
            ),
            if (isLoading) ...[
              const SizedBox(width: 10),
              const SizedBox(
                width: 18,
                height: 18,
                child: CircularProgressIndicator(
                  color: Colors.white,
                  strokeWidth: 2,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
