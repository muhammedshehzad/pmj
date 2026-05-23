import 'dart:async';
import 'dart:developer';

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/person_model.dart';
import '../services/local_database_service.dart';

class DonationsProvider extends ChangeNotifier {
  final Map<String, Map<String, dynamic>> _donorCache = {};
  final LocalDatabaseService _localDb;
  List<Person> _donations = [];
  bool _isLoading = false;
  String? _errorMessage;
  QuerySnapshot? _latestSnapshot;
  bool _hasInitialData = false;
  StreamSubscription<QuerySnapshot>? _donationsSubscription;
  bool _isInitialized = false;

  List<Person> get donations => _donations;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  bool get isInitialized => _isInitialized;

  DonationsProvider({LocalDatabaseService? localDb}) 
      : _localDb = localDb ?? LocalDatabaseService() {
    _initIsarAndLoad();
  }

  Future<void> _initIsarAndLoad() async {
    try {
      _isLoading = true;
      notifyListeners();
      
      // Initialize local database
      await _localDb.init();
      
      // Initial sync with Firestore
      await _localDb.syncWithFirestore();
      
      // Load cached donations
      await _loadCachedDonations();
      
      // Start Firestore listening
      _listenToDonations();
    } catch (e, stackTrace) {
      log('Error in _initIsarAndLoad', error: e, stackTrace: stackTrace);
      _errorMessage = 'Could not load data. Check your connection.';
      _isLoading = false;
      _isInitialized = true;
      notifyListeners();
    }
  }

