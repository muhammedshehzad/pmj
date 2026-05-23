import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:pin_code_fields/pin_code_fields.dart';
import '../providers/donor_auth_provider.dart';

/// Donor login screen with phone number input and OTP verification
class DonorLoginScreen extends StatefulWidget {
  const DonorLoginScreen({super.key});

  @override
  State<DonorLoginScreen> createState() => _DonorLoginScreenState();
}

class _DonorLoginScreenState extends State<DonorLoginScreen> {
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _otpController = TextEditingController();
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();

  @override
  void dispose() {
    _phoneController.dispose();
    _otpController.dispose();
    super.dispose();
  }

  /// Send OTP to phone number
  Future<void> _sendOTP(DonorAuthProvider authProvider) async {
    if (!_formKey.currentState!.validate()) return;

    // Format phone number with +91 country code
    final phoneNumber = '+91${_phoneController.text.trim()}';

    final success = await authProvider.sendOTP(phoneNumber);
    
    if (success && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('OTP sent successfully!'),
          backgroundColor: Color(0xff1BA3A1),
          duration: Duration(seconds: 2),
        ),
      );
    } else if (!success && mounted && authProvider.errorMessage != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(authProvider.errorMessage!),
          backgroundColor: Colors.red,
          duration: const Duration(seconds: 3),
        ),
      );
    }
  }

  /// Verify OTP and complete login
  Future<void> _verifyOTP(DonorAuthProvider authProvider) async {
    if (_otpController.text.length != 6) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please enter 6-digit OTP'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    final success = await authProvider.verifyOTP(_otpController.text);
    
    if (success && mounted) {
      // Navigate to donor dashboard on successful login
      Navigator.pushReplacementNamed(context, '/donor/dashboard');
    } else if (!success && mounted && authProvider.errorMessage != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(authProvider.errorMessage!),
          backgroundColor: Colors.red,
          duration: const Duration(seconds: 3),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Consumer<DonorAuthProvider>(
          builder: (context, authProvider, child) {
            return SingleChildScrollView(
              child: SizedBox(
                height: MediaQuery.of(context).size.height - MediaQuery.of(context).padding.top,
                child: Column(
                  children: [
                    SizedBox(height: MediaQuery.of(context).size.height * 0.1),
                    
                    // Logo
                    Hero(
                      tag: 'donor-logo',
                      child: Container(
                        height: 110,
                        width: 84,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Image.asset('lib/assets/images/PMJ Logo.png'),
                      ),
                    ),
                    
                    const SizedBox(height: 24),
                    
                    // Title
                    const Text(
                      'Donor Login',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: Color(0xff1BA3A1),
                        fontFamily: "Inter",
                      ),
                    ),
                    
                    const SizedBox(height: 8),
                    
                    // Subtitle
                    const Text(
                      'Enter your registered phone number',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey,
                        fontFamily: "Inter",
                      ),
                    ),
                    
                    const SizedBox(height: 40),
                    
                    // Phone input or OTP input
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 24.0),
                      child: authProvider.otpSent
                          ? _buildOTPInput(authProvider)
                          : _buildPhoneInput(authProvider),
                    ),
                    
                    const Spacer(),
                    
                    // Footer
                    const Padding(
                      padding: EdgeInsets.only(bottom: 50.0),
                      child: Text(
                        'Perakkool Muslim Jama-ath Committee',
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                          color: Colors.black54,
                          fontFamily: "Inter",
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  /// Build phone number input form
  Widget _buildPhoneInput(DonorAuthProvider authProvider) {
    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Phone Number',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              fontFamily: "Inter",
            ),
          ),
          const SizedBox(height: 8),
          
          // Phone number field
          TextFormField(
            controller: _phoneController,
            keyboardType: TextInputType.phone,
            maxLength: 10,
            decoration: InputDecoration(
              hintText: '9876543210',
              hintStyle: const TextStyle(
                fontSize: 14,
                color: Color(0xffA7A4AD),
                fontFamily: "Inter",
              ),
              prefixIcon: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 16),
                child: const Text(
                  '+91',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: Colors.black,
                    fontFamily: "Inter",
                  ),
                ),
              ),
              counterText: '',
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
            inputFormatters: [
              FilteringTextInputFormatter.digitsOnly,
            ],
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Please enter your phone number';
              }
              if (value.length != 10) {
                return 'Please enter a valid 10-digit phone number';
              }
              return null;
            },
          ),
          
          const SizedBox(height: 32),
          
          // Send OTP button
          SizedBox(
            width: double.infinity,
            height: 50,
            child: ElevatedButton(
              onPressed: authProvider.isLoading
                  ? null
                  : () => _sendOTP(authProvider),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xff1BA3A1),
                foregroundColor: Colors.white,
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(4),
                ),
                disabledBackgroundColor: const Color(0xff1BA3A1).withOpacity(0.6),
              ),
              child: authProvider.isLoading
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        color: Colors.white,
                        strokeWidth: 2.0,
                      ),
                    )
                  : const Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          'Send OTP',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            fontFamily: "Inter",
                          ),
                        ),
                        SizedBox(width: 8),
                        Icon(Icons.arrow_forward, size: 20),
                      ],
                    ),
            ),
          ),
          
          const SizedBox(height: 24),
          
          // Info text
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: const Color(0xff1BA3A1).withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(
                  Icons.info_outline,
                  size: 20,
                  color: Color(0xff1BA3A1),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'You will receive a 6-digit OTP on this number for verification.',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey[700],
                      fontFamily: "Inter",
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// Build OTP input form
  Widget _buildOTPInput(DonorAuthProvider authProvider) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Back button
        TextButton.icon(
          onPressed: authProvider.isVerifying
              ? null
              : () => authProvider.resetOTPState(),
          icon: const Icon(Icons.arrow_back, size: 18),
          label: const Text('Change Number'),
          style: TextButton.styleFrom(
            foregroundColor: const Color(0xff1BA3A1),
            padding: EdgeInsets.zero,
          ),
        ),
        
        const SizedBox(height: 16),
        
        const Text(
          'Enter OTP',
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.bold,
            fontFamily: "Inter",
          ),
        ),
        
        const SizedBox(height: 8),
        
        Text(
          'OTP sent to +91 ${_phoneController.text}',
          style: const TextStyle(
            fontSize: 12,
            color: Colors.grey,
            fontFamily: "Inter",
          ),
        ),
        
        const SizedBox(height: 24),
        
        // OTP input fields
        PinCodeTextField(
          appContext: context,
          length: 6,
          controller: _otpController,
          keyboardType: TextInputType.number,
          animationType: AnimationType.fade,
          pinTheme: PinTheme(
            shape: PinCodeFieldShape.box,
            borderRadius: BorderRadius.circular(8),
            fieldHeight: 50,
            fieldWidth: 45,
            activeFillColor: Colors.white,
            inactiveFillColor: Colors.white,
            selectedFillColor: Colors.white,
            activeColor: const Color(0xff1BA3A1),
            inactiveColor: Colors.grey[300]!,
            selectedColor: const Color(0xff1BA3A1),
          ),
          animationDuration: const Duration(milliseconds: 300),
          backgroundColor: Colors.transparent,
          enableActiveFill: true,
          onCompleted: (code) {
            // Auto-verify when all digits entered
            if (!authProvider.isVerifying) {
              _verifyOTP(authProvider);
            }
          },
          onChanged: (value) {},
        ),
        
        const SizedBox(height: 24),
        
        // Verify button
        SizedBox(
          width: double.infinity,
          height: 50,
          child: ElevatedButton(
            onPressed: authProvider.isVerifying
                ? null
                : () => _verifyOTP(authProvider),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xff1BA3A1),
              foregroundColor: Colors.white,
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(4),
              ),
              disabledBackgroundColor: const Color(0xff1BA3A1).withOpacity(0.6),
            ),
            child: authProvider.isVerifying
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      color: Colors.white,
                      strokeWidth: 2.0,
                    ),
                  )
                : const Text(
                    'Verify OTP',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      fontFamily: "Inter",
                    ),
                  ),
          ),
        ),
        
        const SizedBox(height: 16),
        
        // Resend OTP
        Center(
          child: TextButton(
            onPressed: authProvider.isLoading || authProvider.isVerifying
                ? null
                : () => authProvider.resendOTP(),
            child: const Text(
              'Resend OTP',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: Color(0xff1BA3A1),
                fontFamily: "Inter",
              ),
            ),
          ),
        ),
      ],
    );
  }
}
