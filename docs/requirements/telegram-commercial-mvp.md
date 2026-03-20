# Telegram Commercial MVP

## Goal

Build a Telegram-like commercial messaging app MVP that is realistic enough to evaluate AI-assisted development efficiency across `CJMP`, `KMP`, and `flutter`.

The MVP must be strong enough to expose real product, UI, state-management, navigation, testing, and tooling problems, while remaining small enough to ship repeatedly across all three frameworks.

## Product Principle

- Prioritize features that expose meaningful AI-efficiency problems.
- Keep the product experience close to Telegram on common flows.
- Prefer slices that are comparable across `CJMP`, `KMP`, and `flutter`.
- Avoid features that mainly add scope without increasing comparison value.

## Target User

- Internal evaluator comparing AI-assisted delivery quality, speed, and friction across frameworks.
- External customer who needs to see a believable Telegram-like demo rather than a toy prototype.

## In Scope

- app launch and startup routing
- login with a demo-first phone/code flow
- session restore on relaunch
- home shell with Telegram-like primary navigation presence
- chat list as the default home tab
- visible `Contacts` and `Settings` tabs on the home shell, even if their inner functionality is not implemented in the MVP
- chat detail screen with realistic message rendering
- sending a local demo text message
- core loading, empty, and error states on major screens
- framework-comparable instrumentation for time, token, and delivery friction reporting

## Out Of Scope

- real backend integration
- real SMS verification
- contacts sync
- contacts management flows
- settings detail flows
- voice and video calls
- channels, bots, payments, stories, mini apps
- advanced moderation and admin controls
- end-to-end encryption implementation details
- rarely used Telegram functions that do not expose additional AI-efficiency problems

## Quality Bar

- common flows should feel close to Telegram in interaction density, information hierarchy, and perceived polish
- the MVP should be credible for a customer demo
- implementation complexity should remain controlled enough to support repeated three-framework delivery

## Core User Flows

1. First launch without session
   - User opens the app and lands in login.
   - User can enter a demo phone number and continue into a demo verification step.
   - Successful login routes to the home shell with the chat list tab active.
2. Relaunch with valid session
   - User reopens the app and is routed directly into the home shell with the chat list tab active after restore.
3. Browse chats
   - User sees a Telegram-like home shell with `Chats`, `Contacts`, and `Settings` tabs present.
   - The `Chats` tab is active by default and shows a realistic list of conversations with avatar, title, snippet, timestamp, unread state, and pinned or muted cues where relevant.
4. Open a conversation
   - User enters chat detail and sees a believable mix of incoming and outgoing messages, grouped with date separators and delivery states where relevant.
5. Send a message
   - User types a text message and sees it appended locally with an immediate pending-to-sent transition.

## MVP Slices

1. App shell and startup routing
2. Demo login flow
3. Session restore
4. Home shell and chat list
5. Chat detail
6. Composer and local message send

## Cross-Framework Delivery Rule

Each approved requirement slice must be implemented for `CJMP`, `KMP`, and `flutter`.
If one framework is behind, the comparison artifact must record the gap explicitly instead of silently collapsing scope.

## Artifact Links

- acceptance: `docs/acceptance/telegram-commercial-mvp.md`
- design: `docs/design/telegram-commercial-mvp.md`
- design source board: `docs/design/figma-source/index.html`
- shared icon assets: `docs/design/assets/icons/`
- shared mock data: `docs/design/assets/mock-data.json`
- aggregate comparison: `reports/comparison/telegram-commercial-mvp-comparison-overview.md`
- `CJMP` round log: `reports/comparison/telegram-commercial-mvp-cjmp-rounds.md`
- `KMP` round log: `reports/comparison/telegram-commercial-mvp-kmp-rounds.md`
- `flutter` round log: `reports/comparison/telegram-commercial-mvp-flutter-rounds.md`
