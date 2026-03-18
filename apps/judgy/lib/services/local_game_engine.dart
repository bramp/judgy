import 'dart:async';
import 'dart:convert';
import 'dart:math';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:judgy/models/bot_personality.dart';
import 'package:judgy/models/game_models.dart';
import 'package:judgy/services/ai_bot_service.dart';
import 'package:judgy/services/analytics_service.dart';
import 'package:judgy/services/deck_service.dart';
import 'package:uuid/uuid.dart';

class LocalGameEngine extends ChangeNotifier {
  LocalGameEngine(
    this._analyticsService,
    this._deckService, {
    AIBotService? aiService,
  }) : _aiService = aiService ?? AIBotService(),
       _rnd = Random(),
       _uuid = const Uuid();

  final AnalyticsService _analyticsService;
  final DeckService _deckService;
  final AIBotService _aiService;

  GameRoom? _room;
  GameRoom? get room => _room;

  String get localPlayerId => 'player_local';

  final Random _rnd;
  final Uuid _uuid;

  List<CardModel> _allAdjectives = [];
  List<CardModel> _allNouns = [];
  List<CardModel> _unusedAdjectives = [];
  List<CardModel> _unusedNouns = [];

  Future<void> initializeLocalGame() async {
    _allAdjectives = _deckService.getActiveAdjectives();
    _allNouns = _deckService.getActiveNouns();

    _unusedAdjectives = List.from(_allAdjectives)..shuffle(_rnd);
    _unusedNouns = List.from(_allNouns)..shuffle(_rnd);

    final jsonString = await rootBundle.loadString(
      'assets/data/bots.json',
    );
    final jsonList = jsonDecode(jsonString) as List<dynamic>;

    final allPersonas = jsonList
        .map((e) => BotPersonality.fromJson(e as Map<String, dynamic>))
        .toList();

    final randomPersonas = List<BotPersonality>.from(allPersonas)
      ..shuffle(_rnd);

    final players = [
      const Player(id: 'player_local', displayName: 'You'),
      Player(
        id: 'bot_1',
        displayName: randomPersonas[0].name,
        isBot: true,
        botPersonality: randomPersonas[0],
      ),
      Player(
        id: 'bot_2',
        displayName: randomPersonas[1].name,
        isBot: true,
        botPersonality: randomPersonas[1],
      ),
      Player(
        id: 'bot_3',
        displayName: randomPersonas[2].name,
        isBot: true,
        botPersonality: randomPersonas[2],
      ),
    ];

    _room = GameRoom(
      id: 'local_room',
      joinCode: 'LOCAL',
      hostId: localPlayerId,
      players: players,
      createdAt: DateTime.now(),
    );
    notifyListeners();
  }

  void startGame() {
    if (_room == null) return;

    _analyticsService.logEvent(
      name: 'game_started',
      parameters: {'player_count': _room!.players.length},
    );

    _dealCardsToAll();
    _startNewRound();
  }

  void _dealCardsToAll() {
    final updatedPlayers = _room!.players.map((p) {
      final updatedHand = List<CardModel>.from(p.hand);
      while (updatedHand.length < 7) {
        if (_unusedNouns.isEmpty) {
          _unusedNouns = List.from(_allNouns)..shuffle(_rnd);
        }
        updatedHand.add(_unusedNouns.removeLast());
      }
      return p.copyWith(hand: updatedHand);
    }).toList();

    _room = _room!.copyWith(players: updatedPlayers);
  }

