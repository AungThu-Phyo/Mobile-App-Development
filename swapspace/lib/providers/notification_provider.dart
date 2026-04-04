import 'dart:async';
import 'base_state_provider.dart';
import '../core/utils/app_logger.dart';
import '../models/notification_model.dart';
import '../services/notification_service.dart';

class NotificationProvider extends BaseStateProvider {
  final NotificationService _service;

  NotificationProvider({required NotificationService service})
      : _service = service;

  List<NotificationModel> _notifications = [];
  StreamSubscription<List<NotificationModel>>? _sub;

  List<NotificationModel> get notifications => _notifications;
  int get unreadCount => _service.calculateUnreadCount(_notifications);

  void listenNotifications(String uid) {
    _sub?.cancel();
    setLoading(true);
    setError(null);

    _sub = _service.streamNotifications(uid).listen((items) {
      _notifications = items;
      setLoading(false);
      notifyListeners();
    }, onError: (e, stackTrace) {
      AppLogger.error('NotificationProvider.listenNotifications stream error', e, stackTrace);
      setError('Unable to load notifications');
      notifyListeners();
    });
  }

  Future<void> loadNotifications(String uid) async {
    _notifications = await runWithLoading<List<NotificationModel>>(
      debugLabel: 'NotificationProvider.loadNotifications',
      errorMessage: 'Unable to load notifications',
      action: () => _service.fetchNotifications(uid),
    );
  }

  Future<void> markAsRead(String notificationId) async {
    await _service.markAsRead(notificationId);
    final idx = _notifications.indexWhere((n) => n.notificationId == notificationId);
    if (idx != -1) {
      _notifications[idx] = _notifications[idx].copyWith(isRead: true);
      notifyListeners();
    }
  }

  @override
  void clearError() {
    setError(null);
  }

  @override
  void dispose() {
    _sub?.cancel();
    super.dispose();
  }
}
