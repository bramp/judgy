import 'dart:async';

import 'package:flutter/material.dart';
import 'package:judgy/build_info.dart';
import 'package:judgy/services/consent_service.dart';
import 'package:judgy/ui/screens/deck_settings_screen.dart';
import 'package:provider/provider.dart';

/// Shows the settings dialog as an overlay on top of the current screen.
Future<void> showSettingsDialog(BuildContext context) {
  return showDialog<void>(
    context: context,
    builder: (_) => const SettingsDialog(),
  );
}

/// A dialog containing app info and privacy settings.
class SettingsDialog extends StatelessWidget {
  const SettingsDialog({super.key});

  @override
  Widget build(BuildContext context) {
    final consentService = context.watch<ConsentService>();
    final theme = Theme.of(context);

    return Dialog(
      clipBehavior: Clip.antiAlias,
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 480),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            AppBar(
              title: const Text('Settings'),
              automaticallyImplyLeading: false,
              actions: [
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () => Navigator.of(context).pop(),
                ),
              ],
            ),
            Flexible(
              child: ListView(
                shrinkWrap: true,
                children: [
                  // ── About ──────────────────────────────
                  _SectionHeader(title: 'About', theme: theme),
                  const ListTile(
                    leading: Icon(Icons.style),
                    title: Text('Judgy'),
                    subtitle: Text(
                      'An Apples-to-Apples inspired party game.',
                    ),
                  ),
                  ListTile(
                    leading: const Icon(Icons.tag),
                    title: const Text('Version'),
                    subtitle: Text(BuildInfo.shortVersion),
                  ),

                  const Divider(),

                  // ── Deck Categories ────────────────────
                  _SectionHeader(title: 'Deck Categories', theme: theme),
                  ListTile(
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16),
                    trailing: const Icon(Icons.settings),
                    title: const Text('Manage card categories'),
                    subtitle: const Text(
                      'Customize which categories are active',
                    ),
                    onTap: () {
                      Navigator.of(context).pop();
                      unawaited(
                        Navigator.of(context).push(
                          MaterialPageRoute<void>(
                            builder: (_) => const DeckSettingsScreen(),
                          ),
                        ),
                      );
                    },
                  ),

                  const Divider(),

                  // ── Privacy ────────────────────────────
                  _SectionHeader(title: 'Privacy', theme: theme),
                  SwitchListTile(
                    secondary: const Icon(Icons.analytics_outlined),
                    title: const Text('Analytics'),
                    subtitle: const Text(
                      'Help improve the game by sharing '
                      'anonymous usage stats.',
                    ),
                    value: consentService.analyticsAllowed,
                    onChanged: (value) =>
                        consentService.setAnalyticsConsent(allowed: value),
                  ),
                  const ListTile(
                    leading: Icon(Icons.privacy_tip_outlined),
                    title: Text('Privacy Policy'),
                    trailing: Icon(Icons.open_in_new, size: 18),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({required this.title, required this.theme});

  final String title;
  final ThemeData theme;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 4),
      child: Text(
        title,
        style: theme.textTheme.titleSmall?.copyWith(
          color: theme.colorScheme.primary,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}
