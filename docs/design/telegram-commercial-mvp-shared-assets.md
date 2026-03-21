# Telegram Commercial MVP Shared Design Assets

## Goal

Define the canonical shared design asset contract for the Telegram commercial MVP so that `CJMP`, `KMP`, and `flutter` implementations use the same tokens, copy, mock data, and placeholder resources.

## Canonical Source

- shared asset spec: `docs/design/telegram-commercial-mvp-shared-assets.md`
- concrete shared asset source: `shared/design/telegram-commercial-mvp/`

The shared source directory is the only canonical source of concrete machine-consumable design assets for this MVP.

## Copy Rule

- each framework app must copy the required shared assets into its own local app asset directory before runtime use
- framework apps must preserve filenames and JSON structure when copying unless the framework requires a trivial packaging wrapper
- framework apps must never load runtime assets directly from `shared/design/telegram-commercial-mvp/`
- if a required shared asset is missing from the canonical source, implementation must stop and surface the gap instead of inventing a local replacement

## Required Asset Categories

### Design Tokens

Canonical file:

- `shared/design/telegram-commercial-mvp/design-tokens.json`

Required token groups:

- colors
- typography scale
- spacing scale
- radii
- border widths
- elevation or shadow levels
- icon sizes
- avatar sizes

### Shared Copy

Canonical file:

- `shared/design/telegram-commercial-mvp/shared-copy.json`

Required shared copy:

- bootstrap copy
- login copy
- home shell tab labels
- chat list loading, empty, and error copy
- chat detail title fallback and composer copy
- local-send failure copy that affects parity
- later-slice placeholder copy that affects parity

### Shared Mock Data

Canonical file:

- `shared/design/telegram-commercial-mvp/shared-mock-data.json`

Required shared mock data:

- startup and login seed data
- home shell tab metadata
- chat list seed conversations
- later-slice chat detail placeholder data
- local-send behavior metadata shared across frameworks

### Shared Placeholder Resources

Canonical files:

- `shared/design/telegram-commercial-mvp/resource-manifest.json`
- `shared/design/telegram-commercial-mvp/resources/app-mark.svg`
- `shared/design/telegram-commercial-mvp/resources/avatar-placeholder.svg`

Required resource coverage:

- app-level placeholder logo mark if needed
- default avatar placeholder
- any required illustration or icon resource that cannot be represented cleanly as token or JSON data

## Existing Narrow Asset Pattern

A startup or login-only JSON catalog such as a single `mock-data.json` file is not sufficient as the shared design asset layer.

That narrower pattern can cover early copy needs, but it does not define:

- design tokens
- home shell tab metadata
- chat list seed data
- chat detail and local-send behavior metadata
- placeholder resources

So framework implementations must use the full shared asset contract above instead of treating a startup-only JSON file as the whole shared asset layer.

## Minimum Consumer Behavior

Every framework implementation must:

1. read the shared asset spec before implementation
2. copy the required canonical files into the framework app project
3. use shared tokens, shared copy, shared mock data, and shared placeholder resources as the default source of truth
4. stop and surface any missing shared asset instead of creating a framework-local replacement
