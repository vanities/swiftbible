"""
Parse Matthew Henry's Concise Commentary (CCEL plain-text edition) into a
structured JSON form that the summary generators consume.

Source: https://www.ccel.org/ccel/h/henry/mhcc/cache/mhcc.txt  (Public Domain)
Input:  python_parser/sources/mhcc/mhcc.txt
Output: python_parser/sources/mhcc/mhcc_parsed.json

Emitted schema:
    {
      "<Book Name>": {
        "<chapter number as str>": [
          {"title": "God creates heaven and earth.",
           "start_verse": 1,
           "end_verse": 2},
          ...
        ]
      }
    }

Titles are left verbatim at this stage — the LLM-modernization step runs later
in generate_chapter_summaries.py.
"""
from __future__ import annotations

import json
import re
from pathlib import Path

SOURCE = Path(__file__).parent / "sources" / "mhcc" / "mhcc.txt"
OUTPUT = Path(__file__).parent / "sources" / "mhcc" / "mhcc_parsed.json"

CANONICAL_BOOKS = [
    "Genesis", "Exodus", "Leviticus", "Numbers", "Deuteronomy", "Joshua",
    "Judges", "Ruth", "1 Samuel", "2 Samuel", "1 Kings", "2 Kings",
    "1 Chronicles", "2 Chronicles", "Ezra", "Nehemiah", "Esther", "Job",
    "Psalms", "Proverbs", "Ecclesiastes", "Song of Solomon", "Isaiah",
    "Jeremiah", "Lamentations", "Ezekiel", "Daniel", "Hosea", "Joel", "Amos",
    "Obadiah", "Jonah", "Micah", "Nahum", "Habakkuk", "Zephaniah", "Haggai",
    "Zechariah", "Malachi", "Matthew", "Mark", "Luke", "John", "Acts",
    "Romans", "1 Corinthians", "2 Corinthians", "Galatians", "Ephesians",
    "Philippians", "Colossians", "1 Thessalonians", "2 Thessalonians",
    "1 Timothy", "2 Timothy", "Titus", "Philemon", "Hebrews", "James",
    "1 Peter", "2 Peter", "1 John", "2 John", "3 John", "Jude", "Revelation",
]

CHAPTER_RE = re.compile(r"^Chapter (\d+)\s*$")
# Format A: "(1, 2)", "(3-5)", "(31)" alone on a line
VERSE_RANGE_RE = re.compile(r"^\(([\d\s,\-–]+)\)\s*$")
# Format B: inline reference like "(Is. 1:1-9)", "(Eccl. 1:1-3)", "(2 Ki. 1:1-8)"
# We don't need to capture the book abbreviation — only the chapter + verse range.
INLINE_REF_RE = re.compile(
    r"\(\s*(?:[\dA-Za-z][\w\s.]*?\.?\s*)(\d+):(\d+)(?:\s*[-–]\s*(\d+))?\s*\)"
)


def parse_verse_range(token: str) -> tuple[int, int | None]:
    """
    Turn the contents of a (…) group into (start_verse, end_verse).
    end_verse is None if only a single verse is mentioned.
    """
    token = token.replace("–", "-").strip()
    # Handle "1, 2" → treat as range 1–2 (it's a small ordered list)
    if "," in token and "-" not in token:
        parts = [int(p.strip()) for p in token.split(",") if p.strip().isdigit()]
        if not parts:
            raise ValueError(f"unparseable verse range: {token!r}")
        return parts[0], parts[-1] if len(parts) > 1 else None
    # Handle range "3-5"
    if "-" in token:
        a, b = token.split("-", 1)
        return int(a.strip()), int(b.strip())
    # Single verse "31"
    return int(token.strip()), None


def find_book_start_indices(lines: list[str]) -> dict[str, int]:
    """
    Walk the file top-to-bottom and locate the FIRST line that is exactly a
    canonical book name surrounded by blank lines. That's the book header;
    any later occurrence is a cross-reference inside the commentary.
    """
    starts: dict[str, int] = {}
    for i, line in enumerate(lines):
        name = line.strip()
        if name not in CANONICAL_BOOKS or name in starts:
            continue
        before_blank = i == 0 or lines[i - 1].strip() == ""
        after_blank = i + 1 == len(lines) or lines[i + 1].strip() == ""
        if before_blank and after_blank:
            starts[name] = i
    return starts


def _clean_title(text: str) -> str:
    text = re.sub(r"\s+", " ", text).strip()
    # Strip surrounding punctuation artifacts but keep internal punctuation.
    text = text.strip(" .,;:")
    return text


