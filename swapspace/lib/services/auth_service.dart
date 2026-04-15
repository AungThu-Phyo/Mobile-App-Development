import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:google_sign_in/google_sign_in.dart';
import '../core/errors/repository_exception.dart';
import '../core/utils/app_logger.dart';
import '../models/user_model.dart';
import '../repositories/feedback_repository.dart';
import '../repositories/user_repository.dart';

class AuthService {
	static const Duration _lastSeenWriteInterval = Duration(minutes: 15);

	final UserRepository _userRepo;
	final FeedbackRepository _feedbackRepo;
	final FirebaseAuth _firebaseAuth;

	AuthService({
		required UserRepository userRepository,
		required FeedbackRepository feedbackRepository,
		FirebaseAuth? firebaseAuth,
	})  : _userRepo = userRepository,
			_feedbackRepo = feedbackRepository,
			_firebaseAuth = firebaseAuth ?? FirebaseAuth.instance;

	Stream<String?> authStateStream() {
		return _firebaseAuth.authStateChanges().map((user) => user?.uid);
	}

	Future<bool> signInWithGoogle() async {
		try {
			if (kIsWeb) {
				final googleProvider = GoogleAuthProvider();
				googleProvider.addScope('email');
				googleProvider.addScope('profile');
				googleProvider.setCustomParameters({
					'prompt': 'select_account',
				});

				final userCredential =
						await _firebaseAuth.signInWithPopup(googleProvider);
				return userCredential.user != null;
			}

			final googleSignIn = GoogleSignIn.instance;
			await googleSignIn.initialize();
			final account = await googleSignIn.authenticate(
				scopeHint: const ['email', 'profile'],
			);
			if (account.email.isEmpty) {
				throw AuthCanceledException('Sign in cancelled');
			}
			final auth = account.authentication;
			final credential = GoogleAuthProvider.credential(
				idToken: auth.idToken,
			);
			final userCredential =
					await _firebaseAuth.signInWithCredential(credential);
			return userCredential.user != null;
		} on FirebaseAuthException catch (e, stackTrace) {
			AppLogger.error('AuthService.signInWithGoogle error', e, stackTrace);
			if (e.code == 'popup-closed-by-user' ||
					e.code == 'cancelled-popup-request') {
				throw AuthCanceledException('Sign in cancelled');
			}
			throw AuthException(_friendlyAuthMessage(e, fallback: 'Unable to sign in. Please try again.'));
		} on GoogleSignInException catch (e, stackTrace) {
			AppLogger.error('AuthService.signInWithGoogle error', e, stackTrace);
			if (e.code == GoogleSignInExceptionCode.canceled) {
				throw AuthCanceledException('Sign in cancelled');
			}
			throw AuthException('Unable to sign in. Please try again.');
		}
	}

	Future<void> signOut() async {
		await _firebaseAuth.signOut();
		if (!kIsWeb) {
			unawaited(
				GoogleSignIn.instance.signOut().timeout(const Duration(seconds: 5)),
			);
		}
	}

	Future<void> deleteCurrentAuthAccount() async {
		final user = _firebaseAuth.currentUser;
		if (user == null) return;
		try {
			await user.delete();
		} on FirebaseAuthException catch (e, stackTrace) {
			AppLogger.error('AuthService.deleteCurrentAuthAccount error', e, stackTrace);
			if (e.code == 'requires-recent-login') {
				throw AuthException(
					'Re-authentication required before deleting account. Please sign in again and retry.',
				);
			}
			throw AuthException('Unable to delete authentication account right now. Please try again.');
		}
	}

