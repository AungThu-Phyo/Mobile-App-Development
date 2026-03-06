import 'package:cloud_firestore/cloud_firestore.dart';

/// Types: 'request_accepted', 'request_rejected', 'session_updated', 'participant_left'
class NotificationModel {
  final String notificationId;
  final String recipientUid;
  final String senderUid;
  final String senderName;
  final String sessionId;
  final String sessionTitle;
  final String type;
  final String message;
  final bool isRead;
  final DateTime createdAt;

  const NotificationModel({
    required this.notificationId,
    required this.recipientUid,
    required this.senderUid,
    this.senderName = '',
    required this.sessionId,
    this.sessionTitle = '',
    required this.type,
    this.message = '',
    this.isRead = false,
    required this.createdAt,
  });

  factory NotificationModel.fromMap(Map<String, dynamic> map) {
    return NotificationModel(
      notificationId: map['notificationId'] as String? ?? '',
      recipientUid: map['recipientUid'] as String? ?? '',
      senderUid: map['senderUid'] as String? ?? '',
      senderName: map['senderName'] as String? ?? '',
      sessionId: map['sessionId'] as String? ?? '',
      sessionTitle: map['sessionTitle'] as String? ?? '',
      type: map['type'] as String? ?? '',
      message: map['message'] as String? ?? '',
      isRead: map['isRead'] as bool? ?? false,
      createdAt: (map['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'notificationId': notificationId,
      'recipientUid': recipientUid,
      'senderUid': senderUid,
      'senderName': senderName,
      'sessionId': sessionId,
      'sessionTitle': sessionTitle,
      'type': type,
      'message': message,
      'isRead': isRead,
      'createdAt': Timestamp.fromDate(createdAt),
    };
  }

  NotificationModel copyWith({bool? isRead}) {
    return NotificationModel(
      notificationId: notificationId,
      recipientUid: recipientUid,
      senderUid: senderUid,
      senderName: senderName,
      sessionId: sessionId,
      sessionTitle: sessionTitle,
      type: type,
      message: message,
      isRead: isRead ?? this.isRead,
      createdAt: createdAt,
    );
  }
}
