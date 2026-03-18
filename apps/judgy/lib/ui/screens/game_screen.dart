import 'dart:async';

import 'package:flutter/material.dart';
import 'package:judgy/models/game_models.dart';
import 'package:judgy/services/analytics_service.dart';
import 'package:judgy/services/deck_service.dart';
import 'package:judgy/services/local_game_engine.dart';
import 'package:provider/provider.dart';

/// Screen widget for game flow.
class GameScreen extends StatelessWidget {
  /// Creates a [GameScreen].
  const GameScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) {
        final analyticsService = context.read<AnalyticsService>();
        final deckService = context.read<DeckService>();
        final engine = LocalGameEngine(analyticsService, deckService);
        unawaited(engine.initializeLocalGame());
        return engine;
      },
      child: const _GameScreenContent(),
    );
  }
}

class _GameScreenContent extends StatelessWidget {
  const _GameScreenContent();

  @override
  Widget build(BuildContext context) {
    final engine = context.watch<LocalGameEngine>();
    final room = engine.room;

    if (room == null) {
      return const Scaffold(body: Center(child: CircularProvider()));
    }

    return Scaffold(
      appBar: AppBar(
        title: Text('Round ${room.roundNumber}'),
        actions: [
          IconButton(
            icon: const Icon(Icons.exit_to_app),
            onPressed: () => Navigator.of(context).pop(),
          ),
        ],
      ),
      body: Column(
        children: [
          // ── Scores Header ──
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

          if (room.status == GameStatus.lobby)
            Expanded(
              child: Center(
                child: ElevatedButton(
                  onPressed: engine.startGame,
                  child: const Text('Start Game'),
                ),
              ),
            )
          else ...[
            // ── Board Area ──
            Expanded(
              child: _BoardArea(engine: engine, room: room),
            ),

            // ── Player Hand ──
            _PlayerHand(engine: engine, room: room),
          ],
        ],
      ),
    );
  }
}

class _BoardArea extends StatelessWidget {
  const _BoardArea({required this.engine, required this.room});

  final LocalGameEngine engine;
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
          // The current Adjective
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
              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
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
                      ? () => engine.selectWinner(played.playerId)
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
            if (isScoring) ...[
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: engine.nextRound,
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

  final LocalGameEngine engine;
  final GameRoom room;

  @override
  Widget build(BuildContext context) {
    final localPlayer = room.players.firstWhere(
      (p) => p.id == engine.localPlayerId,
    );
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
                        ? () => engine.playCard(localPlayer.id, card)
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

/// Provider for circular state.
class CircularProvider extends StatelessWidget {
  /// Creates a [CircularProvider].
  const CircularProvider({super.key});

  @override
  Widget build(BuildContext context) {
    return const CircularProgressIndicator();
  }
}
