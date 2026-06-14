"""
Extract per-book INTRODUCTIONS from Matthew Henry's *unabridged* "Commentary
on the Whole Bible" (the full 6-volume Exposition), not the Concise abridgment.

The Concise edition (parse_mhcc.py / parse_book_intros.parse_mhcc_intros) opens
each book with only a sentence or two; the unabridged Exposition opens each book
with a full introductory essay — authorship, date, occasion, scope, and Henry's
characteristic devotional framing — running anywhere from ~500 to ~12,000 chars.
That fuller essay is the "About this book" content we want to surface.

Inputs (git-LFS; run `git lfs pull` first):
  python_parser/sources/mhc/mhc1.txt  (Genesis–Deuteronomy)
  python_parser/sources/mhc/mhc2.txt  (Joshua–Esther)
  python_parser/sources/mhc/mhc3.txt  (Job–Song of Solomon)
  python_parser/sources/mhc/mhc4.txt  (Isaiah–Malachi)
  python_parser/sources/mhc/mhc5.txt  (Matthew–John)
  python_parser/sources/mhc/mhc6.txt  (Acts–Revelation)
  (CCEL plain-text cache: https://www.ccel.org/ccel/h/henry/mhc{1..6}/cache/mhc{n}.txt)

This module does only the *structural* extraction and returns raw, blank-line
paragraphs per book. parse_book_intros.py applies the shared readability re-flow
(soft_wrap) and writes the JSON the apps load — same as it does for JFB/MHCC.

How a book opens in the unabridged plain text
---------------------------------------------
Each book begins with a spaced-capitals title header sitting directly above the
first chapter marker, and the introductory essay is the prose block immediately
*above* that header, fenced by CCEL underscore rules:

        ____________________   <- separator (top of intro block)
        <intro essay paragraphs>
        ____________________   <- separator (sep_below; directly above header)

    F I R S T   S A M U E L    <- spaced-caps header (1-2 lines; period in vol 4-6)

      CHAP. I.                 <- first-chapter marker (PSALM I. for Psalms)

The spaced-caps header also recurs as a page running-head throughout the book,
so we anchor only on the occurrence immediately followed by CHAP. I. / PSALM I.
Book *names* are assigned positionally: each volume holds its books in canonical
order, so the i-th detected book-start in volume V is VOLUME_BOOKS[V][i]. This
sidesteps parsing the (numbered, multi-word, line-wrapped) header text itself.
"""
from __future__ import annotations

import re
from pathlib import Path

SOURCE_DIR = Path(__file__).parent / "sources" / "mhc"

SOURCE_INFO = {
    "name": "Matthew Henry's Commentary on the Whole Bible (Unabridged)",
    "shortName": "Matthew Henry",
    "year": 1710,
    "license": "Public Domain",
    "attribution": (
        "Matthew Henry (1662–1714). An Exposition of the Old and New "
        "Testament — the complete, unabridged Commentary on the Whole Bible "
        "(published 1708–1710; the New Testament completed posthumously, "
        "1721), sourced from the Christian Classics Ethereal Library (CCEL)."
    ),
}

# Each volume's books in canonical order — book-start anchors are matched to
# names positionally, so these lists must stay in publication/canonical order
# and total the 66 protestant-canon books.
VOLUME_BOOKS: dict[int, list[str]] = {
    1: ["Genesis", "Exodus", "Leviticus", "Numbers", "Deuteronomy"],
    2: ["Joshua", "Judges", "Ruth", "1 Samuel", "2 Samuel", "1 Kings",
        "2 Kings", "1 Chronicles", "2 Chronicles", "Ezra", "Nehemiah",
        "Esther"],
    3: ["Job", "Psalms", "Proverbs", "Ecclesiastes", "Song of Solomon"],
    4: ["Isaiah", "Jeremiah", "Lamentations", "Ezekiel", "Daniel", "Hosea",
        "Joel", "Amos", "Obadiah", "Jonah", "Micah", "Nahum", "Habakkuk",
        "Zephaniah", "Haggai", "Zechariah", "Malachi"],
    5: ["Matthew", "Mark", "Luke", "John"],
    6: ["Acts", "Romans", "1 Corinthians", "2 Corinthians", "Galatians",
        "Ephesians", "Philippians", "Colossians", "1 Thessalonians",
        "2 Thessalonians", "1 Timothy", "2 Timothy", "Titus", "Philemon",
        "Hebrews", "James", "1 Peter", "2 Peter", "1 John", "2 John",
        "3 John", "Jude", "Revelation"],
}

