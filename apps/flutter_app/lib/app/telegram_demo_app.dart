import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../features/login/login_handoff_screen.dart';
import '../features/placeholder/authenticated_placeholder_screen.dart';
import '../features/startup/startup_gate_screen.dart';
import '../shared/assets/shared_asset_repository.dart';
import '../shared/assets/shared_models.dart';
import 'app_bootstrap_controller.dart';

class TelegramDemoApp extends StatefulWidget {
  const TelegramDemoApp({super.key, required this.repository});

  final SharedAssetRepository repository;

  @override
  State<TelegramDemoApp> createState() => _TelegramDemoAppState();
}

class _TelegramDemoAppState extends State<TelegramDemoApp> {
  static const String startupPath = '/';
  static const String loginPath = '/login';
  static const String authenticatedPlaceholderPath =
      '/authenticated-placeholder';

  late final AppBootstrapController _controller;
  late final GoRouter _router;

  @override
  void initState() {
    super.initState();
    _controller = AppBootstrapController(repository: widget.repository);
    _router = GoRouter(
      initialLocation: startupPath,
      refreshListenable: _controller,
      redirect: _redirect,
      routes: <RouteBase>[
        GoRoute(
          path: startupPath,
          builder: (BuildContext context, GoRouterState state) {
            return AnimatedBuilder(
              animation: _controller,
              builder: (BuildContext context, Widget? child) {
                return StartupGateScreen(
                  phase: _controller.phase,
                  bootstrapCopy: _controller.bootstrapCopy,
                  failureMessage: _controller.failureMessage,
                  onRetry: _controller.load,
                );
              },
            );
          },
        ),
        GoRoute(
          path: loginPath,
          builder: (BuildContext context, GoRouterState state) {
            return AnimatedBuilder(
              animation: _controller,
              builder: (BuildContext context, Widget? child) {
                return LoginHandoffScreen(
                  loginCopy: _controller.startupConfig?.loginCopy,
                  appMarkAssetPath: _controller.startupConfig?.appMarkAssetPath,
                  errorMessage: _controller.loginErrorMessage,
                  isSubmitting: _controller.isSubmittingLogin,
                  onSubmitPhoneNumber: _controller.submitDemoLogin,
                  onInputChanged: _controller.clearLoginError,
                );
              },
            );
          },
        ),
        GoRoute(
          path: authenticatedPlaceholderPath,
          builder: (BuildContext context, GoRouterState state) {
            return AuthenticatedPlaceholderScreen(
              placeholderNotice:
                  _controller.startupConfig?.placeholderNotice ??
                  PlaceholderCopy.fallback().placeholderNotice,
            );
          },
        ),
      ],
    );
  }

  String? _redirect(BuildContext context, GoRouterState state) {
    final String location = state.matchedLocation;
    switch (_controller.phase) {
      case BootstrapPhase.loading:
      case BootstrapPhase.failure:
        if (location == startupPath) {
          return null;
        }
        return startupPath;
      case BootstrapPhase.noSession:
        if (_controller.isAuthenticated) {
          if (location == authenticatedPlaceholderPath) {
            return null;
          }
          return authenticatedPlaceholderPath;
        }
        if (location == loginPath) {
          return null;
        }
        return loginPath;
    }
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (BuildContext context, Widget? child) {
        final DesignTokens tokens =
            _controller.startupConfig?.tokens ?? DesignTokens.fallback();

        return MaterialApp.router(
          title: 'Telegram Demo',
          debugShowCheckedModeBanner: false,
          theme: buildTelegramTheme(tokens),
          routerConfig: _router,
        );
      },
    );
  }

  @override
  void dispose() {
    _router.dispose();
    _controller.dispose();
    super.dispose();
  }
}

ThemeData buildTelegramTheme(DesignTokens tokens) {
  final ColorScheme colorScheme = ColorScheme.fromSeed(
    seedColor: tokens.brand,
    brightness: Brightness.light,
    surface: tokens.screen,
  );
  final ThemeData baseTheme = ThemeData(
    useMaterial3: true,
    colorScheme: colorScheme,
    scaffoldBackgroundColor: tokens.appBackground,
  );

  return baseTheme.copyWith(
    scaffoldBackgroundColor: tokens.appBackground,
    cardTheme: CardThemeData(
      margin: EdgeInsets.zero,
      elevation: tokens.cardElevation,
      color: tokens.screen,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(tokens.cardRadius),
        side: BorderSide(color: tokens.borderSubtle),
      ),
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: tokens.brand,
        foregroundColor: tokens.textInverse,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(tokens.fieldRadius),
        ),
        padding: EdgeInsets.symmetric(
          horizontal: tokens.spacingExtraLarge,
          vertical: tokens.spacingLarge,
        ),
      ),
    ),
    textTheme: baseTheme.textTheme.copyWith(
      headlineLarge: baseTheme.textTheme.headlineLarge?.copyWith(
        fontSize: tokens.headlineSize,
        height: tokens.headlineLineHeight / tokens.headlineSize,
        fontWeight: FontWeight.w700,
        color: tokens.textPrimary,
      ),
      headlineSmall: baseTheme.textTheme.headlineSmall?.copyWith(
        fontSize: tokens.titleSize,
        height: tokens.titleLineHeight / tokens.titleSize,
        fontWeight: FontWeight.w600,
        color: tokens.textPrimary,
      ),
      bodyLarge: baseTheme.textTheme.bodyLarge?.copyWith(
        fontSize: tokens.bodyStrongSize,
        height: tokens.bodyStrongLineHeight / tokens.bodyStrongSize,
        fontWeight: FontWeight.w500,
        color: tokens.textPrimary,
      ),
      bodyMedium: baseTheme.textTheme.bodyMedium?.copyWith(
        fontSize: tokens.bodySize,
        height: tokens.bodyLineHeight / tokens.bodySize,
        color: tokens.textSecondary,
      ),
    ),
  );
}
