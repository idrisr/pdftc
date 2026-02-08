#!/usr/bin/env bash
set -euo pipefail

usage() {
  echo "usage: $(basename "$0") <pdf file>" >&2
  exit 1
}

if [[ "$#" -ne 1 ]]; then
  usage
fi

pdf="$1"
if [[ ! -f "$pdf" ]]; then
  echo "$pdf does not exist" >&2
  exit 1
fi

pdftk "$pdf" dump_data_utf8 | \
  rg --no-config --smart-case --text "bookmark(title|level)" | \
  sed '$!N;s/^\([^\n]*\)\n\([^\n]*\)$/\2 \1/' | \
  sed -r -e 's/BookmarkLevel: //' \
    -e 's/BookmarkTitle: //' \
    -e 's/^7 /\t\t\t\t\t\t\t/' \
    -e 's/^6 /\t\t\t\t\t\t/' \
    -e 's/^5 /\t\t\t\t\t/' \
    -e 's/^4 /\t\t\t\t/' \
    -e 's/^3 /\t\t\t/' \
    -e 's/^2 /\t\t/' \
    -e 's/^1 /\t/' \
    -e 's/^\s+([0-9]+\.){7}[0-9]+\s/\t\t\t\t\t\t\t\t/' \
    -e 's/^\s+([0-9]+\.){6}[0-9]+\s/\t\t\t\t\t\t\t/' \
    -e 's/^\s+([0-9]+\.){5}[0-9]+\s/\t\t\t\t\t\t/' \
    -e 's/^\s+([0-9]+\.){4}[0-9]+\s/\t\t\t\t\t/' \
    -e 's/^\s+([0-9]+\.){3}[0-9]+\s/\t\t\t\t/' \
    -e 's/^\s+([0-9]+\.){2}[0-9]+\s/\t\t\t/' \
    -e 's/^\s+([0-9]+\.){1}[0-9]+\s/\t\t/' \
    -e 's/\t/    /g' | \
  tr '[:upper:]' '[:lower:]'
