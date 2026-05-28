"""
Extract red letter (Words of Jesus) verse references from WEB USFX XML.

The <wj> tags in the USFX format mark Jesus's spoken words with word-level precision.
This script extracts:
  1. red_letter_verses.json — which verses contain Jesus's words
  2. red_letter_verse_types.json — per-verse classification (full/intro_only/trail_only/both)

The verse type classification is derived from the WEB JSON output (which must be
generated first with parse_web.py) and tells the post-processor whether a verse has
narrative introduction, trailing narrative, or both.

Usage:
    python3 parse_web.py                  # generate WEB JSON with <JESUS> tags first
    python3 extract_red_letter_refs.py    # then extract refs + types
"""

import json
import re
import os

# Map USFX book IDs to standard names (same as parse_web.py)
BOOK_ID_MAPPING = {
    "GEN": "Genesis", "EXO": "Exodus", "LEV": "Leviticus", "NUM": "Numbers",
    "DEU": "Deuteronomy", "JOS": "Joshua", "JDG": "Judges", "RUT": "Ruth",
    "1SA": "1 Samuel", "2SA": "2 Samuel", "1KI": "1 Kings", "2KI": "2 Kings",
    "1CH": "1 Chronicles", "2CH": "2 Chronicles", "EZR": "Ezra", "NEH": "Nehemiah",
    "EST": "Esther", "JOB": "Job", "PSA": "Psalms", "PRO": "Proverbs",
    "ECC": "Ecclesiastes", "SNG": "Song of Solomon", "ISA": "Isaiah",
    "JER": "Jeremiah", "LAM": "Lamentations", "EZK": "Ezekiel", "DAN": "Daniel",
    "HOS": "Hosea", "JOL": "Joel", "AMO": "Amos", "OBA": "Obadiah",
    "JON": "Jonah", "MIC": "Micah", "NAM": "Nahum", "HAB": "Habakkuk",
    "ZEP": "Zephaniah", "HAG": "Haggai", "ZEC": "Zechariah", "MAL": "Malachi",
    "MAT": "Matthew", "MRK": "Mark", "LUK": "Luke", "JHN": "John",
    "ACT": "Acts", "ROM": "Romans", "1CO": "1 Corinthians", "2CO": "2 Corinthians",
    "GAL": "Galatians", "EPH": "Ephesians", "PHP": "Philippians", "COL": "Colossians",
    "1TH": "1 Thessalonians", "2TH": "2 Thessalonians", "1TI": "1 Timothy",
    "2TI": "2 Timothy", "TIT": "Titus", "PHM": "Philemon", "HEB": "Hebrews",
    "JAS": "James", "1PE": "1 Peter", "2PE": "2 Peter", "1JN": "1 John",
    "2JN": "2 John", "3JN": "3 John", "JUD": "Jude", "REV": "Revelation",
}


def extract_red_letter_refs(usfx_file):
    """Parse USFX XML and extract verse references containing <wj> tags."""
    with open(usfx_file, "r", encoding="utf-8") as f:
        content = f.read()

    red_letter_map = {}  # {book_name: {chapter_str: [verse_numbers]}}

    # Split by book
    book_pattern = re.compile(r'<book id="([A-Z0-9]+)"[^>]*>(.*?)</book>', re.DOTALL)

    for book_match in book_pattern.finditer(content):
        book_id = book_match.group(1)
        book_content = book_match.group(2)

        book_name = BOOK_ID_MAPPING.get(book_id)
        if not book_name:
            continue

        if "<wj" not in book_content:
            continue

        marker_pattern = re.compile(
            r'<c id="(\d+)"/>|<v id="(\d+)"/>|<wj[ >]'
        )

        current_chapter = None
        current_verse = None

        for m in marker_pattern.finditer(book_content):
            if m.group(1):
                current_chapter = int(m.group(1))
                current_verse = None
            elif m.group(2):
                current_verse = int(m.group(2))
            else:
                if current_chapter and current_verse:
                    chapter_str = str(current_chapter)
                    if book_name not in red_letter_map:
                        red_letter_map[book_name] = {}
                    if chapter_str not in red_letter_map[book_name]:
                        red_letter_map[book_name][chapter_str] = []
                    if current_verse not in red_letter_map[book_name][chapter_str]:
                        red_letter_map[book_name][chapter_str].append(current_verse)

    for book in red_letter_map:
        for chapter in red_letter_map[book]:
            red_letter_map[book][chapter].sort()

    return red_letter_map


