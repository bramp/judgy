import 'package:firebase_auth/firebase_auth.dart' as auth;
import 'package:flutter/foundation.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:sign_in_with_apple/sign_in_with_apple.dart';

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

  /// Sign in with Email and Password
  Future<auth.UserCredential> signInWithEmailAndPassword(
    String email,
    String password,
  ) async {
    return _firebaseAuth.signInWithEmailAndPassword(
      email: email,
      password: password,
    );
  }

  /// Create user with Email and Password
  Future<auth.UserCredential> createUserWithEmailAndPassword(
    String email,
    String password,
  ) async {
    return _firebaseAuth.createUserWithEmailAndPassword(
      email: email,
      password: password,
    );
  }

  /// Sign in with Google
  Future<auth.UserCredential?> signInWithGoogle() async {
    if (kIsWeb) {
      final provider = auth.GoogleAuthProvider();
      return _firebaseAuth.signInWithPopup(provider);
    } else {
      final googleUser = await GoogleSignIn().signIn();
      if (googleUser == null) {
        return null; // The user canceled the sign-in
      }

      final googleAuth = await googleUser.authentication;

      final credential = auth.GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      return _firebaseAuth.signInWithCredential(credential);
    }
  }

  /// Sign in with Apple
  Future<auth.UserCredential?> signInWithApple() async {
    if (kIsWeb) {
      final provider = auth.AppleAuthProvider();
      return _firebaseAuth.signInWithPopup(provider);
    } else {
      final appleCredential = await SignInWithApple.getAppleIDCredential(
        scopes: [
          AppleIDAuthorizationScopes.email,
          AppleIDAuthorizationScopes.fullName,
        ],
      );

      final credential = auth.OAuthProvider('apple.com').credential(
        idToken: appleCredential.identityToken,
        accessToken: appleCredential.authorizationCode,
      );

      return _firebaseAuth.signInWithCredential(credential);
    }
  }
}
