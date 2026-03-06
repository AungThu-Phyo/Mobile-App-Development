import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/notification_model.dart';

class NotificationRepository {
  final CollectionReference<Map<String, dynamic>> _ref =
      FirebaseFirestore.instance.collection('notifications');

  Future<void> create(NotificationModel notification) async {
    await _ref.doc(notification.notificationId).set(notification.toMap());
  }

  Future<void> markRead(String notificationId) async {
    await _ref.doc(notificationId).update({'isRead': true});
  }

  Stream<QuerySnapshot<Map<String, dynamic>>> streamForUser(String uid) {
    return _ref
        .where('recipientUid', isEqualTo: uid)
        .snapshots();
  }

  Future<List<NotificationModel>> getForUser(String uid) async {
    final snapshot = await _ref
        .where('recipientUid', isEqualTo: uid)
        .get();
    return snapshot.docs
        .map((doc) => NotificationModel.fromMap(doc.data()))
        .toList();
  }
}
