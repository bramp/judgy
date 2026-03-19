import 'dart:async';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:judgy/services/auth_service.dart';
import 'package:judgy/services/matchmaking_service.dart';
import 'package:provider/provider.dart';

/// Screen for joining an existing online game by entering a join code.
class JoinGameScreen extends StatefulWidget {
  /// Creates a [JoinGameScreen].
  const JoinGameScreen({super.key});

  @override
  State<JoinGameScreen> createState() => _JoinGameScreenState();
}

class _JoinGameScreenState extends State<JoinGameScreen> {
  final _codeController = TextEditingController();
  bool _isJoining = false;
  String? _error;

  @override
  void dispose() {
    _codeController.dispose();
    super.dispose();
  }

  Future<void> _joinGame() async {
    final code = _codeController.text.trim().toUpperCase();
    if (code.isEmpty) {
      setState(() => _error = 'Please enter a join code');
      return;
    }

    setState(() {
      _isJoining = true;
      _error = null;
    });

    try {
      final authService = context.read<AuthService>();
      if (!authService.isAuthenticated) {
        await authService.signInAnonymously();
      }

      final user = authService.currentUser!;
      final matchmaking = MatchmakingService();
      final roomId = await matchmaking.joinRoomByCode(
        code,
        user.uid,
        user.displayName ?? user.email ?? 'Player',
      );

      if (!mounted) return;

      if (roomId == null) {
        setState(() {
          _isJoining = false;
          _error = 'Room not found or is no longer accepting players';
        });
        return;
      }

      context.go('/game/online/$roomId');
    } on Object {
      if (mounted) {
        setState(() {
          _isJoining = false;
          _error = 'Failed to join game. Please try again.';
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Join Game')),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text(
              'Enter the join code shared by your friend:',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 18),
            ),
            const SizedBox(height: 24),
            TextField(
              controller: _codeController,
              textAlign: TextAlign.center,
              textCapitalization: TextCapitalization.characters,
              style: const TextStyle(
                fontSize: 32,
                fontWeight: FontWeight.bold,
                letterSpacing: 8,
              ),
              maxLength: 6,
              decoration: InputDecoration(
                hintText: 'ABC123',
                counterText: '',
                errorText: _error,
                border: const OutlineInputBorder(),
              ),
              onSubmitted: (_) => unawaited(_joinGame()),
            ),
            const SizedBox(height: 24),
            FilledButton(
              onPressed: _isJoining ? null : () => unawaited(_joinGame()),
              child: _isJoining
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Text('Join Game'),
            ),
          ],
        ),
      ),
    );
  }
}
