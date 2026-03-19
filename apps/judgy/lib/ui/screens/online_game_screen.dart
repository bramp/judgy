import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:judgy/models/game_models.dart';
import 'package:judgy/services/auth_service.dart';
import 'package:judgy/services/deck_service.dart';
import 'package:judgy/services/online_game_engine.dart';
import 'package:provider/provider.dart';

/// Screen for online multiplayer games. Shows lobby when in lobby state,
/// game board once the game starts.
class OnlineGameScreen extends StatelessWidget {
  /// Creates an [OnlineGameScreen].
  const OnlineGameScreen({required this.roomId, super.key});

  /// The Firestore room ID to connect to.
  final String roomId;

  @override
  Widget build(BuildContext context) {
    final authService = context.read<AuthService>();
    final deckService = context.read<DeckService>();

    return ChangeNotifierProvider(
      create: (_) {
        final engine = OnlineGameEngine(
          localPlayerId: authService.currentUser!.uid,
          deckService: deckService,
        )..listenToRoom(roomId);
        return engine;
      },
      child: const _OnlineGameContent(),
    );
  }
}

class _OnlineGameContent extends StatelessWidget {
  const _OnlineGameContent();

  @override
  Widget build(BuildContext context) {
    final engine = context.watch<OnlineGameEngine>();
    final room = engine.currentRoom;

    if (room == null) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    if (room.status == GameStatus.lobby) {
      return _LobbyView(engine: engine, room: room);
    }

    return _GameView(engine: engine, room: room);
  }
}

class _LobbyView extends StatelessWidget {
  const _LobbyView({required this.engine, required this.room});

  final OnlineGameEngine engine;
  final GameRoom room;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Game Lobby'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () async {
            await engine.leaveRoom();
            if (context.mounted) {
              context.pop();
            }
          },
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Join Code Display
            Card(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  children: [
                    const Text(
                      'Join Code',
                      style: TextStyle(fontSize: 16),
                    ),
                    const SizedBox(height: 8),
                    SelectableText(
                      room.joinCode,
                      style: const TextStyle(
                        fontSize: 48,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 8,
                      ),
                    ),
                    const SizedBox(height: 8),
                    TextButton.icon(
                      onPressed: () {
                        unawaited(
                          Clipboard.setData(
                            ClipboardData(text: room.joinCode),
                          ),
                        );
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Code copied!')),
                        );
                      },
                      icon: const Icon(Icons.copy, size: 16),
                      label: const Text('Copy'),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 24),

            // Player List
            Text(
              'Players (${room.players.length})',
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Expanded(
              child: ListView.builder(
                itemCount: room.players.length,
                itemBuilder: (context, index) {
                  final player = room.players[index];
                  final isHost = player.id == room.hostId;
                  final isLocal = player.id == engine.localPlayerId;

                  return ListTile(
                    leading: CircleAvatar(
                      child: Text(player.displayName[0].toUpperCase()),
                    ),
                    title: Text(
                      '${player.displayName}${isLocal ? ' (You)' : ''}',
                    ),
                    trailing: isHost ? const Chip(label: Text('Host')) : null,
                  );
                },
              ),
            ),

            // Action Buttons
            if (engine.isHost) ...[
              if (room.players.length < 3)
                const Padding(
                  padding: EdgeInsets.only(bottom: 8),
                  child: Text(
                    'Need at least 3 players to start',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: Colors.orange),
                  ),
                ),
              FilledButton.icon(
                onPressed: room.players.length >= 3
                    ? () => unawaited(engine.startGame())
                    : null,
                icon: const Icon(Icons.play_arrow),
                label: const Text('Start Game'),
              ),
            ] else
              const Text(
                'Waiting for host to start...',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 18,
                  fontStyle: FontStyle.italic,
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _GameView extends StatelessWidget {
  const _GameView({required this.engine, required this.room});

  final OnlineGameEngine engine;
  final GameRoom room;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Round ${room.roundNumber}'),
        actions: [
          IconButton(
            icon: const Icon(Icons.exit_to_app),
            onPressed: () async {
              await engine.leaveRoom();
              if (context.mounted) {
                context.pop();
              }
            },
          ),
        ],
      ),
      body: Column(
        children: [
          // Scores Header
          Container(
            padding: const EdgeInsets.all(8),
            color: Colors.black12,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: room.players.map((p) {
                final isJudge = room.currentRound?.judgeId == p.id;
                return Column(
                  children: [
                    Text(
                      p.displayName,
                      style: TextStyle(
                        fontWeight: isJudge
                            ? FontWeight.bold
                            : FontWeight.normal,
                        color: isJudge ? Colors.amber : null,
                      ),
                    ),
                    Text('${p.score} pts'),
                  ],
                );
              }).toList(),
            ),
          ),

          // Board Area
          Expanded(
            child: _BoardArea(engine: engine, room: room),
          ),

          // Player Hand
          _PlayerHand(engine: engine, room: room),
        ],
      ),
    );
  }
}

