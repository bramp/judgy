// lib/models/game_models.dart

import 'package:judgy/models/bot_personality.dart';

/// Represents a playing card (either an Adjective or a Noun).
// TODO(bramp): Drop the "Model" suffix from these class names,
// since it's redundant in Dart. Just "Card", "Player", etc.
class CardModel {
  /// Creates a [CardModel].
  const CardModel({
    required this.id,
    required this.text,
    required this.type,
    this.category,
    this.subcategory,
  });

  /// Creates a [CardModel] from a JSON map.
  factory CardModel.fromJson(Map<String, dynamic> json) {
    return CardModel(
      id: json['id'] as String,
      text: json['text'] as String,
      type: CardType.values.byName(json['type'] as String),
      category: json['category'] as String?,
      subcategory: json['subcategory'] as String?,
    );
  }

  /// Unique identifier.
  final String id;

  /// Display text for the card.
  final String text;

  /// Card type value.
  final CardType type;

  /// Optional top-level category name.
  final String? category;

  /// Optional subcategory name.
  final String? subcategory;

  /// Converts this [CardModel] to a JSON map.
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'text': text,
      'type': type.name,
      if (category != null) 'category': category,
      if (subcategory != null) 'subcategory': subcategory,
    };
  }
}

/// Enumerates cardtype values.
enum CardType {
  /// The adjective value.
  adjective,

  /// The noun value.
  noun,
}

/// Represents a player in the game. Can be a human or an AI bot.
class Player {
  /// Creates a [Player].
  const Player({
    required this.id,
    required this.displayName,
    this.isBot = false,
    this.botPersonality,
    this.score = 0,
    this.hand = const [],
  });

  /// Creates a [Player] from a JSON map.
  factory Player.fromJson(Map<String, dynamic> json) {
    return Player(
      id: json['id'] as String,
      displayName: json['displayName'] as String,
      isBot: json['isBot'] as bool? ?? false,
      botPersonality: json['botPersonality'] != null
          ? BotPersonality.fromJson(
              json['botPersonality'] as Map<String, dynamic>,
            )
          : null,
      score: json['score'] as int? ?? 0,
      hand:
          (json['hand'] as List<dynamic>?)
              ?.map((e) => CardModel.fromJson(e as Map<String, dynamic>))
              .toList() ??
          const [],
    );
  }

  /// Unique identifier.
  final String id;

  /// Player display name.
  final String displayName;

  /// Whether the player is controlled by a bot.
  final bool isBot;

  /// Optional bot personality configuration.
  final BotPersonality? botPersonality;

  /// Current score.
  final int score;

  /// Cards currently in hand.
  final List<CardModel> hand;

  /// Returns a copy of this [Player] with updated values.
  Player copyWith({
    String? id,
    String? displayName,
    bool? isBot,
    BotPersonality? botPersonality,
    int? score,
    List<CardModel>? hand,
  }) {
    return Player(
      id: id ?? this.id,
      displayName: displayName ?? this.displayName,
      isBot: isBot ?? this.isBot,
      botPersonality: botPersonality ?? this.botPersonality,
      score: score ?? this.score,
      hand: hand ?? this.hand,
    );
  }

  /// Converts this [Player] to a JSON map.
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'displayName': displayName,
      'isBot': isBot,
      'botPersonality': botPersonality?.toJson(),
      'score': score,
      'hand': hand.map((c) => c.toJson()).toList(),
    };
  }
}

/// Represents a single played card from a player.
class PlayedCard {
  /// Creates a [PlayedCard].
  const PlayedCard({
    required this.playerId,
    required this.card,
  });

  /// Creates a [PlayedCard] from a JSON map.
  factory PlayedCard.fromJson(Map<String, dynamic> json) {
    return PlayedCard(
      playerId: json['playerId'] as String,
      card: CardModel.fromJson(json['card'] as Map<String, dynamic>),
    );
  }

  /// Player identifier.
  final String playerId;

  /// Card played by the player.
  final CardModel card;

  /// Converts this [PlayedCard] to a JSON map.
  Map<String, dynamic> toJson() {
    return {
      'playerId': playerId,
      'card': card.toJson(),
    };
  }
}

/// Represents the current round of play.
class Round {
  /// Creates a [Round].
  const Round({
    required this.id,
    required this.judgeId,
    this.currentAdjective,
    this.playedCards = const [],
    this.winningPlayerId,
  });

