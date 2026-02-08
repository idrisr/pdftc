# Benchmarks

This directory contains synthetic PDF fixtures, golden outputs, and a hyperfine
benchmark harness. The goal is to measure end-to-end performance and separate
`pdftk` extraction cost from the text processing pipeline.

## Quick start

1) Enter the dev shell:

```bash
nix develop
```

2) Generate fixtures:

```bash
python bench/gen_fixtures.py
```

3) Update golden outputs (baseline):

```bash
bench/update_golden.sh
```

4) Run benchmarks:

```bash
bench/bench.sh
```

Or via Nix:

```bash
nix run .#bench
```

Results are written to `bench/results.md`.

## Benchmark commands

- `baseline-*`: full pipeline with `pdftk dump_data_utf8`.
- `pdftk-*`: extraction cost only.
- `parse-*`: pipeline cost only, using saved dumps.
- `pikepdf-*`: outlines extracted directly with `pdftc.py`.
