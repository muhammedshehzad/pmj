class Donation {
  int? id;
  
  final String name;
  
  final String date;
  final double amount;
  final String donorId;
  final String method;
  final String month;
  final String year;
  final String status;
  final List<String>? monthsList;
  final String? documentPath;
  final String? imageUrl;
  final double? totalDonationAmount;
  final bool? isMainEntry;
  final bool? hideFromHistory;

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
    this.monthsList,
    this.documentPath,
    this.imageUrl,
    this.totalDonationAmount,
    this.isMainEntry,
    this.hideFromHistory,
  });

  // Factory method to create a Donation from Firestore data
  factory Donation.fromFirestore(Map<String, dynamic> data) {
    return Donation(
      name: data['name'] ?? data['donorName'] ?? 'Unknown',
      date: data['date'] ?? '',
      amount: (data['amount'] as num?)?.toDouble() ?? 0.0,
      donorId: data['donorId'] ?? '',
      method: data['method'] ?? '',
      month: data['month'] ?? '',
      year: data['year'] ?? '',
      status: data['status'] ?? '',
      monthsList: data['monthsList'] != null ? List<String>.from(data['monthsList']) : null,
      documentPath: data['documentPath'],
      imageUrl: data['imageUrl'],
      totalDonationAmount: (data['totalDonationAmount'] as num?)?.toDouble(),
      isMainEntry: data['isMainEntry'] as bool?,
      hideFromHistory: data['hideFromHistory'] as bool?,
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
      'monthsList': monthsList,
      'documentPath': documentPath,
      'imageUrl': imageUrl,
      if (totalDonationAmount != null) 'totalDonationAmount': totalDonationAmount,
      if (isMainEntry != null) 'isMainEntry': isMainEntry,
      if (hideFromHistory != null) 'hideFromHistory': hideFromHistory,
    };
  }

  Donation copyWith({
    String? name,
    String? date,
    double? amount,
    String? donorId,
    String? method,
    String? month,
    String? year,
    String? status,
    List<String>? monthsList,
    String? documentPath,
    String? imageUrl,
    double? totalDonationAmount,
    bool? isMainEntry,
    bool? hideFromHistory,
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
      monthsList: monthsList ?? this.monthsList,
      documentPath: documentPath ?? this.documentPath,
      imageUrl: imageUrl ?? this.imageUrl,
      totalDonationAmount: totalDonationAmount ?? this.totalDonationAmount,
      isMainEntry: isMainEntry ?? this.isMainEntry,
      hideFromHistory: hideFromHistory ?? this.hideFromHistory,
    );
  }
}