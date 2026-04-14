# Telegram Commercial MVP Acceptance

## Scope

This document defines the acceptance scenarios for the Telegram-like commercial MVP.

Related requirement: `docs/requirements/telegram-commercial-mvp.md`
Related design: `docs/design/telegram-commercial-mvp.md`

## Slice Acceptance Contracts

The scenarios below describe the cumulative full-MVP behavior after slices `#1` through `#6` are complete.
For issue-by-issue acceptance of slices `#1` through `#6`, use the contracts below instead of treating later-slice product behavior as early-slice acceptance scope.

### Slice #1: App shell and startup routing

#### Allowed In This Slice

- bootstrap or loading gate
- no-session handoff into login
- startup failure state with recoverable fallback or explicit notice
- authenticated route stub only if routing structure requires it

#### Must Not Be Implemented Yet

- demo verification
- successful authenticated handoff after login
- session persistence
- session restore
- home shell
- chat list

#### Temporary Placeholder Allowed

- a minimal authenticated placeholder screen may exist behind the routing layer
- the placeholder must not look like the real home shell or chat list

#### Depends On Prior Slice Outputs

- none

#### Slice Pass Criteria

- first launch without session reaches login cleanly
- startup failure does not leave the app stuck on a spinner
- the login shell clearly shows the Telegram mark and wordmark, separate country and phone fields, and an interactive keep-signed-in control
- the default login state remains visually sparse instead of relying on dense explanatory copy
- any authenticated destination reachable in this slice is clearly a placeholder, not a later-slice implementation

### Slice #2: Demo login flow

#### Allowed In This Slice

- phone input
- continue CTA
- validation and failure feedback
- demo verification step
- successful authenticated handoff into the authenticated placeholder

#### Must Not Be Implemented Yet

- session persistence
- session restore on relaunch
- real home shell
- real chat list

#### Temporary Placeholder Allowed

- successful authentication may land on the authenticated placeholder from slice `#1`
- the placeholder must not be presented as the real home shell

#### Depends On Prior Slice Outputs

- slice `#1` app shell and startup routing

#### Slice Pass Criteria

- the user can complete the demo login path without developer knowledge
- invalid or incomplete input gets clear feedback
- phone-entry validation stays inline and preserves the overall shell instead of replacing it with a verbose error screen
- success ends in the authenticated placeholder handoff, not in the real home shell or chat list

### Slice #3: Session restore

#### Allowed In This Slice

- local demo session persistence
- restore on relaunch when the local session is valid
- fallback to login when the local session is invalid or missing

#### Must Not Be Implemented Yet

- real home shell
- real chat list
- chat detail
- composer

#### Temporary Placeholder Allowed

- restore may land on the same authenticated placeholder used in slice `#2`
- the placeholder must not be mistaken for the real home shell or chat list

#### Depends On Prior Slice Outputs

- slice `#1` app shell and startup routing
- slice `#2` demo login flow

#### Slice Pass Criteria

- relaunch with a valid local session lands in the authenticated placeholder without exposing broken intermediate states
- invalid or missing session falls back to login cleanly
- restore does not introduce the real home shell or chat list early

### Slice #4: Home shell and chat list

#### Allowed In This Slice

- Telegram-like home shell
- visible `Chats`, `Contacts`, and `Settings` tabs
- `Chats` as the default active tab
- chat list rows and metadata
- lightweight `Contacts` surface with search, quick actions, and alphabetical sections
- simplified `Settings` surface with profile summary and grouped entries
- loading, empty, and error states
- stable list scrolling

#### Must Not Be Implemented Yet

- chat detail
- composer
- local send flow
- real contacts sync or editing flows
- deep settings detail pages

#### Temporary Placeholder Allowed

- `Contacts` and `Settings` may remain shallow first-level destinations without full drill-down behavior
- shallow destinations must still render concrete structured content and must not appear broken

#### Depends On Prior Slice Outputs

- slice `#1` app shell and startup routing
- slice `#2` demo login flow
- slice `#3` session restore

#### Slice Pass Criteria

- login and restore now land in the real home shell with `Chats` active
- the home shell visibly includes `Chats`, `Contacts`, and `Settings`
- `Contacts` exposes search, quick actions, and an alphabetical contact list that feels close to Telegram
- `Settings` exposes a compact grouped settings home with profile summary and a visible `Sign out` affordance
- the chat list meets the required metadata, state, and scrolling quality bar

### Slice #5: Chat detail

#### Allowed In This Slice

- chat detail entry from the existing chat list
- top bar with back navigation and conversation title
- message history rendering
- incoming and outgoing bubbles
- date separators
- stable scrolling for the shared seed conversation

#### Must Not Be Implemented Yet

- local text send flow
- editable composer behavior
- attachments, stickers, or voice notes
- remote delivery receipts

#### Temporary Placeholder Allowed

- a non-interactive composer shell may exist to preserve the intended layout
- the shell must not allow sending or local message append

#### Depends On Prior Slice Outputs

- slices `#1` through `#4`

#### Slice Pass Criteria

