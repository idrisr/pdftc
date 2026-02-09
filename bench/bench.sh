#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="${PDFTC_ROOT:-$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)}"
FIXTURES_DIR="$ROOT_DIR/bench/fixtures"
RESULTS_FILE="$ROOT_DIR/bench/results.md"
CACHE_DIR="$ROOT_DIR/bench/cache"

pdfs=(small medium deep wide numbered)

mkdir -p "$CACHE_DIR"
export XDG_CACHE_HOME="$CACHE_DIR"

for name in "${pdfs[@]}"; do
  pdf="$FIXTURES_DIR/${name}.pdf"
  if [[ ! -f "$pdf" ]]; then
    echo "missing fixture: $pdf" >&2
    exit 1
  fi
done

args=()
for name in "${pdfs[@]}"; do
  pdf="$FIXTURES_DIR/${name}.pdf"
  args+=(-n "pdftc-$name-cold" "python \"$ROOT_DIR/pdftc.py\" --cache-clear \"$pdf\" > /dev/null")
  args+=(-n "pdftc-$name-warm" "python \"$ROOT_DIR/pdftc.py\" \"$pdf\" > /dev/null")
done

hyperfine --warmup 2 --min-runs 5 --export-markdown "$RESULTS_FILE" "${args[@]}"

echo "wrote benchmark results to $RESULTS_FILE"
