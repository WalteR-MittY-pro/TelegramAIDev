import 'package:flutter/material.dart';

class SharedStartupConfig {
  const SharedStartupConfig({
    required this.tokens,
    required this.bootstrapCopy,
    required this.loginCopy,
    required this.homeShellCopy,
    required this.chatListCopy,
    required this.chatDetailCopy,
    required this.homeShellData,
    required this.chatConversations,
    required this.chatDetailData,
    required this.placeholderNotice,
    required this.appMarkAssetPath,
    required this.avatarPlaceholderAssetPath,
    required this.defaultAuthenticatedDestination,
  });

  final DesignTokens tokens;
  final BootstrapCopy bootstrapCopy;
  final LoginCopy loginCopy;
  final HomeShellCopy homeShellCopy;
  final ChatListCopy chatListCopy;
  final ChatDetailCopy chatDetailCopy;
  final HomeShellData homeShellData;
  final List<ChatConversation> chatConversations;
  final ChatDetailData chatDetailData;
  final String placeholderNotice;
  final String? appMarkAssetPath;
  final String? avatarPlaceholderAssetPath;
  final String defaultAuthenticatedDestination;
}

class BootstrapCopy {
  const BootstrapCopy({
    required this.title,
    required this.body,
    required this.failureNotice,
  });

  factory BootstrapCopy.fromJson(Map<String, dynamic> json) {
    final Map<String, dynamic> bootstrap = _readMap(
      json['bootstrap'],
      'bootstrap',
    );
    return BootstrapCopy(
      title: _readString(bootstrap['title'], 'bootstrap.title'),
      body: _readString(bootstrap['body'], 'bootstrap.body'),
      failureNotice: _readString(
        bootstrap['failureNotice'],
        'bootstrap.failureNotice',
      ),
    );
  }

  factory BootstrapCopy.fallback() {
    return const BootstrapCopy(
      title: 'Loading Telegram Demo...',
      body:
          'Preparing startup routing and shared design assets before the first-launch handoff.',
      failureNotice:
          'Shared design assets failed to load. Retry startup or check the bundled assets.',
    );
  }

  final String title;
  final String body;
  final String failureNotice;
}

class LoginCopy {
  const LoginCopy({
    required this.brandTitle,
    required this.headline,
    required this.body,
    required this.phoneLabel,
    required this.phoneHint,
    required this.continueLabel,
    required this.footer,
    required this.invalidInputNotice,
  });

  factory LoginCopy.fromJson(Map<String, dynamic> json) {
    final Map<String, dynamic> login = _readMap(json['login'], 'login');
    return LoginCopy(
      brandTitle: _readString(login['brandTitle'], 'login.brandTitle'),
      headline: _readString(login['headline'], 'login.headline'),
      body: _readString(login['body'], 'login.body'),
      phoneLabel: _readString(login['phoneLabel'], 'login.phoneLabel'),
      phoneHint: _readString(login['phoneHint'], 'login.phoneHint'),
      continueLabel: _readString(login['continueLabel'], 'login.continueLabel'),
      footer: _readString(login['footer'], 'login.footer'),
      invalidInputNotice: _readString(
        login['invalidInputNotice'],
        'login.invalidInputNotice',
      ),
    );
  }

  factory LoginCopy.fallback() {
    return const LoginCopy(
      brandTitle: 'Telegram Demo',
      headline: 'Start with your phone number',
      body:
          'Complete the demo sign-in flow to unlock the authenticated app shell.',
      phoneLabel: 'Phone number',
      phoneHint: '+1 415 555 0199',
      continueLabel: 'Continue',
      footer:
          'Demo verification is local-only and does not contact a real backend.',
      invalidInputNotice: 'Enter a valid demo phone number to continue.',
    );
  }

  final String brandTitle;
  final String headline;
  final String body;
  final String phoneLabel;
  final String phoneHint;
  final String continueLabel;
  final String footer;
  final String invalidInputNotice;
}

class HomeShellCopy {
  const HomeShellCopy({
    required this.chatsLabel,
    required this.contactsLabel,
    required this.settingsLabel,
    required this.placeholderNotice,
  });

