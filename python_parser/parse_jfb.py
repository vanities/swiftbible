"""
Parse the Jamieson-Fausset-Brown Commentary (CCEL plain-text edition) into the
same structured form used by parse_mhcc.py.

Source: https://www.ccel.org/ccel/j/jamieson/jfb/cache/jfb.txt  (Public Domain)
Input:  python_parser/sources/jfb/jfb.txt
Output: python_parser/sources/jfb/jfb_parsed.json

JFB structures each chapter with section headers of the form

    Ge 1:1, 2. The Creation of Heaven and Earth.
    Ex 1:1-22. Increase of the Israelites.

so the parser pattern is much simpler than MHCC's three-format soup. We
extract each header inside a chapter, treating the verse list/range as the
section's verse span and the trailing title as the passage summary.

For one-chapter books (Obadiah, Philemon, 2 John, 3 John, Jude) the headers
omit the chapter number and use the form "Ob 1-21." or "Phm 1-25." which we
also handle.

Emitted schema mirrors mhcc_parsed.json:

    {
      "<Book Name>": {
        "<chapter str>": [
          {"title": "...", "start_verse": N, "end_verse": N|None}
        ]
      }
    }
"""
from __future__ import annotations

import json
import re
from pathlib import Path

SOURCE = Path(__file__).parent / "sources" / "jfb" / "jfb.txt"
OUTPUT = Path(__file__).parent / "sources" / "jfb" / "jfb_parsed.json"

# Map JFB book abbreviations to canonical book names. JFB uses idiosyncratic
# short forms (Mr for Mark, Joh for John, Re for Revelation, etc.). The
# canonical names here match what the rest of ios/swiftbible/Text/*.json uses.
ABBREV_MAP: dict[str, str] = {
    # Pentateuch
    "Ge": "Genesis", "Ex": "Exodus", "Le": "Leviticus", "Nu": "Numbers",
    "De": "Deuteronomy",
    # Historical
    "Jos": "Joshua", "Jud": "Judges", "Ru": "Ruth",
    "1Sa": "1 Samuel", "2Sa": "2 Samuel",
    "1Ki": "1 Kings", "2Ki": "2 Kings",
    "1Ch": "1 Chronicles", "2Ch": "2 Chronicles",
    "Ezr": "Ezra", "Ne": "Nehemiah", "Es": "Esther",
    # Wisdom
    "Job": "Job", "Ps": "Psalms", "Pr": "Proverbs",
    "Ec": "Ecclesiastes", "So": "Song of Solomon",
    # Major prophets
    "Isa": "Isaiah", "Jer": "Jeremiah", "La": "Lamentations",
    "Eze": "Ezekiel", "Da": "Daniel",
    # Minor prophets
    "Ho": "Hosea", "Joe": "Joel", "Am": "Amos", "Ob": "Obadiah",
    "Jon": "Jonah", "Mic": "Micah", "Na": "Nahum", "Hab": "Habakkuk",
    "Zep": "Zephaniah", "Hag": "Haggai", "Zec": "Zechariah", "Mal": "Malachi",
    # Gospels and Acts
    "Mt": "Matthew", "Mr": "Mark", "Lu": "Luke", "Joh": "John", "Ac": "Acts",
    # Pauline
    "Ro": "Romans",
    "1Co": "1 Corinthians", "2Co": "2 Corinthians",
    "Ga": "Galatians", "Eph": "Ephesians", "Php": "Philippians",
    "Col": "Colossians",
    "1Th": "1 Thessalonians", "2Th": "2 Thessalonians",
    "1Ti": "1 Timothy", "2Ti": "2 Timothy",
    "Tit": "Titus", "Phm": "Philemon",
    # General
    "Heb": "Hebrews", "Jas": "James",
    "1Pe": "1 Peter", "2Pe": "2 Peter",
    "1Jo": "1 John", "2Jo": "2 John", "3Jo": "3 John",
    "Jude": "Jude", "Jud:": "Jude",  # JFB uses "Jude" (the colon variant catches occasional formatting)
    "Re": "Revelation",
}

CANONICAL_NAMES = set(ABBREV_MAP.values())

# Lines that mark a chapter boundary. Most books use "CHAPTER N" but
# Lamentations uses "CHAPTER (ELEGY) N" so the regex tolerates an optional
# parenthesized label between "CHAPTER" and the number.
CHAPTER_RE = re.compile(r"^\s*CHAPTER\s+(?:\([A-Z]+\)\s+)?(\d+)\s*$")
CHAPTER_ONE_LITERALS = ("CHAPTER 1", "CHAPTER (ELEGY) 1")

