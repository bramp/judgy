import 'dart:math';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:judgy/models/game_models.dart';
import 'package:uuid/uuid.dart';

/// Service for matchmaking operations: creating and joining game rooms.
class MatchmakingService {
  /// Creates a [MatchmakingService].
  MatchmakingService({
    FirebaseFirestore? firestore,
    Uuid? uuid,
    Random? random,
  }) : _firestore = firestore ?? FirebaseFirestore.instance,
       _uuid = uuid ?? const Uuid(),
       _random = random ?? Random.secure();

  final FirebaseFirestore _firestore;
  final Uuid _uuid;
  final Random _random;

  /// Maximum number of players allowed per room.
  static const maxPlayers = 8;

  /// Characters used for join codes (excludes confusing chars: 0/O, 1/I/L).
  static const _codeChars = 'ABCDEFGHJKMNPQRSTUVWXYZ23456789';

  String _generateJoinCode() {
    return String.fromCharCodes(
      List.generate(
        6,
        (_) => _codeChars.codeUnitAt(_random.nextInt(_codeChars.length)),
      ),
    );
  }

  /// Create a new private game room and return its ID.
  Future<String> createPrivateRoom(
    String hostId,
    String hostDisplayName,
  ) async {
    final roomId = _uuid.v4();
    final joinCode = _generateJoinCode();

    final hostPlayer = Player(
      id: hostId,
      displayName: hostDisplayName,
    );

    final room = GameRoom(
      id: roomId,
      joinCode: joinCode,
      hostId: hostId,
      players: [hostPlayer],
      createdAt: DateTime.now(),
    );

    await _firestore.collection('rooms').doc(roomId).set(room.toJson());
    return roomId;
  }

  /// Join an existing game room by its 6-character code.
  ///
  /// Returns the room ID on success, or `null` if the room was not found,
  /// is full, or the game has already started.
  Future<String?> joinRoomByCode(
    String code,
    String userId,
    String displayName,
  ) async {
    final query = await _firestore
        .collection('rooms')
        .where('joinCode', isEqualTo: code.toUpperCase())
        .limit(1)
        .get();

    if (query.docs.isEmpty) return null;

    final doc = query.docs.first;
    final roomId = doc.id;
    final roomData = GameRoom.fromJson(doc.data());

    // Room must be in lobby state.
    if (roomData.status != GameStatus.lobby) return null;

    // Room must not be full.
    if (roomData.players.length >= maxPlayers) return null;

    // If already in room, just return the roomId.
    if (roomData.players.any((p) => p.id == userId)) return roomId;

    final newPlayer = Player(
      id: userId,
      displayName: displayName,
    );

    final updatedPlayers = List<Player>.from(roomData.players)..add(newPlayer);
    final updatedRoom = roomData.copyWith(players: updatedPlayers);

    await _firestore
        .collection('rooms')
        .doc(roomId)
        .update(updatedRoom.toJson());
    return roomId;
  }
}
