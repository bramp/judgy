import 'dart:async';
import 'dart:math';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:judgy/models/game_models.dart';
import 'package:judgy/services/deck_service.dart';
import 'package:uuid/uuid.dart';

/// Manages online multiplayer game state synchronized via Firestore.
///
/// The host client is authoritative for dealing cards and advancing rounds.
/// All clients receive real-time updates via Firestore snapshot listeners.
class OnlineGameEngine extends ChangeNotifier {
  /// Creates an [OnlineGameEngine].
  OnlineGameEngine({
    required this.localPlayerId,
    required DeckService deckService,
    FirebaseFirestore? firestore,
    Uuid? uuid,
    Random? random,
  }) : _deckService = deckService,
       _firestore = firestore ?? FirebaseFirestore.instance,
       _uuid = uuid ?? const Uuid(),
       _rnd = random ?? Random();

  /// Number of cards dealt to each player's hand.
  static const int cardsPerHand = 7;

  /// The local player's ID (Firebase UID).
  final String localPlayerId;

  final DeckService _deckService;
  final FirebaseFirestore _firestore;
  final Uuid _uuid;
  final Random _rnd;

  GameRoom? _currentRoom;
  String? _roomId;
  StreamSubscription<DocumentSnapshot<Map<String, dynamic>>>? _subscription;

  // Host-only shuffled deck state.
  List<CardModel> _unusedAdjectives = [];
  List<CardModel> _unusedNouns = [];
  bool _deckInitialized = false;

  /// The current room state, updated in real-time from Firestore.
  GameRoom? get currentRoom => _currentRoom;

  /// Whether the local player is the room host.
  bool get isHost => _currentRoom?.hostId == localPlayerId;

  DocumentReference<Map<String, dynamic>> get _roomDoc =>
      _firestore.collection('rooms').doc(_roomId);

  /// Subscribe to real-time updates for the given room.
  void listenToRoom(String roomId) {
    _roomId = roomId;
    _subscription = _roomDoc.snapshots().listen((snapshot) {
      if (snapshot.exists && snapshot.data() != null) {
        _currentRoom = GameRoom.fromJson(snapshot.data()!);
        notifyListeners();
      }
    });
  }

  void _initDeck() {
    if (_deckInitialized) return;
    _unusedAdjectives = List.from(_deckService.getActiveAdjectives())
      ..shuffle(_rnd);
    _unusedNouns = List.from(_deckService.getActiveNouns())..shuffle(_rnd);
    _deckInitialized = true;
  }

  CardModel _drawAdjective() {
    if (_unusedAdjectives.isEmpty) {
      _unusedAdjectives = List.from(_deckService.getActiveAdjectives())
        ..shuffle(_rnd);
    }
    return _unusedAdjectives.removeLast();
  }

  CardModel _drawNoun() {
    if (_unusedNouns.isEmpty) {
      _unusedNouns = List.from(_deckService.getActiveNouns())..shuffle(_rnd);
    }
    return _unusedNouns.removeLast();
  }

  /// Start the game. Host only. Requires at least 3 players.
  Future<void> startGame() async {
    if (_roomId == null || _currentRoom == null) return;
    if (!isHost) return;
    if (_currentRoom!.status != GameStatus.lobby) return;
    if (_currentRoom!.players.length < 3) return;

    _initDeck();

    // Deal cards to all players.
    final updatedPlayers = _currentRoom!.players.map((p) {
      final hand = List.generate(cardsPerHand, (_) => _drawNoun());
      return p.copyWith(hand: hand);
    }).toList();

    final judge = updatedPlayers.first;
    final adjective = _drawAdjective();

    final round = Round(
      id: _uuid.v4(),
      judgeId: judge.id,
      currentAdjective: adjective,
    );

    final updatedRoom = _currentRoom!.copyWith(
      players: updatedPlayers,
      status: GameStatus.playersPlaying,
      currentRound: round,
      roundNumber: 1,
    );

    await _roomDoc.update(updatedRoom.toJson());
  }

