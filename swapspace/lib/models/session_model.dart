import 'package:cloud_firestore/cloud_firestore.dart';

class SessionModel {
  final String sessionId;
  final String creatorUid;
  final String creatorName;
  final String partnerUid;
  final String activityType;
  final String title;
  final String description;
  final String location;
  final DateTime date;
  final int durationMinutes;
  final String interactionPreference;
  final String status;
  final String faculty;
  final bool isActive;
  final int maxParticipants;
  final List<String> participantUids;
  final double minRating;
  final DateTime createdAt;
  final DateTime updatedAt;

  const SessionModel({
    required this.sessionId,
    required this.creatorUid,
    this.creatorName = '',
    this.partnerUid = '',
    required this.activityType,
    required this.title,
    this.description = '',
    required this.location,
    required this.date,
    this.durationMinutes = 60,
    this.interactionPreference = 'social',
    this.status = 'open',
    this.faculty = '',
    this.isActive = true,
    this.maxParticipants = 2,
    this.participantUids = const [],
    this.minRating = 0.0,
    required this.createdAt,
    required this.updatedAt,
  });

  factory SessionModel.empty() {
    return SessionModel(
      sessionId: '',
      creatorUid: '',
      creatorName: '',
      partnerUid: '',
      activityType: 'study',
      title: '',
      description: '',
      location: '',
      date: DateTime.now(),
      durationMinutes: 60,
      interactionPreference: 'social',
      status: 'open',
      faculty: '',
      isActive: true,
      maxParticipants: 2,
      participantUids: const [],
      minRating: 0.0,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );
  }

  factory SessionModel.fromMap(Map<String, dynamic> map) {
    return SessionModel(
      sessionId: map['sessionId'] as String? ?? '',
      creatorUid: map['creatorUid'] as String? ?? '',
      creatorName: map['creatorName'] as String? ?? '',
      partnerUid: map['partnerUid'] as String? ?? '',
      activityType: map['activityType'] as String? ?? 'study',
      title: map['title'] as String? ?? '',
      description: map['description'] as String? ?? '',
      location: map['location'] as String? ?? '',
      date: (map['date'] as Timestamp?)?.toDate() ?? DateTime.now(),
      durationMinutes: (map['durationMinutes'] as num?)?.toInt() ?? 60,
      interactionPreference:
          map['interactionPreference'] as String? ?? 'social',
      status: map['status'] as String? ?? 'open',
      faculty: map['faculty'] as String? ?? '',
      isActive: map['isActive'] as bool? ?? true,
      maxParticipants: (map['maxParticipants'] as num?)?.toInt() ?? 2,
      participantUids: (map['participantUids'] as List<dynamic>?)?.map((e) => e as String).toList() ?? const [],
      minRating: (map['minRating'] as num?)?.toDouble() ?? 0.0,
      createdAt: (map['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      updatedAt: (map['updatedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'sessionId': sessionId,
      'creatorUid': creatorUid,
      'creatorName': creatorName,
      'partnerUid': partnerUid,
      'activityType': activityType,
      'title': title,
      'description': description,
      'location': location,
      'date': Timestamp.fromDate(date),
      'durationMinutes': durationMinutes,
      'interactionPreference': interactionPreference,
      'status': status,
      'faculty': faculty,
      'isActive': isActive,
      'maxParticipants': maxParticipants,
      'participantUids': participantUids,
      'minRating': minRating,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
    };
  }

  SessionModel copyWith({
    String? sessionId,
    String? creatorUid,
    String? creatorName,
    String? partnerUid,
    String? activityType,
    String? title,
    String? description,
    String? location,
    DateTime? date,
    int? durationMinutes,
    String? interactionPreference,
    String? status,
    String? faculty,
    bool? isActive,
    int? maxParticipants,
    List<String>? participantUids,
    double? minRating,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return SessionModel(
      sessionId: sessionId ?? this.sessionId,
      creatorUid: creatorUid ?? this.creatorUid,
      creatorName: creatorName ?? this.creatorName,
      partnerUid: partnerUid ?? this.partnerUid,
      activityType: activityType ?? this.activityType,
      title: title ?? this.title,
      description: description ?? this.description,
      location: location ?? this.location,
      date: date ?? this.date,
      durationMinutes: durationMinutes ?? this.durationMinutes,
      interactionPreference:
          interactionPreference ?? this.interactionPreference,
      status: status ?? this.status,
      faculty: faculty ?? this.faculty,
      isActive: isActive ?? this.isActive,
      maxParticipants: maxParticipants ?? this.maxParticipants,
      participantUids: participantUids ?? this.participantUids,
      minRating: minRating ?? this.minRating,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
