import 'package:cloud_firestore/cloud_firestore.dart';

/// Represents a user with authentication, role, and approval status.
///
/// Stored under `donorUsers/{uid}` (the collection name is legacy).
/// Roles: 'donor' | 'collector' | 'admin'.
/// Status: 'pending' | 'approved' | 'rejected'. Missing status → treated as
/// 'approved' (back-compat for existing accounts created before approval gate).
class DonorUser {
  final String userId;
  final String donorId; // Reference to donors collection (donor role only)
  final String phoneNumber;
  final String? email;
  final String? name;
  final String role; // 'donor' | 'collector' | 'admin'
  final String status; // 'pending' | 'approved' | 'rejected'
  final String? requestedRole; // What role the user asked for at signup
  final String? fcmToken;
  final DonorPreferences preferences;
  final DateTime createdAt;
  final DateTime lastLogin;

  DonorUser({
    required this.userId,
    required this.donorId,
    required this.phoneNumber,
    this.email,
    this.name,
    this.role = 'donor',
    this.status = 'approved',
    this.requestedRole,
    this.fcmToken,
    required this.preferences,
    required this.createdAt,
    required this.lastLogin,
  });

  /// Create DonorUser from Firestore document
  factory DonorUser.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>? ?? {};

    return DonorUser(
      userId: doc.id,
      donorId: data['donorId'] as String? ?? '',
      phoneNumber: data['phoneNumber'] as String? ?? '',
      email: data['email'] as String?,
      name: data['name'] as String?,
      role: data['role'] as String? ?? 'donor',
      status: data['status'] as String? ?? 'approved',
      requestedRole: data['requestedRole'] as String?,
      fcmToken: data['fcmToken'] as String?,
      preferences: DonorPreferences.fromMap(
        data['preferences'] as Map<String, dynamic>? ?? {},
      ),
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      lastLogin: (data['lastLogin'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  /// Create DonorUser from map
  factory DonorUser.fromMap(Map<String, dynamic> map, String userId) {
    return DonorUser(
      userId: userId,
      donorId: map['donorId'] as String? ?? '',
      phoneNumber: map['phoneNumber'] as String? ?? '',
      email: map['email'] as String?,
      name: map['name'] as String?,
      role: map['role'] as String? ?? 'donor',
      status: map['status'] as String? ?? 'approved',
      requestedRole: map['requestedRole'] as String?,
      fcmToken: map['fcmToken'] as String?,
      preferences: DonorPreferences.fromMap(
        map['preferences'] as Map<String, dynamic>? ?? {},
      ),
      createdAt: (map['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      lastLogin: (map['lastLogin'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  /// Convert to Firestore map
  Map<String, dynamic> toFirestore() {
    return {
      'donorId': donorId,
      'phoneNumber': phoneNumber,
      if (email != null) 'email': email,
      if (name != null) 'name': name,
      'role': role,
      'status': status,
      if (requestedRole != null) 'requestedRole': requestedRole,
      if (fcmToken != null) 'fcmToken': fcmToken,
      'preferences': preferences.toMap(),
      'createdAt': Timestamp.fromDate(createdAt),
      'lastLogin': Timestamp.fromDate(lastLogin),
    };
  }

  bool get isApproved => status == 'approved';
  bool get isPending => status == 'pending';
  bool get isRejected => status == 'rejected';

  /// Create a copy with updated fields
  DonorUser copyWith({
    String? userId,
    String? donorId,
    String? phoneNumber,
    String? email,
    String? name,
    String? role,
    String? status,
    String? requestedRole,
    String? fcmToken,
    DonorPreferences? preferences,
    DateTime? createdAt,
    DateTime? lastLogin,
  }) {
    return DonorUser(
      userId: userId ?? this.userId,
      donorId: donorId ?? this.donorId,
      phoneNumber: phoneNumber ?? this.phoneNumber,
      email: email ?? this.email,
      name: name ?? this.name,
      role: role ?? this.role,
      status: status ?? this.status,
      requestedRole: requestedRole ?? this.requestedRole,
      fcmToken: fcmToken ?? this.fcmToken,
      preferences: preferences ?? this.preferences,
      createdAt: createdAt ?? this.createdAt,
      lastLogin: lastLogin ?? this.lastLogin,
    );
  }

  @override
  String toString() {
    return 'DonorUser(userId: $userId, role: $role, status: $status)';
  }
}

/// Donor notification preferences
class DonorPreferences {
  final bool smsNotifications;
  final bool whatsappNotifications;
  final bool emailNotifications;
  final bool pushNotifications;

  DonorPreferences({
    this.smsNotifications = true,
    this.whatsappNotifications = true,
    this.emailNotifications = false,
    this.pushNotifications = true,
  });

  factory DonorPreferences.fromMap(Map<String, dynamic> map) {
    return DonorPreferences(
      smsNotifications: map['smsNotifications'] as bool? ?? true,
      whatsappNotifications: map['whatsappNotifications'] as bool? ?? true,
      emailNotifications: map['emailNotifications'] as bool? ?? false,
      pushNotifications: map['pushNotifications'] as bool? ?? true,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'smsNotifications': smsNotifications,
      'whatsappNotifications': whatsappNotifications,
      'emailNotifications': emailNotifications,
      'pushNotifications': pushNotifications,
    };
  }

  DonorPreferences copyWith({
    bool? smsNotifications,
    bool? whatsappNotifications,
    bool? emailNotifications,
    bool? pushNotifications,
  }) {
    return DonorPreferences(
      smsNotifications: smsNotifications ?? this.smsNotifications,
      whatsappNotifications: whatsappNotifications ?? this.whatsappNotifications,
      emailNotifications: emailNotifications ?? this.emailNotifications,
      pushNotifications: pushNotifications ?? this.pushNotifications,
    );
  }
}
