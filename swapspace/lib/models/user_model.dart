import 'package:cloud_firestore/cloud_firestore.dart';

class UserModel {
  final String uid;
  final String name;
  final String email;
  final String avatarUrl;
  final double rating;
  final int totalSessions;
  final DateTime createdAt;
  final DateTime lastSeen;
  final bool isActive;
  final bool isProfileComplete;
  final String faculty;
  final String bio;
  final List<String> activityPreferences;
  final String interactionPreference;

  const UserModel({
    required this.uid,
    required this.name,
    required this.email,
    this.avatarUrl = '',
    this.rating = 0.0,
    this.totalSessions = 0,
    required this.createdAt,
    required this.lastSeen,
    this.isActive = true,
    this.isProfileComplete = false,
    this.faculty = '',
    this.bio = '',
    this.activityPreferences = const [],
    this.interactionPreference = 'social',
  });

  /// Empty user (used as fallback / placeholder)
  factory UserModel.empty() {
    return UserModel(
      uid: '',
      name: '',
      email: '',
      avatarUrl: '',
      rating: 0.0,
      totalSessions: 0,
      createdAt: DateTime.now(),
      lastSeen: DateTime.now(),
      isActive: true,
      isProfileComplete: false,
      faculty: '',
      bio: '',
      activityPreferences: const [],
      interactionPreference: 'social',
    );
  }

  /// Create from Firestore document map
  factory UserModel.fromMap(Map<String, dynamic> map) {
    return UserModel(
      uid: map['uid'] as String? ?? '',
      name: map['name'] as String? ?? '',
      email: map['email'] as String? ?? '',
      avatarUrl: map['avatarUrl'] as String? ?? '',
      rating: (map['rating'] as num?)?.toDouble() ?? 0.0,
      totalSessions: (map['totalSessions'] as num?)?.toInt() ?? 0,
      createdAt: (map['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      lastSeen: (map['lastSeen'] as Timestamp?)?.toDate() ?? DateTime.now(),
      isActive: map['isActive'] as bool? ?? true,
      isProfileComplete: map['isProfileComplete'] as bool? ?? false,
      faculty: map['faculty'] as String? ?? '',
      bio: map['bio'] as String? ?? '',
      activityPreferences:
          List<String>.from(map['activityPreferences'] as List? ?? []),
      interactionPreference:
          map['interactionPreference'] as String? ?? 'social',
    );
  }

  /// Convert to Firestore-compatible map
  Map<String, dynamic> toMap() {
    return {
      'uid': uid,
      'name': name,
      'email': email,
      'avatarUrl': avatarUrl,
      'rating': rating,
      'totalSessions': totalSessions,
      'createdAt': Timestamp.fromDate(createdAt),
      'lastSeen': Timestamp.fromDate(lastSeen),
      'isActive': isActive,
      'isProfileComplete': isProfileComplete,
      'faculty': faculty,
      'bio': bio,
      'activityPreferences': activityPreferences,
      'interactionPreference': interactionPreference,
    };
  }

  UserModel copyWith({
    String? uid,
    String? name,
    String? email,
    String? avatarUrl,
    double? rating,
    int? totalSessions,
    DateTime? createdAt,
    DateTime? lastSeen,
    bool? isActive,
    bool? isProfileComplete,
    String? faculty,
    String? bio,
    List<String>? activityPreferences,
    String? interactionPreference,
  }) {
    return UserModel(
      uid: uid ?? this.uid,
      name: name ?? this.name,
      email: email ?? this.email,
      avatarUrl: avatarUrl ?? this.avatarUrl,
      rating: rating ?? this.rating,
      totalSessions: totalSessions ?? this.totalSessions,
      createdAt: createdAt ?? this.createdAt,
      lastSeen: lastSeen ?? this.lastSeen,
      isActive: isActive ?? this.isActive,
      isProfileComplete: isProfileComplete ?? this.isProfileComplete,
      faculty: faculty ?? this.faculty,
      bio: bio ?? this.bio,
      activityPreferences: activityPreferences ?? this.activityPreferences,
      interactionPreference:
          interactionPreference ?? this.interactionPreference,
    );
  }
}
