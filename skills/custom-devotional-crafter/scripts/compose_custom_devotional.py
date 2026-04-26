#!/usr/bin/env python3
"""Compose a structured custom devotional payload for SwiftBible."""

from __future__ import annotations

import argparse
import json
import re
from dataclasses import dataclass
from pathlib import Path


OLD_TESTAMENT_BOOKS = {
    "genesis", "exodus", "leviticus", "numbers", "deuteronomy", "joshua", "judges", "ruth",
    "1 samuel", "2 samuel", "1 kings", "2 kings", "1 chronicles", "2 chronicles", "ezra", "nehemiah",
    "esther", "job", "psalm", "psalms", "proverbs", "ecclesiastes", "song of solomon", "isaiah", "jeremiah",
    "lamentations", "ezekiel", "daniel", "hosea", "joel", "amos", "obadiah", "jonah", "micah", "nahum",
    "habakkuk", "zephaniah", "haggai", "zechariah", "malachi",
}

VERSE_RE = re.compile(r"^\s*(?P<book>.+?)\s+(?P<chapter>\d+):(?P<verse>\d+)(?:-\d+)?\s*$", re.IGNORECASE)


@dataclass
class VerseRef:
    book: str
    chapter: int
    verse: int
    testament: str


def normalize_book(book: str) -> str:
    return re.sub(r"\s+", " ", book.strip())


def detect_testament(book: str) -> str:
    return "old" if normalize_book(book).lower() in OLD_TESTAMENT_BOOKS else "new"


def parse_verse(raw: str) -> VerseRef:
    match = VERSE_RE.match(raw)
    if not match:
        raise ValueError(f"Invalid verse format: '{raw}'. Use e.g. 'Romans 5:3' or 'Psalm 23:1'.")

    book = normalize_book(match.group("book"))
    chapter = int(match.group("chapter"))
    verse = int(match.group("verse"))
    testament = detect_testament(book)
    return VerseRef(book=book, chapter=chapter, verse=verse, testament=testament)


def build_markdown(title: str, verses: list[VerseRef], theme: str, audience: str, tone: str) -> str:
    verse_lines = "\n".join([f"- **{v.book} {v.chapter}:{v.verse}**" for v in verses])
    return f"""# {title}

## Scripture Focus
{verse_lines}

## Reflection
Today we reflect on **{theme.lower()}** with a {tone.lower()} posture for {audience.lower()}.

## Application
- Identify one concrete situation where these verses apply today.
- Respond in prayer and obedience, not just reflection.
- Share encouragement with one person this week.

## Prayer
Lord Jesus, shape my heart by Your Word. Help me live this truth faithfully today.

## Reflection Questions
- What is God highlighting to me through these passages?
- Where do I need to trust and obey more concretely?
- Who can I encourage today with this same truth?
""".strip()


def main() -> None:
    parser = argparse.ArgumentParser(description="Compose a custom devotional payload")
    parser.add_argument("--for-date", required=True, help="Date in YYYY-MM-DD")
    parser.add_argument("--theme", required=True)
    parser.add_argument("--audience", required=True)
    parser.add_argument("--tone", required=True)
    parser.add_argument("--title", default="Custom Devotional")
    parser.add_argument("--verse", action="append", required=True, help="Verse ref (repeatable), e.g. 'Romans 5:3'")
    parser.add_argument("--output", help="Optional output JSON file path")
    parser.add_argument("--series-name", help="Optional series name (e.g. 'Extreme Faith')")
    parser.add_argument("--series-part", type=int, help="Optional series part number (e.g. 1)")
    parser.add_argument("--message-file", help="Optional path to a markdown file whose contents replace the auto-generated message")
    args = parser.parse_args()

    verses = [parse_verse(v) for v in args.verse]
    markdown = build_markdown(args.title, verses, args.theme, args.audience, args.tone)

    if args.message_file:
        markdown = Path(args.message_file).read_text(encoding="utf-8")

    payload = {
        "for_date": args.for_date,
        "message": markdown,
        "testament": verses[0].testament,
        "devotional_type": "custom",
        "verses": [v.__dict__ for v in verses],
    }
    if args.series_name:
        payload["series_name"] = args.series_name
    if args.series_part is not None:
        payload["series_part"] = args.series_part

    if args.output:
        output_path = Path(args.output)
        output_path.write_text(json.dumps(payload, indent=2), encoding="utf-8")
        print(f"Wrote payload to {output_path}")
    else:
        print(json.dumps(payload, indent=2))


if __name__ == "__main__":
    main()
