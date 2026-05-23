import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:shared_preferences/shared_preferences.dart';

class UpiConfigScreen extends StatefulWidget {
  const UpiConfigScreen({super.key});

  @override
  State<UpiConfigScreen> createState() => _UpiConfigScreenState();
}

class _UpiConfigScreenState extends State<UpiConfigScreen> {
  final _formKey = GlobalKey<FormState>();
  final _upiIdController = TextEditingController();
  final _organizationNameController = TextEditingController();
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadConfig();
  }

  Future<void> _loadConfig() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      if (mounted) {
        setState(() {
          _upiIdController.text = prefs.getString('upi_id') ?? '';
          _organizationNameController.text = prefs.getString('organization_name') ?? 'PMJ Donations';
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint('Error loading UPI configuration: $e');
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _saveConfig() async {
    if (!_formKey.currentState!.validate()) return;

    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('upi_id', _upiIdController.text.trim());
      await prefs.setString('organization_name', _organizationNameController.text.trim());

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text(
              'UPI configuration saved successfully!',
              style: TextStyle(
                fontFamily: "Inter",
                fontWeight: FontWeight.w500,
              ),
            ),
            backgroundColor: Colors.green,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
            margin: const EdgeInsets.all(16),
          ),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      debugPrint('Error saving UPI configuration: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text(
              'Failed to save configuration. Please try again.',
              style: TextStyle(
                fontFamily: "Inter",
                fontWeight: FontWeight.w500,
              ),
            ),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
            margin: const EdgeInsets.all(16),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(100),
        child: AppBar(
          elevation: 0,
          backgroundColor: const Color(0xff1BA3A1),
          automaticallyImplyLeading: false,
          flexibleSpace: Align(
            alignment: Alignment.bottomCenter,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Padding(
                    padding: const EdgeInsets.only(left: 8.0),
                    child: Image.asset(
                      'lib/assets/images/pmj white.png',
                      height: 50,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(Color(0xff1BA3A1)),
              ),
            )
          : SingleChildScrollView(
              child: Column(
                children: [
                  // Header with back button and title
                  ListTile(
                    leading: GestureDetector(
                      onTap: () => Navigator.pop(context),
                      child: SvgPicture.asset(
                        'lib/assets/images/Back.svg',
                        height: 40,
                        width: 40,
                      ),
                    ),
                    title: const Center(
                      child: Text(
                        'UPI Configuration',
                        style: TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 16,
                          fontFamily: "Inter",
                        ),
                      ),
                    ),
                    trailing: const SizedBox(width: 40), // Balance the layout
                  ),
                  
                  // Main content area with icon and description
                  Container(
                    height: 140,
                    width: double.infinity,
                    margin: const EdgeInsets.symmetric(horizontal: 16.0),
                    child: LayoutBuilder(
                      builder: (context, constraints) {
                        final isSmallScreen = constraints.maxWidth < 400;
                        return Stack(
                          children: [
                            Positioned(
                              left: 20,
                              top: 20,
                              child: Container(
                                width: isSmallScreen ? 70 : 80,
                                height: isSmallScreen ? 70 : 80,
                                decoration: BoxDecoration(
                                  color: const Color(0xff1BA3A1),
                                  borderRadius: BorderRadius.circular(isSmallScreen ? 35 : 40),
                                ),
                                child: Icon(
                                  Icons.account_balance_wallet,
                                  size: isSmallScreen ? 35 : 40,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                            Positioned(
                              top: 17,
                              right: 20,
                              left: isSmallScreen ? 110 : 120,
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'UPI Setup',
                                    style: TextStyle(
                                      fontSize: isSmallScreen ? 14 : 16,
                                      fontFamily: "Inter",
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                  const SizedBox(height: 6),
                                  Text(
                                    'Configure your UPI details to receive payments from donors',
                                    style: TextStyle(
                                      fontSize: isSmallScreen ? 10 : 11,
                                      fontFamily: "Inter",
                                      fontWeight: FontWeight.w400,
                                      color: Colors.grey[600],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        );
                      },
                    ),
                  ),
                  
                  Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Form(
                      key: _formKey,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            padding: const EdgeInsets.all(16.0),
                            decoration: BoxDecoration(
                              color: Colors.blue.withOpacity(0.05),
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(color: Colors.blue.withOpacity(0.2)),
                            ),
                            child: Row(
                              children: [
                                const Icon(Icons.info, color: Colors.blue, size: 20),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Text(
                                    'This information will be used to generate payment links for your donors.',
                                    style: TextStyle(
                                      color: Colors.blue[800],
                                      fontSize: 12,
                                      fontFamily: "Inter",
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          
                          const SizedBox(height: 24),
                    
                          TextFormField(
                            controller: _upiIdController,
                            style: const TextStyle(
                              fontSize: 14,
                              fontFamily: "Inter",
                            ),
                            decoration: InputDecoration(
                              labelText: 'UPI ID *',
                              labelStyle: const TextStyle(
                                fontSize: 14,
                                fontFamily: "Inter",
                              ),
                              hintText: 'e.g., yourname@paytm, yourname@phonepe',
                              hintStyle: const TextStyle(
                                fontSize: 12,
                                fontFamily: "Inter",
                              ),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                              enabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(8),
                                borderSide: BorderSide(color: Colors.grey[300]!),
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(8),
                                borderSide: const BorderSide(color: Color(0xff1BA3A1)),
                              ),
                              prefixIcon: const Icon(
                                Icons.account_balance_wallet,
                                color: Color(0xff1BA3A1),
                              ),
                              filled: true,
                              fillColor: Theme.of(context).brightness == Brightness.dark ? const Color(0xFF1E1E1E) : Colors.grey[50],
                            ),
                            validator: (value) {
                              if (value == null || value.trim().isEmpty) {
                                return 'Please enter your UPI ID';
                              }
                              if (!value.contains('@')) {
                                return 'Please enter a valid UPI ID (e.g., name@bank)';
                              }
                              return null;
                            },
                          ),
                          
                          const SizedBox(height: 16),
                          
                          TextFormField(
                            controller: _organizationNameController,
                            style: const TextStyle(
                              fontSize: 14,
                              fontFamily: "Inter",
                            ),
                            decoration: InputDecoration(
                              labelText: 'Organization Name *',
                              labelStyle: const TextStyle(
                                fontSize: 14,
                                fontFamily: "Inter",
                              ),
                              hintText: 'e.g., PMJ Donations',
                              hintStyle: const TextStyle(
                                fontSize: 12,
                                fontFamily: "Inter",
                              ),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                              enabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(8),
                                borderSide: BorderSide(color: Colors.grey[300]!),
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(8),
                                borderSide: const BorderSide(color: Color(0xff1BA3A1)),
                              ),
                              prefixIcon: const Icon(
                                Icons.business,
                                color: Color(0xff1BA3A1),
                              ),
                              filled: true,
                              fillColor: Theme.of(context).brightness == Brightness.dark ? const Color(0xFF1E1E1E) : Colors.grey[50],
                            ),
                            validator: (value) {
                              if (value == null || value.trim().isEmpty) {
                                return 'Please enter organization name';
                              }
                              return null;
                            },
                          ),
                    
                          const SizedBox(height: 24),
                          
                          Container(
                            padding: const EdgeInsets.all(16.0),
                            decoration: BoxDecoration(
                              color: Colors.orange.withOpacity(0.05),
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(color: Colors.orange.withOpacity(0.2)),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    const Icon(Icons.lightbulb, color: Colors.orange, size: 20),
                                    const SizedBox(width: 8),
                                    Text(
                                      'Tips',
                                      style: TextStyle(
                                        fontSize: 14,
                                        fontWeight: FontWeight.bold,
                                        fontFamily: "Inter",
                                        color: Colors.orange[800],
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  '• Make sure your UPI ID is active and can receive payments\n'
                                  '• Test the payment link before sending to donors\n'
                                  '• Keep your organization name short and recognizable',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: Colors.orange[700],
                                    fontFamily: "Inter",
                                  ),
                                ),
                              ],
                            ),
                          ),
                          
                          const SizedBox(height: 32),
                          
                          SizedBox(
                            width: double.infinity,
                            child: ElevatedButton(
                              onPressed: _saveConfig,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xff1BA3A1),
                                foregroundColor: Colors.white,
                                padding: const EdgeInsets.symmetric(vertical: 16),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(8),
                                ),
                              ),
                              child: const Text(
                                'Save Configuration',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                  fontFamily: "Inter",
                                ),
                              ),
                            ),
                          ),
                          
                          const SizedBox(height: 32), // Bottom padding
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),

    );
  }

  @override
  void dispose() {
    _upiIdController.dispose();
    _organizationNameController.dispose();
    super.dispose();
  }
}