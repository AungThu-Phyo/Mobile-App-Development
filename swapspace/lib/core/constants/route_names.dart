abstract class RouteNames {
  static const String login = '/login';
  static const String home = '/home';
  static const String sessionDetail = '/session-detail';
  static const String createSession = '/create-session';
  static const String requests = '/requests';
  static const String profile = '/profile';
  static const String userProfile = '/user-profile';
  static const String editSession = '/edit-session';
  static const String feedback = '/feedback';
  static const String privacyPolicy = '/privacy-policy';

  static String userProfileById(String userId) => '$userProfile/$userId';
}
