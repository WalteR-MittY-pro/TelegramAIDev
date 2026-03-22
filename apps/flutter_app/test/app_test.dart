import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:flutter_app/app/telegram_demo_app.dart';
import 'package:flutter_app/features/placeholder/authenticated_placeholder_screen.dart';
import 'package:flutter_app/shared/assets/shared_asset_repository.dart';
import 'package:flutter_app/shared/assets/shared_models.dart';
import 'package:flutter_app/shared/session/demo_session_store.dart';

void main() {
  SharedStartupConfig buildConfig() {
    return SharedStartupConfig(
      tokens: DesignTokens.fallback(),
      bootstrapCopy: BootstrapCopy.fallback(),
      loginCopy: LoginCopy.fallback(),
      placeholderNotice: PlaceholderCopy.fallback().placeholderNotice,
      appMarkAssetPath: null,
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
    expect(
      find.text(
        'This destination is intentionally scoped as a placeholder in the current MVP slice.',
      ),
      findsNothing,
    );
  });

  testWidgets(
    'successful demo login hands off into the authenticated placeholder',
    (WidgetTester tester) async {
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

      expect(
        find.text(
          'This destination is intentionally scoped as a placeholder in the current MVP slice.',
        ),
        findsOneWidget,
      );
      expect(find.text('Chats'), findsNothing);
      expect(find.text('Settings'), findsNothing);
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

  testWidgets('authenticated placeholder stays visually scoped as a placeholder', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: AuthenticatedPlaceholderScreen(
          placeholderNotice:
              'This destination is intentionally scoped as a placeholder in the current MVP slice.',
        ),
      ),
    );

    expect(
      find.text(
        'This destination is intentionally scoped as a placeholder in the current MVP slice.',
      ),
      findsOneWidget,
    );
    expect(find.text('Chats'), findsNothing);
    expect(find.text('Settings'), findsNothing);
  });

  testWidgets(
    'valid local demo session restores directly into the authenticated placeholder',
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

      expect(
        find.text(
          'This destination is intentionally scoped as a placeholder in the current MVP slice.',
        ),
        findsOneWidget,
      );
      expect(find.text('Start with your phone number'), findsNothing);
      expect(find.text('Chats'), findsNothing);
    },
  );

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
      expect(
        find.text(
          'This destination is intentionally scoped as a placeholder in the current MVP slice.',
        ),
        findsNothing,
      );
      expect(sessionStore.session, isNull);
      expect(sessionStore.clearCount, 1);
    },
  );
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
