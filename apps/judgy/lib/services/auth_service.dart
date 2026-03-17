import 'package:firebase_auth/firebase_auth.dart' as auth;
import 'package:flutter/foundation.dart';

class AuthService extends ChangeNotifier {
  AuthService() {
    _firebaseAuth.authStateChanges().listen((user) {
      _currentUser = user;
      notifyListeners();
    });
  }
  final auth.FirebaseAuth _firebaseAuth = auth.FirebaseAuth.instance;
  auth.User? _currentUser;

  auth.User? get currentUser => _currentUser;
  bool get isAuthenticated => _currentUser != null;

  /// Sign in anonymously (default quick play).
  Future<auth.UserCredential> signInAnonymously() async {
    return _firebaseAuth.signInAnonymously();
  }

  /// Sign out.
  Future<void> signOut() async {
    await _firebaseAuth.signOut();
  }

  // TODO: Add Google, Apple, and Email Sign-In methods.
}
