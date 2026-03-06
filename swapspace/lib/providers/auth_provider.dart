import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/user_model.dart';
import '../repositories/user_repository.dart';

class AuthProvider extends ChangeNotifier {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final UserRepository _userRepo = UserRepository();

  User? _firebaseUser;
  UserModel? _currentUser;
  bool _isLoading = true;
  String? _error;

  bool get isLoggedIn => _firebaseUser != null;
  User? get firebaseUser => _firebaseUser;
  UserModel? get currentUser => _currentUser;
  bool get isLoading => _isLoading;
  String? get error => _error;

  AuthProvider() {
    _auth.authStateChanges().listen(_onAuthStateChanged);
  }

  Future<void> _onAuthStateChanged(User? user) async {
    _firebaseUser = user;
    if (user != null) {
      _currentUser = await _userRepo.getUser(user.uid);
      if (_currentUser == null) {
        final newUser = UserModel(
          uid: user.uid,
          name: user.displayName ?? '',
          email: user.email ?? '',
          avatarUrl: user.photoURL ?? '',
          createdAt: DateTime.now(),
          lastSeen: DateTime.now(),
        );
        await _userRepo.createUser(newUser);
        _currentUser = newUser;
      } else {
        await _userRepo.updateLastSeen(user.uid);
        _currentUser = _currentUser!.copyWith(lastSeen: DateTime.now());
      }
    } else {
      _currentUser = null;
    }
    _isLoading = false;
    notifyListeners();
  }

  Future<bool> signInWithGoogle() async {
    try {
      _error = null;
      _isLoading = true;
      notifyListeners();

      final GoogleAuthProvider googleProvider = GoogleAuthProvider();
      googleProvider.addScope('email');
      googleProvider.addScope('profile');
      googleProvider.setCustomParameters({
        // 'hd': 'lamduan.mfu.ac.th',
        'prompt': 'select_account',
      });

      final UserCredential userCredential =
          await _auth.signInWithPopup(googleProvider);

      final user = userCredential.user;

      if (user == null) {
        _error = 'Sign in cancelled';
        _isLoading = false;
        notifyListeners();
        return false;
      }

      // Validate email domain
      // TODO: Re-enable domain check after testing
      // final email = user.email ?? '';
      // if (!email.endsWith('@lamduan.mfu.ac.th')) {
      //   await user.delete();
      //   await _auth.signOut();
      //   _error = 'Only MFU student emails (@lamduan.mfu.ac.th) are allowed';
      //   _isLoading = false;
      //   notifyListeners();
      //   return false;
      // }

      return true;
    } on FirebaseAuthException catch (e) {
      if (e.code == 'popup-closed-by-user' ||
          e.code == 'cancelled-popup-request') {
        _error = 'Sign in cancelled';
      } else {
        _error = e.message ?? 'An error occurred during sign in';
      }
      _isLoading = false;
      notifyListeners();
      return false;
    } catch (e) {
      if (e.toString().contains('popup-closed-by-user') ||
          e.toString().contains('cancelled-popup-request')) {
        _error = 'Sign in cancelled';
      } else {
        _error = 'An error occurred during sign in';
      }
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  Future<void> signOut() async {
    await _auth.signOut();
  }

  void clearError() {
    _error = null;
    notifyListeners();
  }
}