  /// Creates a [Round] from a JSON map.
  factory Round.fromJson(Map<String, dynamic> json) {
    return Round(
      id: json['id'] as String,
      judgeId: json['judgeId'] as String,
      currentAdjective: json['currentAdjective'] != null
          ? CardModel.fromJson(json['currentAdjective'] as Map<String, dynamic>)
          : null,
      playedCards:
          (json['playedCards'] as List<dynamic>?)
              ?.map((e) => PlayedCard.fromJson(e as Map<String, dynamic>))
              .toList() ??
          const [],
      winningPlayerId: json['winningPlayerId'] as String?,
    );
  }

  /// Unique identifier.
  final String id;

  /// Player id for the round judge.
  final String judgeId;

  /// Active adjective card for the round.
  final CardModel? currentAdjective;

  /// Cards submitted for the round.
  final List<PlayedCard> playedCards;

  /// Winning player id for the round, if available.
  final String? winningPlayerId;

  /// Returns a copy of this [Round] with updated values.
  Round copyWith({
    String? id,
    String? judgeId,
    CardModel? currentAdjective,
    List<PlayedCard>? playedCards,
    String? winningPlayerId,
  }) {
    return Round(
      id: id ?? this.id,
      judgeId: judgeId ?? this.judgeId,
      currentAdjective: currentAdjective ?? this.currentAdjective,
      playedCards: playedCards ?? this.playedCards,
      winningPlayerId: winningPlayerId ?? this.winningPlayerId,
    );
  }

  /// Converts this [Round] to a JSON map.
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'judgeId': judgeId,
      'currentAdjective': currentAdjective?.toJson(),
      'playedCards': playedCards.map((p) => p.toJson()).toList(),
      'winningPlayerId': winningPlayerId,
    };
  }
}

/// Enumerates gamestatus values.
enum GameStatus {
  /// The lobby value.
  lobby,

  /// The dealing value.
  dealing,

  /// The playersPlaying value.
  playersPlaying,

  /// The judging value.
  judging,

  /// The scoring value.
  scoring,

  /// The finished value.
  finished,
}

/// Represents the top-level game room and state.
class GameRoom {
  /// Creates a [GameRoom].
  const GameRoom({
    required this.id,
    required this.joinCode,
    required this.hostId,
    required this.createdAt,
    this.players = const [],
    this.status = GameStatus.lobby,
    this.currentRound,
    this.roundNumber = 0,
  });

  /// Creates a [GameRoom] from a JSON map.
  factory GameRoom.fromJson(Map<String, dynamic> json) {
    return GameRoom(
      id: json['id'] as String,
      joinCode: json['joinCode'] as String,
      hostId: json['hostId'] as String,
      players:
          (json['players'] as List<dynamic>?)
              ?.map((e) => Player.fromJson(e as Map<String, dynamic>))
              .toList() ??
          const [],
      status: GameStatus.values.byName(json['status'] as String),
      currentRound: json['currentRound'] != null
          ? Round.fromJson(json['currentRound'] as Map<String, dynamic>)
          : null,
      roundNumber: json['roundNumber'] as int? ?? 0,
      createdAt: DateTime.fromMillisecondsSinceEpoch(json['createdAt'] as int),
    );
  }

  /// Unique identifier.
  final String id;

  /// Room join code.
  final String joinCode;

  /// Host player id.
  final String hostId;

  /// Players currently in the room.
  final List<Player> players;

  /// Current game state status.
  final GameStatus status;

  /// Current round data, if available.
  final Round? currentRound;

  /// Current round number.
  final int roundNumber;

  /// Room creation timestamp.
  final DateTime createdAt;

  /// Returns a copy of this [GameRoom] with updated values.
  GameRoom copyWith({
    String? id,
    String? joinCode,
    String? hostId,
    List<Player>? players,
    GameStatus? status,
    Round? currentRound,
    int? roundNumber,
    DateTime? createdAt,
  }) {
    return GameRoom(
      id: id ?? this.id,
      joinCode: joinCode ?? this.joinCode,
      hostId: hostId ?? this.hostId,
      players: players ?? this.players,
      status: status ?? this.status,
      currentRound: currentRound ?? this.currentRound,
      roundNumber: roundNumber ?? this.roundNumber,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  /// Converts this [GameRoom] to a JSON map.
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'joinCode': joinCode,
      'hostId': hostId,
      'players': players.map((p) => p.toJson()).toList(),
      'status': status.name,
      'currentRound': currentRound?.toJson(),
      'roundNumber': roundNumber,
      'createdAt': createdAt.millisecondsSinceEpoch,
    };
  }
}
