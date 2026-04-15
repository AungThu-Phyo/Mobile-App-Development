import 'package:flutter_test/flutter_test.dart';
import 'package:swapspace/core/errors/repository_exception.dart';
import 'package:swapspace/providers/base_state_provider.dart';

class TestProvider extends BaseStateProvider {
  Future<void> runFail(RepositoryException exception) async {
    try {
      await runWithLoading(
        action: () async => throw exception,
        errorMessage: 'Fallback error',
        debugLabel: 'TestProvider.runFail',
      );
    } catch (_) {
      // Expected for this test.
    }
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('runWithLoading maps permission denied errors', () async {
    final provider = TestProvider();
    provider.addListener(() {});

    await provider.runFail(
      const RepositoryException(
        code: 'permission-denied',
        message: 'Denied',
      ),
    );

    expect(provider.error, 'You do not have permission to perform this action.');
  });

  test('runWithLoading maps network errors', () async {
    final provider = TestProvider();
    provider.addListener(() {});

    await provider.runFail(
      const RepositoryException(
        code: 'network-request-failed',
        message: 'Offline',
      ),
    );

    expect(provider.error, 'Network error. Please check your connection and try again.');
  });
}
