import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/join_request_model.dart';

class JoinRequestRepository {
  final CollectionReference<Map<String, dynamic>> _requestsRef =
      FirebaseFirestore.instance.collection('joinRequests');

  /// Creates a new join request document.
  Future<void> create(JoinRequestModel request) async {
    try {
      await _requestsRef.doc(request.requestId).set(request.toMap());
    } catch (e) {
      throw Exception('Failed to create join request: $e');
    }
  }

  /// Fetches a join request by ID. Returns null if not found.
  Future<JoinRequestModel?> getById(String requestId) async {
    try {
      final doc = await _requestsRef.doc(requestId).get();
      if (doc.exists && doc.data() != null) {
        return JoinRequestModel.fromMap(doc.data()!);
      }
      return null;
    } catch (e) {
      throw Exception('Failed to get join request: $e');
    }
  }

  /// Updates an existing join request document.
  Future<void> update(JoinRequestModel request) async {
    try {
      await _requestsRef.doc(request.requestId).update(request.toMap());
    } catch (e) {
      throw Exception('Failed to update join request: $e');
    }
  }

  /// Deletes a join request document.
  Future<void> delete(String requestId) async {
    try {
      await _requestsRef.doc(requestId).delete();
    } catch (e) {
      throw Exception('Failed to delete join request: $e');
    }
  }

  /// Real-time stream of a single join request.
  Stream<JoinRequestModel?> stream(String requestId) {
    return _requestsRef.doc(requestId).snapshots().map((doc) {
      if (doc.exists && doc.data() != null) {
        return JoinRequestModel.fromMap(doc.data()!);
      }
      return null;
    });
  }

  /// Returns all pending requests for a given session.
  Future<List<JoinRequestModel>> getRequestsForSession(
      String sessionId) async {
    try {
      final snapshot = await _requestsRef
          .where('sessionId', isEqualTo: sessionId)
          .get();
      final requests = snapshot.docs
          .map((doc) => JoinRequestModel.fromMap(doc.data()))
          .where((r) => r.status == 'pending')
          .toList()
        ..sort((a, b) => a.createdAt.compareTo(b.createdAt));
      return requests;
    } catch (e) {
      throw Exception('Failed to get requests for session: $e');
    }
  }

  /// Returns all requests sent by a specific user.
  Future<List<JoinRequestModel>> getRequestsByUser(String uid) async {
    try {
      final snapshot = await _requestsRef
          .where('requesterUid', isEqualTo: uid)
          .get();
      final requests = snapshot.docs
          .map((doc) => JoinRequestModel.fromMap(doc.data()))
          .toList()
        ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
      return requests;
    } catch (e) {
      throw Exception('Failed to get requests by user: $e');
    }
  }

  /// Returns all pending requests received by a session creator.
  Future<List<JoinRequestModel>> getRequestsForCreator(String uid) async {
    try {
      final snapshot = await _requestsRef
          .where('creatorUid', isEqualTo: uid)
          .get();
      final requests = snapshot.docs
          .map((doc) => JoinRequestModel.fromMap(doc.data()))
          .where((r) => r.status == 'pending')
          .toList()
        ..sort((a, b) => a.createdAt.compareTo(b.createdAt));
      return requests;
    } catch (e) {
      throw Exception('Failed to get requests for creator: $e');
    }
  }
}
