import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:judgy/services/matchmaking_service.dart';
import 'package:judgy/models/game_models.dart';
import 'package:mocktail/mocktail.dart';
import 'package:uuid/uuid.dart';

class MockFirebaseFirestore extends Mock implements FirebaseFirestore {}

class MockCollectionReference extends Mock
    implements CollectionReference<Map<String, dynamic>> {}

class MockDocumentReference extends Mock
    implements DocumentReference<Map<String, dynamic>> {}

class MockQuery extends Mock implements Query<Map<String, dynamic>> {}

class MockQuerySnapshot extends Mock
    implements QuerySnapshot<Map<String, dynamic>> {}

class MockQueryDocumentSnapshot extends Mock
    implements QueryDocumentSnapshot<Map<String, dynamic>> {}

class MockUuid extends Mock implements Uuid {}

void main() {
  group('MatchmakingService', () {
    late MockFirebaseFirestore mockFirestore;
    late MockCollectionReference mockRoomsCollection;
    late MockUuid mockUuid;
    late MatchmakingService service;

    setUp(() {
      mockFirestore = MockFirebaseFirestore();
      mockRoomsCollection = MockCollectionReference();
      mockUuid = MockUuid();

      when(
        () => mockFirestore.collection('rooms'),
      ).thenReturn(mockRoomsCollection);

      service = MatchmakingService(
        firestore: mockFirestore,
        uuid: mockUuid,
      );
    });

    test('createPrivateRoom works correctly', () async {
      final mockDocRef = MockDocumentReference();
      when(() => mockUuid.v4()).thenReturn('fake-uuid-1234');
      when(
        () => mockRoomsCollection.doc('fake-uuid-1234'),
      ).thenReturn(mockDocRef);
      when(() => mockDocRef.set(any())).thenAnswer((_) async => {});

      final roomId = await service.createPrivateRoom('user1', 'Player 1');

      expect(roomId, 'fake-uuid-1234');

      final captured = verify(() => mockDocRef.set(captureAny())).captured;
      final savedData = captured.first as Map<String, dynamic>;

      expect(savedData['id'], 'fake-uuid-1234');
      expect(
        savedData['joinCode'],
        'FAKE',
      ); // First 4 chars of uppercase 'fake-uuid-1234'
      expect(savedData['hostId'], 'user1');
      expect(savedData['players'][0]['id'], 'user1');
      expect(savedData['players'][0]['displayName'], 'Player 1');
    });

    test('joinRoomByCode works correctly', () async {
      final mockQuery1 = MockQuery();
      final mockQuery2 = MockQuery();
      final mockSnapshot = MockQuerySnapshot();
      final mockDocSnapshot = MockQueryDocumentSnapshot();
      final mockDocRef = MockDocumentReference();

      // Original room state
      final originalRoom = GameRoom(
        id: 'room-id',
        joinCode: 'CODE',
        hostId: 'host1',
        createdAt: DateTime.now(),
        players: [Player(id: 'host1', displayName: 'Host Player')],
      );

      when(
        () => mockRoomsCollection.where('joinCode', isEqualTo: 'CODE'),
      ).thenReturn(mockQuery1);
      when(() => mockQuery1.limit(1)).thenReturn(mockQuery2);
      when(() => mockQuery2.get()).thenAnswer((_) async => mockSnapshot);
      when(() => mockSnapshot.docs).thenReturn([mockDocSnapshot]);
      when(() => mockDocSnapshot.id).thenReturn('room-id');
      when(() => mockDocSnapshot.data()).thenReturn(originalRoom.toJson());

      when(() => mockRoomsCollection.doc('room-id')).thenReturn(mockDocRef);
      when(() => mockDocRef.update(any())).thenAnswer((_) async => {});

      final result = await service.joinRoomByCode('CODE', 'user2', 'Player 2');

      expect(result, 'room-id');
      final captured = verify(() => mockDocRef.update(captureAny())).captured;
      final updatedData = captured.first as Map<String, dynamic>;

      expect(updatedData['players'].length, 2);
      expect(updatedData['players'][1]['id'], 'user2');
      expect(updatedData['players'][1]['displayName'], 'Player 2');
    });

    test('joinRoomByCode returns null if room not found', () async {
      final mockQuery1 = MockQuery();
      final mockQuery2 = MockQuery();
      final mockSnapshot = MockQuerySnapshot();

      when(
        () => mockRoomsCollection.where('joinCode', isEqualTo: 'WRONG'),
      ).thenReturn(mockQuery1);
      when(() => mockQuery1.limit(1)).thenReturn(mockQuery2);
      when(() => mockQuery2.get()).thenAnswer((_) async => mockSnapshot);
      when(() => mockSnapshot.docs).thenReturn([]); // Empty docs

      final result = await service.joinRoomByCode('wrong', 'user2', 'Player 2');

      expect(result, isNull);
    });
  });
}