# CCEL renders a section rule as a run of underscores on its own line.
SEPARATOR_RE = re.compile(r"^\s*_{10,}\s*$")
# A spaced-capitals header line: "G E N E S I S", "F I R S T   S A M U E L",
# "A C T S." — single letters/digits separated by one-or-more spaces, with an
# optional trailing period (volumes 4-6 add one).
SPACED_HEADER_RE = re.compile(r"^[A-Z0-9](?: +[A-Z0-9.])+\.?$")
# A book's first-chapter marker. Psalms uses "PSALM I." instead of "CHAP. I.".
FIRST_CHAPTER_RE = re.compile(r"^\s*(?:CHAP\.|PSALM) I\.\s*$")


def _source_path(volume: int) -> Path:
    return SOURCE_DIR / f"mhc{volume}.txt"


def find_book_starts(lines: list[str]) -> list[tuple[int, int]]:
    """
    Locate every book-start in a volume, in file order.

    Returns (header_top, sep_below) pairs where `header_top` is the first line
    of the spaced-caps title header and `sep_below` is the underscore rule
    directly above it (the lower fence of the intro block). A book-start is a
    FIRST_CHAPTER marker preceded — across blank lines only — by one or more
    spaced-caps header lines and then a separator.
    """
    starts: list[tuple[int, int]] = []
    for i, line in enumerate(lines):
        if not FIRST_CHAPTER_RE.match(line):
            continue
        j = i - 1
        while j >= 0 and not lines[j].strip():
            j -= 1
        header_lines: list[int] = []
        while j >= 0 and SPACED_HEADER_RE.match(lines[j].strip()):
            header_lines.append(j)
            j -= 1
        if not header_lines:
            continue
        while j >= 0 and not lines[j].strip():
            j -= 1
        if j >= 0 and SEPARATOR_RE.match(lines[j]):
            starts.append((min(header_lines), j))
    return starts


def collect_paragraphs(lines: list[str], start: int, end: int) -> list[str]:
    """Gather [start, end) into blank-line-delimited paragraphs, dropping CCEL
    underscore rules and collapsing intra-paragraph whitespace."""
    paragraphs: list[str] = []
    current: list[str] = []
    for i in range(start, end):
        stripped = lines[i].strip()
        if SEPARATOR_RE.match(stripped):
            continue
        if not stripped:
            if current:
                paragraphs.append(" ".join(current))
                current = []
            continue
        current.append(stripped)
    if current:
        paragraphs.append(" ".join(current))
    return [p for p in paragraphs if p]


def _intro_paragraphs(lines: list[str], sep_below: int) -> list[str]:
    """The intro block is the prose fenced between `sep_below` and the nearest
    separator above it (the volume preface, or the prior book's last chapter,
    sits above that upper fence)."""
    top = sep_below - 1
    while top >= 0 and not SEPARATOR_RE.match(lines[top]):
        top -= 1
    return collect_paragraphs(lines, top + 1, sep_below)


def parse_volume(volume: int) -> dict[str, list[str]]:
    """Return {book name: [raw paragraph, ...]} for one volume, asserting the
    detected book count matches the canonical roster so a format drift in the
    source can't silently drop or misalign books."""
    expected = VOLUME_BOOKS[volume]
    lines = _source_path(volume).read_text(encoding="utf-8").splitlines()
    starts = find_book_starts(lines)
    if len(starts) != len(expected):
        raise ValueError(
            f"mhc{volume}.txt: found {len(starts)} book-starts, "
            f"expected {len(expected)} ({', '.join(expected)})"
        )
    return {
        expected[idx]: _intro_paragraphs(lines, sep_below)
        for idx, (_header_top, sep_below) in enumerate(starts)
    }


def parse_raw_intros() -> dict[str, list[str]]:
    """Return {book name: [raw paragraph, ...]} for all 66 books, across the 6
    volumes. Caller applies the shared readability re-flow + JSON shaping."""
    intros: dict[str, list[str]] = {}
    for volume in sorted(VOLUME_BOOKS):
        intros.update(parse_volume(volume))
    return intros


if __name__ == "__main__":
    raw = parse_raw_intros()
    total_chars = sum(len(p) for paras in raw.values() for p in paras)
    print(f"Parsed {len(raw)} unabridged Matthew Henry book intros "
          f"({total_chars:,} chars total)")
    for book, paras in raw.items():
        chars = sum(len(p) for p in paras)
        print(f"  {book:18} {len(paras):2d} para  {chars:6,d} chars")