  factory HomeShellCopy.fromJson(Map<String, dynamic> json) {
    final Map<String, dynamic> homeShell = _readMap(
      json['homeShell'],
      'homeShell',
    );
    final Map<String, dynamic> tabs = _readMap(
      homeShell['tabs'],
      'homeShell.tabs',
    );

    return HomeShellCopy(
      chatsLabel: _readString(tabs['chats'], 'homeShell.tabs.chats'),
      contactsLabel: _readString(tabs['contacts'], 'homeShell.tabs.contacts'),
      settingsLabel: _readString(tabs['settings'], 'homeShell.tabs.settings'),
      placeholderNotice: _readString(
        homeShell['placeholderNotice'],
        'homeShell.placeholderNotice',
      ),
    );
  }

  factory HomeShellCopy.fallback() {
    return const HomeShellCopy(
      chatsLabel: 'Chats',
      contactsLabel: 'Contacts',
      settingsLabel: 'Settings',
      placeholderNotice:
          'This destination is intentionally scoped as a placeholder in the current MVP slice.',
    );
  }

  final String chatsLabel;
  final String contactsLabel;
  final String settingsLabel;
  final String placeholderNotice;

  String labelForTabId(String tabId) {
    switch (tabId) {
      case 'contacts':
        return contactsLabel;
      case 'settings':
        return settingsLabel;
      case 'chats':
      default:
        return chatsLabel;
    }
  }
}

class ChatListCopy {
  const ChatListCopy({
    required this.title,
    required this.loading,
    required this.emptyTitle,
    required this.emptyBody,
    required this.errorTitle,
    required this.errorBody,
  });

  factory ChatListCopy.fromJson(Map<String, dynamic> json) {
    final Map<String, dynamic> chatList = _readMap(
      json['chatList'],
      'chatList',
    );
    return ChatListCopy(
      title: _readString(chatList['title'], 'chatList.title'),
      loading: _readString(chatList['loading'], 'chatList.loading'),
      emptyTitle: _readString(chatList['emptyTitle'], 'chatList.emptyTitle'),
      emptyBody: _readString(chatList['emptyBody'], 'chatList.emptyBody'),
      errorTitle: _readString(chatList['errorTitle'], 'chatList.errorTitle'),
      errorBody: _readString(chatList['errorBody'], 'chatList.errorBody'),
    );
  }

  factory ChatListCopy.fallback() {
    return const ChatListCopy(
      title: 'Telegram',
      loading: 'Loading conversations...',
      emptyTitle: 'No chats yet',
      emptyBody: 'Shared seed conversations have not been loaded.',
      errorTitle: "Couldn't load chats",
      errorBody: 'Check shared mock data and retry.',
    );
  }

  final String title;
  final String loading;
  final String emptyTitle;
  final String emptyBody;
  final String errorTitle;
  final String errorBody;
}

class ChatDetailCopy {
  const ChatDetailCopy({
    required this.titleFallback,
    required this.composerPlaceholder,
    required this.sendLabel,
    required this.sendFailureNotice,
  });

  factory ChatDetailCopy.fromJson(Map<String, dynamic> json) {
    final Map<String, dynamic> chatDetail = _readMap(
      json['chatDetail'],
      'chatDetail',
    );
    return ChatDetailCopy(
      titleFallback: _readString(
        chatDetail['titleFallback'],
        'chatDetail.titleFallback',
      ),
      composerPlaceholder: _readString(
        chatDetail['composerPlaceholder'],
        'chatDetail.composerPlaceholder',
      ),
      sendLabel: _readString(chatDetail['sendLabel'], 'chatDetail.sendLabel'),
      sendFailureNotice: _readString(
        chatDetail['sendFailureNotice'],
        'chatDetail.sendFailureNotice',
      ),
    );
  }

  factory ChatDetailCopy.fallback() {
    return const ChatDetailCopy(
      titleFallback: 'Conversation',
      composerPlaceholder: 'Message',
      sendLabel: 'Send',
      sendFailureNotice: 'The local demo message could not be sent. Try again.',
    );
  }

