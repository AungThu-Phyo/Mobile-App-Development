import '../../models/user_model.dart';
import '../../models/activity_session.dart';

final UserModel mockCurrentUser = UserModel(
  uid: 'user_02',
  name: 'Alex Rivera',
  email: 'alex.rivera@lamduan.mfu.ac.th',
  avatarUrl: '',
  faculty: 'Science',
  rating: 4.9,
  totalSessions: 42,
  createdAt: DateTime(2023, 1, 1),
  lastSeen: DateTime.now(),
  isActive: true,
  isProfileComplete: true,
  bio: '',
  activityPreferences: ['Study', 'Sports'],
  interactionPreference: 'social',
);

final List<ActivitySession> mockCreatedSessions = [
  ActivitySession(
    id: 'session_03',
    title: 'Code Review & Coffee',
    activityType: 'Study',
    location: 'Student Union Café',
    startTime: DateTime(DateTime.now().year, DateTime.now().month, DateTime.now().day, 11, 0),
    durationMinutes: 90,
    interactionLevel: 'Colab',
    minPartnerRating: 4.2,
    createdBy: 'user_02',
    status: 'open',
    notes: 'Reviewing Flutter projects together',
  ),
  ActivitySession(
    id: 'session_01',
    title: 'Library Study Session',
    activityType: 'Study',
    location: 'Central Library Floor 3',
    startTime: DateTime(DateTime.now().year, DateTime.now().month, DateTime.now().day, 14, 0),
    durationMinutes: 120,
    interactionLevel: 'Silent',
    minPartnerRating: 4.5,
    createdBy: 'user_02',
    status: 'closed',
    notes: 'Quiet study session, bring your own materials',
  ),
];

final List<ActivitySession> mockJoinedSessions = [
  ActivitySession(
    id: 'session_05',
    title: 'Pick-up Basketball',
    activityType: 'Sports',
    location: 'University Gym Court 2',
    startTime: DateTime(DateTime.now().year, DateTime.now().month, DateTime.now().day, 17, 30),
    durationMinutes: 120,
    interactionLevel: 'Social',
    minPartnerRating: 4.3,
    createdBy: 'user_01',
    status: 'open',
    notes: '3v3 half court bring water',
  ),
  ActivitySession(
    id: 'session_02',
    title: 'Gym Workout Buddy',
    activityType: 'Fitness',
    location: 'Varsity Wellness Center',
    startTime: DateTime(DateTime.now().year, DateTime.now().month, DateTime.now().day, 16, 30),
    durationMinutes: 60,
    interactionLevel: 'Social',
    minPartnerRating: 4.0,
    createdBy: 'user_03',
    status: 'closed',
    notes: 'Cardio and light weights session',
  ),
];