  void _startNewRound() {
    if (_unusedAdjectives.isEmpty) {
      _unusedAdjectives = List.from(_allAdjectives)..shuffle(_rnd);
    }

    final newRoundNumber = _room!.roundNumber + 1;

    // Choose Judge (round robin based on round number)
    final judgeIndex = (newRoundNumber - 1) % _room!.players.length;
    final judge = _room!.players[judgeIndex];

    final adjective = _unusedAdjectives.removeLast();

    _analyticsService.logEvent(
      name: 'round_played',
      parameters: {
        'round_number': newRoundNumber,
        'adjective_id': adjective.id,
        'adjective_text': adjective.text,
      },
    );

    final round = Round(
      id: _uuid.v4(),
      judgeId: judge.id,
      currentAdjective: adjective,
      playedCards: [],
    );

    _room = _room!.copyWith(
      roundNumber: newRoundNumber,
      currentRound: round,
      status: GameStatus.playersPlaying,
    );
    notifyListeners();

    unawaited(_processBotTurns());
  }

  void playCard(String playerId, CardModel card) {
    if (_room?.status != GameStatus.playersPlaying) return;
    final round = _room!.currentRound;
    if (round == null) return;

    // Make sure player isn't judge and hasn't played yet
    if (playerId == round.judgeId) return;
    if (round.playedCards.any((p) => p.playerId == playerId)) return;

    // Remove card from hand
    final newPlayers = _room!.players.map((p) {
      if (p.id == playerId) {
        return p.copyWith(
          hand: p.hand.where((c) => c.id != card.id).toList(),
        );
      }
      return p;
    }).toList();

    final played = PlayedCard(playerId: playerId, card: card);
    final newPlayedCards = List<PlayedCard>.from(round.playedCards)
      ..add(played);

    var newStatus = GameStatus.playersPlaying;

    // Check if everyone has played
    final totalPlayers = _room!.players.length;
    if (newPlayedCards.length == totalPlayers - 1) {
      newStatus = GameStatus.judging;
      newPlayedCards.shuffle(_rnd); // Hide playing order
    }

    _room = _room!.copyWith(
      players: newPlayers,
      currentRound: round.copyWith(playedCards: newPlayedCards),
      status: newStatus,
    );
    notifyListeners();

    if (newStatus == GameStatus.judging) {
      unawaited(_processBotJudge());
    }
  }

  Future<void> _processBotTurns() async {
    final round = _room?.currentRound;
    if (round == null) return;

    for (final player in _room!.players) {
      if (player.isBot && player.id != round.judgeId) {
        if (player.hand.isNotEmpty && round.currentAdjective != null) {
          final selectedCard = await _aiService.selectNounToPlay(
            botPlayer: player,
            currentAdjective: round.currentAdjective!,
          );

          final currentRoomState = _room;
          if (currentRoomState?.status == GameStatus.playersPlaying &&
              selectedCard != null) {
            playCard(player.id, selectedCard);
          }
        }
      }
    }
  }

  Future<void> _processBotJudge() async {
    final round = _room?.currentRound;
    if (round == null) return;

    final judge = _room!.players.firstWhere((p) => p.id == round.judgeId);
    if (!judge.isBot) return;

    final currentRound = _room!.currentRound;
    if (currentRound != null &&
        currentRound.playedCards.isNotEmpty &&
        currentRound.currentAdjective != null) {
      final winningCard = await _aiService.judgeWinningCard(
        judgePlayer: judge,
        currentAdjective: currentRound.currentAdjective!,
        submissions: currentRound.playedCards,
      );

      if (winningCard != null) {
        selectWinner(winningCard.playerId);
      }
    }
  }

  void selectWinner(String winningPlayerId) {
    if (_room?.status != GameStatus.judging) return;
    final round = _room!.currentRound;
    if (round == null) return;

    final updatedPlayers = _room!.players.map((p) {
      if (p.id == winningPlayerId) {
        return p.copyWith(score: p.score + 1);
      }
      return p;
    }).toList();

    _room = _room!.copyWith(
      players: updatedPlayers,
      currentRound: round.copyWith(winningPlayerId: winningPlayerId),
      status: GameStatus.scoring,
    );
    notifyListeners();
  }

  void nextRound() {
    if (_room?.status != GameStatus.scoring) return;
    _dealCardsToAll();
    _startNewRound();
  }
}