  final String titleFallback;
  final String composerPlaceholder;
  final String sendLabel;
  final String sendFailureNotice;
}

class PlaceholderCopy {
  const PlaceholderCopy({required this.placeholderNotice});

  factory PlaceholderCopy.fromJson(Map<String, dynamic> json) {
    return PlaceholderCopy(
      placeholderNotice: HomeShellCopy.fromJson(json).placeholderNotice,
    );
  }

  factory PlaceholderCopy.fallback() {
    return const PlaceholderCopy(
      placeholderNotice:
          'This destination is intentionally scoped as a placeholder in the current MVP slice.',
    );
  }

  final String placeholderNotice;
}

class StartupData {
  const StartupData({required this.defaultAuthenticatedDestination});

  factory StartupData.fromJson(Map<String, dynamic> json) {
    final Map<String, dynamic> startup = _readMap(json['startup'], 'startup');
    return StartupData(
      defaultAuthenticatedDestination: _readString(
        startup['defaultAuthenticatedDestination'],
        'startup.defaultAuthenticatedDestination',
      ),
    );
  }

  final String defaultAuthenticatedDestination;
}

class HomeShellData {
  const HomeShellData({required this.defaultTab, required this.tabs});

  factory HomeShellData.fromJson(Map<String, dynamic> json) {
    final Map<String, dynamic> homeShell = _readMap(
      json['homeShell'],
      'homeShell',
    );
    final Object? rawTabs = homeShell['tabs'];
    if (rawTabs is! List<Object?>) {
      throw const FormatException('homeShell.tabs must be a list.');
    }

    return HomeShellData(
      defaultTab: _readString(homeShell['defaultTab'], 'homeShell.defaultTab'),
      tabs: rawTabs
          .map(
            (Object? item) => HomeShellTabData.fromJson(_readMap(item, 'tab')),
          )
          .toList(),
    );
  }

  factory HomeShellData.fallback() {
    return HomeShellData(
      defaultTab: 'chats',
      tabs: const <HomeShellTabData>[
        HomeShellTabData(
          id: 'chats',
          labelKey: 'homeShell.tabs.chats',
          iconId: 'chat-bubble',
          implementedInSlice: 4,
          placeholderDestination: false,
        ),
        HomeShellTabData(
          id: 'contacts',
          labelKey: 'homeShell.tabs.contacts',
          iconId: 'contacts',
          implementedInSlice: 4,
          placeholderDestination: true,
        ),
        HomeShellTabData(
          id: 'settings',
          labelKey: 'homeShell.tabs.settings',
          iconId: 'settings',
          implementedInSlice: 4,
          placeholderDestination: true,
        ),
      ],
    );
  }

  final String defaultTab;
  final List<HomeShellTabData> tabs;
}

class HomeShellTabData {
  const HomeShellTabData({
    required this.id,
    required this.labelKey,
    required this.iconId,
    required this.implementedInSlice,
    required this.placeholderDestination,
  });

  factory HomeShellTabData.fromJson(Map<String, dynamic> json) {
    return HomeShellTabData(
      id: _readString(json['id'], 'tab.id'),
      labelKey: _readString(json['labelKey'], 'tab.labelKey'),
      iconId: _readString(json['iconId'], 'tab.iconId'),
      implementedInSlice: _readInt(
        json['implementedInSlice'],
        'tab.implementedInSlice',
      ),
      placeholderDestination:
          _readBool(
            json['placeholderDestination'],
            'tab.placeholderDestination',
          ) ??
          false,
    );
  }

  final String id;
  final String labelKey;
  final String iconId;
  final int implementedInSlice;
  final bool placeholderDestination;
}

class ChatConversation {
  const ChatConversation({
    required this.id,
    required this.title,
    required this.snippet,
    required this.timestamp,
    required this.unreadCount,
    required this.pinned,
    required this.muted,
    required this.avatarAssetPath,
    required this.avatarTintName,
  });

