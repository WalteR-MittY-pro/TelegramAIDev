# Telegram Commercial MVP Icon Assets

This directory is the canonical icon source for the framework-agnostic MVP UI design.

Use these SVG files directly during implementation instead of re-drawing icons from `docs/design/figma-source/index.html` or copying glyph characters from the HTML board.

## What is here

- `telegram-brand-mark.svg`: extracted from the login screen inline SVG
- `telegram-brand-badge.svg`: self-contained version of the login badge, derived from the inline mark plus the badge styling
- `tab-chats.svg`, `tab-contacts.svg`, `tab-settings.svg`: extracted from the home-shell tab bar inline SVGs
- `search.svg`, `compose.svg`, `add.svg`, `back.svg`, `more.svg`, `send.svg`, `pending.svg`: normalized SVG replacements for the design's temporary text glyphs
- `manifest.json`: machine-readable index of names, source type, and intended usage

## Direct use rule

- Treat this directory as the source of truth for icon shape data.
- Framework wrappers are consumption layers only.
- `flutter`, `KMP`, and `CJMP` implementations should all start from the same SVG files.

## Recommended implementation pattern

- Keep these raw SVG files under source control.
- Create framework-local wrappers only for loading, tinting, sizing, or mapping names to components.
- Do not silently redraw or substitute a different icon unless the design source is intentionally updated.

## Source mapping

- `extracted-inline-svg`: copied from the HTML design source without changing the shape
- `normalized-from-glyph`: created to replace a temporary character icon with a reusable SVG asset
- `derived-from-brand-mark-and-css-badge`: combines the inline brand mark with its CSS badge treatment so the full badge can be reused directly
