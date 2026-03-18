#!/usr/bin/env bash

set -euo pipefail

SPREADSHEET_ID="16qNY3gyPHu4e4D5aXkTD5Wy03b2Jm_aFrrXZLxcYGPg"
TAB_LIMIT=4
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
OUT_DIR="${SCRIPT_DIR}/../apps/judgy/assets/data"
CUSTOM_MAPS=()

usage() {
  cat <<'EOF'
Usage:
  ./scripts/fetch_sheet_tabs.sh [options]

Options:
  --spreadsheet-id <id>      Google Sheet ID to export.
  --out-dir <path>           Output directory for CSV files.
  --tab-limit <number>       Number of visible tabs to export (default: 4).
  --map <tab=filename.csv>   Explicit tab-to-file mapping. Can be repeated.
  -h, --help                 Show this help text.

Examples:
  ./scripts/fetch_sheet_tabs.sh
  ./scripts/fetch_sheet_tabs.sh --map "Nouns=nouns.csv" --map "Adjectives=adjectives.csv"
EOF
}

while [[ $# -gt 0 ]]; do
  case "$1" in
    --spreadsheet-id)
      SPREADSHEET_ID="$2"
      shift 2
      ;;
    --out-dir)
      OUT_DIR="$2"
      shift 2
      ;;
    --tab-limit)
      TAB_LIMIT="$2"
      shift 2
      ;;
    --map)
      CUSTOM_MAPS+=("$2")
      shift 2
      ;;
    -h|--help)
      usage
      exit 0
      ;;
    *)
      echo "Unknown argument: $1" >&2
      usage
      exit 1
      ;;
  esac
done

require_cmd() {
  if ! command -v "$1" >/dev/null 2>&1; then
    echo "Error: '$1' is required but not found in PATH." >&2
    exit 1
  fi
}

require_cmd gws
require_cmd jq

if ! [[ "$TAB_LIMIT" =~ ^[1-9][0-9]*$ ]]; then
  echo "Error: --tab-limit must be a positive integer." >&2
  exit 1
fi

mkdir -p "$OUT_DIR"

to_slug() {
  local input="$1"

  local slug
  slug="$(printf '%s' "$input" | tr '[:upper:]' '[:lower:]' | sed -E 's/[^a-z0-9]+/_/g; s/^_+//; s/_+$//')"
  if [[ -z "$slug" ]]; then
    slug="sheet"
  fi
  printf '%s' "$slug"
}

to_a1_sheet_ref() {
  local title="$1"
  local escaped
  escaped="${title//\'/\'\'}"
  printf "'%s'" "$escaped"
}

lookup_custom_filename() {
  local title="$1"
  local pair
  local key
  local value

  for pair in "${CUSTOM_MAPS[@]:-}"; do
    key="${pair%%=*}"
    value="${pair#*=}"
    if [[ "$key" == "$title" ]]; then
      printf '%s' "$value"
      return 0
    fi
  done

  return 1
}

default_filename() {
  local title="$1"
  local lower

  lower="$(printf '%s' "$title" | tr '[:upper:]' '[:lower:]')"

  case "$lower" in
    noun|nouns)
      printf 'nouns.csv'
      ;;
    "noun categories"|"noun category")
      printf 'noun_categories.csv'
      ;;
    adjective|adjectives)
      printf 'adjectives.csv'
      ;;
    "adjective categories"|"adjective category")
      printf 'adjective_categories.csv'
      ;;
    *)
      printf '%s.csv' "$(to_slug "$title")"
      ;;
  esac
}

echo "Fetching sheet metadata from ${SPREADSHEET_ID}..."
sheet_json="$(
  gws sheets spreadsheets get \
    --params "{\"spreadsheetId\":\"${SPREADSHEET_ID}\"}" \
    --format json
)"

tabs_tsv="$(
  printf '%s' "$sheet_json" | jq -r \
    --argjson limit "$TAB_LIMIT" \
    '.sheets
     | sort_by(.properties.index)
     | map(select(.properties.hidden != true))
     | .[:$limit]
     | .[]
     | [.properties.sheetId, .properties.title] | @tsv'
)"

if [[ -z "$tabs_tsv" ]]; then
  echo "Error: No visible tabs found in spreadsheet ${SPREADSHEET_ID}." >&2
  exit 1
fi

echo "Exporting up to ${TAB_LIMIT} tabs to ${OUT_DIR}..."

exported=0
while IFS=$'\t' read -r sheet_id sheet_title; do
  if [[ -z "${sheet_id}" || -z "${sheet_title}" ]]; then
    continue
  fi

  filename=""
  if ! filename="$(lookup_custom_filename "$sheet_title")"; then
    filename="$(default_filename "$sheet_title")"
  fi

  range_ref="$(to_a1_sheet_ref "$sheet_title")"
  tmp_file="${OUT_DIR}/.${filename}.tmp"
  out_file="${OUT_DIR}/${filename}"

  echo "- ${sheet_title} (gid=${sheet_id}) -> ${filename}"
  params_json="$(jq -cn --arg id "$SPREADSHEET_ID" --arg range "$range_ref" '{spreadsheetId: $id, range: $range}')"
  gws sheets spreadsheets values get \
    --params "$params_json" \
    --format csv > "$tmp_file"

  mv "$tmp_file" "$out_file"
  exported=$((exported + 1))
done <<< "$tabs_tsv"

if [[ "$exported" -eq 0 ]]; then
  echo "Error: Script did not export any tabs." >&2
  exit 1
fi

echo "Done. Exported ${exported} tab(s) to ${OUT_DIR}."