# Section header inside a multi-chapter book:
#   "Ge 1:1, 2. The Creation of Heaven and Earth."
#   "Ex 1:1-22. Increase of the Israelites."
#   "Ps 23:1-6. The Lord My Shepherd."
# The verse-range capture is tight (digits, commas, dashes only — NO whitespace)
# so we don't run away into the body of the prose.
SECTION_RE = re.compile(
    r"^\s*((?:[123]\s?)?[A-Z][a-z]{1,4})\s+(\d+):(\d+(?:[-,]\d+)*)\.\s+(.{2,200}?)\s*$"
)

# Section header inside a one-chapter book (Obadiah, Philemon, 2-3 John, Jude).
# Format omits the chapter and uses the form "Ob 1-21. Title."
SINGLE_CHAPTER_SECTION_RE = re.compile(
    r"^\s*((?:[123]\s?)?[A-Z][a-z]{1,4})\s+(\d+(?:[-,]\d+)*)\.\s+(.{2,200}?)\s*$"
)

# JFB uses "PSALM N" markers for Psalms instead of "CHAPTER N", and omits
# chapter markers entirely for the five single-chapter books (Obadiah,
# Philemon, 2 John, 3 John, Jude). Everything else uses the standard
# "CHAPTER N" marker, so we can enumerate the 60 multi-chapter, non-Psalms
# books in canonical order and map them to "CHAPTER 1" markers in source
# order. This sidesteps JFB's wildly inconsistent multi-line title format.
CHAPTERED_BOOKS_IN_ORDER: list[str] = [
    # Pentateuch
    "Genesis", "Exodus", "Leviticus", "Numbers", "Deuteronomy",
    # Historical
    "Joshua", "Judges", "Ruth",
    "1 Samuel", "2 Samuel", "1 Kings", "2 Kings",
    "1 Chronicles", "2 Chronicles",
    "Ezra", "Nehemiah", "Esther", "Job",
    # (Psalms here in the canon, but JFB uses "PSALM N" markers — handled separately)
    "Proverbs", "Ecclesiastes", "Song of Solomon",
    # Major prophets
    "Isaiah", "Jeremiah", "Lamentations", "Ezekiel", "Daniel",
    # Minor prophets — Obadiah skipped as it's single-chapter
    "Hosea", "Joel", "Amos",
    # Obadiah is technically single-chapter but JFB uses CHAPTER 1 for it,
    # so we treat it as a chaptered book here.
    "Obadiah",
    "Jonah", "Micah", "Nahum", "Habakkuk", "Zephaniah", "Haggai",
    "Zechariah", "Malachi",
    # NT — Philemon, 2/3 John, Jude skipped as single-chapter (no CHAPTER N)
    "Matthew", "Mark", "Luke", "John", "Acts", "Romans",
    "1 Corinthians", "2 Corinthians", "Galatians", "Ephesians",
    "Philippians", "Colossians", "1 Thessalonians", "2 Thessalonians",
    "1 Timothy", "2 Timothy", "Titus",
    "Hebrews", "James", "1 Peter", "2 Peter", "1 John",
    "Revelation",
]

PSALM_RE = re.compile(r"^\s*PSALM\s+(\d+)\s*$")
SINGLE_CHAPTER_BOOKS = ["Philemon", "2 John", "3 John", "Jude"]
SINGLE_CHAPTER_ABBREV = {
    "Philemon": "Phm",
    "2 John":   "2Jo",
    "3 John":   "3Jo",
    "Jude":     "Jude",
}


def parse_verse_range(token: str) -> tuple[int, int | None]:
    """
    Turn the verse-range token (e.g., "1, 2", "3-5", "31") into
    (start_verse, end_verse). end_verse is None for a single verse.
    """
    token = token.strip()
    if "-" in token:
        a, b = token.split("-", 1)
        return int(a.strip()), int(b.strip())
    if "," in token:
        parts = [int(p.strip()) for p in token.split(",") if p.strip().isdigit()]
        if not parts:
            raise ValueError(f"unparseable verse range: {token!r}")
        return parts[0], parts[-1] if len(parts) > 1 else None
    return int(token), None


