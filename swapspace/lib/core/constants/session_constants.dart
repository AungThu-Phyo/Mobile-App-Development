class SessionRules {
  static const int maxScheduleDays = 60;
  static const int editCutoffHours = 1;
  static const int defaultMaxParticipants = 2;
}

class SessionConstants {
  static const String defaultActivityType = 'study';
  static const String defaultInteractionPreference = 'social';
  static const String sessionIdPrefix = 'session_';
  static const String filterAll = 'All';

  static const List<String> activityTypes = [
    'study',
    'gym',
    'football',
    'walking',
    'other',
  ];

  static const List<String> interactionPreferences = ['silent', 'social'];
}

class SessionStatus {
  static const String open = 'open';
  static const String matched = 'matched';
  static const String completed = 'completed';
  static const String cancelled = 'cancelled';
}

class JoinRequestStatus {
  static const String pending = 'pending';
  static const String accepted = 'accepted';
  static const String rejected = 'rejected';
  static const String cancelled = 'cancelled';
}

class JoinRequestType {
  static const String join = 'join';
  static const String leave = 'leave';
}

class NotificationType {
  static const String joinRequest = 'join_request';
  static const String requestAccepted = 'request_accepted';
  static const String requestRejected = 'request_rejected';
  static const String sessionUpdated = 'session_updated';
  static const String participantLeft = 'participant_left';
}
