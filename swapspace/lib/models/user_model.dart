class UserModel {
  final String id;
  final String name;
  final String email;
  final String avatarUrl;
  final String department;
  final double rating;
  final int totalSessions;
  final String activeSince;

  const UserModel({
    required this.id,
    required this.name,
    required this.email,
    required this.avatarUrl,
    required this.department,
    required this.rating,
    required this.totalSessions,
    required this.activeSince,
  });

  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      id: json['id'] as String,
      name: json['name'] as String,
      email: json['email'] as String,
      avatarUrl: json['avatarUrl'] as String,
      department: json['department'] as String,
      rating: (json['rating'] as num).toDouble(),
      totalSessions: json['totalSessions'] as int,
      activeSince: json['activeSince'] as String,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'email': email,
      'avatarUrl': avatarUrl,
      'department': department,
      'rating': rating,
      'totalSessions': totalSessions,
      'activeSince': activeSince,
    };
  }

  UserModel copyWith({
    String? id,
    String? name,
    String? email,
    String? avatarUrl,
    String? department,
    double? rating,
    int? totalSessions,
    String? activeSince,
  }) {
    return UserModel(
      id: id ?? this.id,
      name: name ?? this.name,
      email: email ?? this.email,
      avatarUrl: avatarUrl ?? this.avatarUrl,
      department: department ?? this.department,
      rating: rating ?? this.rating,
      totalSessions: totalSessions ?? this.totalSessions,
      activeSince: activeSince ?? this.activeSince,
    );
  }
}
