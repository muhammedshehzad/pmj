import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import '../models/transaction_model.dart';

class TransactionService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  static const String _collection = 'transactions';

  Stream<List<TransactionModel>> watchTransactions() {
    return _firestore
        .collection(_collection)
        .orderBy('entryDate', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => TransactionModel.fromFirestore(doc.data(), doc.id))
            .toList())
        .handleError((error) {
      debugPrint('TransactionService.watchTransactions error: $error');
      return <TransactionModel>[];
    });
  }

  Stream<List<TransactionModel>> watchTransactionsByMonth(String month, String year) {
    return _firestore
        .collection(_collection)
        .where('month', isEqualTo: month)
        .where('year', isEqualTo: year)
        .orderBy('entryDate', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => TransactionModel.fromFirestore(doc.data(), doc.id))
            .toList())
        .handleError((error) {
      debugPrint('TransactionService.watchTransactionsByMonth error: $error');
      return <TransactionModel>[];
    });
  }

  Future<List<TransactionModel>> getTransactionsForMonth(String month, String year) async {
    try {
      final snapshot = await _firestore
          .collection(_collection)
          .where('month', isEqualTo: month)
          .where('year', isEqualTo: year)
          .orderBy('entryDate', descending: false)
          .get();
      return snapshot.docs
          .map((doc) => TransactionModel.fromFirestore(doc.data(), doc.id))
          .toList();
    } catch (e) {
      debugPrint('TransactionService.getTransactionsForMonth error: $e');
      return [];
    }
  }

  Future<List<TransactionModel>> getTransactionsForYear(String year) async {
    try {
      final snapshot = await _firestore
          .collection(_collection)
          .where('year', isEqualTo: year)
          .orderBy('entryDate', descending: false)
          .get();
      return snapshot.docs
          .map((doc) => TransactionModel.fromFirestore(doc.data(), doc.id))
          .toList();
    } catch (e) {
      debugPrint('TransactionService.getTransactionsForYear error: $e');
      return [];
    }
  }

  // Returns a map of month -> {income, expense, balance}
  Future<Map<String, Map<String, double>>> getYearlySummary(String year) async {
    const monthNames = [
      'January', 'February', 'March', 'April', 'May', 'June',
      'July', 'August', 'September', 'October', 'November', 'December',
    ];

    final result = <String, Map<String, double>>{
      for (final m in monthNames) m: {'income': 0.0, 'expense': 0.0, 'balance': 0.0},
    };

    try {
      final transactions = await getTransactionsForYear(year);
      for (final tx in transactions) {
        if (result.containsKey(tx.month)) {
          if (tx.isIncome) {
            result[tx.month]!['income'] = (result[tx.month]!['income'] ?? 0) + tx.amount;
          } else {
            result[tx.month]!['expense'] = (result[tx.month]!['expense'] ?? 0) + tx.amount;
          }
          result[tx.month]!['balance'] =
              (result[tx.month]!['income'] ?? 0) - (result[tx.month]!['expense'] ?? 0);
        }
      }

      // Add paid donation amounts as income per month
      final donationsSnapshot = await _firestore
          .collectionGroup('paymentStatus')
          .where('status', isEqualTo: 'paid')
          .where('year', isEqualTo: year)
          .get();

      for (final doc in donationsSnapshot.docs) {
        final data = doc.data();
        final month = data['month'] as String?;
        final amount = (data['amount'] as num?)?.toDouble() ?? 0.0;
        if (month != null && result.containsKey(month)) {
          result[month]!['income'] = (result[month]!['income'] ?? 0) + amount;
          result[month]!['balance'] =
              (result[month]!['income'] ?? 0) - (result[month]!['expense'] ?? 0);
        }
      }
    } catch (e) {
      debugPrint('TransactionService.getYearlySummary error: $e');
    }

    return result;
  }

  Future<String> addTransaction(TransactionModel tx) async {
    try {
      final ref = await _firestore.collection(_collection).add(tx.toFirestore());
      return ref.id;
    } catch (e) {
      debugPrint('TransactionService.addTransaction error: $e');
      rethrow;
    }
  }

  Future<void> updateTransaction(String id, TransactionModel tx) async {
    try {
      await _firestore.collection(_collection).doc(id).update(tx.toFirestoreUpdate());
    } catch (e) {
      debugPrint('TransactionService.updateTransaction error: $e');
      rethrow;
    }
  }

  Future<void> deleteTransaction(String id) async {
    try {
      final docRef = _firestore.collection(_collection).doc(id);
      final deletedRef = _firestore.collection('deleted_transactions').doc();

      // Atomic check-and-delete: if the doc is already gone, do nothing.
      // Prevents duplicate deletion-history entries when the same transaction
      // is dismissed/deleted twice in quick succession.
      await _firestore.runTransaction((tx) async {
        final snap = await tx.get(docRef);
        if (!snap.exists) return;

        tx.set(deletedRef, {
          ...snap.data()!,
          'originalId': id,
          'deletedAt': FieldValue.serverTimestamp(),
        });
        tx.delete(docRef);
      });
    } catch (e) {
      debugPrint('TransactionService.deleteTransaction error: $e');
      rethrow;
    }
  }

  /// Returns paid donations for a given month/year (used for monthly reports
  /// to include donation income alongside regular transactions).
  Future<List<Map<String, dynamic>>> getDonationsForMonth(
      String month, String year) async {
    try {
      final snapshot = await _firestore
          .collectionGroup('paymentStatus')
          .where('status', isEqualTo: 'paid')
          .where('month', isEqualTo: month)
          .where('year', isEqualTo: year)
          .get();
      return snapshot.docs
          .map((d) => d.data())
          .where((d) => d['hideFromHistory'] != true)
          .toList();
    } catch (e) {
      debugPrint('TransactionService.getDonationsForMonth error: $e');
      return [];
    }
  }
}
