# CJMP Project Guidelines

## Purpose

This guide is for AI coding agents helping developers who use CJMP-SDK to build application projects.

Default stance:

- treat the current workspace as a CJMP SDK consumer project
- prioritize app developer workflows over framework maintainer workflows
- prefer the `keels` CLI over manually driving Gradle, DevEco, or Xcode

This guide is based on CJMP SDK `0.2.1`.

## Who This Guide Is For

| Audience | Typical Goal | Default Agent Stance |
| --- | --- | --- |
| `app` developer | Build a full CJMP application | Prioritize `create`, `build`, `run`, and device debugging |
| `module` developer | Build a reusable cross-platform UI module | Focus on packaging and integration outputs |
| `logic-module` developer | Build a reusable cross-platform logic package | Focus on shell type, packaging, and host integration |
| Framework maintainer | Investigate CJMP internals | Only switch to this mode if the user explicitly asks |

## Default Assistance Policy

When helping a developer, follow this order:

1. Identify the project type from `project.conf`.
2. Identify the target platform: Android, HarmonyOS, iOS device, or iOS simulator.
3. Prefer `keels doctor`, `keels devices`, `keels create`, `keels build`, and `keels run`.
4. Fall back to Gradle, `hvigor`, `adb`, `hdc`, `xcrun devicectl`, or `xcrun simctl` only when the issue is clearly platform-specific or the user already has a built artifact.
5. Only inspect `cjmp-ui`, `ui-engine`, or other SDK internals when the problem looks like linking, packaging, runtime dependency, or framework behavior.

## Recognizing Project Types

`project.conf` is the primary project identity file.

| Project Type | Key Fields | What It Means | Typical Layout |
| --- | --- | --- | --- |
| `app` | `type = app` | Full CJMP application | `android/`, `hos/`, `ios/`, `lib/`, `project.conf` |
| `module` | `type = module`, `packageName = ...` | Reusable cross-platform UI module | `android/`, `hos/`, `ios/`, `lib/`, `project.conf` |
| `logic-module` | `type = logic-module`, `packageName = ...`, optional `appType` | Reusable cross-platform logic package | Depends on `appType` |
| `logic-module` + `appType = keels` | same as above | Logic package with a keels-oriented shell | keels shell plus shared Cangjie sources |
| `logic-module` + `appType = native` | same as above | Logic package with native platform shells | native shells plus reusable `logic-module/` package directory |

Helpful interpretation rules:

- `app` projects do not use `appType`
- `logic-module` creation defaults to `--app-type keels` if the user does not specify one
- also inspect `lib/cjpm.toml` and platform folders such as `android/`, `hos/`, and `ios/`

## Environment Expectations

### Core Variables

| Variable | Purpose | Notes |
| --- | --- | --- |
| `CJMP_SDK_HOME` | CJMP SDK root | Recommended even though `keels` can often infer it |
| `JAVA_HOME` | Java runtime for Android-related tooling | JDK `17+` |
| `ANDROID_SDK_ROOT` | Android SDK root | Needed for Android builds and device tooling |
| `DEVECO_SDK_HOME` | DevEco SDK root | Used to resolve HarmonyOS helper tools |
| `IOS_SDK_DIR` | iPhoneOS SDK path | Relevant on macOS for iOS device builds |
| `IOS_SIM_SDK_DIR` | iPhoneSimulator SDK path | Relevant on macOS for simulator builds |

### Optional Variables

| Variable | Purpose |
| --- | --- |
| `HDC_SERVER` | Override HarmonyOS device server host |
| `HDC_SERVER_PORT` | Override HarmonyOS device server port |
| `ADB_SERVER_SOCKET` | Override Android adb server endpoint |
| `HTTP_PROXY` / `HTTPS_PROXY` / `NO_PROXY` | Network and dependency download setup |
| `OHOS_EMULATOR_HOME` | HarmonyOS emulator deployment path |
| `OHOS_IMAGE_HOME` | HarmonyOS emulator image path |

### Baseline Assumptions

| Item | Expected Value |
| --- | --- |
| Python | `3.8+` |
| JDK | `17+` |
| Android NDK | `26.3.11579264` |
| Android API | build tools around API 34, min app support at API 26 |
| HarmonyOS | `5.1.x` |
| iOS deployment target | `12.0+` |

### First Checks

```bash
keels doctor -v
keels devices
```

## Preferred Developer Workflow

### Create

| Goal | Command |
| --- | --- |
| Create app | `keels create --app <path>` |
| Create module | `keels create --module <path>` |
| Create logic-module | `keels create --logic-module <path>` |
| Create native-shell logic-module | `keels create --logic-module --app-type native <path>` |

Useful options:

- `-n`, `--name`
- `--org`
- `--ios-export-method debugging|release-testing|app-store|enterprise`

Important behavior:

- the parent directory of the target path must already exist
- project names must follow lowercase snake_case such as `[a-z_][a-z0-9_]*`
- `--app-type` is only valid with `--logic-module`

### Build

