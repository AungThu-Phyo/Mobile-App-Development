import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:swapspace/models/notification_model.dart';
import 'package:swapspace/repositories/notification_repository.dart';
import 'package:swapspace/repositories/paginated_query_result.dart';
import 'package:swapspace/services/notification_service.dart';

class MockNotificationRepository extends Mock
    implements NotificationRepository {}

void main() {
  setUpAll(() {
    registerFallbackValue(
      NotificationModel(
        notificationId: 'fallback',
        recipientUid: 'u',
        senderUid: 's',
        senderName: 'Sender',
        sessionId: 's',
        sessionTitle: 'Title',
        type: 'type',
        message: 'message',
        createdAt: DateTime(2024, 1, 1),
      ),
    );
  });

  test('sendNotification persists notification', () async {
    final repo = MockNotificationRepository();
    final service = NotificationService(repository: repo);

    when(() => repo.createNotificationId()).thenReturn('notif-1');
    when(() => repo.create(any())).thenAnswer((_) async {});

    await service.sendNotification(
      recipientUid: 'user-1',
      senderUid: 'creator-1',
      senderName: 'Creator',
      sessionId: 'session-1',
      sessionTitle: 'Session',
      type: 'join_request',
      message: 'Requested',
    );

    final captured = verify(() => repo.create(captureAny())).captured;
    final created = captured.single as NotificationModel;
    expect(created.notificationId, 'notif-1');
    expect(created.recipientUid, 'user-1');
  });

  test('calculateUnreadCount returns only unread items', () async {
    final repo = MockNotificationRepository();
    final service = NotificationService(repository: repo);

    final items = [
      NotificationModel(
        notificationId: 'n1',
        recipientUid: 'u1',
        senderUid: 's1',
        senderName: 'S',
        sessionId: 's1',
        sessionTitle: 'Title',
        type: 't',
        message: 'm',
        createdAt: DateTime(2024, 1, 1),
        isRead: false,
      ),
      NotificationModel(
        notificationId: 'n2',
        recipientUid: 'u1',
        senderUid: 's1',
        senderName: 'S',
        sessionId: 's1',
        sessionTitle: 'Title',
        type: 't',
        message: 'm',
        createdAt: DateTime(2024, 1, 1),
        isRead: true,
      ),
    ];

    expect(service.calculateUnreadCount(items), 1);
  });

  test('markAsRead delegates to repository', () async {
    final repo = MockNotificationRepository();
    final service = NotificationService(repository: repo);

    when(() => repo.markRead('notif-1')).thenAnswer((_) async {});

    await service.markAsRead('notif-1');

    verify(() => repo.markRead('notif-1')).called(1);
  });

  test('fetchNotificationsPage maps paginated result', () async {
    final repo = MockNotificationRepository();
    final service = NotificationService(repository: repo);

    final model = NotificationModel(
      notificationId: 'n1',
      recipientUid: 'u1',
      senderUid: 's1',
      senderName: 'S',
      sessionId: 's1',
      sessionTitle: 'Title',
      type: 't',
      message: 'm',
      createdAt: DateTime(2024, 1, 1),
    );

    when(
      () => repo.getForUserPage(
        uid: 'u1',
        pageSize: any(named: 'pageSize'),
        startAfterDocument: any(named: 'startAfterDocument'),
      ),
    ).thenAnswer(
      (_) async => PaginatedQueryResult<NotificationModel>(
        items: [model],
        lastDocument: null,
        hasMore: false,
      ),
    );

    final page = await service.fetchNotificationsPage(uid: 'u1');

    expect(page.items.length, 1);
    expect(page.items.first.notificationId, 'n1');
    expect(page.hasMore, false);
  });
}
