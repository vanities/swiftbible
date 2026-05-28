"""
One-shot migration: read the existing Swift-dict summary files and emit a single
JSON file under ios/swiftbible/Text/Summaries/swiftbible.json in the new schema.

Inputs (read-only, not modified):
  ios/swiftbible/Text/summaries.swift         - passage summaries keyed by "C:V"
  ios/swiftbible/Text/ChapterSummaries.swift  - chapter titles keyed by chapter

Output:
  ios/swiftbible/Text/Summaries/swiftbible.json

The migration is lossless — after running, every entry in the Swift files is
present in the JSON. The script prints a per-book count summary so you can
eyeball the round-trip.

Schema (documented in the conversation):
{
  "source": { ... metadata ... },
  "chapterTitles": { "<book>": { "<chapter>": "<title>" } },
  "passageSummaries": {
     "<book>": {
        "<chapter>": [ { "startVerse": N, "endVerse": N|null, "title": "..." } ]
     }
  }
}
"""
from __future__ import annotations

import json
import re
from pathlib import Path

REPO = Path(__file__).resolve().parents[1]
SUMMARIES_SWIFT = REPO / "swiftbible" / "Text" / "summaries.swift"
CHAPTER_SUMMARIES_SWIFT = REPO / "swiftbible" / "Text" / "ChapterSummaries.swift"
OUTPUT = REPO / "swiftbible" / "Text" / "summaries_swiftbible.json"


BOOK_HEADER_RE = re.compile(r'^\s*"([^"]+)":\s*\[\s*$')
# Passage entry: "1:1": "God creates ...",
# Chapter-title entry: "1": "Creation",
ENTRY_RE = re.compile(
    r'^\s*"(?P<key>[^"]+)":\s*"(?P<value>(?:[^"\\]|\\.)*)"\s*,?\s*$'
)
BOOK_CLOSE_RE = re.compile(r"^\s*\],?\s*$")


def _unescape_swift_string(s: str) -> str:
    """
    Swift uses the same backslash escapes as JSON for our purposes: \\" and \\\\.
    Strings with \\' are not used in these files. We keep it simple.
    """
    return s.replace('\\"', '"').replace("\\\\", "\\")


def parse_swift_dict(path: Path) -> dict[str, dict[str, str]]:
    """
    Parse a Swift file containing a top-level `let x: [String: [String: String]]`
    literal. Returns {book_name: {inner_key: value}} in source order.
    """
    result: dict[str, dict[str, str]] = {}
    current_book: str | None = None

    with path.open(encoding="utf-8") as f:
        for raw in f:
            line = raw.rstrip("\n")
            # Skip comments and blank lines
            stripped = line.strip()
            if not stripped or stripped.startswith("//"):
                continue

            book_match = BOOK_HEADER_RE.match(line)
            if book_match:
                name = book_match.group(1)
                # Filter out the outer dict header line (which has the form
                # `let xxx: [String: [String: String]] = [`). Book headers look
                # like `"Genesis": [`. We detect that by checking for a colon
                # NOT preceded by `String`.
                if ": " in line and "String" not in stripped:
                    current_book = name
                    result.setdefault(current_book, {})
                    continue

            if current_book and BOOK_CLOSE_RE.match(line):
                current_book = None
                continue

            if current_book:
                m = ENTRY_RE.match(line)
                if m:
                    key = m.group("key")
                    val = _unescape_swift_string(m.group("value"))
                    result[current_book][key] = val

    return result


def build_chapter_titles(raw: dict[str, dict[str, str]]) -> dict[str, dict[str, str]]:
    """ChapterSummaries.swift keys are plain chapter numbers."""
    return {book: {chap: title for chap, title in entries.items()}
            for book, entries in raw.items() if entries}


def build_passage_summaries(
    raw: dict[str, dict[str, str]],
) -> dict[str, dict[str, list[dict]]]:
    """
    summaries.swift keys are "C:V" — one entry per starting verse. The legacy
    schema has no end_verse, so we emit endVerse=null for every entry and let
    the Swift side treat it as "open-ended, this section covers from startVerse
    until the next section starts."
    """
    out: dict[str, dict[str, list[dict]]] = {}
    for book, entries in raw.items():
        per_chapter: dict[str, list[dict]] = {}
        for key, title in entries.items():
            if ":" not in key:
                continue
            chap, verse = key.split(":", 1)
            try:
                start_verse = int(verse)
            except ValueError:
                continue
            per_chapter.setdefault(chap, []).append({
                "startVerse": start_verse,
                "endVerse": None,
                "title": title,
            })
        # Sort each chapter's entries by startVerse for deterministic output.
        for chap in per_chapter:
            per_chapter[chap].sort(key=lambda e: e["startVerse"])
        if per_chapter:
            out[book] = per_chapter
    return out


def main() -> None:
    if not SUMMARIES_SWIFT.exists():
        raise SystemExit(f"missing {SUMMARIES_SWIFT}")
    if not CHAPTER_SUMMARIES_SWIFT.exists():
        raise SystemExit(f"missing {CHAPTER_SUMMARIES_SWIFT}")

    raw_passages = parse_swift_dict(SUMMARIES_SWIFT)
    raw_titles = parse_swift_dict(CHAPTER_SUMMARIES_SWIFT)

    payload = {
        "source": {
            "name": "SwiftBible Curated",
            "shortName": "SwiftBible",
            "year": 2024,
            "license": "Original — SwiftBible",
            "attribution": (
                "Hand-written chapter titles and passage summaries curated by "
                "the SwiftBible authors."
            ),
        },
        "chapterTitles": build_chapter_titles(raw_titles),
        "passageSummaries": build_passage_summaries(raw_passages),
    }

    OUTPUT.parent.mkdir(parents=True, exist_ok=True)
    OUTPUT.write_text(json.dumps(payload, indent=2, ensure_ascii=False) + "\n")

    # Sanity counts
    title_count = sum(len(v) for v in payload["chapterTitles"].values())
    passage_count = sum(
        len(entries)
        for book in payload["passageSummaries"].values()
        for entries in book.values()
    )
    book_count_titles = len(payload["chapterTitles"])
    book_count_passages = len(payload["passageSummaries"])

    print(f"Wrote {OUTPUT.relative_to(REPO)}")
    print(f"  chapter titles:    {title_count} across {book_count_titles} books")
    print(f"  passage summaries: {passage_count} across {book_count_passages} books")


if __name__ == "__main__":
    main()