	Future<void> reauthenticateWithGoogle() async {
		final user = _firebaseAuth.currentUser;
		if (user == null) {
			throw AuthException('No authenticated user');
		}
		if (kIsWeb) {
			final googleProvider = GoogleAuthProvider();
			googleProvider.addScope('email');
			googleProvider.addScope('profile');
			if (user.email != null && user.email!.isNotEmpty) {
				googleProvider.setCustomParameters({
					'login_hint': user.email!,
				});
			}

			try {
				await user.reauthenticateWithProvider(googleProvider);
				return;
			} on FirebaseAuthException catch (e, stackTrace) {
				AppLogger.error('AuthService.reauthenticateWithGoogle error', e, stackTrace);
				if (e.code == 'popup-closed-by-user' ||
						e.code == 'cancelled-popup-request') {
					throw AuthCanceledException('Re-authentication cancelled');
				}
				if (e.code == 'user-mismatch') {
					throw AuthException('Please choose the same Google account you are currently signed in with.');
				}
				if (e.code == 'popup-blocked') {
					throw AuthException('Popup was blocked by the browser. Please allow popups and try again.');
				}

				// Fallback for web popup edge-cases: refresh sign-in using popup.
				try {
					final credential = await _firebaseAuth.signInWithPopup(googleProvider);
					if (credential.user == null || credential.user!.uid != user.uid) {
						throw AuthException('Please choose the same Google account you are currently signed in with.');
					}
					return;
				} on FirebaseAuthException catch (fallbackError, fallbackStackTrace) {
					AppLogger.error('AuthService.reauthenticateWithGoogle fallback error', fallbackError, fallbackStackTrace);
					if (fallbackError.code == 'popup-closed-by-user' ||
							fallbackError.code == 'cancelled-popup-request') {
						throw AuthCanceledException('Re-authentication cancelled');
					}
					if (fallbackError.code == 'popup-blocked') {
						throw AuthException('Popup was blocked by the browser. Please allow popups and try again.');
					}
					if (fallbackError.code == 'user-mismatch') {
						throw AuthException('Please choose the same Google account you are currently signed in with.');
					}
					throw AuthException(_friendlyAuthMessage(
						fallbackError,
						fallback: _friendlyAuthMessage(e, fallback: 'Unable to re-authenticate. Please try again.'),
					));
				}
			}
		}

		try {
			final googleSignIn = GoogleSignIn.instance;
			await googleSignIn.initialize();
			final account = await googleSignIn.authenticate(
				scopeHint: const ['email', 'profile'],
			);
			if (account.email.isEmpty) {
				throw AuthCanceledException('Re-authentication cancelled');
			}
			if (user.email != null && user.email!.isNotEmpty &&
					account.email.toLowerCase() != user.email!.toLowerCase()) {
				throw AuthException('Please choose the same Google account you are currently signed in with.');
			}
			final auth = account.authentication;
			final credential = GoogleAuthProvider.credential(
				idToken: auth.idToken,
			);
			await user.reauthenticateWithCredential(credential);
		} on FirebaseAuthException catch (e, stackTrace) {
			AppLogger.error('AuthService.reauthenticateWithGoogle error', e, stackTrace);
			throw AuthException(_friendlyAuthMessage(
				e,
				fallback: 'Unable to re-authenticate. Please try again.',
			));
		} on GoogleSignInException catch (e, stackTrace) {
			AppLogger.error('AuthService.reauthenticateWithGoogle error', e, stackTrace);
			if (e.code == GoogleSignInExceptionCode.canceled) {
				throw AuthCanceledException('Re-authentication cancelled');
			}
			throw AuthException('Unable to re-authenticate. Please try again.');
		}
	}

	String _friendlyAuthMessage(FirebaseAuthException e, {required String fallback}) {
		switch (e.code) {
			case 'network-request-failed':
				return 'Network error. Please check your connection and try again.';
			case 'too-many-requests':
				return 'Too many attempts. Please wait a moment and try again.';
			case 'user-disabled':
				return 'This account is disabled. Please contact support.';
			case 'operation-not-allowed':
				return 'This sign-in method is not available right now.';
			case 'invalid-credential':
				return 'Authentication failed. Please sign in again.';
			default:
				return fallback;
		}
	}

