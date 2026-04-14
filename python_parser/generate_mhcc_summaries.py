"""
Generate swiftbible/Text/Summaries/mhcc.json from the parsed MHCC outline data.

Inputs:
  python_parser/sources/mhcc/mhcc_parsed.json  (produced by parse_mhcc.py)

Output:
  swiftbible/Text/Summaries/mhcc.json

Rules:
- Chapter title = first outline entry's title, verbatim.
- Passage summaries = every outline entry verbatim, in source order, with
  explicit startVerse / endVerse carried through from the parser.
- Empty books and chapters are omitted — the Swift side falls back through the
  source chain (MHCC → SwiftBible) whenever a book/chapter is missing.

Schema matches migrate_summaries_to_json.py — see that file for the full shape.
"""
from __future__ import annotations

import json
import re
from pathlib import Path

REPO = Path(__file__).resolve().parents[1]
MHCC_PARSED = REPO / "python_parser" / "sources" / "mhcc" / "mhcc_parsed.json"
OUTPUT = REPO / "swiftbible" / "Text" / "summaries_mhcc.json"

# For the chapter-list view we want terse titles. A handful of MHCC chapters
# (notably Psalms 119, Ezekiel 47) have no structured outline — MHCC just
# provides a multi-sentence prose paragraph as the whole-chapter intro. Those
# are valuable content for the passage-summary surface, but unusable as a
# list-row label. We extract the first sentence (or truncate on a word
# boundary) for the chapter title and keep the full paragraph for the
# passage summary.
MAX_TITLE_LENGTH = 90


def _shorten_for_chapter_list(full_title: str) -> str:
    if len(full_title) <= MAX_TITLE_LENGTH:
        return full_title
    # First sentence
    first_sentence_match = re.match(r"[^.!?]+[.!?]", full_title)
    if first_sentence_match:
        candidate = first_sentence_match.group(0).strip().rstrip(".")
        if len(candidate) <= MAX_TITLE_LENGTH:
            return candidate
    # Fall back to a word-boundary truncation with an ellipsis.
    truncated = full_title[:MAX_TITLE_LENGTH].rsplit(" ", 1)[0].rstrip(",;:")
    return truncated + "…"


def main() -> None:
    if not MHCC_PARSED.exists():
        raise SystemExit(f"missing {MHCC_PARSED} — run parse_mhcc.py first")

    parsed = json.loads(MHCC_PARSED.read_text())

    chapter_titles: dict[str, dict[str, str]] = {}
    passage_summaries: dict[str, dict[str, list[dict]]] = {}

    for book, chapters in parsed.items():
        if not chapters:
            continue
        book_titles: dict[str, str] = {}
        book_passages: dict[str, list[dict]] = {}
        for chap_num, entries in chapters.items():
            if not entries:
                continue
            # Chapter title = first section's title, shortened for the list row.
            book_titles[chap_num] = _shorten_for_chapter_list(entries[0]["title"])
            # Passage summaries = all entries, schema rename
            book_passages[chap_num] = [
                {
                    "startVerse": e["start_verse"],
                    "endVerse": e["end_verse"],
                    "title": e["title"],
                }
                for e in entries
            ]
        if book_titles:
            chapter_titles[book] = book_titles
        if book_passages:
            passage_summaries[book] = book_passages

    payload = {
        "source": {
            "name": "Matthew Henry's Concise Commentary",
            "shortName": "Matthew Henry",
            "year": 1706,
            "license": "Public Domain",
            "attribution": (
                "Matthew Henry (1662–1714). Concise Commentary on the Bible, "
                "sourced from the Christian Classics Ethereal Library (CCEL)."
            ),
        },
        "chapterTitles": chapter_titles,
        "passageSummaries": passage_summaries,
    }

    OUTPUT.parent.mkdir(parents=True, exist_ok=True)
    OUTPUT.write_text(json.dumps(payload, indent=2, ensure_ascii=False) + "\n")

    title_count = sum(len(v) for v in chapter_titles.values())
    passage_count = sum(
        len(entries) for book in passage_summaries.values() for entries in book.values()
    )
    print(f"Wrote {OUTPUT.relative_to(REPO)}")
    print(f"  chapter titles:    {title_count} across {len(chapter_titles)} books")
    print(f"  passage summaries: {passage_count} across {len(passage_summaries)} books")


if __name__ == "__main__":
    main()