def extract_verse_types(web_json_file, red_letter_map):
    """Classify each red-letter verse as full/intro_only/trail_only/both.

    Uses the WEB JSON (which has word-level <JESUS> tags) to determine
    whether each verse has narrative introduction, trailing narrative, or both.
    """
    with open(web_json_file, "r", encoding="utf-8") as f:
        web_data = json.load(f)

    verse_types = {}  # {book: {chapter: {verse: type}}}

    for book in web_data:
        book_name = book["name"]
        if book_name not in red_letter_map:
            continue

        book_refs = red_letter_map[book_name]
        book_types = {}

        for chapter in book["chapters"]:
            chapter_str = str(chapter["number"])
            if chapter_str not in book_refs:
                continue

            red_verses = set(book_refs[chapter_str])
            chapter_types = {}

            for paragraph in chapter["paragraphs"]:
                verse_num = paragraph["startingVerse"]
                if verse_num not in red_verses:
                    continue

                raw = paragraph["text"].strip()
                clean = raw.replace("<JESUS>", "").replace("</JESUS>", "")

                # Find Jesus portions
                jesus_parts = re.findall(r"<JESUS>(.*?)</JESUS>", raw)
                jesus_len = sum(len(p) for p in jesus_parts)
                clean_len = len(clean.strip())

                if clean_len == 0:
                    continue

                if jesus_len >= clean_len * 0.95:
                    chapter_types[str(verse_num)] = "full"
                    continue

                # Check for intro and trail
                first_jesus = raw.find("<JESUS>")
                text_before = raw[:first_jesus].replace("</JESUS>", "").strip()
                has_intro = len(text_before) > 0

                last_jesus_end = raw.rfind("</JESUS>") + len("</JESUS>")
                text_after = raw[last_jesus_end:].replace("<JESUS>", "").strip()
                has_trail = len(text_after) > 2

                if has_intro and has_trail:
                    chapter_types[str(verse_num)] = "both"
                elif has_intro:
                    chapter_types[str(verse_num)] = "intro_only"
                elif has_trail:
                    chapter_types[str(verse_num)] = "trail_only"
                else:
                    chapter_types[str(verse_num)] = "full"

            if chapter_types:
                book_types[chapter_str] = chapter_types

        if book_types:
            verse_types[book_name] = book_types

    return verse_types


def main():
    usfx_file = "eng-web.usfx.xml"
    web_json_file = "../ios/swiftbible/Text/web.json"
    refs_output = "red_letter_verses.json"
    types_output = "red_letter_verse_types.json"

    # Step 1: Extract verse references from USFX XML
    print("Extracting red letter verse references from WEB USFX XML...")
    refs = extract_red_letter_refs(usfx_file)

    with open(refs_output, "w", encoding="utf-8") as f:
        json.dump(refs, f, indent=2)

    total_verses = sum(
        len(verses)
        for chapters in refs.values()
        for verses in chapters.values()
    )
    print(f"Extracted {total_verses} red letter verses across {len(refs)} books")
    for book, chapters in refs.items():
        book_total = sum(len(v) for v in chapters.values())
        print(f"  {book}: {book_total} verses")
    print(f"Saved to {refs_output}")

    # Step 2: Extract verse type classifications from WEB JSON
    if os.path.exists(web_json_file):
        print(f"\nClassifying verse types from {web_json_file}...")
        verse_types = extract_verse_types(web_json_file, refs)

        with open(types_output, "w", encoding="utf-8") as f:
            json.dump(verse_types, f, indent=2)

        # Count types
        type_counts = {"full": 0, "intro_only": 0, "trail_only": 0, "both": 0}
        for book_types in verse_types.values():
            for chapter_types in book_types.values():
                for vtype in chapter_types.values():
                    type_counts[vtype] = type_counts.get(vtype, 0) + 1

        print(f"Verse type breakdown:")
        for vtype, count in sorted(type_counts.items(), key=lambda x: -x[1]):
            print(f"  {vtype}: {count}")
        print(f"Saved to {types_output}")
    else:
        print(f"\nWARNING: {web_json_file} not found. Run parse_web.py first.")
        print("Skipping verse type classification.")


if __name__ == "__main__":
    main()
