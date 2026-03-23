#!/usr/bin/env python3
"""Verify holiday verse texts against the actual KJV bible.json data.

Extracts all holiday verse references from the Edge Function,
looks up each one in bible.json, and reports mismatches.

Usage:
    python3 scripts/verify_holiday_verses.py

    # Look up specific verses:
    python3 scripts/verify_holiday_verses.py "John 3:16" "Psalms 23:1"
"""

import json
import re
import sys
from pathlib import Path

BIBLE_JSON = Path("supabase/functions/daily-devotional/bible.json")
EDGE_FUNCTION = Path("supabase/functions/daily-devotional/index.ts")


def load_bible():
    with open(BIBLE_JSON, "r") as f:
        return json.load(f)


def lookup_verse(bible_data, book_name, chapter_num, verse_num):
    """Find exact verse text from bible.json.

    First tries exact startingVerse match. If not found, finds the
    containing paragraph (startingVerse <= verse_num < next startingVerse).
    Strips <JESUS> tags from red-letter text.
    """
    import re

    for book in bible_data:
        if book["name"] == book_name:
            for chapter in book["chapters"]:
                if chapter["number"] == chapter_num:
                    # Try exact match first
                    for paragraph in chapter["paragraphs"]:
                        if paragraph["startingVerse"] == verse_num:
                            text = paragraph["text"].strip()
                            return re.sub(r"</?JESUS>", "", text).strip()

                    # Find containing paragraph (mid-paragraph verse)
                    sorted_p = sorted(
                        chapter["paragraphs"], key=lambda p: p["startingVerse"]
                    )
                    for i in range(len(sorted_p) - 1, -1, -1):
                        if sorted_p[i]["startingVerse"] <= verse_num:
                            text = sorted_p[i]["text"].strip()
                            return re.sub(r"</?JESUS>", "", text).strip()
    return None


def parse_reference(ref):
    """Parse 'Book Chapter:Verse' into (book, chapter, verse)."""
    match = re.match(r"(.+?)\s+(\d+):(\d+)", ref)
    if match:
        return match.group(1), int(match.group(2)), int(match.group(3))
    return None


def extract_holiday_verses(ts_source):
    """Extract all { book: "...", chapter: N, verse: N, text: "..." } from the TS file."""
    pattern = re.compile(
        r'\{\s*book:\s*"([^"]+)",\s*chapter:\s*(\d+),\s*verse:\s*(\d+),\s*text:\s*"([^"]*)"'
    )
    verses = []
    for match in pattern.finditer(ts_source):
        verses.append(
            {
                "book": match.group(1),
                "chapter": int(match.group(2)),
                "verse": int(match.group(3)),
                "hardcoded_text": match.group(4),
            }
        )
    return verses


def main():
    bible = load_bible()

    if len(sys.argv) > 1:
        # Manual lookup mode
        for ref in sys.argv[1:]:
            parsed = parse_reference(ref)
            if not parsed:
                print(f"Invalid reference: {ref}")
                continue
            book, chapter, verse = parsed
            text = lookup_verse(bible, book, chapter, verse)
            if text:
                print(f"\n{book} {chapter}:{verse}")
                print(f'  "{text}"')
            else:
                print(f"NOT FOUND: {ref}")
        return

    # Verification mode: check all holiday verses
    ts_source = EDGE_FUNCTION.read_text()
    verses = extract_holiday_verses(ts_source)

    print(f"Found {len(verses)} holiday verse references in Edge Function\n")

    mismatches = 0
    not_found = 0
    exact = 0

    for v in verses:
        ref = f'{v["book"]} {v["chapter"]}:{v["verse"]}'
        actual = lookup_verse(bible, v["book"], v["chapter"], v["verse"])

        if actual is None:
            print(f"NOT IN BIBLE.JSON: {ref}")
            print(f'  Hardcoded: "{v["hardcoded_text"]}"')
            print()
            not_found += 1
        elif actual != v["hardcoded_text"]:
            print(f"MISMATCH: {ref}")
            print(f'  Hardcoded: "{v["hardcoded_text"]}"')
            print(f'  Actual:    "{actual}"')
            print()
            mismatches += 1
        else:
            exact += 1

    print(f"\nResults: {exact} exact, {mismatches} mismatches, {not_found} not found")
    if mismatches > 0 or not_found > 0:
        print(
            "\nNote: Mismatches are OK — the Edge Function resolves text from bible.json"
        )
        print("at runtime via lookupVerseText(). Hardcoded text is only a fallback.")
        sys.exit(1)


if __name__ == "__main__":
    main()
