#!/usr/bin/env python3
import argparse
import re
import sys

import pikepdf


NUMBERED_RE = re.compile(r"^(\s+)((\d+\.)+)(\d+)\s")


def apply_number_indent(line):
    match = NUMBERED_RE.match(line)
    if not match:
        return line
    dot_count = match.group(2).count(".")
    if 1 <= dot_count <= 7:
        indent = "\t" * (dot_count + 1)
        return indent + line[match.end():]
    return line


def format_line(level, title):
    if 1 <= level <= 7:
        line = ("\t" * level) + title
    else:
        line = f"{level} {title}"
    line = apply_number_indent(line)
    line = line.replace("\t", "    ")
    return line.lower()


def walk_outline(items, level):
    for item in items:
        if isinstance(item, pikepdf.OutlineItem):
            title = str(item.title) if item.title is not None else ""
            yield level, title
            if item.children:
                yield from walk_outline(item.children, level + 1)
        elif isinstance(item, list):
            yield from walk_outline(item, level)


def parse_args():
    parser = argparse.ArgumentParser(
        prog="pdftc",
        description="Generate a table of contents from PDF bookmarks.",
    )
    parser.add_argument("pdf", help="Path to PDF file")
    return parser.parse_args()


def main():
    args = parse_args()
    try:
        with pikepdf.open(args.pdf) as pdf:
            outline = pdf.open_outline()
            if not outline or not outline.root:
                return 0
            for level, title in walk_outline(outline.root, 1):
                print(format_line(level, title))
            return 0
    except FileNotFoundError:
        print(f"{args.pdf} does not exist", file=sys.stderr)
        return 1
    except Exception as exc:
        print(f"failed to read pdf outlines: {exc}", file=sys.stderr)
        return 1


if __name__ == "__main__":
    raise SystemExit(main())
