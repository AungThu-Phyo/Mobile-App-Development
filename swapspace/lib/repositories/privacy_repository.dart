import 'package:cloud_firestore/cloud_firestore.dart';
import '../core/errors/repository_exception.dart';

class PrivacyRepository {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  Future<Map<String, dynamic>> exportUserData(String uid) async {
    final userDoc = await _db.collection('users').doc(uid).get();
    final publicProfileDoc = await _db.collection('publicProfiles').doc(uid).get();

    final createdSessions =
        await _db.collection('sessions').where('creatorUid', isEqualTo: uid).get();
    final joinedSessions = await _db
        .collection('sessions')
        .where('participantUids', arrayContains: uid)
        .get();

    final outgoingRequests = await _db
        .collection('joinRequests')
        .where('requesterUid', isEqualTo: uid)
        .get();
    final incomingRequests = await _db
        .collection('joinRequests')
        .where('creatorUid', isEqualTo: uid)
        .get();

    final feedbackGiven =
        await _db.collection('feedback').where('reviewerUid', isEqualTo: uid).get();
    final feedbackReceived =
        await _db.collection('feedback').where('revieweeUid', isEqualTo: uid).get();

    final notifications = await _db
        .collection('notifications')
        .where('recipientUid', isEqualTo: uid)
        .get();

    return {
      'exportedAt': DateTime.now().toIso8601String(),
      'user': _toSafeMap(userDoc.data()),
      'publicProfile': _toSafeMap(publicProfileDoc.data()),
      'createdSessions': createdSessions.docs.map((d) => _toSafeMap(d.data())).toList(),
      'joinedSessions': joinedSessions.docs.map((d) => _toSafeMap(d.data())).toList(),
      'outgoingJoinRequests':
          outgoingRequests.docs.map((d) => _toSafeMap(d.data())).toList(),
      'incomingJoinRequests':
          incomingRequests.docs.map((d) => _toSafeMap(d.data())).toList(),
      'feedbackGiven': feedbackGiven.docs.map((d) => _toSafeMap(d.data())).toList(),
      'feedbackReceived':
          feedbackReceived.docs.map((d) => _toSafeMap(d.data())).toList(),
      'notifications': notifications.docs.map((d) => _toSafeMap(d.data())).toList(),
    };
  }

  Future<void> deleteUserData(String uid) async {
    try {
      final initialPlan = await _collectDeletionPlan(uid);
      if (initialPlan.refs.isEmpty) {
        return;
      }

      var plan = initialPlan;

      for (var attempt = 0; attempt < 3; attempt++) {
        if (plan.refs.isEmpty) break;
        await _deleteInBatches(plan.refs);
        plan = await _collectDeletionPlan(uid);
      }

      if (plan.refs.isNotEmpty) {
        throw const RepositoryException(
          code: 'partial-delete',
          message: 'Unable to fully delete account data in one pass. Please retry deletion.',
        );
      }
    } on FirebaseException catch (e) {
      throw RepositoryException(
        code: e.code,
        message: 'Unable to delete account data',
        cause: e,
      );
    } on RepositoryException {
      rethrow;
    } catch (e) {
      throw RepositoryException(
        code: 'unknown',
        message: 'Unable to delete account data',
        cause: e,
      );
    }
  }

