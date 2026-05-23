import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';

class TransactionModel {
  final String? id;
  final String type; // 'income' or 'expense'
  final String name;
  final double amount;
  final DateTime entryDate;
  final String? description;
  final String? attachmentUrl;
  final String month;
  final String year;
  final Timestamp? createdAt;

  const TransactionModel({
    this.id,
    required this.type,
    required this.name,
    required this.amount,
    required this.entryDate,
    this.description,
    this.attachmentUrl,
    required this.month,
    required this.year,
    this.createdAt,
  });

  factory TransactionModel.fromFirestore(Map<String, dynamic> data, String id) {
    final entryTs = data['entryDate'];
    DateTime entryDate;
    if (entryTs is Timestamp) {
      entryDate = entryTs.toDate();
    } else {
      entryDate = DateTime.now();
    }
    return TransactionModel(
      id: id,
      type: data['type'] ?? 'income',
      name: data['name'] ?? '',
      amount: (data['amount'] as num?)?.toDouble() ?? 0.0,
      entryDate: entryDate,
      description: data['description'] as String?,
      attachmentUrl: data['attachmentUrl'] as String?,
      month: data['month'] ?? '',
      year: data['year'] ?? '',
      createdAt: data['createdAt'] as Timestamp?,
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'type': type,
      'name': name,
      'amount': amount,
      'entryDate': Timestamp.fromDate(entryDate),
      if (description != null && description!.isNotEmpty) 'description': description,
      if (attachmentUrl != null && attachmentUrl!.isNotEmpty) 'attachmentUrl': attachmentUrl,
      'month': month,
      'year': year,
      'createdAt': FieldValue.serverTimestamp(),
    };
  }

  Map<String, dynamic> toFirestoreUpdate() {
    return {
      'type': type,
      'name': name,
      'amount': amount,
      'entryDate': Timestamp.fromDate(entryDate),
      'description': description ?? '',
      'attachmentUrl': attachmentUrl ?? '',
      'month': month,
      'year': year,
    };
  }

  TransactionModel copyWith({
    String? id,
    String? type,
    String? name,
    double? amount,
    DateTime? entryDate,
    String? description,
    String? attachmentUrl,
    String? month,
    String? year,
    Timestamp? createdAt,
  }) {
    return TransactionModel(
      id: id ?? this.id,
      type: type ?? this.type,
      name: name ?? this.name,
      amount: amount ?? this.amount,
      entryDate: entryDate ?? this.entryDate,
      description: description ?? this.description,
      attachmentUrl: attachmentUrl ?? this.attachmentUrl,
      month: month ?? this.month,
      year: year ?? this.year,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  bool get isIncome => type == 'income';
  bool get isExpense => type == 'expense';

  String get formattedDate => DateFormat('dd MMM yyyy, hh:mm a').format(entryDate);
  String get formattedDateOnly => DateFormat('dd MMM yyyy').format(entryDate);
  String get formattedAmount => '₹${amount.toStringAsFixed(0)}';
}
