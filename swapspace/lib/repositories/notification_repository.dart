import 'package:cloud_firestore/cloud_firestore.dart';
import '../core/errors/repository_exception.dart';
import '../models/notification_model.dart';

class NotificationRepository {
  final CollectionReference<Map<String, dynamic>> _ref =
      FirebaseFirestore.instance.collection('notifications');

  String createNotificationId() {
    return _ref.doc().id;
  }

  Future<void> create(NotificationModel notification) async {
    try {
      await _ref.doc(notification.notificationId).set(notification.toMap());
    } on FirebaseException catch (e) {
      throw RepositoryException(
        code: e.code,
        message: 'Unable to create notification',
        cause: e,
      );
    } catch (e) {
      throw RepositoryException(
        code: 'unknown',
        message: 'Unable to create notification',
        cause: e,
      );
    }
  }

  Future<void> markRead(String notificationId) async {
    try {
      await _ref.doc(notificationId).update({'isRead': true});
    } on FirebaseException catch (e) {
      throw RepositoryException(
        code: e.code,
        message: 'Unable to mark notification as read',
        cause: e,
      );
    } catch (e) {
      throw RepositoryException(
        code: 'unknown',
        message: 'Unable to mark notification as read',
        cause: e,
      );
    }
  }

  Stream<QuerySnapshot<Map<String, dynamic>>> streamForUser(String uid) {
    return _ref
        .where('recipientUid', isEqualTo: uid)
        .snapshots();
  }

  Future<List<NotificationModel>> getForUser(String uid) async {
    try {
      final snapshot = await _ref
          .where('recipientUid', isEqualTo: uid)
          .get();
      return snapshot.docs
          .map((doc) => NotificationModel.fromMap(doc.data()))
          .toList();
    } on FirebaseException catch (e) {
      throw RepositoryException(
        code: e.code,
        message: 'Unable to load notifications',
        cause: e,
      );
    } catch (e) {
      throw RepositoryException(
        code: 'unknown',
        message: 'Unable to load notifications',
        cause: e,
      );
    }
  }
}
