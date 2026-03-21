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

## Slice Delivery Contracts

The full-MVP user flows above describe the cumulative product end state after all slices are delivered.
Issue-by-issue delivery must follow the slice contracts below instead of pulling later behavior forward early.

### Slice #1: App shell and startup routing

#### Allowed In This Slice

- bootstrap or loading gate
- route to login when no valid session exists
- startup failure state with recoverable fallback or explicit notice
- route graph or app shell structure only as needed to support the startup handoff

#### Must Not Be Implemented Yet

- demo verification step
- login success flow beyond a minimal authenticated handoff
- session persistence
- session restore
- real home shell
- chat list surface
- chat rows

#### Temporary Placeholder Allowed

- a minimal authenticated destination stub only if the route structure requires it
- the authenticated stub must not look like the real home shell or chat list

#### Depends On Prior Slice Outputs

- none

### Slice #2: Demo login flow

#### Allowed In This Slice

- phone input
- primary continue CTA
- validation and failure feedback
- demo verification step
- successful authenticated handoff after demo verification

#### Must Not Be Implemented Yet

- session persistence
- session restore on relaunch
- real home shell
- real chat list

#### Temporary Placeholder Allowed

- successful authentication may route to the same authenticated placeholder from slice `#1`
- the placeholder must not become the real home shell

#### Depends On Prior Slice Outputs

- slice `#1` app shell and startup routing

### Slice #3: Session restore

#### Allowed In This Slice

- persist a valid local demo session
- restore a valid local demo session on relaunch
- invalid-session fallback to login

#### Must Not Be Implemented Yet

- real home shell
- real chat list
- chat detail
- composer
- local send flow

#### Temporary Placeholder Allowed

- restore may land on the same authenticated placeholder used in slice `#2`
- the restored placeholder must not be presented as the real home shell or chat list

#### Depends On Prior Slice Outputs

- slice `#1` app shell and startup routing
- slice `#2` demo login flow

### Slice #4: Home shell and chat list

#### Allowed In This Slice

- Telegram-like home shell
- visible `Chats`, `Contacts`, and `Settings` tabs
- `Chats` as the default active tab
- chat list surface
- conversation rows with shared mock data
- loading, empty, and error states
- stable list scrolling

#### Must Not Be Implemented Yet

- chat detail
- composer
- local send flow

#### Temporary Placeholder Allowed

- `Contacts` and `Settings` inner destinations may remain placeholder screens in the MVP
- placeholder destinations must look intentional and must not appear broken

#### Depends On Prior Slice Outputs

- slice `#1` app shell and startup routing
- slice `#2` demo login flow
- slice `#3` session restore

### Slice #5: Chat detail

#### Allowed In This Slice

- chat detail route and back navigation
- top bar with conversation title
- message history rendering
- incoming and outgoing bubbles
- date separators
- stable scrolling for the shared seed conversation
- delivery-state cues for existing shared mock messages

#### Must Not Be Implemented Yet

- local text send flow
- editable composer behavior
- attachments, stickers, or voice notes
- remote sync or delivery receipts

#### Temporary Placeholder Allowed

- a non-interactive composer shell may be shown if needed to preserve the intended layout
- any composer shell shown in this slice must not allow sending or local message append

#### Depends On Prior Slice Outputs

- slices `#1` through `#4`

### Slice #6: Composer and local message send

#### Allowed In This Slice

- text input composer
- send action
- local message append
- pending-to-sent transition
- clear composer on success
- recoverable local send failure state when applicable

#### Must Not Be Implemented Yet

- remote delivery receipts
- attachments, stickers, or voice message compose
- media gallery or advanced message actions

#### Temporary Placeholder Allowed

- non-text composer affordances may remain absent or inert
- local send may stay fully local-only and must not pretend to contact a real backend

#### Depends On Prior Slice Outputs

- slices `#1` through `#5`

## Cross-Framework Delivery Rule

Each approved requirement slice must be implemented for `CJMP`, `KMP`, and `flutter`.
If one framework is behind, the comparison artifact must record the gap explicitly instead of silently collapsing scope.
Each slice must also use the canonical shared design asset contract and source directory instead of inventing framework-local variants.

## Artifact Links

- acceptance: `docs/acceptance/telegram-commercial-mvp.md`
- design: `docs/design/telegram-commercial-mvp.md`
- shared design assets: `docs/design/telegram-commercial-mvp-shared-assets.md`
- shared design asset source: `shared/design/telegram-commercial-mvp/`
- aggregate comparison: `reports/comparison/telegram-commercial-mvp-comparison-overview.md`
- `CJMP` round log: `reports/comparison/telegram-commercial-mvp-cjmp-rounds.md`
- `KMP` round log: `reports/comparison/telegram-commercial-mvp-kmp-rounds.md`
- `flutter` round log: `reports/comparison/telegram-commercial-mvp-flutter-rounds.md`