def find_chaptered_book_boundaries(lines: list[str]) -> list[tuple[str, int, int]]:
    """
    Find each book's slice in the file by enumerating CHAPTER 1 markers and
    mapping them in canonical order to CHAPTERED_BOOKS_IN_ORDER. Returns
    [(canonical_name, start_line, end_line)].
    """
    ch1_indices = [
        i for i, l in enumerate(lines)
        if l.strip() in CHAPTER_ONE_LITERALS
    ]
    if len(ch1_indices) != len(CHAPTERED_BOOKS_IN_ORDER):
        print(
            f"WARNING: found {len(ch1_indices)} 'CHAPTER 1' markers, "
            f"expected {len(CHAPTERED_BOOKS_IN_ORDER)}"
        )
    boundaries: list[tuple[str, int, int]] = []
    for i, book in enumerate(CHAPTERED_BOOKS_IN_ORDER):
        if i >= len(ch1_indices):
            break
        start = ch1_indices[i]
        end = ch1_indices[i + 1] if i + 1 < len(ch1_indices) else len(lines)
        boundaries.append((book, start, end))
    return boundaries


def find_psalms_slice(lines: list[str], chaptered_boundaries: list[tuple[str, int, int]]) -> tuple[int, int] | None:
    """
    Psalms uses "PSALM N" markers and lives canonically between Job and
    Proverbs. Job's slice (in `chaptered_boundaries`) currently extends all
    the way from Job's CHAPTER 1 marker to Proverbs' CHAPTER 1 marker
    because there's no intermediate "CHAPTER 1" for a different book —
    Psalms uses PSALM N instead. We carve Psalms out of the back half of
    that range by finding PSALM N markers anywhere between Job's start and
    Proverbs' start.
    """
    by_book = {b: (s, e) for b, s, e in chaptered_boundaries}
    if "Job" not in by_book or "Proverbs" not in by_book:
        return None
    job_start = by_book["Job"][0]
    proverbs_start = by_book["Proverbs"][0]
    psalm_indices = [
        i for i in range(job_start, proverbs_start)
        if PSALM_RE.match(lines[i])
    ]
    if not psalm_indices:
        return None
    return (psalm_indices[0], proverbs_start)


def parse() -> dict:
    lines = SOURCE.read_text(encoding="utf-8").splitlines(keepends=True)
    boundaries = find_chaptered_book_boundaries(lines)

    result: dict[str, dict[str, list[dict]]] = {}
    section_count = 0
    for canonical, start, end in boundaries:
        # For Job, we need to truncate the slice before the PSALM 1 marker
        # (because Job's slice currently extends all the way to Proverbs).
        if canonical == "Job":
            psalms_slice = find_psalms_slice(lines, boundaries)
            if psalms_slice is not None:
                end = psalms_slice[0]
        result[canonical] = parse_chaptered_book(lines, start, end, canonical)
        section_count += sum(len(v) for v in result[canonical].values())

    # Psalms — uses PSALM N markers
    psalms_slice = find_psalms_slice(lines, boundaries)
    if psalms_slice is not None:
        psalm_data = parse_psalms(lines, psalms_slice[0], psalms_slice[1])
        if psalm_data:
            result["Psalms"] = psalm_data
            section_count += sum(len(v) for v in psalm_data.values())

    # Single-chapter books: scan their slices (we approximate the slice by
    # finding the abbreviation in section headers) and treat all matches as
    # entries for chapter 1.
    for book in SINGLE_CHAPTER_BOOKS:
        single = parse_single_chapter_book(lines, book)
        if single:
            result[book] = single
            section_count += sum(len(v) for v in single.values())

    result["_meta"] = {
        "books": len(result),
        "sections": section_count,
    }  # type: ignore[assignment]
    return result


def parse_psalms(lines: list[str], start: int, end: int) -> dict[str, list[dict]]:
    """
    Walk the Psalms slice. Each "PSALM N" marker delimits a psalm; section
    headers within a psalm slice use the "Ps N:V-V. Title." pattern.
    """
    psalm_marks: list[tuple[int, int]] = []
    for i in range(start, end):
        m = PSALM_RE.match(lines[i])
        if m:
            psalm_marks.append((int(m.group(1)), i))

    book_entries: dict[str, list[dict]] = {}
    for pi, (psalm_num, pstart) in enumerate(psalm_marks):
        pend = psalm_marks[pi + 1][1] if pi + 1 < len(psalm_marks) else end
        entries: list[dict] = []
        for i in range(pstart + 1, pend):
            line = lines[i].rstrip()
            m = SECTION_RE.match(line)
            if not m:
                continue
            abbrev = m.group(1).strip()
            chap_num_in_header = int(m.group(2))
            if abbrev != "Ps" or chap_num_in_header != psalm_num:
                continue
            try:
                start_v, end_v = parse_verse_range(m.group(3))
            except ValueError:
                continue
            title = _clean_title(m.group(4))
            if title:
                entries.append({"title": title, "start_verse": start_v, "end_verse": end_v})
        if entries:
            book_entries[str(psalm_num)] = entries
    return book_entries


