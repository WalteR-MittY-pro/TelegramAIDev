import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

import 'shared_models.dart';

abstract class SharedAssetRepository {
  Future<BootstrapCopy?> tryLoadBootstrapCopy();

  Future<SharedStartupConfig> loadStartupConfig();
}

class RootBundleSharedAssetRepository implements SharedAssetRepository {
  RootBundleSharedAssetRepository({
    AssetBundle? bundle,
    bool? forceStartupFailure,
  }) : _bundle = bundle ?? rootBundle,
       _forceStartupFailure =
           forceStartupFailure ??
           (!kReleaseMode && _forceStartupFailureFromEnvironment);

  static const String _assetRoot = 'assets/telegram-commercial-mvp';
  static const String _designTokensPath = '$_assetRoot/design-tokens.json';
  static const String _sharedCopyPath = '$_assetRoot/shared-copy.json';
  static const String _sharedMockDataPath = '$_assetRoot/shared-mock-data.json';
  static const String _resourceManifestPath =
      '$_assetRoot/resource-manifest.json';
  static const bool _forceStartupFailureFromEnvironment = bool.fromEnvironment(
    'TELEGRAM_DEMO_FORCE_STARTUP_FAILURE',
    defaultValue: false,
  );

  final AssetBundle _bundle;
  final bool _forceStartupFailure;

  @override
  Future<BootstrapCopy?> tryLoadBootstrapCopy() async {
    try {
      final String copyJson = await _bundle.loadString(_sharedCopyPath);
      final Map<String, dynamic> copyMap =
          jsonDecode(copyJson) as Map<String, dynamic>;
      return BootstrapCopy.fromJson(copyMap);
    } catch (_) {
      return null;
    }
  }

  @override
  Future<SharedStartupConfig> loadStartupConfig() async {
    if (_forceStartupFailure) {
      throw StateError(
        'Startup failure forced by TELEGRAM_DEMO_FORCE_STARTUP_FAILURE.',
      );
    }

    final List<String> payloads = await Future.wait(<Future<String>>[
      _bundle.loadString(_designTokensPath),
      _bundle.loadString(_sharedCopyPath),
      _bundle.loadString(_sharedMockDataPath),
      _bundle.loadString(_resourceManifestPath),
    ]);

    final Map<String, dynamic> designTokenMap =
        jsonDecode(payloads[0]) as Map<String, dynamic>;
    final Map<String, dynamic> copyMap =
        jsonDecode(payloads[1]) as Map<String, dynamic>;
    final Map<String, dynamic> mockDataMap =
        jsonDecode(payloads[2]) as Map<String, dynamic>;
    final Map<String, dynamic> resourceManifestMap =
        jsonDecode(payloads[3]) as Map<String, dynamic>;

    final StartupData startupData = StartupData.fromJson(mockDataMap);
    final ResourceManifest resourceManifest = ResourceManifest.fromJson(
      resourceManifestMap,
    );
    final HomeShellData homeShellData = HomeShellData.fromJson(mockDataMap);
    final Object? rawConversations = _coerceMap(
      mockDataMap['chatList'],
      'chatList',
    )['conversations'];
    if (rawConversations is! List<Object?>) {
      throw const FormatException('chatList.conversations must be a list.');
    }

    final List<ChatConversation> chatConversations = rawConversations
        .map(
          (Object? item) => ChatConversation.fromJson(
            _coerceMap(item, 'chatList.conversation'),
            assetRoot: _assetRoot,
          ),
        )
        .toList();

    return SharedStartupConfig(
      tokens: DesignTokens.fromJson(designTokenMap),
      bootstrapCopy: BootstrapCopy.fromJson(copyMap),
      loginCopy: LoginCopy.fromJson(copyMap),
      homeShellCopy: HomeShellCopy.fromJson(copyMap),
      chatListCopy: ChatListCopy.fromJson(copyMap),
      chatDetailCopy: ChatDetailCopy.fromJson(copyMap),
      homeShellData: homeShellData,
      chatConversations: chatConversations,
      chatDetailData: ChatDetailData.fromJson(mockDataMap),
      placeholderNotice: PlaceholderCopy.fromJson(copyMap).placeholderNotice,
      appMarkAssetPath: resourceManifest.resolveAssetPath(
        resourceId: 'app-mark',
        assetRoot: _assetRoot,
      ),
      avatarPlaceholderAssetPath: resourceManifest.resolveAssetPath(
        resourceId: 'avatar-placeholder',
        assetRoot: _assetRoot,
      ),
      defaultAuthenticatedDestination:
          startupData.defaultAuthenticatedDestination,
    );
  }
}

Map<String, dynamic> _coerceMap(Object? value, String label) {
  if (value is Map<String, dynamic>) {
    return value;
  }
  if (value is Map<Object?, Object?>) {
    return value.map(
      (Object? key, Object? nestedValue) =>
          MapEntry(key.toString(), nestedValue),
    );
  }
  throw FormatException('Expected map at $label.');
}
