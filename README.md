# pdftc

A simple command-line tool to generate a table of contents from PDF bookmarks.

## Description

This script takes a PDF file as input, extracts the bookmarks, and prints an indented table of contents to standard output.

## Installation

This project is built with Nix. To install the `pdftc` command, run:

```bash
nix run github:idrisr/idris-pkgs
```

This will create a `result` symlink in the current directory, which contains the `pdftc` executable:

```bash
./result/bin/pdftc
```

## Usage

To generate a table of contents from a PDF file, run:

```bash
./result/bin/pdftc /path/to/your/document.pdf
```

The table of contents will be printed to standard output.

## Cache

By default, `pdftc` caches outputs under the XDG cache directory:

```
${XDG_CACHE_HOME:-~/.cache}/pdftc
```

Useful flags:

- `--no-cache` to bypass caching.
- `--cache-dir /path` to override the cache location.
- `--cache-clear` to clear the cache entry for a specific PDF before running.
- `--cache-clear-all` to wipe all cached entries and exit.
- `--cache-info` to print cache hit/miss info to stderr.

Cache keys are derived from the PDF head+tail for speed. If a file changes
without touching those regions, you may get a stale cache hit.