  void _listenToDonations() {
    // Always cancel the old subscription before creating a new one.
    _donationsSubscription?.cancel();
    _isLoading = true;
    notifyListeners();

    _donationsSubscription = FirebaseFirestore.instance
        .collectionGroup('paymentStatus')
        .where('status', isEqualTo: 'paid')
        .orderBy('timestamp', descending: true)
        .snapshots()
        .listen((snapshot) async {
      try {
        if (!_isInitialized) {
          _isInitialized = true;
          notifyListeners();
        }
        
        if (_latestSnapshot == null || 
            _latestSnapshot!.docs.length != snapshot.docs.length || 
            _hasDataChanged(snapshot)) {
          _latestSnapshot = snapshot;
          _hasInitialData = true;
          await _processDocumentsAsync(snapshot.docs);
        }
      } catch (e) {
        _errorMessage = 'Error processing updates: $e';
        _isLoading = false;
        notifyListeners();
      }
    }, onError: (Object error) {
      log('DonationsProvider Firestore error', error: error);
      _errorMessage = 'Could not load donations. Check your connection.';
      _isLoading = false;
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
    if (!_isInitialized) return;
    
    _isLoading = true;
    notifyListeners();
    
    try {
      // Let LocalDatabaseService handle the sync
      await _localDb.syncWithFirestore();
      
      // Reload from local database
      await _loadCachedDonations();
      
      _errorMessage = null;
    } catch (e, stackTrace) {
      log('Error in _processDocumentsAsync', error: e, stackTrace: stackTrace);
      // Fall back to cached data silently; only surface an error if cache is also empty.
      try {
        await _loadCachedDonations();
        if (_donations.isEmpty) {
          _errorMessage = 'Could not load data. Check your connection.';
        }
        // If cache has data, don't override with an error — user still sees content.
      } catch (cacheError) {
        log('Error loading from cache', error: cacheError);
        _errorMessage = 'Could not load data. Check your connection.';
      }
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> _loadCachedDonations() async {
    if (!_isInitialized) return;
    
    try {
      // Use the watchPeople stream to get cached donations
      final cachedDonationsStream = _localDb.watchPeople();
      final cachedDonations = await cachedDonationsStream.first;
          
      if (cachedDonations.isNotEmpty) {
        _donations = cachedDonations;
        
        // Pre-fetch donor data for cached donations
        final donorIds = _donations
            .where((p) => p.donorId != null)
            .map((p) => p.donorId!)
            .toSet()
            .toList();
        
        if (donorIds.isNotEmpty) {
          await _prefetchDonors(donorIds);
        }
        
        notifyListeners();
      }
    } catch (e, stackTrace) {
      log('Error loading cached donations', error: e, stackTrace: stackTrace);
      rethrow;
    }
  }

  Future<void> _prefetchDonors(List<String> donorIds) async {
    if (donorIds.isEmpty) return;
    
    // Filter out already cached donors
    final uncachedIds = donorIds.where((id) => !_donorCache.containsKey(id)).toList();
    if (uncachedIds.isEmpty) return;
    
    const int batchSize = 10;
    for (int i = 0; i < uncachedIds.length; i += batchSize) {
      final end = (i + batchSize < uncachedIds.length) ? i + batchSize : uncachedIds.length;
      final batch = uncachedIds.sublist(i, end);
      
      try {
        final donorsSnapshot = await FirebaseFirestore.instance
            .collection('donors')
            .where(FieldPath.documentId, whereIn: batch)
            .get(const GetOptions(source: Source.cache));
        
        // Update cache with fetched data
        for (var doc in donorsSnapshot.docs) {
          if (doc.exists && doc.data().isNotEmpty) {
            _donorCache[doc.id] = doc.data();
          }
        }
        
        // If we didn't get all requested donors from cache, try server
        final missingIds = batch.where((id) => !_donorCache.containsKey(id)).toList();
        if (missingIds.isNotEmpty) {
          try {
            final serverSnapshot = await FirebaseFirestore.instance
                .collection('donors')
                .where(FieldPath.documentId, whereIn: missingIds)
                .get(const GetOptions(source: Source.server));
                
            for (var doc in serverSnapshot.docs) {
              if (doc.exists && doc.data().isNotEmpty) {
                _donorCache[doc.id] = doc.data();
              }
            }
          } catch (e) {
            log('Error fetching donors from server', error: e);
          }
        }
        
        // Small delay between batches to avoid overwhelming the network
        if (i + batchSize < uncachedIds.length) {
          await Future.delayed(const Duration(milliseconds: 50));
        }
      } catch (e, stackTrace) {
        log('Error fetching donors batch', error: e, stackTrace: stackTrace);
      }
    }
  }

  int _parseAmount(dynamic amount) {
    if (amount == null) return 0;
    if (amount is int) return amount;
    if (amount is double) return amount.toInt();
    if (amount is String) {
      try {
        // Remove any non-numeric characters except decimal point
        final cleanAmount = amount.replaceAll(RegExp(r'[^\d.]'), '');
        if (cleanAmount.contains('.')) {
          return double.parse(cleanAmount).toInt();
        }
        return int.parse(cleanAmount);
      } catch (e) {
        debugPrint('Error parsing amount "$amount": $e');
        return 0;
      }
    }
    return 0;
  }

  String _formatTimestamp(dynamic timestamp) {
    if (timestamp == null) return 'Unknown Date';
    
    DateTime date;
    if (timestamp is Timestamp) {
      date = timestamp.toDate();
    } else if (timestamp is DateTime) {
      date = timestamp;
    } else if (timestamp is String) {
      try {
        date = DateTime.parse(timestamp);
      } catch (e) {
        debugPrint('Error parsing timestamp "$timestamp": $e');
        return 'Invalid Date';
      }
    } else {
      return 'Unknown Date';
    }
    
    // Format: DD/MM/YYYY
    final day = date.day.toString().padLeft(2, '0');
    final month = date.month.toString().padLeft(2, '0');
    return '$day/$month/${date.year}';
  }

  // dispose() must be synchronous — never mark it async.
  @override
  void dispose() {
    _donationsSubscription?.cancel();
    _donationsSubscription = null;
    _donorCache.clear();
    _donations = [];
    super.dispose();
  }

  Future<void> refresh() async {
    // Guard: cancel existing subscription before creating a new one.
    _donationsSubscription?.cancel();
    _donationsSubscription = null;

    _donations = [];
    _donorCache.clear();
    _latestSnapshot = null;
    _hasInitialData = false;
    _errorMessage = null;
    _isLoading = true;
    notifyListeners();

    try {
      await _localDb.syncWithFirestore();
      await _loadCachedDonations();
      _listenToDonations();
    } catch (e, stackTrace) {
      _errorMessage = 'Failed to refresh data. Please try again.';
      log('Error in refresh', error: e, stackTrace: stackTrace);
      _isLoading = false;
      notifyListeners();
    }
  }
}