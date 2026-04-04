import 'base_state_provider.dart';
import '../core/errors/repository_exception.dart';
import '../core/utils/app_logger.dart';
import '../services/privacy_service.dart';

class PrivacyProvider extends BaseStateProvider {
  final PrivacyService _service;

  PrivacyProvider({required PrivacyService service}) : _service = service;

  Future<String?> exportMyData(String uid) async {
    return runWithLoading<String?>(
      debugLabel: 'PrivacyProvider.exportMyData',
      errorMessage: 'Unable to export your data',
      action: () => _service.exportMyData(uid),
    );
  }

  Future<bool> deleteMyAccount(String uid) async {
    setLoading(true);
    setError(null);
    try {
      await _service.deleteMyAccount(uid);
      return true;
    } catch (e, stackTrace) {
      AppLogger.error('PrivacyProvider.deleteMyAccount error', e, stackTrace);
      final message = _mapDeleteErrorMessage(e);
      setError(message);
      return false;
    } finally {
      setLoading(false);
    }
  }

  String _mapDeleteErrorMessage(Object error) {
    if (error is RepositoryException) {
      if (error.code == 'permission-denied') {
        return 'Unable to delete account data due to access restrictions. Please try again shortly.';
      }
      if (error.code == 'partial-delete') {
        return 'Some account data could not be deleted yet. Please try again.';
      }
    }

    final raw = error.toString().toLowerCase();
    if (raw.contains('requires-recent-login') ||
        raw.contains('re-authentication required') ||
        raw.contains('recent login')) {
      return 'Re-authentication required before deleting account. Please sign in again and retry.';
    }
    return 'Unable to delete account right now. Please try again.';
  }
}
