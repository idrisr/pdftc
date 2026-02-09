#!/usr/bin/env python3
import argparse
import hashlib
import os
import re
import shutil
import sys

import pikepdf


NUMBERED_RE = re.compile(r"^(\s+)((\d+\.)+)(\d+)\s")
CACHE_VERSION = "1"
TAIL_READ_SIZE = 64 * 1024


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


def get_cache_dir(override=None):
    base = override or os.environ.get("XDG_CACHE_HOME")
    if not base:
        base = os.path.join(os.path.expanduser("~"), ".cache")
    return os.path.join(base, "pdftc")


def ensure_cache_dir(path):
    os.makedirs(path, exist_ok=True)


def clear_cache_dir(path):
    if not os.path.isdir(path):
        return
    for name in os.listdir(path):
        entry = os.path.join(path, name)
        if os.path.isfile(entry) or os.path.islink(entry):
            os.remove(entry)
        elif os.path.isdir(entry):
            shutil.rmtree(entry)


def find_startxref_offset(tail):
    index = tail.rfind(b"startxref")
    if index == -1:
        return None
    match = re.search(rb"startxref\s+(\d+)", tail[index:])
    if not match:
        return None
    try:
        return int(match.group(1))
    except ValueError:
        return None


def read_tail(path):
    size = os.path.getsize(path)
    read_size = TAIL_READ_SIZE if size > TAIL_READ_SIZE else size
    with open(path, "rb") as handle:
        if read_size:
            handle.seek(size - read_size)
        tail = handle.read(read_size)
    return tail, size


def hash_xref_region(path):
    tail, size = read_tail(path)
    offset = find_startxref_offset(tail)
    sha = hashlib.sha256()
    if offset is None or offset < 0 or offset >= size:
        sha.update(b"tail:")
        sha.update(tail)
        return sha.hexdigest()
    with open(path, "rb") as handle:
        handle.seek(offset)
        sha.update(b"xref:")
        while True:
            chunk = handle.read(1024 * 1024)
            if not chunk:
                break
            sha.update(chunk)
    return sha.hexdigest()


def cache_key(fingerprint):
    version = f"pdftc-cache-v{CACHE_VERSION}-pikepdf-{pikepdf.__version__}"
    payload = f"{version}:{fingerprint}".encode("utf-8")
    return hashlib.sha256(payload).hexdigest()


def read_cache(path):
    try:
        with open(path, "r", encoding="utf-8") as handle:
            return handle.read()
    except FileNotFoundError:
        return None


def write_cache(path, content):
    tmp_path = f"{path}.tmp"
    with open(tmp_path, "w", encoding="utf-8") as handle:
        handle.write(content)
    os.replace(tmp_path, path)


def clear_cache_entry(path):
    try:
        os.remove(path)
    except FileNotFoundError:
        pass


def parse_args():
    parser = argparse.ArgumentParser(
        prog="pdftc",
        description="Generate a table of contents from PDF bookmarks.",
    )
    parser.add_argument("pdf", nargs="?", help="Path to PDF file")
    parser.add_argument(
        "--cache-dir",
        help="Override cache directory (default: XDG cache)",
    )
    parser.add_argument(
        "--no-cache",
        action="store_true",
        help="Disable cache",
    )
    parser.add_argument(
        "--cache-clear",
        action="store_true",
        help="Clear cache entry for this PDF before running",
    )
    parser.add_argument(
        "--cache-clear-all",
        action="store_true",
        help="Clear all cached entries and exit",
    )
    parser.add_argument(
        "--cache-info",
        action="store_true",
        help="Print cache hit/miss information to stderr",
    )
    return parser.parse_args()


def main():
    args = parse_args()
    cache_dir = get_cache_dir(args.cache_dir)
    cache_enabled = not args.no_cache

    if args.cache_clear_all:
        clear_cache_dir(cache_dir)
        if args.cache_info:
            print(f"cache cleared: {cache_dir}", file=sys.stderr)
        return 0

    if not args.pdf:
        print("pdf path required", file=sys.stderr)
        return 1

    cache_path = None
    if cache_enabled or args.cache_clear:
        try:
            fingerprint = hash_xref_region(args.pdf)
        except FileNotFoundError:
            print(f"{args.pdf} does not exist", file=sys.stderr)
            return 1
        except Exception as exc:
            print(f"failed to hash pdf cache key: {exc}", file=sys.stderr)
            return 1

        cache_path = os.path.join(cache_dir, f"{cache_key(fingerprint)}.txt")
        if args.cache_clear:
            clear_cache_entry(cache_path)
        if cache_enabled:
            cached_output = read_cache(cache_path)
            if cached_output is not None:
                cache_hit = True
                if args.cache_info:
                    print(f"cache hit: {cache_path}", file=sys.stderr)
                sys.stdout.write(cached_output)
                return 0
            if args.cache_info:
                print(f"cache miss: {cache_path}", file=sys.stderr)
        elif args.cache_info:
            print("cache disabled", file=sys.stderr)
    try:
        with pikepdf.open(args.pdf) as pdf:
            outline = pdf.open_outline()
            if not outline or not outline.root:
                if cache_enabled and cache_path:
                    ensure_cache_dir(cache_dir)
                    write_cache(cache_path, "")
                return 0
            lines = [
                format_line(level, title)
                for level, title in walk_outline(outline.root, 1)
            ]
            output = "\n".join(lines) + "\n"
            if cache_enabled and cache_path:
                ensure_cache_dir(cache_dir)
                write_cache(cache_path, output)
            sys.stdout.write(output)
            return 0
    except FileNotFoundError:
        print(f"{args.pdf} does not exist", file=sys.stderr)
        return 1
    except Exception as exc:
        print(f"failed to read pdf outlines: {exc}", file=sys.stderr)
        return 1


if __name__ == "__main__":
    raise SystemExit(main())