  factory ChatConversation.fromJson(
    Map<String, dynamic> json, {
    required String assetRoot,
  }) {
    final String avatarResource = _readString(
      json['avatarResource'],
      'chatList.conversations.avatarResource',
    );
    return ChatConversation(
      id: _readString(json['id'], 'chatList.conversations.id'),
      title: _readString(json['title'], 'chatList.conversations.title'),
      snippet: _readString(json['snippet'], 'chatList.conversations.snippet'),
      timestamp: _readString(
        json['timestamp'],
        'chatList.conversations.timestamp',
      ),
      unreadCount: _readInt(
        json['unreadCount'],
        'chatList.conversations.unreadCount',
      ),
      pinned:
          _readBool(json['pinned'], 'chatList.conversations.pinned') ?? false,
      muted: _readBool(json['muted'], 'chatList.conversations.muted') ?? false,
      avatarAssetPath: '$assetRoot/resources/$avatarResource',
      avatarTintName: _readString(
        json['avatarTint'],
        'chatList.conversations.avatarTint',
      ),
    );
  }

  final String id;
  final String title;
  final String snippet;
  final String timestamp;
  final int unreadCount;
  final bool pinned;
  final bool muted;
  final String avatarAssetPath;
  final String avatarTintName;
}

class ChatDetailData {
  const ChatDetailData({
    required this.placeholderConversationId,
    required this.subtitle,
    required this.typingSubtitle,
    required this.dateLabel,
    required this.composerPlaceholder,
    required this.messages,
  });

  factory ChatDetailData.fromJson(Map<String, dynamic> json) {
    final Map<String, dynamic> chatDetail = _readMap(
      json['chatDetail'],
      'chatDetail',
    );
    final Object? rawMessages = chatDetail['messages'];
    if (rawMessages is! List<Object?>) {
      throw const FormatException('chatDetail.messages must be a list.');
    }

    return ChatDetailData(
      placeholderConversationId: _readString(
        chatDetail['placeholderConversationId'],
        'chatDetail.placeholderConversationId',
      ),
      subtitle: _readString(chatDetail['subtitle'], 'chatDetail.subtitle'),
      typingSubtitle: _readString(
        chatDetail['typingSubtitle'],
        'chatDetail.typingSubtitle',
      ),
      dateLabel: _readString(chatDetail['dateLabel'], 'chatDetail.dateLabel'),
      composerPlaceholder: _readString(
        _readMap(chatDetail['composer'], 'chatDetail.composer')['placeholder'],
        'chatDetail.composer.placeholder',
      ),
      messages: rawMessages
          .map(
            (Object? item) => ChatDetailMessage.fromJson(
              _readMap(item, 'chatDetail.message'),
            ),
          )
          .toList(),
    );
  }

  factory ChatDetailData.fallback() {
    return const ChatDetailData(
      placeholderConversationId: 'chat-alex',
      subtitle: 'last seen recently',
      typingSubtitle: 'typing...',
      dateLabel: 'Today',
      composerPlaceholder: 'Type a message...',
      messages: <ChatDetailMessage>[
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
      ],
    );
  }

  final String placeholderConversationId;
  final String subtitle;
  final String typingSubtitle;
  final String dateLabel;
  final String composerPlaceholder;
  final List<ChatDetailMessage> messages;
}

enum ChatMessageDirection { incoming, outgoing }

class ChatDetailMessage {
  const ChatDetailMessage({
    required this.id,
    required this.direction,
    required this.text,
    required this.timeLabel,
    required this.deliveryLabel,
  });

  factory ChatDetailMessage.fromJson(Map<String, dynamic> json) {
    return ChatDetailMessage(
      id: _readString(json['id'], 'chatDetail.message.id'),
      direction: _readDirection(
        _readString(json['direction'], 'chatDetail.message.direction'),
      ),
      text: _readString(json['text'], 'chatDetail.message.text'),
      timeLabel: _readString(json['timeLabel'], 'chatDetail.message.timeLabel'),
      deliveryLabel: _readNullableString(
        json['deliveryLabel'],
        'chatDetail.message.deliveryLabel',
      ),
    );
  }

