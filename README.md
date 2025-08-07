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
