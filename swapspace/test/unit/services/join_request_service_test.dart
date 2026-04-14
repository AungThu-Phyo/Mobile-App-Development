import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:swapspace/models/join_request_model.dart';
import 'package:swapspace/repositories/join_request_repository.dart';
import 'package:swapspace/repositories/paginated_query_result.dart';
import 'package:swapspace/repositories/session_repository.dart';
import 'package:swapspace/repositories/user_repository.dart';
import 'package:swapspace/services/join_request_service.dart';
import 'package:swapspace/services/notification_service.dart';
import 'package:swapspace/core/constants/session_constants.dart';

class MockJoinRequestRepository extends Mock implements JoinRequestRepository {}
class MockSessionRepository extends Mock implements SessionRepository {}
class MockUserRepository extends Mock implements UserRepository {}
class MockNotificationService extends Mock implements NotificationService {}

void main() {
  setUpAll(() {
    registerFallbackValue(JoinRequestModel.empty());
  });

  test('sendJoinRequest creates request and sends notification', () async {
    final requestRepo = MockJoinRequestRepository();
    final sessionRepo = MockSessionRepository();
    final userRepo = MockUserRepository();
    final notificationService = MockNotificationService();

    when(() => requestRepo.createRequestId()).thenReturn('req-1');
    when(() => requestRepo.create(any())).thenAnswer((_) async {});
    when(
      () => notificationService.sendNotification(
        recipientUid: any(named: 'recipientUid'),
        senderUid: any(named: 'senderUid'),
        senderName: any(named: 'senderName'),
        sessionId: any(named: 'sessionId'),
        sessionTitle: any(named: 'sessionTitle'),
        type: any(named: 'type'),
        message: any(named: 'message'),
      ),
    ).thenAnswer((_) async {});

    final service = JoinRequestService(
      requestRepository: requestRepo,
      sessionRepository: sessionRepo,
      userRepository: userRepo,
      notificationService: notificationService,
    );

    await service.sendJoinRequest(
      sessionId: 's-1',
      creatorUid: 'creator-1',
      requesterUid: 'requester-1',
      requesterName: 'Requester',
      sessionTitle: 'Session Title',
    );

    final captured = verify(() => requestRepo.create(captureAny())).captured;
    final created = captured.single as JoinRequestModel;
    expect(created.requestId, 'req-1');
    expect(created.status, JoinRequestStatus.pending);
    expect(created.requestType, JoinRequestType.join);

    verify(
      () => notificationService.sendNotification(
        recipientUid: 'creator-1',
        senderUid: 'requester-1',
        senderName: 'Requester',
        sessionId: 's-1',
        sessionTitle: 'Session Title',
        type: NotificationType.joinRequest,
        message: 'Requester requested to join your session "Session Title"',
      ),
    ).called(1);
  });

  test('loadIncomingRequestsPage maps repository page result', () async {
    final requestRepo = MockJoinRequestRepository();
    final sessionRepo = MockSessionRepository();
    final userRepo = MockUserRepository();
    final notificationService = MockNotificationService();

    final request = JoinRequestModel(
      requestId: 'req-1',
      sessionId: 's-1',
      requesterUid: 'requester-1',
      creatorUid: 'creator-1',
      createdAt: DateTime(2024, 1, 1),
      updatedAt: DateTime(2024, 1, 1),
    );

    when(
      () => requestRepo.getPendingForCreatorPage(
        uid: 'creator-1',
        pageSize: JoinRequestRepository.defaultPageSize,
        startAfterDocument: null,
      ),
    ).thenAnswer(
      (_) async => PaginatedQueryResult<JoinRequestModel>(
        items: [request],
        lastDocument: null,
        hasMore: false,
      ),
    );

    final service = JoinRequestService(
      requestRepository: requestRepo,
      sessionRepository: sessionRepo,
      userRepository: userRepo,
      notificationService: notificationService,
    );

    final page = await service.loadIncomingRequestsPage(uid: 'creator-1');

    expect(page.items.length, 1);
    expect(page.items.first.requestId, 'req-1');
    expect(page.hasMore, false);
  });
}
