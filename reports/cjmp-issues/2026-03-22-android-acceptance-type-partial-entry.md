# Android acceptance type action only partially enters digits into Flutter phone field

- issue: `#36`
- date: `2026-03-22`
- affected round: Flutter requirement `#22` post-merge acceptance
- category: shared acceptance-tooling friction

## What happened

The shared Android emulator acceptance path could not complete the valid login scenario for Flutter requirement `#22` because the `android_acceptance.py type` command only entered a partial value into the Flutter phone field.

Commands used:

```bash
python3 .agents/skills/android-emulator-acceptance/scripts/android_acceptance.py tap --class-name android.widget.EditText --wait-seconds 1
python3 .agents/skills/android-emulator-acceptance/scripts/android_acceptance.py type --value 14155550199
python3 .agents/skills/android-emulator-acceptance/scripts/android_acceptance.py dump-ui --out .cache/android-acceptance/issue22-digits-entered.xml
```

The resulting UI dump showed `text="141"` for the `android.widget.EditText` instead of the full `14155550199`.

## Why it matters

- blocked runtime verification of the successful login-to-placeholder handoff
- weakened acceptance confidence without proving a product bug
- may affect other lanes whenever reliable text entry is required in emulator-driven acceptance

## Evidence

- `/Users/haifengsong/code-base/telegram/TelegramAIDev/.cache/android-acceptance/issue22-digits-entered.xml`
- `/Users/haifengsong/code-base/telegram/TelegramAIDev/.cache/android-acceptance/issue22-digits-entered.png`
- `/Users/haifengsong/code-base/telegram/TelegramAIDev/.cache/android-acceptance/issue22-after-digits-continue.xml`

## Suggested follow-up

Improve the shared Android acceptance typing path so full text entry into app fields is deterministic and observable during acceptance rounds.
