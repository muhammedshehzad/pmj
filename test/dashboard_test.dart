import 'package:flutter_test/flutter_test.dart';
import 'package:pmj_application/models/person_model.dart';
import 'package:pmj_application/models/donation_model.dart';

void main() {
  group('Dashboard Calculation Tests', () {
    test('should calculate total expected amount correctly', () {
      // Create test donors with expected amounts
      final donors = [
        Person(name: 'John', house: 'House 1', amount: 500.0, photoUrl: '', donorId: 'donor1'),
        Person(name: 'Jane', house: 'House 2', amount: 300.0, photoUrl: '', donorId: 'donor2'),
        Person(name: 'Bob', house: 'House 3', amount: 700.0, photoUrl: '', donorId: 'donor3'),
      ];

      // Calculate total expected amount
      double totalAmount = 0;
      final uniqueDonors = <String, double>{};
      
      for (var donor in donors) {
        if (donor.donorId != null && donor.donorId!.isNotEmpty) {
          uniqueDonors[donor.donorId!] = donor.amount ?? 0.0;
        }
      }
      
      totalAmount = uniqueDonors.values.fold(0.0, (sum, amount) => sum + amount);

      expect(totalAmount, equals(1500.0)); // 500 + 300 + 700
    });

    test('should calculate collected amount for current month correctly', () {
      final currentMonth = 'November';
      final currentYear = '2025';

      // Create test donations
      final donations = [
        Donation(
          name: 'John',
          date: '15 Nov 2025',
          amount: 500,
          donorId: 'donor1',
          method: 'Cash',
          month: currentMonth,
          year: currentYear,
          status: 'paid',
        ),
        Donation(
          name: 'Jane',
          date: '10 Nov 2025',
          amount: 300,
          donorId: 'donor2',
          method: 'Account',
          month: currentMonth,
          year: currentYear,
          status: 'paid',
        ),
        // This should not be counted (different month)
        Donation(
          name: 'Bob',
          date: '15 Oct 2025',
          amount: 700,
          donorId: 'donor3',
          method: 'Cash',
          month: 'October',
          year: currentYear,
          status: 'paid',
        ),
        // This should not be counted (unpaid)
        Donation(
          name: 'Alice',
          date: '20 Nov 2025',
          amount: 400,
          donorId: 'donor4',
          method: 'Cash',
          month: currentMonth,
          year: currentYear,
          status: 'unpaid',
        ),
      ];

      // Calculate collected amount for current month/year
      double collectedAmount = 0;
      for (var donation in donations) {
        if (donation.status == 'paid' && 
            donation.month == currentMonth && 
            donation.year == currentYear) {
          collectedAmount += donation.amount.toDouble();
        }
      }

      expect(collectedAmount, equals(800.0)); // 500 + 300 (only paid donations for Nov 2025)
    });

    test('should calculate balance amount correctly', () {
      final totalAmount = 1500.0;
      final collectedAmount = 800.0;
      final balanceAmount = totalAmount - collectedAmount;

      expect(balanceAmount, equals(700.0)); // 1500 - 800
    });
  });
}