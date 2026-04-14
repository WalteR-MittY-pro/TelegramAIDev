# Telegram Commercial MVP Shared Design Assets

This directory is the **canonical design reference** for the Telegram commercial MVP. Any framework implementation (CJMP, KMP, Flutter) should be able to reproduce the same UI using only these files.

Framework apps must copy the required files into their own local asset directories before runtime use.
Framework apps must not load runtime assets directly from this shared source directory.

## File Index

| File | Purpose |
|---|---|
| `design-tokens.json` | Color palette, typography scale, spacing system, border radii, component-level sizing tokens |
| `shared-copy.json` | Every user-visible text string in the app, keyed by screen and section |
| `shared-mock-data.json` | Seed conversations, contact list, settings items, navigation routing, behavioral specs (state transitions, delays) |
| `resource-manifest.json` | SVG/image asset registry with slice dependency mapping |
| `resources/` | SVG image assets referenced by the manifest |

## How to Reproduce the App

### Step 1: Read the design tokens

`design-tokens.json` defines the visual foundation. Map the token keys to your framework's theming system:

- `color.*` → hex color values for backgrounds, text, accents, status, borders, badges, avatars
- `typography.*` → font sizes (12–28), weights (400–700), line heights
- `spacing.*` → consistent spacing scale (4–32)
- `radius.*` → border radii for cards (18), fields (14), pills (999), bubbles (20)
- `component.loginShell.*` → login-specific sizing (form width, brand mark size, field dimensions)

### Step 2: Read the mock data

`shared-mock-data.json` defines what data to display:

- `startup.*` → session restore routing logic
- `login.*` → pre-filled demo values (country, phone prefix, verification code)
- `chatList.conversations` → 3 seed conversations with title, snippet, timestamp, unread count, pinned/muted state, avatar tint
- `contactsSurface.alphabetSections` → 5 contacts across 5 alphabetical sections with name, avatar initials, tint, online status
- `settingsSurface.*` → profile card, grouped settings sections with items
- `chatDetail.*` → 3 conversations with 4 seed messages, local send flow spec (pending→sent, /fail prefix for error simulation)

### Step 3: Read the copy

`shared-copy.json` defines every text string. Use the same keys to avoid hardcoding:

- `bootstrap.*` → loading and failure screen copy
- `login.*` → all login form labels, hints, validation notices
- `homeShell.*` → tab titles, subtitles, action labels, state filter labels, empty/error state copy
- `contacts.*` → search placeholder, quick action labels, status strings
- `settings.*` → section titles, profile name, session presentation labels
- `chatDetail.*` → composer placeholder, send label, delivery state labels, failure notice

### Step 4: Read the screen specs

`ui-screens.json` defines how to compose tokens + copy + mock data into actual screens:

- `navigation.routes` → page names and navigation graph
- `screens[]` → for each screen: exact component tree, padding/spacing values, font sizes, colors, conditional rendering rules, state variables, and interaction handlers

### Step 5: Copy the image assets

Use `resource-manifest.json` to identify required SVG files. Copy from `resources/` into your framework's asset directory, preserving filenames.

## App Screen Map

The app has 5 product screens (excluding test-only screens):

```
EntryView (3 states: loading → login → verification)
  ↓ successful login
HomeShellPage (3 tabs: Chats | Contacts | Settings)
  ↓ tap conversation
ChatDetailPage (message list + composer with local send)
```

Session restore on relaunch: EntryView → (auto-detect saved session) → HomeShellPage

## Alignment with CJMP Source

These design files are extracted from the CJMP reference implementation at `apps/cjmp/lib/`:
- `index.cj` → EntryView (startup, login, verification)
- `home_shell_page.cj` → HomeShellPage (chats, contacts, settings tabs)
- `chat_detail_page.cj` → ChatDetailPage
- `authenticated_placeholder_page.cj` → AuthenticatedPlaceholderPage
- `ui_test_selectors.cj` → component IDs for test automation
- `demo_session_store.cj` → session persistence behavior

When updating the CJMP implementation, update these design files accordingly to keep them in sync.
