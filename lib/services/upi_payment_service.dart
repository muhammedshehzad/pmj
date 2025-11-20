import 'package:url_launcher/url_launcher.dart';
import 'package:uuid/uuid.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/person_model.dart';

class UpiPaymentService {
  static Future<String> _getPayeeVpa() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('upi_id') ?? 'merchant@upi';
  }
  
  static Future<String> _getPayeeName() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('organization_name') ?? 'PMJ Donations';
  }
  
  /// Builds a UPI payment link
  static Future<String> buildUpiLink({
    String? payeeVpa,
    String? payeeName,
    required double amount,
    String transactionNote = 'Monthly Donation',
    String? transactionId,
  }) async {
    final vpa = payeeVpa ?? await _getPayeeVpa();
    final name = payeeName ?? await _getPayeeName();
    final tr = transactionId ?? const Uuid().v4();
    
    final params = {
      'pa': vpa,
      'pn': name,
      'am': amount.toStringAsFixed(2),
      'cu': 'INR',
      'tn': transactionNote,
      'tr': tr,
    };
    
    final encoded = params.entries
        .map((e) => '${Uri.encodeComponent(e.key)}=${Uri.encodeComponent(e.value)}')
        .join('&');
    
    return 'upi://pay?$encoded';
  }
  
  /// Creates a payment message with UPI link for a donor
  static Future<String> createPaymentMessage({
    required Person donor,
    String? customMessage,
    String? transactionId,
  }) async {
    final upiLink = await buildUpiLink(
      amount: donor.amount,
      transactionNote: 'Monthly Donation - ${donor.name}',
      transactionId: transactionId,
    );
    
    if (customMessage != null) {
      return customMessage.replaceAll('{upi_link}', upiLink)
          .replaceAll('{name}', donor.name)
          .replaceAll('{amount}', '₹${donor.amount.toStringAsFixed(0)}');
    }
    
    final orgName = await _getPayeeName();
    
    return '''Dear ${donor.name},

Please pay your monthly donation of ₹${donor.amount.toStringAsFixed(0)} using this link:

$upiLink

Thank you for your continued support!

- $orgName Team''';
  }
  
  /// Opens WhatsApp with pre-filled payment message
  static Future<bool> sendToWhatsApp({
    required Person donor,
    String? customMessage,
    String? transactionId,
  }) async {
    if (donor.phoneNumber.isEmpty) {
      throw Exception('Phone number not available for ${donor.name}');
    }
    
    final message = await createPaymentMessage(
      donor: donor,
      customMessage: customMessage,
      transactionId: transactionId,
    );
    
    // Clean phone number and ensure it has country code
    String cleanNumber = donor.phoneNumber.replaceAll(RegExp(r'[^0-9+]'), '');
    
    // Add India country code if not present
    if (!cleanNumber.startsWith('+91') && !cleanNumber.startsWith('91')) {
      if (cleanNumber.startsWith('+')) {
        cleanNumber = cleanNumber.substring(1);
      }
      if (cleanNumber.length == 10) {
        cleanNumber = '91$cleanNumber';
      }
    } else if (cleanNumber.startsWith('+91')) {
      cleanNumber = cleanNumber.substring(1);
    }
    
    final whatsappUrl = Uri.parse(
      'https://wa.me/$cleanNumber?text=${Uri.encodeComponent(message)}'
    );
    
    try {
      if (await canLaunchUrl(whatsappUrl)) {
        await launchUrl(whatsappUrl, mode: LaunchMode.externalApplication);
        return true;
      } else {
        throw Exception('Could not launch WhatsApp');
      }
    } catch (e) {
      throw Exception('Failed to open WhatsApp: $e');
    }
  }
  
  /// Opens SMS app with pre-filled payment message (fallback option)
  static Future<bool> sendToSMS({
    required Person donor,
    String? customMessage,
    String? transactionId,
  }) async {
    if (donor.phoneNumber.isEmpty) {
      throw Exception('Phone number not available for ${donor.name}');
    }
    
    final message = await createPaymentMessage(
      donor: donor,
      customMessage: customMessage,
      transactionId: transactionId,
    );
    
    final smsUrl = Uri.parse(
      'sms:${donor.phoneNumber}?body=${Uri.encodeComponent(message)}'
    );
    
    try {
      if (await canLaunchUrl(smsUrl)) {
        await launchUrl(smsUrl);
        return true;
      } else {
        throw Exception('Could not launch SMS app');
      }
    } catch (e) {
      throw Exception('Failed to open SMS: $e');
    }
  }
  
  /// Test UPI link by opening it directly (for testing purposes)
  static Future<bool> testUpiLink({
    required double amount,
    String? transactionId,
  }) async {
    final upiLink = await buildUpiLink(
      amount: amount,
      transactionNote: 'Test Payment',
      transactionId: transactionId,
    );
    
    final uri = Uri.parse(upiLink);
    
    try {
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
        return true;
      } else {
        throw Exception('Could not launch UPI app');
      }
    } catch (e) {
      throw Exception('Failed to open UPI app: $e');
    }
  }
  
  /// Batch send to multiple donors via WhatsApp
  static Future<Map<String, dynamic>> sendBatchWhatsApp({
    required List<Person> donors,
    String? customMessage,
    Function(Person donor, bool success, String? error)? onProgress,
  }) async {
    int successCount = 0;
    int failureCount = 0;
    List<String> errors = [];
    
    for (final donor in donors) {
      try {
        await sendToWhatsApp(
          donor: donor,
          customMessage: customMessage,
        );
        successCount++;
        onProgress?.call(donor, true, null);
        
        // Add small delay between WhatsApp opens to avoid overwhelming the system
        await Future.delayed(const Duration(milliseconds: 500));
      } catch (e) {
        failureCount++;
        final error = e.toString();
        errors.add('${donor.name}: $error');
        onProgress?.call(donor, false, error);
      }
    }
    
    return {
      'success': successCount,
      'failure': failureCount,
      'errors': errors,
      'total': donors.length,
    };
  }
}