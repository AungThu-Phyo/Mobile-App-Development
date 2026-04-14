import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'base_state_provider.dart';
import '../core/utils/app_logger.dart';
import '../models/notification_model.dart';
import '../services/notification_service.dart';

class NotificationProvider extends BaseStateProvider {
  final NotificationService _service;

  NotificationProvider({required NotificationService service})
      : _service = service;

  List<NotificationModel> _notifications = [];
  List<NotificationModel> _liveNotifications = [];
  StreamSubscription<List<NotificationModel>>? _sub;
  QueryDocumentSnapshot<Map<String, dynamic>>? _cursor;
  bool _hasMoreNotifications = true;
  bool _isLoadingMoreNotifications = false;
  bool _hasLiveNotificationData = false;

  List<NotificationModel> get notifications => _notifications;
  bool get hasMoreNotifications => _hasMoreNotifications;
  bool get isLoadingMoreNotifications => _isLoadingMoreNotifications;
  int get unreadCount => _service.calculateUnreadCount(
        _hasLiveNotificationData ? _liveNotifications : _notifications,
      );

  void listenNotifications(String uid) {
    _sub?.cancel();
    setLoading(true);
    setError(null);

    _sub = _service.streamNotifications(uid).listen((items) {
      _liveNotifications = items;
      _hasLiveNotificationData = true;

      if (_notifications.isEmpty) {
        _notifications = items;
      }

      if (isLoading) {
        setLoading(false);
      } else {
        notifyListeners();
      }
    }, onError: (e, stackTrace) {
      AppLogger.error('NotificationProvider.listenNotifications stream error', e, stackTrace);
      setError('Unable to load notifications');
    });
  }

  Future<void> loadNotifications(String uid) async {
    final firstPage = await runWithLoading<NotificationPageResult>(
      debugLabel: 'NotificationProvider.loadNotifications',
      errorMessage: 'Unable to load notifications',
      action: () => _service.fetchNotificationsPage(uid: uid),
    );

    _notifications = firstPage.items;
    _cursor = firstPage.lastDocument;
    _hasMoreNotifications = firstPage.hasMore;
  }

  Future<void> loadMoreNotifications(String uid) async {
    if (_isLoadingMoreNotifications || !_hasMoreNotifications) {
      return;
    }

    _isLoadingMoreNotifications = true;
    notifyListeners();

    try {
      final nextPage = await _service.fetchNotificationsPage(
        uid: uid,
        startAfterDocument: _cursor,
      );

      _notifications = [..._notifications, ...nextPage.items];
      _cursor = nextPage.lastDocument;
      _hasMoreNotifications = nextPage.hasMore;
      setError(null);
    } catch (e, stackTrace) {
      AppLogger.error('NotificationProvider.loadMoreNotifications error', e, stackTrace);
      setError('Unable to load more notifications');
    } finally {
      _isLoadingMoreNotifications = false;
      notifyListeners();
    }
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
