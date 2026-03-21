# Telegram Commercial MVP Design

## Scope

Framework-agnostic UI and interaction design for the Telegram-like commercial MVP.

Related requirement: `docs/requirements/telegram-commercial-mvp.md`
Related acceptance: `docs/acceptance/telegram-commercial-mvp.md`

## Figma Status

- Figma artifact: pending
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
- chat list rows and state surfaces
- chat list mock data and placeholder avatar resources

#### Must Not Be Implemented Yet

- chat detail
- composer
- local send flow

#### Temporary Placeholder Allowed

- `Contacts` and `Settings` destinations may remain placeholders
- placeholders must still use shared copy and tokens

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
- do not treat framework-local assets as acceptable substitutes for missing shared design assets

## Figma Follow-Up

When the Figma file is created, it should include at least:

1. login
2. login validation state
3. chat list default state
4. home shell with visible `Chats`, `Contacts`, and `Settings` tabs
5. chat list loading or empty state
6. chat detail default state
7. chat detail send-pending state