def parse_single_chapter_book(lines: list[str], book: str) -> dict[str, list[dict]]:
    """
    Single-chapter books (Obadiah, Philemon, 2 John, 3 John, Jude) don't use
    a "CHAPTER N" marker in JFB. Their section headers use the form
    "Ob 1-21. Title." — abbreviation, verse range, period, title — without a
    chapter number. We scan the entire file for these and gather them into
    chapter 1.
    """
    target_abbrev = SINGLE_CHAPTER_ABBREV[book]
    entries: list[dict] = []
    seen_starts: set[int] = set()  # de-dup across the file
    for i, raw in enumerate(lines):
        m = SINGLE_CHAPTER_SECTION_RE.match(raw.rstrip())
        if not m:
            continue
        if m.group(1).strip() != target_abbrev:
            continue
        try:
            start_v, end_v = parse_verse_range(m.group(2))
        except ValueError:
            continue
        if start_v in seen_starts:
            continue
        seen_starts.add(start_v)
        title = _clean_title(m.group(3))
        if title:
            entries.append({"title": title, "start_verse": start_v, "end_verse": end_v})
    entries.sort(key=lambda e: e["start_verse"])
    return {"1": entries} if entries else {}


def parse_chaptered_book(lines: list[str], start: int, end: int, canonical: str) -> dict[str, list[dict]]:
    """
    Walk through one book's lines, find CHAPTER N markers, and within each
    chapter slice extract every JFB section header.
    """
    # Find chapter boundaries within the book.
    chapter_marks: list[tuple[int, int]] = []  # (chapter_number, line_index)
    for i in range(start, end):
        m = CHAPTER_RE.match(lines[i])
        if m:
            chapter_marks.append((int(m.group(1)), i))

    book_entries: dict[str, list[dict]] = {}

    for ci, (chapter_num, cstart) in enumerate(chapter_marks):
        cend = chapter_marks[ci + 1][1] if ci + 1 < len(chapter_marks) else end
        entries: list[dict] = []
        for i in range(cstart + 1, cend):
            line = lines[i].rstrip()

            # Try the standard "Abbrev N:V-V. Title." pattern first.
            m = SECTION_RE.match(line)
            if m:
                abbrev = m.group(1).strip()
                chap_num_in_header = int(m.group(2))
                if ABBREV_MAP.get(abbrev) != canonical or chap_num_in_header != chapter_num:
                    continue
                try:
                    start_v, end_v = parse_verse_range(m.group(3))
                except ValueError:
                    continue
                title = _clean_title(m.group(4))
                if title:
                    entries.append({"title": title, "start_verse": start_v, "end_verse": end_v})
                continue

            # Fall back to the single-chapter shape "Abbrev V-V. Title." used
            # by Obadiah (whose JFB CHAPTER 1 contains a header like
            # "Ob 1-21. Doom of Edom...").
            m = SINGLE_CHAPTER_SECTION_RE.match(line)
            if m:
                abbrev = m.group(1).strip()
                if ABBREV_MAP.get(abbrev) != canonical:
                    continue
                try:
                    start_v, end_v = parse_verse_range(m.group(2))
                except ValueError:
                    continue
                title = _clean_title(m.group(3))
                if title:
                    entries.append({"title": title, "start_verse": start_v, "end_verse": end_v})
        if entries:
            book_entries[str(chapter_num)] = entries
    return book_entries


def _clean_title(text: str) -> str:
    text = re.sub(r"\s+", " ", text).strip()
    # Strip a single trailing period if present (some headers have ". " instead
    # of ". ", and the title is captured with no period).
    if text.endswith("."):
        text = text[:-1]
    return text.strip()


def main() -> None:
    data = parse()
    meta = data.pop("_meta", {})  # type: ignore[arg-type]
    OUTPUT.parent.mkdir(parents=True, exist_ok=True)
    OUTPUT.write_text(json.dumps(data, indent=2, ensure_ascii=False))

    total_books = len(data)
    total_chapters = sum(len(v) for v in data.values())
    total_entries = sum(len(e) for v in data.values() for e in v.values())
    print(f"Parsed {total_books} books, {total_chapters} chapters, {total_entries} section entries")
    if meta:
        print(f"Meta: {meta}")
    print(f"Wrote {OUTPUT}")


if __name__ == "__main__":
    main()
