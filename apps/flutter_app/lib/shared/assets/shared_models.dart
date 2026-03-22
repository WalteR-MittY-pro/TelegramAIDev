import 'package:flutter/material.dart';

class SharedStartupConfig {
  const SharedStartupConfig({
    required this.tokens,
    required this.bootstrapCopy,
    required this.loginCopy,
    required this.placeholderNotice,
    required this.appMarkAssetPath,
    required this.defaultAuthenticatedDestination,
  });

  final DesignTokens tokens;
  final BootstrapCopy bootstrapCopy;
  final LoginCopy loginCopy;
  final String placeholderNotice;
  final String? appMarkAssetPath;
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

class PlaceholderCopy {
  const PlaceholderCopy({required this.placeholderNotice});

  factory PlaceholderCopy.fromJson(Map<String, dynamic> json) {
    final Map<String, dynamic> homeShell = _readMap(
      json['homeShell'],
      'homeShell',
    );
    return PlaceholderCopy(
      placeholderNotice: _readString(
        homeShell['placeholderNotice'],
        'homeShell.placeholderNotice',
      ),
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
