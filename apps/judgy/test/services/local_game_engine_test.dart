import 'dart:convert';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:judgy/services/local_game_engine.dart';
import 'package:judgy/services/analytics_service.dart';
import 'package:judgy/services/deck_service.dart';
import 'package:judgy/services/ai_bot_service.dart';
import 'package:judgy/models/game_models.dart';
import 'package:mocktail/mocktail.dart';

class MockAnalyticsService extends Mock implements AnalyticsService {}

class MockDeckService extends Mock implements DeckService {}

class MockAiBotService extends Mock implements AIBotService {}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('LocalGameEngine', () {
    late MockAnalyticsService mockAnalyticsService;
    late MockDeckService mockDeckService;
    late MockAiBotService mockAiBotService;
    late LocalGameEngine engine;

    const mockBotsJson = '''
    [
      {"id": "bot1", "name": "Bot 1", "role": "Adventurer", "description": "Loves adventure"},
      {"id": "bot2", "name": "Bot 2", "role": "Scholar", "description": "Loves knowledge"},
      {"id": "bot3", "name": "Bot 3", "role": "Joker", "description": "Loves humor"}
    ]
    ''';

    setUpAll(() {
      registerFallbackValue(const Player(id: 'dummy', displayName: 'dummy'));
      registerFallbackValue(
        const CardModel(id: 'dummy', type: CardType.noun, text: 'dummy'),
      );
      registerFallbackValue(
        Future.value(
          const CardModel(id: 'dummy', type: CardType.noun, text: 'dummy'),
        ),
      );
    });

    setUp(() {
      mockAnalyticsService = MockAnalyticsService();
      mockDeckService = MockDeckService();
      mockAiBotService = MockAiBotService();

      when(() => mockDeckService.getActiveAdjectives()).thenReturn([
        const CardModel(id: 'adj1', type: CardType.adjective, text: 'Cool'),
        const CardModel(id: 'adj2', type: CardType.adjective, text: 'Hot'),
      ]);

      when(() => mockDeckService.getActiveNouns()).thenReturn([
        for (int i = 0; i < 30; i++)
          CardModel(id: 'noun_\$i', type: CardType.noun, text: 'Thing \$i'),
      ]);

      // Stub the AI service calls to prevent actual execution
      when(
        () => mockAiBotService.selectNounToPlay(
          botPlayer: any(named: 'botPlayer'),
          currentAdjective: any(named: 'currentAdjective'),
        ),
      ).thenAnswer((_) async => null);

      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMessageHandler('flutter/assets', (ByteData? message) async {
            final String key = utf8.decode(message!.buffer.asUint8List());
            if (key.contains('bots.json')) {
              return ByteData.view(
                Uint8List.fromList(utf8.encode(mockBotsJson)).buffer,
              );
            }
            return null;
          });

      engine = LocalGameEngine(
        mockAnalyticsService,
        mockDeckService,
        aiService: mockAiBotService,
      );
    });

    tearDown(() {
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMessageHandler('flutter/assets', null);
    });

    test('initializes correctly and creates room', () async {
      await engine.initializeLocalGame();

      expect(engine.room, isNotNull);
      expect(engine.room!.players.length, 4); // 1 local + 3 bots
      expect(engine.room!.players.first.id, 'player_local');
    });

    test('startGame deals cards and sets first round', () async {
      when(
        () => mockAnalyticsService.logEvent(
          name: any(named: 'name'),
          parameters: any(named: 'parameters'),
        ),
      ).thenReturn(null);

      await engine.initializeLocalGame();
      engine.startGame();

      final room = engine.room!;
      expect(room.status, GameStatus.playersPlaying);
      expect(room.roundNumber, 1);

      // Check hands
      for (final player in room.players) {
        expect(player.hand.length, 7);
      }

      // Check current round
      final round = room.currentRound!;
      expect(
        round.judgeId,
        room.players.first.id,
      ); // round number 1 -> index 0 (player_local)
      expect(round.currentAdjective, isNotNull);
    });

    test('playCard correctly records card and advances to judging', () async {
      when(
        () => mockAnalyticsService.logEvent(
          name: any(named: 'name'),
          parameters: any(named: 'parameters'),
        ),
      ).thenReturn(null);

      await engine.initializeLocalGame();
      engine.startGame();

      final room = engine.room!;
      final localPlayerId = engine.localPlayerId;
      // Local player is the judge in round 1, so let's check a bot playing

      final bot1 = room.players.firstWhere((p) => p.id == 'bot_1');
      final botCard = bot1.hand.first;

      engine.playCard(bot1.id, botCard);

      expect(engine.room!.currentRound!.playedCards.length, 1);

      // Play for bot 2 and 3 to trigger judging state
      final bot2 = room.players.firstWhere((p) => p.id == 'bot_2');
      engine.playCard(bot2.id, bot2.hand.first);

      final bot3 = room.players.firstWhere((p) => p.id == 'bot_3');
      engine.playCard(bot3.id, bot3.hand.first);

      expect(engine.room!.status, GameStatus.judging);
    });
  });
}
