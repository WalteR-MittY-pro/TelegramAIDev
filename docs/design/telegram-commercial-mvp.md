# Telegram Commercial MVP Design

## Scope

Framework-agnostic UI and interaction design for the Telegram-like commercial MVP.

Related requirement: `docs/requirements/telegram-commercial-mvp.md`
Related acceptance: `docs/acceptance/telegram-commercial-mvp.md`

## Figma Status

- Figma artifact: pending
- local `docs/design/figma-source/index.html` mirrors the approved early login shell for slices `#1` and `#2`, but this document remains the canonical framework-agnostic design contract
- Until the Figma file is created, this document is the source of truth for framework-agnostic design decisions.

## Shared Design Asset Contract

- shared asset spec: `docs/design/telegram-commercial-mvp-shared-assets.md`
- canonical shared asset source: `shared/design/telegram-commercial-mvp/`
- framework apps must copy required shared assets into their own local app asset paths before runtime use
- framework apps must not load runtime assets directly from the shared source directory
- if a required shared asset is missing, implementations must stop and surface the gap instead of inventing a local replacement

The existing startup or login-only JSON catalog pattern is not sufficient as the full shared design asset layer.
The canonical shared asset contract now includes tokens, shared copy, shared mock data, and placeholder resources.

## Product Structure

- Launch / restore gate
- Login flow
- Home shell
- Chat list
- Chat detail

## Slice Design Contracts

### Slice #1: App shell and startup routing

#### Allowed In This Slice

- startup loading gate
- login handoff state
- startup failure state
- minimal route structure needed for authenticated and unauthenticated destinations
- shared assets limited to the startup and login subset

#### Must Not Be Implemented Yet

- demo verification UI
- persistent session behavior
- real home shell
- real chat list surface
- chat rows

#### Temporary Placeholder Allowed

- a minimal authenticated placeholder screen may exist if the route structure requires it
- the placeholder must not borrow the home shell tabs or chat list composition

#### Depends On Prior Slice Outputs

- shared design tokens
- shared startup and login copy
- shared startup and login mock data

### Slice #2: Demo login flow

#### Allowed In This Slice

- phone entry UI
- verification step UI
- validation and failure states
- authenticated handoff into the existing placeholder destination

#### Must Not Be Implemented Yet

- session persistence
- session restore
- real home shell
- real chat list

#### Temporary Placeholder Allowed

- continue to use the authenticated placeholder from slice `#1`

#### Depends On Prior Slice Outputs

- slice `#1` route structure and placeholder destination
- shared startup and login copy
- shared startup and login mock data

#### Approved Early Login Shell Visual Contract

- center the Telegram paper-plane badge and `Telegram` wordmark above the form
- use a soft gray-white background with clean white input surfaces instead of a heavy card-within-card treatment
- keep the default login state minimal:
  - no dense support copy on the main slice `#1` shell
  - concise supporting copy is reserved for slice `#2` verification or validation states
- use two separate rounded inputs with left-aligned content:
  - `Country / Region` with `China` as the visible value and a dropdown affordance
  - `Phone number` with `+86` as the visible value
- include an interactive `Keep me signed in on this device` control directly below the inputs
- treat framework-specific smoke or test-entry controls as implementation-only; they are not part of the canonical shared product design

### Slice #3: Session restore

#### Allowed In This Slice

- persistence and restore state wiring
- login fallback state
- restore-time loading and failure messaging

#### Must Not Be Implemented Yet

- real home shell
- real chat list
- chat detail
- composer

#### Temporary Placeholder Allowed

- restore may still land on the authenticated placeholder until slice `#4` ships

#### Depends On Prior Slice Outputs

- slice `#1` route structure
- slice `#2` authenticated placeholder and login handoff
- shared startup and login copy

### Slice #4: Home shell and chat list

#### Allowed In This Slice

- real home shell
- `Chats`, `Contacts`, and `Settings` tabs
- shared home shell tab metadata
- lightweight `Contacts` surface with search, quick actions, and alphabetical contact grouping
- simplified `Settings` surface with profile summary and grouped entry sections
- chat list rows and state surfaces
- chat list mock data and placeholder avatar resources

#### Must Not Be Implemented Yet

- chat detail
- composer
- local send flow
- real contacts sync or edit flows
- deep settings detail pages or nested settings stacks

#### Temporary Placeholder Allowed

- `Contacts` and `Settings` may remain shallow first-level destinations
- shallow destinations must use shared copy and tokens and render concrete grouped-list content instead of centered placeholder cards

