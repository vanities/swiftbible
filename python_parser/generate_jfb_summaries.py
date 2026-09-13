"""
Generate summaries_jfb.json (iOS bundle + Android assets) from the parsed JFB
outline data.

Mirrors generate_mhcc_summaries.py but for Jamieson-Fausset-Brown. Produces
the same JSON schema so SummariesService can load it through the same code
path.

JFB section titles are typically more verbose than MHCC's; we apply the same
chapter-list rule (a multi-sentence prose paragraph is reduced to its first
sentence, everything else passes through verbatim, nothing is truncated) and
keep the full text in passageSummaries.
"""
from __future__ import annotations

import json
import re
from pathlib import Path

REPO = Path(__file__).resolve().parents[1]
JFB_PARSED = REPO / "python_parser" / "sources" / "jfb" / "jfb_parsed.json"
# The iOS bundle and the Android assets carry byte-identical copies.
OUTPUTS = [
    REPO / "ios" / "swiftbible" / "Text" / "summaries_jfb.json",
    REPO / "android" / "app" / "src" / "main" / "assets" / "summaries_jfb.json",
]

PROSE_PARAGRAPH_LENGTH = 90


def _chapter_list_title(full_title: str) -> str:
    if len(full_title) <= PROSE_PARAGRAPH_LENGTH:
        return full_title
    # Multi-sentence prose: keep the first sentence, without its period.
    first_sentence_match = re.match(r"[^.!?]+[.!?]", full_title)
    if first_sentence_match:
        return first_sentence_match.group(0).strip().rstrip(".")
    return full_title


def main() -> None:
    if not JFB_PARSED.exists():
        raise SystemExit(f"missing {JFB_PARSED} — run parse_jfb.py first")

    parsed = json.loads(JFB_PARSED.read_text())
    parsed.pop("_meta", None)

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
            book_titles[chap_num] = _chapter_list_title(entries[0]["title"])
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
            "name": "Jamieson, Fausset & Brown — Commentary on the Whole Bible",
            "shortName": "Jamieson-Fausset-Brown",
            "year": 1871,
            "license": "Public Domain",
            "attribution": (
                "Robert Jamieson, A. R. Fausset, and David Brown. "
                "Commentary Critical and Explanatory on the Whole Bible (1871), "
                "sourced from the Christian Classics Ethereal Library (CCEL)."
            ),
        },
        "chapterTitles": chapter_titles,
        "passageSummaries": passage_summaries,
    }

    serialized = json.dumps(payload, indent=2, ensure_ascii=False) + "\n"
    for output in OUTPUTS:
        output.parent.mkdir(parents=True, exist_ok=True)
        output.write_text(serialized)

    title_count = sum(len(v) for v in chapter_titles.values())
    passage_count = sum(
        len(entries) for book in passage_summaries.values() for entries in book.values()
    )
    for output in OUTPUTS:
        print(f"Wrote {output.relative_to(REPO)}")
    print(f"  chapter titles:    {title_count} across {len(chapter_titles)} books")
    print(f"  passage summaries: {passage_count} across {len(passage_summaries)} books")


if __name__ == "__main__":
    main()
