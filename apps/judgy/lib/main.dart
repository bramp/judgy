import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_native_splash/flutter_native_splash.dart';
import 'package:go_router/go_router.dart';
import 'package:judgy/firebase_options.dart';
import 'package:judgy/providers/theme_provider.dart';
import 'package:judgy/services/analytics_service.dart';
import 'package:judgy/services/consent_service.dart';
import 'package:judgy/services/deck_service.dart';
import 'package:judgy/services/preferences_service.dart';
import 'package:judgy/ui/screens/game_screen.dart';
import 'package:judgy/ui/screens/home_screen.dart';
import 'package:judgy/ui/screens/settings_screen.dart';
import 'package:judgy/ui/widgets/consent_banner.dart';
import 'package:provider/provider.dart';

void main() async {
  final widgetsBinding = WidgetsFlutterBinding.ensureInitialized();
  FlutterNativeSplash.preserve(widgetsBinding: widgetsBinding);

  // Lock to portrait mode
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);

  // Enable edge-to-edge mode (especially for modern Android)
  await SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);

  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
  } on Object catch (e) {
    debugPrint('Firebase initialization failed (not configured?): $e');
  }

  final preferencesService = await PreferencesService.init();
  final consentService = ConsentService(preferencesService);
  final deckService = DeckService(preferencesService);
  final analyticsService = AnalyticsService(consentService);
  await deckService.init();

  FlutterNativeSplash.remove();

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider<ConsentService>.value(value: consentService),
        ChangeNotifierProvider<DeckService>.value(value: deckService),
        Provider<AnalyticsService>.value(value: analyticsService),
        ChangeNotifierProvider(create: (_) => ThemeProvider()),
      ],
      child: const JudgyApp(),
    ),
  );
}

final _router = GoRouter(
  initialLocation: '/',
  observers: <NavigatorObserver>[
    FirebaseAnalyticsObserver(analytics: FirebaseAnalytics.instance),
  ],
  routes: [
    GoRoute(
      path: '/',
      builder: (context, state) => const HomeScreen(),
    ),
    GoRoute(
      path: '/game/local',
      builder: (context, state) => const GameScreen(),
    ),
    GoRoute(
      path: '/settings',
      builder: (context, state) => const Scaffold(
        body: Center(
          child: SettingsDialog(),
        ),
      ),
    ),
  ],
);

class JudgyApp extends StatelessWidget {
  const JudgyApp({super.key});

  @override
  Widget build(BuildContext context) {
    final themeProvider = context.watch<ThemeProvider>();
    return MaterialApp.router(
      routerConfig: _router,
      title: 'Judgy',
      theme: themeProvider.lightTheme,
      darkTheme: themeProvider.darkTheme,
      themeMode: themeProvider.themeMode,
      builder: (context, child) {
        final theme = Theme.of(context);
        final isDark = theme.brightness == Brightness.dark;

        SystemChrome.setSystemUIOverlayStyle(
          SystemUiOverlayStyle(
            systemNavigationBarColor: Colors.transparent,
            systemNavigationBarDividerColor: Colors.transparent,
            systemNavigationBarIconBrightness: isDark
                ? Brightness.light
                : Brightness.dark,
            statusBarColor: Colors.transparent,
            statusBarIconBrightness: isDark
                ? Brightness.light
                : Brightness.dark,
          ),
        );

        return Scaffold(
          backgroundColor: theme.scaffoldBackgroundColor,
          body: Stack(
            children: [
              if (child != null) SafeArea(child: child),
              const Positioned(
                bottom: 0,
                left: 0,
                right: 0,
                child: ConsentBanner(),
              ),
            ],
          ),
        );
      },
    );
  }
}
