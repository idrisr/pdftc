#!/usr/bin/env python3
import os
from reportlab.lib.pagesizes import letter
from reportlab.pdfgen import canvas


ROOT_DIR = os.path.abspath(os.path.join(os.path.dirname(__file__), ".."))
FIXTURES_DIR = os.path.join(ROOT_DIR, "bench", "fixtures")


def make_pdf(path, bookmarks):
    c = canvas.Canvas(path, pagesize=letter)
    width, height = letter
    for idx, (level, title) in enumerate(bookmarks, start=1):
        c.setFont("Helvetica", 12)
        c.drawString(72, height - 72, f"{idx}. {title} (level {level})")
        key = f"bm_{idx}"
        c.bookmarkPage(key)
        c.addOutlineEntry(title, key, level=level - 1, closed=False)
        c.showPage()
    c.save()


def small_bookmarks():
    bookmarks = []
    for i in range(10):
        level = (i % 3) + 1
        title = f"Section {i + 1}"
        bookmarks.append((level, title))
    return bookmarks


def medium_bookmarks():
    bookmarks = []
    for i in range(200):
        level = (i % 6) + 1
        title = f"Topic {i + 1}"
        bookmarks.append((level, title))
    return bookmarks


def deep_bookmarks():
    bookmarks = []
    for i in range(50):
        level = (i % 10) + 1
        title = f"Deep Node {i + 1}"
        bookmarks.append((level, title))
    return bookmarks


def wide_bookmarks():
    bookmarks = []
    for i in range(600):
        level = 2 if i % 10 == 0 and i != 0 else 1
        title = f"Wide Topic {i + 1}"
        bookmarks.append((level, title))
    return bookmarks


def numbered_bookmarks():
    bookmarks = []
    for i in range(60):
        level = (i % 4) + 1
        count = (i % 8) + 1
        numbers = [str(((i + j) % 9) + 1) for j in range(count)]
        prefix = ".".join(numbers)
        title = f"{prefix} Numbered Topic {i + 1}"
        bookmarks.append((level, title))
    return bookmarks


def main():
    os.makedirs(FIXTURES_DIR, exist_ok=True)
    fixtures = {
        "small.pdf": small_bookmarks(),
        "medium.pdf": medium_bookmarks(),
        "deep.pdf": deep_bookmarks(),
        "wide.pdf": wide_bookmarks(),
        "numbered.pdf": numbered_bookmarks(),
    }

    for name, bookmarks in fixtures.items():
        path = os.path.join(FIXTURES_DIR, name)
        make_pdf(path, bookmarks)
        print(f"wrote {path} ({len(bookmarks)} bookmarks)")


if __name__ == "__main__":
    main()
