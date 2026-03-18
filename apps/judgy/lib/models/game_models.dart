// lib/models/game_models.dart

import 'package:judgy/models/bot_personality.dart';

/// Represents a playing card (either an Adjective or a Noun).
// TODO(bramp): Drop the "Model" suffix from these class names, since it's redundant in Dart. Just "Card", "Player", etc.
class CardModel {
  const CardModel({
    required this.id,
    required this.text,
    required this.type,
    this.category,
    this.subcategory,
  });

  factory CardModel.fromJson(Map<String, dynamic> json) {
    return CardModel(
      id: json['id'] as String,
      text: json['text'] as String,
      type: CardType.values.byName(json['type'] as String),
      category: json['category'] as String?,
      subcategory: json['subcategory'] as String?,
    );
  }
  final String id;
  final String text;
  final CardType type;
  final String? category;
  final String? subcategory;

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

enum CardType {
  adjective,
  noun,
}

/// Represents a player in the game. Can be a human or an AI bot.
class Player {
  const Player({
    required this.id,
    required this.displayName,
    this.isBot = false,
    this.botPersonality,
    this.score = 0,
    this.hand = const [],
  });

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
  final String id;
  final String displayName;
  final bool isBot;
  final BotPersonality? botPersonality;
  final int score;
  final List<CardModel> hand;

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
  const PlayedCard({
    required this.playerId,
    required this.card,
  });

  factory PlayedCard.fromJson(Map<String, dynamic> json) {
    return PlayedCard(
      playerId: json['playerId'] as String,
      card: CardModel.fromJson(json['card'] as Map<String, dynamic>),
    );
  }
  final String playerId;
  final CardModel card;

  Map<String, dynamic> toJson() {
    return {
      'playerId': playerId,
      'card': card.toJson(),
    };
  }
}

/// Represents the current round of play.
class Round {
  const Round({
    required this.id,
    required this.judgeId,
    this.currentAdjective,
    this.playedCards = const [],
    this.winningPlayerId,
  });

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
  final String id;
  final String judgeId;
  final CardModel? currentAdjective;
  final List<PlayedCard> playedCards;
  final String? winningPlayerId;

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

enum GameStatus {
  lobby,
  dealing,
  playersPlaying,
  judging,
  scoring,
  finished,
}

/// Represents the top-level game room and state.
class GameRoom {
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
  final String id;
  final String joinCode;
  final String hostId;
  final List<Player> players;
  final GameStatus status;
  final Round? currentRound;
  final int roundNumber;
  final DateTime createdAt;

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
