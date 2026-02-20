import 'package:flutter/material.dart';
import '../models/user_model.dart';
import '../core/mock_data/mock_profile.dart';

class AuthProvider extends ChangeNotifier {
  UserModel? _currentUser;
  bool _isLoggedIn = false;

  bool get isLoggedIn => _isLoggedIn;
  UserModel? get currentUser => _currentUser;

  void checkAuthStatus() {
    _isLoggedIn = false;
    notifyListeners();
  }

  void login(String email) {
    _currentUser = mockCurrentUser;
    _isLoggedIn = true;
    notifyListeners();
  }

  void logout() {
    _currentUser = null;
    _isLoggedIn = false;
    notifyListeners();
  }
}