	Future<UserModel> bootstrapUser(String uid) async {
		try {
			final existing = await _userRepo.getUser(uid);
			final feedbackSummary = await _feedbackRepo.getFeedbackForUser(uid);
			final averageRating = feedbackSummary.isEmpty
				? 0.0
				: feedbackSummary.fold<int>(0, (sum, fb) => sum + fb.rating) /
					feedbackSummary.length;
			final totalSessions = feedbackSummary.length;
			final currentUser = _firebaseAuth.currentUser;
			if (existing == null) {
				final now = DateTime.now();
				final newUser = UserModel(
					uid: uid,
					name: currentUser?.displayName ?? '',
					email: currentUser?.email ?? '',
					avatarUrl: currentUser?.photoURL ?? '',
					rating: averageRating,
					totalSessions: totalSessions,
					createdAt: now,
					lastSeen: now,
				);
				await _userRepo.createUser(newUser);
				await _userRepo.upsertPublicProfile(newUser);
				return newUser;
			}

			final now = DateTime.now();
			final shouldUpdateLastSeen =
				now.difference(existing.lastSeen) >= _lastSeenWriteInterval;

			final displayName = (currentUser?.displayName ?? '').trim();
			final resolvedName = displayName.isNotEmpty ? displayName : existing.name;
			final resolvedAvatarUrl =
					(currentUser?.photoURL ?? '').trim().isNotEmpty
						? currentUser!.photoURL!.trim()
						: existing.avatarUrl;

			final updated = existing.copyWith(
				name: resolvedName,
				avatarUrl: resolvedAvatarUrl,
				rating: averageRating,
				totalSessions: totalSessions,
				lastSeen: shouldUpdateLastSeen ? now : existing.lastSeen,
			);

			if (_shouldWriteUserProfile(existing, updated)) {
				await _userRepo.updateUser(updated);
			}

			if (_shouldWritePublicProfile(existing, updated)) {
				await _userRepo.upsertPublicProfile(updated);
			}

			return updated;
		} catch (e) {
			if (_isOfflineFirestoreError(e) || _isPermissionDeniedFirestoreError(e)) {
				return _fallbackUserFromAuth(uid);
			}
			rethrow;
		}
	}

	bool _isOfflineFirestoreError(Object error) {
		if (error is RepositoryException) {
			return error.code == 'unavailable';
		}
		final message = error.toString().toLowerCase();
		return message.contains('[cloud_firestore/unavailable]') ||
				message.contains('client is offline') ||
				message.contains('failed to get document because the client is offline');
	}

	bool _isPermissionDeniedFirestoreError(Object error) {
		if (error is RepositoryException) {
			return error.code == 'permission-denied';
		}
		final message = error.toString().toLowerCase();
		return message.contains('[cloud_firestore/permission-denied]') ||
				message.contains('missing or insufficient permissions') ||
				message.contains('permission-denied');
	}

	UserModel _fallbackUserFromAuth(String uid) {
		final currentUser = _firebaseAuth.currentUser;
		final now = DateTime.now();
		return UserModel(
			uid: uid,
			name: currentUser?.displayName ?? '',
			email: currentUser?.email ?? '',
			avatarUrl: currentUser?.photoURL ?? '',
			rating: 0.0,
			totalSessions: 0,
			createdAt: now,
			lastSeen: now,
		);
	}

	Future<UserModel?> getUserById(String uid) {
		return _userRepo.getPublicUser(uid);
	}

	Future<Map<String, UserModel>> getUsersByIds(List<String> uids) {
		return _userRepo.getPublicUsersByIds(uids);
	}

	bool _shouldWriteUserProfile(UserModel current, UserModel next) {
		return current.name != next.name ||
				current.avatarUrl != next.avatarUrl ||
				current.rating != next.rating ||
				current.totalSessions != next.totalSessions ||
				current.lastSeen != next.lastSeen;
	}

	bool _shouldWritePublicProfile(UserModel current, UserModel next) {
		return current.name != next.name ||
				current.avatarUrl != next.avatarUrl ||
				current.rating != next.rating ||
				current.totalSessions != next.totalSessions ||
				current.faculty != next.faculty ||
				current.bio != next.bio ||
				current.interactionPreference != next.interactionPreference ||
				!_sameStringList(
					current.activityPreferences,
					next.activityPreferences,
				);
	}

	bool _sameStringList(List<String> a, List<String> b) {
		if (a.length != b.length) {
			return false;
		}
		for (var i = 0; i < a.length; i++) {
			if (a[i] != b[i]) {
				return false;
			}
		}
		return true;
	}
}

class AuthException implements Exception {
	final String message;
	AuthException(this.message);
	@override
	String toString() => message;
}

class AuthCanceledException implements Exception {
	final String message;
	AuthCanceledException(this.message);
	@override
	String toString() => message;
}
