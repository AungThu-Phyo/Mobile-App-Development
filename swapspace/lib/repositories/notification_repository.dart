import 'package:cloud_firestore/cloud_firestore.dart';
import '../core/errors/repository_exception.dart';
import '../models/notification_model.dart';
import 'paginated_query_result.dart';

class NotificationRepository {
  static const int defaultPageSize = 20;

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
      .orderBy('createdAt', descending: true)
      .limit(defaultPageSize)
        .snapshots();
  }

  Future<List<NotificationModel>> getForUser(String uid) async {
    try {
      final snapshot = await _ref
          .where('recipientUid', isEqualTo: uid)
          .orderBy('createdAt', descending: true)
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

  Future<PaginatedQueryResult<NotificationModel>> getForUserPage({
    required String uid,
    int pageSize = defaultPageSize,
    QueryDocumentSnapshot<Map<String, dynamic>>? startAfterDocument,
  }) async {
    try {
      var query = _ref
          .where('recipientUid', isEqualTo: uid)
          .orderBy('createdAt', descending: true)
          .limit(pageSize + 1);

      if (startAfterDocument != null) {
        query = query.startAfterDocument(startAfterDocument);
      }

      final snapshot = await query.get();
      final docs = snapshot.docs;
      final hasMore = docs.length > pageSize;
      final pageDocs = hasMore ? docs.take(pageSize).toList() : docs;

      return PaginatedQueryResult<NotificationModel>(
        items: pageDocs
            .map((doc) => NotificationModel.fromMap(doc.data()))
            .toList(),
        lastDocument: pageDocs.isNotEmpty ? pageDocs.last : null,
        hasMore: hasMore,
      );
    } on FirebaseException catch (e) {
      throw RepositoryException(
        code: e.code,
        message: 'Unable to load paginated notifications',
        cause: e,
      );
    } catch (e) {
      throw RepositoryException(
        code: 'unknown',
        message: 'Unable to load paginated notifications',
        cause: e,
      );
    }
  }
}
