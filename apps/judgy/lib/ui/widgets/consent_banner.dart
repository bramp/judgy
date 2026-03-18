import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:judgy/services/consent_service.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';

/// A GDPR-style consent banner displayed at the bottom of the screen.
///
/// Shown only on first launch (when [ConsentService.needsConsent] is true).
/// The user can accept or decline analytics; game-save storage is always on
/// because it is strictly necessary for the app to function.
class ConsentBanner extends StatefulWidget {
  /// Creates a [ConsentBanner].
  const ConsentBanner({super.key});

  @override
  State<ConsentBanner> createState() => _ConsentBannerState();
}

class _ConsentBannerState extends State<ConsentBanner> {
  bool _analyticsEnabled = true;

  @override
  Widget build(BuildContext context) {
    final consentService = context.watch<ConsentService>();
    if (!consentService.needsConsent) return const SizedBox.shrink();

    final theme = Theme.of(context);
    final linkStyle = theme.textTheme.bodySmall?.copyWith(
      color: theme.colorScheme.primary,
      decoration: TextDecoration.underline,
    );

    return Material(
      elevation: 8,
      child: SafeArea(
        top: false,
        child: Container(
          width: double.infinity,
          color: theme.colorScheme.surfaceContainerHighest,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 720),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Text(
                      '🍪',
                      style: TextStyle(fontSize: 24),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'We value your privacy',
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                const _ConsentRow(
                  title: 'Game Saves',
                  description:
                      'We remember where you left off so you '
                      'don\u2019t have to start from scratch. '
                      'This stays on your device — always on, '
                      'because puzzles should be fun, not frustrating.',
                  value: true,
                  enabled: false,
                ),
                const SizedBox(height: 8),
                _ConsentRow(
                  title: 'Analytics',
                  description: SelectableText.rich(
                    TextSpan(
                      style: theme.textTheme.bodySmall,
                      children: [
                        const TextSpan(
                          text:
                              'Help us figure out which puzzles are '
                              'delightfully tricky and which are just '
                              'plain mean. We use ',
                        ),
                        TextSpan(
                          text: 'Firebase Analytics',
                          style: linkStyle,
                          recognizer: TapGestureRecognizer()
                            ..onTap = () => launchUrl(
                              Uri.parse(
                                'https://firebase.google.com/docs/analytics',
                              ),
                            ),
                        ),
                        const TextSpan(
                          text:
                              ' to collect anonymous stats — no names, '
                              'no emails, no secrets.',
                        ),
                      ],
                    ),
                  ),
                  value: _analyticsEnabled,
                  onChanged: (value) =>
                      setState(() => _analyticsEnabled = value),
                ),
                const SizedBox(height: 12),
                Align(
                  alignment: Alignment.centerRight,
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      TextButton(
                        onPressed: () {},
                        child: const Text('Privacy Policy'),
                      ),
                      const SizedBox(width: 8),
                      FilledButton(
                        onPressed: () => consentService.setAnalyticsConsent(
                          allowed: _analyticsEnabled,
                        ),
                        child: const Text('Accept'),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _ConsentRow extends StatelessWidget {
  const _ConsentRow({
    required this.title,
    required this.value,
    this.description,
    this.enabled = true,
    this.onChanged,
  });

  final String title;

  /// Either a [String] or a pre-built [Widget] (e.g. [SelectableText.rich]).
  final Object? description;
  final bool value;
  final bool enabled;
  final ValueChanged<bool>? onChanged;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: theme.textTheme.bodyMedium),
              if (description is String)
                Text(
                  description! as String,
                  style: theme.textTheme.bodySmall,
                )
              else if (description is Widget)
                description! as Widget,
            ],
          ),
        ),
        const SizedBox(width: 12),
        Switch(
          value: value,
          onChanged: enabled ? onChanged : null,
        ),
      ],
    );
  }
}
