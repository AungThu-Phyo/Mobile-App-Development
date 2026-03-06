import '../../models/user_model.dart';

final List<UserModel> mockUsers = [
  UserModel(
    uid: 'user_01',
    name: 'Marcus Chen',
    email: 'marcus.chen@lamduan.mfu.ac.th',
    avatarUrl: '',
    faculty: 'Engineering',
    rating: 4.9,
    totalSessions: 23,
    createdAt: DateTime(2023, 1, 1),
    lastSeen: DateTime.now(),
  ),
  UserModel(
    uid: 'user_02',
    name: 'Alex Rivera',
    email: 'alex.rivera@lamduan.mfu.ac.th',
    avatarUrl: '',
    faculty: 'Science',
    rating: 4.7,
    totalSessions: 15,
    createdAt: DateTime(2023, 3, 1),
    lastSeen: DateTime.now(),
  ),
  UserModel(
    uid: 'user_03',
    name: 'Priya Sharma',
    email: 'priya.sharma@lamduan.mfu.ac.th',
    avatarUrl: '',
    faculty: 'Arts',
    rating: 4.5,
    totalSessions: 8,
    createdAt: DateTime(2024, 1, 1),
    lastSeen: DateTime.now(),
  ),
];
