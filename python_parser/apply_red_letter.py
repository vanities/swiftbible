"""
Apply red letter (Words of Jesus) tags to Bible JSON files.

Reads red_letter_map.json — word-level spans built by build_red_letter_map.py
from the KJV's own OSIS markup — and wraps exactly those words in <JESUS>…
</JESUS>. Nothing here infers anything: if the map has no span for a verse, the
verse gets no tags.

web.json is not handled: parse_web.py carries WEB's native <wj> markup
straight through, and that markup is the second opinion the map is built
against.

Usage:
    python3 apply_red_letter.py ../ios/swiftbible/Text/bible.json
    python3 apply_red_letter.py ../ios/swiftbible/Text/asv.json
"""

import json
import os
import sys

from red_letter_common import (
    LEADING_PUNCTUATION,
    TRAILING_PUNCTUATION,
    paragraph_segments,
    words_in,
)

HERE = os.path.dirname(os.path.abspath(__file__))
MAP_PATH = os.path.join(HERE, "red_letter_map.json")

# Which set of spans belongs to which text file.
VERSION_BY_FILENAME = {
    "bible.json": "kjv",
    "asv.json": "asv",
}


def load_spans(version, map_path=None):
    """{(book, chapter, verse): [[start, end], ...]} for one translation."""
    with open(map_path or MAP_PATH, "r", encoding="utf-8") as f:
        payload = json.load(f)

    available = payload["spans"]
    if version not in available:
        raise SystemExit(
            f"red_letter_map.json has no spans for '{version}' "
            f"(it has: {', '.join(sorted(available))})"
        )

    spans = {}
    for book, chapters in available[version].items():
        for chapter, verses in chapters.items():
            for verse, ranges in verses.items():
                spans[(book, int(chapter), int(verse))] = ranges
    return spans


def tag_text(text, ranges):
    """Wrap the given word ranges of `text` in <JESUS> tags.

    Ranges are [start, end) indices into the text's word list. A span keeps the
    punctuation that closes it — "…do this?" takes its question mark, and a
    bracket hugging its first word opens with it — but never the whitespace
    either side, so an inline verse marker between two spans stays outside the
    tags.
    """
    words = words_in(text)
    if not words:
        return text

    # Resolve every boundary against the untouched text first, then splice from
    # the back, so one span's tags cannot disturb another's offsets.
    cuts = []
    for start, end in sorted(ranges):
        if start >= len(words) or end > len(words) or start >= end:
            continue
        open_at = words[start][1]
        while open_at > 0 and text[open_at - 1] in LEADING_PUNCTUATION:
            open_at -= 1
        close_at = TRAILING_PUNCTUATION.match(text, words[end - 1][2]).end()
        cuts.append((open_at, close_at))

    result = text
    for open_at, close_at in reversed(cuts):
        result = (
            result[:open_at]
            + "<JESUS>"
            + result[open_at:close_at]
            + "</JESUS>"
            + result[close_at:]
        )
    return result


def apply_red_letter(bible_json_file, version=None, output_file=None, map_path=None):
    """Rewrite a Bible JSON file's <JESUS> tags from the span map."""
    if version is None:
        version = VERSION_BY_FILENAME.get(os.path.basename(bible_json_file))
        if version is None:
            raise SystemExit(
                f"Don't know which translation {bible_json_file} is — "
                f"pass one of: {', '.join(sorted(VERSION_BY_FILENAME.values()))}"
            )

    spans = load_spans(version, map_path)

    with open(bible_json_file, "r", encoding="utf-8") as f:
        bible_data = json.load(f)

    tagged_verses = tagged_spans = 0

    for book in bible_data:
        for chapter in book["chapters"]:
            for paragraph in chapter["paragraphs"]:
                text, segments = paragraph_segments(paragraph, chapter["number"])
                rebuilt, position = [], 0
                for verse, start, end in segments:
                    ranges = spans.get((book["name"], chapter["number"], verse))
                    rebuilt.append(text[position:start])
                    if ranges:
                        rebuilt.append(tag_text(text[start:end], ranges))
                        tagged_verses += 1
                        tagged_spans += len(ranges)
                    else:
                        rebuilt.append(text[start:end])
                    position = end
                rebuilt.append(text[position:])
                paragraph["text"] = "".join(rebuilt)

    with open(output_file or bible_json_file, "w", encoding="utf-8") as f:
        json.dump(bible_data, f, ensure_ascii=False, indent=4)

    print(f"Applied {version.upper()} red letter tags to "
          f"{output_file or bible_json_file}")
    print(f"  {tagged_verses} verses tagged, {tagged_spans} spans")
    missing = len(spans) - tagged_verses
    if missing:
        print(f"  WARNING: {missing} mapped verses were not found in the text")


def main():
    if len(sys.argv) < 2:
        print("Usage: python3 apply_red_letter.py <bible.json> [version] [output.json]")
        sys.exit(1)

    bible_json = sys.argv[1]
    version = sys.argv[2] if len(sys.argv) > 2 else None
    output_file = sys.argv[3] if len(sys.argv) > 3 else None

    apply_red_letter(bible_json, version, output_file)


if __name__ == "__main__":
    main()
