# Telegram Commercial MVP Issue Breakdown

## Source Artifacts

- requirement: `docs/requirements/telegram-commercial-mvp.md`
- acceptance: `docs/acceptance/telegram-commercial-mvp.md`
- design: `docs/design/telegram-commercial-mvp.md`
- shared design assets: `docs/design/telegram-commercial-mvp-shared-assets.md`

Issue-by-issue implementation of slices `#1` through `#4` must follow the slice delivery contracts in the linked requirement, acceptance, and design artifacts.

## Requirement Issues

1. App shell and startup routing across `CJMP`, `KMP`, and `flutter`
2. Demo login flow across `CJMP`, `KMP`, and `flutter`
3. Session restore across `CJMP`, `KMP`, and `flutter`
4. Home shell and chat list core experience across `CJMP`, `KMP`, and `flutter`
5. Chat detail core conversation experience across `CJMP`, `KMP`, and `flutter`
6. Composer and local message send across `CJMP`, `KMP`, and `flutter`

## Labeling

- all issues above use the `requirement` label
- confirmed AI delivery friction discovered during implementation should become separate `ai-efficiency` issues
