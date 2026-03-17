import 'dart:async';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:judgy/services/auth_service.dart';
import 'package:provider/provider.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final authService = context.watch<AuthService>();
    final isAuthenticated = authService.isAuthenticated;

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
                'Signed in as: ${authService.currentUser?.email ?? authService.currentUser?.uid ?? 'Unknown'}',
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
            ElevatedButton(
              onPressed: () {
                // TODO(bramp): Navigate to lobby/create game
              },
              child: const Text('Create Game'),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: () {
                // TODO(bramp): Navigate to join game
              },
              child: const Text('Join Game'),
            ),
          ],
        ),
      ),
    );
  }
}
