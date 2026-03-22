import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:flutter_app/app/telegram_demo_app.dart';
import 'package:flutter_app/features/chat/chat_detail_screen.dart';
import 'package:flutter_app/features/home/chat_list_screen.dart';
import 'package:flutter_app/shared/assets/shared_asset_repository.dart';
import 'package:flutter_app/shared/assets/shared_models.dart';
import 'package:flutter_app/shared/session/demo_session_store.dart';

void main() {
  const String avatarAssetPath =
      'assets/telegram-commercial-mvp/resources/avatar-placeholder.svg';

  List<ChatConversation> buildConversations() {
    return const <ChatConversation>[
      ChatConversation(
        id: 'chat-alex',
        title: 'Alex Mason',
        snippet: "Let's keep the startup slice tight for all three frameworks.",
        timestamp: '09:41',
        unreadCount: 2,
        pinned: true,
        muted: false,
        avatarAssetPath: avatarAssetPath,
        avatarTintName: 'blue',
      ),
      ChatConversation(
        id: 'chat-design',
        title: 'Design Sync',
        snippet:
            'Shared assets should prevent each framework from inventing its own look.',
        timestamp: 'Yesterday',
        unreadCount: 0,
        pinned: false,
        muted: true,
        avatarAssetPath: avatarAssetPath,
        avatarTintName: 'purple',
      ),
      ChatConversation(
        id: 'chat-ops',
        title: 'Ops Bot',
        snippet: 'Build is green. Token and time metrics were recorded.',
        timestamp: 'Thu',
        unreadCount: 1,
        pinned: false,
        muted: false,
        avatarAssetPath: avatarAssetPath,
        avatarTintName: 'green',
      ),
    ];
  }

  List<ChatDetailMessage> buildChatDetailMessages() {
    return const <ChatDetailMessage>[
      ChatDetailMessage(
        id: 'msg-1',
        direction: ChatMessageDirection.incoming,
        text:
            "Let's keep the MVP narrow, but the surface should still feel close to Telegram.",
        timeLabel: '09:21',
        deliveryLabel: null,
      ),
      ChatDetailMessage(
        id: 'msg-2',
        direction: ChatMessageDirection.outgoing,
        text:
            'Agreed. Home shell, chats, detail, and send flow should all feel believable.',
        timeLabel: '09:24',
        deliveryLabel: 'sent-read',
      ),
      ChatDetailMessage(
        id: 'msg-3',
        direction: ChatMessageDirection.incoming,
        text:
            'Also keep Contacts and Settings visible in the shell, even if they stay shallow.',
        timeLabel: '09:26',
        deliveryLabel: null,
      ),
      ChatDetailMessage(
        id: 'msg-4',
        direction: ChatMessageDirection.outgoing,
        text:
            'That keeps the demo credible without exploding the implementation scope.',
        timeLabel: '09:27',
        deliveryLabel: 'sent-read',
      ),
    ];
  }

  SharedStartupConfig buildConfig({List<ChatConversation>? conversations}) {
    return SharedStartupConfig(
      tokens: DesignTokens.fallback(),
      bootstrapCopy: BootstrapCopy.fallback(),
      loginCopy: LoginCopy.fallback(),
      homeShellCopy: HomeShellCopy.fallback(),
      chatListCopy: ChatListCopy.fallback(),
      chatDetailCopy: ChatDetailCopy.fallback(),
      homeShellData: HomeShellData.fallback(),
      chatConversations: conversations ?? buildConversations(),
      chatDetailData: ChatDetailData(
        placeholderConversationId: 'chat-alex',
        subtitle: 'last seen recently',
        typingSubtitle: 'typing...',
        dateLabel: 'Today',
        composerPlaceholder: 'Type a message...',
        messages: buildChatDetailMessages(),
      ),
      placeholderNotice: PlaceholderCopy.fallback().placeholderNotice,
      appMarkAssetPath: null,
      avatarPlaceholderAssetPath: avatarAssetPath,
      defaultAuthenticatedDestination: 'authenticated-placeholder',
    );
  }

  testWidgets('first launch routes cleanly into the login handoff state', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      TelegramDemoApp(
        repository: FakeSharedAssetRepository(configFactory: buildConfig),
        sessionStore: FakeDemoSessionStore(),
      ),
    );

    await tester.pump();
    await tester.pump();

    expect(find.text('Telegram Demo'), findsOneWidget);
    expect(find.text('Start with your phone number'), findsOneWidget);
    expect(find.byType(TextField), findsOneWidget);
    expect(find.text('Continue'), findsOneWidget);
  });

  testWidgets('invalid or incomplete phone input gets clear feedback', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      TelegramDemoApp(
        repository: FakeSharedAssetRepository(configFactory: buildConfig),
        sessionStore: FakeDemoSessionStore(),
      ),
    );

    await tester.pump();
    await tester.pump();

    await tester.tap(find.text('Continue'));
    await tester.pump();

    expect(
      find.text('Enter a valid demo phone number to continue.'),
      findsOneWidget,
    );
    expect(find.text('Chats'), findsNothing);
  });

  testWidgets('successful demo login lands in the home shell with chats active', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      TelegramDemoApp(
        repository: FakeSharedAssetRepository(configFactory: buildConfig),
        sessionStore: FakeDemoSessionStore(),
      ),
    );

    await tester.pump();
    await tester.pump();

    await tester.enterText(find.byType(TextField), '+1 415 555 0199');
    await tester.tap(find.text('Continue'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 450));
    await tester.pumpAndSettle();

    expect(find.text('Chats'), findsWidgets);
    expect(find.text('Contacts'), findsOneWidget);
    expect(find.text('Settings'), findsOneWidget);
    expect(find.text('Telegram'), findsOneWidget);
    expect(find.text('Alex Mason'), findsOneWidget);
    expect(find.text('Design Sync'), findsOneWidget);
    expect(find.text('Ops Bot'), findsOneWidget);
    expect(
      find.text(
        'This destination is intentionally scoped as a placeholder in the current MVP slice.',
      ),
      findsNothing,
    );

    await tester.drag(find.byType(ListView), const Offset(0, -160));
    await tester.pumpAndSettle();
    expect(find.text('Ops Bot'), findsOneWidget);
  });

  testWidgets('contacts and settings tabs stay intentional placeholders', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      TelegramDemoApp(
        repository: FakeSharedAssetRepository(configFactory: buildConfig),
        sessionStore: FakeDemoSessionStore(
          initialSession: const DemoSessionRecord(phoneNumber: '+14155550199'),
        ),
      ),
    );

    await tester.pump();
    await tester.pumpAndSettle();

    await tester.tap(find.text('Contacts'));
    await tester.pumpAndSettle();
    expect(find.text('Contacts'), findsWidgets);
    expect(
      find.text(
        'This destination is intentionally scoped as a placeholder in the current MVP slice.',
      ),
      findsOneWidget,
    );

    await tester.tap(find.text('Settings'));
    await tester.pumpAndSettle();
    expect(find.text('Settings'), findsWidgets);
    expect(
      find.text(
        'This destination is intentionally scoped as a placeholder in the current MVP slice.',
      ),
      findsOneWidget,
    );
  });

  testWidgets(
    'valid local demo session restores directly into the home shell',
    (WidgetTester tester) async {
      await tester.pumpWidget(
        TelegramDemoApp(
          repository: FakeSharedAssetRepository(configFactory: buildConfig),
          sessionStore: FakeDemoSessionStore(
            initialSession: const DemoSessionRecord(
              phoneNumber: '+14155550199',
            ),
          ),
        ),
      );

      await tester.pump();
      await tester.pump();
      await tester.pumpAndSettle();

      expect(find.text('Telegram'), findsOneWidget);
      expect(find.text('Alex Mason'), findsOneWidget);
      expect(find.text('Start with your phone number'), findsNothing);
    },
  );

  testWidgets(
    'shared seed conversation opens chat detail with date separator and inactive composer',
    (WidgetTester tester) async {
      await tester.pumpWidget(
        TelegramDemoApp(
          repository: FakeSharedAssetRepository(configFactory: buildConfig),
          sessionStore: FakeDemoSessionStore(
            initialSession: const DemoSessionRecord(
              phoneNumber: '+14155550199',
            ),
          ),
        ),
      );

      await tester.pump();
      await tester.pumpAndSettle();

      await tester.tap(
        find.byKey(const ValueKey<String>('conversation-row-chat-alex')),
      );
      await tester.pumpAndSettle();

      expect(find.byType(ChatDetailScreen), findsOneWidget);
      expect(find.text('Alex Mason'), findsOneWidget);
      expect(find.text('last seen recently'), findsOneWidget);
      expect(find.text('Today'), findsOneWidget);
      expect(
        find.text(
          "Let's keep the MVP narrow, but the surface should still feel close to Telegram.",
        ),
        findsOneWidget,
      );
      expect(find.byTooltip('Read'), findsWidgets);
      expect(find.text('Type a message...'), findsOneWidget);
      expect(find.text('Inactive'), findsOneWidget);
      expect(find.byType(TextField), findsNothing);
      expect(find.byIcon(Icons.send_rounded), findsNothing);
      expect(find.byType(NavigationBar), findsNothing);

      await tester.drag(find.byType(ListView), const Offset(0, -120));
      await tester.pumpAndSettle();
      expect(
        find.text(
          'That keeps the demo credible without exploding the implementation scope.',
        ),
        findsOneWidget,
      );
    },
  );

  testWidgets('chat detail back navigation returns to the chat list', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      TelegramDemoApp(
        repository: FakeSharedAssetRepository(configFactory: buildConfig),
        sessionStore: FakeDemoSessionStore(
          initialSession: const DemoSessionRecord(phoneNumber: '+14155550199'),
        ),
      ),
    );

    await tester.pump();
    await tester.pumpAndSettle();

    await tester.tap(
      find.byKey(const ValueKey<String>('conversation-row-chat-alex')),
    );
    await tester.pumpAndSettle();
    expect(find.byType(ChatDetailScreen), findsOneWidget);

    await tester.tap(find.byTooltip('Back'));
    await tester.pumpAndSettle();

    expect(find.byType(ChatDetailScreen), findsNothing);
    expect(find.text('Telegram'), findsOneWidget);
    expect(
      find.byKey(const ValueKey<String>('conversation-row-chat-alex')),
      findsOneWidget,
    );
  });

  testWidgets(
    'invalid local demo session falls back to login and clears stored state',
    (WidgetTester tester) async {
      final FakeDemoSessionStore sessionStore = FakeDemoSessionStore(
        initialSession: const DemoSessionRecord(phoneNumber: '4155550199'),
      );

      await tester.pumpWidget(
        TelegramDemoApp(
          repository: FakeSharedAssetRepository(configFactory: buildConfig),
          sessionStore: sessionStore,
        ),
      );

      await tester.pump();
      await tester.pump();
      await tester.pumpAndSettle();

      expect(find.text('Start with your phone number'), findsOneWidget);
      expect(find.text('Alex Mason'), findsNothing);
      expect(sessionStore.session, isNull);
      expect(sessionStore.clearCount, 1);
    },
  );

  testWidgets('startup failure shows an explicit notice instead of a spinner', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      TelegramDemoApp(
        repository: FakeSharedAssetRepository(error: StateError('load failed')),
        sessionStore: FakeDemoSessionStore(),
      ),
    );

    await tester.pump();
    await tester.pump(const Duration(milliseconds: 50));
    await tester.pump(const Duration(milliseconds: 50));

    expect(
      find.textContaining('Shared design assets failed to load'),
      findsOneWidget,
    );
    expect(find.byType(CircularProgressIndicator), findsNothing);
    expect(find.text('Retry startup'), findsOneWidget);
  });

  testWidgets(
    'debug startup-failure hook can force the failure route for acceptance',
    (WidgetTester tester) async {
      await tester.pumpWidget(
        TelegramDemoApp(
          repository: RootBundleSharedAssetRepository(
            bundle: _ThrowingAssetBundle(),
            forceStartupFailure: true,
          ),
          sessionStore: FakeDemoSessionStore(),
        ),
      );

      await tester.pump();
      await tester.pump(const Duration(milliseconds: 50));
      await tester.pump(const Duration(milliseconds: 50));

      expect(
        find.textContaining('Shared design assets failed to load'),
        findsOneWidget,
      );
      expect(find.text('Retry startup'), findsOneWidget);
    },
  );

  testWidgets('chat list loading state renders shared loading copy', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: ChatListScreen(
            copy: ChatListCopy(
              title: 'Telegram',
              loading: 'Loading conversations...',
              emptyTitle: 'No chats yet',
              emptyBody: 'Shared seed conversations have not been loaded.',
              errorTitle: "Couldn't load chats",
              errorBody: 'Check shared mock data and retry.',
            ),
            conversations: <ChatConversation>[],
            avatarPlaceholderAssetPath: avatarAssetPath,
            state: ChatListViewState.loading,
          ),
        ),
      ),
    );

    expect(find.text('Loading conversations...'), findsOneWidget);
    expect(find.byType(CircularProgressIndicator), findsOneWidget);
  });

  testWidgets('chat list empty and error states stay intentional', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: DefaultTabController(
          length: 1,
          child: Column(
            children: const <Widget>[
              Expanded(
                child: ChatListScreen(
                  copy: ChatListCopy(
                    title: 'Telegram',
                    loading: 'Loading conversations...',
                    emptyTitle: 'No chats yet',
                    emptyBody:
                        'Shared seed conversations have not been loaded.',
                    errorTitle: "Couldn't load chats",
                    errorBody: 'Check shared mock data and retry.',
                  ),
                  conversations: <ChatConversation>[],
                  avatarPlaceholderAssetPath: avatarAssetPath,
                  state: ChatListViewState.empty,
                ),
              ),
            ],
          ),
        ),
      ),
    );

    expect(find.text('No chats yet'), findsOneWidget);
    expect(
      find.text('Shared seed conversations have not been loaded.'),
      findsOneWidget,
    );

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: ChatListScreen(
            copy: ChatListCopy.fallback(),
            conversations: const <ChatConversation>[],
            avatarPlaceholderAssetPath: avatarAssetPath,
            state: ChatListViewState.error,
            onRetry: () {},
          ),
        ),
      ),
    );

    expect(find.text("Couldn't load chats"), findsOneWidget);
    expect(find.text('Check shared mock data and retry.'), findsOneWidget);
    expect(find.text('Retry'), findsOneWidget);
  });
}

