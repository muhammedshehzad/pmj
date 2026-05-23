import 'package:cloud_firestore/cloud_firestore.dart';

/// Types of notifications that can be sent to donors
enum NotificationType {
  paymentReminder,
  paymentSuccess,
  announcement,
  general,
}

/// Represents a notification for a donor
class DonorNotification {
  final String notificationId;
  final String donorId;
  final String title;
  final String body;
  final NotificationType type;
  final bool isRead;
  final DateTime createdAt;
  final Map<String, dynamic>? data; // Additional data if needed

  DonorNotification({
    required this.notificationId,
    required this.donorId,
    required this.title,
    required this.body,
    required this.type,
    this.isRead = false,
    required this.createdAt,
    this.data,
  });

  /// Create DonorNotification from Firestore document
  factory DonorNotification.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>? ?? {};
    
    return DonorNotification(
      notificationId: doc.id,
      donorId: data['donorId'] as String? ?? '',
      title: data['title'] as String? ?? '',
      body: data['body'] as String? ?? '',
      type: _parseNotificationType(data['type'] as String?),
      isRead: data['isRead'] as bool? ?? false,
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      data: data['data'] as Map<String, dynamic>?,
    );
  }

  /// Create DonorNotification from map
  factory DonorNotification.fromMap(Map<String, dynamic> map, String notificationId) {
    return DonorNotification(
      notificationId: notificationId,
      donorId: map['donorId'] as String? ?? '',
      title: map['title'] as String? ?? '',
      body: map['body'] as String? ?? '',
      type: _parseNotificationType(map['type'] as String?),
      isRead: map['isRead'] as bool? ?? false,
      createdAt: (map['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      data: map['data'] as Map<String, dynamic>?,
    );
  }

  /// Convert to Firestore map
  Map<String, dynamic> toFirestore() {
    return {
      'donorId': donorId,
      'title': title,
      'body': body,
      'type': _typeToString(type),
      'isRead': isRead,
      'createdAt': Timestamp.fromDate(createdAt),
      if (data != null) 'data': data,
    };
  }

  /// Parse notification type from string
  static NotificationType _parseNotificationType(String? typeString) {
    switch (typeString) {
      case 'payment_reminder':
        return NotificationType.paymentReminder;
      case 'payment_success':
        return NotificationType.paymentSuccess;
      case 'announcement':
        return NotificationType.announcement;
      default:
        return NotificationType.general;
    }
  }

  /// Convert notification type to string
  static String _typeToString(NotificationType type) {
    switch (type) {
      case NotificationType.paymentReminder:
        return 'payment_reminder';
      case NotificationType.paymentSuccess:
        return 'payment_success';
      case NotificationType.announcement:
        return 'announcement';
      case NotificationType.general:
        return 'general';
    }
  }

  /// Create a copy with updated fields
  DonorNotification copyWith({
    String? notificationId,
    String? donorId,
    String? title,
    String? body,
    NotificationType? type,
    bool? isRead,
    DateTime? createdAt,
    Map<String, dynamic>? data,
  }) {
    return DonorNotification(
      notificationId: notificationId ?? this.notificationId,
      donorId: donorId ?? this.donorId,
      title: title ?? this.title,
      body: body ?? this.body,
      type: type ?? this.type,
      isRead: isRead ?? this.isRead,
      createdAt: createdAt ?? this.createdAt,
      data: data ?? this.data,
    );
  }

  @override
  String toString() {
    return 'DonorNotification(id: $notificationId, title: $title, type: ${_typeToString(type)}, isRead: $isRead)';
  }
}
