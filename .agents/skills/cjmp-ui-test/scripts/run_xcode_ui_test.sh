#!/usr/bin/env bash
set -euo pipefail

usage() {
  cat <<'EOF'
Usage:
  run_xcode_ui_test.sh \
    --project <path> \
    --scheme <name> \
    --device-id <id> \
    --only-testing <target/test> \
    [--result-bundle-dir <dir>] \
    [--result-prefix <prefix>] \
    [--dry-run]

Run one Xcode UI test on a real iOS device and create a fresh timestamped
result bundle path.
EOF
}

project=""
scheme=""
device_id=""
only_testing=""
result_bundle_dir="/tmp"
result_prefix="cjmp-ui-test"
dry_run="false"

while [[ $# -gt 0 ]]; do
  case "$1" in
    --project)
      project="${2:-}"
      shift 2
      ;;
    --scheme)
      scheme="${2:-}"
      shift 2
      ;;
    --device-id)
      device_id="${2:-}"
      shift 2
      ;;
    --only-testing)
      only_testing="${2:-}"
      shift 2
      ;;
    --result-bundle-dir)
      result_bundle_dir="${2:-}"
      shift 2
      ;;
    --result-prefix)
      result_prefix="${2:-}"
      shift 2
      ;;
    --dry-run)
      dry_run="true"
      shift 1
      ;;
    -h|--help)
      usage
      exit 0
      ;;
    *)
      echo "Unknown argument: $1" >&2
      usage >&2
      exit 1
      ;;
  esac
done

if [[ -z "$project" || -z "$scheme" || -z "$device_id" || -z "$only_testing" ]]; then
  usage >&2
  exit 1
fi

timestamp="$(date -u +%Y%m%dT%H%M%SZ)"
result_bundle_path="${result_bundle_dir%/}/${result_prefix}-${timestamp}.xcresult"

cmd=(
  xcodebuild test
  -project "$project"
  -scheme "$scheme"
  -destination "id=$device_id"
  -only-testing:"$only_testing"
  -resultBundlePath "$result_bundle_path"
)

printf 'RESULT_BUNDLE_PATH=%s\n' "$result_bundle_path"
printf 'COMMAND='
printf '%q ' "${cmd[@]}"
printf '\n'

if [[ "$dry_run" == "true" ]]; then
  exit 0
fi

"${cmd[@]}"
