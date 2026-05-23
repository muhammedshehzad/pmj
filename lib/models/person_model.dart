import 'package:cloud_firestore/cloud_firestore.dart' show DocumentSnapshot, Timestamp;

class Person {
  int? id;
  String name = '';
  String house = '';
  String phoneNumber = '';
  double amount = 0.0;
  String photoUrl = '';
  String? documentPath;
  String? donorId;
  String? date;
  String? month;
  String? year;
  String? method;
  String? status;
  String? imageUrl;
  DateTime? timestamp;
  List<String>? monthsList;
  double? totalDonationAmount;
  bool? isMainEntry;
  bool? hideFromHistory;
  String? donationId;

  Person({
    this.id,
    required this.name,
    required this.house,
    this.phoneNumber = '',
    required this.amount,
    required this.photoUrl,
    this.documentPath,
    this.donorId,
    this.date,
    this.month,
    this.year,
    this.method,
    this.status,
    this.imageUrl,
    this.timestamp,
    this.monthsList,
    this.totalDonationAmount,
    this.isMainEntry,
    this.hideFromHistory,
    this.donationId,
  });

  /// Creates a Person instance from Firestore document data
  factory Person.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>? ?? {};
    final timestamp = data['timestamp'] is Timestamp 
        ? (data['timestamp'] as Timestamp).toDate() 
        : (data['timestamp'] is DateTime ? data['timestamp'] as DateTime : null);
    
    return Person(
      name: data['name']?.toString() ?? 'Unknown Donor',
      house: data['address']?.toString() ?? data['house']?.toString() ?? 'Unknown',
      phoneNumber: data['number']?.toString() ?? data['phoneNumber']?.toString() ?? '',
      amount: (data['amount'] is num ? (data['amount'] as num).toDouble() : 0.0),
      photoUrl: data['photoUrl']?.toString() ?? data['imageUrl']?.toString() ?? '',
      documentPath: doc.reference.path,
      donorId: data['donorId']?.toString(),
      date: data['date']?.toString(),
      month: data['month']?.toString(),
      year: data['year']?.toString(),
      method: data['method']?.toString() ?? data['paymentMethod']?.toString(),
      status: data['status']?.toString() ?? 'Unpaid',
      imageUrl: data['imageUrl']?.toString(),
      monthsList: data['monthsList'] != null ? List<String>.from(data['monthsList']) : null,
      totalDonationAmount: (data['totalDonationAmount'] as num?)?.toDouble(),
      isMainEntry: data['isMainEntry'] as bool?,
      hideFromHistory: data['hideFromHistory'] as bool?,
      donationId: data['donationId']?.toString(),
      timestamp: timestamp,
    );
  }

  /// Creates a Person instance from a map (useful for JSON serialization)
  factory Person.fromMap(Map<String, dynamic> map) {
    return Person(
      id: map['id'] as int?,
      name: map['name'] as String? ?? 'Unknown',
      house: map['house'] as String? ?? map['address'] as String? ?? 'Unknown',
      phoneNumber: map['phoneNumber'] as String? ?? map['number'] as String? ?? '',
      amount: (map['amount'] as num?)?.toDouble() ?? 0.0,
      photoUrl: map['photoUrl'] as String? ?? '',
      documentPath: map['documentPath'] as String?,
      donorId: map['donorId'] as String?,
      date: map['date'] as String?,
      month: map['month'] as String?,
      year: map['year'] as String?,
      method: map['method'] as String?,
      status: map['status'] as String?,
      imageUrl: map['imageUrl'] as String?,
      timestamp: map['timestamp'] is DateTime 
          ? map['timestamp'] as DateTime 
          : (map['timestamp'] is Timestamp 
              ? (map['timestamp'] as Timestamp).toDate() 
              : null),
      monthsList: map['monthsList'] != null ? List<String>.from(map['monthsList']) : null,
      totalDonationAmount: (map['totalDonationAmount'] as num?)?.toDouble(),
      isMainEntry: map['isMainEntry'] != null ? (map['isMainEntry'] is int ? map['isMainEntry'] == 1 : map['isMainEntry'] as bool) : null,
      hideFromHistory: map['hideFromHistory'] != null ? (map['hideFromHistory'] is int ? map['hideFromHistory'] == 1 : map['hideFromHistory'] as bool) : null,
      donationId: map['donationId'] as String?,
    );
  }

  /// Converts the Person to a map for Firestore
  Map<String, dynamic> toFirestore() {
    return {
      'name': name,
      'address': house,
      'number': phoneNumber,
      'amount': amount,
      'photoUrl': photoUrl,
      if (documentPath != null) 'documentPath': documentPath,
      if (donorId != null) 'donorId': donorId,
      if (date != null) 'date': date,
      if (month != null) 'month': month,
      if (year != null) 'year': year,
      if (method != null) 'method': method,
      'status': status ?? 'Unpaid',
      if (imageUrl != null) 'imageUrl': imageUrl,
      'timestamp': timestamp,
      if (monthsList != null) 'monthsList': monthsList,
      if (totalDonationAmount != null) 'totalDonationAmount': totalDonationAmount,
      if (isMainEntry != null) 'isMainEntry': isMainEntry,
      if (hideFromHistory != null) 'hideFromHistory': hideFromHistory,
      if (donationId != null) 'donationId': donationId,
    };
  }

  /// Creates a copy of this Person with the given fields replaced with new values
  Person copyWith({
    int? id,
    String? name,
    String? house,
    String? phoneNumber,
    double? amount,
    String? photoUrl,
    String? documentPath,
    String? donorId,
    String? date,
    String? month,
    String? year,
    String? method,
    String? status,
    String? imageUrl,
    DateTime? timestamp,
    List<String>? monthsList,
    double? totalDonationAmount,
    bool? isMainEntry,
    bool? hideFromHistory,
    String? donationId,
  }) {
    return Person(
      id: id ?? this.id,
      name: name ?? this.name,
      house: house ?? this.house,
      phoneNumber: phoneNumber ?? this.phoneNumber,
      amount: amount ?? this.amount,
      photoUrl: photoUrl ?? this.photoUrl,
      documentPath: documentPath ?? this.documentPath,
      donorId: donorId ?? this.donorId,
      date: date ?? this.date,
      month: month ?? this.month,
      year: year ?? this.year,
      method: method ?? this.method,
      status: status ?? this.status,
      imageUrl: imageUrl ?? this.imageUrl,
      timestamp: timestamp ?? this.timestamp,
      monthsList: monthsList ?? this.monthsList,
      totalDonationAmount: totalDonationAmount ?? this.totalDonationAmount,
      isMainEntry: isMainEntry ?? this.isMainEntry,
      hideFromHistory: hideFromHistory ?? this.hideFromHistory,
      donationId: donationId ?? this.donationId,
    );
  }

  @override
  String toString() {
    return 'Person(id: $id, name: $name, house: $house, amount: $amount, donorId: $donorId)';
  }
}