  final String id;
  final ChatMessageDirection direction;
  final String text;
  final String timeLabel;
  final String? deliveryLabel;

  bool get isOutgoing => direction == ChatMessageDirection.outgoing;
}

class ResourceManifest {
  const ResourceManifest({required this.resources});

  factory ResourceManifest.fromJson(Map<String, dynamic> json) {
    final Object? rawResources = json['resources'];
    if (rawResources is! List<Object?>) {
      throw const FormatException('resources must be a list.');
    }

    return ResourceManifest(
      resources: rawResources
          .map(
            (Object? item) =>
                ResourceEntry.fromJson(_readMap(item, 'resource')),
          )
          .toList(),
    );
  }

  final List<ResourceEntry> resources;

  String resolveAssetPath({
    required String resourceId,
    required String assetRoot,
  }) {
    for (final ResourceEntry resource in resources) {
      if (resource.id == resourceId) {
        return '$assetRoot/${resource.source}';
      }
    }
    throw FormatException('Missing resource for $resourceId');
  }
}

class ResourceEntry {
  const ResourceEntry({required this.id, required this.source});

  factory ResourceEntry.fromJson(Map<String, dynamic> json) {
    return ResourceEntry(
      id: _readString(json['id'], 'resource.id'),
      source: _readString(json['source'], 'resource.source'),
    );
  }

  final String id;
  final String source;
}

class DesignTokens {
  const DesignTokens({
    required this.appBackground,
    required this.screen,
    required this.textPrimary,
    required this.textSecondary,
    required this.textInverse,
    required this.brand,
    required this.borderSubtle,
    required this.cardRadius,
    required this.fieldRadius,
    required this.cardElevation,
    required this.headlineSize,
    required this.headlineLineHeight,
    required this.titleSize,
    required this.titleLineHeight,
    required this.bodyStrongSize,
    required this.bodyStrongLineHeight,
    required this.bodySize,
    required this.bodyLineHeight,
    required this.spacingLarge,
    required this.spacingExtraLarge,
  });

  factory DesignTokens.fromJson(Map<String, dynamic> json) {
    final Map<String, dynamic> colors = _readMap(json['color'], 'color');
    final Map<String, dynamic> surface = _readMap(
      colors['surface'],
      'color.surface',
    );
    final Map<String, dynamic> text = _readMap(colors['text'], 'color.text');
    final Map<String, dynamic> accent = _readMap(
      colors['accent'],
      'color.accent',
    );
    final Map<String, dynamic> border = _readMap(
      colors['border'],
      'color.border',
    );
    final Map<String, dynamic> radius = _readMap(json['radius'], 'radius');
    final Map<String, dynamic> elevation = _readMap(
      json['elevation'],
      'elevation',
    );
    final Map<String, dynamic> typography = _readMap(
      json['typography'],
      'typography',
    );
    final Map<String, dynamic> size = _readMap(
      typography['size'],
      'typography.size',
    );
    final Map<String, dynamic> lineHeight = _readMap(
      typography['lineHeight'],
      'typography.lineHeight',
    );
    final Map<String, dynamic> spacing = _readMap(json['spacing'], 'spacing');

    return DesignTokens(
      appBackground: _parseColor(
        _readString(surface['appBackground'], 'color.surface.appBackground'),
      ),
      screen: _parseColor(
        _readString(surface['screen'], 'color.surface.screen'),
      ),
      textPrimary: _parseColor(
        _readString(text['primary'], 'color.text.primary'),
      ),
      textSecondary: _parseColor(
        _readString(text['secondary'], 'color.text.secondary'),
      ),
      textInverse: _parseColor(
        _readString(text['inverse'], 'color.text.inverse'),
      ),
      brand: _parseColor(_readString(accent['brand'], 'color.accent.brand')),
      borderSubtle: _parseColor(
        _readString(border['subtle'], 'color.border.subtle'),
      ),
      cardRadius: _readDouble(radius['card'], 'radius.card'),
      fieldRadius: _readDouble(radius['field'], 'radius.field'),
      cardElevation: _readDouble(elevation['card'], 'elevation.card'),
      headlineSize: _readDouble(size['headline'], 'typography.size.headline'),
      headlineLineHeight: _readDouble(
        lineHeight['headline'],
        'typography.lineHeight.headline',
      ),
      titleSize: _readDouble(size['title'], 'typography.size.title'),
      titleLineHeight: _readDouble(
        lineHeight['title'],
        'typography.lineHeight.title',
      ),
      bodyStrongSize: _readDouble(
        size['bodyStrong'],
        'typography.size.bodyStrong',
      ),
      bodyStrongLineHeight: _readDouble(
        lineHeight['bodyStrong'],
        'typography.lineHeight.bodyStrong',
      ),
      bodySize: _readDouble(size['body'], 'typography.size.body'),
      bodyLineHeight: _readDouble(
        lineHeight['body'],
        'typography.lineHeight.body',
      ),
      spacingLarge: _readDouble(spacing['lg'], 'spacing.lg'),
      spacingExtraLarge: _readDouble(spacing['xl'], 'spacing.xl'),
    );
  }

