---
name: android-emulator-deploy-run
description: Use when you need a shared Android emulator or device helper to inspect tools and devices, boot or reuse an emulator, install or uninstall an APK, deploy and run an app, stop or clear app state, inspect logs, or shut down emulators before debugging or acceptance.
---

# Android Emulator Deploy Run

Use the bundled helper:

```bash
python3 .agents/skills/android-emulator-deploy-run/scripts/android_emulator_runtime.py doctor
```

This skill is the canonical name for the shared Android deploy/run helper.
It is intended to work as a normal user-space Android SDK and `adb` helper,
without requiring a repo-specific privilege model in the committed skill
contract.

Core commands:

- `doctor`
- `devices`
- `list-avds`
- `boot`
- `install`
- `deploy`
- `run`
- `uninstall`
- `stop-app`
- `clear-data`
- `shutdown`
- `logs`

Compatibility aliases:

- `install-apk` for `install`
- `start-app` for `run`
