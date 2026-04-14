#!/usr/bin/env bash
set -euo pipefail

usage() {
  cat <<'EOF'
Usage:
  export_xcresult_attachments.sh \
    --result-bundle <path> \
    [--output-dir <dir>] \
    [--output-prefix <prefix>] \
    [--dry-run]

Export attachments from an xcresult bundle into a fresh timestamped directory.
EOF
}

result_bundle=""
output_dir="/tmp"
output_prefix="xcresult-attachments"
dry_run="false"

while [[ $# -gt 0 ]]; do
  case "$1" in
    --result-bundle)
      result_bundle="${2:-}"
      shift 2
      ;;
    --output-dir)
      output_dir="${2:-}"
      shift 2
      ;;
    --output-prefix)
      output_prefix="${2:-}"
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

if [[ -z "$result_bundle" ]]; then
  usage >&2
  exit 1
fi

timestamp="$(date -u +%Y%m%dT%H%M%SZ)"
attachments_path="${output_dir%/}/${output_prefix}-${timestamp}"

printf 'ATTACHMENTS_PATH=%s\n' "$attachments_path"
printf 'COMMAND='
printf '%q ' xcrun xcresulttool export attachments --path "$result_bundle" --output-path "$attachments_path"
printf '\n'

if [[ "$dry_run" == "true" ]]; then
  exit 0
fi

xcrun xcresulttool export attachments --path "$result_bundle" --output-path "$attachments_path"