  factory DesignTokens.fallback() {
    return const DesignTokens(
      appBackground: Color(0xFFF4F6F8),
      screen: Color(0xFFFFFFFF),
      textPrimary: Color(0xFF17212B),
      textSecondary: Color(0xFF5B6B7A),
      textInverse: Color(0xFFFFFFFF),
      brand: Color(0xFF2AABEE),
      borderSubtle: Color(0xFFD9E2EC),
      cardRadius: 18,
      fieldRadius: 14,
      cardElevation: 2,
      headlineSize: 28,
      headlineLineHeight: 34,
      titleSize: 20,
      titleLineHeight: 26,
      bodyStrongSize: 15,
      bodyStrongLineHeight: 22,
      bodySize: 14,
      bodyLineHeight: 20,
      spacingLarge: 16,
      spacingExtraLarge: 24,
    );
  }

  final Color appBackground;
  final Color screen;
  final Color textPrimary;
  final Color textSecondary;
  final Color textInverse;
  final Color brand;
  final Color borderSubtle;
  final double cardRadius;
  final double fieldRadius;
  final double cardElevation;
  final double headlineSize;
  final double headlineLineHeight;
  final double titleSize;
  final double titleLineHeight;
  final double bodyStrongSize;
  final double bodyStrongLineHeight;
  final double bodySize;
  final double bodyLineHeight;
  final double spacingLarge;
  final double spacingExtraLarge;
}

Map<String, dynamic> _readMap(Object? value, String label) {
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

String _readString(Object? value, String label) {
  if (value is String) {
    return value;
  }
  throw FormatException('Expected string at $label.');
}

double _readDouble(Object? value, String label) {
  if (value is int) {
    return value.toDouble();
  }
  if (value is double) {
    return value;
  }
  throw FormatException('Expected numeric value at $label.');
}

int _readInt(Object? value, String label) {
  if (value is int) {
    return value;
  }
  throw FormatException('Expected integer at $label.');
}

bool? _readBool(Object? value, String label) {
  if (value == null) {
    return null;
  }
  if (value is bool) {
    return value;
  }
  throw FormatException('Expected bool at $label.');
}

String? _readNullableString(Object? value, String label) {
  if (value == null) {
    return null;
  }
  if (value is String) {
    return value;
  }
  throw FormatException('Expected nullable string at $label.');
}

ChatMessageDirection _readDirection(String value) {
  switch (value) {
    case 'incoming':
      return ChatMessageDirection.incoming;
    case 'outgoing':
      return ChatMessageDirection.outgoing;
  }
  throw FormatException('Unsupported chat message direction: $value');
}

Color _parseColor(String value) {
  final String normalized = value.replaceFirst('#', '');
  if (normalized.length == 6) {
    return Color(int.parse('FF$normalized', radix: 16));
  }
  if (normalized.length == 8) {
    return Color(int.parse(normalized, radix: 16));
  }
  throw FormatException('Invalid color value: $value');
}
