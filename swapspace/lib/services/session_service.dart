import 'package:cloud_firestore/cloud_firestore.dart';

import '../core/constants/session_constants.dart';
import '../core/utils/app_logger.dart';
import '../models/session_model.dart';
import '../repositories/join_request_repository.dart';
import '../repositories/paginated_query_result.dart';
import '../repositories/session_repository.dart';
import 'notification_service.dart';

class SessionMutationResult {
	final List<SessionModel> sessions;
	final List<SessionModel> mySessions;
	final SessionModel? selectedSession;

	const SessionMutationResult({
		required this.sessions,
		required this.mySessions,
		required this.selectedSession,
	});
}

class SessionPageResult {
	final List<SessionModel> items;
	final QueryDocumentSnapshot<Map<String, dynamic>>? lastDocument;
	final bool hasMore;

	const SessionPageResult({
		required this.items,
		required this.lastDocument,
		required this.hasMore,
	});
}

class JoinedSessionsCursorState {
	final QueryDocumentSnapshot<Map<String, dynamic>>? partnerCursor;
	final QueryDocumentSnapshot<Map<String, dynamic>>? participantCursor;
	final bool hasMorePartner;
	final bool hasMoreParticipant;

	const JoinedSessionsCursorState({
		required this.partnerCursor,
		required this.participantCursor,
		required this.hasMorePartner,
		required this.hasMoreParticipant,
	});
}

class JoinedSessionsPageResult {
	final List<SessionModel> items;
	final JoinedSessionsCursorState cursorState;

	const JoinedSessionsPageResult({
		required this.items,
		required this.cursorState,
	});
}

class SessionService {
	final SessionRepository _repo;
	final JoinRequestRepository? _joinRequestRepo;
	final NotificationService _notificationService;

	SessionService({
		required SessionRepository repository,
		JoinRequestRepository? joinRequestRepository,
		required NotificationService notificationService,
	})  : _repo = repository,
				_joinRequestRepo = joinRequestRepository,
				_notificationService = notificationService;

	List<SessionModel> filterSessions({
		required List<SessionModel> sessions,
		required String currentUid,
		required double userRating,
		required String selectedFilter,
	}) {
		var result = sessions.where((s) {
			final isMine = s.creatorUid == currentUid;
			final hasJoined = s.participantUids.contains(currentUid);
			final isFull = s.participantUids.length >= s.maxParticipants;

			// Always show sessions the user created or already joined
			if (isMine || hasJoined) return true;

			// Hide full sessions from other users
			if (isFull) return false;

			// Check min rating requirement
			return s.minRating <= userRating || s.minRating == 0;
		}).toList();

		if (selectedFilter != SessionConstants.filterAll) {
			result = result
					.where(
						(s) =>
								s.activityType.toLowerCase() == selectedFilter.toLowerCase(),
					)
					.toList();
		}

		return result;
	}

	Future<List<SessionModel>> loadOpenSessions() async {
		final firstPage = await loadOpenSessionsPage();
		return firstPage.items;
	}

	Future<SessionPageResult> loadOpenSessionsPage({
		int pageSize = SessionRepository.defaultPageSize,
		QueryDocumentSnapshot<Map<String, dynamic>>? startAfterDocument,
	}) async {
		final PaginatedQueryResult<SessionModel> page =
				await _repo.getSessionsByStatusPage(
					status: SessionStatus.open,
					pageSize: pageSize,
					startAfterDocument: startAfterDocument,
				);

		return SessionPageResult(
			items: page.items,
			lastDocument: page.lastDocument,
			hasMore: page.hasMore,
		);
	}

	Future<SessionPageResult> loadCreatedSessionsPage({
		required String uid,
		int pageSize = SessionRepository.defaultPageSize,
		QueryDocumentSnapshot<Map<String, dynamic>>? startAfterDocument,
	}) async {
		final PaginatedQueryResult<SessionModel> page =
				await _repo.getSessionsByCreatorPage(
					uid: uid,
					pageSize: pageSize,
					startAfterDocument: startAfterDocument,
				);

		return SessionPageResult(
			items: page.items,
			lastDocument: page.lastDocument,
			hasMore: page.hasMore,
		);
	}

	Future<JoinedSessionsPageResult> loadJoinedSessionsPage({
		required String uid,
		int pageSize = SessionRepository.defaultPageSize,
		JoinedSessionsCursorState? cursorState,
	}) async {
		final currentState =
				cursorState ??
				const JoinedSessionsCursorState(
					partnerCursor: null,
					participantCursor: null,
					hasMorePartner: true,
					hasMoreParticipant: true,
				);

		final sourcePageSize = (pageSize / 2).ceil();

		PaginatedQueryResult<SessionModel> partnerPage =
				const PaginatedQueryResult<SessionModel>(
					items: [],
					lastDocument: null,
					hasMore: false,
				);
		PaginatedQueryResult<SessionModel> participantPage =
				const PaginatedQueryResult<SessionModel>(
					items: [],
					lastDocument: null,
					hasMore: false,
				);

		if (currentState.hasMorePartner) {
			partnerPage = await _repo.getSessionsByPartnerPage(
				uid: uid,
				pageSize: sourcePageSize,
				startAfterDocument: currentState.partnerCursor,
			);
		}

		if (currentState.hasMoreParticipant) {
			participantPage = await _repo.getSessionsByParticipantPage(
				uid: uid,
				pageSize: sourcePageSize,
				startAfterDocument: currentState.participantCursor,
			);
		}

		final merged = <String, SessionModel>{};
		for (final session in [...partnerPage.items, ...participantPage.items]) {
			if (session.creatorUid == uid) {
				continue;
			}
			merged[session.sessionId] = session;
		}

		final items = merged.values.toList()
			..sort((a, b) => b.date.compareTo(a.date));

		return JoinedSessionsPageResult(
			items: items.take(pageSize).toList(),
			cursorState: JoinedSessionsCursorState(
				partnerCursor: partnerPage.lastDocument ?? currentState.partnerCursor,
				participantCursor:
						participantPage.lastDocument ?? currentState.participantCursor,
				hasMorePartner:
						currentState.hasMorePartner ? partnerPage.hasMore : false,
				hasMoreParticipant:
						currentState.hasMoreParticipant ? participantPage.hasMore : false,
			),
		);
	}

