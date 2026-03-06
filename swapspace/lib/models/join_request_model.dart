import 'package:cloud_firestore/cloud_firestore.dart';

class JoinRequestModel {
  final String requestId;
  final String sessionId;
  final String requesterUid;
  final String creatorUid;
  final String message;
  final String status;
  final DateTime createdAt;
  final DateTime updatedAt;

  const JoinRequestModel({
    required this.requestId,
    required this.sessionId,
    required this.requesterUid,
    required this.creatorUid,
    this.message = '',
    this.status = 'pending',
    required this.createdAt,
    required this.updatedAt,
  });

  factory JoinRequestModel.empty() {
    return JoinRequestModel(
      requestId: '',
      sessionId: '',
      requesterUid: '',
      creatorUid: '',
      message: '',
      status: 'pending',
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );
  }

  factory JoinRequestModel.fromMap(Map<String, dynamic> map) {
    return JoinRequestModel(
      requestId: map['requestId'] as String? ?? '',
      sessionId: map['sessionId'] as String? ?? '',
      requesterUid: map['requesterUid'] as String? ?? '',
      creatorUid: map['creatorUid'] as String? ?? '',
      message: map['message'] as String? ?? '',
      status: map['status'] as String? ?? 'pending',
      createdAt: (map['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      updatedAt: (map['updatedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'requestId': requestId,
      'sessionId': sessionId,
      'requesterUid': requesterUid,
      'creatorUid': creatorUid,
      'message': message,
      'status': status,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
    };
  }

  JoinRequestModel copyWith({
    String? requestId,
    String? sessionId,
    String? requesterUid,
    String? creatorUid,
    String? message,
    String? status,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return JoinRequestModel(
      requestId: requestId ?? this.requestId,
      sessionId: sessionId ?? this.sessionId,
      requesterUid: requesterUid ?? this.requesterUid,
      creatorUid: creatorUid ?? this.creatorUid,
      message: message ?? this.message,
      status: status ?? this.status,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
