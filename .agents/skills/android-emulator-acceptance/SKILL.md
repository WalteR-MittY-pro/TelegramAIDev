---
name: android-emulator-acceptance
description: Use when acceptance should run on an Android emulator instead of iOS, especially for scenario-driven validation with adb, screenshots, simulated touch, and UI hierarchy dumps across CJMP, KMP, and flutter lanes.
---

# Android Emulator Acceptance

Use this skill for shared runtime acceptance on Android when the iOS path is slower, harder to automate, or weaker for evidence capture.

This skill is intentionally repo-shared and framework-agnostic:

- use lane-specific tooling only to build the app
- use `android-emulator-runtime` to boot the emulator, install the APK, and start the app
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
separate `android-emulator-runtime` skill first. This skill is for acceptance
interaction after runtime setup is done.

## Sandbox profile

This repo now includes one shared Codex profile for Android acceptance:

```bash
codex --profile android_acceptance_min
```

Use `android_acceptance_min` first. It keeps `workspace-write` and only adds
generic sandbox settings in repo config:

- `sandbox_mode = "workspace-write"`
- `approval_policy = "never"`
- sandboxed network access enabled

It also enables sandboxed network access for commands that need it. The narrow
outside-sandbox exception lives in the runtime skill's repo-scoped execpolicy rule:

```bash
python3 .agents/skills/android-emulator-runtime/scripts/android_emulator_runtime.py boot --headless
```

That boot command is the only documented Android launch path that should be
allowlisted outside the sandbox. Keep the allowlist scoped to the helper's
`boot` subcommand, not the whole script.

Keep host-specific Android paths out of committed repo config. If your local
workflow needs extra writable roots such as the Android SDK directory or
Android user state directories, add them per machine:

```bash
codex --profile android_acceptance_min \
  --add-dir "$ANDROID_HOME" \
  --add-dir "$HOME/.android"
```

Or put the same machine-specific roots in your user-level
`~/.codex/config.toml`, not in this repository's `.codex/config.toml`.

Real-world note from this repo: `adb`-level interaction can work under the
minimal profile, but emulator boot itself may still fail under macOS sandboxing.
So split the workflow like this when you want the least privilege:

1. start a fresh Codex session so `.codex/rules/android-emulator.rules` is loaded
2. use `android-emulator-runtime` to boot the emulator, install the APK, and start the app
3. use this skill from `android_acceptance_min` for `dump-ui`, `find`, `tap`,
   `type`, `keyevent`, `swipe`, `screenshot`, and other `adb`-driven checks

If the boot command is still blocked in your environment, fall back to this split:

1. launch the emulator outside Codex, or from a separate full-access Codex session
2. use this skill from `android_acceptance_min` for `dump-ui`, `find`, `tap`,
   `type`, `keyevent`, `swipe`, `screenshot`, and other `adb`-driven checks

The intended order is:

1. `codex --profile android_acceptance_min`
2. if the allowlisted boot command still cannot boot the emulator, either:
   - launch the emulator outside Codex first, or
   - define a personal full-access fallback in `~/.codex/config.toml`, not in the shared repo config

Important limit: changing `.codex/config.toml` affects future Codex sessions that load the repo config. It does not retroactively widen the sandbox of a session that is already running under tighter outer restrictions.

## Recommended workflow

1. Discover the target lane and how the app is launched on Android.
   - `flutter`: prefer lane tooling or Dart MCP for launch, then use this skill for acceptance interaction.
   - `CJMP` and `KMP`: discover the Android build and launch command from the app before proceeding.
2. Start metrics tracking if this is a real acceptance round.
3. Run:

```bash
python3 .agents/skills/android-emulator-runtime/scripts/android_emulator_runtime.py doctor
python3 .agents/skills/android-emulator-runtime/scripts/android_emulator_runtime.py boot --avd Pixel_3a_API_34
python3 .agents/skills/android-emulator-runtime/scripts/android_emulator_runtime.py install-apk --apk path/to/app-debug.apk
python3 .agents/skills/android-emulator-runtime/scripts/android_emulator_runtime.py start-app --apk path/to/app-debug.apk
```

4. Confirm the app is already running on the emulator.
5. Drive the scenario with `tap`, `type`, `keyevent`, `swipe`, `find`, and `dump-ui`.
6. Capture screenshots for important pass or fail evidence.
7. Record the outcome in the issue and comparison artifacts.

## Fast-path commands

For boot, install, and app launch commands, use `android-emulator-runtime`.
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
