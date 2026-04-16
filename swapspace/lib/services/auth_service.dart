import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:google_sign_in/google_sign_in.dart';
import '../core/errors/repository_exception.dart';
import '../core/constants/session_constants.dart';
import '../core/utils/app_logger.dart';
import '../models/feedback_model.dart';
import '../models/user_model.dart';
import '../repositories/feedback_repository.dart';
import '../repositories/session_repository.dart';
import '../repositories/user_repository.dart';

class AuthService {
	static const Duration _lastSeenWriteInterval = Duration(minutes: 15);
	static const String _allowedSchoolDomain = 'lamduan.mfu.ac.th';
	static const String _schoolEmailOnlyMessage =
			'Login only with school Gmail (@lamduan.mfu.ac.th).';

	final UserRepository _userRepo;
	final FeedbackRepository _feedbackRepo;
	final SessionRepository _sessionRepo;
	final FirebaseAuth _firebaseAuth;

	AuthService({
		required UserRepository userRepository,
		required FeedbackRepository feedbackRepository,
		required SessionRepository sessionRepository,
		FirebaseAuth? firebaseAuth,
	})  : _userRepo = userRepository,
			_feedbackRepo = feedbackRepository,
			_sessionRepo = sessionRepository,
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
				final signedInEmail = userCredential.user?.email?.trim() ?? '';
				if (!_isAllowedSchoolEmail(signedInEmail)) {
					await _firebaseAuth.signOut();
					throw AuthException(_schoolEmailOnlyMessage);
				}
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
			if (!_isAllowedSchoolEmail(account.email)) {
				throw AuthException(_schoolEmailOnlyMessage);
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
			final averageRating = _calculateBlendedRating(feedbackSummary);
			final totalSessions = await _calculateCompletedSessionCount(uid);
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

	Future<int> _calculateCompletedSessionCount(String uid) async {
		final createdFuture = _sessionRepo.getSessionsByCreator(uid);
		final partneredFuture = _sessionRepo.getSessionsByPartner(uid);
		final joinedFuture = _sessionRepo.getSessionsByParticipant(uid);

		final results = await Future.wait([
			createdFuture,
			partneredFuture,
			joinedFuture,
		]);

		final completedSessionIds = <String>{};
		for (final sessions in results) {
			for (final session in sessions) {
				if (session.status == SessionStatus.completed &&
						session.sessionId.isNotEmpty) {
					completedSessionIds.add(session.sessionId);
				}
			}
		}

		return completedSessionIds.length;
	}

	double _calculateBlendedRating(List<FeedbackModel> feedbackList) {
		if (feedbackList.isEmpty) return 0.0;

		final groupedBySession = <String, List<FeedbackModel>>{};
		for (final feedback in feedbackList) {
			final sessionId = feedback.sessionId;
			final rating = feedback.rating;
			if (sessionId.isEmpty || rating <= 0) {
				continue;
			}
			groupedBySession.putIfAbsent(sessionId, () => []).add(feedback);
		}

		if (groupedBySession.isEmpty) return 0.0;

		final sessionAverages = <_SessionAverage>[];
		for (final entry in groupedBySession.entries) {
			final ratings = entry.value
					.map((f) => f.rating)
					.where((r) => r > 0)
					.toList();
			if (ratings.isEmpty) continue;

			final total = ratings.fold<int>(0, (sum, value) => sum + value);
			final average = total / ratings.length;
			final latestAt = entry.value
					.map((f) => f.createdAt)
					.reduce((a, b) => a.isAfter(b) ? a : b);

			sessionAverages.add(
				_SessionAverage(
					average: average,
					time: latestAt,
				),
			);
		}

		if (sessionAverages.isEmpty) return 0.0;

		sessionAverages.sort((a, b) => a.time.compareTo(b.time));

		var finalRating = 0.0;
		for (final item in sessionAverages) {
			if (finalRating == 0.0) {
				finalRating = item.average;
			} else {
				finalRating = (finalRating + item.average) / 2;
			}
		}

		return double.parse(finalRating.toStringAsFixed(2));
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

	@visibleForTesting
	static bool isAllowedSchoolEmail(String email) {
		final normalized = email.trim().toLowerCase();
		return normalized.endsWith('@$_allowedSchoolDomain') ||
				normalized == 'testg0963@gmail.com';
	}

	bool _isAllowedSchoolEmail(String email) => isAllowedSchoolEmail(email);
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

class _SessionAverage {
	final double average;
	final DateTime time;

	const _SessionAverage({required this.average, required this.time});
}
