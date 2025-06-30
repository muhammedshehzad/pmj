import 'dart:async';

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../assets/custom widgets/PeopleListViewHome.dart';
import 'package:hive/hive.dart';
import 'package:path_provider/path_provider.dart';

class DonationsProvider extends ChangeNotifier {
  final Map<String, Map<String, dynamic>> _donorCache = {};
  List<personHome> _donations = [];
  bool _isLoading = false;
  String? _errorMessage;
  QuerySnapshot? _latestSnapshot;
  bool _hasInitialData = false;
  StreamSubscription<QuerySnapshot>? _donationsSubscription;
  Box<personHome>? _donationsBox;

  List<personHome> get donations => _donations;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  DonationsProvider() {
    _initHiveAndLoad();
  }

  Future<void> _initHiveAndLoad() async {
    // Open Hive box for donations
    _donationsBox = await Hive.openBox<personHome>('donationsBox');
    // Load cached donations if available
    final cached = _donationsBox!.values.toList();
    if (cached.isNotEmpty) {
      _donations = cached;
      _isLoading = false;
      notifyListeners();
    }
    // Start Firestore listening
    _listenToDonations();
  }

  void _listenToDonations() {
    _isLoading = true;
    notifyListeners();
    _donationsSubscription = FirebaseFirestore.instance
        .collectionGroup('paymentStatus')
        .where('status', isEqualTo: 'paid')
        .orderBy('timestamp', descending: true)
        .snapshots()
        .listen((snapshot) async {
      if (_latestSnapshot == null || _latestSnapshot!.docs.length != snapshot.docs.length || _hasDataChanged(snapshot)) {
        _latestSnapshot = snapshot;
        _hasInitialData = true;
        await _processDocumentsAsync(snapshot.docs);
      }
    }, onError: (error) {
      _isLoading = false;
      _errorMessage = error.toString();
      notifyListeners();
    });
  }

  bool _hasDataChanged(QuerySnapshot newSnapshot) {
    if (_latestSnapshot == null) return true;
    final oldDocs = _latestSnapshot!.docs;
    final newDocs = newSnapshot.docs;
    if (oldDocs.length != newDocs.length) return true;
    for (int i = 0; i < oldDocs.length; i++) {
      if (oldDocs[i].id != newDocs[i].id || oldDocs[i].metadata.hasPendingWrites != newDocs[i].metadata.hasPendingWrites) {
        return true;
      }
    }
    return false;
  }

  Future<void> _processDocumentsAsync(List<QueryDocumentSnapshot> docs) async {
    _isLoading = true;
    notifyListeners();
    try {
      Set<String> donorIds = {};
      for (var doc in docs) {
        final donorId = doc.reference.parent.parent?.id;
        if (donorId != null && donorId.isNotEmpty) {
          donorIds.add(donorId);
        }
      }
      await _prefetchDonors(donorIds.toList());
      List<personHome> newDonations = [];
      for (var doc in docs) {
        final data = doc.data() as Map<String, dynamic>?;
        if (data == null) continue;
        final donorId = doc.reference.parent.parent?.id;
        if (donorId != null && donorId.isNotEmpty && _donorCache.containsKey(donorId)) {
          final donorData = _donorCache[donorId]!;
          final donorName = donorData['name'] ?? 'Unknown Donor';
          newDonations.add(personHome(
            name: donorName,
            date: _formatTimestamp(data['timestamp']),
            amount: _parseAmount(data['amount']),
            donorId: donorId,
            method: data['paymentMethod']?.toString() ?? 'Unknown',
            month: data['month']?.toString() ?? 'Unknown',
            year: data['year']?.toString() ?? 'Unknown',
            status: data['status']?.toString() ?? 'Unpaid',
            documentPath: doc.reference.path,
          ));
        }
      }
      _donations = newDonations;
      // Save to Hive
      await _donationsBox?.clear();
      await _donationsBox?.addAll(_donations);
      _isLoading = false;
      _errorMessage = null;
      notifyListeners();
    } catch (e) {
      _isLoading = false;
      _errorMessage = 'Failed to process donations: ${e.toString()}';
      notifyListeners();
    }
  }

  Future<void> _prefetchDonors(List<String> donorIds) async {
    if (donorIds.isEmpty) return;
    const int batchSize = 10;
    for (int i = 0; i < donorIds.length; i += batchSize) {
      final end = (i + batchSize < donorIds.length) ? i + batchSize : donorIds.length;
      final batch = donorIds.sublist(i, end);
      if (batch.isEmpty) continue;
      try {
        final donorsSnapshot = await FirebaseFirestore.instance
            .collection('donors')
            .where(FieldPath.documentId, whereIn: batch)
            .get(const GetOptions(source: Source.serverAndCache));
        for (var doc in donorsSnapshot.docs) {
          if (doc.exists && doc.data().isNotEmpty) {
            _donorCache[doc.id] = doc.data();
          }
        }
        if (i + batchSize < donorIds.length) {
          await Future.delayed(const Duration(milliseconds: 50));
        }
      } catch (e) {
        // Continue with other batches even if one fails
      }
    }
  }

  int _parseAmount(dynamic amount) {
    if (amount == null) return 0;
    if (amount is int) return amount;
    if (amount is double) return amount.toInt();
    if (amount is String) {
      try {
        return int.parse(amount);
      } catch (e) {
        try {
          return double.parse(amount).toInt();
        } catch (e) {
          return 0;
        }
      }
    }
    return 0;
  }

  String _formatTimestamp(dynamic timestamp) {
    if (timestamp == null) return '';
    if (timestamp is Timestamp) {
      final dt = timestamp.toDate();
      return '${dt.day.toString().padLeft(2, '0')}.${dt.month.toString().padLeft(2, '0')}.${dt.year}';
    }
    return timestamp.toString();
  }

  @override
  void dispose() {
    _donationsSubscription?.cancel();
    _donationsBox?.close();
    super.dispose();
  }
} 