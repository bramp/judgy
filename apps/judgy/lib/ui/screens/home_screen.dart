import 'dart:async';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:judgy/services/auth_service.dart';
import 'package:judgy/services/matchmaking_service.dart';
import 'package:provider/provider.dart';

/// Screen widget for home flow.
class HomeScreen extends StatelessWidget {
  /// Creates a [HomeScreen].
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final authService = context.watch<AuthService>();
    final isAuthenticated = authService.isAuthenticated;

    final user =
        authService.currentUser?.email ??
        authService.currentUser?.uid ??
        'Unknown';

    return Scaffold(
      appBar: AppBar(
        title: const Text('Judgy'),
        actions: [
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: () {
              unawaited(context.push('/settings'));
            },
          ),
        ],
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text(
              'Welcome to Judgy!',
              style: TextStyle(fontSize: 32, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 40),
            if (!isAuthenticated)
              ElevatedButton(
                onPressed: () {
                  unawaited(context.push('/login'));
                },
                child: const Text('Login'),
              )
            else ...[
              Text(
                'Signed in as: $user',
              ),
              TextButton(
                onPressed: authService.signOut,
                child: const Text('Sign out'),
              ),
            ],
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: () {
                unawaited(context.push('/game/local'));
              },
              child: const Text('Play Local Game'),
            ),
            const SizedBox(height: 20),
            ElevatedButton.icon(
              onPressed: () {
                unawaited(context.push('/settings'));
              },
              icon: const Icon(Icons.settings),
              label: const Text('Settings'),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: () async {
                final authService = context.read<AuthService>();
                if (!authService.isAuthenticated) {
                  await authService.signInAnonymously();
                }

                final user = authService.currentUser;
                if (user == null) return;

                final matchmaking = MatchmakingService();
                final roomId = await matchmaking.createPrivateRoom(
                  user.uid,
                  user.displayName ?? user.email ?? 'Player',
                );

                if (context.mounted) {
                  unawaited(context.push('/game/online/$roomId'));
                }
              },
              child: const Text('Create Game'),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: () {
                unawaited(context.push('/join'));
              },
              child: const Text('Join Game'),
            ),
          ],
        ),
      ),
    );
  }
}
