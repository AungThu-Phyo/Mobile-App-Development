import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import '../core/errors/repository_exception.dart';
import '../core/utils/app_logger.dart';

abstract class BaseStateProvider extends ChangeNotifier {
  bool _isLoading = false;
  String? _error;

  bool get isLoading => _isLoading;
  String? get error => _error;

  void setLoading(bool value) {
    _isLoading = value;
    notifyListeners();
  }

  void setError(String? value) {
    _error = value;
    notifyListeners();
  }

  void clearError() {
    setError(null);
  }

  Future<T> runWithLoading<T>({
    required Future<T> Function() action,
    required String errorMessage,
    required String debugLabel,
  }) async {
    setLoading(true);
    _error = null;

    try {
      return await action();
    } catch (e, stackTrace) {
      AppLogger.error('$debugLabel error', e, stackTrace);
      _error = _friendlyErrorMessage(e, fallback: errorMessage);
      rethrow;
    } finally {
      setLoading(false);
    }
  }

  String _friendlyErrorMessage(Object error, {required String fallback}) {
    if (error is RepositoryException) {
      switch (error.code) {
        case 'permission-denied':
          return 'You do not have permission to perform this action.';
        case 'unauthenticated':
          return 'Please sign in and try again.';
        case 'unavailable':
        case 'network-request-failed':
          return 'Network error. Please check your connection and try again.';
        case 'deadline-exceeded':
          return 'The request timed out. Please try again.';
        case 'already-exists':
          return 'This item already exists.';
        case 'not-found':
          return 'The requested item was not found.';
      }
    }
    return fallback;
  }
}