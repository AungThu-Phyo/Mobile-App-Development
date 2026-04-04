import 'dart:convert';

import '../core/utils/app_logger.dart';
import '../repositories/privacy_repository.dart';
import 'auth_service.dart';

class PrivacyService {
  final PrivacyRepository _privacyRepository;
  final AuthService _authService;

  PrivacyService({
    required PrivacyRepository privacyRepository,
    required AuthService authService,
  })  : _privacyRepository = privacyRepository,
        _authService = authService;

  Future<String> exportMyData(String uid) async {
    final payload = await _privacyRepository.exportUserData(uid);
    const encoder = JsonEncoder.withIndent('  ');
    return encoder.convert(payload);
  }

  Future<void> deleteMyAccount(String uid) async {
    await _privacyRepository.deleteUserData(uid);
    try {
      await _authService.deleteCurrentAuthAccount();
    } catch (e, stackTrace) {
      // Keep account deletion flow resilient: user data is already removed.
      AppLogger.debug('PrivacyService.deleteMyAccount auth delete skipped: $e');
      AppLogger.error(
        'PrivacyService.deleteMyAccount auth delete error',
        e,
        stackTrace,
      );
    }
    await _authService.signOut();
  }
}