  /// Play a card from the local player's hand.
  Future<void> playCard(CardModel card) async {
    if (_roomId == null || _currentRoom == null) return;
    if (_currentRoom!.status != GameStatus.playersPlaying) return;

    final round = _currentRoom!.currentRound;
    if (round == null) return;
    if (round.judgeId == localPlayerId) return;
    if (round.playedCards.any((p) => p.playerId == localPlayerId)) return;

    // Remove card from hand.
    final updatedPlayers = _currentRoom!.players.map((p) {
      if (p.id == localPlayerId) {
        return p.copyWith(
          hand: p.hand.where((c) => c.id != card.id).toList(),
        );
      }
      return p;
    }).toList();

    final played = PlayedCard(playerId: localPlayerId, card: card);
    final newPlayedCards = List<PlayedCard>.from(round.playedCards)
      ..add(played);

    var newStatus = GameStatus.playersPlaying;
    if (newPlayedCards.length == _currentRoom!.players.length - 1) {
      newStatus = GameStatus.judging;
      newPlayedCards.shuffle(_rnd);
    }

    final updatedRoom = _currentRoom!.copyWith(
      players: updatedPlayers,
      currentRound: round.copyWith(playedCards: newPlayedCards),
      status: newStatus,
    );

    await _roomDoc.update(updatedRoom.toJson());
  }

  /// Select the winning player. Judge only.
  Future<void> selectWinner(String winningPlayerId) async {
    if (_roomId == null || _currentRoom == null) return;
    if (_currentRoom!.status != GameStatus.judging) return;

    final round = _currentRoom!.currentRound;
    if (round == null) return;
    if (round.judgeId != localPlayerId) return;

    final updatedPlayers = _currentRoom!.players.map((p) {
      if (p.id == winningPlayerId) {
        return p.copyWith(score: p.score + 1);
      }
      return p;
    }).toList();

    final updatedRoom = _currentRoom!.copyWith(
      players: updatedPlayers,
      currentRound: round.copyWith(winningPlayerId: winningPlayerId),
      status: GameStatus.scoring,
    );

    await _roomDoc.update(updatedRoom.toJson());
  }

  /// Advance to the next round. Host only.
  Future<void> nextRound() async {
    if (_roomId == null || _currentRoom == null) return;
    if (!isHost) return;
    if (_currentRoom!.status != GameStatus.scoring) return;

    _initDeck();

    final newRoundNumber = _currentRoom!.roundNumber + 1;
    final judgeIndex = (newRoundNumber - 1) % _currentRoom!.players.length;
    final judge = _currentRoom!.players[judgeIndex];

    // Replenish hands.
    final updatedPlayers = _currentRoom!.players.map((p) {
      final hand = List<CardModel>.from(p.hand);
      while (hand.length < cardsPerHand) {
        hand.add(_drawNoun());
      }
      return p.copyWith(hand: hand);
    }).toList();

    final adjective = _drawAdjective();

    final round = Round(
      id: _uuid.v4(),
      judgeId: judge.id,
      currentAdjective: adjective,
    );

    final updatedRoom = _currentRoom!.copyWith(
      players: updatedPlayers,
      status: GameStatus.playersPlaying,
      currentRound: round,
      roundNumber: newRoundNumber,
    );

    await _roomDoc.update(updatedRoom.toJson());
  }

  /// Remove the local player from the room.
  Future<void> leaveRoom() async {
    if (_roomId == null || _currentRoom == null) return;

    final updatedPlayers = _currentRoom!.players
        .where((p) => p.id != localPlayerId)
        .toList();

    if (updatedPlayers.isEmpty) {
      // Last player leaving — delete room.
      await _roomDoc.delete();
    } else {
      final updatedRoom = _currentRoom!.copyWith(
        players: updatedPlayers,
        // Transfer host if the host is leaving.
        hostId: _currentRoom!.hostId == localPlayerId
            ? updatedPlayers.first.id
            : _currentRoom!.hostId,
      );
      await _roomDoc.update(updatedRoom.toJson());
    }

    await _subscription?.cancel();
    _subscription = null;
    _currentRoom = null;
    _roomId = null;
    notifyListeners();
  }

  @override
  void dispose() {
    unawaited(_subscription?.cancel());
    super.dispose();
  }
}
