class ActivitySession {
  final String id;
  final String title;
  final String activityType;
  final String location;
  final DateTime startTime;
  final int durationMinutes;
  final String interactionLevel;
  final double minPartnerRating;
  final String createdBy;
  final String status;
  final String notes;

  const ActivitySession({
    required this.id,
    required this.title,
    required this.activityType,
    required this.location,
    required this.startTime,
    required this.durationMinutes,
    required this.interactionLevel,
    required this.minPartnerRating,
    required this.createdBy,
    required this.status,
    required this.notes,
  });

  factory ActivitySession.fromJson(Map<String, dynamic> json) {
    return ActivitySession(
      id: json['id'] as String,
      title: json['title'] as String,
      activityType: json['activityType'] as String,
      location: json['location'] as String,
      startTime: DateTime.parse(json['startTime'] as String),
      durationMinutes: json['durationMinutes'] as int,
      interactionLevel: json['interactionLevel'] as String,
      minPartnerRating: (json['minPartnerRating'] as num).toDouble(),
      createdBy: json['createdBy'] as String,
      status: json['status'] as String,
      notes: json['notes'] as String,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'activityType': activityType,
      'location': location,
      'startTime': startTime.toIso8601String(),
      'durationMinutes': durationMinutes,
      'interactionLevel': interactionLevel,
      'minPartnerRating': minPartnerRating,
      'createdBy': createdBy,
      'status': status,
      'notes': notes,
    };
  }

  ActivitySession copyWith({
    String? id,
    String? title,
    String? activityType,
    String? location,
    DateTime? startTime,
    int? durationMinutes,
    String? interactionLevel,
    double? minPartnerRating,
    String? createdBy,
    String? status,
    String? notes,
  }) {
    return ActivitySession(
      id: id ?? this.id,
      title: title ?? this.title,
      activityType: activityType ?? this.activityType,
      location: location ?? this.location,
      startTime: startTime ?? this.startTime,
      durationMinutes: durationMinutes ?? this.durationMinutes,
      interactionLevel: interactionLevel ?? this.interactionLevel,
      minPartnerRating: minPartnerRating ?? this.minPartnerRating,
      createdBy: createdBy ?? this.createdBy,
      status: status ?? this.status,
      notes: notes ?? this.notes,
    );
  }
}