class _ThrowingAssetBundle extends CachingAssetBundle {
  @override
  Future<String> loadString(String key, {bool cache = true}) {
    throw FlutterError('Unexpected asset request for $key');
  }

  @override
  Future<ByteData> load(String key) {
    throw FlutterError('Unexpected binary asset request for $key');
  }
}

class FakeSharedAssetRepository implements SharedAssetRepository {
  FakeSharedAssetRepository({this.configFactory, this.error});

  final SharedStartupConfig Function()? configFactory;
  final Object? error;

  @override
  Future<BootstrapCopy?> tryLoadBootstrapCopy() async {
    return BootstrapCopy.fallback();
  }

  @override
  Future<SharedStartupConfig> loadStartupConfig() async {
    if (error != null) {
      throw error!;
    }

    final SharedStartupConfig? config = configFactory?.call();
    if (config == null) {
      throw StateError('Missing startup config');
    }
    return config;
  }
}

class FakeDemoSessionStore implements DemoSessionStore {
  FakeDemoSessionStore({DemoSessionRecord? initialSession})
    : _session = initialSession;

  DemoSessionRecord? _session;
  int clearCount = 0;

  DemoSessionRecord? get session => _session;

  @override
  Future<void> clearSession() async {
    clearCount += 1;
    _session = null;
  }

  @override
  Future<DemoSessionRecord?> readSession() async {
    return _session;
  }

  @override
  Future<void> writeSession(DemoSessionRecord session) async {
    _session = session;
  }
}
