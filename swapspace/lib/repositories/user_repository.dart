import 'package:cloud_firestore/cloud_firestore.dart';
import '../core/errors/repository_exception.dart';
import '../models/user_model.dart';

class UserRepository {
  final CollectionReference<Map<String, dynamic>> _usersRef =
      FirebaseFirestore.instance.collection('users');

  final CollectionReference<Map<String, dynamic>> _publicProfilesRef =
      FirebaseFirestore.instance.collection('publicProfiles');

  /// Creates a new user document — only if it does not already exist.
  Future<void> createUser(UserModel user) async {
    try {
      final doc = await _usersRef.doc(user.uid).get();
      if (!doc.exists) {
        await _usersRef.doc(user.uid).set(user.toMap());
      }
    } on FirebaseException catch (e) {
      throw RepositoryException(
        code: e.code,
        message: 'Unable to create user profile',
        cause: e,
      );
    } catch (e) {
      throw RepositoryException(
        code: 'unknown',
        message: 'Unable to create user profile',
        cause: e,
      );
    }
  }

  /// Creates or updates the public profile document for a user.
  Future<void> upsertPublicProfile(UserModel user) async {
    try {
      await _publicProfilesRef.doc(user.uid).set(user.toPublicMap());
    } on FirebaseException catch (e) {
      throw RepositoryException(
        code: e.code,
        message: 'Unable to update public profile',
        cause: e,
      );
    } catch (e) {
      throw RepositoryException(
        code: 'unknown',
        message: 'Unable to update public profile',
        cause: e,
      );
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
    } on FirebaseException catch (e) {
      throw RepositoryException(
        code: e.code,
        message: 'Unable to load user profile',
        cause: e,
      );
    } catch (e) {
      throw RepositoryException(
        code: 'unknown',
        message: 'Unable to load user profile',
        cause: e,
      );
    }
  }

  /// Fetches a public profile by uid. Returns null if not found.
  Future<UserModel?> getPublicUser(String uid) async {
    try {
      final doc = await _publicProfilesRef.doc(uid).get();
      if (doc.exists && doc.data() != null) {
        return UserModel.fromMap(doc.data()!);
      }
      return null;
    } on FirebaseException catch (e) {
      throw RepositoryException(
        code: e.code,
        message: 'Unable to load public profile',
        cause: e,
      );
    } catch (e) {
      throw RepositoryException(
        code: 'unknown',
        message: 'Unable to load public profile',
        cause: e,
      );
    }
  }

  /// Updates an existing user document (merge).
  Future<void> updateUser(UserModel user) async {
    try {
      await _usersRef.doc(user.uid).update(user.toMap());
    } on FirebaseException catch (e) {
      throw RepositoryException(
        code: e.code,
        message: 'Unable to update user profile',
        cause: e,
      );
    } catch (e) {
      throw RepositoryException(
        code: 'unknown',
        message: 'Unable to update user profile',
        cause: e,
      );
    }
  }

  /// Updates only the lastSeen timestamp.
  Future<void> updateLastSeen(String uid) async {
    try {
      await _usersRef.doc(uid).update({
        'lastSeen': Timestamp.now(),
      });
    } on FirebaseException catch (e) {
      throw RepositoryException(
        code: e.code,
        message: 'Unable to update last seen',
        cause: e,
      );
    } catch (e) {
      throw RepositoryException(
        code: 'unknown',
        message: 'Unable to update last seen',
        cause: e,
      );
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

  Stream<UserModel?> streamPublicUser(String uid) {
    return _publicProfilesRef.doc(uid).snapshots().map((doc) {
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
    } on FirebaseException catch (e) {
      throw RepositoryException(
        code: e.code,
        message: 'Unable to check profile completeness',
        cause: e,
      );
    } catch (e) {
      throw RepositoryException(
        code: 'unknown',
        message: 'Unable to check profile completeness',
        cause: e,
      );
    }
  }
}
