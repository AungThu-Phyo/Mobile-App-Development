import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/user_model.dart';

class UserRepository {
  final CollectionReference<Map<String, dynamic>> _usersRef =
      FirebaseFirestore.instance.collection('users');

  /// Creates a new user document — only if it does not already exist.
  Future<void> createUser(UserModel user) async {
    try {
      final doc = await _usersRef.doc(user.uid).get();
      if (!doc.exists) {
        await _usersRef.doc(user.uid).set(user.toMap());
      }
    } catch (e) {
      throw Exception('Failed to create user: $e');
    }
  }

  /// Fetches a single user by uid. Returns null if not found.
  Future<UserModel?> getUser(String uid) async {
    try {
      final doc = await _usersRef.doc(uid).get();
      if (doc.exists && doc.data() != null) {
        return UserModel.fromMap(doc.data()!);
      }
      return null;
    } catch (e) {
      throw Exception('Failed to get user: $e');
    }
  }

  /// Updates an existing user document (merge).
  Future<void> updateUser(UserModel user) async {
    try {
      await _usersRef.doc(user.uid).update(user.toMap());
    } catch (e) {
      throw Exception('Failed to update user: $e');
    }
  }

  /// Updates only the lastSeen timestamp.
  Future<void> updateLastSeen(String uid) async {
    try {
      await _usersRef.doc(uid).update({
        'lastSeen': Timestamp.now(),
      });
    } catch (e) {
      throw Exception('Failed to update lastSeen: $e');
    }
  }

  /// Real-time stream of a user document.
  Stream<UserModel?> streamUser(String uid) {
    return _usersRef.doc(uid).snapshots().map((doc) {
      if (doc.exists && doc.data() != null) {
        return UserModel.fromMap(doc.data()!);
      }
      return null;
    });
  }

  /// Checks whether a user's profile is marked as complete.
  Future<bool> isProfileComplete(String uid) async {
    try {
      final doc = await _usersRef.doc(uid).get();
      if (doc.exists && doc.data() != null) {
        return doc.data()!['isProfileComplete'] as bool? ?? false;
      }
      return false;
    } catch (e) {
      throw Exception('Failed to check profile completeness: $e');
    }
  }
}
