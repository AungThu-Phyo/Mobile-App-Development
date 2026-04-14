import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/notification_model.dart';
import '../repositories/paginated_query_result.dart';
import '../repositories/notification_repository.dart';

class NotificationPageResult {
  final List<NotificationModel> items;
  final QueryDocumentSnapshot<Map<String, dynamic>>? lastDocument;
  final bool hasMore;

  const NotificationPageResult({
    required this.items,
    required this.lastDocument,
    required this.hasMore,
  });
}

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
    final firstPage = await fetchNotificationsPage(uid: uid);
    return firstPage.items;
  }

  Future<NotificationPageResult> fetchNotificationsPage({
    required String uid,
    int pageSize = NotificationRepository.defaultPageSize,
    QueryDocumentSnapshot<Map<String, dynamic>>? startAfterDocument,
  }) async {
    final PaginatedQueryResult<NotificationModel> page =
        await _repo.getForUserPage(
          uid: uid,
          pageSize: pageSize,
          startAfterDocument: startAfterDocument,
        );

    return NotificationPageResult(
      items: page.items,
      lastDocument: page.lastDocument,
      hasMore: page.hasMore,
    );
  }

  /// Calculate unread notification count from a list of notifications
  int calculateUnreadCount(List<NotificationModel> notifications) {
    return notifications.where((n) => !n.isRead).length;
  }
}