def extract_format_a(lines: list[str], start: int, end: int) -> list[dict]:
    """
    Format A: "Chapter Outline" header with titles and verse ranges on
    separate lines. Block ends at first "Verses ..." section.
    """
    outline_start = None
    for i in range(start, end):
        if lines[i].strip() == "Chapter Outline":
            outline_start = i + 1
            break
    if outline_start is None:
        return []

    outline_end = end
    for i in range(outline_start, end):
        if re.match(r"^Verses?\b", lines[i].strip()):
            outline_end = i
            break

    entries: list[dict] = []
    pending_title: list[str] = []

    for i in range(outline_start, outline_end):
        stripped = lines[i].strip()
        if not stripped:
            if pending_title:
                pending_title.append("")
            continue

        m = VERSE_RANGE_RE.match(stripped)
        if m:
            if not pending_title:
                continue
            title = _clean_title(" ".join(t for t in pending_title if t))
            if title:
                start_v, end_v = parse_verse_range(m.group(1))
                entries.append({
                    "title": title,
                    "start_verse": start_v,
                    "end_verse": end_v,
                })
            pending_title = []
            continue

        pending_title.append(stripped)

    return entries


def extract_format_b(lines: list[str], start: int, end: int) -> list[dict]:
    """
    Format B: inline paragraph outline immediately after the "Chapter N"
    header, using book-prefixed refs like "(Is. 1:1-9)" to delimit sections.

        Chapter 1

           The corruptions prevailing among the Jews. (Is. 1:1-9) Severe
           censures. (Is. 1:10-15) ...

    We collapse the paragraph text, then split it at each ref marker; the text
    before each marker becomes that section's title.
    """
    # Collect the indented paragraph block directly after Chapter N up until
    # the first verse-commentary section (which starts with the same ref
    # pattern at the start of its own paragraph, e.g., "Is. 1:1-9 Isaiah...").
    collected: list[str] = []
    i = start + 1
    # Skip leading blanks
    while i < end and not lines[i].strip():
        i += 1
    # Read until we hit a blank followed by a non-parenthetical commentary line
    while i < end:
        stripped = lines[i].strip()
        if not stripped:
            # Stop when the next non-blank line looks like a commentary section
            # header, i.e., it starts with "Abbrev. N:N" (no opening paren).
            j = i + 1
            while j < end and not lines[j].strip():
                j += 1
            if j >= end:
                break
            next_line = lines[j].strip()
            # Commentary sections begin with "Xx. N:N" (or "Xx. N:N-M") followed
            # by the actual prose body, NOT wrapped in parentheses.
            if re.match(r"^[\dA-Za-z][\w\s]*?\.\s*\d+:\d+", next_line):
                break
            collected.append("")
            i += 1
            continue
        collected.append(stripped)
        i += 1

    paragraph = " ".join(x for x in collected if x).strip()
    if not paragraph:
        return []

    # Split on inline refs. Each ref closes the title that preceded it.
    entries: list[dict] = []
    last = 0
    for m in INLINE_REF_RE.finditer(paragraph):
        title = _clean_title(paragraph[last:m.start()])
        start_v = int(m.group(2))
        end_v = int(m.group(3)) if m.group(3) else None
        if title:
            entries.append({
                "title": title,
                "start_verse": start_v,
                "end_verse": end_v,
            })
        last = m.end()
    return entries


def extract_format_c(lines: list[str], start: int, end: int) -> list[dict]:
    """
    Format C: chapter has a single outline sentence with no verse refs at all.
    We take the first non-empty paragraph after "Chapter N" as the summary and
    attach it to verse 1 (covering the whole chapter).
    """
    i = start + 1
    while i < end and not lines[i].strip():
        i += 1
    collected: list[str] = []
    while i < end:
        stripped = lines[i].strip()
        if not stripped:
            if collected:
                break
            i += 1
            continue
        # Stop if we've wandered into the commentary body (lines beginning with
        # a verse ref like "Amos 1:1-5 ...") — shouldn't happen for Format C
        # but guard anyway.
        if re.match(r"^[\dA-Za-z][\w\s]*?\.\s*\d+:\d+", stripped):
            break
        collected.append(stripped)
        i += 1

    title = _clean_title(" ".join(collected))
    if not title:
        return []
    return [{"title": title, "start_verse": 1, "end_verse": None}]


_LEADING_ARTIFACTS = (
    "part. ",   # CCEL plain-text conversion occasionally drops the first half
                # of phrases like "The first part. An exhortation..."
)


