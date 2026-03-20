---
name: android-emulator-acceptance
description: Use when acceptance should run on an Android emulator instead of iOS, especially for scenario-driven validation with adb, screenshots, simulated touch, and UI hierarchy dumps across CJMP, KMP, and flutter lanes.
---

# Android Emulator Acceptance

Use this skill for shared runtime acceptance on Android when the iOS path is slower, harder to automate, or weaker for evidence capture.

This skill is intentionally repo-shared and framework-agnostic:

- use lane-specific tooling only to build the app
- use `android-emulator-deploy-run` to boot the emulator, install the APK, and start the app
- use Android emulator plus `adb` for the actual acceptance interaction and evidence
- keep acceptance scenario-driven and tied to the requirement, design, and acceptance docs

## Why this is the default shared path

For this repo, the lowest-overhead acceptance loop is:

1. boot or reuse an Android emulator
2. launch the target app on that emulator
3. drive the app with `adb shell input`
4. inspect the current UI with `uiautomator dump`
5. capture evidence with `screencap`

This works across `CJMP`, `KMP`, and `flutter` without introducing a separate acceptance framework per lane.

Do not default to Appium, Maestro, or per-app UI test harnesses unless the acceptance surface has become stable enough that the extra maintenance cost is justified.

## Required repo workflow

For a real acceptance round, follow the existing acceptance policy:

1. Read the relevant requirement, design, and acceptance artifacts first.
2. Use `delivery-run-metrics` before substantive acceptance work starts.
3. Run scenario-driven runtime validation.
4. Capture evidence for meaningful observations.
5. File or update `bug` issues for failed scenarios.
6. Update the framework-specific round log under `reports/comparison/`.
7. Run `ai-efficiency-friction-check` before closing the round.

This skill helps with runtime interaction and evidence capture. It does not replace the repo's acceptance process.

## When to use this skill

- a user explicitly asks to do acceptance on Android emulator
- iOS simulator acceptance is slower or less reliable for the current task
- you need a shared acceptance path across `CJMP`, `KMP`, and `flutter`
- you need repeatable screenshot, tap, swipe, or text-input actions from the terminal
- you need to inspect current UI state without guessing raw coordinates

## Tooling choice

Prefer the bundled script:

```bash
python3 .agents/skills/android-emulator-acceptance/scripts/android_acceptance.py doctor
```

The script wraps the repetitive parts:

- discover `adb`, the modern Android emulator binary, connected devices, and available AVDs
- reuse the runtime helper's workspace-local AVD preference and workspace-local datadir defaults
- boot or reuse an emulator and wait for Android to finish booting
- optionally disable animations on the emulator for faster, less flaky acceptance
- dump the current UI hierarchy
- find elements by text, content description, or resource id
- tap a matched element by its computed center point
- type text, send key events, swipe, and capture screenshots

If you need to boot the emulator, install the APK, or start the app, use the
separate `android-emulator-deploy-run` skill first. This skill is for acceptance
interaction after runtime setup is done.

## Sandbox profile

For this repo, `android_acceptance_min` is still a useful default shell for
acceptance interaction:

```bash
codex --profile android_acceptance_min
```

Use the profile when it helps keep the acceptance session narrow, but do not
treat it as a requirement of `android-emulator-deploy-run`. The deploy/run
helper is designed for normal user access and should not rely on a repo-specific
privilege model as part of its contract.

Keep host-specific Android paths out of committed repo config. If your local
workflow needs extra writable roots such as the Android SDK directory or
Android user state directories, add them per machine or in your user-level
`~/.codex/config.toml`, not in this repository's `.codex/config.toml`.

## Recommended workflow

1. Discover the target lane and how the app is launched on Android.
   - `flutter`: prefer lane tooling or Dart MCP for launch, then use this skill for acceptance interaction.
   - `CJMP` and `KMP`: discover the Android build and launch command from the app before proceeding.
2. Start metrics tracking if this is a real acceptance round.
3. Run:

```bash
python3 .agents/skills/android-emulator-deploy-run/scripts/android_emulator_runtime.py doctor
python3 .agents/skills/android-emulator-deploy-run/scripts/android_emulator_runtime.py boot --avd Pixel_3a_API_34
python3 .agents/skills/android-emulator-deploy-run/scripts/android_emulator_runtime.py deploy --apk path/to/app-debug.apk
```

4. Confirm the app is already running on the emulator.
5. Drive the scenario with `tap`, `type`, `keyevent`, `swipe`, `find`, and `dump-ui`.
6. Capture screenshots for important pass or fail evidence.
7. Record the outcome in the issue and comparison artifacts.

## Fast-path commands

For boot, install, and app launch commands, use `android-emulator-deploy-run`.
This skill's fast path starts after the app is already running on the device.

Inspect the current UI and persist the raw XML:

```bash
python3 .agents/skills/android-emulator-acceptance/scripts/android_acceptance.py dump-ui --out .cache/android-acceptance/current-ui.xml
```

Find a primary CTA before tapping it:

```bash
python3 .agents/skills/android-emulator-acceptance/scripts/android_acceptance.py find --text-contains Continue
python3 .agents/skills/android-emulator-acceptance/scripts/android_acceptance.py tap --text-contains Continue --wait-seconds 10
```

Enter a demo phone number and submit:

```bash
python3 .agents/skills/android-emulator-acceptance/scripts/android_acceptance.py type --value 15551234567
python3 .agents/skills/android-emulator-acceptance/scripts/android_acceptance.py keyevent --key KEYCODE_ENTER
```

Capture evidence:

```bash
python3 .agents/skills/android-emulator-acceptance/scripts/android_acceptance.py screenshot --out .cache/android-acceptance/login-step.png
```

## Practical guidance

- Prefer matching by resource id when the app exposes one.
- Use text or content-description matching when resource ids are missing.
- Do not rely on handwritten coordinates unless the UI is stable and no better selector exists.
- When a selector returns multiple matches, refine it instead of tapping an arbitrary result.
- Keep one dedicated emulator AVD for acceptance work so animation settings, login state, and debugging tools do not pollute daily development devices.
- Prefer a workspace-local AVD home under `.cache/android-avd-home/avd` so acceptance state stays inside the repo.
- Reuse a running emulator when possible. Emulator boot is usually slower than the actual acceptance interaction.
- Use a clean start only when the scenario explicitly requires it.

## Escalation guidance

Escalate beyond this skill only when the basic `adb` path is not enough:

- use lane-specific framework tooling to launch or rebuild the app
- use richer framework-specific inspection only when it materially improves the round
- consider a heavier automation framework only if the same scenario is being rerun often enough to justify its setup and maintenance cost

For this repo, the shared baseline remains Android emulator plus `adb`.
