import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:judgy/services/game_loop_service.dart';
import 'package:judgy/models/game_models.dart';
import 'package:mocktail/mocktail.dart';

class MockFirebaseFirestore extends Mock implements FirebaseFirestore {}

class MockCollectionReference extends Mock
    implements CollectionReference<Map<String, dynamic>> {}

class MockDocumentReference extends Mock
    implements DocumentReference<Map<String, dynamic>> {}

class MockDocumentSnapshot extends Mock
    implements DocumentSnapshot<Map<String, dynamic>> {}

void main() {
  group('GameLoopService', () {
    late MockFirebaseFirestore mockFirestore;
    late MockCollectionReference mockRoomsCollection;
    late MockDocumentReference mockDocRef;
    late GameLoopService service;

    setUp(() {
      mockFirestore = MockFirebaseFirestore();
      mockRoomsCollection = MockCollectionReference();
      mockDocRef = MockDocumentReference();

      when(
        () => mockFirestore.collection('rooms'),
      ).thenReturn(mockRoomsCollection);
      when(() => mockRoomsCollection.doc('test-room')).thenReturn(mockDocRef);

      service = GameLoopService(firestore: mockFirestore);
    });

    test('currentRoom is null until room data is received', () {
      final controller =
          StreamController<DocumentSnapshot<Map<String, dynamic>>>();
      when(() => mockDocRef.snapshots()).thenAnswer((_) => controller.stream);

      service.listenToRoom('test-room');

      // Right after listenToRoom, currentRoom should still be null
      expect(service.currentRoom, isNull);

      controller.close();
    });

    test('startGame updates room status if loaded', () async {
      final mockDocRef = MockDocumentReference();
      when(
        () => mockFirestore.collection('rooms'),
      ).thenReturn(mockRoomsCollection);
      when(() => mockRoomsCollection.doc('test-room')).thenReturn(mockDocRef);
      when(
        () => mockDocRef.snapshots(),
      ).thenAnswer((_) => const Stream.empty());
      when(() => mockDocRef.update(any())).thenAnswer((_) async => {});

      final service = GameLoopService(firestore: mockFirestore);
      service.listenToRoom('test-room');

      await service.startGame();

      // Since there's no room loaded yet, this should handle gracefully
      verifyNever(() => mockDocRef.update(any()));
    });
  });
}
