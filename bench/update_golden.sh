#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="${PDFTC_ROOT:-$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)}"
FIXTURES_DIR="$ROOT_DIR/bench/fixtures"
GOLDEN_DIR="$ROOT_DIR/bench/golden"
PIPELINE="$ROOT_DIR/bench/pdftc_pipeline.sh"

mkdir -p "$GOLDEN_DIR"

pdfs=(small medium deep wide numbered)

for name in "${pdfs[@]}"; do
  pdf="$FIXTURES_DIR/${name}.pdf"
  if [[ ! -f "$pdf" ]]; then
    echo "missing fixture: $pdf" >&2
    exit 1
  fi
  "$PIPELINE" "$pdf" > "$GOLDEN_DIR/${name}.txt"
done

echo "updated golden outputs in $GOLDEN_DIR"