| Project Type | Package | Example Command |
| --- | --- | --- |
| `app` | `apk` | `keels build apk --platform android-arm64 --debug` |
| `app` | `hap` | `keels build hap --platform ohos-arm64 --debug` |
| `app` | `ios` | `keels build ios --platform ios-arm64 --debug` |
| `app` | `ios-sim` | `keels build ios-sim --platform ios-sim-arm64 --debug` |
| `app` | `ipa` | `keels build ipa --platform ios-arm64 --release` |
| `module` / `logic-module` | `aar` | `keels build aar --platform android-arm64 --debug` |
| `module` / `logic-module` | `har` | `keels build har --platform ohos-arm64 --debug` |
| `module` / `logic-module` | `framework` | `keels build framework --platform ios-arm64 --debug` |
| `module` / `logic-module` | `framework-sim` | `keels build framework-sim --platform ios-sim-arm64 --debug` |

Important behavior:

- `ios`, `ios-sim`, `ipa`, `framework`, and `framework-sim` are available on macOS only
- `keels` enforces package and project-type compatibility
- HarmonyOS builds use `ohpm` and `hvigor`
- Android builds use Gradle from the local project's `android/` directory
- iOS builds use `xcodebuild`

### Run

| Goal | Command |
| --- | --- |
| Run debug build on device | `keels run -d <device_id> --debug` |
| Run release build on device | `keels run -d <device_id> --release` |
| Run HarmonyOS with autosign | `keels run -d <device_id> --autosign` |

Important behavior:

- `keels run` triggers a build before install and launch
- Android deployment uses `adb`
- HarmonyOS deployment uses `hdc`
- iOS real-device deployment uses `xcrun devicectl`
- iOS simulator deployment uses `xcrun simctl`

### Devices And Emulators

| Goal | Command |
| --- | --- |
| List connected devices | `keels devices` |
| Filter by device id or name | `keels devices -d <device_id_or_name>` |
| List emulators | `keels emulators --list` |
| Launch emulator | `keels emulators --launch <emulator_id>` |

Always identify the platform before guessing the next command.

## Common Output Locations

### App Projects

| Platform | Artifact | Path |
| --- | --- | --- |
| Android | Debug APK | `android/app/build/outputs/apk/debug/app-debug.apk` |
| Android | Release APK | `android/app/build/outputs/apk/release/app-release.apk` |
| HarmonyOS | Signed HAP | `hos/entry/build/default/outputs/default/entry-default-signed.hap` |
| iOS device | Debug app bundle | `ios/output/DerivedData/Build/Products/Debug-iphoneos/<project>.app` |
| iOS device | Release app bundle | `ios/output/DerivedData/Build/Products/Release-iphoneos/<project>.app` |
| iOS simulator | Debug app bundle | `ios/output/DerivedData/Build/Products/Debug-iphonesimulator/<project>.app` |
| iOS simulator | Release app bundle | `ios/output/DerivedData/Build/Products/Release-iphonesimulator/<project>.app` |

### Reusable Package Projects

| Package Type | Typical Output Area |
| --- | --- |
| `aar` | module Gradle `build/outputs/aar/` |
| `har` | HarmonyOS `hos/` build outputs |
| `framework` / `framework-sim` | relevant `ios/.../output` or copied `ios/frameworks/` locations |

If an artifact path is unclear, inspect the current project layout before guessing.

## Troubleshooting Order

| Step | What To Check |
| --- | --- |
| 1. Environment | `CJMP_SDK_HOME`, `JAVA_HOME`, `ANDROID_SDK_ROOT`, `DEVECO_SDK_HOME`, Xcode/iOS SDK availability |
| 2. CLI baseline | `keels doctor -v`, `keels devices` |
| 3. Project identity | `project.conf`, `lib/cjpm.toml`, package type vs. command |
| 4. Project layout | whether the project matches expected template structure |
| 5. Platform tooling | Android: Gradle/adb/NDK, HarmonyOS: ohpm/node/hvigor/hdc, iOS: xcodebuild/devicectl/simctl |
| 6. Runtime assets | `cjmp-ui`, `ui-engine`, `cjmp-libs`, `cjmp-test` if the issue looks like linking or runtime dependency |

Avoid jumping straight to low-level fixes before confirming the project type and target platform.

## When The User Asks About Framework Internals

Only go deeper if the user explicitly asks how CJMP itself works.

| Area | Where To Look |
| --- | --- |
| CLI behavior and command semantics | `cjmp-tools/tools/keels_tools/` |
| Project generation templates | `cjmp-tools/tools/keels_tools/template/` |
| Platform runtime and frontend pieces | `cjmp-ui/` |
| Engine/runtime binaries | `ui-engine/` |
| Shared platform libraries | `cjmp-libs/` |

Do not assume the developer's app workspace contains the framework implementation unless it actually does.

## Agent Guidance Summary

- default to the SDK consumer perspective
- prefer `keels` commands before native platform commands
- use `project.conf` to classify the project before giving advice
- keep explanations practical and developer-oriented rather than implementation-heavy
- only drop into framework internals when the user clearly needs that level of detail