	Future<List<SessionModel>> loadMySessions(String uid) async {
		// Get all sessions where user is creator, partner, or participant
		final created = await _repo.getSessionsByCreator(uid);
		final partnership = await _repo.getSessionsByPartner(uid);
		final participation = await _repo.getSessionsByParticipant(uid);
		
		// Merge results (deduplicate by sessionId), then add fallback from accepted join requests.
		final sessionMap = <String, SessionModel>{};
		for (final session in [...created, ...partnership, ...participation]) {
			sessionMap[session.sessionId] = session;
		}

		if (_joinRequestRepo != null) {
			final outgoing = await _joinRequestRepo.getFromUser(uid);
			final acceptedJoinSessionIds = outgoing
					.where(
						(r) =>
							r.requestType == JoinRequestType.join &&
							r.status == JoinRequestStatus.accepted,
					)
					.map((r) => r.sessionId)
					.toSet();

			final acceptedLeaveSessionIds = outgoing
					.where(
						(r) =>
							r.requestType == JoinRequestType.leave &&
							r.status == JoinRequestStatus.accepted,
					)
					.map((r) => r.sessionId)
					.toSet();

			final fallbackSessionIds = acceptedJoinSessionIds
					.where(
						(sessionId) =>
							!acceptedLeaveSessionIds.contains(sessionId) &&
							!sessionMap.containsKey(sessionId),
					)
					.toList();

			for (final sessionId in fallbackSessionIds) {
				try {
					final session = await _repo.getById(sessionId);
					if (session != null) {
						sessionMap[session.sessionId] = session;
					}
				} catch (e, stackTrace) {
					AppLogger.error('SessionService.loadMySessions fallback fetch failed', e, stackTrace);
				}
			}
		}
		
		var sessions = sessionMap.values.toList()
			..sort((a, b) => b.date.compareTo(a.date));
		
		return sessions;
	}

	Future<SessionModel> createSession(SessionModel session) async {
		await _repo.create(session);
		return session;
	}

	Future<SessionMutationResult> cancelSession({
		required String sessionId,
		required List<SessionModel> sessions,
		required List<SessionModel> mySessions,
		required SessionModel? selectedSession,
	}) async {
		final latestSession = await _repo.getById(sessionId);
		if (latestSession == null || latestSession.sessionId.isEmpty) {
			throw StateError('session-not-found');
		}

		final updated = latestSession.copyWith(
			status: SessionStatus.cancelled,
			isActive: false,
			updatedAt: DateTime.now(),
		);
		await _repo.update(updated);

		final nextSessions = sessions.where((s) => s.sessionId != sessionId).toList();
		final nextMySessions = List<SessionModel>.from(mySessions);
		final myIdx = nextMySessions.indexWhere((s) => s.sessionId == sessionId);
		if (myIdx != -1) {
			nextMySessions[myIdx] = updated;
		}
		final selected = selectedSession?.sessionId == sessionId
				? updated
				: selectedSession;

		return SessionMutationResult(
			sessions: nextSessions,
			mySessions: nextMySessions,
			selectedSession: selected,
		);
	}

	Future<SessionModel?> getSessionById(String sessionId) {
		return _repo.getById(sessionId);
	}

	Future<SessionMutationResult> updateSession({
		required SessionModel session,
		required List<SessionModel> sessions,
		required List<SessionModel> mySessions,
		required SessionModel? selectedSession,
	}) async {
		// If session was matched but now has room, revert to open
		var toSave = session;
		if (session.status == SessionStatus.matched &&
				session.participantUids.length < session.maxParticipants) {
			toSave = session.copyWith(status: SessionStatus.open, isActive: true);
		}

		final updated = toSave.copyWith(updatedAt: DateTime.now());
		await _repo.update(updated);

		final nextSessions = List<SessionModel>.from(sessions);
		final idx = nextSessions.indexWhere((s) => s.sessionId == updated.sessionId);
		if (idx != -1) nextSessions[idx] = updated;

		final nextMySessions = List<SessionModel>.from(mySessions);
		final myIdx =
				nextMySessions.indexWhere((s) => s.sessionId == updated.sessionId);
		if (myIdx != -1) nextMySessions[myIdx] = updated;

		final selected = selectedSession?.sessionId == updated.sessionId
				? updated
				: selectedSession;

		// Notify all joined participants (except the creator) about the update
		for (final uid in updated.participantUids) {
			if (uid != updated.creatorUid) {
				await _notificationService.sendNotification(
					recipientUid: uid,
					senderUid: updated.creatorUid,
					senderName: updated.creatorName,
					sessionId: updated.sessionId,
					sessionTitle: updated.title,
					type: NotificationType.sessionUpdated,
					message: '${updated.creatorName} updated the session ${updated.title}',
				);
			}
		}

		return SessionMutationResult(
			sessions: nextSessions,
			mySessions: nextMySessions,
			selectedSession: selected,
		);
	}
}
