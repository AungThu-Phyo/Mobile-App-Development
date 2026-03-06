import 'package:cloud_firestore/cloud_firestore.dart';

class FeedbackModel {
  final String feedbackId;
  final String sessionId;
  final String reviewerUid;
  final String revieweeUid;
  final int rating;
  final String comment;
  final bool didShowUp;
  final DateTime createdAt;

  const FeedbackModel({
    required this.feedbackId,
    required this.sessionId,
    required this.reviewerUid,
    required this.revieweeUid,
    this.rating = 0,
    this.comment = '',
    this.didShowUp = true,
    required this.createdAt,
  });

  factory FeedbackModel.empty() {
    return FeedbackModel(
      feedbackId: '',
      sessionId: '',
      reviewerUid: '',
      revieweeUid: '',
      rating: 0,
      comment: '',
      didShowUp: true,
      createdAt: DateTime.now(),
    );
  }

  factory FeedbackModel.fromMap(Map<String, dynamic> map) {
    return FeedbackModel(
      feedbackId: map['feedbackId'] as String? ?? '',
      sessionId: map['sessionId'] as String? ?? '',
      reviewerUid: map['reviewerUid'] as String? ?? '',
      revieweeUid: map['revieweeUid'] as String? ?? '',
      rating: (map['rating'] as num?)?.toInt() ?? 0,
      comment: map['comment'] as String? ?? '',
      didShowUp: map['didShowUp'] as bool? ?? true,
      createdAt: (map['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'feedbackId': feedbackId,
      'sessionId': sessionId,
      'reviewerUid': reviewerUid,
      'revieweeUid': revieweeUid,
      'rating': rating,
      'comment': comment,
      'didShowUp': didShowUp,
      'createdAt': Timestamp.fromDate(createdAt),
    };
  }

  FeedbackModel copyWith({
    String? feedbackId,
    String? sessionId,
    String? reviewerUid,
    String? revieweeUid,
    int? rating,
    String? comment,
    bool? didShowUp,
    DateTime? createdAt,
  }) {
    return FeedbackModel(
      feedbackId: feedbackId ?? this.feedbackId,
      sessionId: sessionId ?? this.sessionId,
      reviewerUid: reviewerUid ?? this.reviewerUid,
      revieweeUid: revieweeUid ?? this.revieweeUid,
      rating: rating ?? this.rating,
      comment: comment ?? this.comment,
      didShowUp: didShowUp ?? this.didShowUp,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}
