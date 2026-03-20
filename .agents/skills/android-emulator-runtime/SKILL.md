---
name: android-emulator-runtime
description: Use when you need to boot or reuse an Android emulator, install an APK, and launch an Android app on an emulator or connected Android device before acceptance, debugging, or manual verification across CJMP, KMP, and flutter lanes.
---

# Android Emulator Runtime

Use this skill for Android runtime setup when the goal is to get an app running,
not to perform full acceptance.

This skill is intentionally repo-shared and framework-agnostic:

- boot or reuse an Android emulator
- install an APK on that emulator or another connected Android device
- launch the installed app from package name or APK metadata
- keep framework-specific build steps outside the skill

Use `android-emulator-acceptance` after this skill when the device is ready and
the task moves into UI validation, screenshots, and scenario-driven checks.

## When to use this skill

- a user explicitly asks to launch an Android emulator
- you need to install an APK on an emulator or Android device
- you need to start an Android app before debugging or acceptance
- you need one shared Android runtime path across `CJMP`, `KMP`, and `flutter`

## Tooling choice

Prefer the bundled script:

```bash
python3 .agents/skills/android-emulator-runtime/scripts/android_emulator_runtime.py doctor
```

The script wraps the repetitive runtime parts:

- discover `adb`, the modern Android emulator binary, available AVDs, and devices
- prefer a workspace-local AVD home when one exists under `.cache/android-avd-home/avd`
- place emulator writable runtime data under `.cache/android-avd-data` by default
- boot or reuse an emulator and wait for Android to finish booting
- optionally disable emulator animations after boot
- install an APK with replace semantics
- infer package name and launchable activity from APK metadata when available
- start an app by explicit activity or launcher fallback

## Sandbox profile

Use the shared repo profile first:

```bash
codex --profile android_acceptance_min
```

The narrow outside-sandbox exception is the repo-scoped boot command:

```bash
python3 .agents/skills/android-emulator-runtime/scripts/android_emulator_runtime.py boot --headless
```

Keep host-specific Android paths out of committed repo config. Add them per
machine if needed:

```bash
codex --profile android_acceptance_min \
  --add-dir "$ANDROID_HOME" \
  --add-dir "$HOME/.android"
```

Or put the same machine-specific roots in `~/.codex/config.toml`.

When this repo contains a workspace-local AVD under `.cache/android-avd-home/avd`,
the helper prefers that AVD home automatically. Even when the selected AVD
definition comes from a host path, the helper writes emulator runtime data under
`.cache/android-avd-data` by default so the writable state stays inside the repo.

## Recommended workflow

1. Build or locate the APK using lane-specific tooling.
2. Run:

```bash
python3 .agents/skills/android-emulator-runtime/scripts/android_emulator_runtime.py doctor
python3 .agents/skills/android-emulator-runtime/scripts/android_emulator_runtime.py boot --avd Pixel_3a_API_34
```

If you want a repo-local AVD instead of `~/.android/avd`, create it like this:

```bash
export ANDROID_EMULATOR_HOME="$PWD/.cache/android-avd-home"
export ANDROID_AVD_HOME="$PWD/.cache/android-avd-home/avd"
mkdir -p "$ANDROID_AVD_HOME"
avdmanager create avd -n Pixel_3a_API_34_Local -k 'system-images;android-34;google_apis;arm64-v8a' -d pixel_3a
```

3. Install the APK:

```bash
python3 .agents/skills/android-emulator-runtime/scripts/android_emulator_runtime.py install-apk --apk path/to/app-debug.apk
```

4. Start the app:

```bash
python3 .agents/skills/android-emulator-runtime/scripts/android_emulator_runtime.py start-app --apk path/to/app-debug.apk
```

5. If launch inference fails, rerun with explicit package or activity:

```bash
python3 .agents/skills/android-emulator-runtime/scripts/android_emulator_runtime.py start-app \
  --package org.example.app \
  --activity .MainActivity
```

## Fast-path commands

Boot or reuse the default emulator:

```bash
python3 .agents/skills/android-emulator-runtime/scripts/android_emulator_runtime.py boot
```

Headless boot:

```bash
python3 .agents/skills/android-emulator-runtime/scripts/android_emulator_runtime.py boot --headless
```

Install an APK and grant runtime permissions on install:

```bash
python3 .agents/skills/android-emulator-runtime/scripts/android_emulator_runtime.py install-apk \
  --apk path/to/app-debug.apk \
  --grant-all-permissions
```

Start an already installed app:

```bash
python3 .agents/skills/android-emulator-runtime/scripts/android_emulator_runtime.py start-app --package org.example.app
```

Start an app and force-stop it first:

```bash
python3 .agents/skills/android-emulator-runtime/scripts/android_emulator_runtime.py start-app \
  --package org.example.app \
  --stop-before-start
```

## Practical guidance

- Build the APK with framework-specific tooling before using this skill.
- Prefer `start-app --apk ...` when you want package and activity inference.
- Pass `--activity` when the app has multiple entry activities or inference fails.
- Reuse a running emulator when possible. Boot is usually slower than install and launch.
- Keep one dedicated workspace-local AVD for repo runtime and acceptance work to reduce noise.
- Use `android-emulator-acceptance` only after runtime setup is done.
