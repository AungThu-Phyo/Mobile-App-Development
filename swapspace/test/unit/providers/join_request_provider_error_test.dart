import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:swapspace/core/errors/repository_exception.dart';
import 'package:swapspace/providers/join_request_provider.dart';
import 'package:swapspace/services/join_request_service.dart';

class MockJoinRequestService extends Mock implements JoinRequestService {}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('acceptRequest maps permission-denied into friendly error', () async {
    final service = MockJoinRequestService();
    final provider = JoinRequestProvider(service: service);

    when(() => service.acceptRequest(requestId: 'req-1')).thenThrow(
      const RepositoryException(code: 'permission-denied', message: 'Denied'),
    );

    await expectLater(
      provider.acceptRequest('req-1'),
      throwsA(isA<RepositoryException>()),
    );
    expect(provider.error, 'You do not have permission to perform this action.');
  });

  test('rejectRequest maps network failure into friendly error', () async {
    final service = MockJoinRequestService();
    final provider = JoinRequestProvider(service: service);

    when(() => service.rejectRequest(requestId: 'req-1')).thenThrow(
      const RepositoryException(
        code: 'network-request-failed',
        message: 'Offline',
      ),
    );

    await expectLater(
      provider.rejectRequest('req-1'),
      throwsA(isA<RepositoryException>()),
    );
    expect(provider.error, 'Network error. Please check your connection and try again.');
  });
}
