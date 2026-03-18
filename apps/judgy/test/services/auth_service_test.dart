import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:judgy/services/auth_service.dart';
import 'package:mocktail/mocktail.dart';

// Mocks
class MockFirebaseAuth extends Mock implements FirebaseAuth {}

class MockUserCredential extends Mock implements UserCredential {}

class MockUser extends Mock implements User {}

class MockGoogleSignIn extends Mock implements GoogleSignIn {}

void main() {
  late MockFirebaseAuth mockFirebaseAuth;
  late MockGoogleSignIn mockGoogleSignIn;
  late AuthService authService;

  setUp(() {
    mockFirebaseAuth = MockFirebaseAuth();
    mockGoogleSignIn = MockGoogleSignIn();

    // Stub authStateChanges to return an empty stream to avoid hanging
    // or errors taking place during AuthService initialization
    when(
      () => mockFirebaseAuth.authStateChanges(),
    ).thenAnswer((_) => const Stream.empty());

    authService = AuthService(
      firebaseAuth: mockFirebaseAuth,
      googleSignIn: mockGoogleSignIn,
    );
  });

  group('AuthService', () {
    test('signInAnonymously calls FirebaseAuth.signInAnonymously', () async {
      final mockCredential = MockUserCredential();
      when(
        () => mockFirebaseAuth.signInAnonymously(),
      ).thenAnswer((_) async => mockCredential);

      final result = await authService.signInAnonymously();

      expect(result, equals(mockCredential));
      verify(() => mockFirebaseAuth.signInAnonymously()).called(1);
    });

    test('signOut calls FirebaseAuth.signOut', () async {
      when(() => mockFirebaseAuth.signOut()).thenAnswer((_) async => {});

      await authService.signOut();

      verify(() => mockFirebaseAuth.signOut()).called(1);
    });

    test('signInWithEmailAndPassword calls FirebaseAuth', () async {
      final mockCredential = MockUserCredential();
      when(
        () => mockFirebaseAuth.signInWithEmailAndPassword(
          email: 'test@example.com',
          password: 'password',
        ),
      ).thenAnswer((_) async => mockCredential);

      final result = await authService.signInWithEmailAndPassword(
        'test@example.com',
        'password',
      );

      expect(result, equals(mockCredential));
      verify(
        () => mockFirebaseAuth.signInWithEmailAndPassword(
          email: 'test@example.com',
          password: 'password',
        ),
      ).called(1);
    });
  });
}
