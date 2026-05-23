import 'dart:async';
import 'dart:developer';
import 'package:flutter/foundation.dart';
import '../models/transaction_model.dart';
import '../services/transaction_service.dart';

class TransactionProvider with ChangeNotifier {
  final TransactionService _service = TransactionService();

  List<TransactionModel> _transactions = [];
  bool _isLoading = false;
  String? _error;
  StreamSubscription<List<TransactionModel>>? _subscription;

  List<TransactionModel> get transactions => _transactions;
  List<TransactionModel> get incomeTransactions =>
      _transactions.where((t) => t.isIncome).toList();
  List<TransactionModel> get expenseTransactions =>
      _transactions.where((t) => t.isExpense).toList();

  bool get isLoading => _isLoading;
  String? get error => _error;

  double get totalIncome => incomeTransactions.fold(0.0, (s, t) => s + t.amount);
  double get totalExpense => expenseTransactions.fold(0.0, (s, t) => s + t.amount);
  double get balance => totalIncome - totalExpense;

  TransactionService get service => _service;

  // Auto-initialize on construction so callers don't need to call init() manually.
  TransactionProvider() {
    _subscribe();
  }

  void _subscribe() {
    // Guard against double-subscribe.
    _subscription?.cancel();
    _isLoading = true;
    _error = null;
    _subscription = _service.watchTransactions().listen(
      (list) {
        _transactions = list;
        _isLoading = false;
        _error = null;
        notifyListeners();
      },
      onError: (Object e, StackTrace st) {
        log('TransactionProvider stream error', error: e, stackTrace: st);
        _error = 'Could not load transactions. Check your connection.';
        _isLoading = false;
        notifyListeners();
      },
    );
  }

  // Kept for explicit refresh from UI (e.g. pull-to-refresh).
  void init() => _subscribe();

  Future<void> addTransaction(TransactionModel tx) async {
    await _service.addTransaction(tx);
  }

  Future<void> updateTransaction(String id, TransactionModel tx) async {
    await _service.updateTransaction(id, tx);
  }

  Future<void> deleteTransaction(String id) async {
    await _service.deleteTransaction(id);
  }

  @override
  void dispose() {
    _subscription?.cancel();
    _subscription = null;
    super.dispose();
  }
}
