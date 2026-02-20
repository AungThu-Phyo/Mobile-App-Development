import '../../models/user_model.dart';

const List<UserModel> mockUsers = [
  UserModel(
    id: 'user_01',
    name: 'Marcus Chen',
    email: 'marcus.chen@university.edu',
    avatarUrl: '',
    department: 'Engineering',
    rating: 4.9,
    totalSessions: 23,
    activeSince: '2023',
  ),
  UserModel(
    id: 'user_02',
    name: 'Alex Rivera',
    email: 'alex.rivera@university.edu',
    avatarUrl: '',
    department: 'Science',
    rating: 4.7,
    totalSessions: 15,
    activeSince: '2023',
  ),
  UserModel(
    id: 'user_03',
    name: 'Priya Sharma',
    email: 'priya.sharma@university.edu',
    avatarUrl: '',
    department: 'Arts',
    rating: 4.5,
    totalSessions: 8,
    activeSince: '2024',
  ),
];
