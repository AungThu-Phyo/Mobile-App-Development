import 'package:cloud_firestore/cloud_firestore.dart';
import '../core/constants/session_constants.dart';

class JoinRequestModel {
  final String requestId;
  final String sessionId;
  final String requesterUid;
  final String creatorUid;
  final String requestType;
  final String message;
  final String status;
  final DateTime createdAt;
  final DateTime updatedAt;

  const JoinRequestModel({
    required this.requestId,
    required this.sessionId,
    required this.requesterUid,
    required this.creatorUid,
    this.requestType = JoinRequestType.join,
    this.message = '',
    this.status = JoinRequestStatus.pending,
    required this.createdAt,
    required this.updatedAt,
  });

  factory JoinRequestModel.empty() {
    return JoinRequestModel(
      requestId: '',
      sessionId: '',
      requesterUid: '',
      creatorUid: '',
      requestType: JoinRequestType.join,
      message: '',
      status: JoinRequestStatus.pending,
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
      requestType: map['requestType'] as String? ?? JoinRequestType.join,
      message: map['message'] as String? ?? '',
      status: map['status'] as String? ?? JoinRequestStatus.pending,
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
      'requestType': requestType,
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
    String? requestType,
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
      requestType: requestType ?? this.requestType,
      message: message ?? this.message,
      status: status ?? this.status,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
