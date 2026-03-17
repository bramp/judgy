import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:judgy/models/game_models.dart';

class GameLoopService extends ChangeNotifier {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  GameRoom? _currentRoom;
  GameRoom? get currentRoom => _currentRoom;

  String? _roomId;

  /// Listen to a game room's updates.
  void listenToRoom(String roomId) {
    _roomId = roomId;
    _firestore.collection('rooms').doc(roomId).snapshots().listen((snapshot) {
      if (snapshot.exists && snapshot.data() != null) {
        _currentRoom = GameRoom.fromJson(snapshot.data()!);
        notifyListeners();
      }
    });
  }

  /// Start the game and deal initial cards.
  Future<void> startGame() async {
    if (_roomId == null || _currentRoom == null) return;

    final updatedRoom = _currentRoom!.copyWith(
      status: GameStatus.dealing,
      roundNumber: 1,
    );

    await _firestore
        .collection('rooms')
        .doc(_roomId)
        .update(updatedRoom.toJson());
    // TODO: Trigger actual card dealing logic here (perhaps via Cloud Function or client authority)
  }

  /// Transition state to Judging.
  Future<void> beginJudging() async {
    if (_roomId == null || _currentRoom == null) return;

    final updatedRoom = _currentRoom!.copyWith(
      status: GameStatus.judging,
    );
    await _firestore
        .collection('rooms')
        .doc(_roomId)
        .update(updatedRoom.toJson());
  }

  /// Advance to the next round.
  Future<void> nextRound() async {
    if (_roomId == null || _currentRoom == null) return;

    final updatedRoom = _currentRoom!.copyWith(
      status: GameStatus.dealing,
      roundNumber: _currentRoom!.roundNumber + 1,
    );
    await _firestore
        .collection('rooms')
        .doc(_roomId)
        .update(updatedRoom.toJson());
  }
}
