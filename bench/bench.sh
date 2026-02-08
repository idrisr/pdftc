#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="${PDFTC_ROOT:-$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)}"
FIXTURES_DIR="$ROOT_DIR/bench/fixtures"
DUMPS_DIR="$ROOT_DIR/bench/dumps"
RESULTS_FILE="$ROOT_DIR/bench/results.md"
PIPELINE="$ROOT_DIR/bench/pdftc_pipeline.sh"
PARSE_DUMP="$ROOT_DIR/bench/parse_dump.sh"

pdfs=(small medium deep wide numbered)

mkdir -p "$DUMPS_DIR"

for name in "${pdfs[@]}"; do
  pdf="$FIXTURES_DIR/${name}.pdf"
  if [[ ! -f "$pdf" ]]; then
    echo "missing fixture: $pdf" >&2
    exit 1
  fi
done

for name in "${pdfs[@]}"; do
  pdf="$FIXTURES_DIR/${name}.pdf"
  dump="$DUMPS_DIR/${name}.dump.txt"
  if [[ ! -f "$dump" || "$dump" -ot "$pdf" || ! -s "$dump" ]]; then
    pdftk "$pdf" dump_data_utf8 > "$dump"
  fi
  if ! rg --no-config --text -q "BookmarkTitle:" "$dump"; then
    echo "no bookmarks found in dump: $dump" >&2
    exit 1
  fi
done

args=()
for name in "${pdfs[@]}"; do
  pdf="$FIXTURES_DIR/${name}.pdf"
  dump="$DUMPS_DIR/${name}.dump.txt"
  args+=(-n "baseline-$name" "$PIPELINE \"$pdf\" > /dev/null")
  args+=(-n "pdftk-$name" "pdftk \"$pdf\" dump_data_utf8 > /dev/null")
  args+=(-n "parse-$name" "$PARSE_DUMP \"$dump\" > /dev/null")
  args+=(-n "pikepdf-$name" "python \"$ROOT_DIR/pdftc.py\" \"$pdf\" > /dev/null")
done

hyperfine --warmup 2 --min-runs 5 --export-markdown "$RESULTS_FILE" "${args[@]}"

echo "wrote benchmark results to $RESULTS_FILE"
