import 'dart:async';
import 'base_state_provider.dart';
import '../core/utils/app_logger.dart';
import '../models/user_model.dart';
import '../services/auth_service.dart';

class AuthProvider extends BaseStateProvider {
  final AuthService _authService;
  late StreamSubscription<String?> _authSubscription;
  final Map<String, UserModel> _publicUserCache = {};

  String? _userId;
  UserModel? _currentUser;

  bool get isLoggedIn => _userId != null;
  String? get userId => _userId;
  UserModel? get currentUser => _currentUser;

  AuthProvider({required AuthService authService}) : _authService = authService {
    setLoading(true);
    _authSubscription = authService.authStateStream().listen(_onAuthStateChanged);
  }

  Future<void> _onAuthStateChanged(String? userId) async {
    setError(null);

    try {
      _userId = userId;
      if (userId != null) {
        _currentUser = await _authService.bootstrapUser(userId);
      } else {
        _currentUser = null;
      }
    } catch (e, stackTrace) {
      AppLogger.error('AuthProvider._onAuthStateChanged bootstrap error', e, stackTrace);
      _currentUser = null;
      setError('Profile data could not be loaded. Please sign in again.');
    } finally {
      setLoading(false);
    }
  }

  Future<bool> signInWithGoogle() async {
    return runWithLoading<bool>(
      debugLabel: 'AuthProvider.signInWithGoogle',
      errorMessage: 'Unable to sign in',
      action: () async {
        try {
          return await _authService.signInWithGoogle();
        } on AuthCanceledException catch (e) {
          AppLogger.debug('AuthProvider.signInWithGoogle canceled: $e');
          setError(e.message);
          return false;
        } on AuthException catch (e, stackTrace) {
          AppLogger.error('AuthProvider.signInWithGoogle auth error', e, stackTrace);
          setError(e.message);
          return false;
        }
      },
    );
  }

  Future<void> signOut() async {
    _publicUserCache.clear();
    _userId = null;
    _currentUser = null;
    setError(null);
    setLoading(false);
    notifyListeners();

    try {
      await _authService.signOut();
    } catch (e, stackTrace) {
      AppLogger.error('AuthProvider.signOut error', e, stackTrace);
    }
  }

  Future<bool> reauthenticateForSensitiveAction() async {
    return runWithLoading<bool>(
      debugLabel: 'AuthProvider.reauthenticateForSensitiveAction',
      errorMessage: 'Unable to re-authenticate',
      action: () async {
        try {
          await _authService.reauthenticateWithGoogle();
          return true;
        } on AuthCanceledException catch (e) {
          AppLogger.debug('AuthProvider.reauthenticateForSensitiveAction canceled: $e');
          setError(e.message);
          return false;
        } on AuthException catch (e, stackTrace) {
          AppLogger.error('AuthProvider.reauthenticateForSensitiveAction auth error', e, stackTrace);
          setError(e.message);
          return false;
        }
      },
    );
  }

  Future<UserModel?> getUserById(String uid) {
    final normalizedUid = uid.trim();
    if (normalizedUid.isEmpty) {
      return Future.value(null);
    }

    final cached = _publicUserCache[normalizedUid];
    if (cached != null) {
      return Future.value(cached);
    }

    return _authService.getUserById(normalizedUid).then((user) {
      if (user != null && user.uid.isNotEmpty) {
        _publicUserCache[user.uid] = user;
      }
      return user;
    });
  }

  Future<Map<String, UserModel>> getUsersByIds(List<String> uids) {
    final normalized =
        uids.where((uid) => uid.trim().isNotEmpty).toSet().toList();
    if (normalized.isEmpty) {
      return Future.value({});
    }

    final result = <String, UserModel>{};
    final missing = <String>[];

    for (final uid in normalized) {
      final cached = _publicUserCache[uid];
      if (cached != null) {
        result[uid] = cached;
      } else {
        missing.add(uid);
      }
    }

    if (missing.isEmpty) {
      return Future.value(result);
    }

    return _authService.getUsersByIds(missing).then((loaded) {
      _publicUserCache.addAll(loaded);
      result.addAll(loaded);
      return result;
    });
  }

  Future<void> refreshCurrentUser() async {
    final uid = _userId;
    if (uid == null) return;

    setLoading(true);
    setError(null);
    try {
      _currentUser = await _authService.bootstrapUser(uid);
    } catch (e, stackTrace) {
      AppLogger.error('AuthProvider.refreshCurrentUser error', e, stackTrace);
      _currentUser = null;
      setError('Profile data could not be loaded. Please sign in again.');
    } finally {
      setLoading(false);
    }
  }

  @override
  void clearError() {
    setError(null);
  }

  @override
  void dispose() {
    _authSubscription.cancel();
    super.dispose();
  }
}
