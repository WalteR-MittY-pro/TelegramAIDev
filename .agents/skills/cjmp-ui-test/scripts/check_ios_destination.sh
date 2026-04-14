#!/usr/bin/env bash
set -euo pipefail

usage() {
  cat <<'EOF'
Usage:
  check_ios_destination.sh --project <path> --scheme <name> [--device-id <id>]

Print the current xcodebuild destinations for a project and optionally assert
that a specific real-device id is available.
EOF
}

project=""
scheme=""
device_id=""

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

if [[ -z "$project" || -z "$scheme" ]]; then
  usage >&2
  exit 1
fi

output="$(xcodebuild -project "$project" -scheme "$scheme" -showdestinations 2>&1 || true)"
printf '%s\n' "$output"

if [[ -n "$device_id" ]]; then
  if grep -Fq "id:$device_id" <<<"$output" || grep -Fq "id=$device_id" <<<"$output"; then
    printf 'MATCHED_DEVICE_ID=%s\n' "$device_id"
  else
    printf 'Requested device id not present in xcodebuild destinations: %s\n' "$device_id" >&2
    exit 2
  fi
fi