def _finalize_title(title: str) -> str:
    # CCEL plain-text conversion occasionally leaves an em-dash style prefix
    # at the start of prose paragraphs (e.g., "--We may usefully ..."). Drop
    # those and any stray whitespace.
    title = re.sub(r"^-{1,3}\s*", "", title)
    for artifact in _LEADING_ARTIFACTS:
        if title.lower().startswith(artifact):
            title = title[len(artifact):]
    title = title.strip()
    if title and title[0].islower():
        title = title[0].upper() + title[1:]
    return title


def _merge_fragmented_titles(entries: list[dict]) -> list[dict]:
    """
    MHCC outline paragraphs occasionally split a single grammatical sentence
    across multiple verse refs — e.g. Isaiah 53's outline reads
    "The person. (Is. 53:1-3) sufferings. (Is. 53:4-9) humiliation ... (10-12)"
    which our splitter turns into three nonsensical entries.

    Rule: if a title starts with a lowercase letter, or starts with "and "/"or ",
    it's a continuation of the previous entry. Merge it into the previous one,
    extending the verse range.
    """
    if not entries:
        return entries
    merged: list[dict] = [dict(entries[0])]
    for current in entries[1:]:
        title = current["title"]
        first_word = title.split(" ", 1)[0].lower() if title else ""
        is_continuation = (
            not title
            or title[0].islower()
            or first_word in {"and", "or", "but"}
        )
        if is_continuation and merged:
            prev = merged[-1]
            joiner = ", " if not prev["title"].rstrip().endswith((".", ";", ",")) else " "
            prev["title"] = (prev["title"].rstrip(".;") + joiner + title).strip()
            # Extend the verse range to cover the continuation.
            end_v = current["end_verse"] if current["end_verse"] is not None else current["start_verse"]
            prev["end_verse"] = end_v
        else:
            merged.append(dict(current))
    # Final cleanup pass: strip leading artifacts and capitalize.
    for e in merged:
        e["title"] = _finalize_title(e["title"])
    return merged


def extract_chapter_outline(lines: list[str], start: int, end: int) -> tuple[list[dict], str]:
    """
    Try each format in order. Returns (entries, format_tag) so the caller can
    record which path matched — helpful for diagnostics.
    """
    entries = extract_format_a(lines, start, end)
    if entries:
        return _merge_fragmented_titles(entries), "A"
    entries = extract_format_b(lines, start, end)
    if entries:
        return _merge_fragmented_titles(entries), "B"
    entries = extract_format_c(lines, start, end)
    if entries:
        return _merge_fragmented_titles(entries), "C"
    return [], "none"


def parse() -> dict[str, dict[str, list[dict]]]:
    lines = SOURCE.read_text(encoding="utf-8").splitlines()
    book_starts = find_book_start_indices(lines)

    # Order books by their starting line so we can slice between them.
    ordered = sorted(book_starts.items(), key=lambda kv: kv[1])
    ordered_lines: list[tuple[str, int, int]] = []
    for idx, (book, start) in enumerate(ordered):
        end = ordered[idx + 1][1] if idx + 1 < len(ordered) else len(lines)
        ordered_lines.append((book, start, end))

    result: dict[str, dict[str, list[dict]]] = {}
    format_stats: dict[str, int] = {"A": 0, "B": 0, "C": 0, "none": 0}
    for book, bstart, bend in ordered_lines:
        # Find chapter markers within [bstart, bend)
        chapter_positions: list[tuple[int, int]] = []
        for i in range(bstart, bend):
            m = CHAPTER_RE.match(lines[i].strip())
            if m:
                chapter_positions.append((int(m.group(1)), i))

        book_entries: dict[str, list[dict]] = {}
        for ci, (chapter_num, cstart) in enumerate(chapter_positions):
            cend = chapter_positions[ci + 1][1] if ci + 1 < len(chapter_positions) else bend
            entries, fmt = extract_chapter_outline(lines, cstart, cend)
            format_stats[fmt] += 1
            if entries:
                book_entries[str(chapter_num)] = entries

        if book_entries:
            result[book] = book_entries

    result["_meta"] = {"format_stats": format_stats}  # type: ignore[assignment]
    return result


def main() -> None:
    data = parse()
    meta = data.pop("_meta", {})  # type: ignore[arg-type]
    OUTPUT.parent.mkdir(parents=True, exist_ok=True)
    OUTPUT.write_text(json.dumps(data, indent=2, ensure_ascii=False))

    total_books = len(data)
    total_chapters = sum(len(v) for v in data.values())
    total_entries = sum(len(e) for v in data.values() for e in v.values())
    print(f"Parsed {total_books} books, {total_chapters} chapters, {total_entries} outline entries")
    if meta:
        print(f"Format usage: {meta.get('format_stats')}")
    print(f"Wrote {OUTPUT}")


if __name__ == "__main__":
    main()
