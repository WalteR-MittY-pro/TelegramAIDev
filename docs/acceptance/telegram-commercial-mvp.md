# Telegram Commercial MVP Acceptance

## Scope

This document defines the acceptance scenarios for the Telegram-like commercial MVP.

Related requirement: `docs/requirements/telegram-commercial-mvp.md`
Related design: `docs/design/telegram-commercial-mvp.md`
Related design source board: `docs/design/figma-source/index.html`
Related shared icon assets: `docs/design/assets/icons/`
Related shared mock data: `docs/design/assets/mock-data.json`

## Acceptance Scenario 1: First Launch Routes To Login

### Preconditions

- no valid local session exists

### Steps

1. Launch the app.
2. Wait for initial loading to finish.

### Pass Criteria

- the app lands on the login flow
- the user can see a primary CTA to continue
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
- `Contacts` and `Settings` do not need full inner functionality in the MVP, but their presence must not look broken or accidental

## Acceptance Scenario 5: Chat List Feels Telegram-Like

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

## Acceptance Scenario 6: Opening Chat Shows A Credible Conversation

### Preconditions

- chat list is visible

### Steps

1. Open a conversation from the list.
2. Inspect the message history.

### Pass Criteria

- incoming and outgoing messages are visually distinct
- date separators and delivery-state cues are shown where relevant
- the conversation is believable as a commercial messaging app, not a mock debug screen

## Acceptance Scenario 7: Sending A Local Text Message Works

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
- acceptance should validate against the shared design resource set, not against framework-local restatements of the same UI assets or demo content
- if one framework deviates, the difference must be recorded in the relevant framework round log and later reflected in `reports/comparison/telegram-commercial-mvp-comparison-overview.md`

## Rejection Conditions

- the flow works only with developer shortcuts that are not part of the user-facing path
- UI quality is too low to support a credible Telegram-like demo
- one framework silently drops part of the slice without recording the gap
