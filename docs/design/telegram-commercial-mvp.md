# Telegram Commercial MVP Design

## Scope

Framework-agnostic UI and interaction design for the Telegram-like commercial MVP.

Related requirement: `docs/requirements/telegram-commercial-mvp.md`
Related acceptance: `docs/acceptance/telegram-commercial-mvp.md`

## Figma Status

- Figma artifact: capture started, final file generation still pending browser-side submission
- Figma HTML source board: `docs/design/figma-source/index.html`
- Shared icon assets: `docs/design/assets/icons/`
- Shared mock data: `docs/design/assets/mock-data.json`
- Until the Figma file is fully generated, this document, the HTML source board, the shared icon assets, and the shared mock data are the source of truth for framework-agnostic design decisions.

## Shared Design Resources

- `docs/design/figma-source/index.html`: screen inventory and layout source board
- `docs/design/assets/icons/`: canonical SVG icon source for all framework lanes
- `docs/design/assets/mock-data.json`: canonical demo content and UI-state sample data for all framework lanes
- `docs/design/assets/README.md`: usage contract for shared design assets

All three framework lanes should consume these shared resources directly instead of recreating near-duplicate design assets or demo content locally.

## Product Structure

- Launch / restore gate
- Login flow
- Home shell
- Chat list
- Chat detail

## Screen Inventory

### Launch / Restore

- brief loading state while checking session
- route to login if no valid session
- route to the home shell with the `Chats` tab active if session is valid

### Login

- title and short explanatory text
- phone input
- primary continue CTA
- lightweight verification step for demo entry
- inline validation and failure messaging

### Home Shell

- top-level navigation shell that feels close to Telegram information architecture
- `Chats` tab
- `Contacts` tab
- `Settings` tab
- `Chats` is the default active tab after login and session restore
- `Contacts` and `Settings` may be placeholder destinations in the MVP, but they must exist in the shell and look intentional

### Chat List

- top app bar with product title and primary actions
- vertically scrolling conversation list
- each row includes:
  - avatar
  - conversation title
  - last message snippet
  - timestamp
  - unread badge when needed
  - pinned / muted cues where relevant

### Chat Detail

- top bar with conversation title and back navigation
- scrollable message history
- incoming and outgoing bubbles
- date separators
- composer with text input and send action

## Interaction States

### Global

- initial loading
- recoverable error

### Login

- empty input
- invalid input
- submitting
- verification success
- verification failure

### Chat List

- home shell with tabs visible
- loading
- populated list
- empty list
- load failure

### Chat Detail

- loading conversation
- populated conversation
- local send pending
- local send complete
- recoverable send failure

## Visual Direction

- aim for a Telegram-like hierarchy rather than a minimal debug dashboard
- avoid presenting the product as only a chat list page; the home shell should communicate a broader Telegram-like product surface
- prioritize readable density, clear timestamps, legible snippets, and familiar chat affordances
- use a restrained accent color and neutral surfaces
- keep touch targets production-credible on mobile

## Design Rules

- stay framework-agnostic
- do not leak framework-specific state containers or architectural decisions into the UI spec
- prefer reusable structural components across all three frameworks
- define the major states that materially affect implementation complexity and acceptance

## Figma Follow-Up

When the Figma file is created, it should include at least:

1. login
2. login validation state
3. chat list default state
4. home shell with visible `Chats`, `Contacts`, and `Settings` tabs
5. chat list loading or empty state
6. chat detail default state
7. chat detail send-pending state
