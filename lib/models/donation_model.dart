class Donation {
  int? id;
  
  final String name;
  
  final String date;
  final int amount;
  final String donorId;
  final String method;
  final String month;
  final String year;
  final String status;
  final String? documentPath;
  final String? imageUrl;

  Donation({
    this.id,
    required this.name,
    required this.date,
    required this.amount,
    required this.donorId,
    required this.method,
    required this.month,
    required this.year,
    required this.status,
    this.documentPath,
    this.imageUrl,
  });

  // Factory method to create a Donation from Firestore data
  factory Donation.fromFirestore(Map<String, dynamic> data) {
    return Donation(
      name: data['name'] ?? 'Unknown',
      date: data['date'] ?? '',
      amount: (data['amount'] as num?)?.toInt() ?? 0,
      donorId: data['donorId'] ?? '',
      method: data['method'] ?? '',
      month: data['month'] ?? '',
      year: data['year'] ?? '',
      status: data['status'] ?? '',
      documentPath: data['documentPath'],
      imageUrl: data['imageUrl'],
    );
  }

  // Convert to Map for Firestore
  Map<String, dynamic> toFirestore() {
    return {
      'name': name,
      'date': date,
      'amount': amount,
      'donorId': donorId,
      'method': method,
      'month': month,
      'year': year,
      'status': status,
      'documentPath': documentPath,
      'imageUrl': imageUrl,
    };
  }

  // Create a copy of the donation with optional updates
  Donation copyWith({
    String? name,
    String? date,
    int? amount,
    String? donorId,
    String? method,
    String? month,
    String? year,
    String? status,
    String? documentPath,
    String? imageUrl,
  }) {
    return Donation(
      id: id,
      name: name ?? this.name,
      date: date ?? this.date,
      amount: amount ?? this.amount,
      donorId: donorId ?? this.donorId,
      method: method ?? this.method,
      month: month ?? this.month,
      year: year ?? this.year,
      status: status ?? this.status,
      documentPath: documentPath ?? this.documentPath,
      imageUrl: imageUrl ?? this.imageUrl,
    );
  }
}