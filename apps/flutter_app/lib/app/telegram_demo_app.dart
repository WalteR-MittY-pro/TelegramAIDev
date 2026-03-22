import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../features/chat/chat_detail_screen.dart';
import '../features/home/chat_list_screen.dart';
import '../features/home/home_shell_screen.dart';
import '../features/home/home_tab_placeholder_screen.dart';
import '../features/login/login_handoff_screen.dart';
import '../features/startup/startup_gate_screen.dart';
import '../shared/assets/shared_asset_repository.dart';
import '../shared/assets/shared_models.dart';
import '../shared/session/demo_session_store.dart';
import 'app_bootstrap_controller.dart';

class TelegramDemoApp extends StatefulWidget {
  const TelegramDemoApp({
    super.key,
    required this.repository,
    required this.sessionStore,
  });

  final SharedAssetRepository repository;
  final DemoSessionStore sessionStore;

  @override
  State<TelegramDemoApp> createState() => _TelegramDemoAppState();
}

class _TelegramDemoAppState extends State<TelegramDemoApp> {
  static const String startupPath = '/';
  static const String loginPath = '/login';
  static const String chatsPath = '/home/chats';
  static const String contactsPath = '/home/contacts';
  static const String settingsPath = '/home/settings';
  static const String chatDetailPath = '/chat/:chatId';
  static const String chatDetailPathPrefix = '/chat/';

  late final AppBootstrapController _controller;
  late final GoRouter _router;

  @override
  void initState() {
    super.initState();
    _controller = AppBootstrapController(
      repository: widget.repository,
      sessionStore: widget.sessionStore,
    );
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
          path: chatDetailPath,
          builder: (BuildContext context, GoRouterState state) {
            final SharedStartupConfig config =
                _controller.startupConfig ?? _fallbackConfig();
            final String chatId = state.pathParameters['chatId'] ?? '';
            final ChatConversation conversation = _findConversation(
              config: config,
              chatId: chatId,
            );
            return ChatDetailScreen(
              conversation: conversation,
              chatDetailCopy: config.chatDetailCopy,
              chatDetailData: config.chatDetailData,
              onBack: () => context.go(chatsPath),
            );
          },
        ),
        ShellRoute(
          builder: (BuildContext context, GoRouterState state, Widget child) {
            return AnimatedBuilder(
              animation: _controller,
              builder: (BuildContext context, Widget? nestedChild) {
                final SharedStartupConfig config =
                    _controller.startupConfig ?? _fallbackConfig();
                return HomeShellScreen(
                  tabs: config.homeShellData.tabs,
                  homeShellCopy: config.homeShellCopy,
                  currentTabId: _tabIdForLocation(
                    state.matchedLocation,
                    config.homeShellData.defaultTab,
                  ),
                  chatListTitle: config.chatListCopy.title,
                  onSelectTab: (String tabId) => context.go(_pathForTab(tabId)),
                  child: child,
                );
              },
            );
          },
          routes: <RouteBase>[
            GoRoute(
              path: chatsPath,
              builder: (BuildContext context, GoRouterState state) {
                return AnimatedBuilder(
                  animation: _controller,
                  builder: (BuildContext context, Widget? child) {
                    final SharedStartupConfig config =
                        _controller.startupConfig ?? _fallbackConfig();
                    final ChatListViewState listState =
                        config.chatConversations.isEmpty
                        ? ChatListViewState.empty
                        : ChatListViewState.populated;
                    return ChatListScreen(
                      copy: config.chatListCopy,
                      conversations: config.chatConversations,
                      avatarPlaceholderAssetPath:
                          config.avatarPlaceholderAssetPath,
                      state: listState,
                      onOpenConversation: (String conversationId) {
                        if (conversationId !=
                            config.chatDetailData.placeholderConversationId) {
                          return;
                        }
                        context.go('/chat/$conversationId');
                      },
                    );
                  },
                );
              },
            ),
            GoRoute(
              path: contactsPath,
              builder: (BuildContext context, GoRouterState state) {
                final SharedStartupConfig config =
                    _controller.startupConfig ?? _fallbackConfig();
                return HomeTabPlaceholderScreen(
                  title: config.homeShellCopy.contactsLabel,
                  notice: config.placeholderNotice,
                );
              },
            ),
            GoRoute(
              path: settingsPath,
              builder: (BuildContext context, GoRouterState state) {
                final SharedStartupConfig config =
                    _controller.startupConfig ?? _fallbackConfig();
                return HomeTabPlaceholderScreen(
                  title: config.homeShellCopy.settingsLabel,
                  notice: config.placeholderNotice,
                );
              },
            ),
          ],
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
          if (_isAuthenticatedLocation(location)) {
            return null;
          }
          return _defaultHomePath;
        }
        if (location == loginPath) {
          return null;
        }
        return loginPath;
    }
  }

  String get _defaultHomePath {
    return _pathForTab(
      _controller.startupConfig?.homeShellData.defaultTab ??
          HomeShellData.fallback().defaultTab,
    );
  }

  SharedStartupConfig _fallbackConfig() {
    return SharedStartupConfig(
      tokens: DesignTokens.fallback(),
      bootstrapCopy: BootstrapCopy.fallback(),
      loginCopy: LoginCopy.fallback(),
      homeShellCopy: HomeShellCopy.fallback(),
      chatListCopy: ChatListCopy.fallback(),
      chatDetailCopy: ChatDetailCopy.fallback(),
      homeShellData: HomeShellData.fallback(),
      chatConversations: const <ChatConversation>[],
      chatDetailData: ChatDetailData.fallback(),
      placeholderNotice: PlaceholderCopy.fallback().placeholderNotice,
      appMarkAssetPath: null,
      avatarPlaceholderAssetPath: null,
      defaultAuthenticatedDestination: 'authenticated-placeholder',
    );
  }

  String _tabIdForLocation(String location, String fallbackTabId) {
    if (location == contactsPath) {
      return 'contacts';
    }
    if (location == settingsPath) {
      return 'settings';
    }
    if (location == chatsPath) {
      return 'chats';
    }
    return fallbackTabId;
  }

  bool _isAuthenticatedLocation(String location) {
    return location == chatsPath ||
        location == contactsPath ||
        location == settingsPath ||
        location.startsWith(chatDetailPathPrefix);
  }

  String _pathForTab(String tabId) {
    switch (tabId) {
      case 'contacts':
        return contactsPath;
      case 'settings':
        return settingsPath;
      case 'chats':
      default:
        return chatsPath;
    }
  }

  ChatConversation _findConversation({
    required SharedStartupConfig config,
    required String chatId,
  }) {
    for (final ChatConversation conversation in config.chatConversations) {
      if (conversation.id == chatId) {
        return conversation;
      }
    }
    if (config.chatConversations.isNotEmpty) {
      return config.chatConversations.first;
    }
    return const ChatConversation(
      id: 'missing-chat',
      title: 'Conversation',
      snippet: '',
      timestamp: '',
      unreadCount: 0,
      pinned: false,
      muted: false,
      avatarAssetPath: '',
      avatarTintName: 'blue',
    );
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
