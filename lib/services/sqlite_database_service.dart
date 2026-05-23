import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import 'package:pmj_application/models/person_model.dart';
import 'package:pmj_application/services/image_cache_service.dart';

import '../models/donation_model.dart';

class SQLiteDatabaseService {
  static final SQLiteDatabaseService _instance = SQLiteDatabaseService._internal();
  Database? _database;
  bool _isInitialized = false;
  
  // Stream controllers for real-time updates
  final StreamController<List<Donation>> _donationsController = StreamController<List<Donation>>.broadcast();
  final StreamController<List<Person>> _peopleController = StreamController<List<Person>>.broadcast();

  bool get isInitialized => _isInitialized;

  factory SQLiteDatabaseService() {
    return _instance;
  }

  SQLiteDatabaseService._internal();

  Future<Database> get database async {
    if (!_isInitialized) {
      await init();
    }
    return _database!;
  }

  Future<void> init() async {
    if (_isInitialized) return;

    try {
      final databasesPath = await getDatabasesPath();
      final path = join(databasesPath, 'pmj_donations.db');

      _database = await openDatabase(
        path,
        version: 2,
        onCreate: (db, version) async {
          // Create persons table
          await db.execute('''
            CREATE TABLE persons (
              id INTEGER PRIMARY KEY AUTOINCREMENT,
              name TEXT NOT NULL,
              house TEXT NOT NULL,
              amount REAL,
              photoUrl TEXT,
              documentPath TEXT,
              donorId TEXT,
              date TEXT,
              month TEXT,
              year TEXT,
              method TEXT,
              status TEXT,
              imageUrl TEXT,
              timestamp INTEGER,
              monthsList TEXT,
              totalDonationAmount REAL,
              isMainEntry INTEGER,
              hideFromHistory INTEGER
            )
          ''');

          // Create donations table for compatibility
          await db.execute('''
            CREATE TABLE donations (
              id INTEGER PRIMARY KEY AUTOINCREMENT,
              name TEXT NOT NULL,
              date TEXT,
              amount INTEGER,
              donorId TEXT,
              method TEXT,
              month TEXT,
              year TEXT,
              status TEXT,
              documentPath TEXT,
              imageUrl TEXT
            )
          ''');

          // Create indexes for better performance
          await db.execute('CREATE INDEX idx_persons_donorId ON persons(donorId)');
          await db.execute('CREATE INDEX idx_persons_name ON persons(name)');
          await db.execute('CREATE INDEX idx_persons_timestamp ON persons(timestamp)');
        },
        onUpgrade: (db, oldVersion, newVersion) async {
          if (oldVersion < 2) {
            await db.execute('ALTER TABLE persons ADD COLUMN monthsList TEXT');
            await db.execute('ALTER TABLE persons ADD COLUMN totalDonationAmount REAL');
            await db.execute('ALTER TABLE persons ADD COLUMN isMainEntry INTEGER');
            await db.execute('ALTER TABLE persons ADD COLUMN hideFromHistory INTEGER');
          }
        },
      );

      // Initialize image cache service
      await ImageCacheService().init();

      _isInitialized = true;
      debugPrint('SQLite database initialized successfully');
    } catch (e) {
      debugPrint('Error initializing SQLiteDatabaseService: $e');
      rethrow;
    }
  }

  // Clear all local data (SQLite + image cache)
  Future<void> clearAllData() async {
    try {
      await init();
      final db = await database;
      
      // Clear all tables
      await db.delete('persons');
      await db.delete('donations');

      // Clear image cache files
      await ImageCacheService().clearCache();

      debugPrint('Local data cleared (SQLite + image cache)');
    } catch (e) {
      debugPrint('Error clearing local data: $e');
    }
  }

  // Delete a donation entry from local cache by its Firestore document path
  Future<void> deleteDonationByDocumentPath(String documentPath) async {
    await init();
    final db = await database;
    
    await db.delete(
      'persons',
      where: 'documentPath = ?',
      whereArgs: [documentPath],
    );
  }