  Future<_DeletionPlan> _collectDeletionPlan(
    String uid,
  ) async {
    final results = await Future.wait([
      _db.collection('sessions').where('creatorUid', isEqualTo: uid).get(),
      _db.collection('joinRequests').where('requesterUid', isEqualTo: uid).get(),
      _db.collection('joinRequests').where('creatorUid', isEqualTo: uid).get(),
      _db.collection('feedback').where('reviewerUid', isEqualTo: uid).get(),
      _db.collection('feedback').where('revieweeUid', isEqualTo: uid).get(),
      _db.collection('notifications').where('recipientUid', isEqualTo: uid).get(),
      _db.collection('notifications').where('senderUid', isEqualTo: uid).get(),
      _db.collection('users').doc(uid).get(),
      _db.collection('publicProfiles').doc(uid).get(),
    ]);

    final refsByPath = <String, DocumentReference<Map<String, dynamic>>>{};
    void addRef(DocumentReference<Map<String, dynamic>> ref) {
      refsByPath[ref.path] = ref;
    }

    final sessionDocs = results[0] as QuerySnapshot<Map<String, dynamic>>;
    final requesterDocs = results[1] as QuerySnapshot<Map<String, dynamic>>;
    final creatorRequestDocs = results[2] as QuerySnapshot<Map<String, dynamic>>;
    final feedbackGivenDocs = results[3] as QuerySnapshot<Map<String, dynamic>>;
    final feedbackReceivedDocs = results[4] as QuerySnapshot<Map<String, dynamic>>;
    final recipientNotificationDocs = results[5] as QuerySnapshot<Map<String, dynamic>>;
    final senderNotificationDocs = results[6] as QuerySnapshot<Map<String, dynamic>>;
    final userDoc = results[7] as DocumentSnapshot<Map<String, dynamic>>;
    final publicProfileDoc = results[8] as DocumentSnapshot<Map<String, dynamic>>;

    for (final doc in sessionDocs.docs) {
      addRef(doc.reference);
    }
    for (final doc in requesterDocs.docs) {
      addRef(doc.reference);
    }
    for (final doc in creatorRequestDocs.docs) {
      addRef(doc.reference);
    }
    for (final doc in feedbackGivenDocs.docs) {
      addRef(doc.reference);
    }
    for (final doc in feedbackReceivedDocs.docs) {
      addRef(doc.reference);
    }
    for (final doc in recipientNotificationDocs.docs) {
      addRef(doc.reference);
    }
    for (final doc in senderNotificationDocs.docs) {
      addRef(doc.reference);
    }

    if (userDoc.exists) {
      addRef(userDoc.reference);
    }
    if (publicProfileDoc.exists) {
      addRef(publicProfileDoc.reference);
    }

    final counts = <String, int>{
      'users': userDoc.exists ? 1 : 0,
      'publicProfiles': publicProfileDoc.exists ? 1 : 0,
      'sessionsByCreator': sessionDocs.docs.length,
      'joinRequestsByRequester': requesterDocs.docs.length,
      'joinRequestsByCreator': creatorRequestDocs.docs.length,
      'feedbackByReviewer': feedbackGivenDocs.docs.length,
      'feedbackByReviewee': feedbackReceivedDocs.docs.length,
      'notificationsByRecipient': recipientNotificationDocs.docs.length,
      'notificationsBySender': senderNotificationDocs.docs.length,
    };

    return _DeletionPlan(refs: refsByPath.values.toList(), counts: counts);
  }

  Future<void> _deleteInBatches(
    List<DocumentReference<Map<String, dynamic>>> docs,
  ) async {
    const chunkSize = 350;
    for (var i = 0; i < docs.length; i += chunkSize) {
      final chunk = docs.skip(i).take(chunkSize);
      final batch = _db.batch();
      for (final doc in chunk) {
        batch.delete(doc);
      }
      await batch.commit();
    }
  }

  Map<String, dynamic>? _toSafeMap(Map<String, dynamic>? data) {
    if (data == null) return null;
    return data.map((key, value) => MapEntry(key, _normalize(value)));
  }

  dynamic _normalize(dynamic value) {
    if (value is Timestamp) return value.toDate().toIso8601String();
    if (value is DateTime) return value.toIso8601String();
    if (value is Map<String, dynamic>) {
      return value.map((k, v) => MapEntry(k, _normalize(v)));
    }
    if (value is List) return value.map(_normalize).toList();
    return value;
  }

}

class _DeletionPlan {
  final List<DocumentReference<Map<String, dynamic>>> refs;
  final Map<String, int> counts;

  const _DeletionPlan({required this.refs, required this.counts});
}