#### Depends On Prior Slice Outputs

- slices `#1` through `#3`
- shared design tokens
- shared home shell copy and tab metadata
- shared chat list mock data
- shared placeholder resources

### Slice #5: Chat detail

#### Allowed In This Slice

- chat detail route and conversation selection handoff
- top bar with title and back navigation
- shared seed conversation history
- incoming and outgoing bubble styles
- date separators
- shared placeholder avatar resources where needed

#### Must Not Be Implemented Yet

- interactive text composer behavior
- local message append
- attachments, stickers, or voice notes
- remote sync or delivery receipts

#### Temporary Placeholder Allowed

- a non-interactive composer shell may be shown to preserve the intended layout
- if shown, it must use shared copy and tokens and remain inactive

#### Depends On Prior Slice Outputs

- slices `#1` through `#4`
- shared chat detail copy
- shared chat detail mock data
- shared placeholder resources

### Slice #6: Composer and local message send

#### Allowed In This Slice

- text composer field
- send action
- local message append using shared local-send behavior metadata
- pending, sent, and failure states for the local-only send path
- composer clear-on-success behavior

#### Must Not Be Implemented Yet

- remote delivery receipts
- non-text composer actions as real features
- media gallery or advanced message actions

#### Temporary Placeholder Allowed

- non-text composer affordances may remain absent or inert
- the local send path may remain fully local-only

#### Depends On Prior Slice Outputs

- slices `#1` through `#5`
- shared chat detail copy
- shared chat detail mock data, including local-send behavior metadata

## Screen Inventory

### Launch / Restore

- brief loading state while checking session
- route to login if no valid session
- route to the home shell with the `Chats` tab active if session is valid

### Login

- centered Telegram logo mark and wordmark
- sparse default state without long explanatory copy on slice `#1`
- separate `Country / Region` and `Phone number` inputs with left-aligned values
- interactive keep-signed-in control
- primary login CTA
- lightweight verification step for demo entry
- inline validation and failure messaging
- framework-specific smoke or test-entry affordances are excluded from the canonical product design

### Home Shell

- top-level navigation shell that feels close to Telegram information architecture
- `Chats` tab
- `Contacts` tab
- `Settings` tab
- `Chats` is the default active tab after login and session restore
- `Contacts` and `Settings` should feel like real first-level destinations, even if they stop at one level deep in the MVP

### Contacts

- top app bar with `Contacts` title and a lightweight add action
- search field directly below the app bar
- grouped quick-action list with:
  - `Add Contact`
  - `People Nearby`
  - `Invite Friends`
- alphabetical contact sections using one or a few rows per letter group
- each row includes:
  - avatar
  - name
  - lightweight presence or last-seen status
- avoid chat-list affordances such as unread badges, pinned states, or message snippets

### Settings

- profile summary card at the top of the screen
- grouped list sections with restrained copy and simple disclosure affordances
- compact section set for the MVP:
  - `Account`
  - `Preferences`
  - `Session`
- `Account` should feel Telegram-like and may include `Devices`, `Privacy and Security`, and `Notifications and Sounds`
- `Preferences` should stay short and may include `Appearance`, `Language`, and `Chat Folders`
- `Session` should expose a clear `Sign out` affordance without requiring deeper settings detail pages

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

### Contacts

- populated grouped list
- search field present
- quick actions visible

### Settings

- populated grouped list
- session-present summary card
- destructive sign-out affordance visible

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
- keep `Contacts` and `Settings` visually closer to Telegram's grouped-list rhythm than to a dashboard card grid
- let `Contacts` feel slightly denser and more list-like than `Chats`
- keep `Settings` more restrained than `Contacts`, with fewer subtitles and less visual noise
- keep touch targets production-credible on mobile

## Design Rules

- stay framework-agnostic
- do not leak framework-specific state containers or architectural decisions into the UI spec
- prefer reusable structural components across all three frameworks
- define the major states that materially affect implementation complexity and acceptance
- do not treat framework-local assets as acceptable substitutes for missing shared design assets

## Figma Follow-Up

When the Figma file is created, it should include at least:

1. login
2. login validation state
3. login verification step
4. chat list default state
5. home shell with visible `Chats`, `Contacts`, and `Settings` tabs
6. contacts grouped-list screen with search and quick actions
7. settings grouped-list screen with profile summary and simplified sections
8. chat list loading or empty state
9. chat detail default state
10. chat detail send-pending state
