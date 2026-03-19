import 'dart:async';
import 'dart:math';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:judgy/models/game_models.dart';
import 'package:judgy/services/deck_service.dart';
import 'package:judgy/services/online_game_engine.dart';
import 'package:mocktail/mocktail.dart';
import 'package:uuid/uuid.dart';

class MockFirebaseFirestore extends Mock implements FirebaseFirestore {}

class MockCollectionReference extends Mock
    implements CollectionReference<Map<String, dynamic>> {}

class MockDocumentReference extends Mock
    implements DocumentReference<Map<String, dynamic>> {}

class MockDocumentSnapshot extends Mock
    implements DocumentSnapshot<Map<String, dynamic>> {}

class MockDeckService extends Mock implements DeckService {}

class MockUuid extends Mock implements Uuid {}

void main() {
  // Test data: enough noun cards for dealing.
  final testNouns = List.generate(
    30,
    (i) => CardModel(id: 'n$i', text: 'Noun $i', type: CardType.noun),
  );
  final testAdjectives = List.generate(
    10,
    (i) => CardModel(
      id: 'adj$i',
      text: 'Adjective $i',
      type: CardType.adjective,
    ),
  );

  late MockFirebaseFirestore mockFirestore;
  late MockCollectionReference mockRoomsCollection;
  late MockDocumentReference mockDocRef;
  late MockDeckService mockDeckService;
  late MockUuid mockUuid;
  late StreamController<DocumentSnapshot<Map<String, dynamic>>>
  snapshotController;

  GameRoom makeRoom({
    String id = 'test-room',
    String joinCode = 'ABC123',
    String hostId = 'player1',
    List<Player>? players,
    GameStatus status = GameStatus.lobby,
    Round? currentRound,
    int roundNumber = 0,
  }) {
    return GameRoom(
      id: id,
      joinCode: joinCode,
      hostId: hostId,
      players:
          players ??
          const [
            Player(id: 'player1', displayName: 'Player 1'),
            Player(id: 'player2', displayName: 'Player 2'),
            Player(id: 'player3', displayName: 'Player 3'),
          ],
      status: status,
      currentRound: currentRound,
      roundNumber: roundNumber,
      createdAt: DateTime(2024),
    );
  }

  MockDocumentSnapshot makeSnapshot(GameRoom room) {
    final snapshot = MockDocumentSnapshot();
    when(() => snapshot.exists).thenReturn(true);
    when(() => snapshot.data()).thenReturn(room.toJson());
    return snapshot;
  }

  void emitRoom(GameRoom room) {
    snapshotController.add(makeSnapshot(room));
  }

  OnlineGameEngine createEngine({
    String localPlayerId = 'player1',
  }) {
    return OnlineGameEngine(
      localPlayerId: localPlayerId,
      deckService: mockDeckService,
      firestore: mockFirestore,
      uuid: mockUuid,
      random: Random(42), // Fixed seed for determinism.
    );
  }

  setUp(() {
    mockFirestore = MockFirebaseFirestore();
    mockRoomsCollection = MockCollectionReference();
    mockDocRef = MockDocumentReference();
    mockDeckService = MockDeckService();
    mockUuid = MockUuid();
    snapshotController =
        StreamController<DocumentSnapshot<Map<String, dynamic>>>();

    when(
      () => mockFirestore.collection('rooms'),
    ).thenReturn(mockRoomsCollection);
    when(() => mockRoomsCollection.doc('test-room')).thenReturn(mockDocRef);
    when(
      () => mockDocRef.snapshots(),
    ).thenAnswer((_) => snapshotController.stream);
    when(() => mockDocRef.update(any())).thenAnswer((_) async {});
    when(() => mockDocRef.delete()).thenAnswer((_) async {});
    when(() => mockUuid.v4()).thenReturn('mock-uuid');

    when(() => mockDeckService.getActiveNouns()).thenReturn(testNouns);
    when(
      () => mockDeckService.getActiveAdjectives(),
    ).thenReturn(testAdjectives);
  });

  tearDown(() {
    snapshotController.close();
  });

  group('OnlineGameEngine', () {
    test('currentRoom is null initially', () {
      final engine = createEngine();
      expect(engine.currentRoom, isNull);
      expect(engine.isHost, isFalse);
    });

    test('listenToRoom subscribes and updates currentRoom', () async {
      final engine = createEngine();
      engine.listenToRoom('test-room');
      expect(engine.currentRoom, isNull);

      final room = makeRoom();
      emitRoom(room);
      await Future<void>.delayed(Duration.zero);

      expect(engine.currentRoom, isNotNull);
      expect(engine.currentRoom!.id, 'test-room');
      expect(engine.currentRoom!.players.length, 3);
    });

    test('isHost returns true for host player', () async {
      final engine = createEngine(localPlayerId: 'player1');
      engine.listenToRoom('test-room');
      emitRoom(makeRoom(hostId: 'player1'));
      await Future<void>.delayed(Duration.zero);

      expect(engine.isHost, isTrue);
    });

    test('isHost returns false for non-host player', () async {
      final engine = createEngine(localPlayerId: 'player2');
      engine.listenToRoom('test-room');
      emitRoom(makeRoom(hostId: 'player1'));
      await Future<void>.delayed(Duration.zero);

      expect(engine.isHost, isFalse);
    });

    group('startGame', () {
      test('deals cards and starts round when valid', () async {
        final engine = createEngine(localPlayerId: 'player1');
        engine.listenToRoom('test-room');
        emitRoom(makeRoom(hostId: 'player1'));
        await Future<void>.delayed(Duration.zero);

        await engine.startGame();

        final captured = verify(() => mockDocRef.update(captureAny())).captured;
        expect(captured, hasLength(1));

        final data = captured.first as Map<String, dynamic>;
        expect(data['status'], 'playersPlaying');
        expect(data['roundNumber'], 1);
        expect(data['currentRound'], isNotNull);

        // Each player should have 7 cards.
        final players = data['players'] as List<dynamic>;
        for (final p in players) {
          final hand = (p as Map<String, dynamic>)['hand'] as List<dynamic>;
          expect(hand.length, OnlineGameEngine.cardsPerHand);
        }
      });

      test('does nothing if not host', () async {
        final engine = createEngine(localPlayerId: 'player2');
        engine.listenToRoom('test-room');
        emitRoom(makeRoom(hostId: 'player1'));
        await Future<void>.delayed(Duration.zero);

        await engine.startGame();

        verifyNever(() => mockDocRef.update(any()));
      });

      test('does nothing if not in lobby state', () async {
        final engine = createEngine(localPlayerId: 'player1');
        engine.listenToRoom('test-room');
        emitRoom(
          makeRoom(
            hostId: 'player1',
            status: GameStatus.playersPlaying,
          ),
        );
        await Future<void>.delayed(Duration.zero);

        await engine.startGame();

        verifyNever(() => mockDocRef.update(any()));
      });

      test('does nothing with fewer than 3 players', () async {
        final engine = createEngine(localPlayerId: 'player1');
        engine.listenToRoom('test-room');
        emitRoom(
          makeRoom(
            hostId: 'player1',
            players: const [
              Player(id: 'player1', displayName: 'Player 1'),
              Player(id: 'player2', displayName: 'Player 2'),
            ],
          ),
        );
        await Future<void>.delayed(Duration.zero);

        await engine.startGame();

        verifyNever(() => mockDocRef.update(any()));
      });
    });

    group('playCard', () {
      final testCard = CardModel(id: 'n0', text: 'Noun 0', type: CardType.noun);

      GameRoom makePlayingRoom({String localPlayerId = 'player2'}) {
        return makeRoom(
          hostId: 'player1',
          status: GameStatus.playersPlaying,
          roundNumber: 1,
          currentRound: const Round(
            id: 'round1',
            judgeId: 'player1',
            currentAdjective: CardModel(
              id: 'adj0',
              text: 'Adjective 0',
              type: CardType.adjective,
            ),
          ),
          players: [
            const Player(id: 'player1', displayName: 'Player 1', hand: []),
            Player(
              id: 'player2',
              displayName: 'Player 2',
              hand: [testCard],
            ),
            Player(
              id: 'player3',
              displayName: 'Player 3',
              hand: [
                const CardModel(
                  id: 'n1',
                  text: 'Noun 1',
                  type: CardType.noun,
                ),
              ],
            ),
          ],
        );
      }

      test('plays a card and updates room', () async {
        final engine = createEngine(localPlayerId: 'player2');
        engine.listenToRoom('test-room');
        emitRoom(makePlayingRoom());
        await Future<void>.delayed(Duration.zero);

        await engine.playCard(testCard);

        final captured = verify(() => mockDocRef.update(captureAny())).captured;
        expect(captured, hasLength(1));

        final data = captured.first as Map<String, dynamic>;
        final round = data['currentRound'] as Map<String, dynamic>;
        final playedCards = round['playedCards'] as List<dynamic>;
        expect(playedCards.length, 1);

        final playedCard = playedCards.first as Map<String, dynamic>;
        expect(playedCard['playerId'], 'player2');

        // Card should be removed from player's hand.
        final players = data['players'] as List<dynamic>;
        final player2 = players[1] as Map<String, dynamic>;
        final hand = player2['hand'] as List<dynamic>;
        expect(hand, isEmpty);
      });

      test(
        'transitions to judging when all non-judge players have played',
        () async {
          final engine = createEngine(localPlayerId: 'player3');
          engine.listenToRoom('test-room');

          // Player 2 already played.
          final room = makeRoom(
            hostId: 'player1',
            status: GameStatus.playersPlaying,
            roundNumber: 1,
            currentRound: Round(
              id: 'round1',
              judgeId: 'player1',
              currentAdjective: const CardModel(
                id: 'adj0',
                text: 'Adjective 0',
                type: CardType.adjective,
              ),
              playedCards: [
                PlayedCard(
                  playerId: 'player2',
                  card: testCard,
                ),
              ],
            ),
            players: [
              const Player(id: 'player1', displayName: 'Player 1', hand: []),
              const Player(id: 'player2', displayName: 'Player 2', hand: []),
              Player(
                id: 'player3',
                displayName: 'Player 3',
                hand: [
                  const CardModel(
                    id: 'n1',
                    text: 'Noun 1',
                    type: CardType.noun,
                  ),
                ],
              ),
            ],
          );
          emitRoom(room);
          await Future<void>.delayed(Duration.zero);

          await engine.playCard(
            const CardModel(id: 'n1', text: 'Noun 1', type: CardType.noun),
          );

          final captured = verify(
            () => mockDocRef.update(captureAny()),
          ).captured;
          final data = captured.first as Map<String, dynamic>;
          expect(data['status'], 'judging');
        },
      );

      test('judge cannot play', () async {
        final engine = createEngine(localPlayerId: 'player1');
        engine.listenToRoom('test-room');
        emitRoom(makePlayingRoom(localPlayerId: 'player1'));
        await Future<void>.delayed(Duration.zero);

        await engine.playCard(testCard);

        verifyNever(() => mockDocRef.update(any()));
      });

      test('cannot play when not in playersPlaying state', () async {
        final engine = createEngine(localPlayerId: 'player2');
        engine.listenToRoom('test-room');
        emitRoom(makeRoom(status: GameStatus.judging));
        await Future<void>.delayed(Duration.zero);

        await engine.playCard(testCard);

        verifyNever(() => mockDocRef.update(any()));
      });
    });

    group('selectWinner', () {
      GameRoom makeJudgingRoom() {
        return makeRoom(
          hostId: 'player1',
          status: GameStatus.judging,
          roundNumber: 1,
          currentRound: Round(
            id: 'round1',
            judgeId: 'player1',
            currentAdjective: const CardModel(
              id: 'adj0',
              text: 'Adjective 0',
              type: CardType.adjective,
            ),
            playedCards: [
              const PlayedCard(
                playerId: 'player2',
                card: CardModel(
                  id: 'n0',
                  text: 'Noun 0',
                  type: CardType.noun,
                ),
              ),
              const PlayedCard(
                playerId: 'player3',
                card: CardModel(
                  id: 'n1',
                  text: 'Noun 1',
                  type: CardType.noun,
                ),
              ),
            ],
          ),
        );
      }

      test('selects winner and transitions to scoring', () async {
        final engine = createEngine(localPlayerId: 'player1');
        engine.listenToRoom('test-room');
        emitRoom(makeJudgingRoom());
        await Future<void>.delayed(Duration.zero);

        await engine.selectWinner('player2');

        final captured = verify(() => mockDocRef.update(captureAny())).captured;
        final data = captured.first as Map<String, dynamic>;

        expect(data['status'], 'scoring');

        // Player 2 should have score incremented.
        final players = data['players'] as List<dynamic>;
        final player2 = players[1] as Map<String, dynamic>;
        expect(player2['score'], 1);

        // Winner should be set on round.
        final round = data['currentRound'] as Map<String, dynamic>;
        expect(round['winningPlayerId'], 'player2');
      });

      test('non-judge cannot select winner', () async {
        final engine = createEngine(localPlayerId: 'player2');
        engine.listenToRoom('test-room');
        emitRoom(makeJudgingRoom());
        await Future<void>.delayed(Duration.zero);

        await engine.selectWinner('player3');

        verifyNever(() => mockDocRef.update(any()));
      });

      test('cannot select winner when not judging', () async {
        final engine = createEngine(localPlayerId: 'player1');
        engine.listenToRoom('test-room');
        emitRoom(makeRoom(status: GameStatus.playersPlaying));
        await Future<void>.delayed(Duration.zero);

        await engine.selectWinner('player2');

        verifyNever(() => mockDocRef.update(any()));
      });
    });

    group('nextRound', () {
      GameRoom makeScoringRoom() {
        return makeRoom(
          hostId: 'player1',
          status: GameStatus.scoring,
          roundNumber: 1,
          currentRound: Round(
            id: 'round1',
            judgeId: 'player1',
            currentAdjective: const CardModel(
              id: 'adj0',
              text: 'Adjective 0',
              type: CardType.adjective,
            ),
            playedCards: const [
              PlayedCard(
                playerId: 'player2',
                card: CardModel(
                  id: 'n0',
                  text: 'Noun 0',
                  type: CardType.noun,
                ),
              ),
            ],
            winningPlayerId: 'player2',
          ),
          players: [
            Player(
              id: 'player1',
              displayName: 'Player 1',
              hand: List.generate(
                6,
                (i) => CardModel(
                  id: 'h1_$i',
                  text: 'H1 $i',
                  type: CardType.noun,
                ),
              ),
            ),
            Player(
              id: 'player2',
              displayName: 'Player 2',
              score: 1,
              hand: List.generate(
                6,
                (i) => CardModel(
                  id: 'h2_$i',
                  text: 'H2 $i',
                  type: CardType.noun,
                ),
              ),
            ),
            Player(
              id: 'player3',
              displayName: 'Player 3',
              hand: List.generate(
                6,
                (i) => CardModel(
                  id: 'h3_$i',
                  text: 'H3 $i',
                  type: CardType.noun,
                ),
              ),
            ),
          ],
        );
      }

      test('advances to next round with replenished hands', () async {
        final engine = createEngine(localPlayerId: 'player1');
        engine.listenToRoom('test-room');
        emitRoom(makeScoringRoom());
        await Future<void>.delayed(Duration.zero);

        await engine.nextRound();

        final captured = verify(() => mockDocRef.update(captureAny())).captured;
        final data = captured.first as Map<String, dynamic>;

        expect(data['status'], 'playersPlaying');
        expect(data['roundNumber'], 2);

        // Hands should be replenished to 7 cards.
        final players = data['players'] as List<dynamic>;
        for (final p in players) {
          final hand = (p as Map<String, dynamic>)['hand'] as List<dynamic>;
          expect(hand.length, OnlineGameEngine.cardsPerHand);
        }

        // Judge should rotate (round 2 → index 1 → player2).
        final round = data['currentRound'] as Map<String, dynamic>;
        expect(round['judgeId'], 'player2');
      });

      test('non-host cannot advance round', () async {
        final engine = createEngine(localPlayerId: 'player2');
        engine.listenToRoom('test-room');
        emitRoom(makeScoringRoom());
        await Future<void>.delayed(Duration.zero);

        await engine.nextRound();

        verifyNever(() => mockDocRef.update(any()));
      });

      test('cannot advance when not in scoring state', () async {
        final engine = createEngine(localPlayerId: 'player1');
        engine.listenToRoom('test-room');
        emitRoom(
          makeRoom(
            hostId: 'player1',
            status: GameStatus.judging,
          ),
        );
        await Future<void>.delayed(Duration.zero);

        await engine.nextRound();

        verifyNever(() => mockDocRef.update(any()));
      });
    });

    group('leaveRoom', () {
      test('removes player and updates room', () async {
        final engine = createEngine(localPlayerId: 'player2');
        engine.listenToRoom('test-room');
        emitRoom(makeRoom());
        await Future<void>.delayed(Duration.zero);

        await engine.leaveRoom();

        final captured = verify(() => mockDocRef.update(captureAny())).captured;
        final data = captured.first as Map<String, dynamic>;
        final players = data['players'] as List<dynamic>;
        expect(players.length, 2);
        expect(
          players.every(
            (p) => (p as Map<String, dynamic>)['id'] != 'player2',
          ),
          isTrue,
        );

        // Room state should be cleared.
        expect(engine.currentRoom, isNull);
      });

      test('transfers host when host leaves', () async {
        final engine = createEngine(localPlayerId: 'player1');
        engine.listenToRoom('test-room');
        emitRoom(makeRoom(hostId: 'player1'));
        await Future<void>.delayed(Duration.zero);

        await engine.leaveRoom();

        final captured = verify(() => mockDocRef.update(captureAny())).captured;
        final data = captured.first as Map<String, dynamic>;
        expect(data['hostId'], 'player2');
      });

      test('deletes room when last player leaves', () async {
        final engine = createEngine(localPlayerId: 'player1');
        engine.listenToRoom('test-room');
        emitRoom(
          makeRoom(
            hostId: 'player1',
            players: const [
              Player(id: 'player1', displayName: 'Player 1'),
            ],
          ),
        );
        await Future<void>.delayed(Duration.zero);

        await engine.leaveRoom();

        verify(() => mockDocRef.delete()).called(1);
        verifyNever(() => mockDocRef.update(any()));
      });
    });
  });
}
