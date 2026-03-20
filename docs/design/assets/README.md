# Design Assets

This directory contains machine-consumable, framework-agnostic UI resources for the Telegram Commercial MVP.

Keep reusable design resources here instead of re-encoding them separately in each framework lane.

## Current assets

- `icons/`: canonical SVG icon source
- `mock-data.json`: canonical demo content and UI-state sample data

## Usage rule

- `CJMP`, `KMP`, and `flutter` implementations should consume the same asset files.
- Framework-specific wrappers are allowed for loading, styling, and binding, but the underlying assets should stay shared.
