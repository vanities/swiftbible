"""
Post-processor to apply red letter (Words of Jesus) tags to Bible JSON files.

Uses red_letter_verses.json (extracted from WEB USFX <wj> tags) as the
authoritative reference for which verses contain Jesus's words.

For translations without native red letter markup (KJV, ASV), this applies
phrase-level <JESUS> tags using speech-introduction verb detection to separate
narrative from Jesus's spoken words. Handles KJV's multi-verse paragraphs by
parsing inline chapter:verse references.

Usage:
    python3 apply_red_letter.py ../ios/swiftbible/Text/bible.json
    python3 apply_red_letter.py ../ios/swiftbible/Text/asv.json
"""

import json
import re
import sys
import os


def load_red_letter_refs(refs_file=None):
    """Load the red letter verse reference map."""
    if refs_file is None:
        refs_file = os.path.join(os.path.dirname(__file__), "red_letter_verses.json")
    with open(refs_file, "r", encoding="utf-8") as f:
        return json.load(f)


def load_verse_types(types_file=None):
    """Load the per-verse type classification (full/intro_only/trail_only/both)."""
    if types_file is None:
        types_file = os.path.join(os.path.dirname(__file__), "red_letter_verse_types.json")
    if not os.path.exists(types_file):
        return None
    with open(types_file, "r", encoding="utf-8") as f:
        return json.load(f)


def strip_jesus_tags(text):
    """Remove existing <JESUS> tags from text."""
    return text.replace("<JESUS>", "").replace("</JESUS>", "")


# Speech-introducing verbs. We find these, then scan forward to the next [,;:]
# to locate the boundary where Jesus's speech begins.
SPEECH_VERB_PATTERN = re.compile(
    r"\b(?:said|saith|say|saying|answered|answering|spake|speak|cried|commanded|"
    r"calleth|called|asked|crieth|speaketh)\b",
    re.IGNORECASE,
)

# Alternative intro: "began to say/speak/preach"
ALT_INTRO_PATTERN = re.compile(
    r"\bbegan\s+to\s+(?:say|speak|preach)\b",
    re.IGNORECASE,
)

# "spake ... parable" pattern
SPAKE_PATTERN = re.compile(
    r"\bspake\b",
    re.IGNORECASE,
)

# Trailing narrative pattern: sentence-ending punctuation followed by third-person narrative.
# Matches from the sentence boundary to end of text.
TRAIL_PATTERN = re.compile(
    r"([.!?])\s+"
    r"(And\s+(?:he|she|they|his|her|the|it|immediately|when|straightway|presently|Jesus|Peter|all)"
    r"|Then\s+(?:he|she|they|came|the|Jesus|said|Peter|all)"
    r"|But\s+(?:they|he|she|the|when|Peter|Jesus|it)"
    r"|They\s+(?:said|were|came|told|held|did|answered)"
    r"|His\s+(?:servant|daughter|disciples|mother|fame)"
    r"|She\s+(?:was|said|came)"
    r"|So\s+(?:he|she|they|the|Jesus|when)"
    r"|Immediately\s"
    r"|Straightway\s"
    r"|When\s+(?:he|she|they|the|Jesus|Peter)"
    r"|The\s+(?:woman|man|servant|people|multitude|blind)"
    r"|He\s+(?:arose|went|stretched|came|departed|turned|said|saith)"
    r")",
    re.IGNORECASE,
)


def find_speech_start(text):
    """Find where Jesus's speech begins in a verse with narrative intro.

    Strategy: find the LAST speech-introducing verb, then scan forward to the
    next comma, semicolon, or colon. Everything after that boundary is speech.

    This handles patterns like:
      "said unto him,"  /  "saith Jesus unto them,"
      "spake he unto them;"  /  "began to say,"
      "asked the scribes,"  /  "said unto the sick of the palsy,"

    Returns the character index where Jesus's words start, or None.
    """
    last_boundary = None

    # Check for "began to say/speak/preach" (must come before verb check
    # since "say" would also match as a standalone verb)
    for m in ALT_INTRO_PATTERN.finditer(text):
        rest = text[m.end():]
        # Look for the next [,;:] after the "began to say" phrase
        boundary = re.search(r"[,;:]\s*", rest)
        if boundary:
            last_boundary = m.end() + boundary.end()
        else:
            # "began to say," — the comma might be right at the end of the match
            # or the speech starts immediately
            last_boundary = m.end()

    # Find all speech-introducing verbs and take the LAST one's boundary
    for verb_match in SPEECH_VERB_PATTERN.finditer(text):
        rest = text[verb_match.end():]
        # Scan forward to find the next [,;:] — this is the speech boundary
        boundary = re.search(r"[,;:]\s*", rest)
        if boundary:
            candidate = verb_match.end() + boundary.end()
            # Take the LAST verb's boundary (handles "answered and said,")
            last_boundary = candidate

    return last_boundary


def find_speech_end(text, speech_start):
    """Find where Jesus's speech ends when there's trailing narrative.

    Searches from speech_start forward for the last sentence boundary
    before trailing narrative begins.

    Returns the character index where Jesus's words end, or None if
    no trailing narrative is detected.
    """
    # Search for trailing narrative patterns AFTER the speech starts
    search_text = text[speech_start:]
    matches = list(TRAIL_PATTERN.finditer(search_text))
    if not matches:
        return None

    # Use the LAST match as the trail boundary (handles multiple sentence boundaries)
    # But actually we want the FIRST match that looks like narrative after speech
    # Try each match from last to first and pick the one that makes most sense
    for m in reversed(matches):
        trail_start = speech_start + m.start()
        # Include the sentence-ending punctuation in Jesus's speech
        trail_start += 1  # include the . or ? or !
        speech_portion = text[speech_start:trail_start].strip()
        # Sanity check: Jesus's speech should be non-trivial
        if len(speech_portion) > 2:
            return trail_start

    return None


