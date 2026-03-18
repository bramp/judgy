import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:judgy/models/game_models.dart';
import 'package:uuid/uuid.dart';

class MatchmakingService {
  MatchmakingService({FirebaseFirestore? firestore, Uuid? uuid})
    : _firestore = firestore ?? FirebaseFirestore.instance,
      _uuid = uuid ?? const Uuid();

  final FirebaseFirestore _firestore;
  final Uuid _uuid;

  /// Create a new private game room and return its ID.
  Future<String> createPrivateRoom(
    String hostId,
    String hostDisplayName,
  ) async {
    final roomId = _uuid.v4();
    // A simple 4-character join code.
    // TODOLet's make this 8 characters - and I don't want to use a uuid - since the first 4 chars of a uuid are not very random - we can just generate a random 8 char code instead.
    final joinCode = _uuid.v4().substring(0, 4).toUpperCase();

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

  /// Join an existing game room by its 4-character code.
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

    if (query.docs.isEmpty) {
      return null; // Room not found
    }

    final doc = query.docs.first;
    final roomId = doc.id;
    final roomData = GameRoom.fromJson(doc.data());

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
