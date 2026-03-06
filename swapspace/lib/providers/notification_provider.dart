import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import '../models/notification_model.dart';
import '../repositories/notification_repository.dart';

class NotificationProvider extends ChangeNotifier {
  final NotificationRepository _repo = NotificationRepository();

  List<NotificationModel> _notifications = [];
  StreamSubscription<QuerySnapshot<Map<String, dynamic>>>? _sub;

  List<NotificationModel> get notifications => _notifications;
  int get unreadCount => _notifications.where((n) => !n.isRead).length;

  void listenNotifications(String uid) {
    _sub?.cancel();
    _sub = _repo.streamForUser(uid).listen((snapshot) {
      _notifications = snapshot.docs
          .map((doc) => NotificationModel.fromMap(doc.data()))
          .toList();
      notifyListeners();
    }, onError: (_) {});
  }

  Future<void> markAsRead(String notificationId) async {
    await _repo.markRead(notificationId);
    final idx = _notifications.indexWhere((n) => n.notificationId == notificationId);
    if (idx != -1) {
      _notifications[idx] = _notifications[idx].copyWith(isRead: true);
      notifyListeners();
    }
  }

  /// Fire-and-forget helper used by other providers to create a notification.
  Future<void> sendNotification({
    required String recipientUid,
    required String senderUid,
    required String senderName,
    required String sessionId,
    required String sessionTitle,
    required String type,
    required String message,
  }) async {
    final id = FirebaseFirestore.instance.collection('notifications').doc().id;
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

  @override
  void dispose() {
    _sub?.cancel();
    super.dispose();
  }
}
