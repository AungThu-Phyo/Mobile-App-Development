import '../models/notification_model.dart';
import '../repositories/notification_repository.dart';

class NotificationService {
  final NotificationRepository _repo;

  NotificationService({required NotificationRepository repository})
      : _repo = repository;

  Future<void> sendNotification({
    required String recipientUid,
    required String senderUid,
    required String senderName,
    required String sessionId,
    required String sessionTitle,
    required String type,
    required String message,
  }) async {
    final id = _repo.createNotificationId();
    final notification = NotificationModel(
      notificationId: id,
      recipientUid: recipientUid,
      senderUid: senderUid,
      senderName: senderName,
      sessionId: sessionId,
      sessionTitle: sessionTitle,
      type: type,
      message: message,
      createdAt: DateTime.now(),
    );
    await _repo.create(notification);
  }

  Future<void> markAsRead(String notificationId) {
    return _repo.markRead(notificationId);
  }

  Stream<List<NotificationModel>> streamNotifications(String uid) {
    return _repo.streamForUser(uid).map((snapshot) {
      final list = snapshot.docs
          .map((doc) => NotificationModel.fromMap(doc.data()))
          .toList();
      list.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      return list;
    });
  }

  Future<List<NotificationModel>> fetchNotifications(String uid) async {
    final list = await _repo.getForUser(uid);
    list.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    return list;
  }

  /// Calculate unread notification count from a list of notifications
  int calculateUnreadCount(List<NotificationModel> notifications) {
    return notifications.where((n) => !n.isRead).length;
  }
}
