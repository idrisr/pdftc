# Benchmarks

This directory contains synthetic PDF fixtures and a hyperfine benchmark
harness. The goal is to measure end-to-end performance and cache hit speed for
the current `pdftc` implementation.

## Quick start

1) Enter the dev shell:

```bash
nix develop
```

2) Generate fixtures:

```bash
python bench/gen_fixtures.py
```

3) Run benchmarks:

```bash
bench/bench.sh
```

Or via Nix:

```bash
nix run .#bench
```

Results are written to `bench/results.md`.

## Benchmark commands

- `pdftc-<name>-cold`: clears cache entry then runs.
- `pdftc-<name>-warm`: cached run for the same file.
