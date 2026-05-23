import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import '../models/person_model.dart';
import '../services/upi_payment_service.dart';

class PaymentLinkSender extends StatefulWidget {
  final List<Person> donors;
  final String? customMessage;

  const PaymentLinkSender({
    super.key,
    required this.donors,
    this.customMessage,
  });

  @override
  State<PaymentLinkSender> createState() => _PaymentLinkSenderState();
}

class _PaymentLinkSenderState extends State<PaymentLinkSender> {
  final TextEditingController _messageController = TextEditingController();
  bool _isProcessing = false;
  Map<String, dynamic>? _lastResult;
  List<Person> _selectedDonors = [];

  @override
  void initState() {
    super.initState();
    _selectedDonors = List.from(widget.donors);
    _messageController.text = widget.customMessage ?? _getDefaultMessage();
  }

  String _getDefaultMessage() {
    return '''Dear {name},

Please pay your monthly donation of {amount} using this link:

{upi_link}

Thank you for your continued support!

- Team PMJ''';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xffFFFFFF),
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(100),
        child: AppBar(
          elevation: 0,
          backgroundColor: const Color(0xff1BA3A1),
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
                    padding: const EdgeInsets.only(left: 8.0),
                    child: Image.asset(
                      'lib/assets/images/pmj white.png',
                      height: 50,
                    ),
                  ),
                  Container(
                    height: 26,
                    width: 84,
                    child: ElevatedButton(
                      onPressed: _isProcessing ? null : _testUpiLink,
                      style: ElevatedButton.styleFrom(
                        foregroundColor: Colors.black,
                        backgroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(2),
                        ),
                        elevation: 0,
                      ),
                      child: const Center(
                        child: Text(
                          'Test',
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w600,
                            fontFamily: "Inter",
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
      body: SingleChildScrollView(
        child: Column(children: [
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
                'Send Payment Links',
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                  fontSize: 16,
                  fontFamily: "Inter",
                ),
              ),
            ),
            trailing: const SizedBox(width: 40), // Balance the layout
          ),

          // Main content area with icon and stats
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
                          borderRadius:
                              BorderRadius.circular(isSmallScreen ? 35 : 40),
                        ),
                        child: Icon(
                          Icons.message,
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
                            'Ready to Send',
                            style: TextStyle(
                              fontSize: isSmallScreen ? 14 : 16,
                              fontFamily: "Inter",
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            'Select donors and customize your message before sending payment links',
                            style: TextStyle(
                              fontSize: isSmallScreen ? 10 : 11,
                              fontFamily: "Inter",
                              fontWeight: FontWeight.w400,
                              color: Colors.grey[600],
                            ),
                          ),
                          const SizedBox(height: 8),
                          Row(
                            children: [
                              _buildMiniStatCard(
                                'Selected',
                                _selectedDonors.length.toString(),
                                Colors.green,
                              ),
                              const SizedBox(width: 6),
                              _buildMiniStatCard(
                                'Total',
                                widget.donors.length.toString(),
                                Colors.blue,
                              ),
                            ],
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
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Donor Selection Section
                Container(
                  padding: const EdgeInsets.all(16.0),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(8),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.grey.withOpacity(0.1),
                        spreadRadius: 1,
                        blurRadius: 4,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Selected Donors (${_selectedDonors.length})',
                            style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              fontFamily: "Inter",
                            ),
                          ),
                          Row(
                            children: [
                              TextButton(
                                onPressed: () {
                                  setState(() {
                                    _selectedDonors = List.from(widget.donors);
                                  });
                                },
                                child: const Text(
                                  'Select All',
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontFamily: "Inter",
                                    color: Color(0xff1BA3A1),
                                  ),
                                ),
                              ),
                              TextButton(
                                onPressed: () {
                                  setState(() {
                                    _selectedDonors.clear();
                                  });
                                },
                                child: const Text(
                                  'Clear All',
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontFamily: "Inter",
                                    color: Colors.red,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      ConstrainedBox(
                        constraints: BoxConstraints(
                          maxHeight: MediaQuery.of(context).size.height * 0.25,
                        ),
                        child: ListView.builder(
                          shrinkWrap: true,
                          itemCount: widget.donors.length,
                          itemBuilder: (context, index) {
                            final donor = widget.donors[index];
                            final isSelected = _selectedDonors.contains(donor);
                            final hasPhone = donor.phoneNumber.isNotEmpty;

                            return CheckboxListTile(
                              dense: true,
                              contentPadding: EdgeInsets.zero,
                              title: Text(
                                donor.name,
                                style: const TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w500,
                                  fontFamily: "Inter",
                                ),
                              ),
                              subtitle: Text(
                                hasPhone
                                    ? '${donor.phoneNumber} - ₹${donor.amount.toStringAsFixed(0)}'
                                    : 'No phone number - ₹${donor.amount.toStringAsFixed(0)}',
                                style: TextStyle(
                                  color: hasPhone
                                      ? const Color(0xff817D8A)
                                      : Colors.red,
                                  fontSize: 12,
                                  fontFamily: "Inter",
                                ),
                              ),
                              value: isSelected,
                              activeColor: const Color(0xff1BA3A1),
                              onChanged: hasPhone
                                  ? (bool? value) {
                                      setState(() {
                                        if (value == true) {
                                          _selectedDonors.add(donor);
                                        } else {
                                          _selectedDonors.remove(donor);
                                        }
                                      });
                                    }
                                  : null,
                            );
                          },
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 16),

                // Message Template Section
                Container(
                  padding: const EdgeInsets.all(16.0),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(8),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.grey.withOpacity(0.1),
                        spreadRadius: 1,
                        blurRadius: 4,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Message Template',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          fontFamily: "Inter",
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Use {name}, {amount}, and {upi_link} as placeholders',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey[600],
                          fontFamily: "Inter",
                        ),
                      ),
                      const SizedBox(height: 12),
                      TextField(
                        controller: _messageController,
                        maxLines: 6,
                        style: const TextStyle(
                          fontSize: 12,
                          fontFamily: "Inter",
                        ),
                        decoration: InputDecoration(
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                            borderSide: BorderSide(color: Colors.grey[300]!),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                            borderSide:
                                const BorderSide(color: Color(0xff1BA3A1)),
                          ),
                          hintText: 'Enter your message template...',
                          hintStyle: const TextStyle(
                            fontSize: 12,
                            fontFamily: "Inter",
                          ),
                          filled: true,
                          fillColor: Colors.grey[50],
                          contentPadding: const EdgeInsets.all(12),
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 16),

                // Action Buttons
                Row(
                  children: [
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: _isProcessing ? null : _sendViaWhatsApp,
                        icon: const Icon(Icons.message, size: 18),
                        label: const Text(
                          'WhatsApp',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            fontFamily: "Inter",
                          ),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xff25D366),
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: _isProcessing ? null : _sendViaSMS,
                        icon: const Icon(Icons.sms, size: 18),
                        label: const Text(
                          'SMS',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            fontFamily: "Inter",
                          ),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.blue,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),

                // Progress/Result Section
                if (_isProcessing) ...[
                  const SizedBox(height: 16),
                  Container(
                    padding: const EdgeInsets.all(16.0),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(8),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.grey.withOpacity(0.1),
                          spreadRadius: 1,
                          blurRadius: 4,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Row(
                      children: [
                        const CircularProgressIndicator(
                          valueColor:
                              AlwaysStoppedAnimation<Color>(Color(0xff1BA3A1)),
                          strokeWidth: 3,
                        ),
                        const SizedBox(width: 16),
                        const Text(
                          'Processing...',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                            fontFamily: "Inter",
                          ),
                        ),
                      ],
                    ),
                  ),
                ],

                if (_lastResult != null) ...[
                  const SizedBox(height: 16),
                  Container(
                    padding: const EdgeInsets.all(16.0),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(8),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.grey.withOpacity(0.1),
                          spreadRadius: 1,
                          blurRadius: 4,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Operation Result',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            fontFamily: "Inter",
                          ),
                        ),
                        const SizedBox(height: 12),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceAround,
                          children: [
                            _buildResultCard('Total',
                                '${_lastResult!['total']}', Colors.blue),
                            _buildResultCard('Success',
                                '${_lastResult!['success']}', Colors.green),
                            _buildResultCard('Failed',
                                '${_lastResult!['failure']}', Colors.red),
                          ],
                        ),
                        if (_lastResult!['errors'].isNotEmpty) ...[
                          const SizedBox(height: 12),
                          Text(
                            'Errors:',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: Colors.red[700],
                              fontFamily: "Inter",
                            ),
                          ),
                          const SizedBox(height: 4),
                          ...(_lastResult!['errors'] as List<String>).map(
                            (error) => Padding(
                              padding: const EdgeInsets.only(bottom: 2),
                              child: Text(
                                '• $error',
                                style: const TextStyle(
                                  color: Colors.red,
                                  fontSize: 11,
                                  fontFamily: "Inter",
                                ),
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ],
              ],
            ),
          ),
        ]),
      ),
    );
  }

  Future<void> _sendViaWhatsApp() async {
    if (_selectedDonors.isEmpty) {
      _showSnackBar('Please select at least one donor', Colors.red);
      return;
    }

    if (!mounted) return;

    setState(() {
      _isProcessing = true;
      _lastResult = null;
    });

    try {
      final result = await UpiPaymentService.sendBatchWhatsApp(
        donors: _selectedDonors,
        customMessage: _messageController.text.trim().isNotEmpty
            ? _messageController.text.trim()
            : null,
      );

      if (mounted) {
        setState(() {
          _lastResult = result;
        });

        _showSnackBar(
          'Completed: ${result['success']} sent, ${result['failure']} failed',
          result['failure'] == 0 ? Colors.green : Colors.orange,
        );
      }
    } catch (e) {
      debugPrint('Error sending WhatsApp messages: $e');
      if (mounted) {
        _showSnackBar('Failed to send messages. Please try again.', Colors.red);
      }
    } finally {
      if (mounted) {
        setState(() {
          _isProcessing = false;
        });
      }
    }
  }

  Future<void> _sendViaSMS() async {
    if (_selectedDonors.isEmpty) {
      _showSnackBar('Please select at least one donor', Colors.red);
      return;
    }

    if (!mounted) return;

    setState(() {
      _isProcessing = true;
      _lastResult = null;
    });

    int successCount = 0;
    int failureCount = 0;
    List<String> errors = [];

    try {
      for (final donor in _selectedDonors) {
        if (!mounted) break;

        try {
          await UpiPaymentService.sendToSMS(
            donor: donor,
            customMessage: _messageController.text.trim().isNotEmpty
                ? _messageController.text.trim()
                : null,
          );
          successCount++;
          await Future.delayed(const Duration(milliseconds: 500));
        } catch (e) {
          failureCount++;
          errors.add(
              '${donor.name}: ${e.toString().replaceAll('Exception: ', '')}');
          debugPrint('Error sending SMS to ${donor.name}: $e');
        }
      }

      if (mounted) {
        setState(() {
          _lastResult = {
            'success': successCount,
            'failure': failureCount,
            'errors': errors,
            'total': _selectedDonors.length,
          };
        });

        _showSnackBar(
          'Completed: $successCount sent, $failureCount failed',
          failureCount == 0 ? Colors.green : Colors.orange,
        );
      }
    } catch (e) {
      debugPrint('Error in SMS batch send: $e');
      if (mounted) {
        _showSnackBar(
            'Failed to send SMS messages. Please try again.', Colors.red);
      }
    } finally {
      if (mounted) {
        setState(() {
          _isProcessing = false;
        });
      }
    }
  }

  Future<void> _testUpiLink() async {
    try {
      await UpiPaymentService.testUpiLink(amount: 1.0);
      if (mounted) {
        _showSnackBar('UPI app opened successfully!', Colors.green);
      }
    } catch (e) {
      debugPrint('Error testing UPI link: $e');
      if (mounted) {
        _showSnackBar(
          'Failed to open UPI app. Please check your UPI configuration.',
          Colors.red,
        );
      }
    }
  }

  Widget _buildMiniStatCard(String title, String value, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            value,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: color,
              fontFamily: "Inter",
            ),
          ),
          Text(
            title,
            style: const TextStyle(
              fontSize: 10,
              color: Colors.grey,
              fontFamily: "Inter",
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildResultCard(String title, String value, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            value,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: color,
              fontFamily: "Inter",
            ),
          ),
          Text(
            title,
            style: const TextStyle(
              fontSize: 12,
              color: Colors.grey,
              fontFamily: "Inter",
            ),
          ),
        ],
      ),
    );
  }

  void _showSnackBar(String message, Color color) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          message,
          style: const TextStyle(
            fontFamily: "Inter",
            fontWeight: FontWeight.w500,
          ),
        ),
        backgroundColor: color,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
        margin: const EdgeInsets.all(16),
      ),
    );
  }

  @override
  void dispose() {
    _messageController.dispose();
    super.dispose();
  }
}
