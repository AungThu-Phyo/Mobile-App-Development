import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:swapspace/repositories/privacy_repository.dart';
import 'package:swapspace/services/auth_service.dart';
import 'package:swapspace/services/privacy_service.dart';

class MockPrivacyRepository extends Mock implements PrivacyRepository {}
class MockAuthService extends Mock implements AuthService {}

void main() {
  test('exportMyData returns formatted JSON', () async {
    final privacyRepo = MockPrivacyRepository();
    final authService = MockAuthService();
    final service = PrivacyService(
      privacyRepository: privacyRepo,
      authService: authService,
    );

    when(() => privacyRepo.exportUserData('u1')).thenAnswer(
      (_) async => {
        'user': {'uid': 'u1'},
      },
    );

    final result = await service.exportMyData('u1');

    expect(result, contains('"uid": "u1"'));
  });

  test('deleteMyAccount continues even if auth deletion fails', () async {
    final privacyRepo = MockPrivacyRepository();
    final authService = MockAuthService();
    final service = PrivacyService(
      privacyRepository: privacyRepo,
      authService: authService,
    );

    when(() => privacyRepo.deleteUserData('u1')).thenAnswer((_) async {});
    when(() => authService.deleteCurrentAuthAccount())
        .thenThrow(Exception('auth fail'));
    when(() => authService.signOut()).thenAnswer((_) async {});

    await service.deleteMyAccount('u1');

    verify(() => privacyRepo.deleteUserData('u1')).called(1);
    verify(() => authService.signOut()).called(1);
  });
}