- the user can open the shared seed conversation from the chat list
- the conversation looks believable for a commercial messaging app
- incoming and outgoing messages are visually distinct and grouped coherently
- if a composer shell is present, it is clearly inactive and cannot send

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
- local send may remain local-only and must not pretend to contact a real backend

#### Depends On Prior Slice Outputs

- slices `#1` through `#5`

#### Slice Pass Criteria

- sending a local text message works from chat detail
- the local message appears immediately and settles into a stable state
- the composer clears after success
- any failure state remains recoverable without leaving the conversation broken

## Acceptance Scenario 1: First Launch Routes To Login

### Preconditions

- no valid local session exists

### Steps

1. Launch the app.
2. Wait for initial loading to finish.

### Pass Criteria

- the app lands on the login flow
- the user can see separate country and phone inputs plus a primary login CTA
- the screen does not look like a developer placeholder or raw scaffold

## Acceptance Scenario 2: Demo Login Enters The Product

### Preconditions

- app is on the login flow

### Steps

1. Enter a demo phone number.
2. Continue through the verification step.
3. Complete login with the supported demo path.

### Pass Criteria

- the flow is understandable without developer knowledge
- invalid or incomplete input is handled with clear feedback
- successful completion routes the user into the home shell with the chat list tab active

## Acceptance Scenario 3: Session Restore Skips Login

### Preconditions

- a valid local session exists from a prior successful login

### Steps

1. Force close the app.
2. Reopen the app.

### Pass Criteria

- the app restores the session without requiring another login
- the user lands on the home shell with the chat list tab active
- the transition does not expose broken intermediate states

## Acceptance Scenario 4: Home Shell Feels Telegram-Like

### Preconditions

- user is authenticated

### Steps

1. Land on the home shell.
2. Inspect the primary tabs.
3. Confirm the chat list tab is the default active tab.

### Pass Criteria

- the home shell visibly includes `Chats`, `Contacts`, and `Settings`
- the navigation presence feels close to a real Telegram-like app rather than a single-screen prototype
- `Chats` is the default active destination after login and restore
- `Contacts` and `Settings` do not need deep inner functionality in the MVP, but they must look like intentional first-level destinations rather than placeholders

## Acceptance Scenario 5: Contacts Feels Telegram-Like

### Preconditions

- user is authenticated
- home shell is visible

### Steps

1. Switch to the `Contacts` tab.
2. Inspect the top of the page.
3. Inspect the quick actions and the contact list.

### Pass Criteria

- the screen shows a `Contacts` title and a visible search field
- the screen shows lightweight quick actions such as `Add Contact`, `People Nearby`, and `Invite Friends`
- the main content is an alphabetical contact list rather than a centered placeholder card
- contact rows use person-oriented metadata such as presence or last-seen status, not chat-list snippets or unread badges

## Acceptance Scenario 6: Settings Feels Like A Real First-Level Destination

### Preconditions

- user is authenticated
- home shell is visible

### Steps

1. Switch to the `Settings` tab.
2. Inspect the profile summary area.
3. Inspect the grouped settings sections.

### Pass Criteria

- the screen shows a compact profile summary near the top
- the settings content is organized into grouped sections such as `Account`, `Preferences`, and `Session`
- the screen stays intentionally lightweight and does not require deep drill-down pages to feel complete
- a visible `Sign out` affordance exists and reads as the destructive action on the page

## Acceptance Scenario 7: Chat List Feels Telegram-Like

### Preconditions

- user is authenticated
- home shell is visible with the chat list tab active

### Steps

1. Inspect multiple chat rows.
2. Scroll through the list.

### Pass Criteria

- each row shows avatar, title, last-message snippet, timestamp, and unread state
- the list density and hierarchy feel close to a Telegram-like commercial app
- loading, empty, and error states are coherent and usable
- scrolling is stable and does not visibly degrade core usability

## Acceptance Scenario 8: Opening Chat Shows A Credible Conversation

### Preconditions

- chat list is visible

### Steps

1. Open a conversation from the list.
2. Inspect the message history.

### Pass Criteria

- incoming and outgoing messages are visually distinct
- date separators and delivery-state cues are shown where relevant
- the conversation is believable as a commercial messaging app, not a mock debug screen

## Acceptance Scenario 9: Sending A Local Text Message Works

### Preconditions

- chat detail is visible

### Steps

1. Type a text message.
2. Tap send.

### Pass Criteria

- the message appears in the conversation immediately
- the local sending state transitions to a stable sent state
- the composer clears after success
- the interaction feels responsive and not obviously broken

## Cross-Framework Acceptance Rule

- the same scenario set applies to `CJMP`, `KMP`, and `flutter`
- if one framework deviates, the difference must be recorded in the relevant framework round log and later reflected in `reports/comparison/telegram-commercial-mvp-comparison-overview.md`
- use the slice acceptance contracts above to prevent early implementation of later slices

## Rejection Conditions

- the flow works only with developer shortcuts that are not part of the user-facing path
- UI quality is too low to support a credible Telegram-like demo
- one framework silently drops part of the slice without recording the gap