  // Check if database has data
  Future<bool> databaseExists() async {
    try {
      await init();
      final db = await database;
      final count = await db.rawQuery('SELECT COUNT(*) as count FROM persons');
      final countValue = count.isNotEmpty
          ? (count.first['count'] is int
          ? count.first['count'] as int
          : int.tryParse(count.first['count'].toString()) ?? 0)
          : 0;
      return countValue > 0;
    } catch (e) {
      debugPrint('Error checking database existence: $e');
      return false;
    }
  }

  // Check if device is connected to the internet
  Future<bool> get isConnected async {
    final connectivityResult = await Connectivity().checkConnectivity();
    return !connectivityResult.contains(ConnectivityResult.none);
  }

  // Helper method to parse amount from dynamic value
  int _parseAmount(dynamic amount) {
    if (amount == null) return 0;
    if (amount is int) return amount;
    if (amount is double) return amount.toInt();
    if (amount is String) {
      try {
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

  // Helper method to format timestamp
  String _formatTimestamp(DateTime timestamp) {
    const monthNames = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
    ];
    final day = timestamp.day.toString().padLeft(2, '0');
    final monthName = monthNames[(timestamp.month - 1).clamp(0, 11)];
    final year = timestamp.year.toString();
    final ampm = timestamp.hour >= 12 ? 'PM' : 'AM';
    int h12 = timestamp.hour % 12;
    if (h12 == 0) h12 = 12;
    final hour = h12.toString().padLeft(2, '0');
    final minute = timestamp.minute.toString().padLeft(2, '0');
    return '$day $monthName $year, $hour:$minute $ampm';
  }

  Timer? _notifyTimer;

  // Notify all streams of data changes with debouncing
  Future<void> _notifyDataChanged() async {
    // Cancel previous timer if exists
    _notifyTimer?.cancel();
    
    // Debounce the notification to prevent rapid updates
    _notifyTimer = Timer(const Duration(milliseconds: 100), () async {
      try {
        final db = await database;
        
        // Fetch and emit donations
        final donationMaps = await db.rawQuery('SELECT * FROM persons ORDER BY timestamp DESC');
        final donations = donationMaps.map((map) => Donation(
          name: (map['name'] as String?) ?? '',
          date: (map['date'] as String?) ?? '',
          amount: (map['amount'] as num?)?.toDouble() ?? 0,
          donorId: (map['donorId'] as String?) ?? '',
          method: (map['method'] as String?) ?? '',
          month: (map['month'] as String?) ?? '',
          year: (map['year'] as String?) ?? '',
          status: (map['status'] as String?) ?? '',
          documentPath: map['documentPath'] as String?,
          imageUrl: () {
            final photoUrl = map['photoUrl'] as String?;
            final imageUrl = map['imageUrl'] as String?;
            if (photoUrl != null && photoUrl.isNotEmpty) {
              return photoUrl;
            }
            return imageUrl ?? '';
          }(),
          monthsList: map['monthsList'] != null && (map['monthsList'] as String).isNotEmpty
              ? (map['monthsList'] as String).split(',')
              : null,
          totalDonationAmount: (map['totalDonationAmount'] as num?)?.toDouble(),
          isMainEntry: map['isMainEntry'] == 1,
          hideFromHistory: map['hideFromHistory'] == 1,
        )).toList();
        
        if (!_donationsController.isClosed) {
          _donationsController.add(List<Donation>.from(donations));
        }

        // Fetch and emit people
        final peopleMaps = await db.rawQuery('SELECT * FROM persons');
        final people = peopleMaps.map((map) => Person(
          name: (map['name'] as String?) ?? '',
          house: (map['house'] as String?) ?? '',
          amount: (map['amount'] as num?)?.toDouble() ?? 0.0,
          photoUrl: (map['photoUrl'] as String?) ?? '',
          documentPath: map['documentPath'] as String?,
          donorId: map['donorId'] as String?,
          date: map['date'] as String?,
          month: map['month'] as String?,
          year: map['year'] as String?,
          method: map['method'] as String?,
          status: map['status'] as String?,
          imageUrl: map['imageUrl'] as String?,
          timestamp: map['timestamp'] != null 
              ? DateTime.fromMillisecondsSinceEpoch(map['timestamp'] as int)
              : null,
          monthsList: map['monthsList'] != null && (map['monthsList'] as String).isNotEmpty
              ? (map['monthsList'] as String).split(',')
              : null,
          totalDonationAmount: (map['totalDonationAmount'] as num?)?.toDouble(),
          isMainEntry: map['isMainEntry'] == 1,
          hideFromHistory: map['hideFromHistory'] == 1,
        )).toList();
        final processedPeople = _processPeople(people, '');
        
        if (!_peopleController.isClosed) {
          _peopleController.add(processedPeople);
        }
      } catch (e) {
        debugPrint('Error notifying data changes: $e');
      }
    });
  }

  // Watch all donations in real-time
  Stream<List<Donation>> watchDonations({String? query}) async* {
    await init();
    
    // Emit initial data only once
    if (!_donationsController.hasListener) {
      await _notifyDataChanged();
    }
    
    // Return the stream with filtering if needed
    yield* _donationsController.stream.distinct().map((donations) {
      if (query == null || query.isEmpty) return donations;
      
      final lowercaseQuery = query.toLowerCase();
      return donations.where((donation) {
        return donation.name.toLowerCase().contains(lowercaseQuery) ||
               donation.donorId.toLowerCase().contains(lowercaseQuery);
      }).toList();
    });
  }

  // Get a single person by ID
  Future<Person?> getPersonById(int id) async {
    try {
      final db = await database;
      final List<Map<String, dynamic>> maps = await db.query(
        'persons',
        where: 'id = ?',
        whereArgs: [id],
      );

      if (maps.isNotEmpty) {
        final map = maps.first;
        return Person(
          name: (map['name'] as String?) ?? '',
          house: (map['house'] as String?) ?? '',
          amount: (map['amount'] as num?)?.toDouble() ?? 0.0,
          photoUrl: (map['photoUrl'] as String?) ?? '',
          documentPath: map['documentPath'] as String?,
          donorId: map['donorId'] as String?,
          date: map['date'] as String?,
          month: map['month'] as String?,
          year: map['year'] as String?,
          method: map['method'] as String?,
          status: map['status'] as String?,
          imageUrl: map['imageUrl'] as String?,
          timestamp: map['timestamp'] != null 
              ? DateTime.fromMillisecondsSinceEpoch(map['timestamp'] as int)
              : null,
        );
      }
      return null;
    } catch (e) {
      debugPrint('Error getting person by ID $id: $e');
      return null;
    }
  }

  Future<void> syncWithFirestore() async {
    try {
      final isOnline = await isConnected;
      if (!isOnline) return;

      User? user = FirebaseAuth.instance.currentUser;
      if (user == null) return;

      // Step 1: Fetch ALL donors from the donors collection
      final donorsQuery = await FirebaseFirestore.instance
          .collection('donors')
          .get();

      final allDonors = <String, Map<String, dynamic>>{};
      for (var doc in donorsQuery.docs) {
        if (doc.exists && doc.data().isNotEmpty) {
          allDonors[doc.id] = doc.data();
        }
      }

      if (FirebaseAuth.instance.currentUser == null) return;

      // Step 2: Fetch ALL donations to get payment information
      final donationsQuery = await FirebaseFirestore.instance
          .collectionGroup('paymentStatus')
          .where('status', isEqualTo: 'paid')
          .orderBy('timestamp', descending: true)
          .get();

      // Clear existing data first
      final db = await database;
      await db.delete('persons');

      // Step 3: Add all donors with their expected amounts (for total calculation)
      for (var entry in allDonors.entries) {
        final donorId = entry.key;
        final donorData = entry.value;
        
        // Create a donor record with expected amount
        final donorRecord = {
          'name': donorData['name']?.toString() ?? 'Unknown Donor',
          'house': donorData['address']?.toString() ?? 'Unknown',
          'amount': _parseAmount(donorData['amount']).toDouble(), // Expected amount for total calculation
          'photoUrl': donorData['photoUrl']?.toString() ?? '',
          'documentPath': null,
          'donorId': donorId,
          'date': 'No Payment',
          'month': 'No Payment',
          'year': 'No Payment',
          'method': 'No Payment',
          'status': 'unpaid',
          'imageUrl': donorData['imageUrl']?.toString(),
          'timestamp': 0,
        };
        
        await db.insert('persons', donorRecord);
      }

      // Step 4: Add all payment records (for collected calculation)
      final now = DateTime.now();
      for (var doc in donationsQuery.docs) {
        try {
          final data = doc.data() as Map<String, dynamic>;
          final donorId = doc.reference.parent.parent?.id;

          if (donorId == null || donorId.isEmpty) continue;

          final timestamp = data['timestamp'] is Timestamp
              ? (data['timestamp'] as Timestamp).toDate()
              : now;

          // Get donor info
          final donorData = allDonors[donorId];
          if (donorData == null) continue;

          // Create a payment record
          final paymentRecord = {
            'name': donorData['name']?.toString() ?? 'Unknown Donor',
            'house': donorData['address']?.toString() ?? 'Unknown',
            'amount': _parseAmount(data['amount']).toDouble(), // Payment amount for collected calculation
            'photoUrl': donorData['photoUrl']?.toString() ?? '',
            'documentPath': doc.reference.path,
            'donorId': donorId,
            'date': _formatTimestamp(timestamp),
            'month': data['month']?.toString() ?? 'Unknown',
            'year': data['year']?.toString() ?? 'Unknown',
            'method': data['paymentMethod']?.toString() ?? 'Unknown',
            'status': data['status']?.toString() ?? 'paid',
            'imageUrl': donorData['imageUrl']?.toString(),
            'timestamp': timestamp.millisecondsSinceEpoch,
            'monthsList': data['monthsList'] != null ? (data['monthsList'] as List).join(',') : null,
            'totalDonationAmount': (data['totalDonationAmount'] as num?)?.toDouble() ?? _parseAmount(data['amount']).toDouble(),
            'isMainEntry': data['isMainEntry'] == true ? 1 : 0,
            'hideFromHistory': data['hideFromHistory'] == true ? 1 : 0,
          };

          await db.insert('persons', paymentRecord);
        } catch (e, stackTrace) {
          debugPrint('Error processing donation ${doc.id}: $e');
          debugPrint('Stack trace: $stackTrace');
        }
      }

      if (FirebaseAuth.instance.currentUser == null) return;

      // Notify streams of data changes
      await _notifyDataChanged();

      debugPrint('Successfully synced data to SQLite');
    } catch (e, stackTrace) {
      debugPrint('Error syncing with Firestore: $e');
      debugPrint('Stack trace: $stackTrace');
      rethrow;
    }
  }

  // Get all people with optional search query
  Stream<List<Person>> watchPeople({String query = ''}) async* {
    await init();

    // Emit initial data only once
    if (!_peopleController.hasListener) {
      await _notifyDataChanged();
    }

    // Return the stream with filtering if needed
    // Note: Automatic sync with Firestore has been removed to prevent unnecessary refreshes
    // Manual refresh can be triggered when needed via the refresh button
    yield* _peopleController.stream.distinct().map((people) {
      if (query.isEmpty) return people;
      
      final q = query.toLowerCase();
      return people.where((person) {
        final name = person.name.toLowerCase();
        final house = person.house.toLowerCase();
        final donorId = (person.donorId ?? '').toLowerCase();
        final amountStr = person.amount?.toStringAsFixed(0) ?? '0';
        return name.contains(q) ||
            house.contains(q) ||
            donorId.contains(q) ||
            amountStr.contains(q);
      }).toList();
    });
  }

  // Deduplicate donors and sort alphabetically
  List<Person> _processPeople(List<Person> input, String query) {
    final Map<String, Person> unique = {};
    for (final p in input) {
      final donorKey = (p.donorId != null && p.donorId!.trim().isNotEmpty)
          ? 'id:${p.donorId!.trim()}'
          : 'nh:${p.name.trim().toLowerCase()}|${p.house.trim().toLowerCase()}';

      if (!unique.containsKey(donorKey)) {
        unique[donorKey] = p;
      } else {
        final existing = unique[donorKey]!;
        final existingTs = existing.timestamp ?? DateTime.fromMillisecondsSinceEpoch(0);
        final currentTs = p.timestamp ?? DateTime.fromMillisecondsSinceEpoch(0);
        
        // Preserve the base amount from the actual donor profile (timestamp 0 or status unpaid)
        double baseAmount = existing.amount;
        if (p.status == 'unpaid' || p.timestamp?.millisecondsSinceEpoch == 0) {
          baseAmount = p.amount;
        } else if (existing.status == 'unpaid' || existing.timestamp?.millisecondsSinceEpoch == 0) {
          baseAmount = existing.amount;
        }

        if (currentTs.isAfter(existingTs)) {
          p.amount = baseAmount;
          unique[donorKey] = p;
        } else {
          existing.amount = baseAmount;
          unique[donorKey] = existing;
        }
      }
    }

    var list = unique.values.toList();

    // Filtering
    if (query.isNotEmpty) {
      final q = query.toLowerCase();
      list = list.where((person) {
        final name = person.name.toLowerCase();
        final house = person.house.toLowerCase();
        final donorId = (person.donorId ?? '').toLowerCase();
        final amountStr = person.amount?.toStringAsFixed(0) ?? '0';
        return name.contains(q) ||
            house.contains(q) ||
            donorId.contains(q) ||
            amountStr.contains(q);
      }).toList();
    }

    // Sort alphabetically
    list.sort((a, b) {
      final nameCmp = a.name.toLowerCase().compareTo(b.name.toLowerCase());
      if (nameCmp != 0) return nameCmp;
      final houseCmp = a.house.toLowerCase().compareTo(b.house.toLowerCase());
      if (houseCmp != 0) return houseCmp;
      return (a.donorId ?? '').compareTo(b.donorId ?? '');
    });

    return list;
  }

  // Add or update a person
  Future<void> upsertPerson(Person person) async {
    await init();
    final db = await database;
    
    final personMap = {
      'name': person.name,
      'house': person.house,
      'amount': person.amount,
      'photoUrl': person.photoUrl,
      'documentPath': person.documentPath,
      'donorId': person.donorId,
      'date': person.date,
      'month': person.month,
      'year': person.year,
      'method': person.method,
      'status': person.status,
      'imageUrl': person.imageUrl,
      'timestamp': person.timestamp?.millisecondsSinceEpoch,
      'monthsList': person.monthsList?.join(','),
      'totalDonationAmount': person.totalDonationAmount,
      'isMainEntry': person.isMainEntry == true ? 1 : 0,
      'hideFromHistory': person.hideFromHistory == true ? 1 : 0,
    };

    await db.insert(
      'persons',
      personMap,
      conflictAlgorithm: ConflictAlgorithm.replace,
    );

    // Notify streams of data changes
    await _notifyDataChanged();

    // If online, sync with Firestore
    if (await isConnected) {
      try {
        final user = FirebaseAuth.instance.currentUser;
        if (user != null) {
          await FirebaseFirestore.instance
              .collection('donors')
              .doc(person.donorId ?? person.id.toString())
              .set(person.toFirestore());
        }
      } catch (e) {
        debugPrint('Error syncing with Firestore: $e');
      }
    }
  }

  // Delete a person
  Future<Person?> deletePerson(int id) async {
    await init();
    final db = await database;
    
    // Get person before deleting
    final person = await getPersonById(id);
    
    await db.delete(
      'persons',
      where: 'id = ?',
      whereArgs: [id],
    );

    // Notify streams of data changes
    await _notifyDataChanged();

    // If online, delete from Firestore
    if (await isConnected) {
      try {
        final user = FirebaseAuth.instance.currentUser;
        if (user != null && person?.donorId != null) {
          await FirebaseFirestore.instance
              .collection('donors')
              .doc(person!.donorId!)
              .delete();
        }
      } catch (e) {
        debugPrint('Error deleting from Firestore: $e');
        return person;
      }
    }
    return null;
  }

  // Dispose method to close stream controllers
  void dispose() {
    _notifyTimer?.cancel();
    _donationsController.close();
    _peopleController.close();
  }
}
