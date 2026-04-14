# `keels` app template points iOS simulator builds at a missing `cjmp-libs` path

## Issue summary

Running `keels build ios-sim --platform ios-sim-arm64 --debug` for the freshly created CJMP app fails before the simulator build starts because the generated configuration looks for:

- `/Users/dzy/codes/cjmp-sdk-mac-arm64-0.2.1-release/cjmp-libs/ios-sim-arm64/dynamic/cjmp`

That directory does not exist in the current SDK layout. The installed SDK only exposes:

- `/Users/dzy/codes/cjmp-sdk-mac-arm64-0.2.1-release/cjmp-libs/ios/dynamic/cjmp`

## Reproduction or context

1. Create or repair an app project with `keels create --app apps/cjmp -n cjmp --org com.example`.
2. From the app directory, run `keels build ios-sim --platform ios-sim-arm64 --debug`.
3. The build fails with:

```text
Error: can not find path '/Users/dzy/codes/cjmp-sdk-mac-arm64-0.2.1-release/cjmp-libs/ios-sim-arm64/dynamic/cjmp' which is listed in 'target.aarch64-apple-ios-simulator.bin-dependencies' field at ./cjpm.toml
```

4. Inspecting the SDK shows that `cjmp-libs/ios-sim-arm64/` is absent while `cjmp-libs/ios/` exists.

## Impact on AI-assisted delivery

- The default app template advertises `ios-sim` as a supported package and platform, so an agent can reasonably choose simulator build-and-test as the fastest validation loop.
- The path mismatch blocks that path immediately, which forces the round onto a real-device flow and removes simulator-based iteration as a reliable fallback.
- The mismatch is durable repo-level comparison friction because it weakens repeatable acceptance on machines without a connected iPhone and adds manual investigation before the root cause becomes clear.

## Workaround used in this repo

- Build the app for a real iPhone with `keels build ios --platform ios-arm64 --debug`.
- Run Xcode UI automation on the connected real device instead of trying to validate slice 1 on `ios-sim`.
- Record the simulator-path mismatch as confirmed CJMP tooling friction instead of silently treating it as a local mistake.

## Related slice

- `CJMP` Telegram commercial MVP
- slice `#1` app shell and startup routing

## Upstream issue link

- not created yet