def tag_verse_text(text, verse_type):
    """Apply <JESUS> tags to a single verse's text based on its type.

    verse_type: 'full', 'intro_only', 'trail_only', 'both', or None (unknown/full)
    """
    if not text.strip():
        return text

    if verse_type == "full" or verse_type is None:
        # Entire verse is Jesus's words
        return f"<JESUS>{text}</JESUS>"

    if verse_type in ("intro_only", "both"):
        speech_start = find_speech_start(text)
        if speech_start is None:
            # Can't find speech intro — fall back to full verse
            return f"<JESUS>{text}</JESUS>"

        if verse_type == "both":
            speech_end = find_speech_end(text, speech_start)
            if speech_end is not None:
                # Tag only the speech portion
                intro = text[:speech_start]
                speech = text[speech_start:speech_end]
                trail = text[speech_end:]
                return f"{intro}<JESUS>{speech}</JESUS>{trail}"

        # intro_only or 'both' where trail detection failed
        intro = text[:speech_start]
        speech = text[speech_start:]
        return f"{intro}<JESUS>{speech}</JESUS>"

    if verse_type == "trail_only":
        # Speech at start, narrative at end — try to find trail
        speech_end = find_speech_end(text, 0)
        if speech_end is not None:
            speech = text[:speech_end]
            trail = text[speech_end:]
            return f"<JESUS>{speech}</JESUS>{trail}"
        # Fall back to full verse
        return f"<JESUS>{text}</JESUS>"

    # Unknown type — full verse fallback
    return f"<JESUS>{text}</JESUS>"


def apply_to_paragraph(paragraph, chapter_num, red_verses, verse_types):
    """Apply <JESUS> tags to a paragraph based on the red letter reference map.

    Handles both single-verse paragraphs and KJV-style multi-verse paragraphs
    that contain inline chapter:verse references.
    """
    text = strip_jesus_tags(paragraph["text"])
    starting_verse = paragraph["startingVerse"]

    # Find inline verse references matching the current chapter
    ref_pattern = re.compile(r"\b(\d+):(\d+[a-z]?)\b")
    matches = list(ref_pattern.finditer(text))

    # Filter to refs that match the current chapter (avoid cross-reference false positives)
    chapter_refs = []
    for m in matches:
        ref_ch = int(m.group(1))
        ref_verse_str = m.group(2)
        ref_verse = int(re.match(r"\d+", ref_verse_str).group())
        if ref_ch == chapter_num:
            chapter_refs.append((m.start(), m.end(), ref_verse))

    if not chapter_refs:
        # Simple case: single-verse paragraph
        if starting_verse in red_verses:
            vtype = verse_types.get(str(starting_verse)) if verse_types else None
            paragraph["text"] = tag_verse_text(text, vtype)
        else:
            paragraph["text"] = text
        return

    # Multi-verse paragraph: build segments with verse ownership
    segments = []
    pos = 0
    current_verse = starting_verse

    for ref_start, ref_end, ref_verse in chapter_refs:
        if pos < ref_start:
            segments.append((pos, ref_start, current_verse, False))
        segments.append((ref_start, ref_end, None, True))
        current_verse = ref_verse
        pos = ref_end

    if pos < len(text):
        segments.append((pos, len(text), current_verse, False))

    # Rebuild text with phrase-level <JESUS> tags
    result = []
    for text_start, text_end, verse_num, is_ref in segments:
        seg_text = text[text_start:text_end]
        if is_ref:
            result.append(seg_text)
        elif verse_num in red_verses and seg_text.strip():
            vtype = verse_types.get(str(verse_num)) if verse_types else None
            result.append(tag_verse_text(seg_text, vtype))
        else:
            result.append(seg_text)

    paragraph["text"] = "".join(result)


def apply_red_letter(bible_json_file, refs_file=None, output_file=None):
    """Apply red letter tags to a Bible JSON file using the verse reference map."""
    refs = load_red_letter_refs(refs_file)
    all_verse_types = load_verse_types()

    with open(bible_json_file, "r", encoding="utf-8") as f:
        bible_data = json.load(f)

    if output_file is None:
        output_file = bible_json_file

    tagged_count = 0

    for book in bible_data:
        book_name = book["name"]
        if book_name not in refs:
            continue

        book_refs = refs[book_name]
        book_types = all_verse_types.get(book_name, {}) if all_verse_types else {}

        for chapter in book["chapters"]:
            chapter_str = str(chapter["number"])
            if chapter_str not in book_refs:
                continue

            red_verses = set(book_refs[chapter_str])
            chapter_types = book_types.get(chapter_str, {})

            for paragraph in chapter["paragraphs"]:
                had_tag = "<JESUS>" in paragraph["text"]
                apply_to_paragraph(
                    paragraph, chapter["number"], red_verses, chapter_types
                )
                if "<JESUS>" in paragraph["text"] and not had_tag:
                    tagged_count += 1

    with open(output_file, "w", encoding="utf-8") as f:
        json.dump(bible_data, f, ensure_ascii=False, indent=4)

    print(f"Applied red letter tags to {output_file}")
    print(f"  New paragraphs tagged: {tagged_count}")


def main():
    if len(sys.argv) < 2:
        print(
            "Usage: python3 apply_red_letter.py <bible.json> [red_letter_verses.json] [output.json]"
        )
        sys.exit(1)

    bible_json = sys.argv[1]
    refs_file = sys.argv[2] if len(sys.argv) > 2 else None
    output_file = sys.argv[3] if len(sys.argv) > 3 else None

    apply_red_letter(bible_json, refs_file, output_file)


if __name__ == "__main__":
    main()
