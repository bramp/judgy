import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:firebase_app_check/firebase_app_check.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_native_splash/flutter_native_splash.dart';
import 'package:go_router/go_router.dart';
import 'package:judgy/firebase_options.dart';
import 'package:judgy/providers/theme_provider.dart';
import 'package:judgy/services/analytics_service.dart';
import 'package:judgy/services/auth_service.dart';
import 'package:judgy/services/consent_service.dart';
import 'package:judgy/services/deck_service.dart';
import 'package:judgy/services/preferences_service.dart';
import 'package:judgy/ui/screens/game_screen.dart';
import 'package:judgy/ui/screens/home_screen.dart';
import 'package:judgy/ui/screens/login_screen.dart';
import 'package:judgy/ui/screens/settings_screen.dart';
import 'package:judgy/ui/widgets/consent_banner.dart';
import 'package:provider/provider.dart';

/// Configures app-wide system UI behavior used at startup.
///
/// This locks the app to portrait orientations and enables edge-to-edge UI.
@visibleForTesting
Future<void> setupSystemChrome() async {
  // Lock to portrait mode
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);

  // Enable edge-to-edge mode (especially for modern Android)
  await SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
}

/// Initializes Firebase and App Check for the current platform.
///
/// If Firebase is not configured for the current environment, initialization
/// failures are logged and startup continues.
@visibleForTesting
Future<void> setupFirebase() async {
  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
    await FirebaseAppCheck.instance.activate(
      providerWeb: ReCaptchaV3Provider(
        // TODO(bramp): Change this to a Firebase Remote Config value.
        '6Leu_o0sAAAAAP5iWQ8b0h3YniO1FHEY5Y9uOq7O',
      ),
      // TODO(bramp): Add providers for Android and iOS when we set
      // up App Check for those platforms.
      //
      // providerAndroid: const AndroidPlayIntegrityProvider(),
      // providerApple: const AppleDeviceCheckProvider(),
    );
  } on Object catch (e) {
    debugPrint('Firebase initialization failed (not configured?): $e');
  }
}

/// Creates and initializes the app services required before [runApp].
///
/// Returns a service map consumed by `main` to wire providers.
@visibleForTesting
Future<Map<String, dynamic>> initializeServices() async {
  final preferencesService = await PreferencesService.init();
  final consentService = ConsentService(preferencesService);
  final deckService = DeckService(preferencesService);
  final analyticsService = AnalyticsService(consentService);
  final authService = AuthService();
  await deckService.init();

  return {
    'consentService': consentService,
    'deckService': deckService,
    'analyticsService': analyticsService,
    'authService': authService,
  };
}

void main() async {
  final widgetsBinding = WidgetsFlutterBinding.ensureInitialized();
  FlutterNativeSplash.preserve(widgetsBinding: widgetsBinding);

  await setupSystemChrome();
  await setupFirebase();

  final services = await initializeServices();
  final consentService = services['consentService'] as ConsentService;
  final deckService = services['deckService'] as DeckService;
  final analyticsService = services['analyticsService'] as AnalyticsService;
  final authService = services['authService'] as AuthService;

  FlutterNativeSplash.remove();

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider<ConsentService>.value(value: consentService),
        ChangeNotifierProvider<DeckService>.value(value: deckService),
        Provider<AnalyticsService>.value(value: analyticsService),
        ChangeNotifierProvider<AuthService>.value(value: authService),
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
      path: '/login',
      builder: (context, state) => const LoginScreen(),
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

/// Main app shell for Judgy.
class JudgyApp extends StatelessWidget {
  /// Root application widget that wires router, theming, and global overlays.
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