class _BoardArea extends StatelessWidget {
  const _BoardArea({required this.engine, required this.room});

  final OnlineGameEngine engine;
  final GameRoom room;

  @override
  Widget build(BuildContext context) {
    final round = room.currentRound;
    if (round == null) return const SizedBox.shrink();

    final isJudging = room.status == GameStatus.judging;
    final isScoring = room.status == GameStatus.scoring;
    final amIJudge = round.judgeId == engine.localPlayerId;

    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Current Adjective
          if (round.currentAdjective != null)
            Card(
              color: Colors.green.shade800,
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Text(
                  round.currentAdjective!.text,
                  style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                    color: Colors.white,
                  ),
                ),
              ),
            ),

          const SizedBox(height: 24),

          if (room.status == GameStatus.playersPlaying)
            Text(
              amIJudge
                  ? 'Waiting for players to submit...'
                  : 'Waiting for everyone to play...',
              style: const TextStyle(fontSize: 18, fontStyle: FontStyle.italic),
            )
          else if (isJudging || isScoring) ...[
            Text(
              isScoring
                  ? 'Winner Selected!'
                  : (amIJudge
                        ? 'Select the winning card!'
                        : 'Judge is deciding...'),
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              alignment: WrapAlignment.center,
              children: round.playedCards.map((played) {
                final isWinner = round.winningPlayerId == played.playerId;

                return GestureDetector(
                  onTap: (amIJudge && isJudging)
                      ? () => unawaited(engine.selectWinner(played.playerId))
                      : null,
                  child: Card(
                    color: isWinner ? Colors.amber : Colors.white,
                    child: Container(
                      width: 120,
                      height: 160,
                      padding: const EdgeInsets.all(12),
                      child: Center(
                        child: Text(
                          played.card.text,
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            color: Colors.black87,
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
            if (isScoring && engine.isHost) ...[
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: () => unawaited(engine.nextRound()),
                child: const Text('Next Round'),
              ),
            ],
          ],
        ],
      ),
    );
  }
}

class _PlayerHand extends StatelessWidget {
  const _PlayerHand({required this.engine, required this.room});

  final OnlineGameEngine engine;
  final GameRoom room;

  @override
  Widget build(BuildContext context) {
    final localPlayer = room.players.cast<Player?>().firstWhere(
      (p) => p!.id == engine.localPlayerId,
      orElse: () => null,
    );
    if (localPlayer == null) return const SizedBox.shrink();

    final amIJudge = room.currentRound?.judgeId == localPlayer.id;
    final isPlaying = room.status == GameStatus.playersPlaying;
    final haveIPlayed =
        room.currentRound?.playedCards.any(
          (c) => c.playerId == localPlayer.id,
        ) ??
        false;

    return Container(
      height: 160,
      color: Colors.grey.shade900,
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(8),
            child: Text(
              amIJudge ? 'You are the Judge!' : 'Your Hand',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
          Expanded(
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 8),
              itemCount: localPlayer.hand.length,
              itemBuilder: (context, index) {
                final card = localPlayer.hand[index];
                final canPlay = isPlaying && !amIJudge && !haveIPlayed;

                return Padding(
                  padding: const EdgeInsets.only(right: 8, bottom: 8),
                  child: GestureDetector(
                    onTap: canPlay
                        ? () => unawaited(engine.playCard(card))
                        : null,
                    child: Opacity(
                      opacity: canPlay ? 1.0 : 0.5,
                      child: Card(
                        child: Container(
                          width: 100,
                          padding: const EdgeInsets.all(8),
                          child: Center(
                            child: Text(
                              card.text,
                              textAlign: TextAlign.center,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
